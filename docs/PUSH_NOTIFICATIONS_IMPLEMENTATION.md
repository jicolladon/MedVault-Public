# Push Notifications Implementation

## Objective
Implement push notifications so MedVault users are alerted when sharing links are accessed (emergency or physician access), while keeping localization, privacy, and existing notification preferences intact.

## Scope Implemented
- Backend push infrastructure added with Firebase Cloud Messaging (FCM) provider support.
- Share access audit flow now creates:
  - In-app notification (existing behavior, improved subtitle handling).
  - Optional push notification (new behavior) when allowed by preferences.
- Device token registration support added through existing notification preferences endpoint.
- Mobile app now initializes FCM and syncs device token to backend through the notifications settings pipeline.

## Architecture

### Backend (.NET API)

#### New Components
- `IPushNotificationSender` interface:
  - `src/apps/api/MedVault.API/Features/Notifications/Application/Interfaces/IPushNotificationSender.cs`
- `PushNotificationsOptions` configuration model:
  - `src/apps/api/MedVault.API/Features/Notifications/Infrastructure/PushNotificationsOptions.cs`
- `FirebasePushNotificationSender` implementation:
  - `src/apps/api/MedVault.API/Features/Notifications/Infrastructure/FirebasePushNotificationSender.cs`

#### Updated Components
- DI registration and options binding in:
  - `src/apps/api/MedVault.API/Program.cs`
- Notification preferences persistence now supports push device token:
  - `src/apps/api/MedVault.API/Features/Configuration/Domain/UserNotificationPreferenceEntity.cs`
  - `src/apps/api/MedVault.API/Features/Configuration/Infrastructure/ConfigEntityConfigurations.cs`
  - `src/apps/api/MedVault.API/Features/Configuration/Application/DTOs/ConfigDtos.cs`
  - `src/apps/api/MedVault.API/Features/Configuration/Application/Handlers/ConfigHandlers.cs`
  - `src/apps/api/MedVault.API/Features/Configuration/Application/Validators/ConfigValidators.cs`
- Share access handler now dispatches localized push messages:
  - `src/apps/api/MedVault.API/Features/Sharing/Application/Handlers/LogShareAccessHandler.cs`
- Notification subtitle behavior improved (fallback + placeholder replacement):
  - `src/apps/api/MedVault.API/Features/Notifications/Application/Handlers/NotificationHandlers.cs`

### Mobile (Flutter)

#### New Components
- Push notification service:
  - `src/apps/mobile/medvault/lib/services/push_notification_service.dart`

#### Updated Components
- Service registration and startup initialization:
  - `src/apps/mobile/medvault/lib/core/di/service_locator.dart`
- Startup initialization now includes notifications service:
  - `src/apps/mobile/medvault/lib/pages/home_page.dart`
- Notifications service now syncs push token to backend:
  - `src/apps/mobile/medvault/lib/services/notifications_service.dart`
- API contracts for saving preferences include optional `pushDeviceToken`:
  - `src/apps/mobile/medvault/lib/services/api/notifications_api.dart`
  - `src/apps/mobile/medvault/lib/services/api/config_api.dart`
- Android runtime permission for notifications:
  - `src/apps/mobile/medvault/android/app/src/main/AndroidManifest.xml`
- Flutter dependencies:
  - `firebase_core`
  - `firebase_messaging`
  - in `src/apps/mobile/medvault/pubspec.yaml`

## End-to-End Flow
1. A shared link is accessed from the portal.
2. `LogShareAccessHandler` records audit data (`ShareAccessLogs`).
3. If `NotifyOnAccess` and user preferences allow:
  - In-app notification is created in `UserNotifications`.
  - During non-quiet-hours, backend attempts push delivery.
4. Push delivery uses `FirebasePushNotificationSender`.
5. Mobile client receives push via FCM.

## Notification Eligibility Rules
Push is sent only when all conditions are true:
- Sharing payload security setting `NotifyOnAccess = true`.
- User notification preferences:
  - `DataSharingNotifications = true`.
  - For emergency access, `SecurityAlerts = true`.
  - `PushEnabled = true`.
- Current time is outside quiet hours.
- A non-empty push device token is registered.
- Backend push provider is enabled/configured.

## Localization
- Language is resolved from notification preferences (fallback to user profile language, then `en`).
- Localized title/description/subtitle are generated server-side using `IStringLocalizer<SharedResource>`.
- Push payload includes language metadata.

## Security and Privacy
- Push send logic is backend-controlled only.
- Device token storage is per-user in notification preferences and not exposed in clear through API responses (`HasPushDeviceToken` is returned instead).
- Push payload avoids sensitive PHI fields and uses concise alert text.
- Existing authentication and authorization requirements remain unchanged.

## Validation and Tests
### Backend
- API project builds successfully.
- Notifications integration tests pass.
- Added integration test:
  - `SaveNotifications_WithPushToken_PersistsTokenPresence`
  - in `tests/backend/MedVault.API.IntegrationTests/Tests/ConfigurationControllerTests.cs`

### Mobile
- Service-level notifications tests pass.
- Existing page-level notifications tests currently fail due pre-existing UI assertions not related to push-token contract.

## Notes
- Provider implementation is currently FCM.
- If push provider is disabled or not configured, in-app notifications still work and access auditing is unaffected.
