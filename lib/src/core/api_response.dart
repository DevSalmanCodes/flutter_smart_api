import 'package:flutter_smart_api/src/core/api_exception.dart';
import 'package:flutter_smart_api/src/utils/result.dart';

/// A lightweight wrapper around a successful [data] value and an
/// optional [ApiException] error returned by every [Api] method.
///
/// Use [Result] when you want to handle errors inline without try/catch:
///
/// ```dart
/// final result = await Api.getSafe<User>('/users/1');
/// if (result.isSuccess) {
///   print(result.data);
/// } else {
///   print(result.error);
/// }
/// ```
class ApiResponse<T> {
  /// The parsed response data. `null` when [isSuccess] is `false`.
  final T? data;

  /// The error that occurred. `null` when [isSuccess] is `true`.
  final ApiException? error;

  const ApiResponse._({this.data, this.error});

  /// Creates a successful response.
  factory ApiResponse.success(T data) => ApiResponse._(data: data);

  /// Creates a failed response.
  factory ApiResponse.failure(ApiException error) =>
      ApiResponse._(error: error);

  /// Whether this response contains valid data.
  bool get isSuccess => error == null;

  /// Whether this response contains an error.
  bool get isFailure => error != null;

  /// Converts to a [Result] type.
  Result<T> toResult() {
    if (isSuccess) return Result.success(data as T);
    return Result.failure(error!);
  }

  @override
  String toString() =>
      isSuccess ? 'ApiResponse.success($data)' : 'ApiResponse.failure($error)';
}
