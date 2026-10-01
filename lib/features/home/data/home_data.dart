// lib/features/home/data/home_data.dart
//
// Home loads from four places at once. Two rules shape this file:
//
// 1. PARALLEL, not serial. Four sequential round-trips would make the new home
//    slower than the one it replaces, which would defeat the point.
//
// 2. PARTIAL FAILURE IS NORMAL, not exceptional. /analytics, /courses and
//    /my-library all sit behind CheckStudentActive, but home renders for
//    students who are not activated yet — so a 403 on three of the four calls
//    is the expected state for a brand-new account, not an error. Each source
//    is therefore captured independently: one failure degrades its own section
//    and never blanks the screen or raises a toast.

import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/courses_repo.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/stats/data/stats_repo.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';

/// Everything home renders. Every section is independently nullable.
class HomeData {
  final bool isSignedIn;
  final Student? profile;

  /// True while the four requests are still in flight for a student who IS
  /// signed in — the token has been read, the profile has not arrived yet.
  ///
  /// Home needs this as a THIRD state. With only signed-in and signed-out, the
  /// moment before the profile lands is indistinguishable from being a guest,
  /// so home rendered the guest screen for a second after every login and
  /// after every pull-to-refresh. Nothing was wrong with the token; the screen
  /// simply had no way to say "not yet".
  final bool isLoading;

  /// null when the call failed or the student cannot reach it yet.
  final StudentStats? stats;
  final List<Course>? courses;
  final List<SubjectItem>? library;

  final DateTime loadedAt;

  const HomeData({
    required this.isSignedIn,
    required this.profile,
    required this.stats,
    required this.courses,
    required this.library,
    required this.loadedAt,
    this.isLoading = false,
  });

  factory HomeData.signedOut() => HomeData(
        isSignedIn: false,
        profile: null,
        stats: null,
        courses: null,
        library: null,
        loadedAt: DateTime.now(),
      );

  /// A signed-in student whose data has not arrived yet.
  factory HomeData.loading() => HomeData(
        isSignedIn: true,
        profile: null,
        stats: null,
        courses: null,
        library: null,
        loadedAt: DateTime.now(),
        isLoading: true,
      );

  /// Which snapshot home should render before its own future resolves.
  ///
  /// [last] is the most recent load that produced something, [hasSession]
  /// whether a token exists — null while that read is still in flight.
  ///
  /// THE RULE: reuse [last] only when it sits on the same side of the auth line
  /// as [hasSession] says we are on now. That single condition is the guest
  /// flash. A FutureBuilder drops its snapshot whenever its future is replaced,
  /// so right after a login the only thing on hand is the guest load from
  /// before it — and showing that is what made home read "ضيف" for a second.
  ///
  /// Only a token read that came back EMPTY produces the guest screen. Not yet
  /// knowing is a third state, and it renders as a loader.
  ///
  /// A function rather than a method on the widget's State so it can be tested
  /// without a network, a navigator or a pump. This mistake has now been made
  /// twice in two different places, which is the argument for pinning it down.
  static HomeData placeholder({
    required HomeData? last,
    required bool? hasSession,
  }) {
    if (last != null && last.isSignedIn == hasSession) return last;

    return hasSession == false ? HomeData.signedOut() : HomeData.loading();
  }

  bool get isFresh =>
      DateTime.now().difference(loadedAt) < HomeRepo.cacheTtl;
}

class HomeRepo {
  /// How long a load stays good for.
  ///
  /// The bottom nav uses pushReplacement, so home is rebuilt from scratch every
  /// time the student comes back to the tab. Without this, that is four fresh
  /// requests each time. Short enough that a completed lesson shows up almost
  /// immediately, and pull-to-refresh always bypasses it.
  static const Duration cacheTtl = Duration(seconds: 90);

  static HomeData? _cache;

  /// Whose data [_cache] holds — the auth token it was loaded with, or null
  /// for a signed-out load.
  ///
  /// This is what makes the cache safe across an auth change. It used to be
  /// keyed on time alone, so logging in within 90 seconds of viewing home as a
  /// guest returned the SIGNED-OUT snapshot and home rendered as a guest until
  /// the student pulled to refresh. The token was always saved correctly; the
  /// cache was simply answering for the wrong user.
  ///
  /// Comparing the token covers every direction of that bug at once — signing
  /// in, signing out, and switching from student A to student B — without any
  /// caller having to remember to invalidate.
  static String? _cacheToken;

  /// Drops the cache — call after anything that changes the student's state.
  static void invalidate() {
    _cache = null;
    _cacheToken = null;
  }

  /// Whether a token is stored, without loading anything else.
  ///
  /// Home asks this first so it can tell a guest from a student mid-load and
  /// pick the right placeholder. One secure-storage read, no network.
  static Future<bool> hasSession() async {
    final token = await PrefHelper.getToken();

    return token != null && token.isNotEmpty;
  }

  /// The last usable load, whoever it belongs to — for the brief window where a
  /// refresh has replaced the future and the new one has not resolved.
  ///
  /// Returning stale data beats blanking the screen, and the token check in
  /// [load] still decides what is eventually rendered.
  static HomeData? get lastLoaded => _cache;

  /// [force] bypasses the cache; pull-to-refresh passes true.
  Future<HomeData> load({bool force = false}) async {
    // Read first: a cached snapshot is only usable if it belongs to the
    // student who is signed in right now.
    final token = await PrefHelper.getToken();

    final cached = _cache;
    if (!force && cached != null && cached.isFresh && _cacheToken == token) {
      return cached;
    }

    if (token == null || token.isEmpty) {
      _cacheToken = null;

      return _cache = HomeData.signedOut();
    }

    // All four at once. Each is wrapped so one rejection cannot take the
    // others down with it — Future.wait would otherwise fail the whole batch
    // on the first error.
    final results = await Future.wait([
      _attempt(() => ProfileRepository().fetchProfile()),
      _attempt(() => StatsRepo().fetchStats()),
      _attempt(() => CoursesRepo().fetchCourses()),
      _attempt(() => LibraryRepo().fetchSubjects()),
    ]);

    final data = HomeData(
      isSignedIn: true,
      profile: results[0] as Student?,
      stats: results[1] as StudentStats?,
      courses: results[2] as List<Course>?,
      library: results[3] as List<SubjectItem>?,
      loadedAt: DateTime.now(),
    );

    // Only a usable load is worth caching; otherwise the next visit retries.
    if (data.profile != null) {
      _cache = data;
      _cacheToken = token;
    }

    return data;
  }

  /// Runs [call] and swallows any failure into null.
  ///
  /// Deliberately silent: the common cause is a 403 from CheckStudentActive
  /// for a student awaiting activation, which is a normal state of the app and
  /// must never reach the student as an error.
  static Future<T?> _attempt<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }
}
