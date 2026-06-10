# Gold Invest — Local Gold Investment Plan App

A Flutter + Firebase app for a **monthly gold-savings scheme**. Users enroll in a
gram-denominated plan (1g, 2g, 10g…), pay a fixed amount **in cash each month**,
and an **admin records every payment**. After **12 monthly payments** the user
redeems a physical gold coin. Missing a month automatically pushes the delivery
date out by one month. The same app serves both **users** and **admins** via
role-based access control.

---

## ✨ Features

**User**
- Email/password registration & login (access gated by admin approval)
- Browse plan denominations and enroll
- Live gold-rate banner on the dashboard
- Progress dashboard: current plan, **payment history with timestamps**,
  months completed vs. remaining, **projected delivery date**
- 12-month visual checklist (paid / due / missed / upcoming) + progress bar
- Coin redemption once 12 payments are complete

**Admin**
- Approve / reject registrations (user verification)
- **Manually record cash installments** (transactional, recalculates dates)
- Gold-rate management: manual override + scheduled live API fetch
- Plan management (create / edit / activate / delete denominations)
- Payment tracking & status monitoring (active / overdue / ready / delivered)
- Coin delivery records

---

## 🏛 Architecture

```
Presentation (Flutter widgets)        lib/features/**
        │  Riverpod providers          lib/providers/providers.dart
Controllers / state                   (StateProviders, StreamProviders)
        │
Repositories                          lib/repositories/**       ← all Firestore access
Services                              lib/services/**           ← Auth, callable Functions
        │
Business rules (pure, tested)         lib/business/delivery_calculator.dart
Models                                lib/models/**
        │
Firebase: Auth · Firestore · Functions · (FCM)
```

- **State management / DI / routing:** Riverpod + go_router (auth/role guard in
  `lib/core/router/app_router.dart`).
- **Plain immutable models** with `fromFirestore` / `toMap` — no code-gen, so
  `flutter pub get` is all you need.
- **The critical business rule lives in one pure file**
  (`delivery_calculator.dart`) and is mirrored server-side in
  `functions/src/delivery.ts`. It is fully unit-tested.

### Firestore data model
```
users/{uid}            role, status, fullName, email, phone, referredBy, createdAt, approvedBy
plans/{planId}         name, grams, durationMonths, monthlyAmount, active           (admin catalog)
enrollments/{id}       userId, planSnapshot, startDate, status,
                       paymentsMade, missedMonths, projectedDeliveryDate, actualDeliveryDate
  └ payments/{id}      amount, cycle, paidDate, recordedBy, method, note, goldRateAtPayment
goldRate/current       pricePerGram, currency, source(api|manual), lockManual, updatedAt
  └ history/{id}       snapshots
deliveries/{id}        enrollmentId, userId, grams, deliveredDate, recordedBy, note
```

### The delivery-date rule
Each installment fills the next cycle in order. A cycle whose month has fully
elapsed without a payment counts as **missed**, and:

```
projectedDeliveryDate = startDate + (durationMonths + missedMonths) months
```

So a payment missed in month 3 moves delivery from month 12 → 13, and each
further miss adds another month. Redemption unlocks at 12 payments.

---

## 🚀 Setup

### Prerequisites
- Flutter SDK (stable) + Android Studio and/or Xcode
- Node.js 20 (for Cloud Functions + the admin script)
- `npm i -g firebase-tools` and the FlutterFire CLI:
  `dart pub global activate flutterfire_cli`

### 1. Create the Firebase project
1. <https://console.firebase.google.com> → **Add project**.
2. **Build → Authentication → Sign-in method →** enable **Email/Password**.
3. **Build → Firestore Database → Create database** (production mode).

### 2. Generate platform folders & connect the app
This repo ships the Dart/Firebase code only. Generate the native `android/` and
`ios/` scaffolding (this keeps your existing `lib/`, `pubspec.yaml`, etc.):
```bash
flutter create .               # adds android/ ios/ without touching lib/
flutter pub get
flutterfire configure          # pick your project; select Android + iOS
```
`flutterfire configure` regenerates `lib/firebase_options.dart` and writes the
platform config files (`google-services.json`, `GoogleService-Info.plist`),
replacing the committed placeholders. Follow the CLI prompts to register the
apps. Set your project id in `.firebaserc`.

> **Android:** firebase_auth 5.x needs `minSdkVersion 23`. If a build fails on
> minSdk, set it in `android/app/build.gradle`.
> **iOS:** set the deployment target to 13.0+ in Xcode.

### 3. Deploy security rules & indexes
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 4. Create the first admin
Anyone can register (they land in "pending"). To make yourself an admin:
1. Register once in the app with your email.
2. Firebase console → **Project settings → Service accounts → Generate new
   private key** → save as `serviceAccountKey.json` at the repo root
   (git-ignored).
3. ```bash
   cd functions && npm install && cd ..
   node functions/tools/set_admin.js your@email.com
   ```
4. Sign out and back in — you now see the admin app.

