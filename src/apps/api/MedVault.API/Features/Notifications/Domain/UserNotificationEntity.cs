using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Notifications.Domain;

public enum NotificationType
{
    EmergencyQrAccessed,
    ShareRequest,
    ProfileUpdated,
    ProviderAccess,
    MedicationReminder,
    AppointmentAlert,
    SecurityAlert,
    RecordUpdated
}

public class UserNotificationEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public NotificationType Type { get; set; }
    public string? Language { get; set; }
    public string? Title { get; set; }
    public string? Subtitle { get; set; }
    public string? Description { get; set; }
    public string? ActorName { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }

    public AppUser User { get; set; } = null!;
}

