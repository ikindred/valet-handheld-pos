import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/formatting/peso_currency.dart';
import '../../core/printing/receipt_print_format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'area_dialog_loader.dart';
import 'area_dialog_shell.dart';

/// SPiD orange for rate amounts (design spec).
const Color kSpidOrange = Color(0xFFE87722);

String branchRatesSubtitle(({String branch, String area}) site) {
  final b = site.branch.trim();
  final a = site.area.trim();
  if (b.isEmpty && a.isEmpty) return 'Current branch';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$b · $a';
}

TextStyle branchRatesDialogTitleStyle() => GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

TextStyle branchRatesDialogSubtitleStyle() => GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: DashboardStyles.grey500,
      height: 1.25,
    );

TextStyle branchRatesSectionCapsStyle() => GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    );

TextStyle branchRatesDialogCloseStyle() => GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: DashboardStyles.orange,
    );

/// Outlined pill matching [DashboardStatusPill] height and corner radius.
class RatesOutlinePill extends StatelessWidget {
  const RatesOutlinePill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const Color _border = Color(0xFF6C7688);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _border.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.tag, size: 14, color: _border),
              const SizedBox(width: 6),
              Text(
                'Rates',
                style: DashboardStyles.headerPillLabel().copyWith(
                  color: _border,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branch + vehicle-type rates — refreshes `GET /branches/{id}/areas/{areaId}` each open.
Future<void> showBranchRatesDialog(
  BuildContext context, {
  required AuthRepository authRepository,
  required RateFetchService rateFetchService,
  required RateService rateService,
  required String branchName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AreaDialogShell(
        child: AreaDialogLoader(
          authRepository: authRepository,
          rateFetchService: rateFetchService,
          rateService: rateService,
          allowOfflineFallback: true,
          builder: (context, result, retry) {
            if (result.hasError) {
              return AreaDialogErrorBody(
                title: 'Branch Rates',
                branchName: branchName,
                message: result.errorMessage!,
                onRetry: retry,
              );
            }
            final data = result.data!;
            return _RatesOnlyDialogContent(
              branchName: branchName,
              flatBlockHours: data.flatBlockHours,
              standard: data.standard,
              vehicleTypeRates: data.vehicleTypeRates,
              overnightStart: data.overnightStart,
              overnightEnd: data.overnightEnd,
              offlineCache: result.offlineCache,
            );
          },
        ),
      );
    },
  );
}

class _RatesOnlyDialogContent extends StatefulWidget {
  const _RatesOnlyDialogContent({
    required this.branchName,
    required this.flatBlockHours,
    required this.standard,
    required this.vehicleTypeRates,
    this.overnightStart = '',
    this.overnightEnd = '',
    this.offlineCache = false,
  });

  final String branchName;
  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final String overnightStart;
  final String overnightEnd;
  final bool offlineCache;

  @override
  State<_RatesOnlyDialogContent> createState() =>
      _RatesOnlyDialogContentState();
}

class _RatesOnlyDialogContentState extends State<_RatesOnlyDialogContent> {
  String? _selectedVehicleTypeId;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleTypeRates.isNotEmpty) {
      _selectedVehicleTypeId = widget.vehicleTypeRates.first.id;
    }
  }

  VehicleTypeRateRow? get _selectedRow {
    final id = _selectedVehicleTypeId;
    if (id == null) return null;
    for (final row in widget.vehicleTypeRates) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRow;
    final hasVehicleTypes = widget.vehicleTypeRates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Branch Rates', style: branchRatesDialogTitleStyle()),
        const SizedBox(height: 2),
        Text(widget.branchName, style: branchRatesDialogSubtitleStyle()),
        if (widget.offlineCache) ...[
          const SizedBox(height: 8),
          Text(
            'Offline — showing last saved rates.',
            style: branchRatesDialogSubtitleStyle().copyWith(
              color: DashboardStyles.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.standard.hasAny) ...[
                  Text('BASE RATE', style: branchRatesSectionCapsStyle()),
                  const SizedBox(height: 6),
                  _RateFeeBlock(
                    fees: widget.standard,
                    flatBlockHours: widget.flatBlockHours,
                    overnightStart: widget.overnightStart,
                    overnightEnd: widget.overnightEnd,
                  ),
                ],
                if (hasVehicleTypes) ...[
                  if (widget.standard.hasAny) const SizedBox(height: 14),
                  Text('VEHICLE TYPE', style: branchRatesSectionCapsStyle()),
                  const SizedBox(height: 8),
                  _VehicleTypeSelector(
                    rows: widget.vehicleTypeRates,
                    selectedId: _selectedVehicleTypeId,
                    onChanged: (id) =>
                        setState(() => _selectedVehicleTypeId = id),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'RATES — ${selected.name.toUpperCase()}',
                      style: branchRatesSectionCapsStyle(),
                    ),
                    const SizedBox(height: 6),
                    _RateFeeBlock(
                      fees: selected.fees,
                      flatBlockHours: widget.flatBlockHours,
                      overnightStart: widget.overnightStart,
                      overnightEnd: widget.overnightEnd,
                    ),
                  ],
                ] else if (widget.standard.hasAny) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No vehicle-specific rates configured. Base rate applies to all types.',
                    style: branchRatesDialogSubtitleStyle(),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'No rates configured for this branch yet.',
                    style: branchRatesDialogSubtitleStyle(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: branchRatesDialogCloseStyle()),
          ),
        ),
      ],
    );
  }
}

class _VehicleTypeSelector extends StatelessWidget {
  const _VehicleTypeSelector({
    required this.rows,
    required this.selectedId,
    required this.onChanged,
  });

  final List<VehicleTypeRateRow> rows;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  static const Color _border = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF0A1B39),
            size: 22,
          ),
          hint: Text('Select vehicle type', style: _dropdownHint()),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: [
            for (final row in rows)
              DropdownMenuItem<String>(
                value: row.id,
                child: Text(row.name),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

TextStyle _dropdownHint() => GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: DashboardStyles.grey500,
    );

class _RateFeeBlock extends StatelessWidget {
  const _RateFeeBlock({
    required this.fees,
    required this.flatBlockHours,
    required this.overnightStart,
    required this.overnightEnd,
  });

  final ParkingRateFees fees;
  final int flatBlockHours;
  final String overnightStart;
  final String overnightEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AmountRow(
          label: 'Flat Rate (First $flatBlockHours hours)',
          amountPesos: fees.flatRate,
        ),
        const SizedBox(height: 8),
        _AmountRow(
          label: 'Succeeding Hour',
          amountPesos: fees.succeedingRate,
        ),
        const SizedBox(height: 8),
        _AmountRow(
          label: ReceiptPrintFormat.overnightFeeRowLabel(
            startHhMm24: overnightStart,
            endHhMm24: overnightEnd,
          ),
          amountPesos: fees.overnightFee,
        ),
        const SizedBox(height: 8),
        _AmountRow(
          label: 'Lost Ticket Fee',
          amountPesos: fees.lostTicketFee,
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amountPesos,
  });

  final String label;
  final int amountPesos;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0').format(amountPesos);
    final amt = '${PesoCurrency.symbol} $formatted';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: _rowLabel()),
        ),
        const SizedBox(width: 8),
        Text(
          amt,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kSpidOrange,
            fontFamilyFallback: const ['Noto Sans', 'Roboto'],
          ),
        ),
      ],
    );
  }
}

TextStyle _rowLabel() => GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: DashboardStyles.grey500,
      height: 1.25,
    );
