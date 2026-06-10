# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About the app

**Gold Invest** (`package:gold_invest`) — a local gold-savings scheme app. Users enroll in a gram-denominated plan (1g, 2g, 5g, 10g), pay cash each month, and an admin records every payment. After 12 payments the user redeems a physical gold coin. Missed months push the delivery date out by one month. Both roles (user / admin) share the same app, gated by Firebase custom claims and Firestore security rules.

## Commands

```bash
# Run the app (dev flavor)
flutter run -t lib/main_dev.dart

# All tests (no Firebase required)
flutter test

# Single test file
flutter test test/delivery_calculator_test.dart

# Static analysis
flutter analyze lib/ test/

# Deploy Firestore rules + indexes
firebase deploy --only firestore:rules,firestore:indexes

# Deploy Cloud Functions (requires Blaze plan)
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions

# Seed initial plans + gold rate (requires serviceAccountKey.json at repo root)
node functions/tools/seed.js
node functions/tools/seed.js --rate 9500

# Bootstrap the first admin user (register in-app first, then:)
node functions/tools/set_admin.js your@email.com

# Firebase emulator (manual security-rules testing)
firebase emulators:start --only firestore,auth
```

## Architecture

```
lib/
  main.dart / main_dev.dart / main_staging.dart / main_prod.dart  — flavor entry points
  app.dart                                                          — GetMaterialApp root
  app/
    bindings/          InitialBinding (permanent singletons) + per-screen bindings
    data/
      models/          Immutable Dart models — fromFirestore / toMap, no code-gen
      repositories/    All Firestore access — one file per collection
    modules/
      auth/            LoginView, RegisterView, PendingApprovalView, SplashView
                       AuthController (permanent — drives all routing)
      user/            DashboardView, PlansView, EnrollmentDetailView,
                       RedemptionView, ProfileView, UserHomeShellView
      admin/           AdminDashboardView, AdminUsersView, AdminPaymentsView,
                       AdminGoldRateView, AdminPlansView, AdminDeliveriesView,
                       AdminMoreView, AdminHomeShellView
                       widgets/record_payment_sheet, record_delivery_sheet
    routes/            AppRoutes (constants) + AppPages (GetPage list) + AuthMiddleware
    services/          AppServices (Firebase init), LoggerService, GetxNotificationService
    themes/            ThemeController (light/dark/system, persisted via GetStorage)
    utils/             AppConfig, AppAssets, AppTranslations (EN/AR/HI/GU)
  business/            delivery_calculator.dart — pure, unit-tested, DO NOT MOVE
  core/                constants.dart, theme, utils (formatters, validators, month_math)
  services/            auth_service.dart, functions_service.dart, notification_service.dart
                       (background FCM handler lives here)
  functions/src/       TypeScript Cloud Functions (mirrors Dart business rules)
```

**State management:** GetX (`get: ^4.6.6`) — `Rx<T>`, `RxList<T>`, `Obx()`, `GetView<T>`  
**Routing:** GetX named routes with `GetMiddleware` (`AuthMiddleware` on every page)  
**DI:** `Get.put()` (permanent singletons in `InitialBinding`), `Get.lazyPut()` (per-screen bindings)

## Key design decisions

### AppConfig (flavor toggle)
`lib/app/utils/app_config.dart` — `AppConfig.dev()/.staging()/.prod()`. Controls `useCloudFunctions`. When `false` (default dev), admin actions use client-side repository writes. When `true` (Blaze), routes through callable Cloud Functions for stronger integrity. Access anywhere via `Get.find<AppConfig>().useCloudFunctions`.

### Auth guard — `AuthController` + `AuthMiddleware`
`AuthController` (permanent) subscribes to `FirebaseAuth.authStateChanges()` and then to the Firestore profile stream. Both `isLoadingAuth` and `isLoadingProfile` start as `true` — **never change this**; the middleware reads these synchronous flags before Firebase responds. The 5-step guard chain (loading→splash, signed-out→login, profile-loading→splash, not-approved→pending, admin→/admin, user→/) is enforced both in `AuthMiddleware.redirect()` and in `AuthController._reevaluateRoute()`, which fires via `ever()` reactions on `firebaseUser` and `appUser` to handle mid-session state changes (e.g. user gets approved while on the pending screen).

### Admin identity
Admin is a Firebase **custom claim** (`request.auth.token.admin == true`). Never stored in Firestore. First admin bootstrapped via `functions/tools/set_admin.js`.

### Business rule: delivery date
Lives in `lib/business/delivery_calculator.dart` (pure Dart, fully unit-tested) and is mirrored in `functions/src/delivery.ts`. Formula: `projectedDeliveryDate = startDate + (durationMonths + missedMonths) months`. Each fully-elapsed unpaid month adds one month to delivery. **Do not modify or move this file.**

### GoldRateController — permanent singleton
`GoldRateController` is registered in `InitialBinding` as permanent (not in per-screen bindings) because `GoldRateCard` is shared across both the user dashboard and admin dashboard. Registering it per-screen would cause "already registered" errors.

### Pagination
`AdminUsersController` and `AdminPaymentsController` use cursor-based Firestore pagination (page size 20). `AdminUsersController.loadMoreUsers()` / `AdminPaymentsController.loadMore()` for scroll-driven loading. Pending users and enrollment detail remain real-time streams.

### Localization
`AppTranslations` loads JSON files from `assets/lang/` at startup (before `runApp`). Use `.tr` on all user-visible strings (e.g. `'sign_in'.tr`). Keys are in `assets/lang/en.json`. When adding a new string: add it to all four JSON files (`en`, `ar`, `hi`, `gu`).

## Adding a new feature module

1. Create `lib/app/modules/<name>/controllers/<name>_controller.dart` — extends `GetxController`, subscribes to streams in `onInit()`, cancels in `onClose()`
2. Create `lib/app/modules/<name>/views/<name>_view.dart` — extends `GetView<NameController>`; use `Obx()` for reactive parts, `Get.find<>()` for permanent controllers
3. Create `lib/app/bindings/<name>_binding.dart` — `Get.lazyPut(() => NameController(...))`
4. Add `GetPage` to `lib/app/routes/app_pages.dart` with `middlewares: [AuthMiddleware()]` and the new binding
5. Add route constant to `lib/app/routes/app_routes.dart`

## Firestore collections

```
users/{uid}              role, status, fullName, email, phone, referredBy, fcmToken
plans/{planId}           name, grams, durationMonths, monthlyAmount, active
enrollments/{id}         userId, planSnapshot, startDate, status,
                         paymentsMade, missedMonths, projectedDeliveryDate, actualDeliveryDate
  └ payments/{paymentId} amount, cycle, paidDate, recordedBy, method, note, goldRateAtPayment
goldRate/current         pricePerGram, currency, source (api|manual), lockManual, updatedAt
  └ history/{id}         rate snapshots
deliveries/{id}          enrollmentId, userId, grams, deliveredDate, recordedBy, note
config/app               app-wide config
```

`paymentsMade`, `missedMonths`, `status`, and delivery dates on enrollments are **admin/Cloud Function-only writes** — enforced by Firestore security rules.

## Supported platforms

Android (`minSdkVersion 23`), iOS (deployment target 13.0+), macOS, web, Linux, Windows. APNs auth key required for iOS push notifications — upload in Firebase console → Project settings → Cloud Messaging.
