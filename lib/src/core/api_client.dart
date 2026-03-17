// ignore_for_file: always_use_package_imports

import 'package:dio/dio.dart';
import '../cache/api_cache.dart';
import '../cache/cache_manager.dart';
import 'api_exception.dart';
import 'api_response.dart';
import '../network/dio_client.dart';
import '../parser/json_parser.dart';
import '../utils/result.dart';

/// The primary entry point for all HTTP requests.
///
/// Every method automatically handles:
///   • Dio initialisation
///   • Base URL & default headers
///   • Bearer token injection (via [AuthInterceptor])
///   • JSON parsing to Dart models (via [ModelFactory] + [JsonParser])
///   • Error mapping to typed [ApiException] subclasses
///   • Request retries with exponential back-off (via [RetryInterceptor])
///   • Pretty request/response logging (via [LoggingInterceptor])
///   • Optional in-memory caching
///
/// ## Basic usage
///
/// ```dart
/// // Initialise once in main()
/// ApiConfig.init(baseUrl: 'https://api.example.com');
/// ModelFactory.register<User>((j) => User.fromJson(j));
///
/// // Use anywhere — no scaffolding needed.
/// final users = await Api.get<List<User>>('/users');
/// final user  = await Api.get<User>('/users/1');
/// await Api.post('/login', body: {'email': '...', 'password': '...'});
///
/// // Or use the safe variants to avoid try/catch at the call site:
/// final result = await Api.getSafe<User>('/users/1');
/// result.when(success: (u) => print(u.name), failure: (e) => print(e));
/// ```
class Api {
  Api._();

  // ─── GET ──────────────────────────────────────────────────────────────────

  /// Performs a GET request and parses the response to [T].
  ///
  /// Set [cache] to `true` to return a cached response when available and
  /// store the new response for subsequent calls.  Pass [cacheTtl] to
  /// override the default [ApiCache.defaultTtl] for this specific call.
  ///
  /// Throws an [ApiException] (or its subclass) on failure.
  static Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool cache = false,
    bool persistent = false,
    Duration? cacheTtl,
    Map<String, dynamic>? headers,
  }) async {
    final key = ApiCache.buildKey(path, query);

    if (cache) {
      final cachedData =
          await CacheManager.instance.get(key, persistent: persistent);
      if (cachedData != null) {
        return cachedData as T;
      }
    }

    final response = await _request<T>(
      method: 'GET',
      path: path,
      queryParameters: query,
      headers: headers,
    );

    if (cache) {
      await CacheManager.instance.set(
        key: key,
        value: response,
        ttl: cacheTtl ?? ApiCache.instance.defaultTtl,
        persistent: persistent,
      );
    }

    return response;
  }

  /// Like [get], but returns a [Result] instead of throwing.
  static Future<Result<T>> getSafe<T>(
    String path, {
    Map<String, dynamic>? query,
    bool cache = false,
    bool persistent = false,
    Duration? cacheTtl,
    Map<String, dynamic>? headers,
  }) =>
      _safe(() => get<T>(path,
          query: query,
          cache: cache,
          persistent: persistent,
          cacheTtl: cacheTtl,
          headers: headers));

  // ─── POST ─────────────────────────────────────────────────────────────────

  /// Performs a POST request and parses the response to [T].
  ///
  /// Throws an [ApiException] on failure.
  static Future<T> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _request<T>(
        method: 'POST',
        path: path,
        data: body,
        queryParameters: query,
        headers: headers,
      );

  /// Like [post], but returns a [Result] instead of throwing.
  static Future<Result<T>> postSafe<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _safe(() => post<T>(path, body: body, query: query, headers: headers));

  // ─── PUT ──────────────────────────────────────────────────────────────────

  /// Performs a PUT request and parses the response to [T].
  ///
  /// Throws an [ApiException] on failure.
  static Future<T> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _request<T>(
        method: 'PUT',
        path: path,
        data: body,
        queryParameters: query,
        headers: headers,
      );

  /// Like [put], but returns a [Result] instead of throwing.
  static Future<Result<T>> putSafe<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _safe(() => put<T>(path, body: body, query: query, headers: headers));

  // ─── PATCH ────────────────────────────────────────────────────────────────

  /// Performs a PATCH request and parses the response to [T].
  ///
  /// Throws an [ApiException] on failure.
  static Future<T> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _request<T>(
        method: 'PATCH',
        path: path,
        data: body,
        queryParameters: query,
        headers: headers,
      );

  /// Like [patch], but returns a [Result] instead of throwing.
  static Future<Result<T>> patchSafe<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _safe(() => patch<T>(path, body: body, query: query, headers: headers));

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// Performs a DELETE request.  The response body is ignored.
  ///
  /// Throws an [ApiException] on failure.
  static Future<void> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _request<void>(
        method: 'DELETE',
        path: path,
        data: body,
        queryParameters: query,
        headers: headers,
      );

  static Future<Result<void>> deleteSafe(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _safe(() => delete(path, body: body, query: query, headers: headers));

  // ─── ApiResponse variants ─────────────────────────────────────────────────

  /// Same as [get], but wraps the result in [ApiResponse].
  static Future<ApiResponse<T>> getResponse<T>(
    String path, {
    Map<String, dynamic>? query,
    bool cache = false,
    bool persistent = false,
    Duration? cacheTtl,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final data = await get<T>(path,
          query: query,
          cache: cache,
          persistent: persistent,
          cacheTtl: cacheTtl,
          headers: headers);
      return ApiResponse.success(data);
    } on ApiException catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Core request executor.  All public methods funnel through here.
  static Future<T> _request<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await DioClient.instance.dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
        ),
      );

      return JsonParser.parse<T>(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error: $e');
    }
  }

  /// Wraps a throwing [call] in a try/catch and returns a [Result].
  static Future<Result<T>> _safe<T>(Future<T> Function() call) async {
    try {
      return Result.success(await call());
    } on ApiException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(ApiException(message: e.toString()));
    }
  }
}
