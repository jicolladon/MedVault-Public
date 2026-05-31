using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Domain;
using MedVault.API.Features.UserProfile.Application.Commands;
using MedVault.API.Features.UserProfile.Application.DTOs;
using MedVault.API.Features.UserProfile.Domain;
using MedVault.API.Features.Shared.Domain;

namespace MedVault.API.Features.UserProfile.Application.Handlers;

public sealed class UpdateUserProfileCommandHandler
    : ICommandHandler<UpdateUserProfileCommand, UserProfileResponse>
{
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;
    private readonly ILogger<UpdateUserProfileCommandHandler> _logger;

    public UpdateUserProfileCommandHandler(
        UserManager<AppUser> userManager,
        MedVaultDbContext db,
        ILogger<UpdateUserProfileCommandHandler> logger)
    {
        _userManager = userManager;
        _db = db;
        _logger = logger;
    }

    public async Task<UserProfileResponse> HandleAsync(UpdateUserProfileCommand command, CancellationToken ct)
    {
        var user = await _userManager.FindByIdAsync(command.UserId.ToString())
            ?? throw new KeyNotFoundException("User not found.");

        var data = command.Data;
        var changes = new List<(string Field, string? OldValue, string? NewValue)>();

        if (!string.IsNullOrWhiteSpace(data.Email))
        {
            var normalizedEmail = data.Email.Trim();
            if (!string.Equals(user.Email, normalizedEmail, StringComparison.OrdinalIgnoreCase))
            {
                var oldEmail = user.Email;
                var emailResult = await _userManager.SetEmailAsync(user, normalizedEmail);
                if (!emailResult.Succeeded)
                {
                    var errors = string.Join("; ", emailResult.Errors.Select(e => e.Description));
                    throw new InvalidOperationException($"Failed to update email: {errors}");
                }

                var userNameResult = await _userManager.SetUserNameAsync(user, normalizedEmail);
                if (!userNameResult.Succeeded)
                {
                    var errors = string.Join("; ", userNameResult.Errors.Select(e => e.Description));
                    throw new InvalidOperationException($"Failed to update username: {errors}");
                }

                changes.Add(("Email", oldEmail, normalizedEmail));
            }
        }

        if (!string.IsNullOrWhiteSpace(data.DisplayName) &&
            data.FirstName is null &&
            data.LastName is null)
        {
            var nameParts = data.DisplayName
                .Trim()
                .Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var firstName = nameParts.Length > 0 ? nameParts[0] : string.Empty;
            var lastName = nameParts.Length > 1 ? string.Join(" ", nameParts.Skip(1)) : string.Empty;

            if (!string.Equals(user.FirstName, firstName, StringComparison.Ordinal))
            {
                changes.Add(("FirstName", user.FirstName, firstName));
                user.FirstName = firstName;
            }

            if (!string.Equals(user.LastName, lastName, StringComparison.Ordinal))
            {
                changes.Add(("LastName", user.LastName, lastName));
                user.LastName = lastName;
            }
        }

        SetIfChanged(v => user.FirstName = v, () => user.FirstName, data.FirstName, "FirstName", changes);
        SetIfChanged(v => user.LastName = v, () => user.LastName, data.LastName, "LastName", changes);
        SetIfChanged(v => user.ProfilePictureUrl = v, () => user.ProfilePictureUrl, data.ProfilePictureUrl, "ProfilePictureUrl", changes);
        ApplyIfChanged(user, data, changes);

        user.UpdatedAt = DateTime.UtcNow;
        RecalculateCompleteness(user);

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to update profile: {errors}");
        }
        foreach (var (field, oldValue, newValue) in changes)
        {
            _db.ProfileChangeHistory.Add(new ProfileChangeHistoryEntity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                FieldName = field,
                OldValue = oldValue,
                NewValue = newValue,
                ChangedAt = DateTime.UtcNow,
                ChangedBy = user.Id
            });
        }

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Profile updated for user {UserId}, {ChangeCount} fields changed",
            user.Id, changes.Count);

        var emergencyContacts = await _db.UserEmergencyContacts
            .AsNoTracking()
            .Where(c => c.UserId == user.Id)
            .OrderByDescending(c => c.IsPrimary)
            .ThenBy(c => c.CreatedAt)
            .Select(c => new EmergencyContactResponse
            {
                ContactId = c.ContactId,
                Name = c.Name,
                Relationship = c.Relationship,
                Phone = c.Phone,
                Email = c.Email,
                IsPrimary = c.IsPrimary,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .ToListAsync(ct);

        var primaryContact = emergencyContacts.FirstOrDefault(c => c.IsPrimary)
            ?? emergencyContacts.FirstOrDefault();

        var preferences = await _db.UserPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.UserId == user.Id, ct);

        return new UserProfileResponse
        {
            UserId = user.Id,
            Email = user.Email!,
            DisplayName = ComposeDisplayName(user.FirstName, user.LastName, user.Email),
            FirstName = user.FirstName ?? string.Empty,
            LastName = user.LastName ?? string.Empty,
            DateOfBirth = user.DateOfBirth,
            Gender = user.Gender.ToGender(),
            ProfilePictureUrl = user.ProfilePictureUrl,
            PhoneNumber = user.PhoneNumber,
            AddressLine1 = user.AddressLine1,
            AddressLine2 = user.AddressLine2,
            City = user.City,
            State = user.State,
            PostalCode = user.PostalCode,
            Country = user.Country,
            EmergencyContactName = primaryContact?.Name ?? user.EmergencyContactName,
            EmergencyContactPhone = primaryContact?.Phone ?? user.EmergencyContactPhone,
            EmergencyContactRelationship = primaryContact?.Relationship ?? user.EmergencyContactRelationship,
            BloodType = user.BloodType,
            EmergencyContacts = emergencyContacts,
            ProfileCompleteness = user.ProfileCompleteness,
            PrivacyLevel = preferences?.PrivacyLevel ?? "Standard",
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt
        };
    }

    private static void SetIfChanged(Action<string?> setter, Func<string?> getter,
        string? newValue, string fieldName, List<(string, string?, string?)> changes)
    {
        if (newValue is not null && newValue != getter())
        {
            changes.Add((fieldName, getter(), newValue));
            setter(newValue);
        }
    }

    private static void ApplyIfChanged(AppUser user, UpdateProfileRequest data,
        List<(string, string?, string?)> changes)
    {
        if (data.DateOfBirth.HasValue && data.DateOfBirth != user.DateOfBirth)
        {
            changes.Add(("DateOfBirth", user.DateOfBirth?.ToString(), data.DateOfBirth.Value.ToString()));
            user.DateOfBirth = data.DateOfBirth.Value;
        }

        SetIfChanged(
            v => user.Gender = v,
            () => user.Gender,
            data.Gender?.ToString(),
            "Gender",
            changes);
        SetIfChanged(v => user.PhoneNumber = v, () => user.PhoneNumber, data.PhoneNumber, "PhoneNumber", changes);
        SetIfChanged(v => user.AddressLine1 = v, () => user.AddressLine1, data.AddressLine1, "AddressLine1", changes);
        SetIfChanged(v => user.AddressLine2 = v, () => user.AddressLine2, data.AddressLine2, "AddressLine2", changes);
        SetIfChanged(v => user.City = v, () => user.City, data.City, "City", changes);
        SetIfChanged(v => user.State = v, () => user.State, data.State, "State", changes);
        SetIfChanged(v => user.PostalCode = v, () => user.PostalCode, data.PostalCode, "PostalCode", changes);
        SetIfChanged(v => user.Country = v, () => user.Country, data.Country, "Country", changes);
        SetIfChanged(v => user.EmergencyContactName = v, () => user.EmergencyContactName, data.EmergencyContactName, "EmergencyContactName", changes);
        SetIfChanged(v => user.EmergencyContactPhone = v, () => user.EmergencyContactPhone, data.EmergencyContactPhone, "EmergencyContactPhone", changes);
        SetIfChanged(v => user.EmergencyContactRelationship = v, () => user.EmergencyContactRelationship, data.EmergencyContactRelationship, "EmergencyContactRelationship", changes);
        SetIfChanged(v => user.BloodType = v, () => user.BloodType, data.BloodType, "BloodType", changes);
    }

    private static void RecalculateCompleteness(AppUser user)
    {
        int filled = 0, total = 10;
        if (!string.IsNullOrWhiteSpace(user.FirstName)) filled++;
        if (!string.IsNullOrWhiteSpace(user.LastName)) filled++;
        if (user.DateOfBirth.HasValue) filled++;
        if (!string.IsNullOrWhiteSpace(user.Gender)) filled++;
        if (!string.IsNullOrWhiteSpace(user.PhoneNumber)) filled++;
        if (!string.IsNullOrWhiteSpace(user.AddressLine1)) filled++;
        if (!string.IsNullOrWhiteSpace(user.City)) filled++;
        if (!string.IsNullOrWhiteSpace(user.Country)) filled++;
        if (!string.IsNullOrWhiteSpace(user.EmergencyContactName)) filled++;
        if (!string.IsNullOrWhiteSpace(user.BloodType)) filled++;
        user.ProfileCompleteness = (int)Math.Round(100.0 * filled / total);
    }

    private static string ComposeDisplayName(string? firstName, string? lastName, string? email)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        if (!string.IsNullOrWhiteSpace(fullName))
            return fullName;

        return email ?? string.Empty;
    }
}

