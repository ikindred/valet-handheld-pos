import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/time/philippine_time.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../check_in/presentation/widgets/check_in_vehicle_details_widgets.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../domain/checkout_pricing.dart';
import '../domain/checkout_preview_format.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../models/checkout_preview_response.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';
import 'widgets/checkout_vehicle_review_footer.dart';
import 'widgets/checkout_vehicle_review_tabs.dart';

/// Step 2 — Vehicle review · **Vehicle Info** tab
class CheckOutVehicleInfoScreen extends StatelessWidget {
  const CheckOutVehicleInfoScreen({super.key});

  static const _green = Color(0xFF27AE60);

  static String _belongingLabel(String raw) {
    final id = raw.trim();
    if (id.isEmpty) return raw;
    for (final e in CheckInBelongingsIds.entries) {
      if (e.$1 == id) return e.$2;
    }
    if (id.startsWith('Other:')) return id;
    return id;
  }

  static List<String> _belongingsFromPreview(CheckoutPreviewResponse preview) {
    return [
      for (final b in preview.belongings)
        if (b.trim().isNotEmpty) _belongingLabel(b),
    ];
  }

  static List<String> _belongingsFromDrift(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final d = jsonDecode(json);
      if (d is List) {
        return [
          for (final e in d)
            _belongingLabel(e.toString()),
        ];
      }
    } catch (_) {}
    return const [];
  }

  static String _durationSoFar(DateTime timeIn) {
    final d = PhilippineTime.now().difference(timeIn);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m mins';
    return '$h hrs $m mins';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.preview != b.preview ||
          a.isLoadingPreview != b.isLoadingPreview ||
          a.driverOut != b.driverOut,
      builder: (context, state) {
        if (state.needsScanStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }
        if (state.isReceiptStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-5');
          });
          return const SizedBox.shrink();
        }

        final preview = state.preview;
        if (preview == null) {
          if (state.isLookupBusy || state.isLoadingPreview) {
            return CheckOutStepBody(
              scrollable: true,
              footer: CheckoutVehicleReviewFooter(
                onBack: () => context.go('/check-out/step-1'),
                primaryLabel: 'Next: Proceed to payment',
                onPrimary: null,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return _OfflineVehicleBody(state: state);
        }

        return _PreviewVehicleBody(state: state, preview: preview);
      },
    );
  }
}

class _PreviewVehicleBody extends StatelessWidget {
  const _PreviewVehicleBody({
    required this.state,
    required this.preview,
  });

  final CheckOutState state;
  final CheckoutPreviewResponse preview;

  @override
  Widget build(BuildContext context) {
    final row = state.ticket!;
    final pt = preview.ticket;
    final rs = preview.releaseSummary;

    final nameDisplay = rs.customer.trim().isEmpty ? '—' : rs.customer.trim();
    final contact = (preview.customerContact ?? '').trim().isEmpty
        ? '—'
        : preview.customerContact!.trim();

    final timeInLabel = formatPreviewTime(row.checkInAt);
    final dateInLabel = formatPreviewDate(row.checkInAt);
    final timeOutLabel = formatPreviewTime(PhilippineTime.iso8601Now());
    final durationLabel = CheckoutReceiptSnapshot.durationLabelFromMinutes(
      CheckoutPricing.pricingWindow(checkInRaw: row.checkInAt).durationMinutes,
    );

    final plateDisplay = pt.plate.isNotEmpty ? pt.plate : rs.plate;
    final makeModel = pt.vehicleMake.trim().isEmpty ? '—' : pt.vehicleMake.trim();
    final colorDisplay = pt.vehicleColor.trim().isEmpty ? '—' : pt.vehicleColor.trim();
    final typeDisplay = pt.vehicleType.trim().isEmpty ? '—' : pt.vehicleType.trim();
    final parkingLabel = pt.parkingLocationLine.trim().isEmpty
        ? '—'
        : pt.parkingLocationLine.trim();
    final vrRaw = row.vrNo?.trim() ?? '';
    final vrNo = vrRaw.isEmpty ? '—' : vrRaw;

    final valetIn = (pt.valetIn ?? '').trim().isEmpty ? '—' : pt.valetIn!.trim();
    final valetOutPrefill = pt.valetOut ?? state.driverOut;
    final valetOut =
        (valetOutPrefill ?? '').trim().isEmpty ? '—' : valetOutPrefill!.trim();

    final belongings = CheckOutVehicleInfoScreen._belongingsFromPreview(preview);

    final tabs = CheckoutVehicleReviewTabs(
      vehicleInfoSelected: true,
      onVehicleInfoTap: null,
      onConditionTap: () => context.go('/check-out/step-3'),
    );

    return CheckOutStepBody(
      scrollable: true,
      footer: CheckoutVehicleReviewFooter(
        onBack: () => context.go('/check-out/step-1'),
        primaryLabel: 'Next: Proceed to payment',
        onPrimary: () => context.go('/check-out/step-3'),
      ),
      child: _VehicleInfoLayout(
        tabs: tabs,
        customerCard: _CustomerCard(
          name: nameDisplay,
          contact: contact,
        ),
        timeInCard: _TimeCard(
          title: 'CHECK IN',
          primary: timeInLabel,
          secondary: dateInLabel,
          primaryColor: const Color(0xFF0A1B39),
          secondaryColor: const Color(0xFF0A1B39),
        ),
        timeOutCard: _TimeCard(
          title: 'CHECK OUT',
          primary: timeOutLabel,
          secondary: durationLabel,
          primaryColor: DashboardStyles.orange,
          secondaryColor: CheckOutVehicleInfoScreen._green,
        ),
        vehicleCard: _VehicleCard(
          plate: plateDisplay.isEmpty ? '—' : plateDisplay,
          vrNo: vrNo,
          makeModel: makeModel.isEmpty ? '—' : makeModel,
          color: colorDisplay,
          type: typeDisplay,
          slot: parkingLabel,
        ),
        staffCard: _StaffCard(valetIn: valetIn, valetOut: valetOut),
        belongingsCard: _BelongingsCard(belongings: belongings),
      ),
    );
  }
}

