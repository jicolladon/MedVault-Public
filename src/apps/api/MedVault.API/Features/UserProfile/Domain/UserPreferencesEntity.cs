using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.UserProfile.Domain;

public class UserPreferencesEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string? PrivacyLevel { get; set; }
    public bool DataSharingConsent { get; set; }
    public string? NotificationPreferences { get; set; }
    public string? DisplayPreferences { get; set; }
    public AppUser User { get; set; } = null!;
}

