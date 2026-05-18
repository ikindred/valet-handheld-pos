import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Quarter-turns for [RotatedBox] so the live preview matches locked landscape UI.
///
/// POS tablets usually deliver a portrait-shaped camera buffer while the UI is
/// landscape. A 180° rotation (`quarterTurns: 2`) inverts the preview — avoid it.
int cameraPreviewQuarterTurns(
  BuildContext context, {
  Size? cameraBufferSize,
}) {
  if (MediaQuery.orientationOf(context) == Orientation.portrait) {
    return 0;
  }

  final landscapeLeft = _isLandscapeLeft(context);

  if (cameraBufferSize != null &&
      cameraBufferSize.width > 0 &&
      cameraBufferSize.height > 0) {
    final sensorPortrait = cameraBufferSize.height > cameraBufferSize.width;
    if (sensorPortrait) {
      return landscapeLeft ? 3 : 1;
    }
    return landscapeLeft ? 0 : 2;
  }

  return landscapeLeft ? 3 : 1;
}

bool _isLandscapeLeft(BuildContext context) {
  final pad = MediaQuery.viewPaddingOf(context);
  if (pad.left != pad.right) {
    return pad.left > pad.right;
  }
  return true;
}

/// Restart camera after orientation metrics change (preview matrix is set at start).
Future<void> restartMobileScanner(MobileScannerController? controller) async {
  if (controller == null) return;
  try {
    if (controller.value.isRunning) {
      await controller.stop();
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await controller.start();
  } catch (_) {}
}
