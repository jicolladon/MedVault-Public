using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Domain;
using MedVault.API.Features.UserProfile.Application.DTOs;
using MedVault.API.Features.UserProfile.Application.Queries;
using MedVault.API.Features.Shared.Domain;

namespace MedVault.API.Features.UserProfile.Application.Handlers;

public sealed class GetUserProfileQueryHandler
    : IQueryHandler<GetUserProfileQuery, UserProfileResponse?>
{
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;
    private readonly ILogger<GetUserProfileQueryHandler> _logger;

    public GetUserProfileQueryHandler(
        UserManager<AppUser> userManager,
        MedVaultDbContext db,
        ILogger<GetUserProfileQueryHandler> logger)
    {
        _userManager = userManager;
        _db = db;
        _logger = logger;
    }

    public async Task<UserProfileResponse?> HandleAsync(GetUserProfileQuery query, CancellationToken ct)
    {
        var user = await _userManager.FindByIdAsync(query.UserId.ToString());
        if (user is null) return null;

        var emergencyContacts = await _db.UserEmergencyContacts
            .AsNoTracking()
            .Where(c => c.UserId == query.UserId)
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

        if (emergencyContacts.Count == 0 &&
            (!string.IsNullOrWhiteSpace(user.EmergencyContactName) ||
             !string.IsNullOrWhiteSpace(user.EmergencyContactPhone)))
        {
            emergencyContacts.Add(new EmergencyContactResponse
            {
                ContactId = "legacy-primary",
                Name = user.EmergencyContactName ?? "Emergency Contact",
                Relationship = user.EmergencyContactRelationship ?? "other",
                Phone = user.EmergencyContactPhone ?? string.Empty,
                Email = null,
                IsPrimary = true,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt
            });
        }

        var primaryContact = emergencyContacts.FirstOrDefault(c => c.IsPrimary)
            ?? emergencyContacts.FirstOrDefault();

        var preferences = await _db.UserPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.UserId == query.UserId, ct);

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

    private static string ComposeDisplayName(string? firstName, string? lastName, string? email)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        if (!string.IsNullOrWhiteSpace(fullName))
            return fullName;

        return email ?? string.Empty;
    }
}

public sealed class GetProfileCompletenessQueryHandler
    : IQueryHandler<GetProfileCompletenessQuery, ProfileCompletenessResponse>
{
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;

    public GetProfileCompletenessQueryHandler(UserManager<AppUser> userManager, MedVaultDbContext db)
    {
        _userManager = userManager;
        _db = db;
    }

    public async Task<ProfileCompletenessResponse> HandleAsync(GetProfileCompletenessQuery query, CancellationToken ct)
    {
        var user = await _userManager.FindByIdAsync(query.UserId.ToString())
            ?? throw new KeyNotFoundException("User not found.");

        var hasEmergencyContact = await _db.UserEmergencyContacts
            .AsNoTracking()
            .AnyAsync(c => c.UserId == query.UserId, ct);

        var missing = new List<string>();
        var completed = new List<string>();

        CheckField(user.FirstName, "First Name", missing, completed);
        CheckField(user.LastName, "Last Name", missing, completed);
        CheckField(user.DateOfBirth?.ToString(), "Date of Birth", missing, completed);
        CheckField(user.Gender, "Gender", missing, completed);
        CheckField(user.PhoneNumber, "Phone Number", missing, completed);
        CheckField(user.AddressLine1, "Address", missing, completed);
        CheckField(user.City, "City", missing, completed);
        CheckField(user.Country, "Country", missing, completed);
        CheckField(hasEmergencyContact ? "has-contact" : null, "Emergency Contact", missing, completed);
        CheckField(user.BloodType, "Blood Type", missing, completed);

        var total = missing.Count + completed.Count;
        var percentage = total > 0 ? (int)Math.Round(100.0 * completed.Count / total) : 0;

        return new ProfileCompletenessResponse
        {
            Percentage = percentage,
            MissingFields = missing,
            CompletedSections = completed
        };
    }

    private static void CheckField(string? value, string name, List<string> missing, List<string> completed)
    {
        if (string.IsNullOrWhiteSpace(value))
            missing.Add(name);
        else
            completed.Add(name);
    }
}

public sealed class GetEmergencyContactsQueryHandler
    : IQueryHandler<GetEmergencyContactsQuery, IReadOnlyList<EmergencyContactResponse>>
{
    private readonly MedVaultDbContext _db;

    public GetEmergencyContactsQueryHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<EmergencyContactResponse>> HandleAsync(
        GetEmergencyContactsQuery query,
        CancellationToken ct)
    {
        return await _db.UserEmergencyContacts
            .AsNoTracking()
            .Where(c => c.UserId == query.UserId)
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
    }
}

