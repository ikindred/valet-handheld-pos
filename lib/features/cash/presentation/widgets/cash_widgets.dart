import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class CashLeftRail extends StatelessWidget {
  const CashLeftRail({
    super.key,
    required this.title,
    required this.subtitle,
    required this.online,
  });

  final String title;
  final String subtitle;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.13))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _LogoMark(),
            const SizedBox(height: 16),
            _OnlinePill(online: online),
            const Spacer(),
            RotatedBox(
              quarterTurns: 3,
              child: Column(
                children: [
                  Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    subtitle.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color.fromRGBO(10, 27, 57, 0.6),
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class CashAmountBox extends StatelessWidget {
  const CashAmountBox({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? const Color(0xFFF68D00);
    return Container(
      height: 74,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class CashKeypad extends StatelessWidget {
  const CashKeypad({super.key, required this.onKey});

  final void Function(String) onKey;

  @override
  Widget build(BuildContext context) {
    final keys = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['00', '0', '⌫'],
    ];

    return Column(
      children: [
        for (final row in keys) ...[
          Row(
            children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _KeyButton(label: k, onTap: () => onKey(k)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
      ),
      alignment: Alignment.center,
      child: const Text('S', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF27AE60) : AppColors.warning;
    final bg = online ? const Color(0xFFF4FBF7) : const Color(0xFFFFF7EC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(online ? 'Online' : 'Offline', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAccent = label == '00';
    final isDelete = label == '⌫';

    Color bg = const Color(0xFFF8F9FB);
    Color border = const Color(0xFFC0C0BF);
    Color fg = const Color(0xFF0A1B39);

    if (isAccent) {
      bg = const Color(0xFFFFF5DE);
      border = const Color(0xFFF68D00);
      fg = const Color(0xFFF68D00);
    }
    if (isDelete) {
      bg = Colors.white;
      border = const Color(0xFFC0C0BF);
      fg = const Color(0xFFD64045);
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg)),
      ),
    );
  }
}

