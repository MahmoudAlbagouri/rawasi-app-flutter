// lib/features/contact/data/app_videos_repo.dart
//
// The «كيف يعمل التطبيق؟» video. Its link is set by an admin on the dashboard's
// hero screen and served by GET /app-videos, so publishing or replacing the
// video needs no new app build.

import 'package:flutter/foundation.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';

/// The walkthrough video: either a YouTube video (embedded in the app's
/// locked-down player, built from its id) or any other web link (a video file,
/// Google Drive, Vimeo, …) which is only ever OPENED OUTSIDE the app — an
/// arbitrary page never reaches the in-app WebView.
class AppVideo {
  /// The 11-character YouTube video id; null for an external link.
  final String? id;

  /// The http(s) link of a non-YouTube video; null for YouTube.
  final Uri? externalUrl;

  const AppVideo._(this.id) : externalUrl = null;

  const AppVideo._external(Uri url) : id = null, externalUrl = url;

  /// True when the video plays in the app's own YouTube player.
  bool get isYouTube => id != null;

  /// An absolute http(s) link with a real host, or null. The second check of
  /// what the server sends (it validates the same way), because the link is
  /// handed to the system to open.
  static Uri? safeExternalUrl(Object? raw) {
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.host.isEmpty ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    return uri;
  }

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// The server already validates the id; this is the second check, because
  /// the id is later written into a page that runs in a WebView.
  static bool isValidId(String id) => _idPattern.hasMatch(id);

  /// null when [json] is absent or carries nothing usable.
  ///
  /// A YouTube video is read by its id ALONE: every URL is built from it here,
  /// so nothing the server (or a man in the middle) puts in `url` /
  /// `embed_url` can reach the player. Only a `file` / `link` video uses
  /// `url`, and only as a link to open outside the app.
  static AppVideo? tryParse(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    if (id is String && isValidId(id)) return AppVideo._(id);

    final type = json['type'];
    if (type == 'file' || type == 'link') {
      final url = safeExternalUrl(json['url']);
      if (url != null) return AppVideo._external(url);
    }

    return null;
  }

  /// A video on any other site, opened outside the app.
  factory AppVideo.external(String url) {
    final uri = safeExternalUrl(url);
    if (uri == null) {
      throw ArgumentError.value(url, 'url', 'not an http(s) link');
    }

    return AppVideo._external(uri);
  }

  /// For tests and callers that already hold a trusted id.
  factory AppVideo(String id) {
    if (!isValidId(id)) {
      throw ArgumentError.value(id, 'id', 'not a YouTube video id');
    }

    return AppVideo._(id);
  }

  /// Where "open the video" goes: YouTube's page, or the external link.
  String get watchUrl => isYouTube
      ? 'https://www.youtube.com/watch?v=$id'
      : externalUrl.toString();

  /// The player page — YouTube only. youtube-nocookie: nothing is set on a
  /// viewer who only presses play. playsinline keeps iOS from taking the
  /// video fullscreen.
  String get embedUrl {
    if (!isYouTube) {
      throw StateError('an external video is opened, never embedded');
    }

    return 'https://www.youtube-nocookie.com/embed/$id?rel=0&playsinline=1';
  }
}

class AppVideosRepo {
  final Future<dynamic> Function(String endpoint) _get;

  /// [get] exists so a test can answer without a network.
  AppVideosRepo({Future<dynamic> Function(String endpoint)? get})
    : _get = get ?? ApiServices().get;

  /// The walkthrough, or null while no link has been set (the screen then
  /// shows "coming soon"). Throws [ApiError] when the request itself failed.
  Future<AppVideo?> fetchWalkthrough() async =>
      parse(await _get('/app-videos'));

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
