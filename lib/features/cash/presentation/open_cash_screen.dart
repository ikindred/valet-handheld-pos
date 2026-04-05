import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_bloc.dart';
import 'widgets/cash_widgets.dart';

class OpenCashScreen extends StatefulWidget {
  const OpenCashScreen({super.key});

  @override
  State<OpenCashScreen> createState() => _OpenCashScreenState();
}

class _OpenCashScreenState extends State<OpenCashScreen> {
  final _notesCtrl = TextEditingController();
  String _amountText = '2000.00';

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _tapKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
        if (_amountText.isEmpty) _amountText = '0';
        return;
      }
      if (key == '00') {
        _amountText = (_amountText == '0') ? '00' : '$_amountText$key';
        return;
      }
      if (_amountText == '0') {
        _amountText = key;
      } else {
        _amountText = '$_amountText$key';
      }
    });
  }

  String get _displayAmount {
    final parsed = double.tryParse(_amountText.replaceAll(',', '')) ?? 0;
    return '₱${parsed.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final nowLabel = 'Tuesday, March 25, 2026 · Jazz Mall';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          CashLeftRail(
            title: 'Open Cash',
            subtitle: nowLabel,
            online: true,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'SHIFT INFORMATION',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Expanded(child: _ReadOnlyField(label: 'CASHIER / STAFF', value: 'Carlos Mendoza')),
                            SizedBox(width: 16),
                            Expanded(child: _ReadOnlyField(label: 'SHIFT DATE', value: 'March 25, 2026')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Expanded(child: _ReadOnlyField(label: 'BRANCH', value: 'Jazz Mall')),
                            SizedBox(width: 16),
                            Expanded(child: _ReadOnlyField(label: 'AREA', value: 'Jazz Mall')),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'OPENING BALANCE',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 10),
                        CashAmountBox(text: _displayAmount),
                        const SizedBox(height: 12),
                        CashKeypad(onKey: _tapKey),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 420,
                    child: Column(
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
                            onPressed: () {
                              // TODO: Persist open cash to backend + local DB, then mark cash session open.
                              context.read<AuthBloc>().add(
                                    const AuthCashSessionUpdated(CashSessionStatus.open),
                                  );
                              context.go('/dashboard');
                            },
                            child: const Text('Open Cash and Start Shift'),
                          ),
                        ),
                      ],
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE7E8EB)),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1))],
          ),
          child: Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
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
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            bigValue,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xFFF68D00),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
          Text(
            'NOTES (OPTIONAL)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. received balance from supervisor. . .',
              filled: true,
              fillColor: Color(0xFFF8F9FB),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({required this.staff, required this.date, required this.time});

  final String staff;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          Text(right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHIFT SUMMARY', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          row('Staff', staff),
          const Divider(height: 20),
          row('Date', date),
          const Divider(height: 20),
          row('Time', time),
        ],
      ),
    );
  }
}

