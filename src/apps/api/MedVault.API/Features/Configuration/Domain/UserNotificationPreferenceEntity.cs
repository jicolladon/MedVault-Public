using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Configuration.Domain;

public class UserNotificationPreferenceEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public bool PushEnabled { get; set; } = true;
    public string? PushDeviceToken { get; set; }
    public string? Language { get; set; }
    public bool EmailEnabled { get; set; } = true;
    public bool SecurityAlerts { get; set; } = true;
    public bool DataSharingNotifications { get; set; } = true;
    public TimeOnly? QuietHoursStart { get; set; }
    public TimeOnly? QuietHoursEnd { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public AppUser User { get; set; } = null!;
}