/// Offline checkout: no preview payload — show Drift ticket data.
class _OfflineVehicleBody extends StatelessWidget {
  const _OfflineVehicleBody({required this.state});

  final CheckOutState state;

  @override
  Widget build(BuildContext context) {
    final row = state.ticket!;
    final timeIn = PhilippineTime.fromApiIso(row.checkInAt);
    final belongings = CheckOutVehicleInfoScreen._belongingsFromDrift(
      row.personalBelongings,
    );
    final vrRaw = row.vrNo?.trim() ?? '';
    final vrNo = vrRaw.isEmpty ? '—' : vrRaw;

    final tabs = CheckoutVehicleReviewTabs(
      vehicleInfoSelected: true,
      onVehicleInfoTap: null,
      onConditionTap: () => context.go('/check-out/step-3'),
    );

    return CheckOutStepBody(
      scrollable: true,
      footer: CheckoutVehicleReviewFooter(
        onBack: () => context.go('/check-out/step-1'),
        primaryLabel: 'Next: Proceed to payment',
        onPrimary: () => context.go('/check-out/step-3'),
      ),
      child: _VehicleInfoLayout(
        tabs: tabs,
        customerCard: const _CustomerCard(name: '—', contact: '—'),
        timeInCard: _TimeCard(
          title: 'CHECK IN',
          primary: formatPreviewTime(row.checkInAt),
          secondary: formatPreviewDate(row.checkInAt),
          primaryColor: const Color(0xFF0A1B39),
          secondaryColor: const Color(0xFF0A1B39),
        ),
        timeOutCard: _TimeCard(
          title: 'CHECK OUT',
          primary: formatPreviewTime(PhilippineTime.iso8601Now()),
          secondary: CheckOutVehicleInfoScreen._durationSoFar(timeIn),
          primaryColor: DashboardStyles.orange,
          secondaryColor: CheckOutVehicleInfoScreen._green,
        ),
        vehicleCard: _VehicleCard(
          plate: row.plateNumber.isEmpty ? '—' : row.plateNumber,
          vrNo: vrNo,
          makeModel: [
            row.vehicleBrand.trim(),
            row.vehicleColor.trim(),
          ].where((s) => s.isNotEmpty).join(' '),
          color: row.vehicleColor.isEmpty ? '—' : row.vehicleColor,
          type: row.vehicleType.isEmpty ? '—' : row.vehicleType,
          slot: '—',
        ),
        staffCard: _StaffCard(
          valetIn: (row.driverIn ?? '').trim().isEmpty ? '—' : row.driverIn!,
          valetOut: (state.driverOut ?? '').trim().isEmpty
              ? '—'
              : state.driverOut!.trim(),
        ),
        belongingsCard: _BelongingsCard(belongings: belongings),
      ),
    );
  }
}

class _VehicleInfoLayout extends StatelessWidget {
  const _VehicleInfoLayout({
    required this.tabs,
    required this.customerCard,
    required this.timeInCard,
    required this.timeOutCard,
    required this.vehicleCard,
    required this.staffCard,
    required this.belongingsCard,
  });

