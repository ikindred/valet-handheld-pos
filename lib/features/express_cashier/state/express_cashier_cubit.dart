import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';

import '../../../core/formatting/plate_number.dart';
import '../../../core/formatting/vr_number.dart';
import '../../../core/logging/valet_log.dart';
import '../../../data/remote/check_in_exceptions.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/check_in_sync_payload.dart';
import '../../../data/services/shift_service.dart';
import '../../../data/services/ticket_service.dart';
import 'express_cashier_state.dart';

class ExpressCashierCubit extends Cubit<ExpressCashierState> {
  ExpressCashierCubit({
    required AuthRepository authRepository,
    required TicketService ticketService,
    required TransactionsApi transactionsApi,
    required ShiftService shiftService,
  })  : _auth = authRepository,
        _tickets = ticketService,
        _api = transactionsApi,
        _shifts = shiftService,
        super(const ExpressCashierInitial());

  final AuthRepository _auth;
  final TicketService _tickets;
  final TransactionsApi _api;
  final ShiftService _shifts;

  Shift? _activeShift;

  Future<void> loadTransactions(int localUserId) async {
    emit(const ExpressCashierLoading());
    try {
      final shift = await _auth.getOpenShiftForUser(localUserId);
      if (shift == null) {
        emit(const ExpressCashierError('No open shift found. Open cash first.'));
        return;
      }
      _activeShift = shift;
      final rows = await _loadExpressTransactionsForShift(shift);
      emit(
        ExpressCashierLoaded(
          transactions: rows.map(ExpressCashierTransaction.fromTicket).toList(),
        ),
      );
    } catch (e) {
      emit(ExpressCashierError(e.toString()));
    }
  }

  Future<List<Ticket>> _loadExpressTransactionsForShift(Shift shift) async {
    final session = await _auth.getActiveSession();
    final token = session?.authToken?.trim() ?? '';
    if (token.isNotEmpty) {
      await _tickets.syncExpressTransactionsForToday(
        token: token,
        shiftId: shift.id,
        userId: shift.userId,
      );
    }
    return _tickets.expressTicketsForShift(
      shift.id,
      userId: shift.userId,
    );
  }

