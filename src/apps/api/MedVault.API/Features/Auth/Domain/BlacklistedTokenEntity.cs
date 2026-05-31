namespace MedVault.API.Features.Auth.Domain;

public class BlacklistedTokenEntity
{
    public Guid Id { get; set; }
    public string Token { get; set; } = null!;
    public Guid UserId { get; set; }
    public DateTime BlacklistedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public string? Reason { get; set; }
    public AppUser User { get; set; } = null!;
}

