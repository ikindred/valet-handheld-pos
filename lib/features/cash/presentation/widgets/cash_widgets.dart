import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/logout_flow.dart';
import 'cash_figma_text_styles.dart';

/// Narrow left strip: logo only (matches [Figma Open Cash](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=61-423) rail).
class CashLeftRail extends StatelessWidget {
  const CashLeftRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.13)),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              const _LogoMark(),
              const Spacer(),
              IconButton(
                tooltip: 'Logout',
                onPressed: () => showLogoutFlow(context),
                icon: Icon(
                  Icons.logout_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title strip: `#FAFAFA`, **bottom border only** (1px `black @ 0.13`), height 96.
class CashPageHeader extends StatelessWidget {
  const CashPageHeader({
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
    return SizedBox(
      height: 68,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: Colors.black.withValues(alpha: 0.13),
            ),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title.toUpperCase(), style: CashFigmaStyles.pageTitle()),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.toUpperCase(),
                    style: CashFigmaStyles.pageSubtitle(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _OnlinePill(online: online),
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
      height: 50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          text,
          maxLines: 1,
          style: CashFigmaStyles.openingAmountInline().copyWith(color: accent),
        ),
      ),
    );
  }
}

class CashKeypad extends StatelessWidget {
  const CashKeypad({super.key, required this.onKey});

  final void Function(String) onKey;

  static const _gap = 6.0;
  static const _digitRowHeight = 40.0;
  static const _actionRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    Widget digitRow(String a, String b, String c, {double height = _digitRowHeight}) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _KeyButton(label: a, height: height, onTap: () => onKey(a)),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _KeyButton(label: b, height: height, onTap: () => onKey(b)),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _KeyButton(label: c, height: height, onTap: () => onKey(c)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        digitRow('1', '2', '3'),
        const SizedBox(height: _gap),
        digitRow('4', '5', '6'),
        const SizedBox(height: _gap),
        digitRow('7', '8', '9'),
        const SizedBox(height: _gap),
        digitRow('.', '0', '⌫', height: _actionRowHeight),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/images/spid_logo1.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            online ? 'Online' : 'Offline',
            style: CashFigmaStyles.onlinePill().copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.height = 38,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDelete = label == '⌫';

    Color bg = const Color(0xFFF8F9FB);
    Color border = const Color(0xFFC0C0BF);
    Color fg = const Color(0xFF0A1B39);

    if (isDelete) {
      bg = Colors.white;
      border = const Color(0xFFC0C0BF);
      fg = const Color(0xFFD64045);
    }

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isDelete
            ? Icon(Icons.backspace_outlined, color: fg, size: 18)
            : Text(label, style: CashFigmaStyles.keypadDigit(color: fg)),
      ),
    );
  }
}
