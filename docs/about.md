# Valet Master — Tablet App

### SPiD Smart Parking Technologies

---

## Overview

**Valet Master** is a digital valet parking management system developed for **SPiD Smart Parking Technologies**. It replaces traditional paper-based ticketing with a streamlined, mobile-first workflow designed for real-world valet operations across multiple mall branches in the Philippines.

The tablet app is the **cashier and valet attendant-facing component** of the Valet Master system. It handles the full vehicle lifecycle at the parking lane — from check-in to check-out — with support for offline operation, Bluetooth thermal printing, and per-branch rate configuration.

---

## Target Platform

| Property         | Details                                                 |
| ---------------- | ------------------------------------------------------- |
| **Platform**     | Android Tablet (iPad-sized, ~10")                       |
| **Framework**    | Flutter (Dart)                                          |
| **Connectivity** | Offline-first with background sync                      |
| **Printer**      | Bluetooth thermal printer (80mm roll)                   |
| **Locale**       | Philippines — Philippine Peso (₱), Asia/Manila timezone |

---

## Key Features

### 🚗 Vehicle Check-In (Entry Flow)

- Input vehicle details: plate number, brand, color, type
- Capture personal belongings declared by the customer (iPad, cellphone/charger, laptop/notebook, sunglasses, other valuables)
- Log vehicle condition using an interactive damage diagram (top-view and front-view SVG) — mark dents, scratches, and cracks
- Capture customer signature acknowledging the Terms & Conditions
- Generate a unique valet ticket in `TKT-XXXX` format
- Print a **3-part thermal receipt** via Bluetooth printer:
  - **Customer Claim Stub** — given to the car owner
  - **In-Car Copy** — placed inside the vehicle
  - **Key Card Copy** — attached to the vehicle key

### 🔑 Vehicle Check-Out (Exit Flow)

- Scan the printed QR code from the customer's claim stub
- Display stored vehicle details and check-in information
- Compute parking fees automatically based on branch rate configuration:
  - Flat rate / fixed rate
  - Succeeding hour rate
  - Overnight fee (after 1:30 AM)
  - Lost ticket fee
- Print exit receipt with full transaction breakdown

### 💰 Cash Management

- **Open Cash** — Required immediately after login before the dashboard is accessible. Staff records the opening float to start the shift.
- **Close Cash** — Tally collections and submit shift-end cash remittance. Triggered either from the logout flow or manually from the dashboard.

### 📊 Reports

- **Today Tab** — Live summary of the current shift (vehicles in, total collections)
- **Transactions Tab** — Per-ticket log with plate numbers, time in/out, and amounts
- **Cash Tab** — Running cash position across the shift

### ⚙️ Settings

- Branch assignment
- Bluetooth printer pairing
- Shift and user management

---

## Bootstrap & terminal identity

On first launch (or after data loss), the tablet has **no server-claimed POS terminal identity**. The app enforces a one-time **Device Setup** flow:

1. **Splash** — If `device_identity_key` is **not** set in local preferences, navigation goes to **Device Setup** instead of the normal splash continuation.
2. **Device Setup** — Staff selects a pre-configured terminal from the server (`GET /devices/active`), then **claims** it (`POST /devices/claim`) using a SHA-256 hash of the physical `ANDROID_ID` (raw ID is never stored).
3. On a successful **active** claim, the app stores the identity in Drift (`device_identity` table) and writes `device_identity_key` (the server’s logical terminal id) to preferences, then continues to **Login**.

The legacy `device_info` table in Drift remains for backward compatibility; **authoritative** branch/area/label for the claimed terminal is stored in `device_identity` going forward.

After login, a **device conflict** listener (WebSocket transport still TBD) can show a blocking dialog if another device attempts to use the same terminal identity. **Logout** from that dialog ends the session via the existing auth repository path and does **not** clear terminal identity data, so the tablet keeps its claimed terminal unless re-provisioned.

---

## Session Flow

### Splash → (Device Setup) → Login → Open Cash → Dashboard

If `device_identity_key` is already set, splash proceeds as before (session restore or **Login**). Otherwise the user must complete **Device Setup** once per physical device.

After a successful login, the staff is **not taken directly to the dashboard**. Instead, they are required to complete the **Open Cash** screen first — entering the opening float for the shift. Only after confirming the opening float does the app navigate to the dashboard. This ensures every shift starts with a recorded cash position.

```
Splash → [Device Setup if no terminal identity] → Login → Open Cash (required) → Dashboard
```

### Logout Flow

When a staff member taps **Logout**, the app presents a confirmation dialog with two options:

| Option                  | Behavior                                                                                              |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| **Close Cash & Logout** | Navigates to the Close Cash screen to complete the end-of-shift tally, then logs out after submission |
| **Logout Only**         | Logs out immediately without closing cash — shift remains open and can be resumed on next login       |

This allows flexibility for shift handovers (logout only) while still prompting staff to properly close out when their shift ends.

```
Tap Logout
    ├── Close Cash & Logout → Close Cash Screen → Submit → Logout
    └── Logout Only → Logout immediately (shift stays open)
```

---

## Ticket & Receipt Format

Valet tickets follow the format: **`TKT-XXXX`**

Each thermal receipt (80mm width) is a **3-part tear-off** containing:

- Branch name and logo
- Vehicle details (plate number, brand, color)
- Time in / time out
- Declared personal belongings
- Vehicle damage notes
- Customer signature line
- Terms & Conditions
- QR code for scan-out
- "NOTE: This is not an Official Receipt (OR)."

---

## Rate Configuration

Rates are fetched from the server and cached locally for offline use. No rates are hardcoded in the app. Configuration is managed through the Super Admin web portal and supports:

- Flat rate (first N hours)
- Succeeding hour rate
- Overnight fee (configurable cutoff time, default 1:30 AM)
- Lost ticket fee
- Per-branch and per-vehicle-type overrides

---

## App Screens

| #   | Screen           | Description                                                                     |
| --- | ---------------- | ------------------------------------------------------------------------------- |
| —   | Splash           | Bootstrap, session restore, routing                                             |
| —   | Device Setup     | One-time claim of server POS terminal (shown when `device_identity_key` unset)  |
| 1   | Login            | Staff authentication with branch selection                                      |
| 2   | Open Cash        | Opening float entry — **required only if the user session is currently closed** |
| 3   | Dashboard        | Active vehicles, shift stats, quick actions                                     |
| 4   | Check-In Step 1  | Vehicle details entry (plate, brand, color, type)                               |
| 5   | Check-In Step 2  | Personal belongings declaration                                                 |
| 6   | Check-In Step 3  | Vehicle condition diagram (interactive damage markers)                          |
| 7   | Check-In Step 4  | Customer signature + print confirmation                                         |
| 8   | Check-Out Step 1 | QR scan or manual ticket lookup                                                 |
| 9   | Check-Out Step 2 | Vehicle details review                                                          |
| 10  | Check-Out Step 3 | Fee computation breakdown                                                       |
| 11  | Check-Out Step 4 | Payment confirmation + receipt print                                            |
| 12  | Close Cash       | End-of-shift cash tally and remittance                                          |
| 13  | Reports          | Today / Transactions / Cash tabs                                                |
| 14  | Settings         | Printer, branch, user config                                                    |

---

## Branch References

Active branches covered by the system:

- Jazz Mall
- SM North EDSA
- Trinoma
- Eastwood City
- Vertis North

---

## System Architecture Notes

- **POS terminal identity**: Ticket and billing identifiers are tied to the **server terminal id** after device claim, not to a raw Android hardware id.
- **Offline-first**: All check-in/check-out operations work without an internet connection. Data syncs to the backend when connectivity is restored.
- **Config from server**: All fees, branch details, areas, zones, levels, and slot configurations are fetched from the server API on login and cached locally in the database for offline reference. No values are hardcoded.
- **QR-based ticket flow**: Each ticket embeds a QR code linked to the transaction record, enabling fast scan-out at exit.
- **Bluetooth thermal printing**: Pairs with standard 80mm thermal printers over Bluetooth. No Wi-Fi required for printing.
- **Ticket prefix**: Configurable per branch (e.g., `JZZ-`, `SMN-`) to distinguish transactions across locations.

---

## Branding

| Property      | Value                           |
| ------------- | ------------------------------- |
| Product Name  | Valet Master                    |
| Client        | SPiD Smart Parking Technologies |
| Primary Color | Dark Grey `#3C3434` / near-black `#1C1C1A` (setup flows) |
| Accent Color  | Orange `#E87722` (device setup & CTAs); theme accent `#E8831A` elsewhere |

---

_This document covers the Android tablet app component of the Valet Master system. For the Super Admin web portal documentation, refer to the separate portal specification._
