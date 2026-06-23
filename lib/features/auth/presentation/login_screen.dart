import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/storage/prefs_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../data/remote/api_error_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_session_sync.dart';

/// Figma node `30:401` — Valet Parking login (compact tablet layout).
abstract final class _LoginTokens {
  static const titleOrange = Color(0xFFF68D00);
  static const subtitleGrey = Color(0xFFAEAEAE);
  static const footerGrey = Color(0xFFAFAFAF);

  static const double cardMaxWidth = 440;
  static const double fieldMinHeight = 40;
  static const double buttonHeight = 40;
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
  bool _loading = false;
  String? _error;

  Future<({bool canLogin, String footerLine})>? _loginGateFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loginGateFuture ??= () {
      final repo = context.read<AuthRepository>();
      return SharedPreferences.getInstance()
          .then((prefs) => repo.loginGateFooter(prefs));
    }();
  }

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

  TextStyle _fieldLabelStyle(BuildContext context) => _poppins(
        11,
        FontWeight.w600,
        AppThemeColors.of(context).textPrimary,
        height: 1.2,
      );

  TextStyle _fieldValueStyle(BuildContext context) => _poppins(
        12,
        FontWeight.w400,
        AppThemeColors.of(context).textPrimary,
        height: 1.35,
      );

  Future<void> _onlineLogin() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final online = await InternetConnection().hasInternetAccess;
    if (!mounted) return;
    if (!online) {
      setState(() {
        _error = 'You need an internet connection for online login.';
        _loading = false;
      });
      return;
    }
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final serverDeviceId = prefs.getString(PrefsKeys.deviceIdentityKey);
    try {
      final rates = await repo.loginOnline(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        serverDeviceId: serverDeviceId,
      );
      await OfflineModePrefs.write(prefs, false);
      final session = await repo.getActiveSession();
      if (session == null || !mounted) return;
      await syncAuthBlocAndNavigate(
        context,
        repo: repo,
        localUserId: session.userId,
        email: _emailCtrl.text.trim(),
        standardRates: rates,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = loginErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _offlineLogin() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      await repo.loginOffline(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await OfflineModePrefs.write(prefs, true);
      final session = await repo.getActiveSession();
      if (session == null || !mounted) return;
      await syncAuthBlocAndNavigate(
        context,
        repo: repo,
        localUserId: session.userId,
        email: _emailCtrl.text.trim(),
        standardRates: null,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.message == 'DEVICE_NOT_ASSIGNED') {
          _error =
              'This device is not yet assigned to a branch and area.';
        } else if (e.message == 'OFFLINE_ACCOUNT_MISSING') {
          _error = 'Sign in online at least once before using offline mode.';
        } else if (e.message == 'BAD_PASSWORD') {
          _error = 'Incorrect password.';
        } else {
          _error = 'Offline login failed.';
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Offline login failed.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isDark = AppThemeColors.isDark(context);
    final iconMuted = tc.textSubtitleMuted;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 520;
              final hPad = compact ? 20.0 : 28.0;
              final vPad = compact ? 18.0 : 28.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _LoginTokens.cardMaxWidth,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tc.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tc.cardBorder,
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? const []
                              : const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: vPad,
                          ),
                          child: TextFieldTapRegion(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                      Text(
                        'Valet Master',
                        style: _poppins(
                          26,
                          FontWeight.w700,
                          _LoginTokens.titleOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SMART PARKING TECHNOLOGIES',
                        style: _poppins(
                          10,
                          FontWeight.w500,
                          _LoginTokens.subtitleGrey,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 22),
                      LabeledAppTextField(
                        label: 'Email Address',
                        labelStyle: _fieldLabelStyle(context),
                        gap: 3,
                        child: AppTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          minHeight: _LoginTokens.fieldMinHeight,
                          hint: 'Enter Email Address',
                          style: _fieldValueStyle(context),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.user,
                              size: 12,
                              color: iconMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LabeledAppTextField(
                        label: 'Password',
                        labelStyle: _fieldLabelStyle(context),
                        gap: 3,
                        child: AppTextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          minHeight: _LoginTokens.fieldMinHeight,
                          hint: '************',
                          style: _fieldValueStyle(context),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.lock,
                              size: 12,
                              color: iconMuted,
                            ),
                          ),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 12,
                              color: iconMuted,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3D1A1A)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF7F1D1D)
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: _poppins(
                              11,
                              FontWeight.w500,
                              isDark
                                  ? const Color(0xFFFCA5A5)
                                  : Colors.red.shade800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FutureBuilder<({bool canLogin, String footerLine})>(
                        future: _loginGateFuture,
                        builder: (context, snap) {
                          final done =
                              snap.connectionState == ConnectionState.done;
                          final canLogin = snap.data?.canLogin ?? false;
                          final loginEnabled = done && canLogin && !_loading;
                          final footer = snap.data?.footerLine ??
                              (done
                                  ? 'This device is not yet assigned to a branch and area.'
                                  : 'Loading site…');
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: _LoginTokens.buttonHeight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _LoginTokens.titleOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: loginEnabled ? _onlineLogin : null,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style: _poppins(
                                            13,
                                            FontWeight.w600,
                                            Colors.white,
                                            height: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: _LoginTokens.buttonHeight,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: tc.cardBg,
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
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed:
                                      loginEnabled ? _offlineLogin : null,
                                  child: Text(
                                    'Offline Mode',
                                    style: _poppins(
                                      13,
                                      FontWeight.w600,
                                      _LoginTokens.titleOrange,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                footer,
                                textAlign: TextAlign.center,
                                style: _poppins(
                                  9,
                                  FontWeight.w500,
                                  _LoginTokens.footerGrey,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          );
                        },
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
            },
          ),
        ),
      ),
    );
  }
}
