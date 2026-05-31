using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Queries;
using MedVault.API.Features.Sharing.Domain;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class GetMyShareLinksHandler
    : IQueryHandler<GetMyShareLinksQuery, IReadOnlyList<ShareLinkManagementResponse>>
{
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;
    private readonly ILogger<GetMyShareLinksHandler> _logger;

    public GetMyShareLinksHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        ILogger<GetMyShareLinksHandler> logger)
    {
        _db = db;
        _shareProtection = shareProtection;
        _logger = logger;
    }

    public async Task<IReadOnlyList<ShareLinkManagementResponse>> HandleAsync(
        GetMyShareLinksQuery query,
        CancellationToken cancellationToken = default)
    {
        var tokens = await _db.ShareTokens
            .AsNoTracking()
            .Where(token => token.UserId == query.UserId)
            .OrderByDescending(token => token.CreatedAt)
            .ToListAsync(cancellationToken);

        var responses = new List<ShareLinkManagementResponse>(tokens.Count);
        foreach (var token in tokens)
        {
            var payload = TryReadPayload(token);
            var publicToken = token.Token;
            responses.Add(
                SharePayloadMapper.ToManagementResponse(
                    new ShareTokenSnapshot(
                        token.Id,
                        token.ShareType,
                        token.AccessLevel,
                        token.Label,
                        token.CreatedAt,
                        token.ExpiresAt,
                        token.IsRevoked,
                        token.RevokedAt,
                        token.AccessCount,
                        token.LastAccessedAt,
                        publicToken,
                        SharePayloadMapper.BuildShareCode(publicToken),
                        payload)));
        }

        return responses;
    }

    private SharePayloadDto TryReadPayload(ShareTokenEntity entity)
    {
        if (string.IsNullOrWhiteSpace(entity.EncryptedPayload))
        {
            return new SharePayloadDto();
        }

        try
        {
            var rawPayload = _shareProtection.UnprotectPayload(entity.EncryptedPayload);
            return SharePayloadMapper.Deserialize(rawPayload);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to decrypt sharing payload for share id {ShareId}",
                entity.Id);
            return new SharePayloadDto();
        }
    }
}

