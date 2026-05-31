namespace MedVault.API.Features.Configuration.Application.DTOs;

public sealed record SaveNotificationPreferencesRequest
{
    public bool PushEnabled { get; init; } = true;
    public string? PushDeviceToken { get; init; }
    public string? Language { get; init; }
    public bool? EmailEnabled { get; init; }
    public bool? SecurityAlerts { get; init; }
    public bool? DataSharingNotifications { get; init; }
    public TimeOnly? QuietHoursStart { get; init; }
    public TimeOnly? QuietHoursEnd { get; init; }
}

public sealed record NotificationPreferencesResponse
{
    public Guid Id { get; init; }
    public bool PushEnabled { get; init; }
    public bool HasPushDeviceToken { get; init; }
    public string? Language { get; init; }
    public bool EmailEnabled { get; init; }
    public bool SecurityAlerts { get; init; }
    public bool DataSharingNotifications { get; init; }
    public TimeOnly? QuietHoursStart { get; init; }
    public TimeOnly? QuietHoursEnd { get; init; }
}

public sealed record EnableCloudSyncRequest
{
    public string Provider { get; init; } = "MedVault";
    public bool AutoBackupEnabled { get; init; }
}

public sealed record CloudSyncResponse
{
    public Guid BackupId { get; init; }
    public string Provider { get; init; } = default!;
    public bool AutoBackupEnabled { get; init; }
    public string Status { get; init; } = default!;
    public DateTime CreatedAt { get; init; }
}

public sealed record ConfigurationStatusResponse
{
    public bool NotificationsConfigured { get; init; }
    public bool CloudSyncConfigured { get; init; }
    public bool MedicalInfoProvided { get; init; }
    public int CompletedSteps { get; init; }
    public int TotalSteps { get; init; }
    public bool AllComplete { get; init; }
}

