using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Configuration.Application.Commands;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.Features.Configuration.Application.Queries;
using MedVault.API.Features.Configuration.Domain;

namespace MedVault.API.Features.Configuration.Application.Handlers;

public sealed class SaveNotificationPreferencesCommandHandler
    : ICommandHandler<SaveNotificationPreferencesCommand, NotificationPreferencesResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<SaveNotificationPreferencesCommandHandler> _logger;

    public SaveNotificationPreferencesCommandHandler(
        MedVaultDbContext db,
        ILogger<SaveNotificationPreferencesCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<NotificationPreferencesResponse> HandleAsync(
        SaveNotificationPreferencesCommand command, CancellationToken ct)
    {
        var data = command.Data;
        var existing = await _db.NotificationPreferences
            .FirstOrDefaultAsync(n => n.UserId == command.UserId, ct);
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == command.UserId, ct);

        var effectiveLanguage = NormalizeLanguage(
            data.Language
            ?? existing?.Language
            ?? user?.Language);
        var normalizedPushToken = NormalizePushDeviceToken(data.PushDeviceToken);

        if (existing is not null)
        {
            existing.PushEnabled = data.PushEnabled;
            if (data.PushDeviceToken is not null)
            {
                existing.PushDeviceToken = normalizedPushToken;
            }

            existing.Language = effectiveLanguage;
            existing.EmailEnabled = data.EmailEnabled ?? existing.EmailEnabled;
            existing.SecurityAlerts = data.SecurityAlerts ?? existing.SecurityAlerts;
            existing.DataSharingNotifications = data.DataSharingNotifications ?? existing.DataSharingNotifications;
            existing.QuietHoursStart = data.QuietHoursStart;
            existing.QuietHoursEnd = data.QuietHoursEnd;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            existing = new UserNotificationPreferenceEntity
            {
                Id = Guid.NewGuid(),
                UserId = command.UserId,
                PushEnabled = data.PushEnabled,
                PushDeviceToken = normalizedPushToken,
                Language = effectiveLanguage,
                EmailEnabled = data.EmailEnabled ?? true,
                SecurityAlerts = data.SecurityAlerts ?? true,
                DataSharingNotifications = data.DataSharingNotifications ?? true,
                QuietHoursStart = data.QuietHoursStart,
                QuietHoursEnd = data.QuietHoursEnd,
                CreatedAt = DateTime.UtcNow
            };
            _db.NotificationPreferences.Add(existing);
        }

        if (user is not null)
        {
            user.Language = effectiveLanguage;
            user.UpdatedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Saved notification preferences for user {UserId}. PushEnabled={PushEnabled}, Language={Language}",
            command.UserId,
            existing.PushEnabled,
            existing.Language);

        return new NotificationPreferencesResponse
        {
            Id = existing.Id,
            PushEnabled = existing.PushEnabled,
            HasPushDeviceToken = !string.IsNullOrWhiteSpace(existing.PushDeviceToken),
            Language = existing.Language,
            EmailEnabled = existing.EmailEnabled,
            SecurityAlerts = existing.SecurityAlerts,
            DataSharingNotifications = existing.DataSharingNotifications,
            QuietHoursStart = existing.QuietHoursStart,
            QuietHoursEnd = existing.QuietHoursEnd,
        };
    }

    private static string NormalizeLanguage(string? language)
    {
        if (string.IsNullOrWhiteSpace(language))
        {
            return "en";
        }

        var normalized = language.Trim().Replace('_', '-');
        var segments = normalized.Split('-', StringSplitOptions.RemoveEmptyEntries);
        if (segments.Length == 0)
        {
            return "en";
        }

        if (segments.Length == 1)
        {
            return segments[0].ToLowerInvariant();
        }

        return $"{segments[0].ToLowerInvariant()}-{segments[1].ToUpperInvariant()}";
    }

    private static string? NormalizePushDeviceToken(string? pushDeviceToken)
    {
        if (pushDeviceToken is null)
        {
            return null;
        }

        var normalized = pushDeviceToken.Trim();
        return normalized.Length == 0
            ? null
            : normalized;
    }
}

