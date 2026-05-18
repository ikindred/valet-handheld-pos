import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/presentation/widgets/vehicle_condition_diagram.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../domain/checkout_preview_format.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';
import 'widgets/checkout_vehicle_review_footer.dart';
import 'widgets/checkout_vehicle_review_tabs.dart';

const _kBorder = Color(0xFFC0C0BF);
const _kCardBg = Color(0xFFF4F5F7);
const _kGreen = Color(0xFF27AE60);
const _kOrange = Color(0xFFF68D00);
const _kRed = Color(0xFFEC2231);

/// Step 3 — Vehicle review · **Condition Check** tab
/// ([Figma 36-2255](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=36-2255),
/// [37-2855](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=37-2855)).
class CheckOutConditionScreen extends StatelessWidget {
  const CheckOutConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.preview != b.preview ||
          a.isLoadingPreview != b.isLoadingPreview ||
          a.checkInDamage != b.checkInDamage ||
          a.checkoutAddedDamage != b.checkoutAddedDamage,
      builder: (context, state) {
        final row = state.ticket;
        if (row == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final preview = state.preview;
        final signedIn = (row.signaturePng ?? '').trim().isNotEmpty;
        final timeLabel = preview?.ticket.timeIn != null
            ? formatPreviewTime(preview!.ticket.timeIn)
            : formatPreviewTime(row.checkInAt);

        final usePreviewComparison =
            preview != null && preview.conditionComparison.isNotEmpty;
        final allEntries = usePreviewComparison
            ? damageEntriesFromComparison(preview.conditionComparison)
            : state.diagramEntries;
        final checkInEntries = usePreviewComparison
            ? damageEntriesFromComparison(
                [
                  for (final c in preview.conditionComparison)
                    if (!c.isNew) c,
                ],
              )
            : state.checkInDamage;
        final checkoutEntries = usePreviewComparison
            ? damageEntriesFromComparison(
                [
                  for (final c in preview.conditionComparison)
                    if (c.isNew) c,
                ],
              )
            : state.checkoutAddedDamage;

        final nCheckIn = checkInEntries.length;
        final hasCheckoutDamage = checkoutEntries.isNotEmpty;
        final showCheckoutCompare = hasCheckoutDamage;
        final checkoutIds = usePreviewComparison
            ? newComparisonEntryIds(preview.conditionComparison)
            : checkoutEntries.map((e) => e.id).toSet();

        return CheckOutStepBody(
          scrollable: false,
          footer: CheckoutVehicleReviewFooter(
            onBack: () => context.go('/check-out/step-2'),
            primaryLabel: 'Next: Proceed to payment',
            onPrimary: () => context.go('/check-out/step-4'),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              final tabs = CheckoutVehicleReviewTabs(
                vehicleInfoSelected: false,
                onVehicleInfoTap: () => context.go('/check-out/step-2'),
                onConditionTap: null,
              );

              final sidebar = _ConditionSidebar(
                signedIn: signedIn,
                timeLabel: timeLabel,
                checkInCount: nCheckIn,
                checkInDamage: checkInEntries,
                checkoutDamage: checkoutEntries,
                showCheckoutSection: showCheckoutCompare,
              );

              final diagram = _ConditionDiagramPanel(
                entries: allEntries,
                checkoutMarkerIds: checkoutIds,
                fadeNonCheckoutMarkers: showCheckoutCompare,
                showAlert: showCheckoutCompare,
                newDamageCount: checkoutEntries.length,
                onAddIssue: () => context.push('/check-out/add-issue'),
              );

              if (wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tabs,
                    const SizedBox(height: CheckInCompactTokens.blockGap),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: sidebar),
                          const SizedBox(
                            width: CheckInCompactTokens.columnDividerWidth,
                          ),
                          Expanded(flex: 4, child: diagram),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabs,
                  const SizedBox(height: CheckInCompactTokens.blockGap),
                  SizedBox(height: 220, child: sidebar),
                  const SizedBox(height: 12),
                  Expanded(child: diagram),
                ],
              );
            },
          ),
              if (state.isLoadingPreview)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConditionSidebar extends StatelessWidget {
  const _ConditionSidebar({
    required this.signedIn,
    required this.timeLabel,
    required this.checkInCount,
    required this.checkInDamage,
    required this.checkoutDamage,
    required this.showCheckoutSection,
  });

  final bool signedIn;
  final String timeLabel;
  final int checkInCount;
  final List<VehicleDamageEntry> checkInDamage;
  final List<VehicleDamageEntry> checkoutDamage;
  final bool showCheckoutSection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('AT CHECK-IN', style: CheckOutUiTokens.sectionTitle()),
              const Spacer(),
              _TimeItemsChip(timeLabel: timeLabel, count: checkInCount),
            ],
          ),
          if (signedIn) ...[
            const SizedBox(height: 10),
            const _SignedAtCheckInChip(),
          ],
          const SizedBox(height: 12),
          if (checkInDamage.isEmpty)
            Text(
              'No damage logged at check-in.',
              style: CheckOutUiTokens.hint(),
            )
          else
            for (final e in checkInDamage) ...[
              _AtCheckInIssueCard(entry: e),
              const SizedBox(height: 8),
            ],
          if (showCheckoutSection) ...[
            const SizedBox(height: CheckInCompactTokens.blockGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('AT CHECK-OUT', style: CheckOutUiTokens.sectionTitle()),
                const SizedBox(width: 6),
                Text(
                  '${checkoutDamage.length} Items',
                  style: CheckOutUiTokens.helper(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final e in checkoutDamage) ...[
              _AtCheckOutNewIssueCard(entry: e),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConditionDiagramPanel extends StatelessWidget {
  const _ConditionDiagramPanel({
    required this.entries,
    required this.checkoutMarkerIds,
    required this.fadeNonCheckoutMarkers,
    required this.showAlert,
    required this.newDamageCount,
    required this.onAddIssue,
  });

  final List<VehicleDamageEntry> entries;
  final Set<String> checkoutMarkerIds;
  final bool fadeNonCheckoutMarkers;
  final bool showAlert;
  final int newDamageCount;
  final VoidCallback onAddIssue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAlert) ...[
          _NewDamageAlertBanner(count: newDamageCount),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
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
                      padding: const EdgeInsets.all(8),
                      child: VehicleConditionDiagram(
                        entries: entries,
                        onImageTap: null,
                        checkoutMarkerIds: checkoutMarkerIds,
                        fadeNonCheckoutMarkers: fadeNonCheckoutMarkers,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _AddNewIssueButton(onPressed: onAddIssue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedAtCheckInChip extends StatelessWidget {
  const _SignedAtCheckInChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBF7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGreen),
        ),
        child: Text(
          'Signed at check-in ✓',
          style: CheckOutUiTokens.body().copyWith(color: _kGreen),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _kOrange),
      ),
      child: Text(
        '$timeLabel · $count items',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _kOrange,
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
      padding: CheckOutUiTokens.cardPaddingDense,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.label, style: CheckOutUiTokens.body()),
                Text(zone, style: CheckOutUiTokens.helper()),
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
      padding: CheckOutUiTokens.cardPaddingDense,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.label, style: CheckOutUiTokens.body()),
                Text(zone, style: CheckOutUiTokens.helper()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
      padding: CheckOutUiTokens.cardPaddingDense,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRed),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: _kRed,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: CheckOutUiTokens.body().copyWith(color: _kRed),
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRed),
          ),
          child: Text(
            'Add new Issue +',
            style: CheckOutUiTokens.body().copyWith(
              color: _kRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
