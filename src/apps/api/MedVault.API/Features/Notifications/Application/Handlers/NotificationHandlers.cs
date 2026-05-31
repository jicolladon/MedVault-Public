using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Localization;
using MedVault.API.Data;
using MedVault.API.Features.Notifications.Application.Commands;
using MedVault.API.Features.Notifications.Application.DTOs;
using MedVault.API.Features.Notifications.Application.Queries;
using MedVault.API.Features.Notifications.Domain;
using System.Globalization;

namespace MedVault.API.Features.Notifications.Application.Handlers;

public sealed class GetNotificationsQueryHandler
    : IQueryHandler<GetNotificationsQuery, IReadOnlyList<NotificationItemResponse>>
{
    private readonly MedVaultDbContext _db;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public GetNotificationsQueryHandler(
        MedVaultDbContext db,
        IStringLocalizer<SharedResource> localizer)
    {
        _db = db;
        _localizer = localizer;
    }

    public async Task<IReadOnlyList<NotificationItemResponse>> HandleAsync(
        GetNotificationsQuery query,
        CancellationToken ct)
    {
        var items = await _db.UserNotifications
            .AsNoTracking()
            .Where(n => n.UserId == query.UserId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync(ct);

        var preferredLanguage = await ResolvePreferredLanguage(query.UserId, ct);
        var unreadCount = items.Count(n => !n.ReadAt.HasValue);

        return items
            .Select(item => NotificationResponseMapper.Map(item, preferredLanguage, unreadCount, _localizer))
            .ToList();
    }

    private async Task<string> ResolvePreferredLanguage(Guid userId, CancellationToken ct)
    {
        var languageFromPreferences = await _db.NotificationPreferences
            .AsNoTracking()
            .Where(n => n.UserId == userId)
            .Select(n => n.Language)
            .FirstOrDefaultAsync(ct);

        if (languageFromPreferences is not null)
        {
            return NotificationResponseMapper.NormalizeLanguage(languageFromPreferences);
        }

        var languageFromProfile = await _db.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.Language)
            .FirstOrDefaultAsync(ct);

        return NotificationResponseMapper.NormalizeLanguage(
            languageFromPreferences ?? languageFromProfile);
    }
}

public sealed class MarkNotificationAsReadCommandHandler
    : ICommandHandler<MarkNotificationAsReadCommand, NotificationItemResponse?>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<MarkNotificationAsReadCommandHandler> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public MarkNotificationAsReadCommandHandler(
        MedVaultDbContext db,
        ILogger<MarkNotificationAsReadCommandHandler> logger,
        IStringLocalizer<SharedResource> localizer)
    {
        _db = db;
        _logger = logger;
        _localizer = localizer;
    }

    public async Task<NotificationItemResponse?> HandleAsync(
        MarkNotificationAsReadCommand command,
        CancellationToken ct)
    {
        var entity = await _db.UserNotifications
            .FirstOrDefaultAsync(
                n => n.UserId == command.UserId && n.Id == command.NotificationId,
                ct);

        if (entity is null)
        {
            _logger.LogWarning(
                "Notification {NotificationId} not found for user {UserId}",
                command.NotificationId,
                command.UserId);
            return null;
        }

        if (!entity.ReadAt.HasValue)
        {
            entity.ReadAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
            _logger.LogInformation(
                "Notification {NotificationId} marked as read for user {UserId}",
                entity.Id,
                command.UserId);
        }

        var preferredLanguage = await ResolvePreferredLanguage(command.UserId, ct);
        var unreadCount = await _db.UserNotifications
            .AsNoTracking()
            .CountAsync(n => n.UserId == command.UserId && !n.ReadAt.HasValue, ct);

        return NotificationResponseMapper.Map(entity, preferredLanguage, unreadCount, _localizer);
    }

    private async Task<string> ResolvePreferredLanguage(Guid userId, CancellationToken ct)
    {
        var languageFromPreferences = await _db.NotificationPreferences
            .AsNoTracking()
            .Where(n => n.UserId == userId)
            .Select(n => n.Language)
            .FirstOrDefaultAsync(ct);

        if (languageFromPreferences is not null)
        {
            return NotificationResponseMapper.NormalizeLanguage(languageFromPreferences);
        }

        var languageFromProfile = await _db.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.Language)
            .FirstOrDefaultAsync(ct);

        return NotificationResponseMapper.NormalizeLanguage(
            languageFromPreferences ?? languageFromProfile);
    }
}

public sealed class MarkAllNotificationsAsReadCommandHandler
    : ICommandHandler<MarkAllNotificationsAsReadCommand, MarkAllNotificationsAsReadResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<MarkAllNotificationsAsReadCommandHandler> _logger;

    public MarkAllNotificationsAsReadCommandHandler(
        MedVaultDbContext db,
        ILogger<MarkAllNotificationsAsReadCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<MarkAllNotificationsAsReadResponse> HandleAsync(
        MarkAllNotificationsAsReadCommand command,
        CancellationToken ct)
    {
        var readAt = DateTime.UtcNow;
        var updatedCount = await _db.UserNotifications
            .Where(n => n.UserId == command.UserId && !n.ReadAt.HasValue)
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(n => n.ReadAt, _ => readAt),
                ct);

        if (updatedCount == 0)
        {
            return new MarkAllNotificationsAsReadResponse { UpdatedCount = 0 };
        }

        _logger.LogInformation(
            "Marked {Count} notifications as read for user {UserId}",
            updatedCount,
            command.UserId);

        return new MarkAllNotificationsAsReadResponse
        {
            UpdatedCount = updatedCount
        };
    }
}

