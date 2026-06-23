import 'package:bloc/bloc.dart';

import '../../../core/logging/valet_log.dart';
import '../../../data/repositories/auth_repository.dart';
import 'open_cash_state.dart';

/// Holds the opening-float parameters until the cashier acknowledges any
/// inherited transactions. Nothing is sent to the server until that point.
class _PendingOpenParams {
  const _PendingOpenParams({
    required this.localUserId,
    required this.sessionId,
    required this.openingFloat,
    required this.branch,
    required this.area,
    this.shiftDate,
    this.openingNotes,
  });

  final int localUserId;
  final int sessionId;
  final double openingFloat;
  final String branch;
  final String area;
  final String? shiftDate;
  final String? openingNotes;
}

class OpenCashCubit extends Cubit<OpenCashState> {
  OpenCashCubit(this._auth) : super(const OpenCashInitial());

  final AuthRepository _auth;

  /// Cached opening params — set when inherited tickets are found and the
  /// cashier must acknowledge before we POST to the server.
  _PendingOpenParams? _pendingParams;

  /// Step 1: called when the cashier taps "Open Cash and Start Shift".
  ///
  /// Queries local DB + remote reports API for currently-parked vehicles
  /// **before** creating any shift on the server:
  /// - No parked vehicles → open shift immediately.
  /// - Parked vehicles found → emit [OpenCashHasInheritedTransactions] and
  ///   wait for the cashier to acknowledge.
  Future<void> openShift({
    required int localUserId,
    required int sessionId,
    required double openingFloat,
    String branch = '',
    String area = '',
    String? shiftDate,
    String? openingNotes,
  }) async {
    emit(const OpenCashLoading());
    try {
      _pendingParams = _PendingOpenParams(
        localUserId: localUserId,
        sessionId: sessionId,
        openingFloat: openingFloat,
        branch: branch,
        area: area,
        shiftDate: shiftDate,
        openingNotes: openingNotes,
      );

      final inherited = await _auth.queryInheritedTransactionsPreCheck(
        localUserId: localUserId,
      );

      if (inherited.isEmpty) {
        ValetLog.debug(
          'OpenCashCubit.openShift',
          'No inherited tickets — opening shift immediately.',
        );
        await _commitOpenShift();
        return;
      }

      ValetLog.debug(
        'OpenCashCubit.openShift',
        'Found ${inherited.length} inherited ticket(s) → awaiting acknowledgement.',
      );
      emit(OpenCashHasInheritedTransactions(inheritedTransactions: inherited));
    } catch (e) {
      ValetLog.error('OpenCashCubit.openShift', 'error: $e', e);
      _pendingParams = null;
      emit(OpenCashError(e.toString()));
    }
  }

  /// Step 2a: called when the cashier taps "Acknowledge & Continue".
  ///
  /// NOW creates the shift on the server, then reassigns the inherited
  /// local tickets to the new shift.
  Future<void> adoptInheritedTickets() async {
    final params = _pendingParams;
    if (params == null) {
      emit(const OpenCashReady());
      return;
    }
    emit(const OpenCashLoading());
    try {
      final shiftId = await _auth.recordOpenCash(
        localUserId: params.localUserId,
        sessionId: params.sessionId,
        openingFloat: params.openingFloat,
        branch: params.branch,
        area: params.area,
        shiftDate: params.shiftDate,
        openingNotes: params.openingNotes,
      );
      await _auth.adoptInheritedTicketsForShift(shiftId);
      _pendingParams = null;
      ValetLog.debug(
        'OpenCashCubit.adoptInheritedTickets',
        'Shift opened + tickets adopted → emit OpenCashReady.',
      );
      emit(const OpenCashReady());
    } catch (e) {
      ValetLog.error(
        'OpenCashCubit.adoptInheritedTickets',
        'error: $e',
        e,
      );
      emit(OpenCashError(e.toString()));
    }
  }

  /// Step 2b: called when the cashier taps "Cancel" on the inherited-
  /// transactions modal.
  ///
  /// No shift was ever created, so no server cleanup is needed — just
  /// discard the cached params and let the cashier adjust the opening float.
  Future<void> cancelPendingShift() async {
    _pendingParams = null;
    ValetLog.debug(
      'OpenCashCubit.cancelPendingShift',
      'Cancelled before shift was opened → emit OpenCashCancelled.',
    );
    emit(const OpenCashCancelled());
  }

  /// Commits the open-cash request to the server (no inherited tickets path).
  Future<void> _commitOpenShift() async {
    final params = _pendingParams!;
    await _auth.recordOpenCash(
      localUserId: params.localUserId,
      sessionId: params.sessionId,
      openingFloat: params.openingFloat,
      branch: params.branch,
      area: params.area,
      shiftDate: params.shiftDate,
      openingNotes: params.openingNotes,
    );
    _pendingParams = null;
    emit(const OpenCashReady());
  }
}
