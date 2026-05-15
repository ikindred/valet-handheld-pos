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
      branchId: _str(json, const [
        'branchId',
        'branch_id',
      ]),
      areaId: _str(json, const [
        'areaId',
        'area_id',
      ]),
      isActive: _bool(json['is_active'] ?? json['isActive']),
    );
  }

  /// `POST /devices/claim` body per [docs/MOBILE_INTEGRATION_GUIDE.md] plus
  /// extended name/serial fields when the API returns them.
  factory DeviceModel.fromClaimResponse(
    Map<String, dynamic> json, {
    required String selectedServerDeviceId,
  }) {
    final status = (json['status'] as String?)?.toUpperCase();
    final bool isActive;
    if (json['is_active'] is bool) {
      isActive = json['is_active']! as bool;
    } else if (json['isActive'] is bool) {
      isActive = json['isActive']! as bool;
    } else if (status != null && status.isNotEmpty) {
      isActive = status == 'ONLINE';
    } else {
      isActive = true;
    }

    final serverDeviceId = selectedServerDeviceId.isNotEmpty
        ? selectedServerDeviceId
        : _str(json, const [
            'server_device_id',
            'serverDeviceId',
            'id',
          ]);

    return DeviceModel(
      serverDeviceId: serverDeviceId,
      deviceLabel: _str(json, const [
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
      branchId: _str(json, const [
        'branchId',
        'branch_id',
      ]),
      areaId: _str(json, const [
        'areaId',
        'area_id',
      ]),
      isActive: isActive,
    );
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

final class DeviceSetupPendingActivation extends DeviceSetupState {
  const DeviceSetupPendingActivation({
    required this.displayDeviceId,
    this.selectedServerDeviceId,
    this.polling = false,
  });

  /// Shown to staff / admin (e.g. app `device_id` from [DeviceIdService.getOrCreate]).
  final String displayDeviceId;

  /// Server slot UUID we are waiting on until `is_active` is true.
  final String? selectedServerDeviceId;

  final bool polling;

  DeviceSetupPendingActivation copyWith({bool? polling}) {
    return DeviceSetupPendingActivation(
      displayDeviceId: displayDeviceId,
      selectedServerDeviceId: selectedServerDeviceId,
      polling: polling ?? this.polling,
    );
  }

  @override
  List<Object?> get props =>
      [displayDeviceId, selectedServerDeviceId, polling];
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