public sealed class DeleteNotificationCommandHandler
    : ICommandHandler<DeleteNotificationCommand, bool>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<DeleteNotificationCommandHandler> _logger;

    public DeleteNotificationCommandHandler(
        MedVaultDbContext db,
        ILogger<DeleteNotificationCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<bool> HandleAsync(DeleteNotificationCommand command, CancellationToken ct)
    {
        var entity = await _db.UserNotifications
            .FirstOrDefaultAsync(
                n => n.UserId == command.UserId && n.Id == command.NotificationId,
                ct);

        if (entity is null)
        {
            _logger.LogWarning(
                "Notification {NotificationId} not found for delete by user {UserId}",
                command.NotificationId,
                command.UserId);
            return false;
        }

        _db.UserNotifications.Remove(entity);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Notification {NotificationId} deleted for user {UserId}",
            command.NotificationId,
            command.UserId);

        return true;
    }
}

internal static class NotificationResponseMapper
{
    public static NotificationItemResponse Map(
        UserNotificationEntity entity,
        string preferredLanguage,
        int unreadCount,
        IStringLocalizer<SharedResource> localizer)
    {
        var effectiveLanguage = NormalizeLanguage(entity.Language ?? preferredLanguage);
        var actorFallback = Localize(effectiveLanguage, localizer, "Notification.UnknownUser");
        var actor = string.IsNullOrWhiteSpace(entity.ActorName)
            ? actorFallback
            : entity.ActorName;

        var fallbackTitle = GetFallbackTitle(entity.Type, localizer, effectiveLanguage);
        var fallbackDescription = GetFallbackDescription(entity.Type, actor!, localizer, effectiveLanguage);
        var resolvedSubtitle = string.IsNullOrWhiteSpace(entity.Subtitle)
            ? null
            : entity.Subtitle.Replace(
                "{unreadCount}",
                unreadCount.ToString(CultureInfo.InvariantCulture),
                StringComparison.OrdinalIgnoreCase);

        return new NotificationItemResponse
        {
            Id = entity.Id,
            Type = entity.Type,
            Language = effectiveLanguage,
            Title = string.IsNullOrWhiteSpace(entity.Title) ? fallbackTitle : entity.Title,
            Subtitle = resolvedSubtitle,
            Description = string.IsNullOrWhiteSpace(entity.Description) ? fallbackDescription : entity.Description,
            ActorName = entity.ActorName,
            CreatedAt = entity.CreatedAt,
            ReadAt = entity.ReadAt,
            IsRead = entity.ReadAt.HasValue
        };
    }

    public static string NormalizeLanguage(string? language)
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

    private static string GetFallbackTitle(
        NotificationType type,
        IStringLocalizer<SharedResource> localizer,
        string language)
    {
        var key = type switch
        {
            NotificationType.EmergencyQrAccessed => "Notification.Title.EmergencyQrAccessed",
            NotificationType.ShareRequest => "Notification.Title.ShareRequest",
            NotificationType.ProfileUpdated => "Notification.Title.ProfileUpdated",
            NotificationType.ProviderAccess => "Notification.Title.ProviderAccess",
            NotificationType.MedicationReminder => "Notification.Title.MedicationReminder",
            NotificationType.AppointmentAlert => "Notification.Title.AppointmentAlert",
            NotificationType.SecurityAlert => "Notification.Title.SecurityAlert",
            NotificationType.RecordUpdated => "Notification.Title.RecordUpdated",
            _ => "Notification.Title.Default"
        };

        return Localize(language, localizer, key);
    }

    private static string GetFallbackDescription(
        NotificationType type,
        string actor,
        IStringLocalizer<SharedResource> localizer,
        string language)
    {
        return type switch
        {
            NotificationType.EmergencyQrAccessed => Localize(language, localizer, "Notification.Description.EmergencyQrAccessed"),
            NotificationType.ShareRequest => Localize(language, localizer, "Notification.Description.ShareRequest", actor),
            NotificationType.ProfileUpdated => Localize(language, localizer, "Notification.Description.ProfileUpdated"),
            NotificationType.ProviderAccess => Localize(language, localizer, "Notification.Description.ProviderAccess", actor),
            NotificationType.MedicationReminder => Localize(language, localizer, "Notification.Description.MedicationReminder"),
            NotificationType.AppointmentAlert => Localize(language, localizer, "Notification.Description.AppointmentAlert"),
            NotificationType.SecurityAlert => Localize(language, localizer, "Notification.Description.SecurityAlert"),
            NotificationType.RecordUpdated => Localize(language, localizer, "Notification.Description.RecordUpdated"),
            _ => Localize(language, localizer, "Notification.Description.Default")
        };
    }

    private static string Localize(
        string language,
        IStringLocalizer<SharedResource> localizer,
        string key,
        params object[] arguments)
    {
        var originalCulture = CultureInfo.CurrentCulture;
        var originalUiCulture = CultureInfo.CurrentUICulture;

        try
        {
            CultureInfo culture;
            try
            {
                culture = new CultureInfo(language);
            }
            catch (CultureNotFoundException)
            {
                culture = new CultureInfo("en");
            }

            CultureInfo.CurrentCulture = culture;
            CultureInfo.CurrentUICulture = culture;
            return localizer[key, arguments];
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
            CultureInfo.CurrentUICulture = originalUiCulture;
        }
    }
}

