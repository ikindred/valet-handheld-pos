import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the last successful login email/password for silent online upgrade
/// after an offline session (device keystore / Keychain).
abstract final class LoginCredentialStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _emailKey = 'valet_login_email';
  static const _passwordKey = 'valet_login_password';

  static Future<void> save({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) return;
    await _storage.write(key: _emailKey, value: normalized);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return (email: email, password: password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
