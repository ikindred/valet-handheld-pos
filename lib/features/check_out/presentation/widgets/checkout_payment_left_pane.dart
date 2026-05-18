import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/db/app_database.dart';
import '../../models/checkout_preview_response.dart';
import 'check_out_ui_tokens.dart';

/// Left column on payment step — vehicle summary + server rate breakdown.
class CheckoutPaymentLeftPane extends StatelessWidget {
  const CheckoutPaymentLeftPane({
    super.key,
    required this.row,
    required this.preview,
    required this.serverTotal,
    required this.peso2,
    required this.timeInLabel,
    required this.dateInLabel,
    required this.timeOutLabel,
    required this.durationLabel,
    required this.driverOutController,
  });

  final Ticket row;
  final CheckoutPreviewResponse? preview;
  final double serverTotal;
  final NumberFormat peso2;
  final String timeInLabel;
  final String dateInLabel;
  final String timeOutLabel;
  final String durationLabel;
  final TextEditingController driverOutController;

  static const _plateBlue = Color(0xFF0068D3);
  static const _plateBarBg = Color(0xFFA7D6FF);
  static const _orange = Color(0xFFF68D00);
  static const _green = Color(0xFF27AE60);
  static const _border = Color(0xFFC0C0BF);

  String get _plate {
    final p = preview?.ticket.plate ?? preview?.releaseSummary.plate ?? '';
    return p.isNotEmpty ? p : row.plateNumber;
  }

  String get _subtitle {
    final pt = preview?.ticket;
    if (pt != null) return pt.vehicleReceiptLine;
    final parts = <String>[
      row.vehicleBrand.trim(),
      row.vehicleColor.trim(),
      row.vehicleType.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final pt = preview?.ticket;
    final flatLabel = pt?.flatRateLabel?.trim().isNotEmpty == true
        ? pt!.flatRateLabel!.trim()
        : 'Flat rate';
    final flatAmount = pt?.flatRateAmount ?? serverTotal;
    final succeedingLabel = pt?.succeedingTimeLabel?.trim() ?? '';
    final succeedingAmount = pt?.succeedingRateAmount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSummaryCard(
          plate: _plate,
          subtitle: _subtitle,
          timeInLabel: timeInLabel,
          dateInLabel: dateInLabel,
          timeOutLabel: timeOutLabel,
          durationLabel: durationLabel,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              padding: CheckOutUiTokens.cardPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CheckOutUiTokens.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('RATE BREAKDOWN', style: CheckOutUiTokens.sectionTitle()),
                  const SizedBox(height: 8),
                  _BreakdownLine(
                    label: flatLabel,
                    value: peso2.format(flatAmount),
                  ),
                  if (succeedingLabel.isNotEmpty && succeedingAmount > 0.009) ...[
                    const SizedBox(height: 6),
                    _BreakdownLine(
                      label: succeedingLabel,
                      value: peso2.format(succeedingAmount),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Amount Due',
                          style: CheckOutUiTokens.fieldLabel(),
                        ),
                      ),
                      Text(
                        peso2.format(serverTotal),
                        style: CheckOutUiTokens.amountHero(color: _orange),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: CheckOutUiTokens.hairline),
                  ),
                  Text('RETURNING VALET', style: CheckOutUiTokens.fieldLabel()),
                  const SizedBox(height: 4),
                  TextField(
                    controller: driverOutController,
                    textCapitalization: TextCapitalization.words,
                    style: CheckOutUiTokens.body(),
                    decoration: InputDecoration(
                      hintText: 'Name (optional)',
                      isDense: true,
                      filled: true,
                      fillColor: CheckOutUiTokens.hintFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0068D3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard({
    required this.plate,
    required this.subtitle,
    required this.timeInLabel,
    required this.dateInLabel,
    required this.timeOutLabel,
    required this.durationLabel,
  });

  final String plate;
  final String subtitle;
  final String timeInLabel;
  final String dateInLabel;
  final String timeOutLabel;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: CheckoutPaymentLeftPane._plateBarBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              plate.isEmpty ? '—' : plate,
              style: CheckOutUiTokens.plate().copyWith(
                color: CheckoutPaymentLeftPane._plateBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: CheckOutUiTokens.body()),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeColumn(
                  label: 'TIME IN',
                  primary: timeInLabel,
                  secondary: dateInLabel,
                  primaryColor: const Color(0xFF0A1B39),
                  secondaryColor: const Color(0xFF0A1B39),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeColumn(
                  label: 'TIME OUT',
                  primary: timeOutLabel,
                  secondary: durationLabel,
                  primaryColor: CheckoutPaymentLeftPane._orange,
                  secondaryColor: CheckoutPaymentLeftPane._green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String label;
  final String primary;
  final String secondary;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CheckOutUiTokens.fieldLabel()),
        const SizedBox(height: 2),
        Text(primary, style: CheckOutUiTokens.timeDisplay(color: primaryColor)),
        Text(
          secondary,
          style: CheckOutUiTokens.helper().copyWith(color: secondaryColor),
        ),
      ],
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    this.showRule = true,
  });

  final String label;
  final String value;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: CheckOutUiTokens.fieldLabel())),
            Text(value, style: CheckOutUiTokens.money()),
          ],
        ),
        if (showRule) ...[
          const SizedBox(height: 6),
          const Divider(height: 1, color: CheckOutUiTokens.hairline),
        ],
      ],
    );
  }
}
