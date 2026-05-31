using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Auth.Application.Handlers;

public class LogoutCommandHandler : ICommandHandler<LogoutCommand, bool>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<LogoutCommandHandler> _logger;

    public LogoutCommandHandler(MedVaultDbContext db, ILogger<LogoutCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<bool> HandleAsync(LogoutCommand command, CancellationToken ct = default)
    {
        var sessions = await _db.UserSessions
            .Where(s => s.UserId == command.UserId && s.IsActive)
            .ToListAsync(ct);

        foreach (var session in sessions)
        {
            session.IsActive = false;
        }
        var tokens = await _db.RefreshTokens
            .Where(r => r.UserId == command.UserId && r.IsActive)
            .ToListAsync(ct);

        foreach (var token in tokens)
        {
            token.IsActive = false;
            token.RevokedAt = DateTime.UtcNow;
            token.RevokedReason = "Logout";
        }
        if (!string.IsNullOrEmpty(command.AccessToken))
        {
            _db.BlacklistedTokens.Add(new BlacklistedTokenEntity
            {
                Id = Guid.NewGuid(),
                Token = HashToken(command.AccessToken),
                UserId = command.UserId,
                BlacklistedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(2),
                Reason = "Logout"
            });
        }
        var user = await _db.Users.FindAsync([command.UserId], ct);
        if (user is not null)
        {
            user.LastLogoutDate = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("User {UserId} logged out", command.UserId);

        return true;
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(bytes);
    }
}

