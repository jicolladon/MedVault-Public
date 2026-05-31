# MedVault

MedVault is a secure medical records management application built with Flutter.

## Features

- **Bottom Tab Navigation**: Easy navigation with Dashboard, Contacts, and Settings tabs
- **Landing Page with Authentication**: Google Sign-In integration with the option to continue without signing in
- **Biometric Authentication**: Fingerprint/Face ID authentication for enhanced security
- **Localization**: Multi-language support (English and Spanish)
- **SQLite Database with Drift**: Local data persistence for contacts and settings
- **Theme Support**: Light and dark mode themes
- **Secure Storage**: Encrypted storage for sensitive data using flutter_secure_storage

## Getting Started

### Prerequisites

- Flutter SDK (3.11+)
- Dart SDK (3.11+)
- Android Studio / Xcode for mobile development
- **Run Pub Scripts (rps)**: Global tool for executing project scripts:
  ```bash
  dart pub global activate rps
  ```

### Installation

1. Navigate to the project directory:

   ```bash
   cd src/apps/mobile/medvault
   ```

2. Install dependencies and generate required files:

   ```bash
   rps setup
   ```

   _(This runs `flutter pub get`, generates localization, and builds the database files)._

3. Run the app:
   ```bash
   flutter run
   ```

### Configuration Notes

- Backend: update the connection string in [../../../apps/api/MedVault.API/appsettings.Development.json](../../../apps/api/MedVault.API/appsettings.Development.json) (`ConnectionStrings:DefaultConnection`).
- Backend: confirm the default URLs in [../../../apps/api/MedVault.API/Properties/launchSettings.json](../../../apps/api/MedVault.API/Properties/launchSettings.json) (HTTPS: `https://localhost:7200`, HTTP: `http://localhost:5200`).
- Mobile: VS Code launch profiles and `dart-define` values live in [../../../../.vscode/launch.json](../../../../.vscode/launch.json). Update `API_BASE_URL` and Firebase values as needed.

## Project Structure

```
lib/
├── l10n/                    # Localization files
├── pages/                   # Application pages (home, landing, dashboard, contacts, settings)
├── services/               # Business logic (auth, database, settings, theme)
├── theme/                  # Theme definitions
├── utils/                  # Utilities (biometric auth)
└── main.dart              # Application entry point
```

## Key Features

- **Bottom Navigation**: Dashboard, Contacts, and Settings tabs
- **Biometric Auth**: Fingerprint/Face ID when session is valid
- **Google Sign-In**: OAuth authentication
- **Local Database**: SQLite with Drift ORM
- **Localization**: English and Spanish support

## Google Sign-In Android Fingerprint (Windows)

Use this command to get the Android certificate fingerprint required by Firebase/Google Cloud OAuth:

"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android

Current debug keystore fingerprints for this environment:

- SHA-1: 12:DA:CD:AB:DF:03:72:0F:FF:D0:36:C9:C3:E6:E7:66:14:6D:DA:B3
- SHA-256: E8:0F:73:C7:5C:7B:DE:33:2F:01:92:0D:BA:0D:A2:F8:8F:A5:98:CB:61:EB:3B:16:AA:59:44:FC:2B:4B:CE:F9

Note: In the current project setup, release builds are configured to use the debug signing config, so release fingerprint matches debug unless you add a dedicated release keystore.

Version: 1.0.0+1
