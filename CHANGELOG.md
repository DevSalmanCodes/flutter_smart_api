# Changelog

All notable changes to `flutter_smart_api` will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-17

### Added
- Initial release of `flutter_smart_api`.
- `Api` static class with `get`, `post`, `put`, `patch`, `delete` methods.
- Safe variants (`getSafe`, `postSafe`, etc.) that return `Result<T>` instead of throwing.
- `ApiConfig.init()` for global configuration (base URL, timeout, retry attempts, logging).
- `ApiConfig.setToken()` / `clearToken()` for dynamic bearer-token management.
- `AuthInterceptor` — automatically injects the bearer token into every request.
- `LoggingInterceptor` — pretty-print request / response / error logging.
- `RetryInterceptor` — exponential back-off retry for network failures.
- `ModelFactory` — type-safe registry for `fromJson` constructors. Automatically handles `List<T>`.
- `JsonParser` — converts raw JSON to Dart models using `ModelFactory`.
- `ApiCache` — in-memory TTL cache with prefix invalidation.
- Custom exception hierarchy: `ApiException`, `NetworkException`, `UnauthorizedException`, `ServerException`, `ParsingException`.
- `Result<T>` sealed type with `Success`/`Failure` variants, `map()` and `when()` helpers.
- `ApiResponse<T>` wrapper (alternative to `Result`).
- Example app demonstrating all features against JSONPlaceholder.
- Comprehensive unit tests.
