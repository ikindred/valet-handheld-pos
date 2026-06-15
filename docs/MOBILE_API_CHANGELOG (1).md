# Mobile Cashier API Sync Guide

Standalone contract reference for the **Valet Master cashier app** (Android/iOS). Use this document alone to align local models, sync logic, and UI with the live API.

**API base:** `https://<host>/api/v1`  
**Auth:** `Authorization: Bearer <access_token>` on all routes below unless noted.  
**JSON naming:** transaction/list/detail payloads use **snake_case** for new fields.  
**Time format:** `HH:mm` (24-hour) for overnight window fields.

**Live reference (optional):** Swagger at `http://<host>/api/docs` when the API is running.

---

## 2026-06-09 — Modified endpoints (check these first)

Grep the cashier app for these paths and align before other sections below.

| Method | Path | Change |
|--------|------|--------|
| `GET` | `/rates/branches/:branchId` | Response **no longer includes `standardRates`**. Use `vehicleTypeRates[]` keyed by `vehicle_type`. |
| `PUT` | `/branches/:id/rates` | **Removed** — stop calling. |
| `DELETE` | `/branches/:id/rates` | **Removed** — stop calling. |
| `GET` | `/transactions/:id/checkout-preview` | **Behavior only** — `rates` shape unchanged; values may be **0** when no branch VT row for ticket `vehicle_type`. |
| `POST` | `/transactions/:id/check-out` | **Behavior only** — `preview.rates` / server-built preview may differ when branch VT row is missing (same shape). |

**Unchanged:** `GET /branches/:id/rates`, `GET /rates/branches/:branchId/vehicle-types`, `GET /branches`, check-in, void, cash sessions, dashboard, reports.

**Deploy:** `npx prisma db push` in `valet-api/` (drops `branch_rates` table).

---

## Who this guide is for

| Audience | Use this guide to |
|----------|-------------------|
| Mobile developers | Update DTOs, offline queue, and screens after an API deploy |
| QA | Verify void, check-in, checkout, and rates behavior against current contract |
| Backend | Keep Swagger/examples in sync when changing cashier-facing routes |

---

## 2026-06-09 — Remove legacy branch standard rates (`BranchRate`)

The `branch_rates` table and legacy “branch standard rate” row are **removed**. All branch pricing is **`VehicleTypeRate` rows keyed by `vehicle_type`**. Area overrides unchanged.

### Pricing resolution (server-side, unchanged order except last fallback removed)

1. Area vehicle-type override (`AreaVehicleTypeRate` matched by ticket `vehicle.type` slug → `vehicle_type`)
2. Area scalar override (`Area.flatRate`, …)
3. Branch vehicle-type rate (`VehicleTypeRate` matched by `vehicle_type`)
4. ~~Branch standard scalar row~~ **removed** — if no branch VT row exists for the ticket type, numeric rate fields resolve to **0** (`lost_ticket_fee` still floors at **200** when unset)

### Full endpoint checklist

Use this table to grep your app for each path. **Modified** = response shape or behavior changed. **Removed** = stop calling. **Unchanged** = safe to keep as-is.

| Status | Method | Path | What changed |
|--------|--------|------|--------------|
| **Modified** | `GET` | `/rates/branches/:branchId` | Response **no longer includes `standardRates`**. Payload is `{ branch, areaOverrides, vehicleTypeRates, overnight_start_time, overnight_end_time }` only. |
| **Removed** | `PUT` | `/branches/:id/rates` | Endpoint deleted. Do not write branch “standard” rates here. |
| **Removed** | `DELETE` | `/branches/:id/rates` | Endpoint deleted. |
| **Unchanged** | `GET` | `/branches/:id/rates` | Still returns display rates derived from vehicle-type rows (prefers sedan) + overnight window. **Not** the removed legacy table. |
| **Unchanged** | `GET` | `/rates/branches/:branchId/vehicle-types` | Primary rates sync path. Each row includes `vehicle_type`, `name`, rate fields, `status`, overnight window. |
| **Unchanged** | `GET` | `/branches`, `/branches/:id` | `rate` on branch object is still a **computed** summary from vehicle-type rates (same shape as before). |
| **Unchanged** | `GET` | `/branches/:id/areas`, `/branches/:id/areas/:areaId` | Area + area VT overrides unchanged. |
| **Behavior only** | `GET` | `/transactions/:id/checkout-preview` | Response **`rates` object shape unchanged**. Values may be **0** when branch has no ACTIVE VT row for the ticket’s `vehicle_type` (previously could fall back to legacy standard row). |
| **Behavior only** | `POST` | `/transactions/:id/check-out` | No request field changes. Server-built `preview` (when sent or rebuilt) uses same rate resolution as checkout-preview. |
| **Unchanged** | `POST` | `/transactions/check-in`, `PATCH` ticket, void, cash sessions, dashboard, reports | No request/response field changes from this deploy. |

### Mobile action items

| Area | Action |
|------|--------|
| **Local rate models** | Remove `standardRates` / legacy “branch standard” object from `GET /rates/branches/:branchId` parsing. Sync pricing from `vehicleTypeRates[]` keyed by `vehicle_type`. |
| **Offline cache** | Ensure all six slugs have ACTIVE rows after sync: `sedan`, `suv`, `van`, `luxury`, `ev_phev`, `motorcycle`. |
| **Removed API calls** | Delete any `PUT`/`DELETE` to `/branches/:id/rates` (admin-only; unlikely in cashier app). |
| **`GET /branches/:id/rates`** | Still valid for a single “display standard” row + overnight window; underlying source is VT rates, not a separate table. |
| **Checkout preview** | No DTO change; verify pricing when a branch is missing a VT row for a vehicle type (expect zeros except lost-ticket floor). |

### Related (prior deploy — still required on older DBs)

If not already applied: `vehicle_type` enum on rate rows — see `MOBILE_INTEGRATION_GUIDE.md`. Run `npm run backfill:vehicle-type-kind` after `db push` when upgrading from pre–2026-06-09 schema.
