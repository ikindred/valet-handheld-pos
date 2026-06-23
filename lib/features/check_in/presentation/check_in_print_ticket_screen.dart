import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/printing/check_in_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/receipt_print_format.dart';
import '../../../core/session/standard_parking_rates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/branch_config_service.dart';
import '../../../data/services/rate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../auth/state/auth_bloc.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../models/receipt_part.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_compact_tokens.dart';
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
  static const _wideBreakpoint = 720.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _receiptDataFuture ??= _loadReceiptData(context);
  }

  Future<CheckInReceiptData?> _loadReceiptData(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final tickets = context.read<TicketService>();
    final auth = context.read<AuthRepository>();
    final rateService = context.read<RateService>();
    final branchConfig = context.read<BranchConfigService>();
    final authState = context.read<AuthBloc>().state;

    final id = cubit.state.ticketNumber.trim();
    if (id.isEmpty) return null;
    final row = await tickets.ticketById(id);
    if (!context.mounted) return null;
    if (row == null) return null;
    final state = cubit.state;
    StandardParkingRates? standardRates;
    if (authState is AuthAuthenticated) {
      standardRates = authState.standardRates;
    }

    var mallHours = ReceiptTemplateCopy.defaultMallHours;
    var overnightCutoff = '';
    var flatRateHours = 3;
    try {
      final branchId = await auth.branchUuidForApi();
      final resolved = await rateService.checkoutRatesForOffline(
        branchId: branchId,
      );
      standardRates ??= resolved.rates;
      flatRateHours = resolved.flatBlockHours;
      overnightCutoff = ReceiptPrintFormat.overnightWindowLabel(
        startHhMm24: resolved.overnightStart,
        endHhMm24: resolved.overnightEnd,
      );

      final config = await branchConfig.getConfig(branchId);
      mallHours =
          ReceiptPrintFormat.mallHoursFromBranchConfig(config) ?? mallHours;
    } catch (_) {}

    final rates = standardRates;
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
      mallHours: mallHours,
      flatRatePesos: rates?.flatRatePesos ?? 0,
      flatRateHours: flatRateHours,
      succeedingHourPesos: rates?.succeedingHourPesos ?? 0,
      overnightFeePesos: rates?.overnightFeePesos ?? 0,
      lostTicketFeePesos: rates?.lostTicketFeePesos ?? 0,
      overnightCutoff: overnightCutoff,
    );
    return withBranchName(auth, base, standardRates: standardRates);
  }

  static String _valetTypeLabel(ValetServiceType t) {
    return switch (t) {
      ValetServiceType.standardValet => 'Standard Valet',
      ValetServiceType.selfPark => 'Self-Park',
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
            buildWhen: (prev, next) =>
                prev.receiptParts != next.receiptParts ||
                prev.ticketNumber != next.ticketNumber ||
                prev.plateNumber != next.plateNumber ||
                prev.vehicleBrand != next.vehicleBrand ||
                prev.vehicleColor != next.vehicleColor ||
                prev.dateTimeIn != next.dateTimeIn,
            builder: (context, state) {
              final cubit = context.read<CheckInCubit>();
              final id = state.ticketNumber.trim();
              final nextPart = cubit.nextPartToPrint;
              final allDone = state.allPartsPrinted;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _wideBreakpoint;
                  final summary = _TicketSummaryCard(state: state, ticketId: id);
                  final printPanel = _PrintReceiptPanel(
                    loadingReceipt: loadingReceipt,
                    receiptData: receiptData,
                    state: state,
                    nextPart: nextPart,
                    allDone: allDone,
                    onPrint: cubit.printPart,
                    onReprint: cubit.reprintPart,
                    onDone: () => _onDone(context),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 20),
                        Expanded(child: printPanel),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      const SizedBox(height: CheckInCompactTokens.blockGap),
                      printPanel,
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.cardBorder),
      ),
      child: child,
    );
  }
}

class _TicketSummaryCard extends StatelessWidget {
  const _TicketSummaryCard({
    required this.state,
    required this.ticketId,
  });

  final CheckInState state;
  final String ticketId;

