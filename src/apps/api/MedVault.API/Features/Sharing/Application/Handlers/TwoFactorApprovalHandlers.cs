using System.Globalization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Localization;
using MedVault.API.Data;
using MedVault.API.Features.Notifications.Application.Interfaces;
using MedVault.API.Features.Notifications.Domain;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Queries;
using MedVault.API.Features.Sharing.Domain;
using MedVault.API.Features.Sharing.Hubs;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class RequestTwoFactorApprovalHandler
    : ICommandHandler<RequestTwoFactorApprovalCommand, TwoFactorApprovalRequestResponse>
{
    private static readonly TimeSpan ApprovalLifetime = TimeSpan.FromMinutes(5);

    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;
    private readonly IPushNotificationSender _pushNotificationSender;
    private readonly IHubContext<SharingSyncHub> _sharingHub;
    private readonly IStringLocalizer<SharedResource> _localizer;
    private readonly ILogger<RequestTwoFactorApprovalHandler> _logger;

    public RequestTwoFactorApprovalHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        IPushNotificationSender pushNotificationSender,
        IHubContext<SharingSyncHub> sharingHub,
        IStringLocalizer<SharedResource> localizer,
        ILogger<RequestTwoFactorApprovalHandler> logger)
    {
        _db = db;
        _shareProtection = shareProtection;
        _pushNotificationSender = pushNotificationSender;
        _sharingHub = sharingHub;
        _localizer = localizer;
        _logger = logger;
    }

    public async Task<TwoFactorApprovalRequestResponse> HandleAsync(
        RequestTwoFactorApprovalCommand command,
        CancellationToken cancellationToken = default)
    {
        var shareToken = await ResolveShareTokenAsync(command.Token, cancellationToken);
        var payload = ReadPayload(shareToken.EncryptedPayload);

        if (!payload.SecuritySettings.RequiresTwoFactorApproval)
        {
            throw new InvalidOperationException("This share link does not require two-factor approval.");
        }

        EnforcePasswordProtection(payload, command.AccessPassword);

        var viewerName = LimitLength(command.ViewerName, 120)
            ?? throw new InvalidOperationException("Viewer name is required.");
        var now = DateTime.UtcNow;

        await _db.ShareAccessApprovalRequests
            .Where(request => request.ShareTokenId == shareToken.Id
                && request.Status == ShareAccessApprovalStatus.Pending)
            .ExecuteUpdateAsync(
                setters => setters
                    .SetProperty(request => request.Status, ShareAccessApprovalStatus.Expired)
                    .SetProperty(request => request.DecisionAt, _ => now),
                cancellationToken);

        var approvalCode = GenerateApprovalCode();
        var requestEntity = new ShareAccessApprovalRequestEntity
        {
            Id = Guid.NewGuid(),
            ShareTokenId = shareToken.Id,
            ViewerName = viewerName,
            ViewerIpAddress = LimitLength(command.IpAddress, 50),
            ViewerUserAgent = LimitLength(command.UserAgent, 500),
            ApprovalCodeHash = _shareProtection.HashSecret(approvalCode),
            ApprovalCodeHint = BuildCodeHint(approvalCode),
            Status = ShareAccessApprovalStatus.Pending,
            RequestedAt = now,
            ExpiresAt = now.Add(ApprovalLifetime),
        };

        _db.ShareAccessApprovalRequests.Add(requestEntity);

        await TryCreateOwnerNotificationAsync(
            shareToken,
            requestEntity,
            cancellationToken);

        await _db.SaveChangesAsync(cancellationToken);

        await _sharingHub.Clients
            .Group(BuildShareGroup(shareToken.Token))
            .SendAsync(
                "TwoFactorStatusChanged",
                new
                {
                    requestId = requestEntity.Id,
                    status = ShareApprovalStatusMapper.ToWire(requestEntity.Status),
                    viewerName = requestEntity.ViewerName,
                    expiresAt = requestEntity.ExpiresAt,
                },
                cancellationToken);

        _logger.LogInformation(
            "Created 2FV access approval request {RequestId} for share {ShareId}.",
            requestEntity.Id,
            shareToken.Id);

        return new TwoFactorApprovalRequestResponse
        {
            RequestId = requestEntity.Id,
            ShareLinkId = shareToken.Id,
            ViewerName = requestEntity.ViewerName,
            RequestedAt = requestEntity.RequestedAt,
            ExpiresAt = requestEntity.ExpiresAt,
            Status = ShareApprovalStatusMapper.ToWire(requestEntity.Status),
        };
    }

    private async Task<ShareTokenEntity> ResolveShareTokenAsync(string token, CancellationToken cancellationToken)
    {
        var tokenHash = _shareProtection.HashToken(token);
        var shareToken = await _db.ShareTokens
            .Include(entry => entry.User)
            .FindByPublicTokenAsync(token, tokenHash, cancellationToken)
            ?? throw new KeyNotFoundException("Share token not found.");

        if (shareToken.IsRevoked)
        {
            throw new InvalidOperationException("This share link has been revoked.");
        }

        if (shareToken.ExpiresAt < DateTime.UtcNow)
        {
            throw new InvalidOperationException("This share link has expired.");
        }

        return shareToken;
    }

    private static string GenerateApprovalCode()
    {
        return Random.Shared.Next(0, 1_000_000).ToString("D6", CultureInfo.InvariantCulture);
    }

    private static string BuildCodeHint(string approvalCode)
    {
        if (approvalCode.Length <= 2)
        {
            return approvalCode;
        }

        return $"***{approvalCode[^2..]}";
    }

    private SharePayloadDto ReadPayload(string? encryptedPayload)
    {
        if (string.IsNullOrWhiteSpace(encryptedPayload))
        {
            return new SharePayloadDto();
        }

        try
        {
            var rawPayload = _shareProtection.UnprotectPayload(encryptedPayload);
            return SharePayloadMapper.Deserialize(rawPayload);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to decrypt share payload while creating 2FV approval request.");
            return new SharePayloadDto();
        }
    }

    private void EnforcePasswordProtection(SharePayloadDto payload, string? accessPassword)
    {
        if (!payload.SecuritySettings.PasswordProtected)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(payload.SecretSettings.PasswordHash))
        {
            throw new UnauthorizedAccessException("This share link requires a password.");
        }

        if (string.IsNullOrWhiteSpace(accessPassword)
            || !_shareProtection.VerifySecret(accessPassword.Trim(), payload.SecretSettings.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid share password.");
        }
    }

    private async Task TryCreateOwnerNotificationAsync(
        ShareTokenEntity shareToken,
        ShareAccessApprovalRequestEntity request,
        CancellationToken cancellationToken)
    {
        var preferences = await LoadPreferencesAsync(
            shareToken.UserId,
            shareToken.User.Language,
            cancellationToken);

        if (!preferences.DataSharingNotifications)
        {
            return;
        }

        var title = Localize(preferences.Language, "ShareApproval.RequestTitle");
        var description = Localize(
            preferences.Language,
            "ShareApproval.RequestDescription",
            request.ViewerName,
            request.ExpiresAt.ToLocalTime().ToString("HH:mm", CultureInfo.InvariantCulture));

        _db.UserNotifications.Add(new UserNotificationEntity
        {
            Id = Guid.NewGuid(),
            UserId = shareToken.UserId,
            Type = NotificationType.ShareRequest,
            Language = preferences.Language,
            Title = title,
            Description = description,
            ActorName = request.ViewerName,
            CreatedAt = request.RequestedAt,
        });

        if (!preferences.PushEnabled || string.IsNullOrWhiteSpace(preferences.PushDeviceToken))
        {
            return;
        }

        if (IsWithinQuietHours(preferences.QuietHoursStart, preferences.QuietHoursEnd, request.RequestedAt))
        {
            return;
        }

        var pushResult = await _pushNotificationSender.SendAsync(
            new PushNotificationDispatchRequest(
                DeviceToken: preferences.PushDeviceToken,
                Title: title,
                Body: description,
                Language: preferences.Language,
                Data: new Dictionary<string, string>
                {
                    ["eventType"] = NotificationType.ShareRequest.ToString(),
                    ["twoFactorRequestId"] = request.Id.ToString(),
                    ["shareTokenId"] = shareToken.Id.ToString(),
                    ["shareCode"] = shareToken.ShareCode ?? SharePayloadMapper.BuildShareCode(shareToken.Token),
                    ["viewerName"] = request.ViewerName,
                    ["expiresAt"] = request.ExpiresAt.ToString("O", CultureInfo.InvariantCulture),
                }),
            cancellationToken);

        if (!pushResult.Delivered)
        {
            _logger.LogWarning(
                "Failed to deliver 2FV push approval request for user {UserId}. Reason: {Reason}",
                shareToken.UserId,
                pushResult.FailureReason ?? "unknown");
        }
    }

    private async Task<EffectivePreferences> LoadPreferencesAsync(
        Guid userId,
        string? fallbackLanguage,
        CancellationToken cancellationToken)
    {
        var preferences = await _db.NotificationPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(entry => entry.UserId == userId, cancellationToken);

        var language = NormalizeLanguage(preferences?.Language ?? fallbackLanguage);

        if (preferences is null)
        {
            return new EffectivePreferences(
                PushEnabled: true,
                PushDeviceToken: null,
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
            DataSharingNotifications: preferences.DataSharingNotifications,
            QuietHoursStart: preferences.QuietHoursStart,
            QuietHoursEnd: preferences.QuietHoursEnd,
            Language: language);
    }

    private string Localize(string language, string key, params object[] arguments)
    {
        var originalCulture = CultureInfo.CurrentCulture;
        var originalUiCulture = CultureInfo.CurrentUICulture;
        try
        {
            CultureInfo.CurrentCulture = new CultureInfo(language);
            CultureInfo.CurrentUICulture = new CultureInfo(language);
            return _localizer[key, arguments];
        }
        catch (CultureNotFoundException)
        {
            return _localizer[key, arguments];
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
            CultureInfo.CurrentUICulture = originalUiCulture;
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
        return trimmed.Length <= maxLength ? trimmed : trimmed[..maxLength];
    }

    private static string BuildShareGroup(string token) => $"share-{token}";

    private sealed record EffectivePreferences(
        bool PushEnabled,
        string? PushDeviceToken,
        bool DataSharingNotifications,
        TimeOnly? QuietHoursStart,
        TimeOnly? QuietHoursEnd,
        string Language);
}

public sealed class GetTwoFactorApprovalStatusHandler
    : IQueryHandler<GetTwoFactorApprovalStatusQuery, TwoFactorApprovalStatusResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;

    public GetTwoFactorApprovalStatusHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection)
    {
        _db = db;
        _shareProtection = shareProtection;
    }

    public async Task<TwoFactorApprovalStatusResponse> HandleAsync(
        GetTwoFactorApprovalStatusQuery query,
        CancellationToken cancellationToken = default)
    {
        var shareToken = await ResolveShareTokenAsync(query.Token, cancellationToken);

        var request = await _db.ShareAccessApprovalRequests
            .FirstOrDefaultAsync(entry => entry.Id == query.RequestId && entry.ShareTokenId == shareToken.Id, cancellationToken)
            ?? throw new KeyNotFoundException("Two-factor access request not found.");

        var now = DateTime.UtcNow;
        if (request.Status == ShareAccessApprovalStatus.Pending && request.ExpiresAt <= now)
        {
            request.Status = ShareAccessApprovalStatus.Expired;
            request.DecisionAt = now;
            await _db.SaveChangesAsync(cancellationToken);
        }

        return new TwoFactorApprovalStatusResponse
        {
            RequestId = request.Id,
            Status = ShareApprovalStatusMapper.ToWire(request.Status),
            RequestedAt = request.RequestedAt,
            ExpiresAt = request.ExpiresAt,
            DecisionAt = request.DecisionAt,
            Message = request.Status switch
            {
                ShareAccessApprovalStatus.Pending => "Awaiting patient approval.",
                ShareAccessApprovalStatus.Approved => "Access approved by patient.",
                ShareAccessApprovalStatus.Denied => "Access denied by patient.",
                ShareAccessApprovalStatus.Expired => "Approval request expired.",
                _ => "Unknown approval status.",
            },
        };
    }

    private async Task<ShareTokenEntity> ResolveShareTokenAsync(string token, CancellationToken cancellationToken)
    {
        var tokenHash = _shareProtection.HashToken(token);
        var shareToken = await _db.ShareTokens
            .AsNoTracking()
            .FindByPublicTokenAsync(token, tokenHash, cancellationToken)
            ?? throw new KeyNotFoundException("Share token not found.");

        return shareToken;
    }
}

