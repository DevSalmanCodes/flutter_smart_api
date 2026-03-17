import 'package:dio/dio.dart';

/// Base class for all exceptions thrown by [flutter_smart_api].
///
/// Every subclass carries a human-readable [message], an optional
/// HTTP [statusCode], and the raw [data] from the response body.
class ApiException implements Exception {
  /// Human-readable description of the error.
  final String message;

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// Raw response body, if available.
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  /// Maps a [DioException] to the most specific [ApiException] subclass.
  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timed out. Please check your internet.',
          statusCode: dioError.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message:
              'No internet connection. Please check your network settings.',
        );

      case DioExceptionType.badResponse:
        return ApiException.fromStatusCode(
          statusCode: dioError.response?.statusCode ?? 0,
          data: dioError.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'The request was cancelled.',
          statusCode: dioError.response?.statusCode,
        );

      default:
        return ApiException(
          message: dioError.message ?? 'An unexpected error occurred.',
          statusCode: dioError.response?.statusCode,
          data: dioError.response?.data,
        );
    }
  }

  /// Maps an HTTP [statusCode] to the most specific [ApiException] subclass.
  factory ApiException.fromStatusCode({
    required int statusCode,
    dynamic data,
  }) {
    final message = _extractMessage(data);

    if (statusCode == 401) {
      return UnauthorizedException(
          message: message ?? 'Unauthorised.', data: data);
    }
    if (statusCode == 403) {
      return UnauthorizedException(
          message: message ?? 'Forbidden.', statusCode: 403, data: data);
    }
    if (statusCode >= 500) {
      return ServerException(
          message: message ?? 'Server error ($statusCode).',
          statusCode: statusCode,
          data: data);
    }
    if (statusCode == 404) {
      return ApiException(
          message: message ?? 'Resource not found.',
          statusCode: statusCode,
          data: data);
    }
    if (statusCode == 422) {
      return ApiException(
          message: message ?? 'Validation error.',
          statusCode: statusCode,
          data: data);
    }

    return ApiException(
      message: message ?? 'Request failed with status $statusCode.',
      statusCode: statusCode,
      data: data,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    }
    return null;
  }

  @override
  String toString() => 'ApiException(status: $statusCode, message: "$message")';
}

// ─── Specific Exceptions ───────────────────────────────────────────────────

/// Thrown when the device cannot reach the server (no internet / timeout).
class NetworkException extends ApiException {
  const NetworkException(
      {required super.message, super.statusCode, super.data});

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the server responds with a 401 or 403 status code.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
    super.data,
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Thrown when the server responds with a 5xx status code.
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.data,
  });

  @override
  String toString() => 'ServerException(status: $statusCode): $message';
}

/// Thrown when JSON cannot be parsed into the requested model type.
class ParsingException extends ApiException {
  const ParsingException({required super.message, super.data});

  @override
  String toString() => 'ParsingException: $message';
}
