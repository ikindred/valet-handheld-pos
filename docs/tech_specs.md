# Valet Master — Technical Specifications

### SPiD Smart Parking Technologies · Android Tablet App

> **Framework:** Flutter (Dart)  
> **Target Platform:** Android Tablet (10"–12")  
> **Version:** 1.0.0  
> **Last Updated:** April 2026

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Platform & Environment](#2-platform--environment)
3. [State Management](#3-state-management)
4. [Color Theme](#4-color-theme)
5. [Typography](#5-typography)
6. [Icon Package](#6-icon-package)
7. [Local Storage](#7-local-storage)
8. [Local Database](#8-local-database)
9. [Key Packages & Dependencies](#9-key-packages--dependencies)

---

## 1. Project Overview

**Valet Master** is the cashier and valet attendant-facing Android tablet application for **SPiD Smart Parking Technologies**. It digitalizes the full valet parking lifecycle — check-in, check-out, cash management, and reporting — replacing paper-based ticketing across multiple mall branches in the Philippines.

| Property         | Value                                            |
| ---------------- | ------------------------------------------------ |
| Product Name     | Valet Master                                     |
| Client           | SPiD Smart Parking Technologies                  |
| Locale           | Philippines — `₱` Philippine Peso, `Asia/Manila` |
| Primary Audience | Cashiers and valet attendants                    |
| Deployment       | Android Tablet (sideloaded APK or MDM)           |

---

## 2. Platform & Environment

| Property    | Value                          |
| ----------- | ------------------------------ |
| Framework   | Flutter `^3.22.x`              |
| Language    | Dart `^3.4.x`                  |
| Target OS   | Android 10+ (API Level 29+)    |
| Device      | Android Tablet, 10"–12" screen |
| Orientation | **Landscape locked** (primary) |
| Min SDK     | `minSdkVersion 29`             |
| Target SDK  | `targetSdkVersion 34`          |
| Build       | `flutter build apk --release`  |

---

## 3. State Management

### ✅ Bloc + Cubit (`flutter_bloc`)

**Package:** `flutter_bloc: ^8.1.x` + `bloc: ^8.1.x`

**Why Bloc:**

- Explicit event → state flow — easy to trace exactly what triggered a state change
- `Cubit` (lightweight Bloc variant) is ideal for multi-step forms like check-in/check-out where full event separation isn't needed
- `BlocBuilder` / `BlocListener` / `BlocConsumer` cover all UI reaction patterns cleanly
- Battle-tested in production Flutter apps — large ecosystem and community support
- Excellent for teams already familiar with the pattern — low onboarding friction
- Easy unit testing: feed events, assert states

**Bloc vs Cubit — when to use each:**

| Type    | Use Case                                                             |
| ------- | -------------------------------------------------------------------- |
| `Cubit` | Multi-step check-in form, multi-step check-out form, cash open/close |
| `Cubit` | Dashboard stats, reports data loading                                |
| `Bloc`  | Auth flow (login events, session expiry, token refresh)              |
| `Bloc`  | Sync engine (SyncStarted, SyncSuccess, SyncFailed, SyncRetry events) |
| `Cubit` | Settings (printer pairing, branch selection)                         |

**Cubits & Blocs inventory:**

| Class            | Type  | Responsibility                             |
| ---------------- | ----- | ------------------------------------------ |
| `AuthBloc`       | Bloc  | Login, logout, session management          |
| `CheckInCubit`   | Cubit | Holds state across all 4 check-in steps    |
| `CheckOutCubit`  | Cubit | Holds state across all 4 check-out steps   |
| `DashboardCubit` | Cubit | Active tickets stream, shift summary       |
| `CashCubit`      | Cubit | Open float, close shift, remittance total  |
| `ReportsCubit`   | Cubit | Today / Transactions / Cash tab data       |
| `SyncBloc`       | Bloc  | Background sync queue processing           |
| `SettingsCubit`  | Cubit | Printer pairing, branch config, user prefs |

---

## 4. Color Theme

### Brand Colors

| Token           | Name               | Hex       | Usage                             |
| --------------- | ------------------ | --------- | --------------------------------- |
| `primary`       | SPiD Dark Grey     | `#3C3434` | App bar, sidebar, headers         |
| `accent`        | SPiD Orange        | `#E8831A` | CTAs, active states, highlights   |
| `primaryLight`  | Warm Grey          | `#5A5050` | Secondary text, inactive nav      |
| `accentLight`   | Light Orange       | `#F4A84A` | Hover states, badges              |
| `surface`       | Off-White          | `#F9F7F5` | Card and panel backgrounds        |
| `background`    | Light Grey         | `#F0EDEA` | App background                    |
| `error`         | Alert Red          | `#D64045` | Validation errors, damage markers |
| `success`       | Confirmation Green | `#2E7D52` | Vehicle out, payment confirmed    |
| `warning`       | Amber              | `#F0A500` | Overnight fee alerts, warnings    |
| `textPrimary`   | Near Black         | `#1A1616` | Body text                         |
| `textSecondary` | Muted Grey         | `#7A7070` | Labels, metadata                  |
| `divider`       | Light Line         | `#E2DEDE` | Separators, borders               |
| `white`         | White              | `#FFFFFF` | Receipt preview, modals           |

### ThemeData

```dart
// lib/core/theme/app_theme.dart

ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3C3434),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFE8831A),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF9F7F5),
    onSurface: Color(0xFF1A1616),
    error: Color(0xFFD64045),
    onError: Color(0xFFFFFFFF),
  ),
  scaffoldBackgroundColor: Color(0xFFF0EDEA),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF3C3434),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
  ),
);
```

> **Dark Mode:** Not in scope for v1.0. The app is intended for bright, well-lit valet booth environments.

---

## 5. Typography

**Package:** `google_fonts: ^6.x`  
**Font:** `Poppins` — modern, friendly, highly legible on tablets. Single font family across all styles.

| Style            | Weight | Size | Usage                      |
| ---------------- | ------ | ---- | -------------------------- |
| `displayLarge`   | 700    | 32sp | Screen titles              |
| `headlineMedium` | 600    | 24sp | Section headers            |
| `titleLarge`     | 600    | 20sp | Card titles, modal headers |
| `titleMedium`    | 500    | 16sp | List item titles           |
| `bodyLarge`      | 400    | 16sp | Body text, form labels     |
| `bodyMedium`     | 400    | 14sp | Secondary text, metadata   |
| `labelLarge`     | 600    | 14sp | Button text                |
| `labelSmall`     | 400    | 11sp | Timestamps, helper text    |
| `ticketNumber`   | 700    | 22sp | TKT-XXXX display           |
| `plateNumber`    | 600    | 18sp | Plate number display       |
| `amount`         | 700    | 20sp | ₱ amounts, fee breakdown   |

```dart
// lib/core/theme/app_theme.dart

textTheme: GoogleFonts.poppinsTextTheme().copyWith(
  displayLarge:   GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
  headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
  titleLarge:     GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
  titleMedium:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
  bodyLarge:      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
  labelLarge:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
  labelSmall:     GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
),
```

---

## 6. Icon Package

### ✅ `lucide_icons`

**Package:** `lucide_icons: ^0.x`  
**Why:** Clean, consistent modern line icon set. Full coverage for valet/parking operations with no licensing concerns.

**Supplemental:** `flutter_svg: ^2.x` for the SPiD logo and custom SVG assets (vehicle condition diagram, damage markers).

### Icon Map

| Icon Token   | Lucide Icon                   | Usage                    |
| ------------ | ----------------------------- | ------------------------ |
| Dashboard    | `LucideIcons.layoutDashboard` | Nav — Dashboard          |
| Check In     | `LucideIcons.logIn`           | Nav / action — Check-In  |
| Check Out    | `LucideIcons.logOut`          | Nav / action — Check-Out |
| Reports      | `LucideIcons.barChart2`       | Nav — Reports            |
| Settings     | `LucideIcons.settings`        | Nav — Settings           |
| Open Cash    | `LucideIcons.walletCards`     | Cash management          |
| Close Cash   | `LucideIcons.badgeDollarSign` | Cash management          |
| Scan QR      | `LucideIcons.scanLine`        | Check-Out step 1         |
| Plate Number | `LucideIcons.car`             | Vehicle input            |
| Printer      | `LucideIcons.printer`         | Print actions            |
| Ticket       | `LucideIcons.ticket`          | Ticket display           |
| Damage       | `LucideIcons.alertTriangle`   | Condition tab            |
| Signature    | `LucideIcons.penLine`         | Signature capture        |
| Calendar     | `LucideIcons.calendarDays`    | Date range picker        |
| Export       | `LucideIcons.download`        | Report export            |
| User         | `LucideIcons.userRound`       | Staff profile            |
| Branch       | `LucideIcons.mapPin`          | Branch assignment        |
| Overnight    | `LucideIcons.moon`            | Overnight fee indicator  |
| Success      | `LucideIcons.circleCheck`     | Confirmation states      |
| Error        | `LucideIcons.circleX`         | Error states             |
| Sync         | `LucideIcons.refreshCcw`      | Sync status indicator    |

---

## 7. Local Storage

### ✅ `shared_preferences`

**Package:** `shared_preferences: ^2.3.x`

Used **only** for auth session state and device identity. All business data lives exclusively in the local database.

| Key               | Type     | Description                                                              |
| ----------------- | -------- | ------------------------------------------------------------------------ |
| `spid_auth_token` | `String` | JWT/session token for API auth                                           |
| `spid_user_id`    | `String` | Logged-in staff user ID                                                  |
| `spid_user_name`  | `String` | Logged-in staff display name                                             |
| `spid_device_id`  | `String` | Unique device identifier — generated once on first launch, never cleared |

---

## 8. Local Database

### ✅ `drift` (formerly Moor)

**Package:** `drift: ^2.18.x` + `drift_flutter: ^0.2.x`  
**Code gen:** `drift_dev: ^2.18.x` + `build_runner: ^2.4.x`  
**SQLite engine:** `sqlite3_flutter_libs: ^0.5.x`

**Why Drift:**

- Type-safe SQL with Dart code generation — no raw string queries
- Full SQLite support on Android with WAL mode for performance
- Supports complex joins, aggregates, and transactions — needed for reports
- Reactive streams via `watch` / `watchSingleOrNull` — live dashboard updates
- Clean migration support via `MigrationStrategy`

> Database structure, tables, and DAOs will be defined in a separate document.

---

## 9. Key Packages & Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
  equatable: ^2.0.5

  # Local Storage
  shared_preferences: ^2.3.1

  # Local Database
  drift: ^2.18.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24

  # Icons
  lucide_icons: ^0.0.1
  flutter_svg: ^2.0.10+1

  # Typography
  google_fonts: ^6.2.1

  # Navigation
  go_router: ^14.2.0

  # QR Code
  mobile_scanner: ^5.1.1 # QR scan on check-out
  qr_flutter: ^4.1.0 # QR generation for receipt/ticket

  # Bluetooth Printing
  flutter_bluetooth_serial: ^0.4.0
  esc_pos_utils: ^2.0.0 # ESC/POS command builder
  esc_pos_bluetooth: ^0.4.1 # Send to Bluetooth printer

  # Signature Capture
  signature: ^5.4.1

  # Networking & Sync
  dio: ^5.4.3
  connectivity_plus: ^6.0.3
  internet_connection_checker_plus: ^2.4.0

  # PDF / Export
  pdf: ^3.11.1
  printing: ^5.13.1
  share_plus: ^9.0.0

  # Date & Time
  intl: ^0.19.0 # Asia/Manila timezone, ₱ formatting

  # Utilities
  uuid: ^4.4.0 # device_id + ticket ID generation
  freezed_annotation: ^2.4.1 # Immutable data classes
  json_annotation: ^4.9.0

  # Permissions
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  drift_dev: ^2.18.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
```

---

_Database structure, data models, business logic, and folder structure will be covered in separate documents._

https://software-fwd-gmbh-linking.trycloudflare.com/api/docs#/
