// lib/core/network/network_status.dart
//
// Whether the app can currently reach the server, as one global flag.
//
// WHY. Every screen used to find out it was offline from its own failed
// request, so each one guessed at a message independently — which is how a
// dropped connection ended up reported as "فشل تحميل الإحصائيات" on one
// screen and "يرجى تسجيل الدخول أولاً" on another, neither of which is true.
// [DioClient] updates this flag on every request; a single banner
// (NetworkStatusBanner, wired in main.dart) renders it for the whole app, so
// a connection drop is announced once, correctly, wherever the student is.

import 'package:flutter/foundation.dart';

class NetworkStatus {
  NetworkStatus._();

  /// True once a request has failed for a connectivity reason and stayed
  /// that way until one succeeds. Starts false so app launch never flashes
  /// an "offline" banner before the first request has even been tried.
  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);
}
