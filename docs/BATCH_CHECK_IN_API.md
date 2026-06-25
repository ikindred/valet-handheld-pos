# Batch check-in API — mobile contract (draft for backend)

**Endpoint:** `POST /api/v1/transactions/check-in`  
**Content-Type:** `application/json`  
**Auth:** `Authorization: Bearer <token>`

Used for:

- **Online check-in** — `check_ins` array with **1** item
- **Offline sync** — `check_ins` array with **all** pending check-in rows for that flush

Cashier mode is determined from **JWT `user.express_cashier`** (not from the request body).  
A single request contains **only one type** of item (all normal **or** all express).

---

## 1. Request — normal cashier (full check-in)

```json
{
  "check_ins": [
    {
      "ticket_number": "TKT-260625-A1B2-143052",
      "slot_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "contact_number": "09171234567",
      "valet_type": "standard_valet",
      "vehicle": {
        "plate_number": "ABC1234",
        "brand": "Toyota",
        "color": "White",
        "type": "sedan"
      },
      "belongings": ["Umbrella", "Child seat"],
      "damages": [
        {
          "zone": "Front bumper",
          "type": "scratch",
          "x": 0.42,
          "y": 0.18
        }
      ],
      "vr_no": "EP432624",
      "customer_name": "Juan Dela Cruz",
      "driver_in": "Pedro Valet",
      "notes": "VIP — park near entrance",
      "signature_base64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
      "signature_content_type": "image/png"
    }
  ]
}
```

### Normal — void at intake (offline void sync)

Same endpoint and wrapper. Item uses void fields; server creates ticket with `status: void`.

```json
{
  "check_ins": [
    {
      "ticket_number": "TKT-260625-A1B2-143215",
      "slot_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "contact_number": "09987654321",
      "valet_type": "self_park",
      "vehicle": {
        "plate_number": "XYZ9876",
        "brand": "Honda",
        "color": "Black",
        "type": "suv"
      },
      "belongings": [],
      "damages": [],
      "vr_no": "EP432625",
      "driver_in": "Ana Valet",
      "void_requested": true,
      "void_reason": "Duplicate entry — void at check-in.",
      "signature_base64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
      "signature_content_type": "image/png"
    }
  ]
}
```

---

## 2. Request — express cashier (one-shot completed)

JWT must have `user.express_cashier: true`. No slot, signature, belongings, or damages.

```json
{
  "check_ins": [
    {
      "ticket_number": "TKT-260625-A1B2-150101",
      "vehicle": {
        "plate_number": "NIA4567"
      },
      "amount": 150.0,
      "vr_no": "EP500101",
      "driver_in": "Maria Cashier",
      "driver_out": "Maria Cashier"
    },
    {
      "ticket_number": "TKT-260625-A1B2-150245",
      "vehicle": {
        "plate_number": "DEF2468"
      },
      "amount": 200.0,
      "vr_no": "EP500102",
      "driver_in": "Carlos Cashier"
    }
  ]
}
```

---

## 3. Expected response (mobile requirement)

Mobile tags local rows **synced** or **failed** from `results[]`.  
Each result **must** echo the client correlation fields we sent:

| Field | Required on every result | Purpose |
|-------|--------------------------|---------|
| `index` | yes | Position in request `check_ins` (0-based) |
| `status` | yes | `"success"` or `"failed"` |
| `ticket_number` | yes | Client-generated id (`TKT-…`); primary local match key |
| `plate_number` | yes | Normalized uppercase plate from request |
| `vr_no` | yes | VR from request |
| `server_transaction_id` | success only | Server UUID for checkout/PATCH later |
| `transaction` | success only (recommended) | Full transaction object (same shape as single check-in today) |
| `error` | failed only | `{ "status_code", "message", "code"? }` |

**Do not** put `error` on success lines.  
**Do not** use `ticket_number` as `server_transaction_id` — they are different values.

### 3.1 HTTP status codes (Option B — mobile preference)

| HTTP | When | Mobile action |
|------|------|---------------|
| **200** | Request accepted and **processed** — body always includes `results` + `summary` (all success, mixed, or **all items failed** at business/validation level) | Parse `results[]`; tag each row synced or failed from `status` |
| **400** | **Unprocessable request** — missing/invalid `check_ins` wrapper, empty array, wrong `Content-Type`, express fields on normal JWT (or vice versa), payload cannot be processed at all | Do **not** update queue rows; show error |
| **401** | Missing or invalid Bearer token | Do **not** update queue rows |

**Key rule:** per-item outcomes live in `results[].status`, **not** in the HTTP status code.  
Mobile uses a **single code path** on **200**: read `summary` + `results`, then apply per-row synced/failed.

`summary` is **required** on every **200** response.

| `summary` | Meaning |
|-----------|---------|
| `failed === 0` | All items synced locally |
| `failed > 0` && `succeeded > 0` | Partial sync — retry failed items on next flush |
| `succeeded === 0` | Nothing synced — still **HTTP 200** with per-line `error` objects |

---

## 4. Response examples

### 4.1 All succeeded (HTTP 200)

