# Push Notifications Configuration

## Purpose
This guide explains how to configure MedVault push notifications end-to-end for:
- Backend (.NET API, FCM provider)
- Mobile app (Flutter FCM token registration)

## 1. Firebase Console Setup

### 1.1 Create or Select a Firebase Project
1. Open Firebase Console: `https://console.firebase.google.com`.
2. Create a new project or select the project used by MedVault.
3. Keep the Firebase `Project ID` value; it is required in backend and mobile configuration.

### 1.2 Register App in Firebase
Register the mobile app for the environment you are configuring:
- Android package name: `com.application.medvault`.
- iOS bundle id: use your `PRODUCT_BUNDLE_IDENTIFIER` for the target build.

Because MedVault initializes Firebase using `--dart-define` values, `google-services.json` / `GoogleService-Info.plist` are not required for this specific integration path, but you can still add them if you later move to generated FlutterFire config.

### 1.3 Enable Cloud Messaging
1. In Firebase Console, open **Project settings**.
2. Open the **Cloud Messaging** tab.
3. Verify Cloud Messaging is enabled for the project.
4. For iOS delivery, configure APNs key/certificate in the same tab.

### 1.4 Create Service Account Credentials (Backend)
1. Open **Project settings** > **Service accounts**.
2. Click **Generate new private key**.
3. Save the JSON securely (do not commit to source control).
4. Provide it to backend through `PushNotifications:ServiceAccountFilePath` or secure secret injection for `PushNotifications:ServiceAccountJson`.

## 2. Backend Configuration

Update `src/apps/api/MedVault.API/appsettings.json` (or environment-specific settings):

```json
{
  "PushNotifications": {
    "Enabled": true,
    "Provider": "FCM",
    "ProjectId": "your-firebase-project-id",
    "ServiceAccountJson": "",
    "ServiceAccountFilePath": "C:/secrets/firebase-service-account.json",
    "AndroidChannelId": "medvault_alerts"
  }
}
```

### Field Notes
- `Enabled`: Global on/off switch for backend push dispatch.
- `Provider`: Current implementation supports `FCM`.
- `ProjectId`: Firebase project id.
- `ServiceAccountJson`: Raw service-account JSON (optional alternative to file path).
- `ServiceAccountFilePath`: Path to Firebase service-account file (recommended for local/dev).
- `AndroidChannelId`: Notification channel identifier used in Android push payload.

### Credential Loading Priority
1. `ServiceAccountJson` (if non-empty)
2. `ServiceAccountFilePath` (if file exists)
3. If neither is valid, push dispatch is skipped and logged.

## 3. Mobile Configuration (Flutter)

### 3.1 Dependencies
Already added in `src/apps/mobile/medvault/pubspec.yaml`:
- `firebase_core`
- `firebase_messaging`

Run:
```bash
cd src/apps/mobile/medvault
flutter pub get
```

### 3.2 Runtime Firebase Options
The app initializes Firebase using compile-time `--dart-define` values.

How to get these values in Firebase Console:
1. Open **Firebase Console** > your project > **Project settings** (gear icon).
2. In **General** tab, scroll to **Your apps** and select your Android or iOS app.
3. Open the app's **SDK setup and configuration** details.
4. Copy the values from the Firebase config fields shown there.

Value mapping:
- `FIREBASE_API_KEY`: copy from **apiKey**.
- `FIREBASE_APP_ID`: copy from **mobilesdk_app_id** (Android/iOS app id in Firebase config).
- `FIREBASE_MESSAGING_SENDER_ID`: copy from **messagingSenderId**.
- `FIREBASE_PROJECT_ID`: copy from **projectId** (also visible at project level as Project ID).
- `FIREBASE_STORAGE_BUCKET` (optional): copy from **storageBucket**.
- `FIREBASE_IOS_BUNDLE_ID` (optional): use the iOS app bundle identifier from **Your apps** > iOS app settings.

Notes:
- Use values from the same Firebase project configured in backend `PushNotifications:ProjectId`.
- If multiple Firebase apps exist in one project, ensure the selected app matches the build target package/bundle id.

Required defines:
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`

Optional defines:
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_IOS_BUNDLE_ID`

Example run command:
```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

### 3.3 Android Permission
`POST_NOTIFICATIONS` permission is declared in:
- `src/apps/mobile/medvault/android/app/src/main/AndroidManifest.xml`

### 3.4 Token Registration
At startup:
1. `PushNotificationService` initializes FCM and requests notification permissions.
2. `NotificationsService` resolves current FCM token.
3. Token is sent through `/api/configuration/notifications` using `pushDeviceToken`.
4. Backend stores token in `NotificationPreferences`.

### 3.5 iOS Delivery Prerequisites
For iOS push delivery outside local tests, APNs must be configured in Firebase:
1. Create an APNs authentication key in Apple Developer account.
2. Upload the APNs key in Firebase **Project settings** > **Cloud Messaging**.
3. Ensure your iOS app identifier and provisioning profiles include push notification capability.

## 4. API Contract

### Endpoint
`POST /api/configuration/notifications`

### Request additions
- `pushDeviceToken` (optional, string)

Example:
```json
{
  "pushEnabled": true,
  "language": "en-US",
  "emailEnabled": true,
  "securityAlerts": true,
  "dataSharingNotifications": true,
  "quietHoursStart": "22:00:00",
  "quietHoursEnd": "07:00:00",
  "pushDeviceToken": "fcm-token-..."
}
```

### Response additions
- `hasPushDeviceToken` (boolean)

## 5. Operational Behavior

Push is dispatched only if:
- sharing access notification is enabled (`NotifyOnAccess`),
- user settings permit push and relevant alert category,
- current time is outside quiet hours,
- a device token is available,
- backend push provider is enabled and validly configured.

If any condition fails, backend still stores in-app notifications and logs the reason push was skipped.

## 6. Recommended Production Setup
- Keep `ServiceAccountJson` empty in committed config.
- Inject secrets through environment-specific secure configuration.
- Restrict service account permissions to messaging-only scope where possible.
- Rotate credentials periodically.
- Monitor push failures from server logs and alert on sustained delivery errors.

## 7. Troubleshooting

### Backend logs "FCM client is not configured"
- Verify `PushNotifications:Enabled = true`.
- Verify valid service account JSON or file path.
- Verify file path exists in runtime environment.

### Token not persisted
- Ensure user is authenticated.
- Ensure app has requested notification permissions.
- Verify `/api/configuration/notifications` is returning `200`.

### Firebase console setup looks correct but backend still cannot send
- Verify Firebase service account belongs to the same project id configured in `PushNotifications:ProjectId`.
- Verify service account key has not been revoked or rotated without updating deployment secrets.

### No push received but in-app notification exists
- Check quiet hours settings.
- Verify `PushEnabled` and `DataSharingNotifications`.
- Verify stored token is current (reinstall/login can rotate token).
- Confirm Firebase project/app ids match device app build.
