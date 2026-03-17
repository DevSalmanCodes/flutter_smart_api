import 'package:dio/dio.dart';

/// Interceptor that pretty-prints every request and response to the console.
///
/// Enable / disable via [ApiConfig.enableLogging].
/// Output uses emoji to aid quick scanning in the debug console.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('┌──── 🚀 REQUEST ─────────────────────────────────────');
    // ignore: avoid_print
    print('│ ${options.method.toUpperCase()} ${options.uri}');
    if (options.headers.isNotEmpty) {
      // ignore: avoid_print
      print('│ Headers: ${options.headers}');
    }
    if (options.data != null) {
      // ignore: avoid_print
      print('│ Body: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      // ignore: avoid_print
      print('│ Query: ${options.queryParameters}');
    }
    // ignore: avoid_print
    print('└────────────────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('┌──── ✅ RESPONSE ────────────────────────────────────');
    // ignore: avoid_print
    print('│ ${response.statusCode} ${response.requestOptions.uri}');
    // ignore: avoid_print
    print('│ Body: ${response.data}');
    // ignore: avoid_print
    print('└────────────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('┌──── ❌ ERROR ───────────────────────────────────────');
    // ignore: avoid_print
    print('│ ${err.type.name} — ${err.message}');
    if (err.response != null) {
      // ignore: avoid_print
      print('│ Status: ${err.response?.statusCode}');
      // ignore: avoid_print
      print('│ Body: ${err.response?.data}');
    }
    // ignore: avoid_print
    print('└────────────────────────────────────────────────────');
    super.onError(err, handler);
  }
}
