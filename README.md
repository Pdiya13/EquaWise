# 💰 EquaWise — Personal Finance & Group Expense Splitting

> A full-stack, cross-platform mobile application for personal budgeting, expense tracking, and collaborative group bill splitting — built with **Flutter** and **Firebase**.

---

## 📖 Project Overview

**EquaWise** is a personal finance platform designed to help individuals and groups manage money with clarity and confidence. The app combines everyday expense tracking with powerful group-splitting tools, so users never lose sight of where their money goes — whether it's a solo coffee purchase or a shared dinner bill.

Users can set monthly spending goals by category, log personal expenses, create groups with friends or colleagues, split shared costs four different ways, and settle debts instantly via **Razorpay UPI** — all synced in real time through **Cloud Firestore**.

---

## 🚨 Problem Statement

Managing personal finances and shared expenses is fragmented across spreadsheets, messaging apps, and mental math. Most people lack a single tool that handles both individual budgeting and group settlements without friction.

**Challenges in existing systems:**
- No unified view of personal spending and group debts in one place
- Manual bill splitting leads to calculation errors and awkward follow-ups
- Budget goals are rarely tracked with proactive alerts before overspending
- Group expense apps lack transparent settlement flows tied to real payments
- Offline-first personal finance tools often miss real-time collaboration

---

## 💡 Solution Approach

EquaWise addresses these gaps through a single, Firebase-backed application with two core workflows:

| Workflow | Purpose |
|---|---|
| **Personal Finance** | Track expenses, set monthly category goals, monitor today's spending |
| **Group Splitting** | Create groups, split bills, settle debts via UPI, auto-record settlements |

**Key design decisions:**
- **Firebase BaaS architecture** — no custom backend server; Auth, Firestore, Storage, and FCM handle all persistence and messaging, reducing ops overhead.
- **Repository + ViewModel pattern** — data access is isolated in repositories; `ChangeNotifier` view models expose reactive state to the UI via `provider`.
- **Real-time Firestore streams** — transactions, budgets, groups, and expenses update live without manual refresh.
- **Declarative routing with `go_router`** — nested `ShellRoute` wraps the bottom-navigation shell; deep links like `/group-details/:groupId` are first-class.
- **Server-side security rules** — Firestore rules enforce per-user and per-group access; clients cannot read or write data they don't own.
- **Transparent split calculation** — split amounts are computed in the view model from member lists and split type, then persisted atomically to Firestore.
- **Settlement → transaction pipeline** — when a split is marked settled (via Razorpay or manual), debit/credit transactions are auto-created for both payer and participant.

---

## 🏗️ Architecture Overview

EquaWise follows a **client–BaaS** architecture: the Flutter app talks directly to Firebase services with no intermediate REST API.

```
┌──────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile / Web App                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Auth    │  │Dashboard │  │  Groups  │  │  Goals   │         │
│  │  Screens │  │  & Txns  │  │  & Split │  │  Screen  │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       └─────────────┴─────────────┴─────────────┘                 │
│         AuthViewModel │ GroupsViewModel │ BudgetsViewModel        │
│              TransactionsViewModel (Provider / ChangeNotifier)    │
│       ┌─────────────────────────────────────────────────────┐    │
│       │  Repositories  →  Services  →  Firebase SDK          │    │
│       └─────────────────────────────────────────────────────┘    │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Firebase SDK (direct)
┌────────────────────────────▼─────────────────────────────────────┐
│                        Firebase Platform                            │
│  ┌──────────┐  ┌──────────────┐  ┌─────────┐  ┌──────────────┐  │
│  │   Auth   │  │  Firestore   │  │ Storage │  │     FCM      │  │
│  │ (JWT)    │  │  (NoSQL DB)  │  │ (files) │  │ (push msgs)  │  │
│  └──────────┘  └──────────────┘  └─────────┘  └──────────────┘  │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                     External Integrations                           │
│         Razorpay (UPI settlements)  │  Google Sign-In            │
└──────────────────────────────────────────────────────────────────┘
```

**External integrations:**
- **Firebase Authentication** — email/password and Google OAuth
- **Cloud Firestore** — real-time document database for all app data
- **Firebase Cloud Messaging (FCM)** — push notifications for budget alerts and split requests
- **Flutter Local Notifications** — foreground and background notification display
- **Razorpay Flutter SDK** — UPI payment flow for settling group splits
- **Google Sign-In** — one-tap social authentication

