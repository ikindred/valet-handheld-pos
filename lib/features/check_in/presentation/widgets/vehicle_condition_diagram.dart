import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/vehicle_damage.dart';

/// Top-down car bitmap size (must match [assetPath] pixels).
const Size kVehicleConditionImageSize = Size(1024, 469);

const String kVehicleConditionCarAsset =
    'assets/images/vehicle_condition_car_top.png';

/// Interactive diagram: tap maps to normalized \[0,1\] x/y; markers overlay entries.
class VehicleConditionDiagram extends StatelessWidget {
  const VehicleConditionDiagram({
    super.key,
    required this.entries,
    this.onImageTap,
    this.checkoutMarkerIds,
    this.fadeNonCheckoutMarkers = false,
  });

  final List<VehicleDamageEntry> entries;
  final void Function(double nx, double ny)? onImageTap;

  /// When [fadeNonCheckoutMarkers] is true, markers whose ids are not in this set use a neutral style.
  final Set<String>? checkoutMarkerIds;
  final bool fadeNonCheckoutMarkers;

  static Rect _destRectForContain(Size imageSize, Size box) {
    final scale = math.min(
      box.width / imageSize.width,
      box.height / imageSize.height,
    );
    final w = imageSize.width * scale;
    final h = imageSize.height * scale;
    final left = (box.width - w) / 2;
    final top = (box.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  static (double, double)? _localToNormalized(Offset local, Rect dest) {
    if (!dest.contains(local)) return null;
    final rel = local - dest.topLeft;
    final nx = (rel.dx / dest.width).clamp(0.0, 1.0);
    final ny = (rel.dy / dest.height).clamp(0.0, 1.0);
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(
          constraints.maxWidth.clamp(0.0, double.infinity),
          constraints.maxHeight.clamp(0.0, double.infinity),
        );
        final dest = _destRectForContain(kVehicleConditionImageSize, box);

        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: dest.left,
              top: dest.top,
              width: dest.width,
              height: dest.height,
              child: Image.asset(
                kVehicleConditionCarAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            for (final e in entries)
              Positioned(
                left: dest.left + e.normalizedX * dest.width - 13,
                top: dest.top + e.normalizedY * dest.height - 13,
                child: _DamageMarker(
                  type: e.type,
                  muted: fadeNonCheckoutMarkers &&
                      (checkoutMarkerIds == null ||
                          !checkoutMarkerIds!.contains(e.id)),
                ),
              ),
          ],
        );

        if (onImageTap == null) {
          return stack;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final n = _localToNormalized(d.localPosition, dest);
            if (n != null) onImageTap!(n.$1, n.$2);
          },
          child: stack,
        );
      },
    );
  }
}

class _DamageMarker extends StatelessWidget {
  const _DamageMarker({
    required this.type,
    required this.muted,
  });

  final DamageType type;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final border = muted ? const Color(0xFF6C7688) : _diagramMarkerColor(type);
    final fill = muted ? const Color(0xFFEFEFEF) : _diagramMarkerFill(type);

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        type.badgeLetter,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: border,
        ),
      ),
    );
  }
}

Color _diagramMarkerColor(DamageType t) {
  switch (t) {
    case DamageType.crack:
      return const Color(0xFF0068D3);
    case DamageType.scratch:
      return const Color(0xFFF68D00);
    case DamageType.dent:
      return const Color(0xFFEC2231);
  }
}

Color _diagramMarkerFill(DamageType t) {
  switch (t) {
    case DamageType.crack:
      return const Color(0xFFECEEFF);
    case DamageType.scratch:
      return const Color(0xFFFFF4EC);
    case DamageType.dent:
      return const Color(0xFFFFECEC);
  }
}
