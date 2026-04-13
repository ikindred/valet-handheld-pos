import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/local/db/app_database.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/checkout_vehicle_review_tabs.dart';

/// Step 2 — Vehicle review (read-only), Figma-aligned
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=34-1994)).
class CheckOutVehicleInfoScreen extends StatelessWidget {
  const CheckOutVehicleInfoScreen({super.key});

  static const _grey500 = Color(0xFF6C7688);
  static const _plateBlue = Color(0xFF0068D3);
  static const _plateBarBg = Color(0xFFA7D6FF);
  static const _green = Color(0xFF27AE60);

  static List<String> _belongings(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final d = jsonDecode(json);
      if (d is List) {
        return [for (final e in d) e.toString()];
      }
    } catch (_) {}
    return const [];
  }

  static String _slotLine(Ticket row) {
    return '—';
  }

  static String _prettyValetType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Standard Valet';
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((s) => s.isNotEmpty)
        .map(
          (w) =>
              '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  static String _durationSoFar(int timeInUnix) {
    final inDt = DateTime.fromMillisecondsSinceEpoch(timeInUnix * 1000);
    final d = DateTime.now().difference(inDt);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m mins';
    return '$h hrs $m mins';
  }

  static TextStyle _poppins(
    double size,
    FontWeight w,
    Color c, {
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      height: height,
      color: c,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) => a.ticket != b.ticket,
      builder: (context, state) {
        final row = state.ticket;
        if (row == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final belongings = _belongings(row.personalBelongings);
        final timeInMs = DateTime.tryParse(row.checkInAt)?.millisecondsSinceEpoch ?? 0;
        final timeIn = DateTime.fromMillisecondsSinceEpoch(timeInMs);
        final now = DateTime.now();
        final timeInLabel = DateFormat('h:mm a').format(timeIn);
        final dateInLabel = DateFormat('MMMM d, y').format(timeIn);
        final timeOutLabel = DateFormat('h:mm a').format(now);
        final durationLabel = _durationSoFar(timeInMs ~/ 1000);
        final slot = _slotLine(row);
        final subtitle = [
          row.vehicleBrand.trim(),
          row.vehicleColor.trim(),
          row.vehicleType.trim(),
        ].where((s) => s.isNotEmpty).join(' · ');
        final displaySubtitle = subtitle.isEmpty ? '—' : subtitle;

        return CheckOutStepBody(
          showBack: true,
          onBack: () => context.go('/check-out/step-1'),
          primaryLabel: 'Next: Proceed to payment',
          onPrimary: () => context.go('/check-out/step-3'),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 960;

              final tabs = CheckoutVehicleReviewTabs(
                vehicleInfoSelected: true,
                onVehicleInfoTap: null,
                onConditionTap: () => context.go('/check-out/step-3'),
              );

              final vehicleCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VEHICLE', style: _poppins(15, FontWeight.w500, AppColors.textPrimary)),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      color: _plateBarBg,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          row.plateNumber.isEmpty ? '—' : row.plateNumber,
                          style: _poppins(40, FontWeight.w700, _plateBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(displaySubtitle, style: _poppins(15, FontWeight.w500, AppColors.textPrimary)),
                    const SizedBox(height: 22),
                    _OrangeChip(text: slot),
                  ],
                ),
              );

              final customerCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUSTOMER', style: _poppins(15, FontWeight.w500, AppColors.textPrimary)),
                    const SizedBox(height: 11),
                    Text(
                      '—',
                      style: _poppins(25, FontWeight.w500, AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.cellphoneNumber.trim().isEmpty
                          ? '—'
                          : row.cellphoneNumber.trim(),
                      style: _poppins(15, FontWeight.w500, AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _prettyValetType(null),
                        style: _poppins(15, FontWeight.w600, DashboardStyles.orange),
                      ),
                    ),
                  ],
                ),
              );

              final timeInCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME IN', style: _poppins(15, FontWeight.w500, _grey500)),
                    const SizedBox(height: 11),
                    Text(timeInLabel, style: _poppins(30, FontWeight.w600, AppColors.textPrimary)),
                    Text(dateInLabel, style: _poppins(15, FontWeight.w500, AppColors.textPrimary)),
                  ],
                ),
              );

              final timeOutCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME OUT', style: _poppins(15, FontWeight.w500, _grey500)),
                    const SizedBox(height: 11),
                    Text(
                      timeOutLabel,
                      style: _poppins(30, FontWeight.w600, DashboardStyles.orange),
                    ),
                    Text(
                      durationLabel,
                      style: _poppins(15, FontWeight.w500, _green),
                    ),
                  ],
                ),
              );

              const valetName = '—';

              final staffCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STAFF', style: _poppins(15, FontWeight.w500, AppColors.textPrimary)),
                    const SizedBox(height: 25),
                    _StaffRow(label: 'Valet In', name: valetName),
                    const SizedBox(height: 8),
                    Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.13)),
                    const SizedBox(height: 8),
                    _StaffRow(label: 'Valet Out', name: valetName),
                  ],
                ),
              );

              final belongingsCard = _WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DECLARED BELONGINGS',
                      style: _poppins(15, FontWeight.w500, AppColors.textPrimary),
                    ),
                    const SizedBox(height: 25),
                    if (belongings.isEmpty)
                      Text(
                        'None declared',
                        style: _poppins(14, FontWeight.w400, _grey500),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final b in belongings) _OrangeChip(text: b),
                        ],
                      ),
                  ],
                ),
              );

              if (wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tabs,
                    const SizedBox(height: 20),
                    vehicleCard,
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: customerCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: timeInCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: timeOutCard),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    staffCard,
                    const SizedBox(height: 16),
                    belongingsCard,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabs,
                  const SizedBox(height: 16),
                  vehicleCard,
                  const SizedBox(height: 12),
                  customerCard,
                  const SizedBox(height: 12),
                  timeInCard,
                  const SizedBox(height: 12),
                  timeOutCard,
                  const SizedBox(height: 12),
                  staffCard,
                  const SizedBox(height: 12),
                  belongingsCard,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _OrangeChip extends StatelessWidget {
  const _OrangeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: DashboardStyles.orange),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DashboardStyles.orange,
        ),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CheckOutVehicleInfoScreen._grey500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            name,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
