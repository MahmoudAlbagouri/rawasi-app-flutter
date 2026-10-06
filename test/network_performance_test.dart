import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/network/api_cache.dart';
import 'package:rawasi_app_n/core/network/dio_client.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';

/// The app-side causes of slowness: the token decrypted on every request,
/// the same data refetched on every tab switch, and dropped connections left
/// hanging with no timeout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'token-A'});
    PrefHelper.resetMemoryForTest();
    ApiCache.invalidateAll();
  });

  group('the token is read from secure storage once', () {
    test('later reads come from memory, not the keystore', () async {
      expect(await PrefHelper.getToken(), 'token-A');

      // Change what storage holds underneath: a memory read does not notice.
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'changed-on-disk'});
      expect(await PrefHelper.getToken(), 'token-A');
    });

    test('concurrent first reads share one storage read', () async {
      final reads = await Future.wait([
        PrefHelper.getToken(),
        PrefHelper.getToken(),
        PrefHelper.getToken(),
      ]);
      expect(reads, ['token-A', 'token-A', 'token-A']);
    });

    test('save and clear keep memory and storage in step', () async {
      await PrefHelper.saveToken('token-B');
      expect(await PrefHelper.getToken(), 'token-B');

      await PrefHelper.clearToken();
      expect(await PrefHelper.getToken(), isNull);
    });
  });

  group('ApiCache', () {
    late int loads;
    late ApiCache<String> cache;

    Future<String> load() async {
      loads++;
      return 'value-$loads';
    }

    setUp(() {
      loads = 0;
      cache = ApiCache<String>(const Duration(minutes: 1));
    });

    test('reuses a fresh answer instead of refetching', () async {
      expect(await cache.get(load), 'value-1');
      expect(await cache.get(load), 'value-1');
      expect(loads, 1);
    });

    test('screens asking at the same moment share ONE request', () async {
      final answers = await Future.wait([cache.get(load), cache.get(load), cache.get(load)]);
      expect(answers.toSet(), {'value-1'});
      expect(loads, 1);
    });

    test('never answers for a different student', () async {
      await cache.get(load);
      await PrefHelper.saveToken('token-B'); // someone else signs in

      expect(await cache.get(load), 'value-2');
      expect(loads, 2);
    });

    test('a failure is not cached — the next call tries again', () async {
      await expectLater(cache.get(() async => throw Exception('offline')), throwsException);
      expect(await cache.get(load), 'value-1');
    });

    test('force and invalidate both go back to the server', () async {
      await cache.get(load);
      expect(await cache.get(load, force: true), 'value-2');

      ApiCache.invalidateAll();
      expect(await cache.get(load), 'value-3');
    });

    test('an expired answer is refetched', () async {
      final short = ApiCache<String>(Duration.zero);
      await short.get(load);
      await short.get(load);
      expect(loads, 2);
    });
  });

  group('dropped connections', () {
    DioException failure(DioExceptionType type, {String method = 'GET', Object? data}) =>
        DioException(
          requestOptions: RequestOptions(path: '/x', method: method, data: data),
          type: type,
        );

    test('a connection that never opened is retried, for any method', () {
      expect(DioClient.shouldRetry(failure(DioExceptionType.connectionTimeout), 0), isTrue);
      expect(
        DioClient.shouldRetry(failure(DioExceptionType.connectionTimeout, method: 'POST'), 0),
        isTrue,
        reason: 'the request never left the phone, so repeating it is safe',
      );
    });

    test('a mid-request drop is retried only for a read', () {
      expect(DioClient.shouldRetry(failure(DioExceptionType.connectionError), 0), isTrue);
      expect(
        DioClient.shouldRetry(failure(DioExceptionType.connectionError, method: 'POST'), 0),
        isFalse,
        reason: 'the server may already have acted on it',
      );
    });

    test('never retries a server answer, a slow server, or an upload', () {
      expect(DioClient.shouldRetry(failure(DioExceptionType.badResponse), 0), isFalse);
      expect(DioClient.shouldRetry(failure(DioExceptionType.receiveTimeout), 0), isFalse);
      expect(
        DioClient.shouldRetry(
          failure(DioExceptionType.connectionTimeout, method: 'POST', data: FormData()),
          0,
        ),
        isFalse,
        reason: 'a FormData body cannot be sent twice',
      );
    });

    test('gives up after the retry limit', () {
      expect(
        DioClient.shouldRetry(failure(DioExceptionType.connectionTimeout), DioClient.maxRetries),
        isFalse,
      );
    });

    test('connecting no longer waits forever', () {
      expect(DioClient().dio.options.connectTimeout, const Duration(seconds: 8));
    });
  });
}