---

## 🔄 Technical Flow

### User signing in

```
1. App launch
   └─> main() initializes Firebase, NotificationService, MessagingService
       └─> EquaWiseApp mounts with MultiProvider (4 ViewModels)
           └─> GoRouter initialLocation: '/login'
               └─> AuthViewModel listens to FirebaseAuth.authStateChanges()
                   ├─ Authenticated  → user navigates to /dashboard
                   └─ Unauthenticated → LoginScreen

2. Login (email/password or Google)
   └─> AuthService.signInWithEmailPassword() / signInWithGoogle()
       └─> Firebase Auth issues ID token
           └─> FirestoreService.createUser() or updateUserLastLogin()
               └─> MessagingService.registerUserMessaging(uid)
                   └─> FCM token saved to users/{uid}
                   └─> Subscribe to topics: goals_user_{uid}, splits_user_{uid}
                       └─> context.go('/dashboard')
```

### Adding a personal expense

```
1. Dashboard → "Add Expense" quick action
   └─> /add-expense → AddPersonalExpenseScreen
       └─> User enters title, amount, category, description
           └─> TransactionRepository.createTransaction()
               └─> Firestore: transactions/{uuid}
                   { userId, title, amount, type: "expense", category, date }
                       └─> TransactionsViewModel stream updates
                           └─> Dashboard "Today's Expenses" card refreshes
                           └─> BudgetsViewModel re-evaluates category thresholds
```

### Setting a monthly budget goal

```
1. Goals tab → /goals
   └─> BudgetsViewModel.load(userId)
       └─> BudgetRepository.getUserBudgets(userId)  [Firestore stream]
       └─> TransactionRepository.getUserTransactions(userId)  [Firestore stream]

2. User taps "Set Goal" on a category (e.g. Food)
   └─> BudgetsViewModel.setGoal(userId, category, amount)
       └─> BudgetRepository.upsertBudget()
           └─> Firestore: budgets/{uuid}
               { userId, category, amount, period: "monthly" }

3. As expenses accrue, _evaluateBudgetThresholds() runs
   └─> spent / goal ≥ 50%  → local notification (once per month)
   └─> remaining ≤ 10%     → local notification (once per month)
```

### Splitting a group expense

```
1. Groups tab → select group → GroupDetailsScreen
   └─> FAB "Split an expense" → /split-expense/:groupId
       └─> User enters title + total amount
       └─> Chooses split type tab:
           ├─ Evenly    → totalAmount / memberCount per person
           ├─ Amount    → custom ₹ per member
           ├─ Shares    → proportional by share count
           └─ Percent   → proportional by percentage
               └─> GroupsViewModel.createGroupExpense()
                   └─> GroupRepository.createGroupExpense()
                       └─> Firestore: group_expenses/{uuid}
                           { groupId, paidBy, splits[], status: "pending" }
                               └─> Pending badge appears on Groups nav tab
                               └─> Local notification to members who owe
```

### Settling a pending split via UPI

```
1. GroupDetails → Pending Splits card → /pending-splits/:groupId
   └─> Lists splits where current user owes money (amount > 0)

2. User taps "Pay & Settle"
   └─> PaymentService.pay() opens Razorpay Checkout (UPI intent flow)
       └─> On success:
           └─> GroupsViewModel.updateSplitStatus(expenseId, userId, settled)
               ├─> GroupRepository.updateSplitStatus()  [Firestore update]
               └─> TransactionRepository.createTransaction() × 2
                   ├─ Expense tx for payer (participant paid them)
                   └─ Income tx for payer (money received)
                       └─> Split removed from pending list
```

---

## 📂 Project Structure