```json
{
  "results": [
    {
      "index": 0,
      "status": "success",
      "ticket_number": "TKT-260625-A1B2-143052",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "server_transaction_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "transaction": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "ticket_number": "TKT-260625-A1B2-143052",
        "status": "parked",
        "vr_no": "EP432624",
        "vehicle": {
          "plate_number": "ABC1234",
          "brand": "Toyota",
          "color": "White",
          "type": "sedan"
        }
      }
    },
    {
      "index": 1,
      "status": "success",
      "ticket_number": "TKT-260625-A1B2-143215",
      "plate_number": "XYZ9876",
      "vr_no": "EP432625",
      "server_transaction_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "transaction": {
        "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
        "ticket_number": "TKT-260625-A1B2-143215",
        "status": "void",
        "void_reason": "Duplicate entry — void at check-in.",
        "vr_no": "EP432625",
        "vehicle": {
          "plate_number": "XYZ9876"
        }
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

### 4.2 Mixed success and failure (HTTP 200)

```json
{
  "results": [
    {
      "index": 0,
      "status": "success",
      "ticket_number": "TKT-260625-A1B2-143052",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "server_transaction_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "transaction": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "ticket_number": "TKT-260625-A1B2-143052",
        "status": "parked",
        "vr_no": "EP432624"
      }
    },
    {
      "index": 1,
      "status": "failed",
      "ticket_number": "TKT-260625-A1B2-150245",
      "plate_number": "DEF2468",
      "vr_no": "EP500102",
      "error": {
        "status_code": 409,
        "code": "VR_NUMBER_ALREADY_EXISTS",
        "message": "VR number EP500102 already exists"
      }
    },
    {
      "index": 2,
      "status": "failed",
      "ticket_number": "TKT-260625-A1B2-150301",
      "plate_number": "GHI1357",
      "vr_no": "EP500103",
      "error": {
        "status_code": 400,
        "code": "VALIDATION_ERROR",
        "message": "slot_id is required"
      }
    }
  ],
  "summary": {
    "total": 3,
    "succeeded": 1,
    "failed": 2
  }
}
```

### 4.3 All items failed — business/validation (HTTP 200)

When every item fails (409 VR conflict, duplicate ticket, invalid slot, etc.), still return **200** with full `results` + `summary`. Mobile marks every row **failed** and retries on next sync.

```json
{
  "results": [
    {
      "index": 0,
      "status": "failed",
      "ticket_number": "TKT-260625-A1B2-150101",
      "plate_number": "NIA4567",
      "vr_no": "EP500101",
      "error": {
        "status_code": 409,
        "code": "VR_NUMBER_ALREADY_EXISTS",
        "message": "VR number EP500101 already exists"
      }
    },
    {
      "index": 1,
      "status": "failed",
      "ticket_number": "TKT-260625-A1B2-150245",
      "plate_number": "DEF2468",
      "vr_no": "EP500102",
      "error": {
        "status_code": 409,
        "code": "TICKET_NUMBER_ALREADY_EXISTS",
        "message": "Ticket number TKT-260625-A1B2-150245 already exists"
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

### 4.4 Unprocessable request (HTTP 400)

No `results` array — the batch could not be processed. Examples: missing `check_ins`, `check_ins: []`, invalid JSON, normal cashier JWT with express-only payload shape.

```json
{
  "statusCode": 400,
  "message": "check_ins must be a non-empty array",
  "error": "Bad Request"
}
```

### 4.5 Online single check-in (HTTP 200, one item)

Same response shape; `summary.total` is always `1`.

```json
{
  "results": [
    {
      "index": 0,
      "status": "success",
      "ticket_number": "TKT-260625-A1B2-143052",
      "plate_number": "ABC1234",
      "vr_no": "EP432624",
      "server_transaction_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "transaction": { }
    }
  ],
  "summary": {
    "total": 1,
    "succeeded": 1,
    "failed": 0
  }
}
```

---

## 5. How mobile applies the response

On **HTTP 200** only:

For each object in `results`:

1. **Match local row** using, in order:
   - `ticket_number` → local `tickets.id` and `sync_queue.record_id`
   - Confirm with `vr_no` + `plate_number` when present (guards against mismatches)
2. If `status == "success"`:
   - Set `tickets.sync_status = synced`
   - Set `sync_queue.sync_status = synced`
   - Persist `server_transaction_id` on the ticket
   - Apply void fields from `transaction` when `status` is `void`
3. If `status == "failed"`:
   - Set `sync_queue.sync_status = failed` (increment retry)
   - Leave ticket `sync_status` as `pending`
   - Do **not** stop processing other items in the batch

Items missing from `results` when `summary.total` does not match request length → treat as **failed** (safe default).

---

## 6. Field notes

| Request field | Normal | Express |
|---------------|--------|---------|
| `ticket_number` | required | required |
| `slot_id` | required | — |
| `contact_number` | required | — |
| `valet_type` | required | — |
| `vehicle.plate_number` | required | required |
| `belongings` | required (may be `[]`) | — |
| `damages` | required (may be `[]`) | — |
| `vr_no` | required | required |
| `amount` | — | required |
| `signature_base64` | required | — |
| `signature_content_type` | required with signature | — |
| `void_requested` / `void_reason` | optional | not used on express |
| `customer_name`, `driver_in`, `notes` | optional | optional drivers only |

**Plate normalization:** mobile sends uppercase, no spaces (e.g. `ABC1234`). Backend should echo the same in `results[].plate_number`.

**`ticket_number` format:** `TKT-{YYMMDD}-{DEVICE}-{HHmmss}` — generated on device, sent to backend, stored as local primary key.

---

## 7. Differences from current Swagger draft

| Current draft | Mobile expectation |
|---------------|-------------------|
| 201 / 207 / 400 by outcome | **200** for any processed batch; **400** only for unprocessable request |
| Success line may include `error` | `error` only when `status: "failed"` |
| `id` same as `ticket_number` | `server_transaction_id` = UUID; `ticket_number` = client id |
| No `plate_number` / `vr_no` on results | **Required** on every result line |
| `data` object | Prefer `transaction` (full check-in response body) |

---

*Document owner: Valet Master handheld POS — for backend alignment before mobile implementation.*
