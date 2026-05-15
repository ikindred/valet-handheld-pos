import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/platform/device_info_payload.dart';
import '../../../core/services/device_id_service.dart';
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

  Timer? _pollTimer;
  String? _pendingSlotId;
  String? _pendingAndroidIdHash;

  @override
  Future<void> close() {
    _cancelPoll();
    return super.close();
  }

  void _safeEmit(DeviceSetupState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  void _cancelPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startPoll() {
    _cancelPoll();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_pollTick()),
    );
  }

  Future<void> _pollTick() async {
    final s = state;
    if (s is! DeviceSetupPendingActivation) return;
    _safeEmit(s.copyWith(polling: true));
    try {
      await _tryResolveClaimPending(s);
    } finally {
      final cur = state;
      if (cur is DeviceSetupPendingActivation) {
        _safeEmit(cur.copyWith(polling: false));
      }
    }
  }

  /// Manual poll trigger from UI.
  Future<void> checkPendingAgain() async {
    final s = state;
    if (s is! DeviceSetupPendingActivation) return;
    _safeEmit(s.copyWith(polling: true));
    try {
      await _tryResolveClaimPending(s);
    } finally {
      final cur = state;
      if (cur is DeviceSetupPendingActivation) {
        _safeEmit(cur.copyWith(polling: false));
      }
    }
  }

  /// Leave pending activation UI and reload the device list.
  Future<void> returnToDeviceList() async {
    _cancelPoll();
    _pendingSlotId = null;
    _pendingAndroidIdHash = null;
    await fetchDevices();
  }

  /// GET [AppConfig.devicesActiveUrl]
  Future<void> fetchDevices() async {
    _cancelPoll();
    _pendingSlotId = null;
    _pendingAndroidIdHash = null;
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

  /// POST [AppConfig.devicesClaimUrl] (thin; mirrors body shape used elsewhere).
  Future<void> claimDevice(String serverDeviceId) async {
    _cancelPoll();
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

      DeviceModel? claimed;
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
        claimed = await _postClaim(serverDeviceId, androidIdHash);
        if (claimed == null) {
          _safeEmit(const DeviceSetupError('Claim failed. Try again.'));
          return;
        }
        if (!claimed.isActive) {
          final displayId = await DeviceIdService.getOrCreate();
          _pendingSlotId = serverDeviceId;
          _pendingAndroidIdHash = androidIdHash;
          _safeEmit(
            DeviceSetupPendingActivation(
              displayDeviceId: displayId,
              selectedServerDeviceId: serverDeviceId,
            ),
          );
          unawaited(_tryResolveClaimPending(
            DeviceSetupPendingActivation(
              displayDeviceId: displayId,
              selectedServerDeviceId: serverDeviceId,
            ),
          ));
          _startPoll();
          return;
        }
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
      _safeEmit(DeviceSetupError(_messageFromDio(e)));
    } catch (_) {
      _safeEmit(const DeviceSetupError('Claim failed. Try again.'));
    }
  }

  Future<DeviceModel?> _postClaim(String serverDeviceId, String androidIdHash) async {
    final deviceId = await DeviceIdService.getOrCreate();
    final deviceInfo = await buildDeviceInfoPayload();
    final deviceModel = deviceInfo['model']?.toString() ??
        deviceInfo['manufacturer']?.toString() ??
        'unknown';
    final osVersion = deviceInfo['system_version']?.toString() ??
        deviceInfo['sdk_int']?.toString() ??
        '';

    final bearer = AppConfig.deviceClaimBearerToken;
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.devicesClaimUrl,
      data: <String, dynamic>{
        'server_device_id': serverDeviceId,
        'device_id': deviceId,
        'android_id_hash': androidIdHash,
        'device_model': deviceModel,
        'os_version': osVersion,
      },
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
      selectedServerDeviceId: serverDeviceId,
    );
  }

  Future<void> _tryResolveClaimPending(DeviceSetupPendingActivation pending) async {
    final slotId = pending.selectedServerDeviceId ?? _pendingSlotId;
    final hash = _pendingAndroidIdHash;
    if (slotId == null || slotId.isEmpty || hash == null) return;

    final list = await _fetchActiveDevicesList();
    if (list != null) {
      for (final d in list) {
        if (d.serverDeviceId == slotId && d.isActive) {
          await _finishClaimFromModel(d, hash);
          return;
        }
      }
    }

    try {
      final claimed = await _postClaim(slotId, hash);
      if (claimed != null && claimed.isActive) {
        await _finishClaimFromModel(claimed, hash);
      }
    } catch (_) {
      // keep pending; next tick retries
    }
  }

  Future<void> _finishClaimFromModel(DeviceModel claimed, String androidIdHash) async {
    try {
      await _persistClaimedDevice(claimed, androidIdHash);
    } catch (_) {
      _safeEmit(
        const DeviceSetupError(
          'Could not save device identity. Try again.',
        ),
      );
      _cancelPoll();
      _pendingSlotId = null;
      _pendingAndroidIdHash = null;
      return;
    }
    _cancelPoll();
    _pendingSlotId = null;
    _pendingAndroidIdHash = null;
    _safeEmit(DeviceClaimSuccess(claimed));
  }

  static String _messageFromDio(DioException e) {
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
