import 'package:bloc/bloc.dart';

import '../../../core/logging/valet_log.dart';
import '../../../data/repositories/auth_repository.dart';
import '../models/open_transaction.dart';
import 'open_cash_state.dart';

class OpenCashCubit extends Cubit<OpenCashState> {
  OpenCashCubit(this._auth) : super(const OpenCashInitial());

  final AuthRepository _auth;

  String? _pendingShiftId;

  Future<void> openShift({
    required int localUserId,
    required int sessionId,
    required double openingFloat,
    String branch = '',
    String area = '',
    String? shiftDate,
    String? openingNotes,
  }) async {
    ValetLog.debug('OpenCashCubit.openShift', 'emit OpenCashLoading');
    emit(const OpenCashLoading());
    try {
      final shiftId = await _auth.recordOpenCash(
        localUserId: localUserId,
        sessionId: sessionId,
        openingFloat: openingFloat,
        branch: branch,
        area: area,
        shiftDate: shiftDate,
        openingNotes: openingNotes,
      );
      final inherited = await _auth.queryInheritedOpenTickets(shiftId);
      if (inherited.isEmpty) {
        _pendingShiftId = null;
        ValetLog.debug(
          'OpenCashCubit.openShift',
          'success shiftId=$shiftId → emit OpenCashReady (no inherited tickets)',
        );
        emit(const OpenCashReady());
        return;
      }
      _pendingShiftId = shiftId;
      ValetLog.debug(
        'OpenCashCubit.openShift',
        'success shiftId=$shiftId → emit OpenCashHasInheritedTransactions '
        'count=${inherited.length}',
      );
      emit(
        OpenCashHasInheritedTransactions(
          inheritedTransactions:
              inherited.map(OpenTransaction.fromTicket).toList(),
        ),
      );
    } catch (e) {
      ValetLog.error(
        'OpenCashCubit.openShift',
        'error → emit OpenCashError: $e',
        e,
      );
      emit(OpenCashError(e.toString()));
    }
  }

  Future<void> adoptInheritedTickets() async {
    final id = _pendingShiftId;
    if (id == null) {
      emit(const OpenCashReady());
      return;
    }
    emit(const OpenCashLoading());
    try {
      await _auth.adoptInheritedTicketsForShift(id);
      _pendingShiftId = null;
      ValetLog.debug(
        'OpenCashCubit.adoptInheritedTickets',
        'success → emit OpenCashReady',
      );
      emit(const OpenCashReady());
    } catch (e) {
      ValetLog.error(
        'OpenCashCubit.adoptInheritedTickets',
        'error → emit OpenCashError: $e',
        e,
      );
      emit(OpenCashError(e.toString()));
    }
  }
}
