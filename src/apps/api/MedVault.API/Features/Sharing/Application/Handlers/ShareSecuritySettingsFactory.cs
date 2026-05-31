using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;

namespace MedVault.API.Features.Sharing.Application.Handlers;

internal static class ShareSecuritySettingsFactory
{
    public static SharePayloadDto ApplyProtectedSecrets(
        SharePayloadDto nextPayload,
        SharePayloadDto? currentPayload,
        IShareProtectionService shareProtection)
    {
        var settings = nextPayload.SecuritySettings;
        var currentSecrets = currentPayload?.SecretSettings ?? new ShareSecretSettingsDto();

        var passwordHash = ResolveHash(
            settings.PasswordProtected,
            settings.AccessPassword,
            currentSecrets.PasswordHash,
            shareProtection);

        var verificationCodeHash = ResolveHash(
            settings.RequiresTwoFactorApproval,
            settings.VerificationCode,
            currentSecrets.VerificationCodeHash,
            shareProtection);

        return nextPayload with
        {
            SecuritySettings = SharePayloadMapper.SanitizeSecuritySettings(settings),
            SecretSettings = new ShareSecretSettingsDto
            {
                PasswordHash = passwordHash,
                VerificationCodeHash = verificationCodeHash,
            },
        };
    }

    private static string? ResolveHash(
        bool protectionEnabled,
        string? providedSecret,
        string? existingHash,
        IShareProtectionService shareProtection)
    {
        if (!protectionEnabled)
        {
            return null;
        }

        if (!string.IsNullOrWhiteSpace(providedSecret))
        {
            return shareProtection.HashSecret(providedSecret.Trim());
        }

        return existingHash;
    }
}

