namespace MedVault.API.Features.Notifications.Infrastructure;

public sealed class PushNotificationsOptions
{
    public const string SectionName = "PushNotifications";

    public bool Enabled { get; set; }

    public string Provider { get; set; } = "FCM";

    public string? ProjectId { get; set; }

    public string? ServiceAccountJson { get; set; }

    public string? ServiceAccountFilePath { get; set; }

    public string AndroidChannelId { get; set; } = "medvault_alerts";
}

