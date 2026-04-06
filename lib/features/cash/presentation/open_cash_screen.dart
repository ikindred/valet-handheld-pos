import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/state/auth_bloc.dart';
import 'widgets/cash_figma_text_styles.dart';
import 'widgets/cash_widgets.dart';

class OpenCashScreen extends StatefulWidget {
  const OpenCashScreen({super.key});

  @override
  State<OpenCashScreen> createState() => _OpenCashScreenState();
}

class _OpenCashScreenState extends State<OpenCashScreen> {
  final _notesCtrl = TextEditingController();

  /// Whole peso digits only (no decimal point). "0" means zero pesos.
  String _digits = '0';

  static final _pesoFmt = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  static const int _maxDigitChars = 12;

  void _tapKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_digits.length <= 1) {
          _digits = '0';
        } else {
          _digits = _digits.substring(0, _digits.length - 1);
        }
        return;
      }
      if (key == '00') {
        if (_digits == '0') return;
        _appendDigits('00');
        return;
      }
      if (key == '0') {
        if (_digits == '0') return;
        _appendDigits('0');
        return;
      }
      // 1–9
      if (_digits == '0') {
        _digits = key;
      } else {
        _appendDigits(key);
      }
    });
  }

  void _appendDigits(String chunk) {
    if (_digits.length + chunk.length > _maxDigitChars) return;
    _digits += chunk;
  }

  String get _displayAmount {
    final n = int.tryParse(_digits) ?? 0;
    return _pesoFmt.format(n);
  }

  @override
  Widget build(BuildContext context) {
    final nowLabel = 'Tuesday, March 25, 2026 · Jazz Mall';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          const CashLeftRail(),
          Expanded(
            child: SafeArea(
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CashPageHeader(
                    title: 'Open Cash',
                    subtitle: nowLabel,
                    online: true,
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SHIFT INFORMATION',
                                  style: CashFigmaStyles.sectionCaps(),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _ReadOnlyField(
                                        label: 'CASHIER / STAFF',
                                        value: 'Carlos Mendoza',
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _ReadOnlyField(
                                        label: 'SHIFT DATE',
                                        value: 'March 25, 2026',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _ReadOnlyField(
                                        label: 'BRANCH',
                                        value: 'Jazz Mall',
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _ReadOnlyField(
                                        label: 'AREA',
                                        value: 'Jazz Mall',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'OPENING BALANCE',
                                  style: CashFigmaStyles.sectionCaps(),
                                ),
                                const SizedBox(height: 10),
                                CashAmountBox(text: _displayAmount),
                                const SizedBox(height: 12),
                                CashKeypad(onKey: _tapKey),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 1,
                              color: Colors.black.withValues(alpha: 0.13),
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: TextFieldTapRegion(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _SummaryCard(
                                      title: 'TOTAL OPENING BALANCE',
                                      bigValue: _displayAmount,
                                      subtitle: 'Counted & Verified by staff',
                                    ),
                                    const SizedBox(height: 16),
                                    _NotesCard(controller: _notesCtrl),
                                    const SizedBox(height: 16),
                                    _ShiftSummaryCard(
                                      staff: 'Carlos Mendoza',
                                      date: 'March 25, 2026',
                                      time: '07:00 AM',
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          textStyle:
                                              CashFigmaStyles.filledActionLabel(),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          // TODO: Persist open cash to backend + local DB, then mark cash session open.
                                          context.read<AuthBloc>().add(
                                            const AuthCashSessionUpdated(
                                              CashSessionStatus.open,
                                            ),
                                          );
                                          context.go('/dashboard');
                                        },
                                        child: const Text(
                                          'Open Cash and Start Shift',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CashFigmaStyles.fieldLabel()),
        const SizedBox(height: 6),
        Container(
          height: 40,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE7E8EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(value, style: CashFigmaStyles.fieldValue()),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.bigValue,
    required this.subtitle,
  });

  final String title;
  final String bigValue;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: CashFigmaStyles.totalCardLabel()),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bigValue,
              textAlign: TextAlign.center,
              style: CashFigmaStyles.totalCardAmount(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: CashFigmaStyles.totalCardLabel(),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES (OPTIONAL)', style: CashFigmaStyles.notesSectionLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            style: CashFigmaStyles.notesInput(),
            decoration: InputDecoration(
              hintText: 'e.g. received balance from supervisor. . .',
              hintStyle: CashFigmaStyles.notesHint(),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({
    required this.staff,
    required this.date,
    required this.time,
  });

  final String staff;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: CashFigmaStyles.shiftSummaryRow(isLabel: true)),
          Text(right, style: CashFigmaStyles.shiftSummaryRow(isLabel: false)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHIFT SUMMARY', style: CashFigmaStyles.shiftSummaryTitle()),
          const SizedBox(height: 14),
          row('Staff', staff),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Date', date),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Time', time),
        ],
      ),
    );
  }
}
