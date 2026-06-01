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
10. [Device presence (WebSocket)](#10-device-presence-websocket)

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

List unclaimed terminal slots visible to the tablet (rows with `claimedAt == null` and a branch assignment). No authentication required.

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
  "server_device_id": "00000000-0000-4000-8000-000000000000"
}
```

`server_device_id` is optional. When present, it must be the **device row UUID** from `GET /devices/active` or claim — not the hardware `deviceId` string. The server checks that the device’s **branch** matches the user’s branch (and for **CASHIER**, if the device is tied to an **area**, the cashier’s **open** cash session must be for that same area). On success, **`lastSeenAt`** is updated for activity tracking (separate from **`claimedAt`**, which is set only when a slot is claimed via `POST /devices/claim`). If checks fail, the API responds **403** and does not issue tokens.

**Response 200**

```json
{
  "accessToken": "eyJ...",
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
    },
    "area": {
      "id": "uuid",
      "name": "Area A",
      "code": "AREA-A"
    },
    "shiftSchedule": [
      { "dayOfWeek": 1, "startTime": "08:00", "endTime": "17:00" },
      { "dayOfWeek": 2, "startTime": "08:00", "endTime": "17:00" }
    ]
  }
}
```

| Field | Notes |
|---|---|
| `accessToken` | Short-lived JWT (15 minutes). Send as `Authorization: Bearer <accessToken>`. |
| `token` | Same value as `accessToken` (mobile clients may read either). |
| `server_device_id` | Optional on login. When sent, must pass branch/area rules above or login returns **403**. |
| `is_open_cash` | `true` if this cashier already has an open shift. Skip the "Open Shift" screen and go straight to the main screen. |
| `user.branch.id` | Store this as the cashier's `branchId` — required for rates sync. |
| `user.area` | Cashiers only — assigned operating area used when opening a shift via `POST /cash-sessions/start` (server reads branch/area from the user profile). |
| `user.shiftSchedule` | Cashiers only — admin-assigned recurring weekly hours (`dayOfWeek` 0=Sun … 6=Sat, `startTime`/`endTime` as `HH:mm`). Empty array if not configured. |

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
    "role": "CASHIER",
    "shiftSchedule": [
      { "dayOfWeek": 1, "startTime": "08:00", "endTime": "17:00" }
    ]
  }
}
```

`user.shiftSchedule` is included for cashiers (same shape as login). Empty array when no schedule is configured.

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
  "openingBalance": 2000,
  "timestamp": "2026-05-16T08:00:00.000Z",
  "notes": ""
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `openingBalance` | Yes | ≥ 0 |
| `timestamp` | Yes | Shift open time from the device (UTC ISO-8601). Persisted as `openedAt`. |
| `notes` | No | Empty string is stored as no note |

Branch and area come from the cashier profile (`user.branch`, `user.area`) — do not send them in the body.

**Response 201**

```json
{
  "id": "uuid",
  "status": "open",
  "opened_at": "2026-05-16T08:00:00.000Z",
  "timestamp": "2026-05-16T08:00:00.000Z"
}
```

`opened_at` and `timestamp` are UTC ISO-8601 strings (same value on start). Save `id` as local `shift_id` and `opened_at` (or `timestamp`) as `shift_opened_at` for close-shift and reporting windows.

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
  "shiftId": "uuid",
  "actualCash": 3890,
  "timestamp": "2026-05-16T17:00:00.000Z",
  "notes": ""
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `shiftId` | Yes | Session UUID from `POST /cash-sessions/start` (`id`) |
| `actualCash` | Yes | Physical cash count, ≥ 0 |
| `timestamp` | Yes | Shift close time from the device (UTC ISO-8601). Persisted as `closedAt`. Must be ≥ shift `opened_at`. |
| `notes` | No | Empty string stored as no note |

**Response 200**

```json
{
  "id": "uuid",
  "status": "closed",
  "opened_at": "2026-05-16T08:00:00.000Z",
  "closed_at": "2026-05-16T17:00:00.000Z",
  "timestamp": "2026-05-16T17:00:00.000Z",
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

Fetch the current open session for the authenticated cashier. **Bearer token only** — no request body.

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
  "opening_balance": 2000,
  "opened_at": "2026-05-16T08:00:00.000Z"
}
```