public sealed class EnableCloudSyncCommandHandler
    : ICommandHandler<EnableCloudSyncCommand, CloudSyncResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<EnableCloudSyncCommandHandler> _logger;

    public EnableCloudSyncCommandHandler(MedVaultDbContext db, ILogger<EnableCloudSyncCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<CloudSyncResponse> HandleAsync(EnableCloudSyncCommand command, CancellationToken ct)
    {
        var data = command.Data;
        var existing = await _db.BackupMetadata
            .FirstOrDefaultAsync(b => b.UserId == command.UserId && b.Provider == data.Provider, ct);

        if (existing is not null)
        {
            existing.AutoBackupEnabled = data.AutoBackupEnabled;
            existing.UpdatedAt = DateTime.UtcNow;
            existing.Status = "Active";
        }
        else
        {
            existing = new BackupMetadataEntity
            {
                Id = Guid.NewGuid(),
                UserId = command.UserId,
                BackupType = "CloudSync",
                Provider = data.Provider,
                AutoBackupEnabled = data.AutoBackupEnabled,
                Status = "Active",
                CreatedAt = DateTime.UtcNow
            };
            _db.BackupMetadata.Add(existing);
        }

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Cloud sync configured for user {UserId}: provider={Provider}",
            command.UserId, data.Provider);

        return new CloudSyncResponse
        {
            BackupId = existing.Id,
            Provider = existing.Provider ?? data.Provider,
            AutoBackupEnabled = existing.AutoBackupEnabled,
            Status = existing.Status ?? "Active",
            CreatedAt = existing.CreatedAt
        };
    }
}

public sealed class GetConfigurationStatusQueryHandler
    : IQueryHandler<GetConfigurationStatusQuery, ConfigurationStatusResponse>
{
    private readonly MedVaultDbContext _db;

    public GetConfigurationStatusQueryHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<ConfigurationStatusResponse> HandleAsync(GetConfigurationStatusQuery query, CancellationToken ct)
    {
        var notifications = await _db.NotificationPreferences
            .AnyAsync(n => n.UserId == query.UserId, ct);

        var cloudSync = await _db.BackupMetadata
            .AnyAsync(b => b.UserId == query.UserId && b.Status == "Active", ct);

        var medicalInfo = false;

        int completed = (notifications ? 1 : 0) + (cloudSync ? 1 : 0) + (medicalInfo ? 1 : 0);
        const int total = 3;

        return new ConfigurationStatusResponse
        {
            NotificationsConfigured = notifications,
            CloudSyncConfigured = cloudSync,
            MedicalInfoProvided = medicalInfo,
            CompletedSteps = completed,
            TotalSteps = total,
            AllComplete = completed == total
        };
    }
}

public sealed class GetNotificationPreferencesQueryHandler
    : IQueryHandler<GetNotificationPreferencesQuery, NotificationPreferencesResponse?>
{
    private readonly MedVaultDbContext _db;

    public GetNotificationPreferencesQueryHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<NotificationPreferencesResponse?> HandleAsync(
        GetNotificationPreferencesQuery query, CancellationToken ct)
    {
        var entity = await _db.NotificationPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(n => n.UserId == query.UserId, ct);

        if (entity is null) return null;

        var language = entity.Language
            ?? await _db.Users
                .AsNoTracking()
                .Where(u => u.Id == query.UserId)
                .Select(u => u.Language)
                .FirstOrDefaultAsync(ct)
            ?? "en";

        return new NotificationPreferencesResponse
        {
            Id = entity.Id,
            PushEnabled = entity.PushEnabled,
            HasPushDeviceToken = !string.IsNullOrWhiteSpace(entity.PushDeviceToken),
            Language = language,
            EmailEnabled = entity.EmailEnabled,
            SecurityAlerts = entity.SecurityAlerts,
            DataSharingNotifications = entity.DataSharingNotifications,
            QuietHoursStart = entity.QuietHoursStart,
            QuietHoursEnd = entity.QuietHoursEnd,
        };
    }

}

