using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.Features.Auth.Application.Queries;

namespace MedVault.API.Features.Auth.Application.Handlers;

public class GetSessionStatusQueryHandler : IQueryHandler<GetSessionStatusQuery, SessionStatusDto?>
{
    private readonly MedVaultDbContext _db;

    public GetSessionStatusQueryHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<SessionStatusDto?> HandleAsync(GetSessionStatusQuery query, CancellationToken ct = default)
    {
        var session = await _db.UserSessions
            .Where(s => s.UserId == query.UserId && s.IsActive)
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (session is null)
            return null;

        return new SessionStatusDto(
            SessionId: session.Id,
            UserId: session.UserId,
            CreatedAt: session.CreatedAt,
            ExpiresAt: session.ExpiresAt,
            IsActive: session.IsActive && session.ExpiresAt > DateTime.UtcNow,
            DeviceInfo: session.DeviceInfo
        );
    }
}