```
equawise_project/
│
├── lib/
│   ├── main.dart                          # Entry point: Firebase + notification init
│   ├── firebase_options.dart              # Auto-generated Firebase config (FlutterFire)
│   │
│   ├── app/
│   │   └── app.dart                       # EquaWiseApp root widget, theme, providers
│   │
│   ├── router/
│   │   └── app_router.dart                # go_router routes & ShellRoute (bottom nav)
│   │
│   ├── models/
│   │   ├── user_model.dart                # User profile document
│   │   ├── transaction_model.dart         # Personal & settlement transactions
│   │   ├── budget_model.dart              # Monthly category budget goals
│   │   ├── group_model.dart               # Group with member list
│   │   └── group_expense_model.dart       # Split expenses + ExpenseSplit
│   │
│   ├── repositories/
│   │   ├── budget_repository.dart           # Firestore CRUD for budgets
│   │   ├── transaction_repository.dart    # Firestore CRUD for transactions
│   │   └── group_repository.dart          # Groups, expenses, split status
│   │
│   ├── services/
│   │   ├── auth_service.dart              # Firebase Auth + user doc bootstrap
│   │   ├── firestore_service.dart         # User document operations
│   │   ├── messaging_service.dart         # FCM token registration & topics
│   │   ├── notification_service.dart      # Local notification channel & display
│   │   └── payment_service.dart           # Razorpay checkout wrapper
│   │
│   ├── viewmodels/
│   │   ├── auth_view_model.dart           # Auth state (ChangeNotifier)
│   │   ├── budgets_view_model.dart        # Goals, spending, threshold alerts
│   │   ├── transactions_view_model.dart   # Personal transaction list
│   │   └── groups_view_model.dart         # Groups, splits, settlements
│   │
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── transactions_screen.dart
│   │   │   ├── transaction_details_screen.dart
│   │   │   ├── add_personal_expense_screen.dart
│   │   │   ├── today_expenses_screen.dart
│   │   │   ├── goals_screen.dart
│   │   │   ├── groups_screen.dart
│   │   │   ├── create_group_screen.dart
│   │   │   ├── group_details_screen.dart
│   │   │   ├── split_expense_screen.dart
│   │   │   ├── pending_splits_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── reports_screen.dart        # Placeholder (future charts)
│   │   └── widgets/
│   │       └── bottom_nav.dart            # NavigationBar shell with pending badge
│   │
│   └── utils/
│       └── constants.dart                 # Razorpay API key
│
├── android/                               # Android platform layer
├── ios/                                   # iOS platform layer
├── web/                                   # Web platform layer (+ firebase-messaging-sw.js)
├── firestore.rules                        # Firestore security rules
├── firestore.indexes.json                 # Composite index definitions
├── firebase.json                          # Firebase project configuration
├── pubspec.yaml                           # Dart / Flutter dependencies
└── test/
    └── widget_test.dart                   # Widget tests
```

---

## ⚙️ Features

### 👤 Authentication
- Email/password sign-up and sign-in with validation
- Google Sign-In via Firebase Auth provider
- Password reset via email
- Persistent session via Firebase Auth token (auto-restored on launch)
- User profile document created in Firestore on first registration
- FCM token registration on every successful login

### 🏠 Dashboard
- Personalized welcome card with display name
- **Today's Expenses** summary card (count + total ₹) — tap to drill down
- Quick-action shortcuts: Add Expense, Transactions, Groups, Goals

### 💳 Personal Expense Tracking
- Add expenses with title, amount, category, and optional description
- 11 personal categories: Food, Health, Donation, Party, Repairing, Movie, Household, Transport, Travel, Sports, Other
- Full transaction history with type badges (income / expense / group settlement)
- Per-transaction detail view
- Today's expenses filtered view

### 🎯 Budget Goals
- Set monthly spending limits per category
- Live progress bars showing spent vs. goal
- Edit or reset goals at any time
- **Local notifications** when 50% of budget is used or only 10% remains (deduplicated per month via `SharedPreferences`)

### 👥 Group Management
- Create groups with name, description, and member selection from registered users
- View all groups the user belongs to
- Group detail screen with member list and expense history
- Pending splits badge on the Groups bottom-nav tab

### ✂️ Expense Splitting
- Four split modes:
  | Mode | Description |
  |------|-------------|
  | **Evenly** | Divide total equally among all members |
  | **Amount** | Assign a custom ₹ amount per member |
  | **Shares** | Split proportionally by share count |
  | **Percent** | Split by percentage (must sum to 100%) |
- Expense status lifecycle: `pending` → `approved` / `rejected` → `settled`
- Per-member split status tracking with `paidAt` timestamp

### 💸 UPI Settlements (Razorpay)
- One-tap "Pay & Settle" on pending splits you owe
- Razorpay Checkout with UPI intent flow (GPay, PhonePe, Paytm, etc.)
- On successful payment, split marked `settled` and transactions auto-recorded

### 🔔 Notifications
- **Local notifications** via `flutter_local_notifications`:
  - Budget threshold alerts (50% used, 10% remaining)
  - New split requests from group members
