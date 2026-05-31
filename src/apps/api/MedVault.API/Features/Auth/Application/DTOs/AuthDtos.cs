using MedVault.API.Features.Shared.Domain;

namespace MedVault.API.Features.Auth.Application.DTOs;

public record GoogleLoginRequest(string IdToken);

public record GoogleLoginResponse(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpiresAt,
    UserSummaryDto User,
    bool IsNewUser
);

public record RegisterRequest(
    string GoogleIdToken,
    string FirstName,
    string LastName,
    DateTime? DateOfBirth,
    Gender? Gender,
    string? PhoneNumber,
    string? Address,
    string? City,
    string? State,
    string? ZipCode,
    string? Country,
    bool TermsAccepted,
    bool PrivacyPolicyAccepted
);

public record RegisterResponse(
    UserSummaryDto User
);

public record RefreshTokenRequest(string RefreshToken);

public record EmailRegisterRequest(
    string Email,
    string Password,
    string FirstName,
    string LastName,
    bool TermsAccepted,
    bool PrivacyPolicyAccepted,
    string CodeChallenge,
    string CodeChallengeMethod = "S256"
);

public record EmailLoginRequest(
    string Email,
    string Password,
    string CodeChallenge,
    string CodeChallengeMethod = "S256"
);

public record PkceAuthorizationCodeRequest(
    string AuthorizationCode,
    string CodeVerifier
);

public record PkceAuthorizationCodeResponse(
    string AuthorizationCode,
    int ExpiresInSeconds,
    bool IsNewUser
);

public record PkceTokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpiresAt,
    UserSummaryDto User
);

public record RefreshTokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpiresAt
);

public record UserSummaryDto(
    Guid Id,
    string Email,
    string? FirstName,
    string? LastName,
    string? ProfilePictureUrl,
    int ProfileCompleteness
);

public record SessionStatusDto(
    Guid SessionId,
    Guid UserId,
    DateTime CreatedAt,
    DateTime ExpiresAt,
    bool IsActive,
    string? DeviceInfo
);

