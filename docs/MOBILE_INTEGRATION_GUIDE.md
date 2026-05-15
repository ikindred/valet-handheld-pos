# Valet Master — Mobile API Integration Guide

Flutter tablet app (Valet Master) integration reference.  
Verified against the NestJS backend at `valet-api/`.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Device Setup](#2-device-setup)
3. [Authentication](#3-authentication)
4. [Shift Management (Cash Sessions)](#4-shift-management-cash-sessions)
5. [Transaction Lifecycle](#5-transaction-lifecycle)
6. [Transaction Lookup](#6-transaction-lookup)
7. [Rates & Settings Sync](#7-rates--settings-sync)
8. [Error Reference](#8-error-reference)
9. [Endpoint Quick Reference](#9-endpoint-quick-reference)

---

## 1. Overview

### Base URL

```
https://<server>/api/v1
```

All endpoints below are relative to this base.

### Content-Type

All request bodies must be JSON:

```
Content-Type: application/json
```

### Authentication

The mobile app uses **Bearer token auth** — no cookies required.

```
Authorization: Bearer <accessToken>
```

The `accessToken` is obtained from `POST /auth/login` and revalidated on every online splash via `POST /auth/validate-token`. Tokens expire after **15 minutes**. Store the token in `SharedPreferences`; re-login when `POST /auth/validate-token` returns `valid: false`.

> **No refresh token flow on mobile.** Unlike the web admin, the mobile app does not use the `POST /auth/refresh` cookie-based refresh flow. When the token expires the app prompts the user to log in again.

### Role

The mobile app authenticates as `CASHIER`. All endpoints listed in this guide are accessible by the `CASHIER` role.

> **Exception:** Device provisioning endpoints (`POST /devices/claim`) require an `ADMIN` session and are used only during device setup/replacement.

---

## 2. Device Setup

The device setup screen runs **before** login. It allows the physical tablet to claim a pre-registered terminal slot created by an admin in the web portal.

### Flow

```
GET /devices/active          ← list unclaimed slots
POST /devices/claim          ← admin consumes placeholder, binds this tablet
POST /devices/:id/rebind     ← admin rebinds replacement tablet to existing slot
POST /device/register        ← called on every online splash (after setup)
```

---

### `GET /devices/active`

List unclaimed terminal slots visible to the tablet. No authentication required.

**Request**

```
GET /api/v1/devices/active
```

**Response 200**

```json
[
  {
    "server_device_id": "uuid",
    "device_label": "Jazz Main Cashier",
    "branch": "jazz-mall",
    "area": "Area A",
    "is_active": true
  }
]
```

The app shows this list so the staff can pick the slot for this physical tablet.

---

### `POST /devices/claim`

Consume a pre-registered placeholder slot and bind this physical tablet.
Requires an authenticated `ADMIN` user from the same branch as the placeholder.

**Request**

```
POST /api/v1/devices/claim
Authorization: Bearer <adminToken>
```

```json
{
  "server_device_id": "uuid",
  "device_id": "android-device-id-or-app-device-identifier",
  "android_id_hash": "sha256-hex",
  "device_model": "Samsung Galaxy Tab S9",
  "os_version": "Android 14"
}
```

**Response 200**

```json
{
  "id": "uuid",
  "deviceId": "android-device-id-or-app-device-identifier",
  "label": "Samsung Galaxy Tab S9",
  "branchId": "branch-uuid",
  "areaId": "area-uuid",
  "status": "ONLINE"
}
```

- Save `server_device_id` from selection and persist the bound `deviceId` locally.
- If branch mismatch/invalid placeholder occurs, show the API error and keep the user in setup.

---

### `POST /device/register`

Register or refresh the device on every online splash. Keeps the branch/area assignment in sync.

**Request**

```
POST /api/v1/device/register
Authorization: Bearer <token>   (if a session token is available)
```

```json
{
  "device_id": "sha256-hash",
  "device_model": "Samsung Galaxy Tab S9",
  "os_version": "Android 14",
  "branch": "jazz-mall",
  "area": "Area A"
}
```

**Response 200**

```json
{
  "success": true,
  "branch": "jazz-mall",
  "area": "Area A"
}
```

Persist `branch` and `area` from the response into the local `device_info` table and `SharedPreferences`.

---

### `POST /devices/:id/rebind`

Rebind an existing server slot to a replacement physical device without creating a new device record.
Requires an authenticated `ADMIN` user from the same branch as the target slot.

**Request**

```
POST /api/v1/devices/:id/rebind
Authorization: Bearer <adminToken>
```

```json
{
  "device_id": "android-new-xyz789",
  "device_model": "Samsung Galaxy Tab S10",
  "os_version": "Android 15"
}
```

**Response 200**

```json
{
  "id": "slot-uuid",
  "deviceId": "android-new-xyz789",
  "label": "Samsung Galaxy Tab S10",
  "branchId": "branch-uuid",
  "status": "ONLINE"
}
```

Use this when replacing lost/damaged hardware while preserving the same server-side slot identity.

---

## 3. Authentication

### `POST /auth/login`

**Request**

```
POST /api/v1/auth/login
```

```json
{
  "email": "cashier@example.com",
  "password": "strongpassword",
  "device_id": "sha256-hash"
}
```

**Response 200**

```json
{
  "accessToken": "eyJ...",
  "token": "eyJ...",
  "is_open_cash": false,
  "user": {
    "id": "uuid",
    "email": "cashier@example.com",
    "firstName": "Juan",
    "lastName": "dela Cruz",
    "full_name": "Juan dela Cruz",
    "role": "CASHIER",
    "isActive": true,
    "branch": {
      "id": "uuid",
      "name": "Jazz Mall"
    }
  }
}
```

| Field | Notes |
|---|---|
| `accessToken` / `token` | Both fields carry the same JWT. Read either. |
| `is_open_cash` | `true` if this cashier already has an open shift. Skip the "Open Shift" screen and go straight to the main screen. |
| `user.branch.id` | Store this as the cashier's `branchId` — required for rates sync. |

If `is_open_cash` is `false`, the next required call is `POST /cash-sessions/start` before entering cashier transaction flow.

---

### `POST /auth/validate-token`

Called on every online app launch (splash screen) to confirm the stored token is still valid.

**Request**

```
POST /api/v1/auth/validate-token
Authorization: Bearer <storedToken>
```

```json
{
  "device_id": "sha256-hash"
}
```

**Response 200**

```json
{
  "valid": true,
  "is_open_cash": true,
  "user": {
    "id": "uuid",
    "email": "cashier@example.com",
    "full_name": "Juan dela Cruz",
    "role": "CASHIER"
  }
}
```

If `valid: false` — clear the local session and navigate to `/login`.

---

### `POST /auth/logout`

Fire and forget. Call before clearing the local session; errors are safe to swallow.

**Request**

```
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

```json
{
  "device_id": "sha256-hash"
}
```

**Response 200**

```json
"Logged out successfully"
```

---

## 4. Shift Management (Cash Sessions)

### `POST /cash-sessions/start`

Open a cashier shift.

**Request**

```
POST /api/v1/cash-sessions/start
Authorization: Bearer <token>
```

```json
{
  "shift_date": "2026-05-08T02:00:00.000Z",
  "branch_id": "branch-uuid",
  "area_id": "area-uuid",
  "device_id": "android-device-id-or-app-device-identifier",
  "opening_balance": 2000,
  "notes": null
}
```

**Response 201**

```json
{
  "id": "uuid",
  "status": "open",
  "opened_at": "2024-01-01T08:00:00.000Z"
}
```

Save returned `id` as local `shift_id` and `opened_at` as local `shift_opened_at`. These are required for close-shift and open-to-close reporting windows.
`shift_date`, `branch_id`, and `area_id` are required on request and validated by the backend.

---

### `POST /cash-sessions/close`

Close the active cashier shift.

**Request**

```
POST /api/v1/cash-sessions/close
Authorization: Bearer <token>
```

```json
{
  "shift_id": "uuid",
  "actual_cash": 3890,
  "notes": null
}
```

**Response 200**

```json
{
  "id": "uuid",
  "status": "closed",
  "opened_at": "2024-01-01T08:00:00.000Z",
  "closed_at": "2024-01-01T17:00:00.000Z",
  "opening_balance": 2000,
  "total_transactions": 12,
  "total_sales": 1890,
  "expected_cash": 3890,
  "breakdown": {
    "flat_rate": 1500,
    "succeeding_hours": 240,
    "overnight_fee": 0,
    "lost_ticket_fee": 150
  },
  "actual_cash": 3890,
  "variance": 0
}
```

Call this **before** clearing the session token on logout.
Server computes totals using checkout timestamps between `opened_at` and `closed_at` (inclusive).
Totals include only tickets checked out by the authenticated cashier.

---

### `GET /cash-sessions/current`

Fetch the current open session for the authenticated cashier. Wired for future use.

**Request**

```
GET /api/v1/cash-sessions/current
Authorization: Bearer <token>
```

**Response 200**

```json
{
  "id": "uuid",
  "status": "open",
  "total_transactions": 12,
  "total_sales": 1890,
  "expected_cash": 3890,
  "breakdown": {
    "flat_rate": 1500,
    "succeeding_hours": 240,
    "overnight_fee": 0,
    "lost_ticket_fee": 150
  },
  "opening_balance": 2000,
  "opened_at": "2024-01-01T08:00:00.000Z"
}
```

---

## 5. Transaction Lifecycle

The full check-in to check-out flow uses **3 API calls**:

```
[Check-in]
  1. POST   /transactions/check-in      ← single-call check-in with full payload (ACTIVE)

[Check-out]
  2. POST   /transactions/:id/checkout-preview ← preview totals + condition comparison
  3. POST   /transactions/:id/check-out        ← confirm checkout (marks COMPLETED)
```

> **Optional extra:**
> - `POST /transactions/:id/print-log` — log that the thermal ticket was printed

---

## Dashboard Summary (Post-Login)

### `GET /dashboard/summary`

Load cashier dashboard data after login/open-shift. This endpoint is shift-scoped.

**Request**

```
GET /api/v1/dashboard/summary
Authorization: Bearer <token>
```

**Response 200**

```json
{
  "shift_id": "uuid",
  "opened_at": "2026-05-08T02:00:00.000Z",
  "area_id": "area-uuid",
  "opening_balance": 2000,
  "total_vehicles_in": 14,
  "checked_out_total": 12,
  "active_slots": 2,
  "parked_count": 2,
  "remaining_count": 2,
  "total_slots": 30,
  "total_revenue": 1890,
  "collected_cash": 1890,
  "expected_amount": 3890,
  "transactions_total": 12,
  "recent_transactions": [
    {
      "id": "ticket-uuid",
      "ticket_number": "TKT-0123",
      "plate_number": "ABC1234",
      "status": "COMPLETED",
      "amount": 150,
      "time_out": "2026-05-08T03:10:00.000Z"
    }
  ]
}
```

- `active_slots`, `parked_count`, and `total_slots` are area-scoped (current shift area only).
- `recent_transactions` returns max 10 records.
- Revenue/transactions are checkout-based (`COMPLETED` + `LOST`) for the current cashier shift window.
- Mobile Reports page can reuse this endpoint as the primary source for shift KPI cards.
- Exception: Reports `Transactions` tab should use `GET /transactions` (paginated via `limit` and `page`).

---

### Step 1 — `POST /transactions/check-in` — Single-call check-in

Call once when a car arrives with all check-in details. This creates an `ACTIVE` ticket immediately and returns the server UUID used for checkout/payment calls.

**Request**

```
POST /api/v1/transactions/check-in
Authorization: Bearer <token>
```

```json
{
  "customer_name": "Juan dela Cruz",
  "contact_number": "09171234567",
  "valet_type": "standard_valet",
  "driver_in": "Juan dela Cruz",
  "notes": null,
  "vehicle": {
    "plate_number": "ABC 1234",
    "brand": "Toyota",
    "model": "Camry",
    "color": "Silver",
    "type": "sedan",
    "year": null
  },
  "parking": {
    "level": null,
    "slot": null
  },
  "belongings": ["iPad", "Cellphone / Charger"],
  "condition": {
    "damages": [
      { "zone": "Hood", "type": "dent", "x": 0.2, "y": 0.15 }
    ],
    "signature": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

**Response 201**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "ticket_number": "TKT-0001",
  "status": "active"
}
```

Save `id` as `server_ticket_id`. All subsequent API calls for this ticket use this UUID as `:id`.

---

### Step 2 — `POST /transactions/:id/checkout-preview` — Preview checkout

Before final confirmation, send checkout payload to preview charges and compare checkout condition vs check-in condition.

**Request**

```
POST /api/v1/transactions/:id/checkout-preview
Authorization: Bearer <token>
```

```json
{
  "driver_out": "Pedro Santos",
  "condition_checkout": [
    { "zone": "Front Bumper", "type": "scratch", "x": 0.5, "y": 0.05 }
  ],
  "status": "active"
}
```

**Response 200**

```json
{
  "release_summary": {
    "plate": "ABC 1234",
    "customer": "Juan dela Cruz",
    "duration": "2h 15m"
  },
  "ticket": {
    "ticket_number": "TKT-0001",
    "flat_rate_amount": 150,
    "succeeding_rate_amount": 60,
    "total_amount": 210
  },
  "condition_comparison": [
    { "zone": "Front Bumper", "type": "scratch", "x": 0.5, "y": 0.05, "is_new": true }
  ]
}
```

Use this response to show checkout confirmation UI. No separate pay endpoint is required.

---

### Step 3 — `POST /transactions/:id/check-out` — Confirm and finalize checkout

After preview confirmation, call check-out with the same payload to finalize.

**Request**

```
POST /api/v1/transactions/:id/check-out
Authorization: Bearer <token>
```

```json
{
  "driver_out": "Pedro Santos",
  "condition_checkout": [
    { "zone": "Front Bumper", "type": "scratch", "x": 0.5, "y": 0.05 }
  ],
  "status": "active"
}
```

**Response 200**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "total": 210
}
```

After success the ticket is marked **COMPLETED** on the server.

---

### `POST /transactions/:id/print-log`

Record that the thermal ticket was printed at this device. Fire and forget.

**Request**

```
POST /api/v1/transactions/:id/print-log
Authorization: Bearer <token>
```

**Response 200**

```json
{
  "printed_at": "2024-01-01T10:05:00.000Z"
}
```

---

### `POST /tickets/:id/lost` — Mark ticket lost *(reserved)*

Wired but not yet called from any active screen. For future lost ticket flow.

**Request**

```
POST /api/v1/tickets/:id/lost
Authorization: Bearer <token>
```

```json
{
  "notes": "Customer unable to produce ticket"
}
```

**Response 200**

```json
{
  "status": "LOST",
  "fee": 200
}
```

The lost ticket fee is configured per branch in the rates table.

---

### `GET /transactions` — List transactions

Background sync for the Reports tab.

**Request**

```
GET /api/v1/transactions?date_from=2024-01-01&date_to=2024-01-31&limit=200&page=1
Authorization: Bearer <token>
```

| Query param | Type | Notes |
|---|---|---|
| `date_from` | `YYYY-MM-DD` | inclusive |
| `date_to` | `YYYY-MM-DD` | inclusive |
| `limit` | number | max 200 |
| `page` | number | 1-based |
| `search` | string | plate number search |
| `status` | string | `active`, `completed`, `lost`, `parked`, `long_stay` |
| `sort` | string | `asc` or `desc` (default `desc`) |

**Response 200**

```json
{
  "data": [
    {
      "id": "uuid",
      "ticket_number": "TKT-0001",
      "plate_number": "ABC 1234",
      "vehicle": "Toyota Camry",
      "color": "Silver",
      "time_in": "10:00",
      "time_out": null,
      "duration_minutes": 45,
      "slot": "Area A",
      "status": "parked",
      "amount": null
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "totalPages": 3
}
```

Results are scoped to the authenticated cashier's branch automatically. Used for display in the Reports tab only — not merged into local Drift.

---

## 6. Transaction Lookup

Both endpoints return the same full transaction shape. The app resolves from local Drift first; these are fallback for cross-device lookups.

### `GET /transactions/:id` — Lookup by server UUID

Used for QR scan (QR encodes the server UUID).

**Request**

```
GET /api/v1/transactions/:id
Authorization: Bearer <token>
```

> `:id` accepts either a UUID or a `TKT-XXXX` ticket number.

**Response 200** — see [full transaction shape](#full-transaction-shape) below.

---

### `GET /tickets/by-number/:ticketNumber` — Lookup by ticket number

Used when the customer manually types their `TKT-XXXX` stub number.

**Request**

```
GET /api/v1/tickets/by-number/TKT-0001
Authorization: Bearer <token>
```

**Response 200** — see [full transaction shape](#full-transaction-shape) below.

---

### Full Transaction Shape

```json
{
  "id": "uuid",
  "ticket_number": "TKT-0001",
  "invoice_number": null,
  "status": "active",
  "created_at": "2024-01-01T10:00:00.000Z",
  "customer": {
    "name": null,
    "contact_number": "09171234567"
  },
  "vehicle": {
    "plate_number": "ABC 1234",
    "brand": "Toyota",
    "model": "Camry",
    "color": "Silver",
    "year": null,
    "type": "sedan"
  },
  "parking": {
    "level": null,
    "slot": null
  },
  "belongings": ["iPad", "Cellphone / Charger"],
  "condition_checkin": {
    "damages": [{ "zone": "Hood", "type": "dent", "x": 0.2, "y": 0.15 }],
    "signature": "data:image/png;base64,..."
  },
  "condition_checkout": null,
  "qr_code": "TKT-0001",
  "notes": null,
  "valet_type": "standard_valet",
  "driver_in": "Juan dela Cruz",
  "driver_out": null,
  "time_in": "2024-01-01T10:00:00.000Z",
  "time_out": null,
  "duration_minutes": 45,
  "amount": null,
  "amount_paid": null,
  "change": null,
  "payment_method": null,
  "printed_at": null
}
```

> Tickets with status `completed`, `lost`, or `void` return **409 Conflict** from both lookup endpoints. Handle this by displaying the ticket's final state from local storage.

---

## 7. Rates & Settings Sync

Perform this sync after login and on periodic background refresh. All data is cached locally.

### `GET /branches/:id`

Fetch branch hours for the overnight rate window.

**Request**

```
GET /api/v1/branches/:id
Authorization: Bearer <token>
```

Use `user.branch.id` from the login response as `:id`.

**Response 200**

```json
{
  "id": "uuid",
  "name": "Jazz Mall",
  "opensAt": "10:00",
  "closesAt": "21:00",
  "status": "ACTIVE"
}
```

Store `opensAt` as `mall_open_time` and `closesAt` as `mall_close_time` in the local `branch_config` table.

---

### `GET /branches/:id/rates`

Fetch the branch's standard (default) parking rates.

**Request**

```
GET /api/v1/branches/:id/rates
Authorization: Bearer <token>
```

**Response 200**

```json
{
  "flatRate": 150,
  "succeedingRate": 30,
  "overnightFee": 200,
  "lostTicketFee": 200
}
```

Stored as the `Standard` vehicle type row in the local `rates` table. Also accepts snake_case variants: `flat_rate`, `succeeding_rate`, `overnight_fee`, `lost_ticket_fee`.

---

### `GET /rates/branches/:branchId/vehicle-types`

Fetch per-vehicle-type rates that override the standard rates.

**Request**

```
GET /api/v1/rates/branches/:branchId/vehicle-types
Authorization: Bearer <token>
```

**Response 200**

```json
[
  {
    "name": "Sedan / Hatchback",
    "flatRate": 150,
    "succeedingRate": 30,
    "overnightFee": 200,
    "lostTicketFee": 200,
    "status": "ACTIVE"
  },
  {
    "name": "SUV / Van",
    "flatRate": 200,
    "succeedingRate": 40,
    "overnightFee": 250,
    "lostTicketFee": 200,
    "status": "ACTIVE"
  }
]
```

Filter to `status == "ACTIVE"` rows only. Map server `name` to local keys:

| Server name (contains) | Local key |
|---|---|
| `Sedan` / `Hatchback` | `sedan` |
| `SUV` | `suv` |
| `Van` | `van` |
| `Luxury` | `luxury` |
| `EV` / `PHEV` | `ev_phev` |

Used in checkout pricing via `RateService.checkoutRatesResolved()`.

---

### `GET /settings`

Fetch global system configuration.

**Request**

```
GET /api/v1/settings
Authorization: Bearer <token>
```

**Response 200**

```json
{
  "overnightCutoff": "01:30",
  "ticketPrefix": "TKT-",
  "ticketNumberLength": "4",
  "openingFloat": "2000",
  "receiptFooter": "NOTE: This is not an Official Receipt (OR).",
  "systemName": "Valet Master",
  "timezone": "Asia/Manila"
}
```

| Field | App usage |
|---|---|
| `overnightCutoff` | Also read as `overnight_cutoff`, `overnightStart`, `overnight_start_time`. Stored as `overnight_start_time` in `branch_config`. |
| `ticketPrefix` | Prepended to the local counter for display ticket numbers. |
| `ticketNumberLength` | Zero-pad width for the counter (e.g. `4` → `TKT-0001`). |
| `openingFloat` | Pre-fill value on the Open Shift screen. |
| `receiptFooter` | Printed at the bottom of every receipt. |
| `timezone` | Used for time display and overnight window calculations. `overnight_end_time` is hardcoded to `06:00` on the app side. |

---

## 8. Error Reference

All errors follow this shape:

```json
{
  "statusCode": 400,
  "message": "Plate number is required",
  "error": "Bad Request"
}
```

| Status | When | Handling |
|---|---|---|
| `400 Bad Request` | Validation failed (missing field, invalid format) | Show the `message` to the user |
| `401 Unauthorized` | Token missing, expired, or invalid | Clear session → navigate to `/login` |
| `403 Forbidden` | Role does not have permission | Show permission error; should not happen for CASHIER on listed endpoints |
| `404 Not Found` | Ticket / device / branch not found | Show "not found" message |
| `409 Conflict` | Duplicate plate already active; ticket already completed/lost/void; area already occupied | Show the `message` — specific reason is included |

### Common 409 messages

| Scenario | Message |
|---|---|
| Plate already checked in | `"Vehicle ABC 1234 is already checked in"` |
| Ticket already closed | `"Ticket is already completed"` |
| Ticket is already lost | `"Ticket is already lost"` |
| Paying a completed ticket | `"Can only process payment for an active ticket"` |
| Insufficient payment | `"Insufficient payment. Required: 150, received: 100"` |

---

## 9. Endpoint Quick Reference

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/devices/active` | Public | List unclaimed terminal slots |
| `POST` | `/devices/claim` | Bearer (ADMIN) | Consume placeholder and bind tablet |
| `POST` | `/devices/:id/rebind` | Bearer (ADMIN) | Rebind replacement tablet to existing slot |
| `POST` | `/device/register` | Public (optional Bearer) | Splash device refresh |
| `POST` | `/auth/login` | Public | Login → get token + shift status |
| `POST` | `/auth/validate-token` | Public (Bearer) | Splash token revalidation |
| `POST` | `/auth/logout` | Bearer | Fire-and-forget logout |
| `GET` | `/dashboard/summary` | Bearer | Cashier shift dashboard KPIs + recent 10 |
| `POST` | `/cash-sessions/start` | Bearer | Open shift |
| `POST` | `/cash-sessions/close` | Bearer | Close shift |
| `GET` | `/cash-sessions/current` | Bearer | Current open session |
| `POST` | `/transactions/check-in` | Bearer | Single-call check-in (full payload) |
| `POST` | `/transactions/:id/checkout-preview` | Bearer | Preview release summary + compare condition |
| `POST` | `/transactions/:id/check-out` | Bearer | Confirm checkout → marks COMPLETED |
| `POST` | `/transactions/:id/print-log` | Bearer | Log ticket print |
| `GET` | `/transactions/:id` | Bearer | Lookup by UUID or TKT-XXXX |
| `GET` | `/transactions` | Bearer | List / reports sync |
| `GET` | `/tickets/by-number/:ticketNumber` | Bearer | Lookup by TKT-XXXX |
| `POST` | `/tickets/:id/lost` | Bearer | Mark ticket lost *(reserved)* |
| `GET` | `/branches/:id` | Bearer | Branch hours |
| `GET` | `/branches/:id/rates` | Bearer | Standard branch rates |
| `GET` | `/rates/branches/:branchId/vehicle-types` | Bearer | Per-vehicle-type rates |
| `GET` | `/settings` | Bearer | System config + overnight cutoff |

---

*Guide generated against `valet-api/` — last verified May 2026.*
