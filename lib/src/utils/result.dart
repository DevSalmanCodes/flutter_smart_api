import 'package:flutter_smart_api/src/core/api_exception.dart';

/// A discriminated union representing either a [success] value of type [T]
/// or a [failure] with an [ApiException].
///
/// Inspired by Kotlin's `Result` and Rust's `Result<T, E>`.
///
/// ```dart
/// final result = await Api.getSafe<User>('/users/1');
/// result.when(
///   success: (user) => print(user.name),
///   failure: (error) => print(error.message),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result holding [exception].
  const factory Result.failure(ApiException exception) = Failure<T>;

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the data if [isSuccess], otherwise `null`.
  T? get dataOrNull => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => null,
      };

  /// Returns the error if [isFailure], otherwise `null`.
  ApiException? get errorOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.exception,
      };

  /// Executes [success] or [failure] based on the variant.
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) =>
      switch (this) {
        Success<T> s => success(s.data),
        Failure<T> f => failure(f.exception),
      };

  /// Transforms the data using [transform] if this is a [Success].
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success<T> s => Result.success(transform(s.data)),
        Failure<T> f => Result.failure(f.exception),
      };

  @override
  String toString() => switch (this) {
        Success<T> s => 'Result.success(${s.data})',
        Failure<T> f => 'Result.failure(${f.exception})',
      };
}

/// The successful variant of [Result].
final class Success<T> extends Result<T> {
  /// The successfully produced value.
  final T data;
  const Success(this.data);
}

/// The failed variant of [Result].
final class Failure<T> extends Result<T> {
  /// The exception that caused the failure.
  final ApiException exception;
  const Failure(this.exception);
}
