namespace MedVault.API.Features.Sharing.Application.Interfaces;

public interface IShareProtectionService
{
    string GenerateProtectedToken(Guid shareId);

    string HashToken(string token);

    string HashSecret(string secret);

    bool VerifySecret(string secret, string hashedSecret);

    string ProtectPayload(string payloadJson);

    string UnprotectPayload(string encryptedPayload);
}

