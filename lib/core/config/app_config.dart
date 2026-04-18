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

  static String get devSeedArea =>
      (_env('DEV_SEED_AREA') ?? 'Area B').trim();

  // ── AUTH ──────────────────────────────────
  static String get deviceRegister =>
      baseUrl + (_env('API_DEVICE_REGISTER') ?? '/api/v1/device/register');

  static String get authLogin =>
      baseUrl + (_env('API_AUTH_LOGIN') ?? '/api/v1/auth/login');

  static String get authValidateToken =>
      baseUrl + (_env('API_AUTH_VALIDATE_TOKEN') ?? '/api/v1/auth/validate-token');

  static String get authLogout =>
      baseUrl + (_env('API_AUTH_LOGOUT') ?? '/api/v1/auth/logout');

  /// GET active POS terminals available for claim (pre-configured on server).
  static String get devicesActiveUrl =>
      baseUrl + (_env('API_DEVICES_ACTIVE') ?? '/api/v1/devices/active');

  /// POST claim a terminal identity for this physical device.
  static String get devicesClaimUrl =>
      baseUrl + (_env('API_DEVICES_CLAIM') ?? '/api/v1/devices/claim');

  // ── SHIFT ─────────────────────────────────
  static String get shiftOpen =>
      baseUrl + (_env('API_SHIFT_OPEN') ?? '/api/v1/shifts/open');

  static String get shiftClose =>
      baseUrl + (_env('API_SHIFT_CLOSE') ?? '/api/v1/shifts/close');

  static String get shiftCurrent =>
      baseUrl + (_env('API_SHIFT_CURRENT') ?? '/api/v1/shifts/current');

  /// REST collection for shifts (POST create, PATCH update).
  static String get shiftsRest =>
      baseUrl + (_env('API_SHIFTS_REST') ?? '/api/v1/shifts');

  static String shiftById(String shiftId) {
    final enc = Uri.encodeComponent(shiftId);
    final t = (_env('API_SHIFT_BY_ID') ?? '').trim();
    if (t.isNotEmpty) {
      return baseUrl + t.replaceAll('{id}', enc);
    }
    return '$baseUrl/api/v1/shifts/$enc';
  }

  // ── TICKETS ───────────────────────────────
  static String get ticketCreate =>
      baseUrl + (_env('API_TICKET_CREATE') ?? '/api/v1/tickets');

  /// REST collection for tickets (POST create, PATCH update by id).
  static String get ticketsRest =>
      baseUrl + (_env('API_TICKETS_REST') ?? '/api/v1/tickets');

  static String ticketById(String ticketId) {
    final enc = Uri.encodeComponent(ticketId);
    final t = (_env('API_TICKET_BY_ID') ?? '').trim();
    if (t.isNotEmpty) {
      return baseUrl + t.replaceAll('{id}', enc);
    }
    return '$baseUrl/api/v1/tickets/$enc';
  }

  static String get ticketScan =>
      baseUrl + (_env('API_TICKET_SCAN') ?? '/api/v1/tickets/scan');

  static String ticketCheckout(String ticketId) =>
      baseUrl + (_env('API_TICKET_CHECKOUT')
          ?.replaceAll('{ticket_id}', ticketId) ??
          '/api/v1/tickets/$ticketId/checkout');

  static String ticketLost(String ticketId) =>
      baseUrl + (_env('API_TICKET_LOST')
          ?.replaceAll('{ticket_id}', ticketId) ??
          '/api/v1/tickets/$ticketId/lost');

  static String ticketGet(String ticketNumber) =>
      baseUrl + (_env('API_TICKET_GET')
          ?.replaceAll('{ticket_number}', ticketNumber) ??
          '/api/v1/tickets/$ticketNumber');

  // ── CONFIG ────────────────────────────────
  static String get config =>
      baseUrl + (_env('API_CONFIG') ?? '/api/v1/config');

  /// GET branch-level key/value settings (overnight window, mall hours, …).
  /// [branchId] is URL-encoded as a single path segment.
  static String branchConfigUrl(String branchId) {
    final encoded = Uri.encodeComponent(branchId.trim());
    final template = (_env('API_BRANCH_CONFIG') ?? '').trim();
    if (template.isNotEmpty) {
      return baseUrl + template.replaceAll('{branch_id}', encoded);
    }
    return '$baseUrl/api/v1/branches/$encoded/config';
  }

  // ── REPORTS ───────────────────────────────
  static String get reportsSales =>
      baseUrl + (_env('API_REPORTS_SALES') ?? '/api/v1/reports/sales');

  static String get reportsShifts =>
      baseUrl + (_env('API_REPORTS_SHIFTS') ?? '/api/v1/reports/shifts');

  /// GET historical transactions (Tier 2 background sync).
  static String get transactionsList =>
      baseUrl + (_env('API_TRANSACTIONS') ?? '/api/v1/transactions');

  // ── SYNC ──────────────────────────────────
  static String get syncFlush =>
      baseUrl + (_env('API_SYNC_FLUSH') ?? '/api/v1/sync/flush');
}
