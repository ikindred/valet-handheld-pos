import 'package:equatable/equatable.dart';

import '../../../core/storage/site_display_name.dart';

/// Device row from GET `/devices/active` or successful claim response.
class DeviceModel extends Equatable {
  const DeviceModel({
    required this.serverDeviceId,
    required this.deviceLabel,
    required this.branchName,
    required this.areaName,
    required this.serialNumber,
    required this.branchId,
    required this.areaId,
    required this.isActive,
  });

  final String serverDeviceId;
  final String deviceLabel;
  final String branchName;
  final String areaName;
  final String serialNumber;
  final String branchId;
  final String areaId;
  final bool isActive;

  static String _str(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final t = SiteDisplayName.fromJsonValue(v);
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v == null) return false;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1';
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      serverDeviceId: _str(json, const [
        'server_device_id',
        'serverDeviceId',
        'id',
      ]),
      deviceLabel: _str(json, const [
        'display_name',
        'displayName',
        'device_label',
        'deviceLabel',
        'label',
      ]),
      branchName: _str(json, const [
        'branchName',
        'branch_name',
        'branch',
      ]),
      areaName: _str(json, const [
        'areaName',
        'area_name',
        'area',
      ]),
      serialNumber: _str(json, const [
        'serialNumber',
        'serial_number',
      ]),
      branchId: _nestedId(json, 'branch', const ['branchId', 'branch_id']),
      areaId: _nestedId(json, 'area', const ['areaId', 'area_id']),
      isActive: _bool(json['is_active'] ?? json['isActive']),
    );
  }

  /// `POST /devices/claim` — successful HTTP 200 means setup is complete (login next).
  /// `status: OFFLINE` is connectivity only, not "wait for activation".
  factory DeviceModel.fromClaimResponse(
    Map<String, dynamic> json, {
    String selectedServerDeviceId = '',
  }) {
    final serverDeviceId = _serverIdFromClaimResponse(json, selectedServerDeviceId);

    return DeviceModel(
      serverDeviceId: serverDeviceId,
      deviceLabel: _str(json, const [
        'display_name',
        'displayName',
        'device_label',
        'deviceLabel',
        'label',
      ]),
      branchName: _str(json, const [
        'branchName',
        'branch_name',
        'branch',
      ]),
      areaName: _str(json, const [
        'areaName',
        'area_name',
        'area',
      ]),
      serialNumber: _str(json, const [
        'serialNumber',
        'serial_number',
      ]),
      branchId: _nestedId(json, 'branch', const ['branchId', 'branch_id']),
      areaId: _nestedId(json, 'area', const ['areaId', 'area_id']),
      isActive: _connectivityActive(json),
    );
  }

  /// Authoritative server row UUID from claim `id` (not hardware `deviceId`).
  static String _serverIdFromClaimResponse(
    Map<String, dynamic> json,
    String selectedSlotId,
  ) {
    final id = json['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    final fromKeys = _str(json, const [
      'server_device_id',
      'serverDeviceId',
    ]);
    if (fromKeys.isNotEmpty) return fromKeys;
    return selectedSlotId.trim();
  }

  static String _nestedId(
    Map<String, dynamic> json,
    String objectKey,
    List<String> topLevelKeys,
  ) {
    final nested = json[objectKey];
    if (nested is Map) {
      final map = nested is Map<String, dynamic>
          ? nested
          : Map<String, dynamic>.from(nested);
      final id = map['id']?.toString().trim() ?? '';
      if (id.isNotEmpty) return id;
    }
    return _str(json, topLevelKeys);
  }

  /// Records server connectivity when present; does not gate claim completion.
  static bool _connectivityActive(Map<String, dynamic> json) {
    if (json['is_active'] is bool) return json['is_active']! as bool;
    if (json['isActive'] is bool) return json['isActive']! as bool;
    final status = (json['status'] as String?)?.toUpperCase();
    if (status == null || status.isEmpty) return true;
    return status == 'ONLINE';
  }

  @override
  List<Object?> get props => [
        serverDeviceId,
        deviceLabel,
        branchName,
        areaName,
        serialNumber,
        branchId,
        areaId,
        isActive,
      ];
}

sealed class DeviceSetupState extends Equatable {
  const DeviceSetupState();

  @override
  List<Object?> get props => [];
}

final class DeviceSetupInitial extends DeviceSetupState {
  const DeviceSetupInitial();
}

final class DeviceSetupLoadingDevices extends DeviceSetupState {
  const DeviceSetupLoadingDevices();
}

final class DeviceSetupDevicesLoaded extends DeviceSetupState {
  const DeviceSetupDevicesLoaded(this.devices);

  final List<DeviceModel> devices;

  @override
  List<Object?> get props => [devices];
}

final class DeviceSetupClaiming extends DeviceSetupState {
  const DeviceSetupClaiming();
}

final class DeviceClaimSuccess extends DeviceSetupState {
  const DeviceClaimSuccess(this.device);

  final DeviceModel device;

  @override
  List<Object?> get props => [device];
}

final class DeviceSetupError extends DeviceSetupState {
  const DeviceSetupError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