- **FCM push notifications** for background/terminated state
- Per-user FCM topics: `goals_user_{uid}`, `splits_user_{uid}`
- Per-group topics: `splits_group_{groupId}_{uid}`

### 👤 Profile
- View display name, email, avatar (Google photo or initials)
- Account creation date
- Sign-out action

---

## 🗄️ Firestore Data Model

### Collections

| Collection | Document ID | Key Fields |
|---|---|---|
| `users` | `{uid}` | `email`, `displayName`, `photoURL`, `totalBalance`, `groupIds[]`, `fcmTokens`, `preferences` |
| `transactions` | `{uuid}` | `userId`, `title`, `amount`, `type`, `category`, `date`, `groupId?`, `groupExpenseId?` |
| `budgets` | `{uuid}` | `userId`, `category`, `amount`, `period` (`monthly`) |
| `groups` | `{uuid}` | `name`, `createdBy`, `memberIds[]`, `memberNames{}` |
| `group_expenses` | `{uuid}` | `groupId`, `paidBy`, `totalAmount`, `splitType`, `splits[]`, `status` |

### Security Rules Summary

| Collection | Read | Write |
|---|---|---|
| `users/{userId}` | Owner only | Owner only |
| `transactions/{id}` | Owner (`userId` match) | Owner only |
| `budgets/{id}` | Owner (`userId` match) | Owner only |
| `groups/{id}` | Members or creator | Members or creator |
| `group_expenses/{id}` | Group members | Group members |

> Full rules are defined in [`firestore.rules`](firestore.rules).

---

## 🌐 App Routes

| Path | Screen | Description |
|------|--------|-------------|
| `/login` | LoginScreen | Sign in / sign up / Google auth |
| `/dashboard` | DashboardScreen | Home with today's summary & quick actions |
| `/transactions` | TransactionsScreen | Full transaction history |
| `/transaction` | TransactionDetailsScreen | Single transaction detail (requires `extra`) |
| `/add-expense` | AddPersonalExpenseScreen | Log a personal expense |
| `/today-expenses` | TodayExpensesScreen | Today's spending breakdown |
| `/goals` | GoalsScreen | Monthly category budget goals |
| `/groups` | GroupsScreen | List of user's groups |
| `/create-group` | CreateGroupScreen | Create a new group |
| `/group-details/:groupId` | GroupDetailsScreen | Group info + expense list |
| `/split-expense/:groupId` | SplitExpenseScreen | Create a split expense |
| `/pending-splits/:groupId` | PendingSplitsScreen | View & settle pending splits |
| `/profile` | ProfileScreen | User profile & sign out |

---

## 🔌 Services & Configuration

| Service | Technology | Notes |
|---------|-----------|-------|
| Authentication | Firebase Auth | Email/password + Google |
| Database | Cloud Firestore | Real-time NoSQL |
| File Storage | Firebase Storage | Receipt attachments (configured) |
| Push Messaging | Firebase Cloud Messaging | Background + foreground handlers |
| Local Notifications | flutter_local_notifications | Budget & split alerts |
| Payments | Razorpay Flutter SDK | UPI settlements |
| State Management | Provider | 4 ChangeNotifier view models |
| Navigation | go_router v16 | ShellRoute + deep links |

---

## 🔐 Environment & Secrets

| Secret | Location | Description |
|--------|----------|-------------|
| Firebase config | `lib/firebase_options.dart` | Auto-generated by FlutterFire CLI — do not edit manually |
| Google Services (Android) | `android/app/google-services.json` | Firebase Android config |
| Razorpay Key | `lib/utils/constants.dart` | Test/live Razorpay API key for UPI checkout |
| Firestore Rules | `firestore.rules` | Deploy with `firebase deploy --only firestore:rules` |

