using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Queries;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public class ValidateShareTokenHandler : IQueryHandler<ValidateShareTokenQuery, ShareTokenValidationDto>
{
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;

    public ValidateShareTokenHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection)
    {
        _db = db;
        _shareProtection = shareProtection;
    }

    public async Task<ShareTokenValidationDto> HandleAsync(
        ValidateShareTokenQuery query, CancellationToken cancellationToken = default)
    {
        var tokenHash = _shareProtection.HashToken(query.Token);
        var shareToken = await _db.ShareTokens
            .AsNoTracking()
            .FindByPublicTokenAsync(query.Token, tokenHash, cancellationToken);

        if (shareToken is null)
        {
            return new ShareTokenValidationDto
            {
                IsValid = false,
                Message = "Share token not found."
            };
        }

        if (shareToken.IsRevoked)
        {
            return new ShareTokenValidationDto
            {
                IsValid = false,
                Message = "This share link has been revoked."
            };
        }

        if (shareToken.ExpiresAt < DateTime.UtcNow)
        {
            return new ShareTokenValidationDto
            {
                IsValid = false,
                ExpiresAt = shareToken.ExpiresAt,
                Message = "This share link has expired."
            };
        }

        var payload = ReadPayload(shareToken.EncryptedPayload);
        var requiresPassword = payload.SecuritySettings.PasswordProtected
            && !string.IsNullOrWhiteSpace(payload.SecretSettings.PasswordHash);
        var requiresTwoFactorApproval = payload.SecuritySettings.RequiresTwoFactorApproval;
        var requiresVerificationCode = !requiresTwoFactorApproval
            && !string.IsNullOrWhiteSpace(payload.SecretSettings.VerificationCodeHash);

        return new ShareTokenValidationDto
        {
            IsValid = true,
            AccessLevel = shareToken.AccessLevel,
            ExpiresAt = shareToken.ExpiresAt,
            RequiresPassword = requiresPassword,
            RequiresVerificationCode = requiresVerificationCode,
            RequiresTwoFactorApproval = requiresTwoFactorApproval,
        };
    }

    private SharePayloadDto ReadPayload(string? encryptedPayload)
    {
        if (string.IsNullOrWhiteSpace(encryptedPayload))
        {
            return new SharePayloadDto();
        }

        try
        {
            var raw = _shareProtection.UnprotectPayload(encryptedPayload);
            return SharePayloadMapper.Deserialize(raw);
        }
        catch
        {
            return new SharePayloadDto();
        }
    }
}

