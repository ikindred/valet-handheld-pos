import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/valet_log.dart';
import '../../core/time/unix_timestamp.dart';
import '../../features/check_in/domain/vehicle_damage.dart';
import '../../features/check_in/state/check_in_cubit.dart';
import '../local/db/app_database.dart';

/// Persists check-in rows to `transactions` and enqueues `sync_queue` (`type: transaction`).
class TransactionsRepository {
  TransactionsRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  static String encodeBelongings(List<String> items) => jsonEncode(items);

  static String? encodeDamage(List<VehicleDamageEntry> entries) {
    if (entries.isEmpty) return null;
    return jsonEncode([
      for (final e in entries)
        {
          'id': e.id,
          'normalizedX': e.normalizedX,
          'normalizedY': e.normalizedY,
          'type': e.type.name,
          'zoneLabel': e.zoneLabel,
        },
    ]);
  }

  /// Inserts a row and a sync_queue entry. Returns local row [ValetTransaction.id].
  Future<int> insertOfflineCheckIn({
    required CheckInState state,
    required int checkinShiftId,
    required int userId,
    required String branchSnapshot,
    required String areaSnapshot,
    required String deviceIdSnapshot,
  }) async {
    final now = unixNowSeconds();
    final localUuid = _uuid.v4();
    final timeIn =
        (state.dateTimeIn ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final slotDisplay = [
      state.parkingLevel.trim(),
      state.parkingSlot.trim(),
    ].where((s) => s.isNotEmpty).join(' · ');
    final damageJson = encodeDamage(state.vehicleDamageEntries);

    return _db.transaction(() async {
      final id = await _db.into(_db.valetTransactions).insert(
            ValetTransactionsCompanion.insert(
              localUuid: Value(localUuid),
              checkinShiftId: checkinShiftId,
              userId: userId,
              ticketNumber: state.ticketNumber,
              plateNumber: state.plateNumber,
              vehicleBrand: Value(_emptyToNull(state.vehicleBrandMake)),
              vehicleModel: Value(_emptyToNull(state.vehicleModel)),
              vehicleYear: Value(_emptyToNull(state.vehicleYear)),
              vehicleColor: Value(_emptyToNull(state.vehicleColor)),
              vehicleType: Value(state.vehicleBodyType.name),
              slot: Value(_emptyToNull(slotDisplay)),
              parkingLevel: Value(_emptyToNull(state.parkingLevel)),
              parkingSlot: Value(_emptyToNull(state.parkingSlot)),
              belongingsJson: Value(encodeBelongings(state.selectedBelongings)),
              otherBelongings: Value(_emptyToNull(state.otherBelongings)),
              signaturePng: state.signaturePng != null
                  ? Value(base64Encode(state.signaturePng!))
                  : const Value.absent(),
              signatureCapturedAt: state.signatureCapturedAt != null
                  ? Value(state.signatureCapturedAt!)
                  : const Value.absent(),
              customerFullName: Value(_emptyToNull(state.customerFullName)),
              customerMobile: Value(_emptyToNull(state.contactNumber)),
              assignedValetDriver:
                  Value(_emptyToNull(state.assignedValetDriver)),
              specialInstructions:
                  Value(_emptyToNull(state.specialInstructions)),
              valetServiceType: Value(state.valetServiceType.name),
              vehicleDamageJson: damageJson != null
                  ? Value(damageJson)
                  : const Value.absent(),
              branchSnapshot: Value(_emptyToNull(branchSnapshot)),
              areaSnapshot: Value(_emptyToNull(areaSnapshot)),
              deviceIdSnapshot: Value(_emptyToNull(deviceIdSnapshot)),
              lastModifiedAt: Value(now),
              localCreatedAt: Value(now),
              timeIn: timeIn,
              status: const Value('active'),
            ),
          );

      final row = await (_db.select(_db.valetTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      final payload = jsonEncode(transactionToSyncPayload(row));
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              type: 'transaction',
              entityId: id,
              payload: payload,
              createdAt: now,
            ),
          );
      ValetLog.d(
        'TransactionsRepository.insertOfflineCheckIn',
        'saved local transaction id=$id localUuid=$localUuid ticket=${state.ticketNumber}',
      );
      return id;
    });
  }

  /// Full row read (e.g. tests / future detail screen).
  Future<ValetTransaction?> transactionById(int id) {
    return (_db.select(_db.valetTransactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  static String? _emptyToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  /// Shape for [AuthApi.syncFlush] / server: includes `local_uuid` and scalars; signature as base64.
  static Map<String, dynamic> transactionToSyncPayload(ValetTransaction t) {
    return {
      'local_uuid': t.localUuid,
      'ticket_number': t.ticketNumber,
      'plate_number': t.plateNumber,
      'vehicle_brand': t.vehicleBrand,
      'vehicle_model': t.vehicleModel,
      'vehicle_year': t.vehicleYear,
      'vehicle_color': t.vehicleColor,
      'vehicle_type': t.vehicleType,
      'slot': t.slot,
      'parking_level': t.parkingLevel,
      'parking_slot': t.parkingSlot,
      'belongings_json': t.belongingsJson,
      'other_belongings': t.otherBelongings,
      'customer_full_name': t.customerFullName,
      'customer_mobile': t.customerMobile,
      'assigned_valet_driver': t.assignedValetDriver,
      'special_instructions': t.specialInstructions,
      'valet_service_type': t.valetServiceType,
      'vehicle_damage_json': t.vehicleDamageJson,
      'branch_snapshot': t.branchSnapshot,
      'area_snapshot': t.areaSnapshot,
      'device_id_snapshot': t.deviceIdSnapshot,
      'time_in': t.timeIn,
      'signature_captured_at': t.signatureCapturedAt,
      'signature_png_base64': t.signaturePng,
      'checkin_shift_id': t.checkinShiftId,
      'checkout_shift_id': t.checkoutShiftId,
      'user_id': t.userId,
    };
  }
}
