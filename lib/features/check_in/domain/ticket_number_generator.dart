import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../core/device/device_instance_id.dart';

/// Local ticket numbers (`TKT-YYYY-…`).
///
/// **Production options (choose one strategy):**
///
/// 1. **Server-assigned (recommended)** — Backend returns the canonical id when a
///    check-in session starts. Guarantees uniqueness across devices and sites.
///
/// 2. **UUID** — `TKT-2026-${uuid fragment}` (below). Collision risk is negligible
///    for practical purposes; not sequential, not human-meaningful.
///
/// 3. **Device instance + time + counter** — Combine [DeviceInstanceId], UTC
///    timestamp, and a monotonic counter in [SharedPreferences] per day/shift.
///    Good offline; resolve collisions when syncing to server.
///
/// 4. **ULID / KSUID** — Time-sortable, unique strings via a package (`ulid`).
///
/// 5. **Hash(deviceId + timestamp + random)** — e.g. first 8 hex chars of
///    SHA-256; include a random nonce if multiple tickets per ms are possible.
abstract final class TicketNumberGenerator {
  /// Fast, offline-friendly display id (not guaranteed globally unique under
  /// extreme parallel load — use server ids for billing).
  static String generateLocal() {
    final y = DateTime.now().year;
    final part = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 8)
        .toUpperCase();
    return 'TKT-$y-$part';
  }

  /// Example: device-scoped entropy (still add server validation in production).
  static Future<String> generateWithDeviceHash() async {
    final y = DateTime.now().year;
    final device = await DeviceInstanceId.getOrCreate();
    final salt = const Uuid().v4();
    final payload = '$device|${DateTime.now().toUtc().toIso8601String()}|$salt';
    final digest = sha256.convert(utf8.encode(payload));
    final hex = digest.toString().substring(0, 8).toUpperCase();
    return 'TKT-$y-$hex';
  }
}
