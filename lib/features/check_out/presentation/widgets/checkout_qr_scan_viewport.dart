import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/platform/camera_preview_orientation.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';

/// Figma scan frame — fixed square viewport with orange corner brackets.
class CheckoutQrScanViewport extends StatelessWidget {
  const CheckoutQrScanViewport({
    super.key,
    required this.size,
    required this.scannerReady,
    required this.controller,
    required this.onDetect,
  });

  final double size;
  final bool scannerReady;
  final MobileScannerController? controller;
  final void Function(BarcodeCapture) onDetect;

  static const Color _border = Color(0xFFC0C0BF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black.withValues(alpha: 0.04)),
              if (scannerReady && controller != null)
                ListenableBuilder(
                  listenable: controller!,
                  builder: (context, _) {
                    final state = controller!.value;
                    final turns = cameraPreviewQuarterTurns(
                      context,
                      cameraBufferSize:
                          state.isInitialized ? state.size : null,
                    );
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return _OrientedCameraPreview(
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                          quarterTurns: turns,
                          controller: controller!,
                          onDetect: onDetect,
                        );
                      },
                    );
                  },
                )
              else
                const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              const _QrScanFrameOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fills the square viewport; rotates preview to match device landscape.
class _OrientedCameraPreview extends StatelessWidget {
  const _OrientedCameraPreview({
    required this.maxWidth,
    required this.maxHeight,
    required this.quarterTurns,
    required this.controller,
    required this.onDetect,
  });

  final double maxWidth;
  final double maxHeight;
  final int quarterTurns;
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    final scanner = MobileScanner(
      controller: controller,
      onDetect: onDetect,
      fit: BoxFit.cover,
    );

    if (quarterTurns == 0) {
      return SizedBox(width: maxWidth, height: maxHeight, child: scanner);
    }

    final swapped = quarterTurns.isOdd;
    final childW = swapped ? maxHeight : maxWidth;
    final childH = swapped ? maxWidth : maxHeight;

    return ClipRect(
      child: OverflowBox(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: SizedBox(
            width: childW,
            height: childH,
            child: scanner,
          ),
        ),
      ),
    );
  }
}

class _QrScanFrameOverlay extends StatelessWidget {
  const _QrScanFrameOverlay();

  static const Color _orange = DashboardStyles.orange;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _CornerBracketPainter(color: _orange)),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 2,
              width: 120,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({required this.color});

  final Color color;
  static const _stroke = 3.0;
  static const _arm = 28.0;
  static const _inset = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset origin, {required bool top, required bool left}) {
      final dx = left ? 1.0 : -1.0;
      final dy = top ? 1.0 : -1.0;
      final o = origin;
      canvas.drawLine(o, o + Offset(_arm * dx, 0), paint);
      canvas.drawLine(o, o + Offset(0, _arm * dy), paint);
    }

    corner(Offset(_inset, _inset), top: true, left: true);
    corner(Offset(size.width - _inset, _inset), top: true, left: false);
    corner(Offset(_inset, size.height - _inset), top: false, left: true);
    corner(
      Offset(size.width - _inset, size.height - _inset),
      top: false,
      left: false,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