  Future<void> save({
    required int localUserId,
    required String plateNumber,
    required String ticketNumber,
    required String amountText,
    required String vrNo,
    String? driverIn,
    String? driverOut,
  }) async {
    final current = state;
    final loaded = current is ExpressCashierLoaded ? current : null;
    if (loaded != null) {
      emit(loaded.copyWith(isSaving: true));
    }

    try {
      final plate = normalizePlateNumber(plateNumber);
      if (plate.isEmpty) {
        _failValidation('Enter a plate number.', loaded);
        return;
      }

      final ticket = ticketNumber.trim();
      if (ticket.isEmpty) {
        _failValidation('Enter a ticket number.', loaded);
        return;
      }

      final amount = double.tryParse(amountText.replaceAll(',', '').trim()) ?? 0;
      if (amount <= 0) {
        _failValidation('Enter a valid amount.', loaded);
        return;
      }

      final vr = normalizeVrNumber(vrNo);
      if (vr.isEmpty) {
        _failValidation('Enter a VR number.', loaded);
        return;
      }

      var shift = _activeShift ?? await _auth.getOpenShiftForUser(localUserId);
      if (shift == null) {
        emit(const ExpressCashierError('No open shift found. Open cash first.'));
        return;
      }
      _activeShift = shift;

      final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
      final site = await _auth.branchAndAreaFromDb();
      final branchUuid = await _auth.branchUuidForApi();
      final branchId = branchUuid.isNotEmpty ? branchUuid : site.branch;

      final driverInName = driverIn?.trim();
      final driverOutName = driverOut?.trim();

      await _tickets.persistExpressCheckInLocally(
        ticketId: ticket,
        shiftId: shift.id,
        userId: uid,
        branchId: branchId,
        plateNumber: plate,
        amount: amount,
        vrNo: vr,
        driverIn: driverInName,
        driverOut: driverOutName,
      );

      final session = await _auth.getActiveSession();
      final token = session?.authToken?.trim() ?? '';
      var synced = false;

      if (token.isNotEmpty) {
        try {
          final response = await _api.submitExpressCheckIn(
            token: token,
            ticketNumber: ticket,
            plateNumber: plate,
            amount: amount,
            vrNo: vr,
            driverIn: driverInName,
            driverOut: driverOutName,
          );
          final serverId = response.id.trim();
          if (serverId.isEmpty) {
            ValetLog.warning(
              'ExpressCashierCubit.save',
              'check-in HTTP 201 but missing server id ticket=$ticket',
            );
          } else {
            await _tickets.updateServerTicketId(ticket, serverId);
            synced = true;
          }
        } on VrNumberConflictOnServerException catch (_) {
          final linked = await _tickets.reconcileLocalTicketFromServerLookup(
            localTicketId: ticket,
            token: token,
          );
          if (linked) {
            synced = true;
          }
        } on VehicleAlreadyCheckedInException catch (_) {
          final linked = await _tickets.reconcileLocalTicketFromServerLookup(
            localTicketId: ticket,
            token: token,
          );
          if (linked) {
            synced = true;
          }
        } on DioException catch (e) {
          if (!_isUncertainNetworkDio(e)) {
            ValetLog.warning(
              'ExpressCashierCubit.save',
              'check-in failed, queueing for sync ticket=$ticket: $e',
            );
          }
        } on CheckInValidationException {
          await _tickets.deleteExpressPendingTicket(ticket);
          rethrow;
        } catch (e, st) {
          ValetLog.error(
            'ExpressCashierCubit.save',
            'check-in failed, queueing for sync ticket=$ticket',
            e,
            st,
          );
        }
      }

      if (!synced) {
        await _tickets.enqueueCheckInSync(
          localTicketId: ticket,
          payload: expressCheckInSyncQueuePayload(
            localTicketId: ticket,
            ticketNumber: ticket,
            plateNumber: plate,
            amount: amount,
            vrNo: vr,
            driverIn: driverInName,
            driverOut: driverOutName,
          ),
        );
      }

      final rows = await _tickets.expressTicketsForShift(
        shift.id,
        userId: shift.userId,
      );
      final transactions =
          rows.map(ExpressCashierTransaction.fromTicket).toList();
      emit(ExpressCashierSaved(ticketId: ticket, transactions: transactions));
    } on StateError catch (e) {
      emit(ExpressCashierError(e.message));
    } on VrNumberAlreadyUsedException catch (_) {
      if (loaded != null) {
        emit(loaded.copyWith(isSaving: false));
      }
      emit(const ExpressCashierError('This VR number is already in use.'));
    } on CheckInValidationException catch (e) {
      emit(ExpressCashierError(e.message));
    } on DioException catch (e) {
      emit(ExpressCashierError(
        e.response?.data?.toString() ?? e.message ?? 'Save failed.',
      ));
    } catch (e) {
      emit(ExpressCashierError(e.toString()));
    }
  }

  void restoreLoadedAfterSave(List<ExpressCashierTransaction> transactions) {
    emit(ExpressCashierLoaded(transactions: transactions));
  }

  Future<ExpressVoidResult> voidTransaction({
    required int localUserId,
    required String ticketId,
    String? reason,
  }) async {
    final result = await _tickets.voidExpressTicket(
      localTicketId: ticketId,
      reason: reason,
    );
    await reloadTransactionsFromDb(localUserId);
    return result;
  }

  /// Refreshes the transaction list from local DB without a loading spinner
  /// (e.g. after background [SyncCubit] marks rows synced).
  Future<void> reloadTransactionsFromDb(int localUserId) async {
    final current = state;
    final ExpressCashierLoaded? loaded = switch (current) {
      ExpressCashierLoaded() => current,
      ExpressCashierSaved(:final transactions) =>
        ExpressCashierLoaded(transactions: transactions),
      _ => null,
    };
    if (loaded == null) return;

    try {
      final shift = _activeShift ?? await _auth.getOpenShiftForUser(localUserId);
      if (shift == null) return;
      _activeShift = shift;
      final rows = await _loadExpressTransactionsForShift(shift);
      emit(
        loaded.copyWith(
          transactions:
              rows.map(ExpressCashierTransaction.fromTicket).toList(),
          isSaving: false,
        ),
      );
    } catch (e, st) {
      ValetLog.error(
        'ExpressCashierCubit.reloadTransactionsFromDb',
        'refresh failed',
        e,
        st,
      );
    }
  }

  void _failValidation(String message, ExpressCashierLoaded? loaded) {
    if (loaded != null) {
      emit(loaded.copyWith(isSaving: false));
    }
    emit(ExpressCashierError(message));
  }

  static bool _isUncertainNetworkDio(DioException e) {
    if (e.error is SocketException) return true;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }
}
