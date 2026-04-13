import 'package:equatable/equatable.dart';

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

final class SyncIdle extends SyncState {
  const SyncIdle();
}

final class SyncInProgress extends SyncState {
  const SyncInProgress();
}

/// [synced] = rows marked `synced` this flush; [failed] / [pending] = current DB counts after flush.
final class SyncComplete extends SyncState {
  const SyncComplete({
    required this.synced,
    required this.failed,
    required this.pending,
  });

  final int synced;
  final int failed;
  final int pending;

  @override
  List<Object?> get props => [synced, failed, pending];
}

final class SyncError extends SyncState {
  const SyncError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