**Response 404** — no open shift (`{ "message": "No active shift found" }`).

---

## 5. Transaction Lifecycle

The full check-in to check-out flow uses **3 API calls**:

```
[Check-in]
  1. POST   /transactions/check-in      ← single-call check-in with full payload (ACTIVE)

[Check-out]
  2. GET    /transactions/:id/checkout-preview ← Vehicle Review + Payment (no checkout condition)
  3. POST   /transactions/:id/check-out          ← finalize + optional checkout condition
```

### Checkout condition (when it is saved)

- **Check-in** — `condition_checkin` (damages + signature) on `POST /transactions/check-in`.
- **Checkout preview** — does **not** accept `condition_checkout`. Mobile keeps new marks in local state through Vehicle Review / Condition / Payment.
- **Check-out** — mobile sends `condition_checkout` (and `driver_out`) on the **final** `POST check-out` only. If `condition_checkout` is present in the body, the server saves it to `conditionCheckout` (with `is_new` vs check-in) and returns `condition_comparison` in the response.

### Payment recording

- **Only the amount collected** is stored — the parking fee charged at checkout (`Ticket.amount`, server-computed from rates).
- **Not stored:** amount tendered (cash rendered by the customer), change, or tender-vs-total validation. The mobile UI may show those for cashier convenience locally, but the API does not persist them.
- Checkout confirmation (`check-out`) writes `amount`, `timeOut`, and `COMPLETED`; there is no separate pay step.
- Response fields `amount_paid`, `change`, and `payment_method` are legacy placeholders and remain `null`.

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
  "active_slots": 6,
  "parked_count_area": 6,
  "remaining_count": 24,
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

- **Cashier + shift:** `total_vehicles_in`, `checked_out_total`, revenue/cash fields, `recent_transactions`.
- **Shift area (all cashiers in area):** `active_slots`, `parked_count_area`, `remaining_count`, `total_slots`.
- Area occupancy trio: `parked_count_area` (= occupied), `remaining_count` (= free slots), `total_slots` (= capacity in that area).
- `recent_transactions`: max 10; includes still-parked (`ACTIVE`, `time_out: null`) and completed/lost checkouts for this cashier in the shift; sorted by most recent `time_out` or `time_in`.
- Revenue/transactions are checkout-based (`COMPLETED` + `LOST`) for the current cashier shift window.
- Mobile Reports page can reuse this endpoint as the primary source for shift KPI cards.
- Exception: Reports `Transactions` tab should use `GET /transactions` (paginated via `limit` and `page`).
- Legacy data: run `npm run backfill:ticket-area -- --email <cashier@email> [--dry-run]` in `valet-api` if slot counts stay 0 (sets `areaId` from cashier profile).

---

### Step 1 — `POST /transactions/check-in` — Single-call check-in

Call once when a car arrives with all check-in details. This creates an `ACTIVE` ticket immediately and returns the server UUID used for checkout/payment calls.

**The mobile app must send `ticket_number`** (physical or pre-assigned number). The server does **not** auto-generate a ticket number on this endpoint. If that number already exists, the API returns **409**.

The ticket’s `areaId` is set from the cashier’s profile (`user.areaId`), not from the request body — same value used when opening cash. Cashier must be assigned to an area or check-in returns 400.

**Request** — `multipart/form-data` (not JSON)