  final Widget tabs;
  final Widget customerCard;
  final Widget timeInCard;
  final Widget timeOutCard;
  final Widget vehicleCard;
  final Widget staffCard;
  final Widget belongingsCard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabs,
              const SizedBox(height: CheckInCompactTokens.blockGap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: customerCard),
                    const SizedBox(width: 16),
                    Expanded(child: timeInCard),
                    const SizedBox(width: 16),
                    Expanded(child: timeOutCard),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: vehicleCard),
                    const SizedBox(width: 16),
                    Expanded(child: staffCard),
                    const SizedBox(width: 16),
                    Expanded(child: belongingsCard),
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
            const SizedBox(height: 16),
            customerCard,
            const SizedBox(height: 12),
            timeInCard,
            const SizedBox(height: 12),
            timeOutCard,
            const SizedBox(height: 12),
            vehicleCard,
            const SizedBox(height: 12),
            staffCard,
            const SizedBox(height: 12),
            belongingsCard,
          ],
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.name, required this.contact});

  final String name;
  final String contact;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CUSTOMER', style: CheckOutUiTokens.sectionTitleOf(context)),
          const SizedBox(height: 8),
          Text(name, style: CheckOutUiTokens.timeDisplayOf(context)),
          const SizedBox(height: 4),
          Text(contact, style: CheckOutUiTokens.bodyOf(context)),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String title;
  final String primary;
  final String secondary;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CheckOutUiTokens.sectionTitleOf(context)),
          const SizedBox(height: 6),
          Text(
            primary,
            style: CheckOutUiTokens.timeDisplay(color: primaryColor),
          ),
          Text(
            secondary,
            style: CheckOutUiTokens.bodyOf(context).copyWith(
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.plate,
    required this.vrNo,
    required this.makeModel,
    required this.color,
    required this.type,
    required this.slot,
  });

  final String plate;
  final String vrNo;
  final String makeModel;
  final String color;
  final String type;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEHICLE', style: CheckOutUiTokens.sectionTitleOf(context)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: CheckOutUiTokens.plateBarBgOf(context),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                plate,
                style: CheckOutUiTokens.plate().copyWith(
                  color: CheckOutUiTokens.plateBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('VR No.', style: CheckOutUiTokens.fieldLabelOf(context)),
          Text(vrNo, style: CheckOutUiTokens.bodyOf(context)),
          const SizedBox(height: 6),
          Text('Make / Model', style: CheckOutUiTokens.fieldLabelOf(context)),
          Text(makeModel, style: CheckOutUiTokens.bodyOf(context)),
          const SizedBox(height: 6),
          Text('Color', style: CheckOutUiTokens.fieldLabelOf(context)),
          Text(color, style: CheckOutUiTokens.bodyOf(context)),
          const SizedBox(height: 6),
          Text('Type', style: CheckOutUiTokens.fieldLabelOf(context)),
          Text(type, style: CheckOutUiTokens.bodyOf(context)),
          const SizedBox(height: 10),
          _OrangeChip(text: slot),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.valetIn, required this.valetOut});

  final String valetIn;
  final String valetOut;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STAFF', style: CheckOutUiTokens.sectionTitleOf(context)),
          const SizedBox(height: 10),
          _StaffRow(label: 'Valet In', name: valetIn),
          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 1,
            color: CheckOutUiTokens.hairlineOf(context),
          ),
          const SizedBox(height: 6),
          _StaffRow(label: 'Returning Valet Attendant', name: valetOut),
        ],
      ),
    );
  }
}

class _BelongingsCard extends StatelessWidget {
  const _BelongingsCard({required this.belongings});

  final List<String> belongings;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DECLARED BELONGINGS',
            style: CheckOutUiTokens.sectionTitleOf(context),
          ),
          const SizedBox(height: 10),
          if (belongings.isEmpty)
            Text('None declared', style: CheckOutUiTokens.hintOf(context))
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
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CheckOutUiTokens.cardBgOf(context),
        borderRadius: BorderRadius.circular(CheckOutUiTokens.cardRadius),
        border: Border.all(color: CheckOutUiTokens.cardBorderOf(context)),
      ),
      padding: CheckOutUiTokens.cardPadding,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CheckOutUiTokens.chipFillOf(context),
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
          child: Text(label, style: CheckOutUiTokens.fieldLabelOf(context)),
        ),
        Expanded(
          child: Text(
            name,
            textAlign: TextAlign.right,
            style: CheckOutUiTokens.bodyOf(context),
          ),
        ),
      ],
    );
  }
}
