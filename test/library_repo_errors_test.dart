import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_exceptions.dart';

/// THE BUG, and why the library cap would have shipped mute.
///
/// `ApiServices` does not throw on an HTTP error — it catches the DioException
/// and RETURNS `ApiExceptions.handleError(e)`, an `ApiError` VALUE. Every
/// refusal from /add-to-library is a 422, so the result arrives as an ApiError.
///
/// `LibraryRepo.addToLibrary` only inspected `Map` and `String`, so an ApiError
/// fell through to `throw Exception('استجابة غير متوقعة من الخادم')` and the
/// server's actual reason was discarded. Both the pre-existing "already added"
/// message and the new per-subject full message reached the student as
/// "unexpected response from the server".
///
/// These tests pin the conversion itself — that a 422 body becomes an ApiError
/// carrying the server's message, which is what the repo now rethrows and the
/// lesson flow prints.
void main() {
  ApiError convert(int status, Object? body) => ApiExceptions.handleError(
        DioException(
          requestOptions: RequestOptions(path: '/add-to-library'),
          response: Response(
            requestOptions: RequestOptions(path: '/add-to-library'),
            statusCode: status,
            data: body,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

  group('a refusal keeps the server message', () {
    test('the library-full message survives the conversion', () {
      const arabic = 'يجب إفراغ المكتبة أولاً، فقد اكتملت مكتبة هذه المادة.';

      final error = convert(422, {'success': false, 'message': arabic});

      expect(error.message, arabic);
      // The lesson flow prints e.toString() for a non-ApiError, so this has to
      // read correctly either way.
      expect(error.toString(), arabic);
    });

    test('the already-added message survives too', () {
      final error = convert(422, {
        'success': false,
        'message': 'هذه المهمة قد تمت اضافتها من قبل.',
      });

      expect(error.message, 'هذه المهمة قد تمت اضافتها من قبل.');
    });

    test('a 403 on delete keeps its reason', () {
      // The full-library message tells the student to delete questions, so a
      // failed delete must say why.
      final error = convert(403, {
        'success': false,
        'message': 'لا تملك صلاحية لحذف هذه المهمة.',
      });

      expect(error.message, 'لا تملك صلاحية لحذف هذه المهمة.');
    });
  });

  group('the conversion produces a VALUE, not a throw', () {
    test('which is exactly why the repo must test for ApiError', () {
      // If handleError ever started throwing, the `is ApiError` branches would
      // be dead code — and this test would be the thing that noticed.
      final result = convert(422, {'success': false, 'message': 'أي رسالة'});

      expect(result, isA<ApiError>());
    });
  });

  group('a body with no message', () {
    test('falls back rather than producing an empty alert', () {
      final error = convert(500, 'Internal Server Error');

      expect(error.message, isNotEmpty);
    });
  });
}
