# Mobile Cashier API Sync Guide

Standalone contract reference for the **Valet Master cashier app** (Android/iOS). Use this document alone to align local models, sync logic, and UI with the live API.

**API base:** `https://<host>/api/v1`  
**Auth:** `Authorization: Bearer <access_token>` on all routes below unless noted.  
**JSON naming:** transaction/list/detail payloads use **snake_case** for new fields.  
**Time format:** `HH:mm` (24-hour) for overnight window fields.

**Live reference (optional):** Swagger at `http://<host>/api/docs` when the API is running.

---

## 1. Who this guide is for

| Audience | Use this guide to |
|----------|-------------------|
| Mobile developers | Update DTOs, offline queue, and screens after an API deploy |
| QA | Verify void, check-in, checkout, and rates behavior against current contract |
| Backend | Keep Swagger/examples in sync when changing cashier-facing routes |

This guide does **not** cover the admin dashboard API surface (camelCase tickets admin routes are listed only where cashiers call them, e.g. void).

---

## 2. Breaking changes at a glance

| Area | What changed | Mobile action |
|------|----------------|---------------|
| **Void** | No approval workflow; no `void_request` object | Use `status: "void"` + `void_reason`, `voided_by`, `voided_at` |
| **Void routes** | `POST /tickets/:id/void/approve` and `/reject` removed | Delete approve/reject calls and pending-void UI |
| **Check-out** | `applied_rate` required on `POST .../check-out` | Send rate snapshot from checkout-preview `rates` |
| **Overnight window** | Per-branch; snake_case keys; not in settings | Sync from branch/rates endpoints |
| **Vehicle model** | `vehicle.model` always `null` in responses | Display `brand` / `type`; keep sending model on check-in if known |
| **Deprecated** | `POST /tickets/check-in`, `POST /transactions/:id/pay` | Use transactions check-in and checkout-preview + check-out |

---

## 3. Void workflow (current contract)

### 3.1 Rules

- Void is **immediate** from the cashier — no admin approval, no `PENDING` state.
- Primary signal: **`status: "void"`** on transaction-shaped responses.
- Audit fields are **flat** on the ticket (always present; `null` when not voided).
- Voided tickets **cannot** checkout or preview checkout (409 — not active).
- There is **no** “pending void blocks checkout” rule anymore.

### 3.2 Remove from the mobile app

| Remove | Use instead |
|--------|-------------|
| `void_request` object in API models / DB | `void_reason`, `voided_by`, `voided_at` |
| `void_request.status` (`pending` / `approved` / `rejected`) | `status === "void"` |
| `void_request.requested_by` | `voided_by` |
| `void_request.requested_at` / `reviewed_at` | `voided_at` |
| `void_request.reviewed_by`, `reviewed_note` | Dropped |
| Pending-void UI, admin inbox, approve/reject | Not applicable |
| `POST /tickets/:id/void/approve` or `/reject` | Removed (404) |

### 3.3 Response fields (transactions API)

Present on every **transaction-shaped** response:

- `GET /transactions` (list items)
- `GET /transactions/:id`
- `POST /transactions/check-in` (and express wrapper `transaction`)
- `PATCH /transactions/:id`
- `GET /transactions/:id/checkout-preview` → `transaction`
- `POST /transactions/:id/check-out` → `transaction`
- `GET /reports/today` → `currently_parked[]`
- `GET /reports/transactions` → `data[]`
- `GET /dashboard/summary` → `recent_transactions[]`

