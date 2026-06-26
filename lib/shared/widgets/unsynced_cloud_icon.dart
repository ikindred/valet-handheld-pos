import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Small cloud-off marker for rows/tickets not yet synced to the server.
class UnsyncedCloudIcon extends StatelessWidget {
  const UnsyncedCloudIcon({
    super.key,
    this.size = 13,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.cloudOff,
      size: size,
      color: color ?? const Color(0xFF6C7688).withValues(alpha: 0.85),
    );
  }
}
