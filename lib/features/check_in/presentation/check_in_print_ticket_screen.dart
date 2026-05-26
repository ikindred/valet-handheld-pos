import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/printing/check_in_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../models/receipt_part.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_step_body.dart';

/// Step 6 — sequential 3-part print (tear-off between parts on HM-A300E).
class CheckInPrintTicketScreen extends StatefulWidget {
  const CheckInPrintTicketScreen({super.key});

  @override
  State<CheckInPrintTicketScreen> createState() =>
      _CheckInPrintTicketScreenState();
}

class _CheckInPrintTicketScreenState extends State<CheckInPrintTicketScreen> {
  Future<CheckInReceiptData?>? _receiptDataFuture;

  static final _timeFmt = DateFormat('MMM dd, yyyy · hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _receiptDataFuture ??= _loadReceiptData(context);
  }

  Future<CheckInReceiptData?> _loadReceiptData(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final id = cubit.state.ticketNumber.trim();
    if (id.isEmpty) return null;
    final row = await context.read<TicketService>().ticketById(id);
    if (row == null) return null;
    final state = cubit.state;
    final auth = context.read<AuthRepository>();
    final base = CheckInReceiptData(
      ticket: row,
      branchName: '',
      customerName: state.customerFullName,
      contactNumber: state.contactNumber,
      parkingLevel: state.parkingLevel,
      parkingSlot: state.parkingSlot,
      valetTypeLabel: _valetTypeLabel(state.valetServiceType),
      specialRequest: state.specialInstructions,
      hasSignature: state.isCustomerSignatureComplete,
      qrCode: state.ticketNumber,
    );
    return withBranchName(auth, base);
  }

  static String _valetTypeLabel(ValetServiceType t) {
    return switch (t) {
      ValetServiceType.standardValet => 'Standard Valet',
      ValetServiceType.selfPark => 'Self Park',
    };
  }

  void _onDone(BuildContext context) {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      scrollable: true,
      footer: const SizedBox.shrink(),
      child: FutureBuilder<CheckInReceiptData?>(
        future: _receiptDataFuture,
        builder: (context, snap) {
          final receiptData = snap.data;
          final loadingReceipt =
              snap.connectionState != ConnectionState.done;

          return BlocBuilder<CheckInCubit, CheckInState>(
            builder: (context, state) {
              final cubit = context.read<CheckInCubit>();
              final id = state.ticketNumber.trim();
              final nextPart = cubit.nextPartToPrint;
              final allDone = state.allPartsPrinted;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TicketSummaryColumn(state: state, ticketId: id)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Print Receipt',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (loadingReceipt)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (receiptData == null)
                              Text(
                                'Ticket data unavailable. Re-open check-in from dashboard.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else
                              ...state.receiptParts.map(
                                (part) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ReceiptPartCard(
                                    part: part,
                                    isNext: part.part == nextPart,
                                    receiptData: receiptData,
                                    onPrint: () => cubit.printPart(
                                      context,
                                      part.part,
                                      receiptData,
                                    ),
                                    onReprint: () => cubit.reprintPart(
                                      context,
                                      part.part,
                                      receiptData,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: allDone && !loadingReceipt
                                    ? () => _onDone(context)
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFF68D00),
                                  disabledBackgroundColor:
                                      const Color(0xFFE0E0E0),
                                  disabledForegroundColor:
                                      const Color(0xFF9E9E9E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Done — Go to Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketSummaryColumn extends StatelessWidget {
  const _TicketSummaryColumn({
    required this.state,
    required this.ticketId,
  });

  final CheckInState state;
  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ticket created',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ticketId.isEmpty ? '—' : ticketId,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: DashboardStyles.orange,
          ),
        ),
        const SizedBox(height: 24),
        _line(
          'Plate',
          state.plateNumber.trim().isEmpty ? '—' : state.plateNumber.trim(),
        ),
        _line(
          'Brand',
          state.vehicleBrandMake.trim().isEmpty
              ? '—'
              : state.vehicleBrandMake.trim(),
        ),
        _line(
          'Color',
          state.vehicleColor.trim().isEmpty ? '—' : state.vehicleColor.trim(),
        ),
        _line(
          'Check-in',
          state.dateTimeIn != null
              ? _CheckInPrintTicketScreenState._timeFmt
                  .format(state.dateTimeIn!.toLocal())
              : _CheckInPrintTicketScreenState._timeFmt.format(DateTime.now()),
        ),
      ],
    );
  }

  static Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPartCard extends StatelessWidget {
  const _ReceiptPartCard({
    required this.part,
    required this.isNext,
    required this.receiptData,
    required this.onPrint,
    required this.onReprint,
  });

  final ReceiptPartState part;
  final bool isNext;
  final CheckInReceiptData receiptData;
  final VoidCallback onPrint;
  final VoidCallback onReprint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              part.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusChip(status: part.status),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            part: part,
            isNext: isNext,
            onPrint: onPrint,
            onReprint: onReprint,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReceiptPartStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, showSpinner) = switch (status) {
      ReceiptPartStatus.pending => (
          const Color(0xFFF0F0F0),
          const Color(0xFF6E7584),
          'Not yet printed',
          false,
        ),
      ReceiptPartStatus.printing => (
          const Color(0xFFFFF3E0),
          const Color(0xFFF68D00),
          'Printing...',
          true,
        ),
      ReceiptPartStatus.printed => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          'Printed ✓',
          false,
        ),
      ReceiptPartStatus.failed => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          'Failed',
          false,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.part,
    required this.isNext,
    required this.onPrint,
    required this.onReprint,
  });

  final ReceiptPartState part;
  final bool isNext;
  final VoidCallback onPrint;
  final VoidCallback onReprint;

  @override
  Widget build(BuildContext context) {
    return switch (part.status) {
      ReceiptPartStatus.pending when isNext => SizedBox(
          width: 88,
          height: 36,
          child: FilledButton(
            onPressed: onPrint,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF68D00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Print',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ReceiptPartStatus.pending => const SizedBox.shrink(),
      ReceiptPartStatus.printing => SizedBox(
          width: 88,
          height: 36,
          child: FilledButton(
            onPressed: null,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ReceiptPartStatus.printed => SizedBox(
          width: 88,
          height: 36,
          child: OutlinedButton(
            onPressed: onReprint,
            child: Text(
              'Reprint',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ReceiptPartStatus.failed => SizedBox(
          width: 88,
          height: 36,
          child: OutlinedButton(
            onPressed: onReprint,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    };
  }
}
