import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_api/flutter_smart_api.dart';
import 'package:flutter_smart_api/src/network/dio_client.dart';

// Helper mock to capture outgoing requests
class MockCapturingInterceptor extends Interceptor {
  RequestOptions? lastRequestOptions;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequestOptions = options;
    // Resolve immediately so we don't actually hit the network
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {'msg': 'ok'},
    ));
  }
}

void main() {
  late MockCapturingInterceptor captureInterceptor;

  setUp(() async {
    final directory = Directory.systemTemp.createTempSync('interceptor_tests');
    await ApiConfig.init(
      baseUrl: 'https://test.example.com',
      enableLogging: false,
      testCacheDirectory: directory.path,
    );

    ApiConfig.clearToken(); // Reset token state

    captureInterceptor = MockCapturingInterceptor();
    captureInterceptor.lastRequestOptions = null;
    DioClient.instance.dio.interceptors.add(captureInterceptor);
  });

  group('AuthInterceptor Tests', () {
    test('1. Does not add Authorization header if token is null', () async {
      final res = await Api.getSafe<dynamic>('/test');
      if (res.isFailure) print(res.errorOrNull);
      
      final headers = captureInterceptor.lastRequestOptions!.headers;
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('2. Adds Authorization Bearer header if token is set', () async {
      ApiConfig.setToken('my-secret-token');
      final res = await Api.getSafe<dynamic>('/test');
      if (res.isFailure) print(res.errorOrNull);
      
      final headers = captureInterceptor.lastRequestOptions!.headers;
      expect(headers['Authorization'], 'Bearer my-secret-token');
    });

    test('3. Clears Authorization header when token is cleared', () async {
      ApiConfig.setToken('my-secret-token');
      final res1 = await Api.getSafe<dynamic>('/test');
      if (res1.isFailure) print(res1.errorOrNull);
      expect(captureInterceptor.lastRequestOptions!.headers['Authorization'], 'Bearer my-secret-token');

      ApiConfig.clearToken();
      final res2 = await Api.getSafe<dynamic>('/test2');
      if (res2.isFailure) print(res2.errorOrNull);
      expect(captureInterceptor.lastRequestOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('4. Does not override manually provided Authorization header', () async {
      ApiConfig.setToken('my-global-token');
      
      // Override in the specific request
      final res = await Api.getSafe<dynamic>('/test', headers: {'Authorization': 'Bearer other-token'});
      if (res.isFailure) print(res.errorOrNull);
      
      final headers = captureInterceptor.lastRequestOptions!.headers;
      expect(headers['Authorization'], 'Bearer other-token');
    });
  });

  group('ApiConfig defaultHeaders tests', () {
    test('1. defaultHeaders are applied to every request', () async {
      ApiConfig.addHeader('X-Custom-Client', 'SmartApp');
      
      final res1 = await Api.postSafe<dynamic>('/test', body: {});
      if (res1.isFailure) print(res1.errorOrNull);
      
      final headers = captureInterceptor.lastRequestOptions!.headers;
      expect(headers['X-Custom-Client'], 'SmartApp');
      
      ApiConfig.removeHeader('X-Custom-Client');
      final res2 = await Api.postSafe<dynamic>('/test2', body: {});
      if (res2.isFailure) print(res2.errorOrNull);
      expect(captureInterceptor.lastRequestOptions!.headers.containsKey('X-Custom-Client'), isFalse);
    });
  });
}