| Field | Type | When set |
|-------|------|----------|
| `void_reason` | `string \| null` | Reason (max 500 chars) |
| `voided_by` | `{ id, username, name } \| null` | Cashier who voided |
| `voided_at` | ISO-8601 \| null` | When void was applied |

**Active ticket:**

```json
{
  "status": "parked",
  "void_reason": null,
  "voided_by": null,
  "voided_at": null
}
```

**Voided ticket:**

```json
{
  "status": "void",
  "void_reason": "Duplicate entry — void at check-in.",
  "voided_by": {
    "id": "cashier-uuid",
    "username": "cashier1",
    "name": "Ana Lopez"
  },
  "voided_at": "2026-05-16T10:00:00.000Z"
}
```

List items use mobile `status` values (`parked`, `long_stay`, `completed`, `lost`, `void`, `draft`). Full detail uses lowercase ticket status (`active`, `void`, `completed`, etc.).

### 3.4 Void after check-in (online)

```http
POST /api/v1/tickets/:id/void
Authorization: Bearer <token>
Content-Type: application/json
```

**Body (optional):**

```json
{ "reason": "Wrong plate entered." }
```

| | |
|--|--|
| **Role** | `CASHIER` |
| **`:id`** | Ticket UUID |
| **Success** | Ticket `VOID`, slot released, flat void fields set |
| **409** | Ticket not `ACTIVE` |

**Note:** Cashier void uses the **tickets** route (`/tickets/:id/void`). Response uses camelCase ticket shape (`voidReason`, `voidedBy`, `voidedAt`). Map to your local transaction model if you unify storage.

### 3.5 Void at intake (offline sync)

Same request as normal check-in — **no new required fields**.

```http
POST /api/v1/transactions/check-in
Content-Type: multipart/form-data
```

| Form field | Value | Notes |
|------------|-------|--------|
| `ticket_number` | required | Same as normal check-in |
| `void_requested` | `true`, `1`, or `yes` | Void in one call |
| `void_reason` | optional string | Max 500 chars |

**Server behavior:**

- Creates ticket with `status: void` (no slot occupy).
- Returns full transaction with flat void fields populated.
- **400** if express one-shot (`void_requested` + `amount` on express cashier).

**Offline queue:** Send **one** check-in with `void_requested=true`. Do **not** also queue `POST /tickets/:id/void` for the same ticket after sync.

**Online:** Use void-at-intake **or** void after check-in — not both for the same mistake.

### 3.6 Void migration checklist

1. Remove `void_request` from API models, SQLite/Room schema, and sync mappers.
2. Add `void_reason`, `voided_by` (id, username, name), `voided_at`.
3. Treat `status === "void"` (list) or `status === "void"` (detail) as voided.
4. Remove ticket from parked/active lists after void; hide checkout actions.
5. Show `void_reason` and `voided_by.name` on detail; optional `voided_at`.
6. Delete approve/reject API calls and any pending-void UI.
7. Keep check-in request fields `void_requested` / `void_reason` unchanged for offline void.

---

## 4. Core cashier flows (unchanged paths)

### 4.1 Standard flow (non-express)

```
POST /transactions/check-in     → ACTIVE
GET  /transactions/:id/checkout-preview
POST /transactions/:id/check-out → COMPLETED (+ invoice_number)
```

`:id` = ticket UUID, ticket number, or active plate (normalized uppercase).

### 4.2 Express flow

```
POST /transactions/check-in  (with amount)  → COMPLETED in one call
```

Express cashiers must not use checkout-preview / check-out for the one-shot path.

### 4.3 Check-out request (required `applied_rate`)

```http
POST /api/v1/transactions/:id/check-out
```

**Body must include** `applied_rate` — copy from checkout-preview `rates`:

```json
{
  "amount": 150,
  "time_out": "2026-05-16T14:00:00.000Z",
  "applied_rate": {
    "flat_rate": 150,
    "flat_rate_hours": 3,
    "succeeding_rate": 30,
    "overnight_fee": 100,
    "lost_ticket_fee": 500,
    "overnight_start_time": "01:30",
    "overnight_end_time": "06:00"
  }
}
```

Optional: `cash_tendered`, `driver_out`, `condition_checkout`, `ticket_lost`, `is_overnight`, `preview`.

**Response:** `invoice_number`, `transaction` (with `applied_rate` snapshot), `preview`.

Persist `applied_rate` from responses for receipts and offline reprints.

### 4.4 Partial update

```http
PATCH /api/v1/transactions/:id
```

Partial groups: `customer`, `vehicle`, `parking`, `condition_checkin`, `notes`, `valet_type`, `driver_in`, `driver_out`, `condition_checkout`, `vr_no`, optional `status: "active"` to finalize draft steps.

---

## 5. Rates and overnight window

### 5.1 Per-branch overnight (not global settings)

The cashier app **does not** call `GET /settings`. Load overnight window from branch/rates sync:

| Method | Path | Fields |
|--------|------|--------|
| `GET` | `/branches` | `overnight_start_time`, `overnight_end_time` per branch |
| `GET` | `/branches/:id` | Same |
| `GET` | `/rates/branches/:branchId` | Top-level overnight keys + `vehicleTypeRates[]` (no `standardRates`) |
| `GET` | `/rates/branches/:branchId/vehicle-types` | Duplicated on each row |
| `GET` | `/transactions/:id/checkout-preview` | `rates.overnight_start_time`, `rates.overnight_end_time` |

**Keys (snake_case):** `overnight_start_time`, `overnight_end_time` (`HH:mm`).  
**Server default if missing:** `01:30` – `06:00`.

Do **not** expect `overnightStartTime` / `overnightEndTime` on branch/rates reads.

### 5.2 Rates sync route

`GET /rates/branches/:branchId` returns `{ branch, areaOverrides, vehicleTypeRates, overnight_start_time, overnight_end_time }`. Sync pricing from **`vehicleTypeRates[]`** keyed by `vehicle_type`. Legacy branch `standardRates` is **removed** (2026-06-09).

When checkout-preview returns `flat_rate: 0` and `succeeding_rate: 0`, the app falls back to the **Drift cache** from the last rates sync (full row: flat, succeeding, overnight, lost ticket, hours, overnight window). If both preview and cache are zero, checkout proceeds at ₱0 — admin must configure branch vehicle-type rates.

---

## 6. Other response rules

| Topic | Rule |
|-------|------|
| `vehicle.model` | Always `null` in API responses; still accepted on check-in/PATCH |
| `payment_method` / `paymentMethod` | Always `null` on all transaction and ticket API responses (redacted) |
| `vr_no` | Optional on check-in/PATCH; returned on list/detail when set |
| `GET /transactions/:id` | Returns completed and void tickets (historical view) |
| Reports search | `GET /reports/transactions` — `search` matches plate **or** ticket number |

---

## 7. Cashier endpoint reference

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/auth/login` | Login |
| `POST` | `/auth/refresh` | Refresh token |
| `GET` | `/branches/:branchId/areas/:areaId` | Parking slots for check-in |
| `POST` | `/transactions/check-in` | Check-in (multipart) |
| `GET` | `/transactions` | Transaction list |
| `GET` | `/transactions/:id` | Transaction detail |
| `PATCH` | `/transactions/:id` | Partial update |
| `GET` | `/transactions/:id/checkout-preview` | Rates + ticket for checkout UI |
| `POST` | `/transactions/:id/check-out` | Complete checkout |
| `POST` | `/tickets/:id/void` | Void active ticket |
| `GET` | `/reports/today` | Shift summary + `currently_parked` |
| `GET` | `/reports/transactions` | Shift transaction list |
| `GET` | `/dashboard/summary` | Cashier dashboard |
| `GET` | `/rates/branches/:branchId` | Rates + overnight for branch |
| `GET` | `/rates/branches/:branchId/vehicle-types` | Per vehicle type rates |

