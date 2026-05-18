import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String? _env(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  static String get baseUrl => _env('API_BASE_URL') ?? 'http://localhost:8000';

  /// When `API_BASE_URL` is unset or blank, [AuthApi] uses in-memory stubs (e.g. unit tests).
  /// When `.env` sets `API_BASE_URL`, remote calls are enabled.
  static bool get useStubApi => (_env('API_BASE_URL') ?? '').trim().isEmpty;

  /// Optional `.env` override for `POST /device/register` body when prefs are empty.
  /// Empty means "no site" until the admin assigns the device; assignment comes from the API response saved locally.
  static String get defaultDeviceBranch => (_env('DEVICE_BRANCH') ?? '').trim();

  static String get defaultDeviceArea => (_env('DEVICE_AREA') ?? '').trim();

  /// Temporary dev: insert/fill `device_info` for the real device id after splash.
  /// Defaults to **on** in debug builds; set `DEV_SEED_DEVICE_SITE=false` to disable.
  /// Release/profile: off unless `DEV_SEED_DEVICE_SITE=true`.
  static bool get devSeedDeviceSiteEnabled {
    final v = (_env('DEV_SEED_DEVICE_SITE') ?? '').trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return kDebugMode;
  }

  static String get devSeedBranch =>
      (_env('DEV_SEED_BRANCH') ?? 'Ayala Circuit').trim();

  static String get devSeedArea => (_env('DEV_SEED_AREA') ?? 'Area B').trim();

  /// Pre-fill all check-in fields for faster QA (e.g. printer testing).
  /// On in debug builds; set `CHECK_IN_PREFILL=false` to disable.
  static bool get checkInPrefillEnabled {
    final v = (_env('CHECK_IN_PREFILL') ?? '').trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return kDebugMode;
  }

  // ── AUTH ──────────────────────────────────
  static String get deviceRegister =>
      baseUrl + (_env('API_DEVICE_REGISTER') ?? '/api/v1/device/register');

  static String get authLogin =>
      baseUrl + (_env('API_AUTH_LOGIN') ?? '/api/v1/auth/login');

  static String get authValidateToken =>
      baseUrl +
      (_env('API_AUTH_VALIDATE_TOKEN') ?? '/api/v1/auth/validate-token');

  static String get authLogout =>
      baseUrl + (_env('API_AUTH_LOGOUT') ?? '/api/v1/auth/logout');

  /// GET active POS terminals available for claim (pre-configured on server).
  static String get devicesActiveUrl =>
      baseUrl + (_env('API_DEVICES_ACTIVE') ?? '/api/v1/devices/active');

  /// POST claim a terminal identity for this physical device.
  static String get devicesClaimUrl =>
      baseUrl + (_env('API_DEVICES_CLAIM') ?? '/api/v1/devices/claim');

  /// POST verify server branch/area assignment for this claimed device (Bearer).
  static String get devicesValidateUrl =>
      baseUrl + (_env('API_DEVICES_VALIDATE') ?? '/api/v1/devices/validate');

  /// Optional `Authorization: Bearer …` for [devicesClaimUrl] only.
  /// Per `docs/MOBILE_INTEGRATION_GUIDE.md`, claim expects an ADMIN JWT; use
  /// during provisioning when the app has no admin sign-in on this screen.
  static String? get deviceClaimBearerToken {
    final t = (_env('DEVICE_CLAIM_BEARER_TOKEN') ?? '').trim();
    return t.isEmpty ? null : t;
  }

  // ── SHIFT ─────────────────────────────────
  static String get shiftOpen =>
      baseUrl + (_env('API_SHIFT_OPEN') ?? '/api/v1/shifts/open');

  static String get shiftClose =>
      baseUrl + (_env('API_SHIFT_CLOSE') ?? '/api/v1/shifts/close');

  static String get shiftCurrent =>
      baseUrl + (_env('API_SHIFT_CURRENT') ?? '/api/v1/shifts/current');

  /// POST start cash session (local "shift" open).
  static String get shiftsRest =>
      baseUrl + (_env('API_SHIFTS_REST') ?? '/api/v1/cash-sessions/start');

  /// POST `/api/v1/cash-sessions/start` (prefer over [shiftsRest] in new code).
  static String get cashSessionsStart =>
      baseUrl +
      (_env('API_CASH_SESSIONS_START') ??
          _env('API_SHIFTS_REST') ??
          '/api/v1/cash-sessions/start');

  /// POST `/api/v1/cash-sessions/close`.
  static String get cashSessionsClose =>
      baseUrl +
      (_env('API_CASH_SESSIONS_CLOSE') ?? '/api/v1/cash-sessions/close');

  /// POST close cash session. [shiftId] is only used when `API_SHIFT_BY_ID` template contains `{id}`.
  static String shiftById(String shiftId) {
    final enc = Uri.encodeComponent(shiftId);
    final t = (_env('API_SHIFT_BY_ID') ?? '').trim();
    if (t.isNotEmpty) {
      return baseUrl + t.replaceAll('{id}', enc);
    }
    return baseUrl +
        (_env('API_CASH_SESSIONS_CLOSE') ?? '/api/v1/cash-sessions/close');
  }

  // ── TRANSACTIONS (tickets) ──────────────────
  static String get ticketCreate =>
      baseUrl + (_env('API_TICKET_CREATE') ?? '/api/v1/transactions');

  /// POST full check-in (multipart) — single-call ACTIVE ticket.
  static String get checkInUrl {
    final t = (_env('API_TRANSACTIONS_CHECK_IN') ?? '').trim();
    if (t.isNotEmpty) return baseUrl + t;
    return '$baseUrl/api/v1/transactions/check-in';
  }

  /// Legacy draft POST (retired from check-in flow).
  static String get ticketsRest =>
      baseUrl + (_env('API_TICKETS_REST') ?? '/api/v1/transactions');

  static String ticketById(String ticketId) {
    final enc = Uri.encodeComponent(ticketId);
    final t = (_env('API_TICKET_BY_ID') ?? '').trim();
    if (t.isNotEmpty) {
      return baseUrl + t.replaceAll('{id}', enc);
    }
    return '$baseUrl/api/v1/transactions/$enc';
  }

  /// GET `/api/v1/transactions/{id}` (server UUID).
  static String transactionGetUrl(String transactionId) {
    final enc = Uri.encodeComponent(transactionId.trim());
    final t = (_env('API_TRANSACTION_GET') ?? '').trim();
    if (t.isNotEmpty) return baseUrl + t.replaceAll('{id}', enc);
    return '$baseUrl/api/v1/transactions/$enc';
  }

  /// GET `/api/v1/transactions/{id}/checkout-preview` (no body).
  static String checkoutPreviewUrl(String id) {
    final enc = Uri.encodeComponent(id.trim());
    final t = (_env('API_CHECKOUT_PREVIEW') ?? '').trim();
    if (t.isNotEmpty) return baseUrl + t.replaceAll('{id}', enc);
    return '$baseUrl/api/v1/transactions/$enc/checkout-preview';
  }

  /// POST `/api/v1/transactions/{id}/check-out`.
  static String checkOutUrl(String id) {
    final enc = Uri.encodeComponent(id.trim());
    final t = (_env('API_CHECK_OUT') ?? '').trim();
    if (t.isNotEmpty) return baseUrl + t.replaceAll('{id}', enc);
    return '$baseUrl/api/v1/transactions/$enc/check-out';
  }

  /// POST `/api/v1/transactions/{id}/pay`.
  static String transactionPayUrl(String transactionId) {
    final enc = Uri.encodeComponent(transactionId.trim());
    final t = (_env('API_TRANSACTION_PAY') ?? '').trim();
    if (t.isNotEmpty) return baseUrl + t.replaceAll('{id}', enc);
    return '$baseUrl/api/v1/transactions/$enc/pay';
  }

  static String get ticketScan =>
      baseUrl + (_env('API_TICKET_SCAN') ?? '/api/v1/tickets/scan');

  /// Same resource as [ticketById] (checkout uses PATCH + `/pay` in services).
  static String ticketCheckout(String ticketId) {
    final enc = Uri.encodeComponent(ticketId.trim());
    final t = (_env('API_TICKET_CHECKOUT') ?? '').trim();
    if (t.isNotEmpty) {
      return baseUrl + t.replaceAll('{ticket_id}', enc);
    }
    return '$baseUrl/api/v1/transactions/$enc';
  }

  static String ticketLost(String ticketId) =>
      baseUrl +
      (_env('API_TICKET_LOST')?.replaceAll('{ticket_id}', ticketId) ??
          '/api/v1/tickets/$ticketId/lost');

  static String ticketGet(String ticketNumber) =>
      baseUrl +
      (_env('API_TICKET_GET')?.replaceAll('{ticket_number}', ticketNumber) ??
          '/api/v1/tickets/$ticketNumber');

  // ── CONFIG ────────────────────────────────
  static String get config =>
      baseUrl + (_env('API_CONFIG') ?? '/api/v1/settings');

  /// GET area detail (standard rates + `vehicleTypeRates`).
  static String branchAreaDetailUrl(String branchId, String areaId) {
    final branch = Uri.encodeComponent(branchId.trim());
    final area = Uri.encodeComponent(areaId.trim());
    final template = (_env('API_BRANCH_AREA_DETAIL') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl +
          template
              .replaceAll('{branch_id}', branch)
              .replaceAll('{area_id}', area);
    }
    return '$baseUrl/api/v1/branches/$branch/areas/$area';
  }

  /// GET branch record (hours, etc.). Prefer this over legacy [branchConfigUrl].
  static String branchDetailUrl(String branchId) {
    final encoded = Uri.encodeComponent(branchId.trim());
    final template = (_env('API_BRANCH_DETAIL') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl + template.replaceAll('{branch_id}', encoded);
    }
    return '$baseUrl/api/v1/branches/$encoded';
  }

  /// GET `/api/v1/branches/{branchId}/rates` (branch default flat/succeeding/overnight/lost).
  static String branchStandardRatesUrl(String branchId) {
    final encoded = Uri.encodeComponent(branchId.trim());
    final template = (_env('API_BRANCH_STANDARD_RATES') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl + template.replaceAll('{branch_id}', encoded);
    }
    return '$baseUrl/api/v1/branches/$encoded/rates';
  }

  /// GET branch-level standard rates object.
  static String branchRatesUrl(String branchId) {
    final encoded = Uri.encodeComponent(branchId.trim());
    final template = (_env('API_BRANCH_RATES') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl + template.replaceAll('{branch_id}', encoded);
    }
    return '$baseUrl/api/v1/rates/branches/$encoded';
  }

  /// Per-vehicle-type rate rows for [branchId].
  static String branchVehicleTypeRatesUrl(String branchId) {
    final encoded = Uri.encodeComponent(branchId.trim());
    final template = (_env('API_BRANCH_VEHICLE_TYPE_RATES') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl + template.replaceAll('{branch_id}', encoded);
    }
    return '$baseUrl/api/v1/rates/branches/$encoded/vehicle-types';
  }

  /// Interim: same as [branchDetailUrl] until callers use explicit getters.
  static String branchConfigUrl(String branchId) => branchDetailUrl(branchId);

  // ── REPORTS ───────────────────────────────
  static String get reportsSales =>
      baseUrl + (_env('API_REPORTS_SALES') ?? '/api/v1/reports/summary');

  static String get reportsShifts =>
      baseUrl + (_env('API_REPORTS_SHIFTS') ?? '/api/v1/reports/shifts');

  /// GET historical transactions (Tier 2 background sync).
  static String get transactionsList =>
      baseUrl + (_env('API_TRANSACTIONS') ?? '/api/v1/transactions');

  // ── CASH SESSIONS ─────────────────────────
  static String get cashSessionCurrent =>
      baseUrl +
      (_env('API_CASH_SESSION_CURRENT') ?? '/api/v1/cash-sessions/current');

  /// GET shift-scoped dashboard KPIs + recent transactions.
  static String get dashboardSummary =>
      baseUrl +
      (_env('API_DASHBOARD_SUMMARY') ?? '/api/v1/dashboard/summary');
}
