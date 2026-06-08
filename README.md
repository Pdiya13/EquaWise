# EquaWise

EquaWise is a cross-platform personal finance companion built with Flutter. It helps users manage budgets, track expenses, and collaborate on shared payments across mobile and web.

## Key Features
- Budget creation and category tracking
- Expense logging with attachments and notes
- Group expense splitting and settlement tracking
- Firebase Authentication (email/password, social providers)
- Cloud Firestore data sync with offline support
- Push notifications for reminders and updates

## Tech Stack
- Flutter (Android, iOS, Web)
- Firebase: Auth, Firestore, Storage, Cloud Messaging
- State management: Provider
- Navigation: go_router
- Platform plugins: Firebase, local notifications, secure storage, file picker

## Getting Started
### Prerequisites
- Flutter SDK installed
- Android or iOS development tools configured
- Chrome for web testing (optional)
- Firebase project access

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/equawise_project.git
   cd equawise_project
   ```
2. Install packages:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Install FlutterFire CLI if needed:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Run Firebase configuration:
     ```bash
     flutterfire configure --project=<your-firebase-project>
     ```
   - This will generate `lib/firebase_options.dart` and update native platform files.
4. Verify Web Firebase setup:
   - Ensure `web/firebase-messaging-sw.js` exists for Firebase Messaging.

### Run the app
- Android emulator or device:
  ```bash
  flutter run
  ```
- iOS simulator or device:
  ```bash
  flutter run -d ios
  ```
- Web:
  ```bash
  flutter run -d chrome
  ```

## Project Structure
- `lib/main.dart` — app entry point
- `lib/app/` — app configuration, theme, and shell
- `lib/router/` — route definitions and navigation
- `lib/ui/` — screens, widgets, and dialogs
- `lib/models/` — domain models and data classes
- `lib/services/` — Firebase and platform integration services
- `lib/repositories/` — app data access and synchronization logic
- `lib/viewmodels/` — state and business logic for UI
- `lib/firebase_options.dart` — generated Firebase settings

## Tips
- Keep Firebase rules secure and validate user data on the server side.
- Use `flutter analyze` to catch lint issues early.
- Write widget tests for key flows in `test/`.

## Contribution
1. Create a new branch for your feature or fix.
2. Commit changes with clear messages.
3. Open a pull request for review.

## Suggested Commit Message
`docs: replace README with complete professional documentation`