```
POST /api/v1/transactions/check-in
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

| Field | Required | Notes |
|-------|----------|--------|
| `ticket_number` | Yes | e.g. `TKT-0142` — from mobile / printed ticket |
| `signature` | Yes | Image file (PNG/JPEG/WebP, max 1MB) |
| `vehicle` | Yes | JSON **string**: `{"plate_number":"ABC 1234","brand":"Toyota",...}` |
| `customer_name` | No | |
| `contact_number` | No | |
| `valet_type` | No | e.g. `standard_valet`, `premium_valet` |
| `driver_in` | No | |
| `notes` | No | |
| `parking` | No | JSON string: `{"level":null,"slot":null}` |
| `belongings` | No | JSON array string or comma-separated list |
| `damages` | No | JSON array string of damage points |

Example form fields:

- `ticket_number`: `TKT-0142`
- `vehicle`: `{"plate_number":"ABC 1234","brand":"Toyota","model":"Camry","color":"Silver","type":"sedan","year":null}`
- `belongings`: `["iPad","Cellphone / Charger"]`
- `damages`: `[{"zone":"Hood","type":"dent","x":0.2,"y":0.15}]`
- `signature`: *(file upload)*

**Response 201** — full transaction object (abbreviated):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "ticket_number": "TKT-0142",
  "status": "active",
  "vehicle": { "plate_number": "ABC 1234", "brand": "Toyota", "model": "Camry" },
  "condition_checkin": { "damages": [], "signature": "/uploads/signatures/..." },
  "qr_code": "TKT-0142"
}
```

Save `id` as `server_ticket_id`. Subsequent calls may use either the UUID or `ticket_number` as `:id`.

---

### Step 2 — `GET /transactions/:id/checkout-preview` — Checkout preview

**One GET** for Vehicle Review (both tabs) and the Payment screen (rate lines and total). Do **not** send checkout condition here.

**Request**

```
GET /api/v1/transactions/:id/checkout-preview
Authorization: Bearer <token>
```

`:id` = ticket UUID or `TKT-XXXX`.

**Response 200**

```json
{
  "transaction": {
    "id": "uuid",
    "ticket_number": "TKT-0142",
    "status": "active",
    "customer": { "name": "Juan dela Cruz", "contact_number": "09171234567" },
    "vehicle": {
      "plate_number": "ABC 1234",
      "brand": "Toyota",
      "model": "Vios",
      "color": "White",
      "year": 2022,
      "type": "sedan"
    },
    "parking": { "level": "Level 2", "slot": "B-04", "area": "Zone B" },
    "belongings": ["Cellphone declared"],
    "condition_checkin": {
      "damages": [{ "zone": "Hood", "type": "dent", "x": 0.2, "y": 0.15 }],
      "signature": "/uploads/signatures/..."
    },
    "condition_checkout": null,
    "valet_type": "standard_valet",
    "driver_in": "Carlos Mendoza",
    "driver_out": null,
    "time_in": "2026-03-24T02:18:00.000Z",
    "time_out": null,
    "duration_minutes": 209,
    "amount": null
  },
  "preview": {
    "release_summary": {
      "plate": "ABC 1234",
      "customer": "Juan dela Cruz",
      "duration": "3h 29m"
    },
    "ticket": {
      "ticket_number": "TKT-0142",
      "plate": "ABC 1234",
      "vehicle_make": "Toyota",
      "vehicle_model": "Vios",
      "vehicle_color": "White",
      "time_in": "2026-03-24T02:18:00.000Z",
      "time_out": "2026-03-24T05:47:00.000Z",
      "duration": "3h 29m",
      "parking_slot": "B-04",
      "valet_in": "Carlos Mendoza",
      "valet_out": "Pedro Santos",
      "flat_rate_label": "Flat Rate (first hour)",
      "flat_rate_amount": 150,
      "succeeding_time_label": "Succeeding Time (2 hour/s @ 30.00)",
      "succeeding_rate_amount": 30,
      "total_amount": 180
    },
    "condition_comparison": []
  },
  "compute": {
    "duration_minutes": 209,
    "breakdown": {
      "base": 150,
      "extra": 30,
      "overnight": 0
    },
    "total": 180
  }
}
```

`compute` matches `GET /transactions/:id/compute` (duration + base/extra/overnight breakdown). `preview.ticket.total_amount` equals `compute.total`.

`preview.condition_comparison` is **empty** at preview time. Compare check-in vs new checkout marks in the app locally until check-out.

**UI mapping**

