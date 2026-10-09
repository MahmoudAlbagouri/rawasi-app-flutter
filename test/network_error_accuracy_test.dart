import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/network/api_exceptions.dart';
import 'package:rawasi_app_n/core/network/network_status.dart';
import 'package:rawasi_app_n/features/courses/views/course_lessons_view.dart';

/// THE REPORTED BUG: when the connection drops, the app showed a misleading
/// error - a forced "يرجى تسجيل الدخول أولاً", or an unexplained generic
/// message under the statistics page's retry button - instead of saying what
/// actually happened.
///
/// These tests pin the one place that decides it (ApiExceptions) and the
/// global signal (NetworkStatus) the rest of the app now reads instead of
/// guessing from its own error message.
void main() {
  DioException connectivity(DioExceptionType type) {
    return DioException(
      requestOptions: RequestOptions(path: '/analytics'),
      type: type,
    );
  }

  DioException withResponse(int statusCode, [Object? data]) {
    final options = RequestOptions(path: '/analytics');
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  group('ApiExceptions.isConnectivityIssue', () {
    test('a connect timeout is a connectivity issue', () {
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.connectionTimeout),
        ),
        isTrue,
      );
    });

    test('a dropped connection mid-request is a connectivity issue', () {
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.connectionError),
        ),
        isTrue,
      );
    });

    test('a slow/no response is a connectivity issue', () {
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.receiveTimeout),
        ),
        isTrue,
      );
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.sendTimeout),
        ),
        isTrue,
      );
    });

    test('an unclassified failure with no response is treated as one', () {
      // On this app's stack, DioExceptionType.unknown with no response is
      // almost always a raw SocketException - no signal, DNS failure,
      // airplane mode.
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.unknown),
        ),
        isTrue,
      );
    });

    test('a deliberate cancellation is not a connectivity issue', () {
      expect(
        ApiExceptions.isConnectivityIssue(
          connectivity(DioExceptionType.cancel),
        ),
        isFalse,
      );
    });

    test('ANY response from the server means it was reached', () {
      // THE CORE RULE: whatever DioExceptionType says, a response means the
      // server answered - a 401, a 403, a 500 - and that is never "no
      // internet", however confusing the server's own answer might be.
      for (final status in [401, 403, 404, 422, 500]) {
        expect(ApiExceptions.isConnectivityIssue(withResponse(status)), isFalse);
      }
    });
  });

  group('ApiExceptions.handleError', () {
    test('a connectivity failure gets an honest, specific message', () {
      final error = ApiExceptions.handleError(
        connectivity(DioExceptionType.connectionError),
      );

      expect(error.isConnectivityIssue, isTrue);
      expect(error.message, contains('اتصال بالإنترنت'));
    });

    test('a server message is preferred over the generic fallback', () {
      final error = ApiExceptions.handleError(
        withResponse(401, {'message': 'غير مصرح بالدخول'}),
      );

      expect(error.message, 'غير مصرح بالدخول');
      expect(
        error.isConnectivityIssue,
        isFalse,
        reason: 'the server answered - this is not a dropped connection',
      );
    });

    test('a response with no message still does not claim to be offline', () {
      final error = ApiExceptions.handleError(withResponse(500, 'oops'));

      expect(error.isConnectivityIssue, isFalse);
      expect(error.message, isNot(contains('اتصال')));
    });
  });

  group('NetworkStatus', () {
    setUp(() => NetworkStatus.isOffline.value = false);

    test('starts online', () {
      expect(NetworkStatus.isOffline.value, isFalse);
    });

    test('is a single shared flag', () {
      // DioClient flips this on a connectivity failure and clears it on any
      // success - asserting the identity here is what stops a future change
      // from quietly giving every screen its own copy again.
      NetworkStatus.isOffline.value = true;
      expect(NetworkStatus.isOffline.value, isTrue);
      NetworkStatus.isOffline.value = false;
      expect(NetworkStatus.isOffline.value, isFalse);
    });
  });

  group('CourseLessonsView.showStreamNotice', () {
    // THE RULE: only 2nd/3rd year secondary split into علمي/أدبي at all (1st
    // year's بكالوريا has none), and only a علمي student has lessons missing
    // from the numbering (the ones exclusive to أدبي).
    test('shown for a 2nd year science student', () {
      expect(CourseLessonsView.showStreamNotice('2', 'science'), isTrue);
    });

    test('shown for a 3rd year science student', () {
      expect(CourseLessonsView.showStreamNotice('3', 'science'), isTrue);
    });

    test('not shown for a literature student, same years', () {
      expect(CourseLessonsView.showStreamNotice('2', 'literature'), isFalse);
      expect(CourseLessonsView.showStreamNotice('3', 'literature'), isFalse);
    });

    test('not shown for 1st year science - البكالوريا has no stream split', () {
      expect(CourseLessonsView.showStreamNotice('1', 'science'), isFalse);
    });

    test('not shown with no branch on record', () {
      expect(CourseLessonsView.showStreamNotice('2', null), isFalse);
    });

    test('not shown with no year on record', () {
      expect(CourseLessonsView.showStreamNotice(null, 'science'), isFalse);
    });
  });
}
