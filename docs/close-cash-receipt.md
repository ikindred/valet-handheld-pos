# Close Cash Receipt Format

End-of-shift thermal receipt printed automatically after a successful close cash submission. Both **Standard** and **Express** cashier modes use the same template; Express omits active check-ins and vehicle-type breakdown.

**Implementation:** `lib/core/printing/escpos_receipt_builder.dart`, `lib/core/printing/receipt_raster_builder.dart`, `lib/core/printing/close_cash_receipt_data.dart`

**Trigger:** `CloseCashCubit` → `CloseCashSuccess` → `printCloseCashFromContext`

---

## Logo

| Detail | Value |
| --- | --- |
| Asset | `assets/images/spid_black.png` |
| Loader | `ReceiptBrandLogo.loadForReceipt()` |
| When shown | Always attempted on print; omitted only if decode/load fails |
| Position | Top of receipt, centered |
| Width | **160px** on 58mm paper · **220px** on 80mm paper |
| Processing | Resized, grayscale (ESC/POS) or rasterized (58mm), white background |

If the asset fails to load, the receipt still prints and starts directly with **VALET MASTER** (no logo block).

---

## Standard cashier

Single tear-off. Paper cut at the end.

```
┌─────────────────────────────────┐
│         [LOGO — if loaded]      │  ← spid_black.png, centered
│                                 │
│         VALET MASTER            │  ← bold, centered
│    SM Sta Rosa / Valet Area     │  ← centered; "{Branch} / {Area}"
│                                 │     omitted if empty or "Valet Master"
├─────────────────────────────────┤
│      CLOSE CASH RECEIPT         │  ← bold, centered
├─────────────────────────────────┤
│                                 │
│ Branch              SM Sta Rosa │  ← omitted if branch empty
│ Area               Valet Area   │  ← omitted if area empty
│ Cashier         Kindred Inocencio│
│ Opened at    Jun 6, 2026 4:00 PM│  ← Philippine time
│ Closed at    Jun 6, 2026 1:00 AM│
│                                 │
├─────────────────────────────────┤
│                                 │
│ ACTIVE CHECK-INS                │  ← bold section title
│ Active check-ins              2 │
│                                 │
│ SHIFT CHECKOUTS                 │  ← bold section title
│ Total checkouts               3 │
│                                 │
│ BY VEHICLE TYPE                 │  ← bold section title
│ Sedan/Crossover               2 │
│ SUV                           1 │
│ Van                           0 │
│ Luxury                        0 │
│ EV/PHEV                       0 │
│ Motorcycle                    0 │
│                                 │
├─────────────────────────────────┤
│ Actual cash turned in PHP 2,430.00│  ← bold amount
│                                 │
├─────────────────────────────────┤
│  Printed Jun 6, 2026 1:05 AM    │  ← centered
│                                 │
│         [paper cut]             │
└─────────────────────────────────┘
```

---

## Express cashier

Same header, shift fields, cash total, and footer. Middle stats block is shorter.

```
┌─────────────────────────────────┐
│         [LOGO — if loaded]      │
│         VALET MASTER            │
│    SM Sta Rosa / Valet Area     │
├─────────────────────────────────┤
│      CLOSE CASH RECEIPT         │
├─────────────────────────────────┤
│ Branch              SM Sta Rosa │
│ Area               Valet Area   │
│ Cashier           Express User  │
│ Opened at    Jun 6, 2026 4:00 PM│
│ Closed at    Jun 6, 2026 1:00 AM│
│                                 │
├─────────────────────────────────┤
│                                 │
│ SHIFT CHECKOUTS                 │  ← bold section title
│ Total checkouts               5 │
│                                 │
├─────────────────────────────────┤
│ Actual cash turned in PHP 2,500.00│  ← bold amount
│                                 │
├─────────────────────────────────┤
│  Printed Jun 6, 2026 1:05 AM    │
│                                 │
│         [paper cut]             │
└─────────────────────────────────┘
```

**Express omits:**

- `ACTIVE CHECK-INS` section
- `BY VEHICLE TYPE` section (all six vehicle rows)

Controlled by `CloseCashReceiptData.isExpressCashier` (from `shift.isExpressCashier`).

---

## Field reference

| # | Line | Standard | Express | Notes |
| --- | --- | --- | --- | --- |
| 1 | Logo | Yes (if loaded) | Yes (if loaded) | `spid_black.png` |
| 2 | `VALET MASTER` | Yes | Yes | Bold, centered |
| 3 | `{Branch} / {Area}` | Yes* | Yes* | Centered under brand |
| 4 | `CLOSE CASH RECEIPT` | Yes | Yes | Bold, centered |
| 5 | Branch | If non-empty | If non-empty | Label left, value right |
| 6 | Area | If non-empty | If non-empty | Label left, value right |
| 7 | Cashier | Yes | Yes | Defaults to `—` if blank |
| 8 | Opened at | Yes | Yes | `MMM d, yyyy h:mm a` |
| 9 | Closed at | Yes | Yes | `MMM d, yyyy h:mm a` |
| 10 | Active check-ins | Yes | No | Count only |
| 11 | Total checkouts | Yes | Yes | Integer count |
| 12 | Vehicle type rows (×6) | Yes | No | Always all six types, including `0` |
| 13 | Actual cash turned in | Yes | Yes | `PHP #,##0.00`, bold |
| 14 | Printed timestamp | Yes | Yes | `Printed MMM d, yyyy h:mm a` |

\* Brand subtitle uses `headerBranchLine`: `{branch} / {area}`, or just one if the other is empty, or `Valet Master` if both are empty.

### Vehicle type rows (standard only)

Always printed in this order, even when count is `0`:

| Label |
| --- |
| Sedan/Crossover |
| SUV |
| Van |
| Luxury |
| EV/PHEV |
| Motorcycle |

---

## Layout and formatting

- **80mm paper:** two-column rows — label left, value right (e.g. `Branch          SM Sta Rosa`).
- **58mm paper:** stacked rows — label on one line, value on the next. Entire receipt is rasterized to an image before printing.
- **Amounts:** `PHP 2,430.00` (not ₱ — thermal font compatibility).
- **Timestamps:** Philippine local time via `ReceiptPrintFormat.dateTimeLabel()`.
- **No** “Thank you” line and **no** mall hours (unlike checkout receipts).
- **Single** tear-off with paper cut at the end.

---

## Not printed on receipt

These may appear on the Close Cash screen but are **not** on the thermal receipt:

- Opening float
- Total sales / revenue
- Total check-in count (standard only prints **active** check-ins, not all check-ins)
- Vehicles-in-lot count

---

## Standard vs Express summary

| Section | Standard | Express |
| --- | --- | --- |
| Logo + brand header | Yes | Yes |
| Branch / Area / Cashier / Opened / Closed | Yes | Yes |
| Active check-ins | Yes | No |
| Total checkouts | Yes | Yes |
| By vehicle type (6 rows) | Yes | No |
| Actual cash turned in | Yes | Yes |
| Printed timestamp | Yes | Yes |
