import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/formatting/peso_currency.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import 'area_parking_layout_section.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';

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

/// Loads area rates from API when UUIDs are available; falls back to local Drift.
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
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: FutureBuilder<_RatesDialogData?>(
                future: _loadRatesData(
                  authRepository: authRepository,
                  rateFetchService: rateFetchService,
                  rateService: rateService,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 140,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final data = snap.data;
                  if (data == null) {
                    return _EmptyRates(branchName: branchName);
                  }
                  return _RatesDialogContent(
                    branchName: branchName,
                    flatBlockHours: data.flatBlockHours,
                    standard: data.standard,
                    vehicleTypeRates: data.vehicleTypeRates,
                    levels: data.levels,
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RatesDialogData {
  const _RatesDialogData({
    required this.flatBlockHours,
    required this.standard,
    required this.vehicleTypeRates,
    required this.levels,
  });

  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;
}

Future<_RatesDialogData?> _loadRatesData({
  required AuthRepository authRepository,
  required RateFetchService rateFetchService,
  required RateService rateService,
}) async {
  final branchUuid = await authRepository.branchUuidForApi();
  final areaUuid = await authRepository.areaUuidForApi();
  final flatHours = CheckoutPricing.defaultFlatBlockHours;

  if (branchUuid.isNotEmpty && areaUuid.isNotEmpty) {
    final detail = await rateFetchService.fetchAreaDetail(
      branchId: branchUuid,
      areaId: areaUuid,
    );
    if (detail != null) {
      return _RatesDialogData(
        flatBlockHours: flatHours,
        standard: detail.standard,
        vehicleTypeRates: detail.vehicleTypeRates,
        levels: detail.levels,
      );
    }
  }

  final branchKey =
      branchUuid.isNotEmpty ? branchUuid : (await authRepository.branchAndAreaFromDb()).branch;
  final resolved = await rateService.checkoutRatesResolved(
    branchId: branchKey.trim().isEmpty ? '_' : branchKey.trim(),
    vehicleType: 'Standard',
  );
  if (resolved == null) return null;
  final r = resolved.rates;
  return _RatesDialogData(
    flatBlockHours: resolved.flatBlockHours,
    standard: ParkingRateFees(
      flatRate: r.flatRatePesos,
      succeedingRate: r.succeedingHourPesos,
      overnightFee: r.overnightFeePesos,
      lostTicketFee: r.lostTicketFeePesos,
    ),
    vehicleTypeRates: const [],
    levels: const [],
  );
}

class _EmptyRates extends StatelessWidget {
  const _EmptyRates({required this.branchName});

  final String branchName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Branch Rates', style: _dialogTitle()),
        const SizedBox(height: 2),
        Text(branchName, style: _dialogSubtitle()),
        const SizedBox(height: 12),
        Text(
          'No rates are available yet. Sign in online with branch and area assigned.',
          style: _dialogSubtitle(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: _closeLabel()),
          ),
        ),
      ],
    );
  }
}

class _RatesDialogContent extends StatefulWidget {
  const _RatesDialogContent({
    required this.branchName,
    required this.flatBlockHours,
    required this.standard,
    required this.vehicleTypeRates,
    required this.levels,
  });

  final String branchName;
  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;

  @override
  State<_RatesDialogContent> createState() => _RatesDialogContentState();
}

class _RatesDialogContentState extends State<_RatesDialogContent> {
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Branch Rates', style: _dialogTitle()),
        const SizedBox(height: 2),
        Text(widget.branchName, style: _dialogSubtitle()),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.standard.hasAny) ...[
                  Text('BASE RATE', style: _sectionCaps()),
                  const SizedBox(height: 6),
                  _RateFeeBlock(
                    fees: widget.standard,
                    flatBlockHours: widget.flatBlockHours,
                  ),
                ],
                if (hasVehicleTypes) ...[
                  if (widget.standard.hasAny) const SizedBox(height: 14),
                  Text('VEHICLE TYPE', style: _sectionCaps()),
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
                      style: _sectionCaps(),
                    ),
                    const SizedBox(height: 6),
                    _RateFeeBlock(
                      fees: selected.fees,
                      flatBlockHours: widget.flatBlockHours,
                    ),
                  ],
                ] else if (widget.standard.hasAny) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No vehicle-specific rates configured. Base rate applies to all types.',
                    style: _dialogSubtitle(),
                  ),
                ],
                if (widget.levels.isNotEmpty) ...[
                  if (widget.standard.hasAny || hasVehicleTypes)
                    const SizedBox(height: 14),
                  AreaParkingLayoutSection(levels: widget.levels),
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
            child: Text('Close', style: _closeLabel()),
          ),
        ),
      ],
    );
  }
}

/// Dropdown to pick a vehicle type; updates the rate block below.
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
  });

  final ParkingRateFees fees;
  final int flatBlockHours;

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
          label: 'Overnight Fee (after 1:30AM)',
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
        Expanded(child: Text(label, style: _rowLabel())),
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

TextStyle _dialogTitle() => GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

TextStyle _dialogSubtitle() => GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: DashboardStyles.grey500,
      height: 1.25,
    );

TextStyle _sectionCaps() => GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    );

TextStyle _rowLabel() => GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: DashboardStyles.grey500,
      height: 1.25,
    );

TextStyle _closeLabel() => GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: DashboardStyles.orange,
    );
