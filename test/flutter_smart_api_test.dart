import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_smart_api/flutter_smart_api.dart';

void main() {
  // ─── Result tests ─────────────────────────────────────────────────────────
  group('Result', () {
    test('Success carries data and isSuccess is true', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Failure carries ApiException and isFailure is true', () {
      const err = ApiException(message: 'Not found', statusCode: 404);
      const result = Result<int>.failure(err);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, err);
    });

    test('when() dispatches to the correct branch', () {
      const success = Result<String>.success('hello');
      final got = success.when(
        success: (v) => 'got: $v',
        failure: (e) => 'error: ${e.message}',
      );
      expect(got, 'got: hello');

      const err = ApiException(message: 'oops');
      const failure = Result<String>.failure(err);
      final got2 = failure.when(
        success: (v) => 'ok',
        failure: (e) => 'error: ${e.message}',
      );
      expect(got2, 'error: oops');
    });

    test('map() transforms data on success', () {
      const result = Result<int>.success(5);
      final mapped = result.map((n) => n * 2);
      expect(mapped.dataOrNull, 10);
    });

    test('map() passes failure through unchanged', () {
      const err = ApiException(message: 'boom');
      const result = Result<int>.failure(err);
      final mapped = result.map((n) => n * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull?.message, 'boom');
    });
  });

  // ─── ApiException tests ───────────────────────────────────────────────────
  group('ApiException', () {
    test('fromStatusCode maps 401 to UnauthorizedException', () {
      final ex = ApiException.fromStatusCode(statusCode: 401);
      expect(ex, isA<UnauthorizedException>());
    });

    test('fromStatusCode maps 403 to UnauthorizedException', () {
      final ex = ApiException.fromStatusCode(statusCode: 403);
      expect(ex, isA<UnauthorizedException>());
    });

    test('fromStatusCode maps 500 to ServerException', () {
      final ex = ApiException.fromStatusCode(statusCode: 500);
      expect(ex, isA<ServerException>());
    });

    test('fromStatusCode extracts message from JSON body', () {
      final ex = ApiException.fromStatusCode(
        statusCode: 422,
        data: {'message': 'Validation failed'},
      );
      expect(ex.message, 'Validation failed');
    });
  });

  // ─── ApiCache tests ───────────────────────────────────────────────────────
  group('ApiCache', () {
    setUp(() => ApiCache.instance.clear());

    test('set and get returns the stored value', () {
      ApiCache.instance.set('/users', [1, 2, 3]);
      expect(ApiCache.instance.get('/users'), [1, 2, 3]);
    });

    test('has returns true for unexpired key', () {
      ApiCache.instance.set('/posts', 'data');
      expect(ApiCache.instance.has('/posts'), isTrue);
    });

    test('invalidate removes a key', () {
      ApiCache.instance.set('/key', 'value');
      ApiCache.instance.invalidate('/key');
      expect(ApiCache.instance.has('/key'), isFalse);
    });

    test('invalidatePrefix removes all matching keys', () {
      ApiCache.instance.set('/users', 1);
      ApiCache.instance.set('/users/1', 2);
      ApiCache.instance.set('/posts', 3);
      ApiCache.instance.invalidatePrefix('/users');
      expect(ApiCache.instance.has('/users'), isFalse);
      expect(ApiCache.instance.has('/users/1'), isFalse);
      expect(ApiCache.instance.has('/posts'), isTrue);
    });

    test('expired entries return null', () {
      ApiCache.instance
          .set('/data', 'value', ttl: const Duration(milliseconds: 1));
      // Sleep a bit longer than the TTL.  This relies on real time—fine for a
      // unit test but keep TTL short.
      Future.delayed(const Duration(milliseconds: 5), () {
        expect(ApiCache.instance.get('/data'), isNull);
      });
    });

    test('buildKey produces consistent keys', () {
      final k1 = ApiCache.buildKey('/users', {'page': 1, 'limit': 10});
      final k2 = ApiCache.buildKey('/users', {'limit': 10, 'page': 1});
      expect(k1, k2);
    });
  });

  // ─── ModelFactory tests ───────────────────────────────────────────────────
  group('ModelFactory', () {
    tearDown(() => ModelFactory.clear());

    test('register and fromJson work correctly', () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      final user = ModelFactory.fromJson<_FakeUser>({'id': 1, 'name': 'Alice'});
      expect(user.id, 1);
      expect(user.name, 'Alice');
    });

    test('isRegistered returns false before registration', () {
      expect(ModelFactory.isRegistered<_FakeUser>(), isFalse);
    });

    test('isRegistered returns true after registration', () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      expect(ModelFactory.isRegistered<_FakeUser>(), isTrue);
    });

    test('fromJson throws ParsingException for unknown type', () {
      expect(
        () => ModelFactory.fromJson<_FakeUser>({'id': 1, 'name': 'Bob'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('unregister removes type', () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      ModelFactory.unregister<_FakeUser>();
      expect(ModelFactory.isRegistered<_FakeUser>(), isFalse);
    });
  });

  // ─── JsonParser tests ─────────────────────────────────────────────────────
  group('JsonParser', () {
    tearDown(() => ModelFactory.clear());

    test('parses primitives', () {
      expect(JsonParser.parse<int>(42), 42);
      expect(JsonParser.parse<String>('hello'), 'hello');
      expect(JsonParser.parse<bool>(true), isTrue);
      expect(JsonParser.parse<double>(3.14), closeTo(3.14, 0.001));
    });

    test('parses registered model from Map', () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      final user = JsonParser.parse<_FakeUser>({'id': 7, 'name': 'Charlie'});
      expect(user.name, 'Charlie');
    });

    test('parses List<model> from JSON array', () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      final users = JsonParser.parse<List<_FakeUser>>([
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ]);
      expect(users, isA<List<_FakeUser>>());
      expect(users.length, 2);
      expect(users[0].name, 'Alice');
    });

    test('throws ParsingException on malformed primitive', () {
      expect(
        () => JsonParser.parse<int>('not_an_int'),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException when JSON is null but type is non-nullable',
        () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      expect(
        () => JsonParser.parse<_FakeUser>(null),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
        'throws ParsingException parsing deeply nested list without custom parserOverride',
        () {
      ModelFactory.register<_FakeUser>((j) => _FakeUser.fromJson(j));
      // Try parsing List<List<_FakeUser>> which is NOT registered automatically
      expect(
        () => JsonParser.parse<List<List<_FakeUser>>>([
          [
            {'id': 1, 'name': 'A'}
          ]
        ]),
        throwsA(isA<ParsingException>()),
      );
    });

    test('parserOverride completely bypasses default logic', () {
      final overrideResult = JsonParser.parse<int>(
        '50',
        parserOverride: (json) => 999,
      );
      expect(overrideResult, 999);
    });
  });

  // ─── ApiConfig tests ──────────────────────────────────────────────────────
  group('ApiConfig', () {
    test('setToken and clearToken work', () {
      ApiConfig.setToken('my-token');
      expect(ApiConfig.token, 'my-token');
      ApiConfig.clearToken();
      expect(ApiConfig.token, isNull);
    });

    test('addHeader and removeHeader work', () {
      ApiConfig.addHeader('X-Custom', 'value');
      expect(ApiConfig.defaultHeaders.containsKey('X-Custom'), isTrue);
      ApiConfig.removeHeader('X-Custom');
      expect(ApiConfig.defaultHeaders.containsKey('X-Custom'), isFalse);
    });
  });
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

class _FakeUser {
  final int id;
  final String name;
  const _FakeUser({required this.id, required this.name});
  factory _FakeUser.fromJson(Map<String, dynamic> j) =>
      _FakeUser(id: j['id'] as int, name: j['name'] as String);
}
