# Luciérnagas Control

A Flutter application for managing night tour reservations, QR-based guest check-in, and local synchronization between tablet and mobile devices.

## Why this project matters
- Business-ready reservation flow for local tourism operations.
- Supports offline-first operation with local SQLite storage.
- Includes route syncing over local WiFi for paired devices.
- Designed for fast check-in with QR scanning and real-time status updates.

## Key features
- Reservation management: create, edit, cancel, and track status.
- QR check-in workflow with duplicate detection.
- Local storage using SQLite and remote sync using Supabase.
- Business reporting for revenue, expenses, and reservation analytics.
- Admin settings for pricing, device role, and sync configuration.

## Tech stack
- Flutter 3.x / Dart 3.x
- Riverpod state management
- Supabase as backend platform
- SQLite via `sqflite`
- QR scanning with `mobile_scanner`
- Local HTTP sync server with `shelf` + `shelf_router`
- Sharing and file export features with `share_plus` and `file_picker`

## Architecture
```text
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── database/database_helper.dart
│   ├── network/sync_client.dart
│   ├── network/sync_server.dart
│   └── utils/qr_service.dart
├── data/repositories/
│   ├── reservation_repository.dart
│   └── settings_repository.dart
├── domain/entities/
│   ├── customer.dart
│   ├── reservation.dart
│   └── app_settings.dart
└── presentation/
    ├── providers/app_providers.dart
    ├── screens/
    │   ├── auth/role_selection_screen.dart
    │   ├── dashboard/dashboard_screen.dart
    │   ├── reservations/
    │   │   ├── reservations_list_screen.dart
    │   │   ├── reservation_form_screen.dart
    │   │   └── reservation_detail_screen.dart
    │   ├── checkin/checkin_screen.dart
    │   ├── reports/reports_screen.dart
    │   └── settings/settings_screen.dart
    └── widgets/
        ├── reservation_list_tile.dart
        └── stat_card.dart
```

## Setup and run
1. Install dependencies:
```bash
flutter pub get
```
2. Run locally with secure environment values:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-supabase-url.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
3. Build release:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Environment variables
This app uses compile-time environment values for Supabase credentials. Do not store API keys or URLs directly in source code.

## Screenshots
Add visual proof of the product here once available:
- `assets/screenshots/overview.png`
- `assets/screenshots/checkin.png`
- `assets/screenshots/reports.png`

## Recommended .gitignore
The repository should ignore generated and local files such as:
- `.dart_tool/`
- `build/`
- `.idea/`, `.vscode/`
- `.env`
- `local.properties`
- `*.log`
- `ios/Pods/`
- `android/.gradle/`
- `**/Flutter/ephemeral/`

## Recruiter notes
- The app is built for tourism operations with strong offline-first and sync capabilities.
- Clean production code with no hardcoded secrets.
- Simple deployment path using Dart define values for configuration.
- Good candidate project for Flutter, mobile sync, and SaaS-style business logic.

