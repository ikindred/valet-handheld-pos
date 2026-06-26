# Batch checkout API — mobile contract (draft for backend)

**Endpoint:** `POST /api/v1/transactions/check-out`  
**Content-Type:** `application/json`  
**Auth:** `Authorization: Bearer <token>`

Used for **offline sync flush only** — all pending `checkout/finalize` queue rows in one request.

Online single checkout stays `POST /api/v1/transactions/{id}/check-out` (not this endpoint).

---

## 1. Request payload

Top-level **JSON array** (not wrapped). Array order matches pending queue order (oldest first).  
`index` in the response refers to position in this array (0-based).

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "amount": 180,
    "time_out": "2026-03-24T05:47:00.000Z",
    "is_overnight": false,
    "ticket_lost": false,
    "applied_rate": {
      "flat_rate": 150,
      "flat_rate_hours": 3,
      "succeeding_rate": 30,
      "overnight_fee": 500,
      "lost_ticket_fee": 200,
      "overnight_start_time": "22:00",
      "overnight_end_time": "05:00"
    },
    "cash_tendered": 200,
    "driver_out": "Pedro Santos",
    "condition_checkout": [
      {
        "zone": "Front bumper",
        "type": "scratch",
        "x": 0.05,
        "y": 0.5
      }
    ],
    "preview": {}
  },
  {
    "id": "TKT-260626-4A12-091200",
    "amount": 120,
    "time_out": "2026-03-24T06:00:00.000Z",
    "is_overnight": false,
    "ticket_lost": false,
    "applied_rate": {
      "flat_rate": 150,
      "flat_rate_hours": 3,
      "succeeding_rate": 30,
      "overnight_fee": 500,
      "lost_ticket_fee": 200,
      "overnight_start_time": "22:00",
      "overnight_end_time": "05:00"
    },
    "cash_tendered": 150,
    "driver_out": "Ana Valet",
    "condition_checkout": [],
    "preview": {}
  }
]
```

### Per-item fields

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `id` | string | yes | Server transaction UUID when known; else local `TKT-…`. BE may also accept active plate. |
| `amount` | number | yes | Total charged at checkout |
| `time_out` | string | yes | UTC ISO-8601 with `Z` |
| `is_overnight` | boolean | yes | |
| `ticket_lost` | boolean | yes | |
| `applied_rate` | object | yes | Rate snapshot used at checkout (see below) |
| `cash_tendered` | number | yes when cash | Amount received |
| `driver_out` | string | optional | Valet who returned the vehicle |
| `condition_checkout` | array | yes | Damage markers at checkout (may be `[]`) |
| `preview` | object | yes | **Empty `{}` only** — do not echo GET checkout-preview blocks in the request |

### `applied_rate` object

| Field | Type |
|-------|------|
| `flat_rate` | number |
| `flat_rate_hours` | number |
| `succeeding_rate` | number |
| `overnight_fee` | number |
| `lost_ticket_fee` | number |
| `overnight_start_time` | string (`"HH:mm"`) |
| `overnight_end_time` | string (`"HH:mm"`) |

---

## 2. Expected response

Same envelope as batch check-in: `results[]` + `summary`.  
Mobile matches rows by **`index`** and **`ticket_number`** (local `TKT-…`).

### 2.1 Per-item fields in `results[]`

| Field | Required | Purpose |
|-------|----------|---------|
| `index` | yes | Position in request array (0-based) |
| `status` | yes | `"success"` or `"failed"` — **sync outcome for this line** |
| `ticket_number` | yes | Client `TKT-…`; primary local match key |
| `plate_number` | yes | Echo (empty string ok) |
| `vr_no` | yes | Echo (empty string ok) |
| `server_transaction_id` | success only | Server UUID (not `TKT-…`) |
| `transaction` | optional | Minimal server state when needed (see below) |
| `error` | failed only | `{ "status_code", "message", "code"? }` |

**Two different statuses:**

- `results[i].status` — did this batch line succeed? → mobile marks **synced** or **failed**
- `transaction.status` — server ticket state after success (e.g. `completed`, `lost`) → optional local update only

Do **not** duplicate correlation fields inside `transaction` (no nested `ticket_number`, `vehicle`, `amount`, etc.).

### 2.2 `summary` (required on processed responses)

```json
{
  "total": 2,
  "succeeded": 2,
  "failed": 0
}
```

### 2.3 HTTP status codes

| HTTP | When |
|------|------|
| **200** | Processed — body includes `results` + `summary` (all success, mixed, or all items failed at item level) |
| **201** / **207** | Accept while BE stabilizes if body includes `results` + `summary` |
| **400** | Unprocessable batch **without** `results[]` (empty array, invalid JSON, etc.) |
| **400** with `results[]` | Parse per line like 200 |
| **401** | Missing or invalid Bearer token |

Per-item outcomes live in `results[].status`, not only in the HTTP status code.

---

## 3. Response examples

### 3.1 All succeeded (HTTP 200)

```json
{
  "results": [
    {
      "index": 0,
      "status": "success",
      "ticket_number": "TKT-260626-3EF8-081735",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "server_transaction_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "transaction": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "status": "completed"
      }
    },
    {
      "index": 1,
      "status": "success",
      "ticket_number": "TKT-260626-4A12-091200",
      "plate_number": "XYZ9876",
      "vr_no": "EP432625",
      "server_transaction_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "transaction": {
        "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
        "status": "lost"
      }
    }
  ],
  "summary": {
    "total": 2,
    "succeeded": 2,
    "failed": 0
  }
}
```

`transaction` may be omitted or `{}` when `server_transaction_id` is present and no extra server state is needed.

### 3.2 Mixed success and failure (HTTP 200)

```json
{
  "results": [
    {
      "index": 0,
      "status": "success",
      "ticket_number": "TKT-260626-3EF8-081735",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "server_transaction_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    },
    {
      "index": 1,
      "status": "failed",
      "ticket_number": "TKT-260626-4A12-091200",
      "plate_number": "XYZ9876",
      "vr_no": "EP432625",
      "error": {
        "status_code": 409,
        "code": "ALREADY_CHECKED_OUT",
        "message": "Transaction is already completed."
      }
    }
  ],
  "summary": {
    "total": 2,
    "succeeded": 1,
    "failed": 1
  }
}
```

### 3.3 All items failed (HTTP 200)

```json
{
  "results": [
    {
      "index": 0,
      "status": "failed",
      "ticket_number": "TKT-260626-3EF8-081735",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "error": {
        "status_code": 404,
        "code": "TRANSACTION_NOT_FOUND",
        "message": "Transaction not found."
      }
    },
    {
      "index": 1,
      "status": "failed",
      "ticket_number": "TKT-260626-4A12-091200",
      "plate_number": "XYZ9876",
      "vr_no": "EP432625",
      "error": {
        "status_code": 409,
        "code": "ALREADY_CHECKED_OUT",
        "message": "Transaction is already completed."
      }
    }
  ],
  "summary": {
    "total": 2,
    "succeeded": 0,
    "failed": 2
  }
}
```

### 3.4 Unprocessable batch (HTTP 400, no `results`)

```json
{
  "statusCode": 400,
  "message": "Request body must be a non-empty array",
  "error": "Bad Request"
}
```

---

## 4. Mobile sync tagging (reference)

| `results[i].status` | `sync_queue` | Local ticket |
|---------------------|--------------|--------------|
| `"success"` | `synced` | `sync_status: synced` |
| `"failed"` | `failed` (retry) | stays `pending` |

Optional: `409` + `ALREADY_CHECKED_OUT` may be reconciled as success if the server already completed the checkout.