---

## 8. Do not use (removed or deprecated)

| Method | Path | Status | Use instead |
|--------|------|--------|-------------|
| `POST` | `/tickets/check-in` | **410 Gone** | `POST /transactions/check-in` |
| `POST` | `/transactions/:id/pay` | **410 Gone** | checkout-preview + check-out |
| `POST` | `/tickets/:id/void/approve` | **404** | N/A — void is immediate |
| `POST` | `/tickets/:id/void/reject` | **404** | N/A |
| `GET` | `/settings` | Not used by cashier app | Local config + branch/rates sync |

Legacy `POST /tickets/:id/check-out` and `/lost` exist for admin; mobile should use transactions checkout.

---

## 9. Field naming quick reference

| Concept | Transactions API (cashier) | Tickets API (void response only) |
|---------|----------------------------|----------------------------------|
| VR number | `vr_no` | `vrNo` |
| Void reason | `void_reason` | `voidReason` |
| Voided by | `voided_by` | `voidedBy` |
| Voided at | `voided_at` | `voidedAt` |
| Overnight window | `overnight_start_time`, `overnight_end_time` | Same on branch/rates |
| Rate snapshot | `applied_rate` | `applied_rate` on ticket reads |
| Payment method | `payment_method` (always `null`) | `paymentMethod` (always `null`) |
| List status | `parked`, `long_stay`, `void`, … | — |
| Detail status | `active`, `void`, `completed`, … | `ACTIVE`, `VOID`, … |

---

## 10. Full app sync checklist

Use after pulling a new API build:

- [ ] Rates: sync from `vehicleTypeRates[]` / `vehicle_type` slug; no `standardRates` on branch rates endpoint
- [ ] Checkout: when preview parking fees are zero, use Drift rates cache; verify `applied_rate` sent on check-out
- [ ] Void: drop `void_request`; add flat void fields; remove pending/approve UI
- [ ] Check-out: always send `applied_rate` from preview/cache
- [ ] Overnight: read snake_case keys from branch/rates; drop settings sync
- [ ] Vehicle: do not read `vehicle.model` from API
- [ ] Confirm deprecated routes return 410/404 and are not called
- [ ] Offline queue: void-at-intake uses `void_requested` only (no follow-up void POST)
- [ ] Smoke: check-in → preview → check-out; void active ticket; void-at-intake sync

---

## Appendix — Change log (by date)

| Date | Summary |
|------|---------|
| 2026-06-09 | Branch rates: `standardRates` removed from `GET /rates/branches/:branchId`; pricing is `VehicleTypeRate` rows keyed by `vehicle_type`; `PUT`/`DELETE /branches/:id/rates` removed |
| 2026-06-09 | Checkout preview may return zero parking fees when branch VT row missing; app falls back to Drift rates cache |
| 2026-06-01 | Void: immediate + flat fields; `void_request` removed; approve/reject routes removed |
| 2026-06-01 | Check-out: required `applied_rate` on request and response |
| 2026-06-01 | Overnight: per-branch; snake_case; removed from settings |
| 2026-06-01 | `vehicle.model` redacted in responses |
| 2026-06-01 | `vr_no` on check-in and transaction payloads |
| 2026-06-01 | `PATCH /transactions/:id` reactivated |
| 2026-06-01 | `GET /transactions/:id` allows completed/void history |

---

*Backend maintainers: when changing cashier-facing contracts, update this guide, `valet-api` Swagger (`*.swagger.ts`, controller decorators), and run `npm run build` in `valet-api/`.*
