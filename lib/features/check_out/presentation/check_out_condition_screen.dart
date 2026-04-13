import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/presentation/widgets/vehicle_condition_diagram.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/checkout_vehicle_review_tabs.dart';

const _kGrey500 = Color(0xFF6C7688);
const _kBorder = Color(0xFFC0C0BF);
const _kCardBg = Color(0xFFF4F5F7);
const _kGreen = Color(0xFF27AE60);
const _kOrange = Color(0xFFF68D00);
const _kRed = Color(0xFFEC2231);

/// Step 3 — Vehicle condition review at check-out
/// ([Figma 36-2255](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=36-2255),
/// [37-2855](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=37-2855)).
class CheckOutConditionScreen extends StatelessWidget {
  const CheckOutConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.checkInDamage != b.checkInDamage ||
          a.checkoutAddedDamage != b.checkoutAddedDamage ||
          a.checkoutExitIssueSignatureAcknowledged !=
              b.checkoutExitIssueSignatureAcknowledged,
      builder: (context, state) {
        final row = state.ticket;
        if (row == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final signedIn = (row.signaturePng ?? '').trim().isNotEmpty;
        final timeIn = DateTime.tryParse(row.checkInAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final timeLabel = DateFormat('h:mm a').format(timeIn);
        final nCheckIn = state.checkInDamage.length;
        final hasCheckoutDamage = state.checkoutAddedDamage.isNotEmpty;
        final showCheckoutCompare = hasCheckoutDamage &&
            state.checkoutExitIssueSignatureAcknowledged;
        final checkoutIds =
            state.checkoutAddedDamage.map((e) => e.id).toSet();

        return CheckOutStepBody(
          scrollable: false,
          showBack: true,
          onBack: () => context.go('/check-out/step-2'),
          primaryLabel: 'Next: Proceed to payment',
          onPrimary: () => context.go('/check-out/step-4'),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              final tabs = CheckoutVehicleReviewTabs(
                vehicleInfoSelected: false,
                onVehicleInfoTap: () => context.go('/check-out/step-2'),
                onConditionTap: null,
              );

              final leftColumn = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tabs,
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'AT CHECK-IN',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$nCheckIn Items',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0x7A0A1B39),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (signedIn) ...[
                      _SignedAtCheckInChip(),
                      const SizedBox(height: 10),
                    ],
                    _TimeItemsChip(timeLabel: timeLabel, count: nCheckIn),
                    const SizedBox(height: 14),
                    ...[
                      for (final e in state.checkInDamage) ...[
                        _AtCheckInIssueCard(entry: e),
                        const SizedBox(height: 8),
                      ],
                    ],
                    if (state.checkInDamage.isEmpty)
                      Text(
                        'No damage logged at check-in.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kGrey500,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _AddNewIssueButton(
                      onPressed: () => context.push('/check-out/add-issue'),
                    ),
                    if (hasCheckoutDamage) ...[
                      const SizedBox(height: 24),
                      if (showCheckoutCompare)
                        _NewDamageAlertBanner(
                          count: state.checkoutAddedDamage.length,
                        ),
                      if (showCheckoutCompare) const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'AT CHECK-OUT',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${state.checkoutAddedDamage.length} Items',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0x7A0A1B39),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final e in state.checkoutAddedDamage) ...[
                        if (showCheckoutCompare)
                          _AtCheckOutNewIssueCard(entry: e)
                        else
                          _AtCheckInIssueCard(entry: e),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              );

              final diagram = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VEHICLE DIAGRAM',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kGrey500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use Add new Issue to place markers. After signing, check-in pins fade on the diagram.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0x7A0A1B39),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.13),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: VehicleConditionDiagram(
                            entries: state.diagramEntries,
                            onImageTap: null,
                            checkoutMarkerIds: checkoutIds,
                            fadeNonCheckoutMarkers: showCheckoutCompare,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: diagram),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 320, child: leftColumn),
                  const SizedBox(height: 16),
                  Expanded(child: diagram),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SignedAtCheckInChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Signed at check-in ✓',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeItemsChip extends StatelessWidget {
  const _TimeItemsChip({required this.timeLabel, required this.count});

  final String timeLabel;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _kOrange),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$timeLabel ',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kOrange,
              ),
            ),
            TextSpan(
              text: '· $count items',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _kOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtCheckInIssueCard extends StatelessWidget {
  const _AtCheckInIssueCard({required this.entry});

  final VehicleDamageEntry entry;

  static Color _dot(DamageType t) {
    switch (t) {
      case DamageType.crack:
        return const Color(0xFF0068D3);
      case DamageType.scratch:
        return const Color(0xFFF68D00);
      case DamageType.dent:
        return const Color(0xFFEC2231);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = entry.zoneLabel ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1B39),
                  ),
                ),
                Text(
                  zone,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0x7F0A1B39),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtCheckOutNewIssueCard extends StatelessWidget {
  const _AtCheckOutNewIssueCard({required this.entry});

  final VehicleDamageEntry entry;

  static Color _dot(DamageType t) {
    switch (t) {
      case DamageType.crack:
        return const Color(0xFF0068D3);
      case DamageType.scratch:
        return const Color(0xFFF68D00);
      case DamageType.dent:
        return const Color(0xFFEC2231);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = entry.zoneLabel ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1B39),
                  ),
                ),
                Text(
                  zone,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0x7F0A1B39),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kRed),
            ),
            child: Text(
              'New',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _kRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewDamageAlertBanner extends StatelessWidget {
  const _NewDamageAlertBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? '1 new damage found — document before releasing'
        : '$count new damages found — document before releasing';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRed),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _kRed,
        ),
      ),
    );
  }
}

class _AddNewIssueButton extends StatelessWidget {
  const _AddNewIssueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECEC),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRed),
          ),
          child: Text(
            'Add new Issue',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _kRed,
            ),
          ),
        ),
      ),
    );
  }
}
