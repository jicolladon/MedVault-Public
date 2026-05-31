namespace MedVault.API.Features.Auth.Domain;

public class UserSessionEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string SessionToken { get; set; } = null!;
    public string? DeviceInfo { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastActivityAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public bool IsRememberMe { get; set; }
    public bool IsActive { get; set; } = true;
    public AppUser User { get; set; } = null!;
}

