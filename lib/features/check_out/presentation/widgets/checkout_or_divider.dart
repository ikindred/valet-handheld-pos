import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma-style **OR** separator — full-length rules with a centered label.
class CheckoutOrDivider extends StatelessWidget {
  const CheckoutOrDivider.vertical({super.key}) : axis = Axis.vertical;

  const CheckoutOrDivider.horizontal({super.key}) : axis = Axis.horizontal;

  final Axis axis;

  static const Color _line = Color(0xFFC0C0BF);
  static const Color _label = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return axis == Axis.vertical ? _buildVertical() : _buildHorizontal();
  }

  Widget _buildVertical() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Inside a vertical scroll view, max height is infinite — [Expanded] crashes.
          final stretch = constraints.maxHeight.isFinite;
          if (stretch) {
            return Column(
              children: [
                const Expanded(child: _Rule(axis: Axis.vertical)),
                const SizedBox(height: 14),
                _orLabel(),
                const SizedBox(height: 14),
                const Expanded(child: _Rule(axis: Axis.vertical)),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fixedVerticalRule(120),
              const SizedBox(height: 14),
              _orLabel(),
              const SizedBox(height: 14),
              _fixedVerticalRule(120),
            ],
          );
        },
      ),
    );
  }

  Widget _fixedVerticalRule(double height) {
    return Center(
      child: Container(
        width: 1,
        height: height,
        color: _line,
      ),
    );
  }

  Widget _buildHorizontal() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(child: _Rule(axis: Axis.horizontal)),
          const SizedBox(width: 14),
          _orLabel(),
          const SizedBox(width: 14),
          const Expanded(child: _Rule(axis: Axis.horizontal)),
        ],
      ),
    );
  }

  Widget _orLabel() {
    return Text(
      'OR',
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1,
        color: _label,
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.axis});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return Center(
        child: Container(
          width: 1,
          constraints: const BoxConstraints(minHeight: 48),
          color: CheckoutOrDivider._line,
        ),
      );
    }
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 1,
        constraints: const BoxConstraints(minWidth: 24),
        color: CheckoutOrDivider._line,
      ),
    );
  }
}

/// Horizontal **OR** between form fields with extra vertical breathing room.
class CheckoutFieldOrDivider extends StatelessWidget {
  const CheckoutFieldOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const CheckoutOrDivider.horizontal(),
    );
  }
}