public sealed class GetPendingTwoFactorApprovalsHandler
    : IQueryHandler<GetPendingTwoFactorApprovalsQuery, IReadOnlyList<PendingTwoFactorApprovalItemResponse>>
{
    private readonly MedVaultDbContext _db;

    public GetPendingTwoFactorApprovalsHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<PendingTwoFactorApprovalItemResponse>> HandleAsync(
        GetPendingTwoFactorApprovalsQuery query,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;

        await _db.ShareAccessApprovalRequests
            .Where(request => request.Status == ShareAccessApprovalStatus.Pending
                && request.ExpiresAt <= now
                && request.ShareToken.UserId == query.UserId)
            .ExecuteUpdateAsync(
                setters => setters
                    .SetProperty(request => request.Status, ShareAccessApprovalStatus.Expired)
                    .SetProperty(request => request.DecisionAt, _ => now),
                cancellationToken);

        return await _db.ShareAccessApprovalRequests
            .AsNoTracking()
            .Where(request => request.ShareToken.UserId == query.UserId
                && request.Status == ShareAccessApprovalStatus.Pending
                && request.ExpiresAt > now)
            .OrderByDescending(request => request.RequestedAt)
            .Select(request => new PendingTwoFactorApprovalItemResponse
            {
                RequestId = request.Id,
                ShareLinkId = request.ShareTokenId,
                ShareCode = request.ShareToken.ShareCode ?? string.Empty,
                ViewerName = request.ViewerName,
                ViewerIpAddress = request.ViewerIpAddress,
                RequestedAt = request.RequestedAt,
                ExpiresAt = request.ExpiresAt,
                Status = ShareApprovalStatusMapper.ToWire(request.Status),
            })
            .ToListAsync(cancellationToken);
    }
}

