import '../core/logging/valet_log.dart';

/// Listens for server-side “another device claimed this terminal” events.
/// Real transport (socket.io vs native WebSocket) is TBD — use [DeviceConflictServiceStub] until then.
abstract class DeviceConflictService {
  /// Call after successful login to begin listening for conflict events from the server.
  Future<void> connect(String sessionToken, String serverDeviceId);

  /// Clean up connection on logout.
  Future<void> disconnect();

  /// Emits `true` when a conflict is detected for the current device identity.
  Stream<bool> get onConflictDetected;
}

class DeviceConflictServiceStub implements DeviceConflictService {
  @override
  Future<void> connect(String sessionToken, String serverDeviceId) async {
    ValetLog.debug(
      'DeviceConflictServiceStub',
      'WebSocket not yet configured',
    );
  }

  @override
  Future<void> disconnect() async {}

  @override
  Stream<bool> get onConflictDetected => const Stream<bool>.empty();
}
