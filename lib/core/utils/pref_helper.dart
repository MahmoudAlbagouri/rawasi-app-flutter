import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    iOptions: IOSOptions(
      // Readable only after the first unlock since boot, and never synced to
      // iCloud or restored onto a different device.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Marker in ordinary prefs, which ARE cleared on uninstall.
  static const String _installMarkerKey = 'secure_storage_initialised';

  /// Wipes the keystore if this is the first run after a fresh install.
  ///
  /// iOS keeps Keychain items when an app is deleted, so a reinstall would
  /// otherwise start signed in as whoever used the phone before — including
  /// on a resold or handed-down device. The marker lives in plain prefs
  /// precisely because those DO go away with the app: marker missing means
  /// fresh install, so anything still in the keystore is stale and is dropped.
  ///
  /// Safe to call on every launch; it only acts once per install. Never
  /// throws — a storage fault must not stop the app from starting.
  static Future<void> clearIfFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installMarkerKey) ?? false) return;

      await _storage.deleteAll();
      _token = null;
      _loaded = true;
      await prefs.setBool(_installMarkerKey, true);
    } catch (_) {
      // Leaving the marker unset just means this runs again next launch.
    }
  }

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
