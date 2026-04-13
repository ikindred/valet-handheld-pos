import 'package:bloc/bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/shift_service.dart';
import '../../sync/state/sync_cubit.dart';
import '../cash_sales_formulas.dart';
import '../models/open_transaction.dart';
import 'close_cash_state.dart';

class CloseCashCubit extends Cubit<CloseCashState> {
  CloseCashCubit(this._auth, this._shifts, this._sync) : super(const CloseCashInitial());

  final AuthRepository _auth;
  final ShiftService _shifts;
  final SyncCubit _sync;

  CloseCashLoaded? _loaded;

  /// Last successful load; used while confirming close or showing warnings.
  CloseCashLoaded? get lastLoaded => _loaded;

  Future<void> loadShift(int localUserId) async {
    emit(const CloseCashLoading());
    try {
      final shift = await _auth.getOpenShiftForUser(localUserId);
      if (shift == null) {
        emit(const CloseCashError('No open shift found.'));
        return;
      }
      final totalSales = await _auth.sumSalesForCheckoutShift(shift.id);
      final transactionsCount =
          await _auth.countCompletedForCheckoutShift(shift.id);
      final opening = shift.openingFloat;
      final expected = CashSalesFormulas.expectedCash(opening, totalSales);
      final remit = CashSalesFormulas.salesToRemit(opening, totalSales);
      final openRows = await _auth.queryOpenTicketsForShiftClose(shift.id);
      final openTx = openRows.map(OpenTransaction.fromTicket).toList();

      final loaded = CloseCashLoaded(
        shift: shift,
        openingFloat: opening,
        totalSales: totalSales,
        expectedCash: expected,
        actualCash: opening,
        variance: opening - expected,
        salesToRemit: remit,
        transactionsCount: transactionsCount,
        openTransactions: openTx,
        closingNotes: '',
      );
      _loaded = loaded;
      emit(loaded);
    } catch (e) {
      emit(CloseCashError(e.toString()));
    }
  }

  void updateActualCash(double amount) {
    final cur = _loaded;
    if (cur == null) return;
    final next = cur.copyWith(actualCash: amount);
    _loaded = next;
    emit(next);
  }

  void updateClosingNotes(String notes) {
    final cur = _loaded;
    if (cur == null) return;
    final next = cur.copyWith(closingNotes: notes);
    _loaded = next;
    emit(next);
  }

  Future<void> attemptCloseShift(int localUserId) async {
    final cur = _loaded;
    if (cur == null) return;
    if (cur.openTransactions.isNotEmpty) {
      emit(CloseCashHasOpenTransactions(openTransactions: cur.openTransactions));
      return;
    }
    await _executeCloseShift(localUserId);
  }

  Future<void> confirmCloseWithOpenTransactions(int localUserId) async {
    await _executeCloseShift(localUserId);
  }

  Future<void> _executeCloseShift(int localUserId) async {
    final cur = _loaded;
    if (cur == null) return;
    emit(const CloseCashConfirming());
    try {
      await _shifts.closeActiveShiftForLocalUser(
        localUserId,
        cur.actualCash,
      );
      // Flush while session + bearer token still exist; [confirmCloseCash] clears the token.
      await _sync.flush();
      await _auth.confirmCloseCash(
        localUserId: localUserId,
        closingFloat: cur.actualCash,
        closingNotes: cur.closingNotes.trim().isEmpty
            ? null
            : cur.closingNotes.trim(),
        totalSales: cur.totalSales,
        expectedCash: cur.expectedCash,
        variance: cur.variance,
        remittance: cur.salesToRemit,
        transactionsCount: cur.transactionsCount,
      );
      emit(const CloseCashSuccess());
    } catch (e) {
      emit(CloseCashError(e.toString()));
    }
  }

  void restoreLoadedAfterError() {
    if (_loaded != null) emit(_loaded!);
  }

  void dismissOpenTransactionsWarning() {
    if (_loaded != null) emit(_loaded!);
  }
}
