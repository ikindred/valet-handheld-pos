import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/local/db/app_database.dart';
import '../../domain/checkout_pricing.dart';
import '../../models/checkout_preview_response.dart';
import 'check_out_ui_tokens.dart';

/// Left column on payment step — vehicle summary + server rate breakdown.
class CheckoutPaymentLeftPane extends StatelessWidget {
  const CheckoutPaymentLeftPane({
    super.key,
    required this.row,
    required this.preview,
    required this.serverTotal,
    this.breakdown,
    required this.peso2,
    required this.timeInLabel,
    required this.dateInLabel,
    required this.timeOutLabel,
    required this.durationLabel,
    required this.flatBlockHours,
    required this.driverOutController,
    required this.isLostTicket,
    required this.lostTicketFee,
    required this.onLostTicketChanged,
  });

  final Ticket row;
  final CheckoutPreviewResponse? preview;
  final double serverTotal;
  final CheckoutBreakdown? breakdown;
  final bool isLostTicket;
  final double lostTicketFee;
  final ValueChanged<bool> onLostTicketChanged;
  final NumberFormat peso2;
  final String timeInLabel;
  final String dateInLabel;
  final String timeOutLabel;
  final String durationLabel;
  final int flatBlockHours;
  final TextEditingController driverOutController;

  static const _plateBlue = Color(0xFF0068D3);
  static const _orange = Color(0xFFF68D00);
  static const _green = Color(0xFF27AE60);
  static const _red = Color(0xFFEC2231);

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
    final tc = AppThemeColors.of(context);
    final border = tc.cardBorder;
    final b = breakdown;
    final flatHours = flatBlockHours;
    final flatLabel = 'First $flatHours hrs (flat)';
    final flatAmount = b?.flatRateAmount ?? serverTotal;
    final succeedingAmount = b?.succeedingAmount ?? 0;
    final succeedingLabel =
        b != null && succeedingAmount > 0.009 ? 'Succeeding hours' : '';
    final overnightAmount = b?.overnightAmount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
        Container(
          width: double.infinity,
          padding: CheckOutUiTokens.cardPadding,
          decoration: BoxDecoration(
            color: CheckOutUiTokens.cardBgOf(context),
            borderRadius: BorderRadius.circular(CheckOutUiTokens.cardRadius),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
                  Text(
                    'RATE BREAKDOWN',
                    style: CheckOutUiTokens.sectionTitleOf(context),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: isLostTicket
                        ? CheckOutUiTokens.lostTicketTileBgOf(context)
                        : CheckOutUiTokens.hintFillOf(context),
                    borderRadius: BorderRadius.circular(8),
                    child: CheckboxListTile(
                      value: isLostTicket,
                      onChanged: (v) => onLostTicketChanged(v ?? false),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      activeColor: _red,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Lost ticket (no stub)',
                        style: CheckOutUiTokens.bodyOf(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Charge lost ticket fee · ${peso2.format(lostTicketFee)}',
                        style: CheckOutUiTokens.money().copyWith(
                          color: _red,
                          fontSize: CheckOutUiTokens.helper().fontSize,
                          fontWeight: CheckOutUiTokens.helper().fontWeight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BreakdownLine(
                    label: flatLabel,
                    value: peso2.format(flatAmount),
                  ),
                  if (succeedingLabel.isNotEmpty &&
                      succeedingAmount > 0.009) ...[
                    const SizedBox(height: 6),
                    _BreakdownLine(
                      label: succeedingLabel,
                      value: peso2.format(succeedingAmount),
                    ),
                  ],
                  if (overnightAmount > 0.009) ...[
                    const SizedBox(height: 6),
                    _BreakdownLine(
                      label: 'Overnight fee',
                      value: peso2.format(overnightAmount),
                    ),
                  ],
                  if (isLostTicket) ...[
                    const SizedBox(height: 6),
                    _BreakdownLine(
                      label: 'Lost ticket fee',
                      value: peso2.format(lostTicketFee),
                      showRule: false,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Amount Due',
                          style: CheckOutUiTokens.fieldLabelOf(context),
                        ),
                      ),
                      Text(
                        peso2.format(serverTotal),
                        style: CheckOutUiTokens.amountHero(color: _orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: 10),
        _ReturningValetAttendantCard(
          controller: driverOutController,
        ),
      ],
    );
  }
}

/// Returning valet name captured at payment (Figma left column, below rates).
class _ReturningValetAttendantCard extends StatelessWidget {
  const _ReturningValetAttendantCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final border = tc.cardBorder;
    return Container(
      width: double.infinity,
      padding: CheckOutUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: CheckOutUiTokens.cardBgOf(context),
        borderRadius: BorderRadius.circular(CheckOutUiTokens.cardRadius),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RETURNING VALET ATTENDANT',
            style: CheckOutUiTokens.sectionTitleOf(context),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: CheckOutUiTokens.bodyOf(context),
            decoration: InputDecoration(
              hintText: 'Name of valet returning the vehicle',
              hintStyle: CheckOutUiTokens.hintOf(context),
              isDense: true,
              filled: true,
              fillColor: CheckOutUiTokens.hintFillOf(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFF68D00),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
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
    final tc = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: CheckOutUiTokens.plateBarBgOf(context),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: CheckoutPaymentLeftPane._plateBlue.withValues(
                  alpha: 0.45,
                ),
              ),
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
          Text(subtitle, style: CheckOutUiTokens.bodyOf(context)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeColumn(
                  label: 'CHECK IN',
                  primary: timeInLabel,
                  secondary: dateInLabel,
                  primaryColor: tc.textPrimary,
                  secondaryColor: tc.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeColumn(
                  label: 'CHECK OUT',
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
        Text(label, style: CheckOutUiTokens.fieldLabelOf(context)),
        const SizedBox(height: 2),
        Text(primary, style: CheckOutUiTokens.timeDisplay(color: primaryColor)),
        Text(
          secondary,
          style: CheckOutUiTokens.helperOf(context).copyWith(
            color: secondaryColor,
          ),
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
            Expanded(
              child: Text(label, style: CheckOutUiTokens.fieldLabelOf(context)),
            ),
            Text(value, style: CheckOutUiTokens.moneyOf(context)),
          ],
        ),
        if (showRule) ...[
          const SizedBox(height: 6),
          Divider(height: 1, color: CheckOutUiTokens.hairlineOf(context)),
        ],
      ],
    );
  }
}
