import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_smart_api/src/core/api_config.dart';

/// Interceptor that automatically retries failed requests.
///
/// Only retries on connection / timeout errors (i.e. [DioExceptionType] that
/// does NOT include a server response).  4xx and 5xx responses are NOT
/// retried — those are treated as definitive failures.
///
/// The number of attempts is controlled by [ApiConfig.retryAttempts].
///
/// Consecutive retries are separated by an exponential back-off:
///   attempt 1 → 500 ms
///   attempt 2 → 1 000 ms
///   attempt 3 → 2 000 ms
class RetryInterceptor extends Interceptor {
  /// Delays injected for unit-testing (override to speed up tests).
  Duration Function(int attempt) delayBuilder;

  RetryInterceptor({
    Duration Function(int attempt)? delayBuilder,
  }) : delayBuilder = delayBuilder ??
            ((attempt) => Duration(milliseconds: 500 * (1 << attempt)));

  final Dio _dio = Dio();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      return super.onError(err, handler);
    }

    final options = err.requestOptions;
    final attempts = options.extra['_retryCount'] as int? ?? 0;
    final maxAttempts = ApiConfig.retryAttempts;

    if (attempts >= maxAttempts) {
      return super.onError(err, handler);
    }

    // Back-off.
    await Future<void>.delayed(delayBuilder(attempts));

    // Increment the attempt counter so we can track across recursive calls.
    options.extra['_retryCount'] = attempts + 1;

    try {
      // Re-issue the request through the same Dio instance so all
      // interceptors (including auth) run again.
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return super.onError(retryError, handler);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
