import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_text_field.dart';
import '../state/auth_bloc.dart';

/// Figma node `30:401` — Valet Parking login (dev mode colors; Poppins).
abstract final class _LoginTokens {
  static const titleOrange = Color(0xFFF68D00);
  static const subtitleGrey = Color(0xFFAEAEAE);
  static const hintGrey300 = Color(0xFF9DA4B0);
  static const offlineBg = Color(0xFFFAFAFA);
  static const footerGrey = Color(0xFFAFAFAF);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  TextStyle _poppins(
    double size,
    FontWeight w,
    Color color, {
    double height = 1.0,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.13),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 19.3,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 50,
                ),
                child: TextFieldTapRegion(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Valet Master',
                        style: _poppins(
                          35,
                          FontWeight.w700,
                          _LoginTokens.titleOrange,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SMART PARKING TECHNOLOGIES',
                        style: _poppins(
                          12,
                          FontWeight.w500,
                          _LoginTokens.subtitleGrey,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LabeledAppTextField(
                        label: 'Email Address',
                        child: AppTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'Enter Email Address',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.user,
                              size: 14,
                              color: _LoginTokens.hintGrey300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledAppTextField(
                        label: 'Password',
                        child: AppTextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          hint: '************',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.lock,
                              size: 14,
                              color: _LoginTokens.hintGrey300,
                            ),
                          ),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 14,
                              color: _LoginTokens.hintGrey300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _LoginTokens.titleOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () async {
                            // TODO: Login API must return cash session status:
                            // - open  => proceed to dashboard
                            // - closed => force open cash before dashboard
                            final cashStatus = CashSessionStatus.closed;
                            context.read<AuthBloc>().add(
                              AuthLoggedIn(cashSessionStatus: cashStatus),
                            );

                            if (!context.mounted) return;

                            if (cashStatus == CashSessionStatus.closed) {
                              context.go('/cash/open');
                            } else {
                              context.go('/dashboard');
                            }
                          },
                          child: Text(
                            'Login',
                            style: _poppins(
                              14,
                              FontWeight.w500,
                              Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _LoginTokens.offlineBg,
                            foregroundColor: _LoginTokens.titleOrange,
                            side: const BorderSide(
                              color: _LoginTokens.titleOrange,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            'Offline Mode',
                            style: _poppins(
                              14,
                              FontWeight.w500,
                              _LoginTokens.titleOrange,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'JAZZ MALL : AREA — VALET ATTENDANT',
                        textAlign: TextAlign.center,
                        style: _poppins(
                          10,
                          FontWeight.w500,
                          _LoginTokens.footerGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
