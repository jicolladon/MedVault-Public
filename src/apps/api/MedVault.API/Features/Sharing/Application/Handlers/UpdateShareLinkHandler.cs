using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Domain;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class UpdateShareLinkHandler
    : ICommandHandler<UpdateShareLinkCommand, ShareLinkManagementResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;
    private readonly ILogger<UpdateShareLinkHandler> _logger;

    public UpdateShareLinkHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        ILogger<UpdateShareLinkHandler> logger)
    {
        _db = db;
        _shareProtection = shareProtection;
        _logger = logger;
    }

    public async Task<ShareLinkManagementResponse> HandleAsync(
        UpdateShareLinkCommand command,
        CancellationToken cancellationToken = default)
    {
        var entity = await _db.ShareTokens
            .FirstOrDefaultAsync(
                token => token.Id == command.LinkId && token.UserId == command.UserId,
                cancellationToken)
            ?? throw new KeyNotFoundException("Sharing link not found.");

        if (entity.IsRevoked)
        {
            throw new InvalidOperationException("A revoked sharing link cannot be updated.");
        }

        var currentPayload = GetPayload(entity);
        var nextPayload = SharePayloadMapper.UpdatePayload(currentPayload, command.Data);
        nextPayload = ShareSecuritySettingsFactory.ApplyProtectedSecrets(nextPayload, currentPayload, _shareProtection);
        nextPayload = await ShareDocumentContentStore.PersistForShareTokenAsync(
            _db,
            _shareProtection,
            entity.Id,
            command.UserId,
            nextPayload,
            cancellationToken);

        entity.Label = string.IsNullOrWhiteSpace(command.Data.Label)
            ? null
            : command.Data.Label.Trim();
        entity.ExpiresAt = entity.CreatedAt.AddMinutes(command.Data.SecuritySettings.AccessDurationMinutes);
        entity.EncryptedPayload = _shareProtection.ProtectPayload(SharePayloadMapper.Serialize(nextPayload));

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Sharing link {ShareId} updated for user {UserId}",
            entity.Id,
            command.UserId);

        var publicToken = entity.Token;

        return SharePayloadMapper.ToManagementResponse(
            new ShareTokenSnapshot(
                entity.Id,
                entity.ShareType,
                entity.AccessLevel,
                entity.Label,
                entity.CreatedAt,
                entity.ExpiresAt,
                entity.IsRevoked,
                entity.RevokedAt,
                entity.AccessCount,
                entity.LastAccessedAt,
                publicToken,
                SharePayloadMapper.BuildShareCode(publicToken),
                nextPayload));
    }

    private SharePayloadDto GetPayload(ShareTokenEntity entity)
    {
        if (string.IsNullOrWhiteSpace(entity.EncryptedPayload))
        {
            return new SharePayloadDto();
        }

        var rawPayload = _shareProtection.UnprotectPayload(entity.EncryptedPayload);
        return SharePayloadMapper.Deserialize(rawPayload);
    }
}

