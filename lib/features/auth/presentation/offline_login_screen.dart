import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_session_sync.dart';

/// Password gate when an active session exists but the device is offline.
class OfflineLoginScreen extends StatefulWidget {
  const OfflineLoginScreen({super.key});

  @override
  State<OfflineLoginScreen> createState() => _OfflineLoginScreenState();
}

class _OfflineLoginScreenState extends State<OfflineLoginScreen> {
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _email;
  String? _error;
  /// `null` until [AuthRepository.isDeviceSiteConfigured] is resolved.
  bool? _siteReady;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final repo = context.read<AuthRepository>();
    final session = await repo.getActiveSession();
    if (session == null) {
      if (mounted) context.go('/login');
      return;
    }
    final acct = await repo.offlineAccountById(session.userId);
    if (acct == null) {
      if (mounted) context.go('/login');
      return;
    }
    final ready = await repo.isDeviceSiteConfigured();
    if (!mounted) return;
    setState(() {
      _email = acct.email;
      _siteReady = ready;
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
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

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      await repo.verifyPasswordForActiveOfflineSession(_passwordCtrl.text);
      await OfflineModePrefs.write(prefs, true);
      final session = await repo.getActiveSession();
      if (session == null || !mounted) return;
      final email = await repo.emailForOfflineAccountId(session.userId);
      if (!mounted) return;
      await syncAuthBlocAndNavigate(
        context,
        repo: repo,
        localUserId: session.userId,
        email: email,
        standardRates: null,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.message == 'DEVICE_NOT_ASSIGNED') {
          _error =
              'This device is not yet assigned to a branch and area.';
        } else if (e.message == 'BAD_PASSWORD') {
          _error = 'Incorrect password.';
        } else {
          _error = 'Unable to sign in offline.';
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('BAD_PASSWORD')
              ? 'Incorrect password.'
              : 'Unable to sign in offline.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleOrange = Color(0xFFF68D00);
    const hintGrey = Color(0xFF9DA4B0);

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
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Offline sign-in',
                    style: _poppins(28, FontWeight.w700, titleOrange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your password to continue without an internet connection.',
                    style: _poppins(13, FontWeight.w400, const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 28),
                  if (_email != null)
                    LabeledAppTextField(
                      label: 'Email',
                      child: AppReadOnlyField(
                        minHeight: 40,
                        child: Text(
                          _email!,
                          style: _poppins(14, FontWeight.w500, Colors.black87),
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
                          color: hintGrey,
                        ),
                      ),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 14,
                          color: hintGrey,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: _poppins(12, FontWeight.w500, Colors.red.shade700),
                    ),
                  ],
                  if (_siteReady == false) ...[
                    const SizedBox(height: 12),
                    Text(
                      'This device is not yet assigned to a branch and area.',
                      textAlign: TextAlign.center,
                      style: _poppins(
                        11,
                        FontWeight.w500,
                        const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _loading || _siteReady != true
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: titleOrange,
                        foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Continue',
                              style: _poppins(
                                14,
                                FontWeight.w500,
                                Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
