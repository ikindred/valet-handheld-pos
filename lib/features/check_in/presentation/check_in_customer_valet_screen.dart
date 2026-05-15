import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/app_text_field.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_compact_tokens.dart';
import 'widgets/check_in_footer_actions.dart';
import 'widgets/check_in_form_fields.dart';
import 'widgets/check_in_valet_type_cards.dart';

/// Step 1 — Customer and valet details
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-1467)).
///
/// Two-column grid (landscape):
/// | Customer information | Valet assignment |
/// | Full name            | Assigned driver  |
/// | Contact number       | Date & time      |
/// | Valet type           | Special request  |
class CheckInCustomerValetScreen extends StatefulWidget {
  const CheckInCustomerValetScreen({super.key});

  @override
  State<CheckInCustomerValetScreen> createState() =>
      _CheckInCustomerValetScreenState();
}

class _CheckInCustomerValetScreenState
    extends State<CheckInCustomerValetScreen> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _valetCtrl;
  late final TextEditingController _instructionsCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<CheckInCubit>().state;
    _fullNameCtrl = TextEditingController(text: s.customerFullName);
    _contactCtrl = TextEditingController(text: s.contactNumber);
    _valetCtrl = TextEditingController(text: s.assignedValetDriver);
    _instructionsCtrl = TextEditingController(text: s.specialInstructions);
    if (s.dateTimeIn == null) {
      context.read<CheckInCubit>().updateCustomerStep(
        dateTimeIn: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _contactCtrl.dispose();
    _valetCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? d) {
    final dt = d ?? DateTime.now();
    return DateFormat('MMMM d, yyyy — h:mm a').format(dt);
  }

  void _onNext() {
    context.read<CheckInCubit>().updateCustomerStep(
      customerFullName: _fullNameCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      assignedValetDriver: _valetCtrl.text.trim(),
      specialInstructions: _instructionsCtrl.text.trim(),
    );
    context.go('/check-in/step-2');
  }

  void _onCancel() {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  Widget _dateTimeField() {
    return CheckInFormField(
      label: 'DATE & TIME IN',
      child: BlocBuilder<CheckInCubit, CheckInState>(
        buildWhen: (a, b) => a.dateTimeIn != b.dateTimeIn,
        builder: (context, state) {
          return _DateTimeReadOnly(text: _formatDateTime(state.dateTimeIn));
        },
      ),
    );
  }

  Widget _specialRequestField() {
    return CheckInFormField(
      label: 'SPECIAL REQUEST (OPTIONAL)',
      child: CheckInTextField(
        controller: _instructionsCtrl,
        maxLines: 3,
        minHeight: 64,
        hint: 'e.g fragile items inside, handle with care...',
      ),
    );
  }

  /// Left column: customer block + valet type cards.
  Widget _columnCustomerAndValetType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'CUSTOMER INFORMATION'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        CheckInFormField(
          label: 'FULL NAME',
          child: CheckInTextField(
            controller: _fullNameCtrl,
            hint: 'Juan dela Cruz',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        CheckInFormField(
          label: 'CONTACT NUMBER',
          child: CheckInTextField(
            controller: _contactCtrl,
            keyboardType: TextInputType.phone,
            hint: '09171234567',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        Text('VALET TYPE', style: CheckInCompactTokens.inlineLabel()),
        const SizedBox(height: 6),
        const CheckInValetTypeCards(),
      ],
    );
  }

  /// Right column: valet assignment + special request.
  Widget _columnValetAssignmentAndSpecial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'VALET ASSIGNMENT'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        CheckInFormField(
          label: 'ASSIGNED VALET DRIVER',
          child: CheckInTextField(
            controller: _valetCtrl,
            hint: 'Carlos Mendoza',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _dateTimeField(),
        const SizedBox(height: 20),
        _specialRequestField(),
      ],
    );
  }

  /// Stacked layout for narrow / portrait.
  Widget _narrowBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'CUSTOMER INFORMATION'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        CheckInFormField(
          label: 'FULL NAME',
          child: CheckInTextField(
            controller: _fullNameCtrl,
            hint: 'Juan dela Cruz',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        CheckInFormField(
          label: 'CONTACT NUMBER',
          child: CheckInTextField(
            controller: _contactCtrl,
            keyboardType: TextInputType.phone,
            hint: '09171234567',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        const CheckInSectionTitle(text: 'VALET ASSIGNMENT'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        CheckInFormField(
          label: 'ASSIGNED VALET DRIVER',
          child: CheckInTextField(
            controller: _valetCtrl,
            hint: 'Carlos Mendoza',
          ),
        ),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _dateTimeField(),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        Text('VALET TYPE', style: CheckInCompactTokens.inlineLabel()),
        const SizedBox(height: 6),
        const CheckInValetTypeCards(),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _specialRequestField(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CheckInCompactTokens.screenPaddingH,
        CheckInCompactTokens.screenPaddingTop,
        CheckInCompactTokens.screenPaddingH,
        CheckInCompactTokens.screenPaddingBottom,
      ),
      child: TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape =
                        MediaQuery.orientationOf(context) ==
                        Orientation.landscape;
                    final useTwoColumns =
                        isLandscape && constraints.maxWidth >= 400;

                    if (!useTwoColumns) {
                      return _narrowBody();
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _columnCustomerAndValetType()),
                        VerticalDivider(
                          width: CheckInCompactTokens.columnDividerWidth,
                          thickness: 1,
                          color: Colors.black.withValues(alpha: 0.13),
                        ),
                        Expanded(child: _columnValetAssignmentAndSpecial()),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: CheckInCompactTokens.footerGap),
            CheckInFooterActions(
              onCancel: _onCancel,
              primaryLabel: 'Next: Vehicle Details',
              onPrimary: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeReadOnly extends StatelessWidget {
  const _DateTimeReadOnly({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppReadOnlyField(
      minHeight: CheckInCompactTokens.inputMinHeight,
      padding: CheckInCompactTokens.inputPadding,
      child: Text(text, style: CheckInCompactTokens.dateTimeAccent()),
    );
  }
}
