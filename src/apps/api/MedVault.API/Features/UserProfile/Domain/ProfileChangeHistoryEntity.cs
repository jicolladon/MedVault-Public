using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.UserProfile.Domain;

public class ProfileChangeHistoryEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FieldName { get; set; } = null!;
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public Guid ChangedBy { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public AppUser User { get; set; } = null!;
}

