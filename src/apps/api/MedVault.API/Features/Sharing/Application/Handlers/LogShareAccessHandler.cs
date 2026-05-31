using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Localization;
using MedVault.API.Data;
using MedVault.API.Features.Notifications.Domain;
using MedVault.API.Features.Notifications.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Domain;
using System.Globalization;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public class LogShareAccessHandler : ICommandHandler<LogShareAccessCommand, bool>
{
    private const int MaxViewerNameLength = 120;
    private const int MaxIpLength = 50;
    private const int MaxUserAgentLength = 500;

    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;
    private readonly ILogger<LogShareAccessHandler> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;
    private readonly IPushNotificationSender _pushNotificationSender;

    public LogShareAccessHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        ILogger<LogShareAccessHandler> logger,
        IStringLocalizer<SharedResource> localizer,
        IPushNotificationSender pushNotificationSender)
    {
        _db = db;
        _shareProtection = shareProtection;
        _logger = logger;
        _localizer = localizer;
        _pushNotificationSender = pushNotificationSender;
    }

    public async Task<bool> HandleAsync(
        LogShareAccessCommand command, CancellationToken cancellationToken = default)
    {
        var tokenHash = _shareProtection.HashToken(command.Token);
        var shareToken = await _db.ShareTokens
            .Include(token => token.User)
            .FindByPublicTokenAsync(command.Token, tokenHash, cancellationToken);

        if (shareToken is null)
            return false;

        if (shareToken.IsRevoked || shareToken.ExpiresAt < DateTime.UtcNow)
            return false;

        var payload = TryReadPayload(shareToken.EncryptedPayload);
        var accessedAt = DateTime.UtcNow;

        var logEntry = new ShareAccessLogEntity
        {
            Id = Guid.NewGuid(),
            ShareTokenId = shareToken.Id,
            ViewerName = LimitLength(command.ViewerName, MaxViewerNameLength),
            ViewerIpAddress = LimitLength(command.IpAddress, MaxIpLength),
            ViewerUserAgent = LimitLength(command.UserAgent, MaxUserAgentLength),
            AccessedAt = accessedAt,
        };

        shareToken.AccessCount += 1;
        shareToken.LastAccessedAt = accessedAt;

        _db.ShareAccessLogs.Add(logEntry);

        try
        {
            await TryCreateShareAccessNotificationAsync(shareToken, payload, logEntry, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to dispatch share access notification for share {ShareId}; continuing with audit log persistence.",
                shareToken.Id);
        }

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Share link {ShareId} accessed from IP {IpAddress}",
            shareToken.Id,
            logEntry.ViewerIpAddress ?? "unknown");

        return true;
    }

    private async Task TryCreateShareAccessNotificationAsync(
        ShareTokenEntity shareToken,
        SharePayloadDto payload,
        ShareAccessLogEntity logEntry,
        CancellationToken cancellationToken)
    {
        if (!payload.SecuritySettings.NotifyOnAccess)
        {
            _logger.LogDebug(
                "Skipping access notification for share {ShareId} because notifyOnAccess is disabled.",
                shareToken.Id);
            return;
        }

        var preferences = await LoadPreferencesAsync(shareToken.UserId, shareToken.User.Language, cancellationToken);
        var isEmergency = shareToken.ShareType.Equals("Emergency", StringComparison.OrdinalIgnoreCase);

        if (!preferences.DataSharingNotifications)
        {
            _logger.LogDebug(
                "Skipping access notification for share {ShareId} because data-sharing notifications are disabled for user {UserId}.",
                shareToken.Id,
                shareToken.UserId);
            return;
        }

        if (isEmergency && !preferences.SecurityAlerts)
        {
            _logger.LogDebug(
                "Skipping emergency access notification for share {ShareId} because security alerts are disabled for user {UserId}.",
                shareToken.Id,
                shareToken.UserId);
            return;
        }

        var unreadCount = await _db.UserNotifications
            .AsNoTracking()
            .CountAsync(
                n => n.UserId == shareToken.UserId && !n.ReadAt.HasValue,
                cancellationToken);

        var actorName = logEntry.ViewerName;
        var type = isEmergency
            ? NotificationType.EmergencyQrAccessed
            : NotificationType.ProviderAccess;

        string title;
        string description;
        string subtitle;
        var originalCulture = CultureInfo.CurrentCulture;
        var originalUiCulture = CultureInfo.CurrentUICulture;
        try
        {
            var culture = new CultureInfo(preferences.Language);
            CultureInfo.CurrentCulture = culture;
            CultureInfo.CurrentUICulture = culture;

            title = isEmergency
                ? _localizer["Notification.Title.EmergencyQrAccessed"]
                : _localizer["Notification.Title.ProviderAccess"];
            var ipLabel = string.IsNullOrWhiteSpace(logEntry.ViewerIpAddress)
                ? _localizer["ShareAccess.UnknownIp"]
                : logEntry.ViewerIpAddress;
            var deviceLabel = ResolveDeviceLabel(
                logEntry.ViewerUserAgent,
                _localizer["ShareAccess.UnknownDevice"]);
            var viewerLabel = string.IsNullOrWhiteSpace(logEntry.ViewerName)
                ? _localizer["ShareAccess.UnknownViewer"]
                : logEntry.ViewerName;
            var accessTimeLabel = logEntry.AccessedAt.ToString("u", culture);
            description = _localizer["ShareAccess.Description", viewerLabel, accessTimeLabel, ipLabel, deviceLabel];
        }
        catch (CultureNotFoundException)
        {
            title = isEmergency
                ? _localizer["Notification.Title.EmergencyQrAccessed"]
                : _localizer["Notification.Title.ProviderAccess"];
            var ipLabel = string.IsNullOrWhiteSpace(logEntry.ViewerIpAddress)
                ? _localizer["ShareAccess.UnknownIp"]
                : logEntry.ViewerIpAddress;
            var deviceLabel = ResolveDeviceLabel(
                logEntry.ViewerUserAgent,
                _localizer["ShareAccess.UnknownDevice"]);
            var viewerLabel = string.IsNullOrWhiteSpace(logEntry.ViewerName)
                ? _localizer["ShareAccess.UnknownViewer"]
                : logEntry.ViewerName;
            description = _localizer[
                "ShareAccess.Description",
                viewerLabel,
                logEntry.AccessedAt.ToString("u"),
                ipLabel,
                deviceLabel];
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
            CultureInfo.CurrentUICulture = originalUiCulture;
        }

        _db.UserNotifications.Add(new UserNotificationEntity
        {
            Id = Guid.NewGuid(),
            UserId = shareToken.UserId,
            Type = type,
            Language = preferences.Language,
            Title = title,
            Description = description,
            ActorName = actorName,
            CreatedAt = logEntry.AccessedAt,
        });

        var inQuietHours = IsWithinQuietHours(preferences.QuietHoursStart, preferences.QuietHoursEnd, logEntry.AccessedAt);
        if (inQuietHours)
        {
            _logger.LogInformation(
                "Share access alert for user {UserId} stored in-app but external delivery deferred due to quiet hours.",
                shareToken.UserId);
            return;
        }

        if (preferences.PushEnabled)
        {
            if (string.IsNullOrWhiteSpace(preferences.PushDeviceToken))
            {
                _logger.LogInformation(
                    "Push alert skipped for user {UserId}: no device token is registered.",
                    shareToken.UserId);
            }
            else
            {
                var pushResult = await _pushNotificationSender.SendAsync(
                    new PushNotificationDispatchRequest(
                        DeviceToken: preferences.PushDeviceToken,
                        Title: title,
                        Body: description,
                        Language: preferences.Language,
                        Data: new Dictionary<string, string>
                        {
                            ["eventType"] = type.ToString(),
                            ["shareTokenId"] = shareToken.Id.ToString(),
                            ["accessedAt"] = logEntry.AccessedAt.ToString("O", CultureInfo.InvariantCulture),
                            ["viewerName"] = actorName ?? string.Empty,
                        }),
                    cancellationToken);

                if (pushResult.Delivered)
                {
                    _logger.LogInformation(
                        "Push alert delivered for user {UserId}. ProviderMessageId={ProviderMessageId}",
                        shareToken.UserId,
                        pushResult.ProviderMessageId);
                }
                else
                {
                    _logger.LogWarning(
                        "Push alert failed for user {UserId}. Reason={Reason}",
                        shareToken.UserId,
                        pushResult.FailureReason ?? "unknown");
                }
            }
        }

        if (preferences.EmailEnabled)
        {
            _logger.LogInformation(
                "Email dispatch placeholder: share access alert for user {UserId} (share {ShareId}).",
                shareToken.UserId,
                shareToken.Id);
        }

        if (!preferences.PushEnabled && !preferences.EmailEnabled)
        {
            _logger.LogInformation(
                "Share access alert for user {UserId} stored in-app only because all external channels are disabled.",
                shareToken.UserId);
        }
    }

    private async Task<EffectivePreferences> LoadPreferencesAsync(
        Guid userId,
        string? fallbackLanguage,
        CancellationToken cancellationToken)
    {
        var preferences = await _db.NotificationPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.UserId == userId, cancellationToken);

        var language = NormalizeLanguage(preferences?.Language ?? fallbackLanguage);

        if (preferences is null)
        {
            return new EffectivePreferences(
                PushEnabled: true,
                PushDeviceToken: null,
                EmailEnabled: true,
                SecurityAlerts: true,
                DataSharingNotifications: true,
                QuietHoursStart: null,
                QuietHoursEnd: null,
                Language: language);
        }

        return new EffectivePreferences(
            PushEnabled: preferences.PushEnabled,
            PushDeviceToken: string.IsNullOrWhiteSpace(preferences.PushDeviceToken)
                ? null
                : preferences.PushDeviceToken,
            EmailEnabled: preferences.EmailEnabled,
            SecurityAlerts: preferences.SecurityAlerts,
            DataSharingNotifications: preferences.DataSharingNotifications,
            QuietHoursStart: preferences.QuietHoursStart,
            QuietHoursEnd: preferences.QuietHoursEnd,
            Language: language);
    }

    private SharePayloadDto TryReadPayload(string? encryptedPayload)
    {
        if (string.IsNullOrWhiteSpace(encryptedPayload))
        {
            return new SharePayloadDto();
        }

        try
        {
            var payloadRaw = _shareProtection.UnprotectPayload(encryptedPayload);
            return SharePayloadMapper.Deserialize(payloadRaw);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to decrypt sharing payload while logging access event.");
            return new SharePayloadDto();
        }
    }

    private static bool IsWithinQuietHours(TimeOnly? start, TimeOnly? end, DateTime timestamp)
    {
        if (start is null || end is null)
        {
            return false;
        }

        var time = TimeOnly.FromDateTime(timestamp);
        if (start == end)
        {
            return false;
        }

        if (start < end)
        {
            return time >= start && time < end;
        }

        return time >= start || time < end;
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

    private static string? LimitLength(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= maxLength
            ? trimmed
            : trimmed[..maxLength];
    }

    private static string ResolveDeviceLabel(string? userAgent, string fallback)
    {
        var normalizedUserAgent = LimitLength(userAgent, MaxUserAgentLength);
        if (string.IsNullOrWhiteSpace(normalizedUserAgent))
        {
            return fallback;
        }

        var ua = normalizedUserAgent.ToLowerInvariant();

        var operatingSystem = ua switch
        {
            _ when ua.Contains("android") => "Android",
            _ when ua.Contains("iphone") || ua.Contains("ipad") || ua.Contains("ios") => "iOS",
            _ when ua.Contains("windows") => "Windows",
            _ when ua.Contains("mac os x") || ua.Contains("macintosh") => "macOS",
            _ when ua.Contains("linux") => "Linux",
            _ => null,
        };

        var browser = ua switch
        {
            _ when ua.Contains("edg/") => "Edge",
            _ when ua.Contains("chrome/") && !ua.Contains("edg/") => "Chrome",
            _ when ua.Contains("firefox/") => "Firefox",
            _ when ua.Contains("safari/") && !ua.Contains("chrome/") => "Safari",
            _ => null,
        };

        if (!string.IsNullOrWhiteSpace(operatingSystem) && !string.IsNullOrWhiteSpace(browser))
        {
            return $"{operatingSystem} / {browser}";
        }

        if (!string.IsNullOrWhiteSpace(operatingSystem))
        {
            return operatingSystem;
        }

        if (!string.IsNullOrWhiteSpace(browser))
        {
            return browser;
        }

        return normalizedUserAgent;
    }

    private sealed record EffectivePreferences(
        bool PushEnabled,
        string? PushDeviceToken,
        bool EmailEnabled,
        bool SecurityAlerts,
        bool DataSharingNotifications,
        TimeOnly? QuietHoursStart,
        TimeOnly? QuietHoursEnd,
        string Language);
}

