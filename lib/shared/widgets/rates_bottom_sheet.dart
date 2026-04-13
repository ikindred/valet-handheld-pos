import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/formatting/peso_currency.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/rate_service.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _border.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.tag, size: 18, color: _border),
              const SizedBox(width: 8),
              Text(
                'Rates',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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

Future<void> showBranchRatesBottomSheet(
  BuildContext context, {
  required RateService rateService,
  required String branchId,
  required String branchName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: FutureBuilder<CheckoutRatesResolved?>(
            future: rateService.checkoutRatesResolved(
              branchId: branchId,
              vehicleType: 'Standard',
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final resolved = snap.data;
              if (resolved == null) {
                return _EmptyRates(branchName: branchName);
              }
              return _RatesSheetContent(
                branchName: branchName,
                flatBlockHours: resolved.flatBlockHours,
                rates: resolved.rates,
              );
            },
          ),
        ),
      );
    },
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
        Text(
          'Branch Rates',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          branchName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DashboardStyles.grey500,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No rates available for this branch. Please go online to sync rates.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DashboardStyles.grey500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: DashboardStyles.orange,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatesSheetContent extends StatelessWidget {
  const _RatesSheetContent({
    required this.branchName,
    required this.flatBlockHours,
    required this.rates,
  });

  final String branchName;
  final int flatBlockHours;
  final StandardParkingRates rates;

  static const _mono = ['Roboto Mono', 'Noto Sans', 'Roboto'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Branch Rates',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            branchName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DashboardStyles.grey500,
            ),
          ),
          const SizedBox(height: 20),
          _AmountRow(
            label: 'Flat Rate (First $flatBlockHours hours)',
            amountPesos: rates.flatRatePesos,
            monoFallback: _mono,
          ),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Succeeding Hour',
            amountPesos: rates.succeedingHourPesos,
            monoFallback: _mono,
          ),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Overnight Fee (after 1:30AM)',
            amountPesos: rates.overnightFeePesos,
            monoFallback: _mono,
          ),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Lost Ticket Fee',
            amountPesos: rates.lostTicketFeePesos,
            monoFallback: _mono,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: DashboardStyles.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amountPesos,
    required this.monoFallback,
  });

  final String label;
  final int amountPesos;
  final List<String> monoFallback;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0').format(amountPesos);
    final amt = '${PesoCurrency.symbol} $formatted';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: DashboardStyles.grey500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amt,
          style: GoogleFonts.robotoMono(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kSpidOrange,
          ).copyWith(fontFamilyFallback: monoFallback),
        ),
      ],
    );
  }
}
