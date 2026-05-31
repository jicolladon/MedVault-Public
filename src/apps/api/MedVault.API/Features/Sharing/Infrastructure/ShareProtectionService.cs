using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.WebUtilities;
using MedVault.API.Features.Sharing.Application.Interfaces;

namespace MedVault.API.Features.Sharing.Infrastructure;

public sealed class ShareProtectionService : IShareProtectionService
{
    private const string SecretHashVersion = "PBKDF2-SHA256-v1";
    private const int SecretSaltSize = 16;
    private const int SecretKeySize = 32;
    private const int SecretIterations = 120_000;

    private readonly IDataProtector _payloadProtector;

    public ShareProtectionService(IDataProtectionProvider dataProtectionProvider)
    {
        _payloadProtector = dataProtectionProvider.CreateProtector("MedVault.Sharing.Payload.v1");
    }

    public string GenerateProtectedToken(Guid shareId)
    {
        _ = shareId;
        var tokenBytes = RandomNumberGenerator.GetBytes(16);
        return WebEncoders.Base64UrlEncode(tokenBytes);
    }

    public string HashToken(string token)
    {
        var tokenBytes = Encoding.UTF8.GetBytes(token);
        var hashBytes = SHA256.HashData(tokenBytes);
        return Convert.ToHexString(hashBytes);
    }

    public string HashSecret(string secret)
    {
        if (string.IsNullOrWhiteSpace(secret))
        {
            throw new ArgumentException("Secret cannot be empty.", nameof(secret));
        }

        var salt = RandomNumberGenerator.GetBytes(SecretSaltSize);
        var secretBytes = Encoding.UTF8.GetBytes(secret);
        var hash = Rfc2898DeriveBytes.Pbkdf2(secretBytes, salt, SecretIterations, HashAlgorithmName.SHA256, SecretKeySize);

        return string.Join(
            '$',
            SecretHashVersion,
            SecretIterations,
            Convert.ToBase64String(salt),
            Convert.ToBase64String(hash));
    }

    public bool VerifySecret(string secret, string hashedSecret)
    {
        if (string.IsNullOrWhiteSpace(secret) || string.IsNullOrWhiteSpace(hashedSecret))
        {
            return false;
        }

        var parts = hashedSecret.Split('$', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length != 4 || !string.Equals(parts[0], SecretHashVersion, StringComparison.Ordinal))
        {
            return false;
        }

        if (!int.TryParse(parts[1], out var iterations) || iterations <= 0)
        {
            return false;
        }

        try
        {
            var salt = Convert.FromBase64String(parts[2]);
            var expectedHash = Convert.FromBase64String(parts[3]);
            var secretBytes = Encoding.UTF8.GetBytes(secret);
            var candidateHash = Rfc2898DeriveBytes.Pbkdf2(secretBytes, salt, iterations, HashAlgorithmName.SHA256, expectedHash.Length);
            return CryptographicOperations.FixedTimeEquals(candidateHash, expectedHash);
        }
        catch (FormatException)
        {
            return false;
        }
    }

    public string ProtectPayload(string payloadJson)
    {
        return _payloadProtector.Protect(payloadJson);
    }

    public string UnprotectPayload(string encryptedPayload)
    {
        return _payloadProtector.Unprotect(encryptedPayload);
    }
}

