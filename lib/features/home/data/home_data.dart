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
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
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
  });

  factory HomeData.signedOut() => HomeData(
        isSignedIn: false,
        profile: null,
        stats: null,
        courses: null,
        library: null,
        loadedAt: DateTime.now(),
      );

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

  /// Drops the cache — call after anything that changes the student's state.
  static void invalidate() => _cache = null;

  /// [force] bypasses the cache; pull-to-refresh passes true.
  Future<HomeData> load({bool force = false}) async {
    final cached = _cache;
    if (!force && cached != null && cached.isFresh) return cached;

    final signedIn = await isUserSignedIn();
    if (!signedIn) {
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
    if (data.profile != null) _cache = data;

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
