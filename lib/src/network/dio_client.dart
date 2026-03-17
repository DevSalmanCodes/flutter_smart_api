import 'package:dio/dio.dart';
import 'package:flutter_smart_api/src/core/api_config.dart';
import 'package:flutter_smart_api/src/network/interceptors/auth_interceptor.dart';
import 'package:flutter_smart_api/src/network/interceptors/logging_interceptor.dart';
import 'package:flutter_smart_api/src/network/interceptors/retry_interceptor.dart';

/// Singleton wrapper around [Dio] that wires up all interceptors and applies
/// the global [ApiConfig] settings.
///
/// You should not use [DioClient] directly in application code — use [Api]
/// instead.  [DioClient] is `public` only so that advanced users can access
/// the underlying [Dio] instance for custom interceptors.
class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();

  /// The global [DioClient] singleton.
  static DioClient get instance => _instance;

  Dio? _dio;

  /// The configured [Dio] instance.  Lazily initialised.
  Dio get dio {
    _dio ??= _buildDio();
    return _dio!;
  }

  /// Destroys the current [Dio] instance so it is rebuilt on the next access.
  ///
  /// Called automatically by [ApiConfig.init] when the configuration changes.
  void reset() {
    _dio?.close(force: true);
    _dio = null;
  }

  Dio _buildDio() {
    final options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: Map<String, dynamic>.from(ApiConfig.defaultHeaders),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);

    // Order matters: auth first, then retry, then logging (outermost).
    dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(),
      if (ApiConfig.enableLogging) LoggingInterceptor(),
    ]);

    return dio;
  }
}
