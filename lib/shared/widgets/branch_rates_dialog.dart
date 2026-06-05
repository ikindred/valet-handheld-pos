import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/formatting/peso_currency.dart';
import '../../core/printing/receipt_print_format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import '../../features/check_in/domain/vehicle_body_type.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/parking_layout_service.dart';
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
  required ParkingLayoutService parkingLayoutService,
  required String branchName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AreaDialogShell(
        maxHeight: 560,
        child: AreaDialogLoader(
          authRepository: authRepository,
          rateFetchService: rateFetchService,
          rateService: rateService,
          parkingLayoutService: parkingLayoutService,
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
              usesAreaOverride: data.usesAreaOverride,
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
    this.usesAreaOverride = false,
    this.overnightStart = '',
    this.overnightEnd = '',
    this.offlineCache = false,
  });

  final String branchName;
  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final bool usesAreaOverride;
  final String overnightStart;
  final String overnightEnd;
  final bool offlineCache;

  @override
  State<_RatesOnlyDialogContent> createState() =>
      _RatesOnlyDialogContentState();
}

class _RatesOnlyDialogContentState extends State<_RatesOnlyDialogContent> {
  late VehicleBodyType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = _firstRatedType() ?? VehicleBodyType.sedan;
  }

  VehicleBodyType? _firstRatedType() {
    for (final type in VehicleBodyType.values) {
      if (_typeHasRates(type)) return type;
    }
    return null;
  }

  bool _typeHasRates(VehicleBodyType type) =>
      BranchRatesSnapshot.bodyTypeHasRates(
        type: type,
        standard: widget.standard,
        vehicleTypeRates: widget.vehicleTypeRates,
        usesAreaOverride: widget.usesAreaOverride,
      );

  ParkingRateFees? get _effectiveFees => BranchRatesSnapshot.feesForBodyType(
        type: _selectedType,
        standard: widget.standard,
        vehicleTypeRates: widget.vehicleTypeRates,
        usesAreaOverride: widget.usesAreaOverride,
      );

  int get _effectiveFlatHours => BranchRatesSnapshot.flatHoursForBodyType(
        type: _selectedType,
        standardHours: widget.flatBlockHours,
        vehicleTypeRates: widget.vehicleTypeRates,
      );

  bool get _selectedHasRates => _typeHasRates(_selectedType);

  bool get _hasRates =>
      widget.standard.hasAny ||
      widget.vehicleTypeRates.any((r) => r.fees.hasAny);

  @override
  Widget build(BuildContext context) {
    final overnightWindow = ReceiptPrintFormat.overnightWindowLabel(
      startHhMm24: widget.overnightStart,
      endHhMm24: widget.overnightEnd,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kSpidOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.tag,
                size: 18,
                color: kSpidOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branch Rates', style: branchRatesDialogTitleStyle()),
                  const SizedBox(height: 2),
                  Text(
                    widget.branchName,
                    style: branchRatesDialogSubtitleStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.offlineCache) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DashboardStyles.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: DashboardStyles.orange.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.wifiOff,
                  size: 14,
                  color: DashboardStyles.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Offline — showing last saved rates',
                    style: branchRatesDialogSubtitleStyle().copyWith(
                      color: DashboardStyles.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_hasRates)
                  Text(
                    'No rates configured for this branch yet.',
                    style: branchRatesDialogSubtitleStyle(),
                  )
                else ...[
                  Text(
                    'SELECT VEHICLE TYPE',
                    style: branchRatesSectionCapsStyle(),
                  ),
                  const SizedBox(height: 8),
                  _VehicleTypeChips(
                    selected: _selectedType,
                    onSelected: (type) => setState(() => _selectedType = type),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'RATES',
                    style: branchRatesSectionCapsStyle(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedType.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_selectedHasRates)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'No rates configured for ${_selectedType.label}. '
                        'Choose another vehicle type or contact your admin.',
                        style: branchRatesDialogSubtitleStyle(),
                      ),
                    )
                  else
                    _BranchRatesCard(
                      fees: _effectiveFees!,
                      flatBlockHours: _effectiveFlatHours,
                      overnightWindow: overnightWindow,
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

class _VehicleTypeChips extends StatelessWidget {
  const _VehicleTypeChips({
    required this.selected,
    required this.onSelected,
  });

  final VehicleBodyType selected;
  final ValueChanged<VehicleBodyType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in VehicleBodyType.values)
          _VehicleTypeChip(
            label: type.label,
            selected: type == selected,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

class _VehicleTypeChip extends StatelessWidget {
  const _VehicleTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? kSpidOrange.withValues(alpha: 0.08)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? kSpidOrange.withValues(alpha: 0.55)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? kSpidOrange : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchRatesCard extends StatelessWidget {
  const _BranchRatesCard({
    required this.fees,
    required this.flatBlockHours,
    required this.overnightWindow,
  });

  final ParkingRateFees fees;
  final int flatBlockHours;
  final String overnightWindow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlatRateHeroCard(
              amountPesos: fees.flatRate,
              flatBlockHours: flatBlockHours,
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RateMetricCard(
                      icon: LucideIcons.clock,
                      title: 'Extra hour',
                      subtitle: 'After flat block',
                      amountPesos: fees.succeedingRate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateMetricCard(
                      icon: LucideIcons.moon,
                      title: 'Overnight',
                      subtitle:
                          overnightWindow.isNotEmpty ? overnightWindow : '—',
                      amountPesos: fees.overnightFee,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _RateMetricCard(
              icon: LucideIcons.ticket,
              title: 'Lost ticket',
              subtitle: 'Replacement charge',
              amountPesos: fees.lostTicketFee,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatRateHeroCard extends StatelessWidget {
  const _FlatRateHeroCard({
    required this.amountPesos,
    required this.flatBlockHours,
  });

  final int amountPesos;
  final int flatBlockHours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kSpidOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kSpidOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.car,
              size: 20,
              color: kSpidOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flat rate',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: DashboardStyles.grey500,
                  ),
                ),
                Text(
                  'First $flatBlockHours hours',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatPeso(amountPesos),
            style: _rateAmountStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _RateMetricCard extends StatelessWidget {
  const _RateMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountPesos,
    this.fullWidth = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int amountPesos;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: DashboardStyles.grey500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: fullWidth ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: DashboardStyles.grey500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatPeso(amountPesos),
            style: _rateAmountStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

String _formatPeso(int amountPesos) {
  final formatted = NumberFormat('#,##0').format(amountPesos);
  return '${PesoCurrency.symbol} $formatted';
}

/// Poppins lacks U+20B1 (₱); Noto Sans renders the peso sign.
TextStyle _rateAmountStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w700,
}) =>
    GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: kSpidOrange,
    ).copyWith(fontFamilyFallback: const ['Noto Sans', 'Roboto']);
