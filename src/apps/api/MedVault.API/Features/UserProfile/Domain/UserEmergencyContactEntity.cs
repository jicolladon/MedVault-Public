using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.UserProfile.Domain;

public class UserEmergencyContactEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ContactId { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Relationship { get; set; } = default!;
    public string Phone { get; set; } = default!;
    public string? Email { get; set; }
    public bool IsPrimary { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public AppUser User { get; set; } = default!;
}
