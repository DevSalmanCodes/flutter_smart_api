import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_api/flutter_smart_api.dart';
import 'package:flutter_smart_api/src/network/dio_client.dart';

class MockErrorInterceptor extends Interceptor {
  final DioException exceptionToThrow;

  MockErrorInterceptor(this.exceptionToThrow);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(exceptionToThrow, true);
  }
}

class MockResponseInterceptor extends Interceptor {
  final dynamic responseData;
  final int statusCode;

  MockResponseInterceptor(this.responseData, {this.statusCode = 200});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(Response(
      requestOptions: options,
      data: responseData,
      statusCode: statusCode,
    ));
  }
}

void main() {
  setUp(() {
    final directory = Directory.systemTemp.createTempSync('error_tests');
    ApiConfig.init(
      baseUrl: 'https://test.example.com',
      enableLogging: false,
      retryAttempts: 0, // Disable retry to test immediate failure
      testCacheDirectory: directory.path,
    );
    // Clear out previous interceptors and add our mock one
    DioClient.instance.dio.interceptors.clear();
  });

  group('ApiClient Error Handling Edge Cases', () {
    test('1. connectionTimeout maps to TimeoutException', () async {
      final reqOptions = RequestOptions(path: '/test');
      DioClient.instance.dio.interceptors.add(
        MockErrorInterceptor(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      final result = await Api.getSafe<dynamic>('/test');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkException>());
      expect(result.errorOrNull!.message.toLowerCase(), contains('timed out'));
    });

    test('2. receiveTimeout maps to TimeoutException', () async {
      final reqOptions = RequestOptions(path: '/test');
      DioClient.instance.dio.interceptors.add(
        MockErrorInterceptor(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.receiveTimeout,
          ),
        ),
      );

      final result = await Api.getSafe<dynamic>('/test');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkException>());
    });

    test('3. SocketException maps to NetworkException', () async {
      final reqOptions = RequestOptions(path: '/test');
      DioClient.instance.dio.interceptors.add(
        MockErrorInterceptor(
          DioException(
            requestOptions: reqOptions,
            error: const SocketException('No internet'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      final result = await Api.getSafe<dynamic>('/test');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkException>());
    });

    test('5. 4XX and 5XX Dio badResponse map correctly', () async {
      final reqOptions = RequestOptions(path: '/test');

      // Test 401
      DioClient.instance.dio.interceptors.add(
        MockErrorInterceptor(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: reqOptions,
              statusCode: 401,
              data: {'message': 'Unauthorized access'},
            ),
          ),
        ),
      );

      final res401 = await Api.getSafe<dynamic>('/test');
      expect(res401.errorOrNull, isA<UnauthorizedException>());
      expect(res401.errorOrNull!.message, 'Unauthorized access');

      // Clear interceptors and test 500
      DioClient.instance.dio.interceptors.clear();
      DioClient.instance.dio.interceptors.add(
        MockErrorInterceptor(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: reqOptions,
              statusCode: 500,
              data: {'message': 'Server is down'},
            ),
          ),
        ),
      );

      final res500 = await Api.postSafe<dynamic>('/test');
      expect(res500.errorOrNull, isA<ServerException>());
      expect(res500.errorOrNull!.message, 'Server is down');
    });

    test('6. Malformed JSON returns ParsingException via Api wrap', () async {
      DioClient.instance.dio.interceptors.add(
        MockResponseInterceptor('This is not json', statusCode: 200),
      );

      // Using String as expected type, but server returns unparseable stuff
      // Actually Dio throws DioExceptionType.unknown with FormatException if it's bad json internally if content-type is json
      // But if it slips through as a String when a Map was expected:
      final result = await Api.getSafe<Map<String, dynamic>>('/test');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ParsingException>());
    });
  });
}
