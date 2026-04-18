import 'package:equatable/equatable.dart';

/// Device row from GET `/devices/active` or successful claim response.
class DeviceModel extends Equatable {
  const DeviceModel({
    required this.serverDeviceId,
    required this.deviceLabel,
    required this.branch,
    required this.area,
    required this.isActive,
  });

  final String serverDeviceId;
  final String deviceLabel;
  final String branch;
  final String area;
  final bool isActive;

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      serverDeviceId: json['server_device_id'] as String? ?? '',
      deviceLabel: json['device_label'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      area: json['area'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [serverDeviceId, deviceLabel, branch, area, isActive];
}

sealed class DeviceSetupState extends Equatable {
  const DeviceSetupState();

  @override
  List<Object?> get props => [];
}

final class DeviceSetupInitial extends DeviceSetupState {
  const DeviceSetupInitial();
}

final class DeviceSetupLoading extends DeviceSetupState {
  const DeviceSetupLoading();
}

final class DeviceListLoaded extends DeviceSetupState {
  const DeviceListLoaded(this.devices);

  final List<DeviceModel> devices;

  @override
  List<Object?> get props => [devices];
}

final class DeviceClaimSuccess extends DeviceSetupState {
  const DeviceClaimSuccess(this.device);

  final DeviceModel device;

  @override
  List<Object?> get props => [device];
}

final class DeviceClaimPendingActivation extends DeviceSetupState {
  const DeviceClaimPendingActivation();
}

final class DeviceSetupError extends DeviceSetupState {
  const DeviceSetupError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
