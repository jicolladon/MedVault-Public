using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Configuration.Application.Services;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Domain;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class CreateEmergencyShareLinkHandler
    : ICommandHandler<CreateEmergencyShareLinkCommand, ShareLinkManagementResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly ISystemConfigurationService _systemConfigurationService;
    private readonly IShareProtectionService _shareProtection;
    private readonly ILogger<CreateEmergencyShareLinkHandler> _logger;

    public CreateEmergencyShareLinkHandler(
        MedVaultDbContext db,
        ISystemConfigurationService systemConfigurationService,
        IShareProtectionService shareProtection,
        ILogger<CreateEmergencyShareLinkHandler> logger)
    {
        _db = db;
        _systemConfigurationService = systemConfigurationService;
        _shareProtection = shareProtection;
        _logger = logger;
    }

    public async Task<ShareLinkManagementResponse> HandleAsync(
        CreateEmergencyShareLinkCommand command,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var maxSharingLinksPerUser = _systemConfigurationService.GetSharingSettings().MaxSharingLinksPerUser;
        if (maxSharingLinksPerUser == 0)
        {
            throw new InvalidOperationException("Sharing link creation is disabled by system configuration.");
        }

        var activeLinkCount = await _db.ShareTokens.CountAsync(
            token => token.UserId == command.UserId
                && !token.IsRevoked
                && token.ExpiresAt >= now,
            cancellationToken);

        if (activeLinkCount >= maxSharingLinksPerUser)
        {
            throw new InvalidOperationException(
                $"You have reached the maximum of {maxSharingLinksPerUser} active sharing links. Revoke an existing link to create a new one.");
        }

        var entity = new ShareTokenEntity
        {
            Id = Guid.NewGuid(),
            UserId = command.UserId,
            AccessLevel = "EmergencyOnly",
            ShareType = "Emergency",
            Label = string.IsNullOrWhiteSpace(command.Data.Label) ? null : command.Data.Label.Trim(),
            CreatedAt = now,
            ExpiresAt = now.AddMinutes(command.Data.SecuritySettings.AccessDurationMinutes),
            IsRevoked = false,
            AccessCount = 0,
        };

        var publicToken = _shareProtection.GenerateProtectedToken(entity.Id);
        entity.Token = publicToken;
        entity.TokenHash = _shareProtection.HashToken(publicToken);
        entity.ShareCode = SharePayloadMapper.BuildShareCode(publicToken);

        _db.ShareTokens.Add(entity);
        var payload = SharePayloadMapper.CreateEmergencyPayload(command.Data);
        payload = ShareSecuritySettingsFactory.ApplyProtectedSecrets(payload, null, _shareProtection);
        payload = await ShareDocumentContentStore.PersistForShareTokenAsync(
            _db,
            _shareProtection,
            entity.Id,
            command.UserId,
            payload,
            cancellationToken);
        var payloadJson = SharePayloadMapper.Serialize(payload);
        entity.EncryptedPayload = _shareProtection.ProtectPayload(payloadJson);
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Emergency sharing link created for user {UserId} with share id {ShareId}",
            command.UserId,
            entity.Id);

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
                payload));
    }
}

