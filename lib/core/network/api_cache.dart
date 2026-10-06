// lib/core/network/api_cache.dart
//
// A short-lived, per-student memory of one API response.
//
// WHY. The bottom bar rebuilds each tab from scratch (pushReplacement), and
// almost every screen asks for the profile to decide what to show — so the
// same /profile, /analytics and /courses were fetched again on every tab
// switch, often several at once. This keeps the last answer for a short while
// and shares one in-flight request between callers that ask at the same time.
//
// SAFE BY CONSTRUCTION:
//   - keyed on the auth token, so signing in, out, or as someone else never
//     returns another student's data (the same rule HomeRepo uses);
//   - failures are never cached — the next call simply tries again;
//   - anything that changes the student's state calls [invalidate] (or
//     [invalidateAll]), and pull-to-refresh passes `force: true`.

import 'package:rawasi_app_n/core/utils/pref_helper.dart';

class ApiCache<T> {
  ApiCache(this.ttl) {
    _all.add(this);
  }

  /// How long an answer is reused.
  final Duration ttl;

  T? _value;
  String? _valueToken;
  DateTime? _loadedAt;

  Future<T>? _inFlight;
  String? _inFlightToken;

  static final List<ApiCache<dynamic>> _all = [];

  /// The cached answer when fresh and for this student, otherwise [load]'s.
  Future<T> get(Future<T> Function() load, {bool force = false}) async {
    final token = await PrefHelper.getToken();

    final loadedAt = _loadedAt;
    if (!force &&
        _value != null &&
        _valueToken == token &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < ttl) {
      return _value as T;
    }

    // Someone already asked for this student's data: wait for that answer
    // instead of sending a second identical request.
    final pending = _inFlight;
    if (!force && pending != null && _inFlightToken == token) {
      return pending;
    }

    final request = load();
    _inFlight = request;
    _inFlightToken = token;
    try {
      final value = await request;
      _value = value;
      _valueToken = token;
      _loadedAt = DateTime.now();
      return value;
    } finally {
      if (identical(_inFlight, request)) _inFlight = null;
    }
  }

  void invalidate() {
    _value = null;
    _valueToken = null;
    _loadedAt = null;
  }

  /// Every cache at once — after sign-in, sign-out, or anything that changes
  /// what the student is allowed to see.
  static void invalidateAll() {
    for (final cache in _all) {
      cache.invalidate();
    }
  }
}
