import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';

import '../../state/check_in_cubit.dart';

const _kTitleColor = Color(0xFF0A1B39);
const _kGrey500 = Color(0xFF6C7688);
const _kPadBg = Color(0xFFF2F2F2);
const _kPadBorder = Color(0xFFB8B8B8);
const _kOrange = Color(0xFFF68D00);
const _kCancelBorder = Color(0xFFC0C0BF);

/// Figma: [Customer signature modal](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=32-690&m=dev).
///
/// The dialog route sits above the check-in page, so [CheckInCubit] is re-provided
/// with `BlocProvider.value` from the caller context (see below).
Future<void> showCustomerSignatureModal(BuildContext context) {
  final cubit = context.read<CheckInCubit>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _CustomerSignatureDialog(),
    ),
  );
}

class _CustomerSignatureDialog extends StatefulWidget {
  const _CustomerSignatureDialog();

  @override
  State<_CustomerSignatureDialog> createState() =>
      _CustomerSignatureDialogState();
}

class _CustomerSignatureDialogState extends State<_CustomerSignatureDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: _kTitleColor,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onConfirm(BuildContext context) async {
    if (_controller.isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Please sign in the box before confirming.')),
      );
      return;
    }

    final bytes = await _controller.toPngBytes();
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not save signature. Try again.')),
      );
      return;
    }

    context
        .read<CheckInCubit>()
        .setCustomerSignatureCaptured(Uint8List.fromList(bytes));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxW = math.min(
      455.0,
      MediaQuery.sizeOf(context).width - 48,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CUSTOMER SIGNATURE',
                  style: GoogleFonts.poppins(
                    color: _kTitleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'I acknowledge the above vehicle condition report',
                  style: GoogleFonts.poppins(
                    color: _kGrey500,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    const h = 240.0;
                    return Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: _kPadBg,
                        border: Border.all(color: _kPadBorder),
                      ),
                      child: Signature(
                        controller: _controller,
                        width: w,
                        height: h,
                        backgroundColor: _kPadBg,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _controller.clear());
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _kGrey500,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear signature',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kGrey500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 51,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _kTitleColor,
                            side: const BorderSide(color: _kCancelBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: _kTitleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 51,
                        child: FilledButton(
                          onPressed: () => _onConfirm(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
