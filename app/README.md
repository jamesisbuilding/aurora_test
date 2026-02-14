# Aurora Test App (`app/`)

This directory is the Flutter application shell for the IMGO project.

For full architecture, feature, and setup details, see the repository root README:
- `../README.md`

## What lives here
- `lib/main.dart` – app bootstrap + Firebase init
- `lib/di/service_locator.dart` – dependency registration and module wiring
- `lib/app_navigation/app_router.dart` – GoRouter configuration
- `lib/theme/` – app-level theme mode state

## Local run (from this folder)
```bash
flutter pub get
dart run build_runner build -d
flutter run
```
