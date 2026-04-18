import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/device_id_service.dart';
import '../../../core/storage/prefs_keys.dart';
import '../../../data/local/db/app_database.dart';
import 'device_setup_state.dart';

/// After a claim, this device’s Drift + prefs hold the terminal identity.
/// Unsynced offline data created under a previous identity is **not** migrated
/// if the terminal is reassigned — accepted operational risk.
class DeviceSetupCubit extends Cubit<DeviceSetupState> {
  DeviceSetupCubit({
    required Dio dio,
    required AppDatabase database,
  })  : _dio = dio,
        _db = database,
        super(const DeviceSetupInitial());

  final Dio _dio;
  final AppDatabase _db;

  /// GET [AppConfig.devicesActiveUrl]
  Future<void> fetchDevices() async {
    emit(const DeviceSetupLoading());
    try {
      if (AppConfig.useStubApi) {
        emit(
          DeviceListLoaded([
            DeviceModel(
              serverDeviceId: 'stub-dev-1',
              deviceLabel: 'Stub Tablet',
              branch: 'Ayala Circuit',
              area: 'Area B',
              isActive: true,
            ),
          ]),
        );
        return;
      }

      final res = await _dio.get<dynamic>(AppConfig.devicesActiveUrl);
      final data = res.data;
      if (data is! List<dynamic>) {
        emit(
          const DeviceSetupError(
            'Could not load devices. Check connection.',
          ),
        );
        return;
      }
      final devices = data
          .map(
            (e) => DeviceModel.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList();
      emit(DeviceListLoaded(devices));
    } on DioException {
      emit(
        const DeviceSetupError(
          'Could not load devices. Check connection.',
        ),
      );
    } catch (_) {
      emit(
        const DeviceSetupError(
          'Could not load devices. Check connection.',
        ),
      );
    }
  }

  /// POST [AppConfig.devicesClaimUrl]
  Future<void> claimDevice(String serverDeviceId) async {
    emit(const DeviceSetupLoading());
    try {
      final androidIdHash = await DeviceIdService.sha256RawAndroidId();
      if (androidIdHash.isEmpty) {
        emit(
          const DeviceSetupError(
            'Could not read device identifier. Try again or contact support.',
          ),
        );
        return;
      }

      DeviceModel? claimed;
      if (AppConfig.useStubApi) {
        claimed = DeviceModel(
          serverDeviceId: serverDeviceId,
          deviceLabel: 'Stub Tablet',
          branch: 'Ayala Circuit',
          area: 'Area B',
          isActive: true,
        );
      } else {
        final res = await _dio.post<Map<String, dynamic>>(
          AppConfig.devicesClaimUrl,
          data: <String, dynamic>{
            'server_device_id': serverDeviceId,
            'android_id_hash': androidIdHash,
          },
        );
        final data = res.data ?? {};
        final isActive = data['is_active'] as bool? ?? false;
        if (!isActive) {
          emit(const DeviceClaimPendingActivation());
          return;
        }
        claimed = DeviceModel.fromJson(data);
      }

      try {
        await _persistClaimedDevice(claimed, androidIdHash);
      } catch (_) {
        emit(
          const DeviceSetupError(
            'Could not save device identity. Try again.',
          ),
        );
        return;
      }
      emit(DeviceClaimSuccess(claimed));
    } on DioException catch (e) {
      final msg = _messageFromDio(e);
      emit(DeviceSetupError(msg));
    } catch (_) {
      emit(const DeviceSetupError('Claim failed. Try again.'));
    }
  }

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'] ?? data['error'];
      if (m != null && m.toString().isNotEmpty) return m.toString();
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    return 'Claim failed. Try again.';
  }

  /// Single row in [device_identity]; [PrefsKeys.deviceIdentityKey] stores
  /// [DeviceModel.serverDeviceId] for splash routing only.
  Future<void> _persistClaimedDevice(
    DeviceModel device,
    String androidIdHash,
  ) async {
    await _db.transaction(() async {
      await _db.delete(_db.deviceIdentity).go();
      await _db.into(_db.deviceIdentity).insert(
            DeviceIdentityCompanion.insert(
              deviceLabel: device.deviceLabel,
              serverDeviceId: device.serverDeviceId,
              androidIdHash: androidIdHash,
              branch: device.branch,
              area: device.area,
              isActive: const Value(true),
              claimedAt: Value(DateTime.now()),
            ),
          );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.deviceIdentityKey, device.serverDeviceId);
  }
}