> ⚠️ **Before deploying to production:**
> - Replace the Razorpay test key in `constants.dart` with your live key
> - Review and tighten Firestore security rules
> - Never commit production API keys or service account JSON to version control
> - Enable App Check for additional abuse protection

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | ≥ 3.8.1 | Mobile & web framework |
| [Dart SDK](https://dart.dev/) | ≥ 3.8.1 | Language runtime |
| [Firebase CLI](https://firebase.google.com/docs/cli) | Latest | Deploy rules, manage project |
| [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) | Latest | Generate `firebase_options.dart` |
| Android Studio / Xcode | Latest | Android / iOS development |
| Chrome | Latest | Web development (optional) |
| Razorpay Account | — | UPI payment settlements |
| Google Cloud Console | — | Google Sign-In OAuth credentials |

---

### Installation

#### 1. Clone the repository

```bash
git clone https://github.com/Pdiya13/EquaWise.git
cd EquaWise
```

#### 2. Install Flutter dependencies

```bash
flutter pub get
```

#### 3. Configure Firebase

If setting up a new Firebase project:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure --project=<your-firebase-project-id>
```

This generates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- iOS `GoogleService-Info.plist` (if iOS is selected)

Enable the following in the [Firebase Console](https://console.firebase.google.com/):
- **Authentication** → Email/Password + Google sign-in providers
- **Cloud Firestore** → Create database in production or test mode
- **Cloud Messaging** → For push notifications

Deploy Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

#### 4. Configure Razorpay

1. Create a [Razorpay](https://razorpay.com/) account and obtain your API key.
2. Update `lib/utils/constants.dart`:

```dart
static const String razorpayKey = 'rzp_test_YOUR_KEY_HERE';
```

3. For Android, ensure the Razorpay SDK is linked (handled automatically by `razorpay_flutter`).

#### 5. Configure Google Sign-In

- **Android:** Add your app's SHA-1 fingerprint in Firebase Console → Project Settings → Your Apps.
- **iOS:** Configure the reversed client ID in `Info.plist` and enable Google Sign-In in Firebase.
- **Web:** Add authorized domains in Firebase Authentication settings.

---

### Running the Project

#### Android emulator or device

```bash
flutter run
```

#### iOS simulator or device

```bash
flutter run -d ios
```

#### Web (Chrome)

```bash
flutter run -d chrome
```

> **Web push notifications:** Ensure `web/firebase-messaging-sw.js` is present and registered in `web/index.html`.

---

## 🧪 Testing

### Manual Testing Flow

1. **Register** a new account via the Sign Up tab on the login screen.
2. **Add a personal expense** from Dashboard → Add Expense.
3. **Set a budget goal** on the Goals tab (e.g. Food → ₹5,000).
4. **Create a group** — register a second account on another device/emulator, then add them as a member.
5. **Split an expense** inside the group using any of the four split modes.
6. **Settle a split** from Pending Splits → Pay & Settle (Razorpay test mode).

### Flutter Widget Tests

```bash
flutter test
```

### Static Analysis

```bash
flutter analyze
```

---

## 🛠️ Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `Firebase initialization error` | Missing or invalid `firebase_options.dart` | Run `flutterfire configure` for your project |
| Google Sign-In fails on Android | SHA-1 not registered | Add debug/release SHA-1 in Firebase Console |
| `PERMISSION_DENIED` on Firestore | Security rules block access | Deploy rules: `firebase deploy --only firestore:rules` |
| Razorpay checkout doesn't open | Invalid or missing API key | Set `razorpayKey` in `lib/utils/constants.dart` |
| Notifications not showing (Android 13+) | Runtime permission not granted | Accept the notification permission prompt on first launch |
| Groups list empty after creation | Member not included in `memberIds` | Ensure creator adds themselves when creating the group |
| Budget alerts not firing | No goal set or threshold already notified | Set a goal; alerts deduplicate per month via SharedPreferences |
| Web FCM not working | Service worker missing | Verify `web/firebase-messaging-sw.js` exists and is registered |

---

## 📈 Future Improvements

- **Reports & charts** — integrate `fl_chart` for spending trends, category breakdowns, and monthly comparisons (Reports screen is currently a placeholder)
- **Receipt attachments** — use `file_picker` + Firebase Storage to attach photos to expenses
- **CSV / PDF export** — leverage `csv` and `printing` packages for downloadable statements
- **Offline persistence** — enable Firestore offline cache and `connectivity_plus` for network-aware UI
- **Facebook Sign-In** — `flutter_facebook_auth` is in dependencies but not yet wired in the login screen
- **Multi-currency support** — locale-aware formatting beyond ₹ (INR)
- **Recurring expenses** — scheduled monthly bills auto-logged as transactions
- **Group chat** — in-app messaging per group for expense context
- **Admin dashboard** — web panel for platform oversight
- **CI/CD pipeline** — GitHub Actions for `flutter analyze`, `flutter test`, and Firebase deploy
- **App Check** — protect Firestore and Auth from abuse

---