| Screen | Fields |
|--------|--------|
| Vehicle Review — Vehicle info | `transaction.*` (customer, vehicle, parking, belongings, `time_in`, `driver_in`, `valet_type`) |
| Vehicle Review — Condition | `transaction.condition_checkin`; **new** checkout marks kept in **app state only** |
| Payment | `preview.ticket` (times, rate lines, `total_amount`); `compute.breakdown` for base/extra/overnight; cash tendered / change **local only** |
| Checkout summary | `POST check-out` response (same as checkout-preview + `invoice_number`; cash tendered / change **local only**) |

While `status` is `active`, use `preview.ticket.time_out` as projected checkout time (not `transaction.time_out`, which stays `null` until confirm).

---

### Step 3 — `POST /transactions/:id/check-out` — Confirm and finalize checkout

Final step. Send **`driver_out`** and **`condition_checkout`** here when the user completed the condition screen.

**Request**

```
POST /api/v1/transactions/:id/check-out
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "driver_out": "Pedro Santos",
  "condition_checkout": [
    { "zone": "Front Bumper", "type": "scratch", "x": 0.5, "y": 0.05 }
  ]
}
```

| Field | Required | Notes |
|-------|----------|--------|
| `driver_out` | No | Valet releasing the vehicle |
| `condition_checkout` | No | Omit if no new checkout marks. If **present** (including `[]`), server saves to DB and returns `condition_comparison` |

**Response 200**

Same shape as **`GET checkout-preview`**, plus top-level **`invoice_number`**. Timestamps and duration use the **actual** checkout `time_out` (not projected).

```json
{
  "invoice_number": "INV-0042",
  "transaction": {
    "id": "uuid",
    "ticket_number": "TKT-0142",
    "invoice_number": "INV-0042",
    "status": "completed",
    "customer": { "name": "Juan dela Cruz", "contact_number": "09171234567" },
    "vehicle": { "plate_number": "ABC 1234", "brand": "Toyota", "model": "Vios", "color": "White", "type": "sedan" },
    "parking": { "level": "Level 2", "slot": "B-04", "area": "Zone B" },
    "time_in": "2026-03-24T02:18:00.000Z",
    "time_out": "2026-03-24T05:47:00.000Z",
    "duration_minutes": 209,
    "amount": 180,
    "driver_in": "Carlos Mendoza",
    "driver_out": "Pedro Santos"
  },
  "preview": {
    "release_summary": {
      "plate": "ABC 1234",
      "customer": "Juan dela Cruz",
      "duration": "3h 29m"
    },
    "ticket": {
      "ticket_number": "TKT-0142",
      "plate": "ABC 1234",
      "time_in": "2026-03-24T02:18:00.000Z",
      "time_out": "2026-03-24T05:47:00.000Z",
      "duration": "3h 29m",
      "total_amount": 180
    },
    "condition_comparison": [
      { "zone": "Front Bumper", "type": "scratch", "x": 0.5, "y": 0.05, "is_new": true }
    ]
  },
  "compute": {
    "duration_minutes": 209,
    "breakdown": { "base": 150, "extra": 30, "overnight": 0 },
    "total": 180
  }
}
```

`preview.condition_comparison` is populated when `condition_checkout` was sent on this request; otherwise `[]`.

`transaction.time_out`, `preview.ticket.time_out`, and `compute.duration_minutes` all reflect the finalized checkout time.

After success the ticket is **COMPLETED**. The server persists **`amount`** (amount collected) and, when provided, **`conditionCheckout`** on the ticket.

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

### `GET /reports/transactions` — Reports Transactions tab (mobile)

Paginated transaction list for the tablet **Reports → Transactions** screen. Scoped to the authenticated cashier; **requires an open cash shift** (same as the app gate before calling this endpoint).

**Request**

```
GET /api/v1/reports/transactions?date_from=2026-05-30&date_to=2026-05-30&limit=20&page=1&sort=desc
Authorization: Bearer <token>
```

| Query param | Type | Notes |
|---|---|---|
| `search` | string | Plate search |
| `status` | string | `active`, `completed`, `lost`, `parked`, `long_stay` |
| `date_from` | `YYYY-MM-DD` | Start of range (inclusive) |
| `date_to` | `YYYY-MM-DD` | End of range (inclusive) |
| `sort` | string | `asc` or `desc` (default `desc`) |
| `limit` | number | Page size (app uses `20`) |
| `page` | number | 1-based |

