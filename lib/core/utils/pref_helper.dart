import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT storage, backed by the OS keystore.
///
/// Every call is guarded: secure storage talks to the Android KeyStore over a
/// platform channel and genuinely throws — most often after the app is
/// reinstalled over a build whose key is gone while its encrypted prefs remain
/// (BadPaddingException). An unguarded read there propagates out of whatever
/// awaited it, which once left the splash screen hanging forever.
///
/// A failed read therefore means "no token" (signed out), never a crash.
class PrefHelper {
  static const String _tokenKey = 'auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Jetpack Security instead of the legacy RSA-wrapped prefs, and wipe the
      // store rather than throw if it can no longer be decrypted.
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Nothing useful to do here: the session still works for this run, and
      // the student is asked to log in again next launch.
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // Unreadable store — drop it so the next launch starts clean.
      await clearToken();
      return null;
    }
  }

  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Already unreadable; nothing to remove.
    }
  }
}
