using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.Features.Auth.Application.Interfaces;
using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Auth.Application.Handlers;

public class GoogleLoginCommandHandler : ICommandHandler<GoogleLoginCommand, GoogleLoginResponse>
{
    private readonly IGoogleTokenValidator _googleValidator;
    private readonly IJwtTokenService _jwtService;
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;
    private readonly ILogger<GoogleLoginCommandHandler> _logger;

    public GoogleLoginCommandHandler(
        IGoogleTokenValidator googleValidator,
        IJwtTokenService jwtService,
        UserManager<AppUser> userManager,
        MedVaultDbContext db,
        ILogger<GoogleLoginCommandHandler> logger)
    {
        _googleValidator = googleValidator;
        _jwtService = jwtService;
        _userManager = userManager;
        _db = db;
        _logger = logger;
    }

    public async Task<GoogleLoginResponse> HandleAsync(GoogleLoginCommand command, CancellationToken ct = default)
    {
        var payload = await _googleValidator.ValidateAsync(command.IdToken);
        if (payload is null)
            throw new UnauthorizedAccessException("Invalid Google ID token.");
        var user = await _userManager.Users
            .FirstOrDefaultAsync(u => u.GoogleId == payload.Subject || u.Email == payload.Email, ct);

        if (user is null)
        {
            return new GoogleLoginResponse(
                AccessToken: "",
                RefreshToken: "",
                AccessTokenExpiresAt: DateTime.UtcNow,
                User: new UserSummaryDto(Guid.Empty, payload.Email, payload.GivenName, payload.FamilyName, payload.Picture, 0),
                IsNewUser: true
            );
        }
        user.LastLoginDate = DateTime.UtcNow;
        user.LastActivityDate = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);
        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken();
        var refreshDays = 30;
        var refreshEntity = new RefreshTokenEntity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Token = HashToken(refreshToken),
            IssuedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
            IsActive = true
        };
        _db.RefreshTokens.Add(refreshEntity);
        var session = new UserSessionEntity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            SessionToken = HashToken(accessToken),
            IpAddress = command.IpAddress,
            UserAgent = command.UserAgent,
            CreatedAt = DateTime.UtcNow,
            LastActivityAt = DateTime.UtcNow,
            ExpiresAt = _jwtService.GetAccessTokenExpiration(),
            IsActive = true
        };
        _db.UserSessions.Add(session);

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} logged in via Google", user.Id);

        return new GoogleLoginResponse(
            AccessToken: accessToken,
            RefreshToken: refreshToken,
            AccessTokenExpiresAt: _jwtService.GetAccessTokenExpiration(),
            User: new UserSummaryDto(
                user.Id, user.Email!, user.FirstName, user.LastName,
                user.ProfilePictureUrl, user.ProfileCompleteness),
            IsNewUser: false
        );
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(bytes);
    }
}

