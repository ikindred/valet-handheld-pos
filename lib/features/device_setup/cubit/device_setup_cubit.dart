import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/platform/device_info_payload.dart';
import '../../../core/services/device_id_service.dart';
import '../../../core/storage/device_claim_restore.dart';
import '../../../core/storage/prefs_keys.dart';
import '../../../core/storage/site_display_name.dart';
import '../../../data/local/db/app_database.dart';
import 'device_setup_state.dart';

/// After claim, Drift + prefs hold the terminal identity.
class DeviceSetupCubit extends Cubit<DeviceSetupState> {
  DeviceSetupCubit({
    required Dio dio,
    required AppDatabase database,
  })  : _dio = dio,
        _db = database,
        super(const DeviceSetupInitial());

  final Dio _dio;
  final AppDatabase _db;

  void _safeEmit(DeviceSetupState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  /// When GET active is empty but this tablet is already claimed on the server.
  Future<void> continueIfAlreadyClaimed() async {
    _safeEmit(const DeviceSetupClaiming());
    try {
      final restored = await DeviceClaimRestore.tryRestoreFromDatabase(_db);
      if (restored != null) {
        _safeEmit(DeviceClaimSuccess(restored));
        return;
      }
      final reclaimed = await _attemptReclaimByBindingHash();
      if (reclaimed == null) {
        _safeEmit(
          const DeviceSetupError(
            'Could not verify this tablet. Contact your administrator.',
          ),
        );
        return;
      }
      final hash = await DeviceIdService.sha256RawAndroidId();
      await _persistClaimedDevice(reclaimed, hash);
      _safeEmit(DeviceClaimSuccess(reclaimed));
    } on DioException catch (e) {
      _safeEmit(DeviceSetupError(_messageFromDio(e)));
    } catch (_) {
      _safeEmit(
        const DeviceSetupError(
          'Could not verify this tablet. Contact your administrator.',
        ),
      );
    }
  }

  /// GET [AppConfig.devicesActiveUrl] — only before first successful claim.
  Future<void> fetchDevices() async {
    _safeEmit(const DeviceSetupLoadingDevices());
    try {
      if (AppConfig.useStubApi) {
        _safeEmit(
          const DeviceSetupDevicesLoaded([
            DeviceModel(
              serverDeviceId: 'stub-dev-1',
              deviceLabel: 'Stub Tablet',
              branchName: 'Ayala Circuit',
              areaName: 'Area B',
              serialNumber: 'SN-STUB-001',
              branchId: 'stub-branch-id',
              areaId: 'stub-area-id',
              isActive: true,
            ),
          ]),
        );
        return;
      }

      final devices = await _fetchActiveDevicesList();
      if (devices == null) {
        _safeEmit(
          const DeviceSetupError(
            'Could not load devices. Check connection.',
          ),
        );
        return;
      }
      if (devices.isEmpty) {
        final restored = await DeviceClaimRestore.tryRestoreFromDatabase(_db);
        if (restored != null) {
          _safeEmit(DeviceClaimSuccess(restored));
          return;
        }
        final reclaimed = await _attemptReclaimByBindingHash();
        if (reclaimed != null) {
          try {
            final hash = await DeviceIdService.sha256RawAndroidId();
            await _persistClaimedDevice(reclaimed, hash);
            _safeEmit(DeviceClaimSuccess(reclaimed));
            return;
          } catch (_) {
            // show empty state below
          }
        }
      }
      _safeEmit(DeviceSetupDevicesLoaded(devices));
    } on DioException {
      _safeEmit(
        const DeviceSetupError(
          'Could not load devices. Check connection.',
        ),
      );
    } catch (_) {
      _safeEmit(
        const DeviceSetupError(
          'Could not load devices. Check connection.',
        ),
      );
    }
  }

  Future<List<DeviceModel>?> _fetchActiveDevicesList() async {
    final res = await _dio.get<dynamic>(AppConfig.devicesActiveUrl);
    final raw = res.data;
    final List<dynamic>? data = switch (raw) {
      final List<dynamic> list => list,
      final Map<dynamic, dynamic> map when map['data'] is List<dynamic> =>
        map['data']! as List<dynamic>,
      final Map<dynamic, dynamic> map when map['devices'] is List<dynamic> =>
        map['devices']! as List<dynamic>,
      _ => null,
    };
    if (data == null) return null;
    return data
        .map(
          (e) => DeviceModel.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  /// POST [AppConfig.devicesClaimUrl] — one-time per tablet until app data wipe.
  Future<void> claimDevice(String serverDeviceId) async {
    _safeEmit(const DeviceSetupClaiming());
    try {
      final androidIdHash = await DeviceIdService.sha256RawAndroidId();
      if (androidIdHash.isEmpty) {
        _safeEmit(
          const DeviceSetupError(
            'Could not read device identifier. Try again or contact support.',
          ),
        );
        return;
      }

      final DeviceModel claimed;
      if (AppConfig.useStubApi) {
        claimed = DeviceModel(
          serverDeviceId: serverDeviceId,
          deviceLabel: 'Stub Tablet',
          branchName: 'Ayala Circuit',
          areaName: 'Area B',
          serialNumber: 'SN-STUB-001',
          branchId: 'stub-branch-id',
          areaId: 'stub-area-id',
          isActive: true,
        );
      } else {
        final parsed = await _postClaim(serverDeviceId, androidIdHash);
        if (parsed == null) {
          _safeEmit(const DeviceSetupError('Claim failed. Try again.'));
          return;
        }
        claimed = parsed;
      }

      try {
        await _persistClaimedDevice(claimed, androidIdHash);
      } catch (_) {
        _safeEmit(
          const DeviceSetupError(
            'Could not save device identity. Try again.',
          ),
        );
        return;
      }
      _safeEmit(DeviceClaimSuccess(claimed));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final androidIdHash = await DeviceIdService.sha256RawAndroidId();
        if (androidIdHash.isNotEmpty) {
          final recovered = _deviceFrom409(e, serverDeviceId);
          if (recovered != null) {
            try {
              await _persistClaimedDevice(recovered, androidIdHash);
              _safeEmit(DeviceClaimSuccess(recovered));
              return;
            } catch (_) {
              // fall through to error message
            }
          }
        }
      }
      _safeEmit(DeviceSetupError(_messageFromDio(e)));
    } catch (_) {
      _safeEmit(const DeviceSetupError('Claim failed. Try again.'));
    }
  }

  /// Tablet already bound on server: active list is empty; recover via claim by hash.
  Future<DeviceModel?> _attemptReclaimByBindingHash() async {
    if (AppConfig.useStubApi) return null;
    final androidIdHash = await DeviceIdService.sha256RawAndroidId();
    if (androidIdHash.isEmpty) return null;

    try {
      return await _postClaim('', androidIdHash);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return _deviceFrom409(e, '');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DeviceModel?> _postClaim(
    String serverDeviceId,
    String androidIdHash,
  ) async {
    final deviceId = await DeviceIdService.getOrCreate();
    final deviceInfo = await buildDeviceInfoPayload();
    final deviceModel = deviceInfo['model']?.toString() ??
        deviceInfo['manufacturer']?.toString() ??
        'unknown';
    final osVersion = deviceInfo['system_version']?.toString() ??
        deviceInfo['sdk_int']?.toString() ??
        '';
    final serialNumber = await getHardwareSerialNumber();

    final bearer = AppConfig.deviceClaimBearerToken;
    final body = <String, dynamic>{
      'device_id': deviceId,
      'android_id_hash': androidIdHash,
      'device_model': deviceModel,
      'os_version': osVersion,
      'serial_number': serialNumber,
    };
    final slotId = serverDeviceId.trim();
    if (slotId.isNotEmpty) {
      body['server_device_id'] = slotId;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.devicesClaimUrl,
      data: body,
      options: bearer == null
          ? null
          : Options(
              headers: <String, dynamic>{
                'Authorization': 'Bearer $bearer',
              },
            ),
    );
    final data = res.data ?? {};
    return DeviceModel.fromClaimResponse(
      data,
      selectedServerDeviceId: slotId,
    );
  }

  /// When the slot is already bound to this tablet, recover from 409 body (`id` field).
  DeviceModel? _deviceFrom409(DioException e, String serverDeviceId) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final parsed = DeviceModel.fromClaimResponse(
        data,
        selectedServerDeviceId: serverDeviceId,
      );
      if (parsed.serverDeviceId.isNotEmpty) return parsed;
    } else if (data is Map) {
      final parsed = DeviceModel.fromClaimResponse(
        Map<String, dynamic>.from(data),
        selectedServerDeviceId: serverDeviceId,
      );
      if (parsed.serverDeviceId.isNotEmpty) return parsed;
    }
    final sid = serverDeviceId.trim();
    if (sid.isEmpty) return null;
    return DeviceModel(
      serverDeviceId: sid,
      deviceLabel: '',
      branchName: '',
      areaName: '',
      serialNumber: '',
      branchId: '',
      areaId: '',
      isActive: false,
    );
  }

  static String _messageFromDio(DioException e) {
    if (e.response?.statusCode == 409) {
      return 'This device is already claimed. Contact your admin.';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'] ?? data['error'];
      if (m != null && m.toString().isNotEmpty) return m.toString();
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    return 'Request failed. Try again.';
  }

  /// Drift [device_identity] + prefs (identity, branch/area names and ids, serial).
  Future<void> _persistClaimedDevice(
    DeviceModel device,
    String androidIdHash,
  ) async {
    final branchName = SiteDisplayName.sanitizeStored(device.branchName);
    final areaName = SiteDisplayName.sanitizeStored(device.areaName);
    await _db.transaction(() async {
      await _db.delete(_db.deviceIdentity).go();
      await _db.into(_db.deviceIdentity).insert(
            DeviceIdentityCompanion.insert(
              deviceLabel: device.deviceLabel,
              serverDeviceId: device.serverDeviceId,
              androidIdHash: androidIdHash,
              branch: branchName,
              area: areaName,
              branchId: Value(device.branchId.trim()),
              areaId: Value(device.areaId.trim()),
              serialNumber: Value(device.serialNumber.trim()),
              isActive: Value(device.isActive),
              claimedAt: Value(DateTime.now()),
            ),
          );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.deviceIdentityKey, device.serverDeviceId);
    final b = branchName;
    final a = areaName;
    if (b.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranch, b);
    } else {
      await prefs.remove(PrefsKeys.deviceBranch);
    }
    if (a.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceArea, a);
    } else {
      await prefs.remove(PrefsKeys.deviceArea);
    }

    final bid = device.branchId.trim();
    final aid = device.areaId.trim();
    if (bid.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranchId, bid);
    } else {
      await prefs.remove(PrefsKeys.deviceBranchId);
    }
    if (aid.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceAreaId, aid);
    } else {
      await prefs.remove(PrefsKeys.deviceAreaId);
    }
  }
}
