import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/session/standard_parking_rates.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart';

/// Centered modal with “Standard Rates” (read-only). Uses a normal [Dialog] so
/// all corners match and the scrim dims the background.
Future<void> showStandardRatesSheet(
  BuildContext context, {
  required StandardParkingRates rates,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _StandardRatesDialog(rates: rates),
  );
}

class _StandardRatesDialog extends StatelessWidget {
  const _StandardRatesDialog({required this.rates});

  final StandardParkingRates rates;

  static const _divider = Divider(height: 1, color: Color(0x21000000));
  static const _cardRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Standard Rates',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applies to all areas unless overridden',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DashboardStyles.grey500,
                  ),
                ),
                const SizedBox(height: 20),
                _RateRow(
                  title: 'Flat Rate',
                  description: 'First 3 hours',
                  amountPesos: rates.flatRatePesos,
                ),
                _divider,
                _RateRow(
                  title: 'Succeeding Hour',
                  description: 'Per hour after flat',
                  amountPesos: rates.succeedingHourPesos,
                ),
                _divider,
                _RateRow(
                  title: 'Overnight Fee',
                  description: 'After 1:30 AM',
                  amountPesos: rates.overnightFeePesos,
                ),
                _divider,
                _RateRow(
                  title: 'Lost Ticket Fee',
                  description: 'Flat penalty charge',
                  amountPesos: rates.lostTicketFeePesos,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardStyles.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.title,
    required this.description,
    required this.amountPesos,
  });

  final String title;
  final String description;
  final int amountPesos;

  static const _pesoFallback = ['Noto Sans', 'Roboto'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: DashboardStyles.grey500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Text(
              '${PesoCurrency.symbol} $amountPesos',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ).copyWith(fontFamilyFallback: _pesoFallback),
            ),
          ),
        ],
      ),
    );
  }
}
