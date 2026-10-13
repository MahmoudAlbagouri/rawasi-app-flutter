// lib/features/contact/data/app_videos_repo.dart
//
// The «كيف يعمل التطبيق؟» video. Its link is set by an admin on the dashboard's
// hero screen and served by GET /app-videos, so publishing or replacing the
// video needs no new app build.

import 'package:flutter/foundation.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';

class AppVideo {
  /// The 11-character YouTube video id.
  final String id;

  const AppVideo._(this.id);

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// The server already validates the id; this is the second check, because
  /// the id is later written into a page that runs in a WebView.
  static bool isValidId(String id) => _idPattern.hasMatch(id);

  /// null when [json] is absent or carries anything but a real video id.
  ///
  /// Only the id is read. Every URL is built from it here, so nothing the
  /// server (or a man in the middle) puts in `url` / `embed_url` can reach the
  /// player.
  static AppVideo? tryParse(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    if (id is! String || !isValidId(id)) return null;

    return AppVideo._(id);
  }

  /// For tests and callers that already hold a trusted id.
  factory AppVideo(String id) {
    if (!isValidId(id)) {
      throw ArgumentError.value(id, 'id', 'not a YouTube video id');
    }

    return AppVideo._(id);
  }

  /// Where "open in YouTube" goes.
  String get watchUrl => 'https://www.youtube.com/watch?v=$id';

  /// The player page. youtube-nocookie: nothing is set on a viewer who only
  /// presses play. playsinline keeps iOS from taking the video fullscreen.
  String get embedUrl =>
      'https://www.youtube-nocookie.com/embed/$id?rel=0&playsinline=1';
}

class AppVideosRepo {
  final Future<dynamic> Function(String endpoint) _get;

  /// [get] exists so a test can answer without a network.
  AppVideosRepo({Future<dynamic> Function(String endpoint)? get})
    : _get = get ?? ApiServices().get;

  /// The walkthrough, or null while no link has been set (the screen then
  /// shows "coming soon"). Throws [ApiError] when the request itself failed.
  Future<AppVideo?> fetchWalkthrough() async => parse(await _get('/app-videos'));

  @visibleForTesting
  static AppVideo? parse(dynamic response) {
    // ApiServices RETURNS its failures as an ApiError value rather than
    // throwing them.
    if (response is ApiError) throw response;

    if (response is! Map) {
      throw ApiError(message: 'استجابة غير متوقعة من الخادم');
    }

    // The envelope is authoritative: success:false is an error whatever the
    // HTTP status said.
    if (response['success'] == false) {
      throw ApiError(
        message: (response['message'] as String?)?.trim().isNotEmpty == true
            ? response['message'] as String
            : 'تعذّر تحميل الفيديو',
      );
    }

    final data = response['data'];

    return data is Map ? AppVideo.tryParse(data['walkthrough']) : null;
  }
}
