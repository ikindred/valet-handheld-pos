import 'package:bloc/bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../models/open_transaction.dart';
import 'open_cash_state.dart';

class OpenCashCubit extends Cubit<OpenCashState> {
  OpenCashCubit(this._auth) : super(const OpenCashInitial());

  final AuthRepository _auth;

  int? _pendingShiftId;

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
      final shiftId = await _auth.recordOpenCash(
        localUserId: localUserId,
        sessionId: sessionId,
        openingFloat: openingFloat,
        branch: branch,
        area: area,
        shiftDate: shiftDate,
        openingNotes: openingNotes,
      );
      final inherited =
          await _auth.queryInheritedOpenTransactions(shiftId);
      if (inherited.isEmpty) {
        _pendingShiftId = null;
        emit(const OpenCashReady());
        return;
      }
      _pendingShiftId = shiftId;
      emit(
        OpenCashHasInheritedTransactions(
          inheritedTransactions:
              inherited.map(OpenTransaction.fromRow).toList(),
        ),
      );
    } catch (e) {
      emit(OpenCashError(e.toString()));
    }
  }

  Future<void> adoptInheritedTransactions() async {
    final id = _pendingShiftId;
    if (id == null) {
      emit(const OpenCashReady());
      return;
    }
    emit(const OpenCashLoading());
    try {
      await _auth.adoptInheritedTransactionsForShift(id);
      _pendingShiftId = null;
      emit(const OpenCashReady());
    } catch (e) {
      emit(OpenCashError(e.toString()));
    }
  }
}
