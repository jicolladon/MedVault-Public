namespace MedVault.ConsoleClient.Models;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string>? Errors { get; set; }
}

public record GoogleLoginResponse(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpiresAt,
    UserSummaryDto User,
    bool IsNewUser
);

public record RegisterResponse(
    UserSummaryDto User
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
