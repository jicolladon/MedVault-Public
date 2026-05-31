namespace MedVault.API.Features.Auth.Application.Interfaces;

public record PkceAuthorizationCodeRecord(
    Guid UserId,
    string CodeChallenge,
    string CodeChallengeMethod,
    string? IpAddress,
    string? UserAgent,
    bool IsNewUser
);

public interface IPkceAuthorizationCodeStore
{
    string CreateCode(PkceAuthorizationCodeRecord record);
    bool TryRedeemCode(string authorizationCode, out PkceAuthorizationCodeRecord? record);
}

