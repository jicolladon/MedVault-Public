using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.Features.Auth.Application.Interfaces;
using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Auth.Application.Handlers;

public class RegisterWithGoogleCommandHandler : ICommandHandler<RegisterWithGoogleCommand, RegisterResponse>
{
    private readonly IGoogleTokenValidator _googleValidator;
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;
    private readonly ILogger<RegisterWithGoogleCommandHandler> _logger;

    public RegisterWithGoogleCommandHandler(
        IGoogleTokenValidator googleValidator,
        UserManager<AppUser> userManager,
        MedVaultDbContext db,
        ILogger<RegisterWithGoogleCommandHandler> logger)
    {
        _googleValidator = googleValidator;
        _userManager = userManager;
        _db = db;
        _logger = logger;
    }

    public async Task<RegisterResponse> HandleAsync(RegisterWithGoogleCommand command, CancellationToken ct = default)
    {
        var reg = command.Registration;
        var payload = await _googleValidator.ValidateAsync(reg.GoogleIdToken);
        if (payload is null)
            throw new UnauthorizedAccessException("Invalid Google ID token.");
        var existing = await _userManager.Users
            .AnyAsync(u => u.GoogleId == payload.Subject || u.Email == payload.Email, ct);
        if (existing)
            throw new InvalidOperationException("A user with this Google account already exists.");
        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = payload.Email,
            Email = payload.Email,
            EmailConfirmed = payload.EmailVerified,
            GoogleId = payload.Subject,
            FirstName = reg.FirstName,
            LastName = reg.LastName,
            ProfilePictureUrl = payload.Picture,
            DateOfBirth = reg.DateOfBirth.HasValue ? new DateOnly(reg.DateOfBirth.Value.Year, reg.DateOfBirth.Value.Month, reg.DateOfBirth.Value.Day) : null,
            Gender = reg.Gender?.ToString(),
            PhoneNumber = reg.PhoneNumber,
            AddressLine1 = reg.Address,
            City = reg.City,
            State = reg.State,
            PostalCode = reg.ZipCode,
            Country = reg.Country,
            TermsAccepted = reg.TermsAccepted,
            TermsAcceptedDate = DateTime.UtcNow,
            PrivacyPolicyAccepted = reg.PrivacyPolicyAccepted,
            PrivacyPolicyAcceptedDate = DateTime.UtcNow,
            AccountStatus = "Active",
            LastLoginDate = DateTime.UtcNow,
            LastActivityDate = DateTime.UtcNow,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            ProfileCompleteness = CalculateCompleteness(reg)
        };

        var result = await _userManager.CreateAsync(user);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to create user: {errors}");
        }
        var loginInfo = new UserLoginInfo("Google", payload.Subject, "Google");
        await _userManager.AddLoginAsync(user, loginInfo);
        _db.UserConsents.AddRange(
            new UserConsentEntity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ConsentType = "Terms",
                ConsentGiven = true,
                ConsentDate = DateTime.UtcNow,
                IpAddress = command.IpAddress,
                UserAgent = command.UserAgent,
                ConsentVersion = "1.0"
            },
            new UserConsentEntity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ConsentType = "Privacy",
                ConsentGiven = true,
                ConsentDate = DateTime.UtcNow,
                IpAddress = command.IpAddress,
                UserAgent = command.UserAgent,
                ConsentVersion = "1.0"
            }
        );

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("New user registered: {UserId} ({Email})", user.Id, user.Email);

        return new RegisterResponse(
            User: new UserSummaryDto(
                user.Id, user.Email!, user.FirstName, user.LastName,
                user.ProfilePictureUrl, user.ProfileCompleteness)
        );
    }

    private static int CalculateCompleteness(RegisterRequest reg)
    {
        var fields = new object?[] { reg.FirstName, reg.LastName, reg.DateOfBirth, reg.Gender, reg.PhoneNumber, reg.Address, reg.City, reg.State, reg.ZipCode, reg.Country };
        var filled = fields.Count(f => f is not null && f.ToString() != "");
        return (int)((double)filled / fields.Length * 100);
    }

}

