import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Tier 2 offline / server-error banner (Reports **Transactions** tab, Cash **Transactions** tab).
abstract final class OfflineDataBannerTokens {
  static const Color background = Color(0xFFFFF5DE);
  static const Color foreground = Color(0xFFE8831A);
}

/// Thin banner: offline vs server fetch error (mutually styled; may stack if both apply).
class OfflineDataBanner extends StatelessWidget {
  const OfflineDataBanner({
    super.key,
    this.isOffline = false,
    this.serverError,
  });

  final bool isOffline;

  /// When non-null and non-empty, shows the server / historical fetch error line.
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    final errText = serverError?.trim();
    if (!isOffline && (errText == null || errText.isEmpty)) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    if (isOffline) {
      children.add(
        _BannerLine(
          icon: LucideIcons.wifiOff,
          text: "You're offline — showing local records only",
        ),
      );
    }
    if (errText != null && errText.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 8));
      }
      children.add(
        _BannerLine(
          icon: LucideIcons.alertTriangle,
          text: errText,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _BannerLine extends StatelessWidget {
  const _BannerLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OfflineDataBannerTokens.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OfflineDataBannerTokens.foreground.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: OfflineDataBannerTokens.foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: OfflineDataBannerTokens.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab title with optional small spinner while server historical fetch runs.
class OfflineDataTabTitle extends StatelessWidget {
  const OfflineDataTabTitle({
    super.key,
    required this.label,
    required this.showSpinner,
  });

  final String label;
  final bool showSpinner;

  static const Color _spinnerColor = Color(0xFFE8831A);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _spinnerColor,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(label),
      ],
    );
  }
}
