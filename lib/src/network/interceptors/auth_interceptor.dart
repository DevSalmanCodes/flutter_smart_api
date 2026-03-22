import 'package:dio/dio.dart';
import 'package:flutter_smart_api/src/core/api_config.dart';

/// Interceptor that injects the `Authorization: Bearer <token>` header into
/// every outgoing request when a token has been set via [ApiConfig.setToken].
///
/// The token is read lazily on each request, so calling [ApiConfig.setToken]
/// after initialisation is reflected immediately.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = ApiConfig.token;
    if (token != null && token.isNotEmpty) {
      if (!options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    super.onRequest(options, handler);
  }
}
