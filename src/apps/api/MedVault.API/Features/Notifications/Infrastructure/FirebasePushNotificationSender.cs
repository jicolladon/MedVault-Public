using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;
using MedVault.API.Features.Notifications.Application.Interfaces;

namespace MedVault.API.Features.Notifications.Infrastructure;

public sealed class FirebasePushNotificationSender : IPushNotificationSender
{
    private static readonly SemaphoreSlim InitializationLock = new(1, 1);
    private static FirebaseMessaging? _messaging;

    private readonly IOptions<PushNotificationsOptions> _options;
    private readonly ILogger<FirebasePushNotificationSender> _logger;

    public FirebasePushNotificationSender(
        IOptions<PushNotificationsOptions> options,
        ILogger<FirebasePushNotificationSender> logger)
    {
        _options = options;
        _logger = logger;
    }

    public async Task<PushNotificationDispatchResult> SendAsync(
        PushNotificationDispatchRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.DeviceToken))
        {
            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: "Device token is missing.");
        }

        var options = _options.Value;
        if (!options.Enabled)
        {
            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: "Push delivery is disabled by configuration.");
        }

        if (!string.Equals(options.Provider, "FCM", StringComparison.OrdinalIgnoreCase))
        {
            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: $"Unsupported push provider '{options.Provider}'.");
        }

        var messaging = await EnsureMessagingClientAsync(cancellationToken);
        if (messaging is null)
        {
            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: "FCM client is not configured.");
        }

        var data = request.Data is null
            ? new Dictionary<string, string>(StringComparer.Ordinal)
            : new Dictionary<string, string>(request.Data, StringComparer.Ordinal);

        data["language"] = request.Language;

        var message = new Message
        {
            Token = request.DeviceToken,
            Notification = new Notification
            {
                Title = request.Title,
                Body = request.Body,
            },
            Data = data,
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = string.IsNullOrWhiteSpace(options.AndroidChannelId)
                        ? null
                        : options.AndroidChannelId,
                },
            },
            Apns = new ApnsConfig
            {
                Headers = new Dictionary<string, string>
                {
                    ["apns-priority"] = "10",
                },
            },
        };

        try
        {
            var messageId = await messaging.SendAsync(message, cancellationToken);
            return new PushNotificationDispatchResult(
                Delivered: true,
                ProviderMessageId: messageId,
                FailureReason: null);
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogWarning(
                ex,
                "FCM delivery failed with error code {ErrorCode}.",
                ex.ErrorCode);

            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: ex.ErrorCode.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected failure while dispatching push notification via FCM.");
            return new PushNotificationDispatchResult(
                Delivered: false,
                ProviderMessageId: null,
                FailureReason: "Unexpected FCM delivery error.");
        }
    }

    private async Task<FirebaseMessaging?> EnsureMessagingClientAsync(CancellationToken cancellationToken)
    {
        if (_messaging is not null)
        {
            return _messaging;
        }

        await InitializationLock.WaitAsync(cancellationToken);
        try
        {
            if (_messaging is not null)
            {
                return _messaging;
            }

            var credential = BuildCredential(_options.Value);
            if (credential is null)
            {
                _logger.LogWarning(
                    "Push notifications are enabled but no valid FCM service account configuration was found.");
                return null;
            }

            FirebaseApp firebaseApp;
            try
            {
                firebaseApp = FirebaseApp.DefaultInstance;
                if (firebaseApp is null)
                {
                    firebaseApp = FirebaseApp.Create(new AppOptions
                    {
                        Credential = credential,
                        ProjectId = string.IsNullOrWhiteSpace(_options.Value.ProjectId)
                            ? null
                            : _options.Value.ProjectId,
                    });
                }

                _messaging = FirebaseMessaging.GetMessaging(firebaseApp);
            }
            catch (InvalidOperationException)
            {
                firebaseApp = FirebaseApp.Create(new AppOptions
                {
                    Credential = credential,
                    ProjectId = string.IsNullOrWhiteSpace(_options.Value.ProjectId)
                        ? null
                        : _options.Value.ProjectId,
                });
            }

            _messaging = FirebaseMessaging.GetMessaging(firebaseApp);
            return _messaging;
        }
        finally
        {
            InitializationLock.Release();
        }
    }

    private static GoogleCredential? BuildCredential(PushNotificationsOptions options)
    {
        if (!string.IsNullOrWhiteSpace(options.ServiceAccountJson))
        {
            return GoogleCredential.FromJson(options.ServiceAccountJson);
        }

        if (!string.IsNullOrWhiteSpace(options.ServiceAccountFilePath))
        {
            var fullPath = Path.GetFullPath(options.ServiceAccountFilePath);
            if (!File.Exists(fullPath))
            {
                return null;
            }

            return GoogleCredential.FromFile(fullPath);
        }

        return null;
    }
}

