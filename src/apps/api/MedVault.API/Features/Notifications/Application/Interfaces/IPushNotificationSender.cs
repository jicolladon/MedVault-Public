namespace MedVault.API.Features.Notifications.Application.Interfaces;

public sealed record PushNotificationDispatchRequest(
    string DeviceToken,
    string Title,
    string Body,
    string Language,
    IReadOnlyDictionary<string, string>? Data = null);

public sealed record PushNotificationDispatchResult(
    bool Delivered,
    string? ProviderMessageId,
    string? FailureReason);

public interface IPushNotificationSender
{
    Task<PushNotificationDispatchResult> SendAsync(
        PushNotificationDispatchRequest request,
        CancellationToken cancellationToken = default);
}

