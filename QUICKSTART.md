# MedVault - Quick Start Guide for Contributors

Welcome to **MedVault**! This quick start guide will get you up and running in minutes.

**MedVault** is a portable medical history system with two main components:

- **Mobile App** (Flutter): Patient-facing application for iOS/Android
- **API** (ASP.NET Core): Backend services with database and authentication

---

## Table of Contents

1. [Artifacts and Folders](#1-artifacts-and-folders)
2. [Prerequisites](#2-prerequisites)
3. [Setting Up Your Local Environment](#3-setting-up-your-local-environment)
4. [Running the Application](#4-running-the-application)
5. [Testing](#5-testing)
6. [Troubleshooting](#6-troubleshooting)
7. [Next Steps](#7-next-steps)

---

## 1. Artifacts and Folders

### Project Structure Overview

```
healthId_passport/
├── docs/                        # Documentation and design assets
├── src/                          # Main application source code
│   └── apps/
│       ├── mobile/               # Flutter mobile app
│       │   └── medvault/        # Main Flutter project
│       │       ├── lib/         # Dart source code
│       │       ├── pubspec.yaml  # Flutter dependencies
│       │       └── test/        # Flutter unit tests
│       └── api/                 # ASP.NET Core backend
│           ├── MedVault.API/    # Main API project
│           ├── MedVault.AppHost/         # .NET Aspire host
│           └── MedVault.ServiceDefaults/ # Shared configuration
├── tools/                       # Development utilities
│   └── MedVault.DocIntelligence/ # Document AI processing
├── tests/                       # Test suites
│   └── backend/                # .NET unit & integration tests
├── QUICKSTART.md               # This file
└── README.md                   # Project overview
```

---

## 2. Prerequisites

### Required Software

#### For All Developers

- [Git](https://git-scm.com/) - Version control
- [Visual Studio Code](https://code.visualstudio.com/) - Code editor (optional but recommended)

#### For Mobile Development (Flutter)

- [Flutter SDK](https://flutter.dev/docs/get-started/install) - **v3.11.4+** (check `pubspec.yaml`)
- [Dart SDK](https://dart.dev/get-dart) - Included with Flutter
- [Android Studio](https://developer.android.com/studio) - For Android emulator & build tools
  - Android SDK Level 21+ (API 21+)
  - Android Build Tools 34.0+

#### For Backend Development (.NET)

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) - Build & runtime
- [Visual Studio 2026](https://visualstudio.microsoft.com/) or [VS Code](https://code.visualstudio.com/) - IDE
- [SQL Server 2022](https://www.microsoft.com/sql-server/sql-server-2022) or [SQL Server Developer Edition](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
  - **Alternatively**: Use Docker (see [Running with Docker](#running-with-docker))

#### For Document Intelligence (Optional)

- [Ollama](https://ollama.ai/) - Local LLM for document processing (optional)
  - Model: `llama3.2` (recommended)

### Verify Your Environment

```bash
# Check Flutter
flutter --version

# Check Dart
dart --version

# Check .NET
dotnet --version

# Check Android Studio
# Look for: ~/Library/Android/sdk (macOS) or %ANDROID_HOME% (Windows)
```

---

## 3. Setting Up Your Local Environment

## 3.1 Quick Setup Overview

You need to run both the **Mobile App** and the **Backend API** to have a fully functional local development environment. You can choose to run them separately or use Docker for a more streamlined experience.

The following steps are the strightforward way to get everything running but I would recommend you to dive into the details of each component setup as described in the next sections, especially if you want to contribute to a specific part of the project.

1. Create/Install SQL Server Database
   1. Fastest: Use Docker (see Option B: Using Docker (Recommended))

```bash
# From repository root
cd devops/docker
# Start SQL Server and API
docker compose up -d sqlserver medvault-api
```

2. Run Backend API

```bash
  cd src/apps/api/MedVault.API
  dotnet run
```

3. Run Mobile App

```bash
flutter emulators
flutter emulators --launch <emulator_id> # Start an emulator (or connect a physical device)
  cd src/apps/mobile/medvault
flutter run --target=lib/main.dart --debug --dart-define='GOOGLE_CLIENT_ID={{GOOGLE_CLIENT_ID}}' --dart-define='API_BASE_URL=https://10.0.2.2:7200' --dart-define='APP_ENV=development' --dart-define='FIREBASE_API_KEY={{FIREBASE_API_KEY}}' --dart-define='FIREBASE_APP_ID={{FIREBASE_APP_ID}}' --dart-define='FIREBASE_MESSAGING_SENDER_ID={{FIREBASE_MESSAGING_SENDER_ID}}' --dart-define='FIREBASE_PROJECT_ID={{FIREBASE_PROJECT_ID}}' --dart-define='FIREBASE_STORAGE_BUCKET={{FIREBASE_STORAGE_BUCKET}}'
```

### 3.1 Mobile App Setup (Flutter)

#### Install Dependencies

```bash
cd src/apps/mobile/medvault

# Get Dart packages
flutter pub get

# Generate code (Drift database, localization)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Generate launcher icons & splash screen
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

flutter build apk --debug --dart-define=GOOGLE_CLIENT_ID={{GOOGLE_CLIENT_ID}} --dart-define=API_BASE_URL=https://10.0.2.2:7200 --dart-define=APP_ENV=demo --dart-define=FIREBASE_API_KEY={{FIREBASE_API_KEY}} --dart-define=FIREBASE_APP_ID={{FIREBASE_APP_ID}} --dart-define=FIREBASE_MESSAGING_SENDER_ID={{FIREBASE_MESSAGING_SENDER_ID}} --dart-define=FIREBASE_PROJECT_ID={{FIREBASE_PROJECT_ID}} --dart-define=FIREBASE_STORAGE_BUCKET={{FIREBASE_STORAGE_BUCKET}}
```

#### Run on Emulator/Device

1. Open Visual Studio Code.
2. Review .vscode/launch.json for predefined run configurations.
3. Start an Android emulator or connect a physical device.
4. Go to the Run and Debug view (Ctrl+Shift+D) and select the better option for your deployment:
   - MedVault-dev
     - Debug mode with hot reload
     - API endpoint: https://10.0.2.2:7200 - Local Development API
     - No Demo mode
   - MedVault-test
     - Debug mode with hot reload
     - API endpoint: Azure Test API - Without Credits
   - MedVault-demo
     - Debug mode with hot reload
     - API endpoint: No API Required
   - ... and more configurations for release mode, test, etc.
   - The current values for the rest of the configurations like FIREBASE and Google Client are there for dev purposes, please don't share with the public as they are not meant for production use.
     - They must match with the values in `appsettings.Development.json` or `appsettings.json`

### 3.2 Backend API Setup (.NET)

#### Option A: Using SQL Server Locally

1. **Install SQL Server 2022** and create a database:

   ```sql
   CREATE DATABASE MedVaultDb;
   ```

2. **Navigate to API project**:

   ```bash
   cd src/apps/api/MedVault.API
   ```

3. **Update connection string** in `appsettings.Development.json`:

   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=localhost;Database=MedVaultDb;User Id=sa;Password=YourPassword;TrustServerCertificate=true;"
     }
   }
   ```

4. **Apply Entity Framework migrations**:
   ```bash
   dotnet ef database update
   ```

#### Option B: Using Docker (Recommended)

```bash
# From repository root
cd devops/docker

# Start SQL Server and API
docker compose up -d sqlserver medvault-api

# Verify services are running
docker compose ps
```

**Default credentials**:

- **SQL Server**: User `sa`, Password `MedVault_Dev123!`
- **API**: https://localhost:7200 (HTTPS)

#### Build and Run Locally

```bash
cd src/apps/api/MedVault.API

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run the API
dotnet run
```

API will be available at: `https://localhost:7200`

#### Configure Environment Variables

Review `appsettings.Development.json` with:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=MedVaultDb;User Id=sa;Password=MedVault_Dev123!;TrustServerCertificate=true;"
  },
  "Jwt": {
    "Key": "your-secret-key-at-least-32-characters-long-for-development",
    "Issuer": "MedVault.API",
    "Audience": "MedVault.Client",
    "AccessTokenExpirationMinutes": 120,
    "RefreshTokenExpirationDays": 90
  },
  "Google": {
    "ClientId": "your-google-client-id.apps.googleusercontent.com"
  }
}
```

## 4. Testing

### 4.1 Flutter Testing

#### Run Unit Tests

```bash
cd src/apps/mobile/medvault

# Run all tests
flutter test

# Run specific test file
flutter test test/services/database/database_test.dart

# Run with coverage
flutter test --coverage
```

#### Run Integration Tests

```bash
# Requires running device/emulator
flutter test integration_test/app_test.dart
```

#### Test Coverage Report

```bash
flutter test --coverage

# View report (macOS/Linux)
open coverage/lcov.html

# View report (Windows)
start coverage/lcov.html
```

### 4.2 Backend (.NET) Testing

#### Run Unit Tests

```bash
cd tests/backend/MedVault.API.IntegrationTests

dotnet test

# With verbose output
dotnet test --verbosity detailed

# Run specific test class
dotnet test --filter "ClassName=UserServiceTests"
```

#### Run Integration Tests

```bash
cd tests/backend/MedVault.API.IntegrationTests

# Requires database connection
dotnet test --configuration Release
```

### Useful Commands Quick Reference

```bash
# Flutter
flutter doctor                 # Check environment
flutter run -v                # Run with verbose output
flutter test --coverage       # Run with coverage report
flutter clean                 # Clean build files
flutter pub upgrade          # Update dependencies

# .NET
dotnet build                 # Build solution
dotnet run                   # Run API
dotnet test                  # Run tests
dotnet ef database update    # Apply migrations

# Docker
docker compose up -d        # Start services
docker compose logs -f      # View logs
docker compose down         # Stop services
```

## 5. Third-Party services

### Google Sign-In

The mobile app uses Google Sign-In for authentication. You need to set up a Google Cloud project and create OAuth 2.0 credentials to get the `GOOGLE_CLIENT_ID`. This client ID must be added to both the mobile app configuration and the backend API configuration.

- Create a project in the [Google Cloud Console](https://console.cloud.google.com/).
- Navigate to **APIs & Services > Credentials**.
- Click **Create Credentials > OAuth client ID**.
- Select **Web application** and configure the authorized redirect URIs (e.g., `com.yourapp:/oauth2redirect` for mobile).
- Copy the generated client ID and add it to your environment variables and configuration files.
- The client Id will be used for authenticating users in the mobile app and validating tokens in the backend API.

### Push Notifications

The app uses Firebase Cloud Messaging (FCM) for push notifications. You need to set up a Firebase project and configure FCM to get the necessary credentials.

- Create a project in the [Firebase Console](https://console.firebase.google.com/).
- Add an Android app to your Firebase project and follow the setup instructions to download the `google-services.json` file.
- Open the `google-services.json` file and extract the following values:
  - `api_key/current_key` → `FIREBASE_API_KEY`
  - `project_info/project_id` → `FIREBASE_PROJECT_ID`
  - `project_info/storage_bucket` → `FIREBASE_STORAGE_BUCKET`
  - `client[0]/client_info/android_client_info/package_name` → Used for app configuration