public sealed class DecideTwoFactorApprovalHandler
    : ICommandHandler<DecideTwoFactorApprovalCommand, TwoFactorApprovalDecisionResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly IHubContext<SharingSyncHub> _sharingHub;

    public DecideTwoFactorApprovalHandler(
        MedVaultDbContext db,
        IHubContext<SharingSyncHub> sharingHub)
    {
        _db = db;
        _sharingHub = sharingHub;
    }

    public async Task<TwoFactorApprovalDecisionResponse> HandleAsync(
        DecideTwoFactorApprovalCommand command,
        CancellationToken cancellationToken = default)
    {
        var request = await _db.ShareAccessApprovalRequests
            .Include(entry => entry.ShareToken)
            .FirstOrDefaultAsync(entry => entry.Id == command.RequestId, cancellationToken)
            ?? throw new KeyNotFoundException("Two-factor access request not found.");

        if (request.ShareToken.UserId != command.UserId)
        {
            throw new UnauthorizedAccessException("This approval request does not belong to the current user.");
        }

        var now = DateTime.UtcNow;

        if (request.Status == ShareAccessApprovalStatus.Pending && request.ExpiresAt <= now)
        {
            request.Status = ShareAccessApprovalStatus.Expired;
            request.DecisionAt = now;
        }
        else if (request.Status == ShareAccessApprovalStatus.Pending)
        {
            request.Status = command.Approved
                ? ShareAccessApprovalStatus.Approved
                : ShareAccessApprovalStatus.Denied;
            request.DecisionAt = now;
        }

        await _db.SaveChangesAsync(cancellationToken);

        await _sharingHub.Clients
            .Group(BuildShareGroup(request.ShareToken.Token))
            .SendAsync(
                "TwoFactorStatusChanged",
                new
                {
                    requestId = request.Id,
                    status = ShareApprovalStatusMapper.ToWire(request.Status),
                    viewerName = request.ViewerName,
                    expiresAt = request.ExpiresAt,
                    decisionAt = request.DecisionAt,
                },
                cancellationToken);

        return new TwoFactorApprovalDecisionResponse
        {
            RequestId = request.Id,
            ShareLinkId = request.ShareTokenId,
            Status = ShareApprovalStatusMapper.ToWire(request.Status),
            DecisionAt = request.DecisionAt ?? now,
        };
    }

    private static string BuildShareGroup(string token) => $"share-{token}";
}

internal static class ShareApprovalStatusMapper
{
    public static string ToWire(ShareAccessApprovalStatus status)
    {
        return status switch
        {
            ShareAccessApprovalStatus.Pending => "pending",
            ShareAccessApprovalStatus.Approved => "approved",
            ShareAccessApprovalStatus.Denied => "denied",
            ShareAccessApprovalStatus.Expired => "expired",
            _ => "unknown",
        };
    }
}

