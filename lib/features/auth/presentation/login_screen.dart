import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/device_id_service.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_session_sync.dart';

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
    final deviceId = await DeviceIdService.getOrCreate();
    try {
      final rates = await repo.loginOnline(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        deviceId: deviceId,
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
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'DEVICE_NOT_ASSIGNED') {
        setState(() {
          _error =
              'This device is not yet assigned to a branch and area.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _error = 'Login failed. Check your credentials and try again.';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Login failed. Check your credentials and try again.';
          _loading = false;
        });
      }
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
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: _poppins(
                            12,
                            FontWeight.w500,
                            Colors.red.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
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
                                  onPressed: loginEnabled ? _onlineLogin : null,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
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
                              const SizedBox(height: 8),
                              Text(
                                'Online login checks the server. Local / dev accounts (e.g. seeded offline) — use Offline Mode.',
                                textAlign: TextAlign.center,
                                style: _poppins(
                                  10,
                                  FontWeight.w400,
                                  _LoginTokens.footerGrey,
                                  height: 1.35,
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
                                  onPressed:
                                      loginEnabled ? _offlineLogin : null,
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
                                footer,
                                textAlign: TextAlign.center,
                                style: _poppins(
                                  10,
                                  FontWeight.w500,
                                  _LoginTokens.footerGrey,
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
  }
}
