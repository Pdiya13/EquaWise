# EquaWise

A personal finance tracker with budgeting and group expense splitting.

## Tech Stack
- Flutter (Android, iOS, Web)
- Firebase (Auth, Firestore, Storage, Cloud Messaging)
- State: Provider
- Routing: go_router

## Local Setup
1. Requirements: Flutter SDK, Android/iOS tooling, Chrome (for web).
2. Create Firebase project in the Firebase Console.
3. Add apps for Android, iOS, and Web.
4. Install FlutterFire CLI and configure:
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure --project=<your-firebase-project>`
   This generates `lib/firebase_options.dart` and updates platform files.
5. For Web FCM, ensure `firebase-messaging-sw.js` is placed under `web/` with your sender ID.
6. Run:
   - `flutter pub get`
   - `flutter run -d chrome` (or emulator/device)

## Environment
- Optional: create a `.env` for runtime config and use `flutter_dotenv` if needed.

## Structure
- `lib/app` app root and theme
- `lib/router` routes
- `lib/ui` screens and widgets
- `lib/models` data models
- `lib/services` Firebase and platform services
- `lib/repositories` data access
- `lib/viewmodels` presentation layer

## Next Steps
- Implement Auth (email/password, Google, Facebook, 2FA)
- Transactions CRUD with offline-first Firestore
- Budgets and alerts
- Group splitting and settlements
- Reports and exports
