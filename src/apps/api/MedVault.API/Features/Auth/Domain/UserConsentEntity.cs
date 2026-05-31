namespace MedVault.API.Features.Auth.Domain;

public class UserConsentEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ConsentType { get; set; } = null!;
    public bool ConsentGiven { get; set; }
    public DateTime ConsentDate { get; set; } = DateTime.UtcNow;
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? ConsentVersion { get; set; }
    public AppUser User { get; set; } = null!;
}