**Response 200**

```json
{
  "total": 42,
  "page": 1,
  "limit": 20,
  "totalPages": 3,
  "data": [
    {
      "id": "uuid",
      "ticket_number": "TKT-0123",
      "plate_number": "ABC1234",
      "vehicle": "Toyota Vios",
      "color": "White",
      "time_in": "08:00",
      "time_out": "10:30",
      "duration_minutes": 150,
      "duration_display": "1h 20m",
      "slot": "A-12",
      "status": "active",
      "amount": 150
    }
  ]
}
```

**Mobile mapping** (`ReportsCubit` / `TransactionsApi.fetchReportsTransactions`):

- Status dropdown: All Status → omit param; Parked → `active`; Long Stay → `long_stay`; Checked Out → `completed`
- Date range: both `date_from` and `date_to` sent as inclusive `YYYY-MM-DD` (Manila calendar days)
- Row tap → `GET /api/v1/transactions/{id}` via `detailId` (server UUID)

---

## 6. Transaction Lookup

Returns the full transaction shape. The app resolves from local Drift first; this is a fallback for cross-device lookups. **Check-out** uses `GET /transactions/:id/checkout-preview` instead (see §5); `GET /tickets/by-number/{ticketNumber}` is not used.

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
  "printed_at": null
}
```

> `amount` is the **amount collected** (parking fee) once checkout completes. Legacy keys `amount_paid`, `change`, and `payment_method` may still appear on some responses as `null` — ignore them; they are not part of the product model.

> Tickets with status `completed`, `lost`, or `void` return **409 Conflict** from transaction lookup / checkout-preview. Handle this by displaying the ticket's final state from local storage.

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
| `GET` | `/transactions/:id/checkout-preview` | Bearer | Full ticket + pricing preview + compute breakdown (no checkout condition) |
| `POST` | `/transactions/:id/check-out` | Bearer | Confirm checkout → marks COMPLETED |
| `POST` | `/transactions/:id/print-log` | Bearer | Log ticket print |
| `GET` | `/transactions/:id` | Bearer | Lookup by UUID or TKT-XXXX *(not used on checkout scan)* |
| `GET` | `/transactions` | Bearer | List / reports sync |
| `POST` | `/tickets/:id/lost` | Bearer | Mark ticket lost *(reserved)* |
| `GET` | `/branches/:id` | Bearer | Branch hours |
| `GET` | `/branches/:id/rates` | Bearer | Standard branch rates |
| `GET` | `/rates/branches/:branchId/vehicle-types` | Bearer | Per-vehicle-type rates |
| `GET` | `/settings` | Bearer | System config + overnight cutoff |

---

## 10. Device presence (WebSocket)

Admins see tablet **ONLINE** / **OFFLINE** in real time. **OFFLINE** means the tablet is **not connected** to the server (not the same as an unclaimed `IDLE` slot).

After login (with `server_device_id` from claim), the app must keep a Socket.io connection open while the cashier session is active.

### Connect

```
URL: wss://<server>/realtime
Library: socket_io_client (Dart)
```

Handshake `auth`:

```json
{
  "token": "<accessToken from POST /auth/login>",
  "clientType": "mobile",
  "server_device_id": "<device row UUID from claim>"
}
```

### Lifecycle

| App action | Expected |
|------------|----------|
| Login success + `server_device_id` known | Connect presence socket |
| App foreground / resume | Ensure socket connected |
| Logout | Disconnect socket |
| Token invalid / re-login | Disconnect old socket; connect with new token |

Server sets the device row to `ONLINE` on connect and `OFFLINE` ~15s after disconnect (configurable `DEVICE_PRESENCE_GRACE_MS`). Claim/rebind alone sets `OFFLINE` until the first presence connection.

The tablet does **not** need to listen for branch events—presence only.

See [`valet-api/docs/REALTIME.md`](valet-api/docs/REALTIME.md) for admin subscription and nginx proxy notes.

---

*Guide generated against `valet-api/` — last verified May 2026.*