### 5. (Optional) Cloud Functions — needs the Blaze plan
Functions give you the **scheduled live gold-rate fetch** and server-enforced
payment recording. The app works **without** them on the free Spark plan (it
uses client-side paths guarded by the same security rules), except the gold rate
must then be set manually by the admin.

```bash
# upgrade the project to Blaze in the console first
firebase functions:secrets:set GOLD_API_KEY      # free key from https://www.goldapi.io
firebase deploy --only functions
```
Then flip `kUseCloudFunctions` to `true` in `lib/providers/providers.dart` to
route admin actions through the callables.

### 6. Run
```bash
flutter run
```

---

## 🌱 Seeding plans
**Option A — script (fastest).** With a `serviceAccountKey.json` at the repo root
and `functions` deps installed:
```bash
node functions/tools/seed.js                # 1g/2g/5g/10g plans + default rate
node functions/tools/seed.js --rate 9500    # also set gold rate to ₹9500/g
node functions/tools/seed.js --force-rate   # overwrite an existing rate
```
It's idempotent (fixed plan IDs), so re-running just updates the plans.

**Option B — in-app.** Sign in as admin → **More → Investment plans → New plan**.

| Name              | Grams | Monthly (₹) | Months |
|-------------------|-------|-------------|--------|
| 1g Monthly Saver  | 1     | 600         | 12     |
| 2g Monthly Saver  | 2     | 1,200       | 12     |
| 5g Gold Plan      | 5     | 3,000       | 12     |
| 10g Gold Builder  | 10    | 6,000       | 12     |

(Monthly amounts are illustrative — set them to your scheme's pricing.)

## 🔔 Push notifications (FCM)
Users are notified when they're **approved/rejected**, when a **payment is
recorded**, and when a **coin is delivered**. These are sent by
**Firestore-triggered Cloud Functions** (`onUserStatusChanged`,
`onPaymentRecorded`, `onCoinDelivered`), so they fire regardless of whether the
admin used the client-side path or a callable.

Requirements:
- **Deploy functions** (`firebase deploy --only functions`) — needs the Blaze
  plan. Without functions the app still works; there's just no push.
- **iOS:** upload an APNs auth key in Firebase console → Project settings →
  Cloud Messaging, and enable Push Notifications + Background Modes
  (Remote notifications) in Xcode.
- **Android:** works out of the box; the app requests the Android 13+
  notification permission on first sign-in.

The client stores each device's FCM token on the user's profile (`fcmToken`) and
keeps it fresh. Background/terminated pushes show in the system tray; foreground
pushes appear as an in-app snackbar.

---

## ✅ Verification

### Automated business-logic tests (no Firebase needed)
```bash
flutter test
```
`test/delivery_calculator_test.dart` covers the missed-month math, projected
delivery shifts, completion, and the checklist cell states.

### Security-rules check (Firebase emulator)
```bash
firebase emulators:start --only firestore,auth
```
Manually confirm in the Emulator UI that:
- a signed-in user **cannot** change their own `role`/`status`;
- a non-admin **cannot** write `plans`, `goldRate`, payments, or another user's
  enrollment counters;
- a user can read only their own enrollments / payments / deliveries.

### Manual end-to-end runbook
1. **Register** a user → app shows *Awaiting approval*.
2. As **admin → Users → Pending → Approve** → the user gains access.
3. User **→ Plans → Start this plan**.
4. Admin **→ Payments →** open the enrollment **→ Record cash payment** twice.
5. Skip a month, then record again — confirm the dashboard shows
   *“1 missed payment — delivery moved to …”* and the projected date is +1 month.
6. Record up to 12 payments → enrollment becomes **Ready** → admin **Record coin
   delivery** → user sees the coin under **Coins → Delivered**.

---

## 🔐 Security notes
- Admin is a Firebase **custom claim** (`admin == true`); rules never trust a
  client-set flag.
- Users may only create their own profile with `role=user`, `status=pending`,
  and can never escalate.
- All gold-rate / plan / payment / delivery writes are admin-only.
- The external gold API key is stored as a **Functions secret**, never in the
  client or Firestore.
- Never commit `serviceAccountKey.json`, `google-services.json`, or
  `GoogleService-Info.plist` (already in `.gitignore`).

---

## 📁 Project layout
```
lib/
  main.dart, app.dart, firebase_options.dart(placeholder)
  core/        constants, theme, router(guard), utils, shared widgets
  models/      app_user, investment_plan, enrollment, payment, gold_rate, delivery
  repositories/ one per collection (all Firestore access)
  services/    auth_service, functions_service
  providers/   Riverpod providers
  business/    delivery_calculator.dart  (pure, unit-tested)
  features/
    auth/      splash, login, register, pending_approval
    user/      dashboard, plans, enrollment, redemption, profile
    admin/     dashboard, users, payments, plans, gold_rate, deliveries
functions/     TypeScript Cloud Functions + tools/set_admin.js
firestore.rules, firestore.indexes.json, firebase.json
test/          delivery_calculator_test.dart
```