  static String _vehicleLine(CheckInState state) {
    final brand = state.vehicleBrand.trim();
    return brand.isEmpty ? '—' : brand;
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.checkCircle,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket created',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: tc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-in saved. Print each receipt part in order.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.35,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ticketId.isEmpty ? '—' : ticketId,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: DashboardStyles.orange,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: tc.divider),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Plate',
            value: state.plateNumber.trim().isEmpty
                ? '—'
                : state.plateNumber.trim(),
            emphasize: true,
          ),
          _DetailRow(label: 'Vehicle', value: _vehicleLine(state)),
          _DetailRow(
            label: 'Color',
            value: state.vehicleColor.trim().isEmpty
                ? '—'
                : state.vehicleColor.trim(),
          ),
          _DetailRow(
            label: 'Check-in',
            value: state.dateTimeIn != null
                ? _CheckInPrintTicketScreenState._timeFmt
                    .format(state.dateTimeIn!.toLocal())
                : _CheckInPrintTicketScreenState._timeFmt
                    .format(DateTime.now()),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tc.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: emphasize ? 16 : 14,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                  height: 1.3,
                  color: emphasize
                      ? DashboardStyles.plateBlue
                      : tc.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: tc.divider),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PrintReceiptPanel extends StatelessWidget {
  const _PrintReceiptPanel({
    required this.loadingReceipt,
    required this.receiptData,
    required this.state,
    required this.nextPart,
    required this.allDone,
    required this.onPrint,
    required this.onReprint,
    required this.onDone,
  });

  final bool loadingReceipt;
  final CheckInReceiptData? receiptData;
  final CheckInState state;
  final int? nextPart;
  final bool allDone;
  final Future<void> Function(
    BuildContext context,
    int part,
    CheckInReceiptData data,
  ) onPrint;
  final Future<void> Function(
    BuildContext context,
    int part,
    CheckInReceiptData data,
  ) onReprint;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Print receipt',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Print each part in order. Tear off between parts on the printer.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.35,
            color: tc.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (loadingReceipt)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (receiptData == null)
          _SurfaceCard(
            child: Text(
              'Ticket data unavailable. Re-open check-in from the dashboard.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.35,
                color: tc.textSecondary,
              ),
            ),
          )
        else
          ...state.receiptParts.map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceiptPartCard(
                part: part,
                isNext: part.part == nextPart,
                receiptData: receiptData!,
                onPrint: () => onPrint(context, part.part, receiptData!),
                onReprint: () => onReprint(context, part.part, receiptData!),
              ),
            ),
          ),
        if (!loadingReceipt && receiptData != null && !allDone) ...[
          const SizedBox(height: 4),
          Text(
            'Print all three parts to finish and return to the dashboard.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.35,
              color: tc.textSubtitleMuted,
            ),
          ),
        ],
        const SizedBox(height: 16),
        // TODO: Remove temporary skip-print bypass before production release.
        if (!loadingReceipt && !allDone)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tc.textPrimary,
                  side: BorderSide(color: tc.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Skip printing'),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: allDone && !loadingReceipt && receiptData != null
                ? onDone
                : null,
            icon: const Icon(LucideIcons.layoutDashboard, size: 20),
            label: Text(
              'Done — Go to Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: tc.cardBorder,
              disabledForegroundColor: tc.textSecondary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
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
    final tc = AppThemeColors.of(context);
    final highlighted = isNext && part.status == ReceiptPartStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppColors.accent : tc.cardBorder,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusChip(status: part.status),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ReceiptActionButton(
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
    final isDark = AppThemeColors.isDark(context);
    final (bg, fg, label, icon, showSpinner) = switch (status) {
      ReceiptPartStatus.pending => (
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F5F7),
          AppThemeColors.of(context).textSecondary,
          'Not yet printed',
          LucideIcons.clock,
          false,
        ),
      ReceiptPartStatus.printing => (
          isDark ? const Color(0xFF422006) : const Color(0xFFFFF3E0),
          AppColors.accent,
          'Printing…',
          LucideIcons.printer,
          true,
        ),
      ReceiptPartStatus.printed => (
          isDark ? const Color(0xFF14532D) : const Color(0xFFE8F5E9),
          AppColors.success,
          'Printed',
          LucideIcons.checkCircle,
          false,
        ),
      ReceiptPartStatus.failed => (
          isDark ? const Color(0xFF3D1F24) : const Color(0xFFFFEBEE),
          AppColors.error,
          'Failed',
          LucideIcons.alertCircle,
          false,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptActionButton extends StatelessWidget {
  const _ReceiptActionButton({
    required this.part,
    required this.isNext,
    required this.onPrint,
    required this.onReprint,
  });

  final ReceiptPartState part;
  final bool isNext;
  final VoidCallback onPrint;
  final VoidCallback onReprint;

  static const _btnWidth = 108.0;
  static const _btnHeight = 40.0;

  static ButtonStyle _filledStyle() => FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        minimumSize: const Size(_btnWidth, _btnHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle _outlinedStyle({Color? foreground, Color? border}) =>
      OutlinedButton.styleFrom(
        foregroundColor: foreground ?? AppColors.accent,
        side: BorderSide(color: border ?? AppColors.accent),
        minimumSize: const Size(_btnWidth, _btnHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return switch (part.status) {
      ReceiptPartStatus.pending when isNext => SizedBox(
          width: _btnWidth,
          height: _btnHeight,
          child: FilledButton.icon(
            onPressed: onPrint,
            style: _filledStyle(),
            icon: const Icon(LucideIcons.printer, size: 16),
            label: const Text('Print'),
          ),
        ),
      ReceiptPartStatus.pending => const SizedBox(
          width: _btnWidth,
          height: _btnHeight,
        ),
      ReceiptPartStatus.printing => SizedBox(
          width: _btnWidth,
          height: _btnHeight,
          child: FilledButton(
            onPressed: null,
            style: _filledStyle(),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ReceiptPartStatus.printed => SizedBox(
          width: _btnWidth,
          height: _btnHeight,
          child: OutlinedButton.icon(
            onPressed: onReprint,
            style: _outlinedStyle(),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Reprint'),
          ),
        ),
      ReceiptPartStatus.failed => SizedBox(
          width: _btnWidth,
          height: _btnHeight,
          child: OutlinedButton.icon(
            onPressed: onReprint,
            style: _outlinedStyle(
              foreground: AppColors.error,
              border: AppColors.error,
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
          ),
        ),
    };
  }
}
