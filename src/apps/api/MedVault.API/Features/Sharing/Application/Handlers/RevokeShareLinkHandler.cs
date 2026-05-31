using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.Commands;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class RevokeShareLinkHandler
    : ICommandHandler<RevokeShareLinkCommand, bool>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<RevokeShareLinkHandler> _logger;

    public RevokeShareLinkHandler(
        MedVaultDbContext db,
        ILogger<RevokeShareLinkHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<bool> HandleAsync(
        RevokeShareLinkCommand command,
        CancellationToken cancellationToken = default)
    {
        var entity = await _db.ShareTokens
            .FirstOrDefaultAsync(
                token => token.Id == command.LinkId && token.UserId == command.UserId,
                cancellationToken);

        if (entity is null)
        {
            return false;
        }

        if (entity.IsRevoked)
        {
            return true;
        }

        entity.IsRevoked = true;
        entity.RevokedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Sharing link {ShareId} revoked by user {UserId}",
            command.LinkId,
            command.UserId);

        return true;
    }
}

