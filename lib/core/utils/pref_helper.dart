import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT storage, backed by the OS keystore — with an in-memory copy.
///
/// Every call is guarded: secure storage talks to the Android KeyStore over a
/// platform channel and genuinely throws — most often after the app is
/// reinstalled over a build whose key is gone while its encrypted prefs remain
/// (BadPaddingException). An unguarded read there propagates out of whatever
/// awaited it, which once left the splash screen hanging forever.
///
/// A failed read therefore means "no token" (signed out), never a crash.
///
/// IN-MEMORY COPY. The token used to be decrypted from the keystore on EVERY
/// API request (the Dio interceptor reads it) and on every "signed in?" check
/// — a platform-channel round trip plus a KeyStore decryption each time, and
/// noticeably slow on mid-range phones. It is now read from storage once per
/// app run and kept in memory; [saveToken] and [clearToken] keep the two in
/// step, so the copy can never disagree with what is stored.
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

  /// The token as last read or written. Meaningful only once [_loaded].
  static String? _token;
  static bool _loaded = false;

  /// The first read in flight, shared by callers that arrive before it
  /// finishes (home fires several requests at once on start-up).
  static Future<String?>? _firstRead;

  static Future<void> saveToken(String token) async {
    // In memory first: the session works for this run even if the write fails.
    _token = token;
    _loaded = true;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Nothing useful to do here: the session still works for this run, and
      // the student is asked to log in again next launch.
    }
  }

  static Future<String?> getToken() {
    if (_loaded) return Future.value(_token);
    return _firstRead ??= _readFromStorage();
  }

  static Future<String?> _readFromStorage() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      // A save/clear that happened while this read was in flight wins.
      if (!_loaded) {
        _token = token;
        _loaded = true;
      }
      return _token;
    } catch (_) {
      // Unreadable store — drop it so the next launch starts clean.
      await clearToken();
      return null;
    } finally {
      _firstRead = null;
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    _loaded = true;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Already unreadable; nothing to remove.
    }
  }

  /// Forgets the in-memory copy so the next read goes to storage — tests only.
  static void resetMemoryForTest() {
    _token = null;
    _loaded = false;
    _firstRead = null;
  }
}
