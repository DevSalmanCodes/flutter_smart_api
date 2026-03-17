import 'package:flutter_smart_api/src/network/dio_client.dart';
import '../cache/hive_cache.dart';

/// Global configuration for the [flutter_smart_api] package.
///
/// Call [ApiConfig.init] once at app startup (typically in `main.dart`)
/// before making any API requests.
///
/// ```dart
/// void main() {
///   ApiConfig.init(
///     baseUrl: 'https://api.example.com',
///     timeout: Duration(seconds: 30),
///     defaultHeaders: {'Accept': 'application/json'},
///     retryAttempts: 3,
///     enableLogging: true,
///   );
///
///   runApp(const MyApp());
/// }
/// ```
class ApiConfig {
  ApiConfig._();

  static String _baseUrl = '';
  static Duration _timeout = const Duration(seconds: 30);
  static Map<String, dynamic> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static int _retryAttempts = 3;
  static bool _enableLogging = true;
  static String? _token;

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// The base URL for all requests (e.g. `https://api.example.com`).
  static String get baseUrl => _baseUrl;

  /// Connection / receive / send timeout applied to every request.
  static Duration get timeout => _timeout;

  /// Headers merged into every request.  The `Authorization` header is
  /// managed separately via [setToken] / [clearToken].
  static Map<String, dynamic> get defaultHeaders =>
      Map.unmodifiable(_defaultHeaders);

  /// Maximum number of retry attempts for failed network requests.
  static int get retryAttempts => _retryAttempts;

  /// Whether the built-in pretty logger interceptor is enabled.
  static bool get enableLogging => _enableLogging;

  /// Current bearer token, or `null` if no token has been set.
  static String? get token => _token;

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Initialises the package with the provided settings.
  ///
  /// Optionally await `ApiConfig.init()` if using `CacheManager` with
  /// disk-persistent caching to ensure the local database opens completely.
  ///
  /// Must be called **before** the first API request.
  /// Calling [init] again will reset the Dio instance.
  static Future<void> init({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    Map<String, dynamic>? defaultHeaders,
    int retryAttempts = 3,
    bool enableLogging = true,
  }) async {
    assert(baseUrl.isNotEmpty, 'baseUrl must not be empty.');
    _baseUrl = baseUrl;
    _timeout = timeout;
    _retryAttempts = retryAttempts;
    _enableLogging = enableLogging;

    if (defaultHeaders != null) {
      _defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...defaultHeaders,
      };
    }

    // Initialize the Hive Persistent caching DB
    await HiveCache.instance.init();

    // Reset and rebuild the Dio instance with the new config.
    DioClient.instance.reset();
  }

  // ─── Token management ─────────────────────────────────────────────────────

  /// Sets (or replaces) the bearer token injected into every request.
  ///
  /// ```dart
  /// // After a successful login:
  /// ApiConfig.setToken(response.accessToken);
  /// ```
  static void setToken(String token) {
    _token = token;
  }

  /// Removes the current token (e.g. on logout).
  static void clearToken() {
    _token = null;
  }

  // ─── Runtime header mutations ─────────────────────────────────────────────

  /// Adds or replaces a single header in [defaultHeaders].
  static void addHeader(String key, String value) {
    _defaultHeaders[key] = value;
  }

  /// Removes a header by [key].
  static void removeHeader(String key) {
    _defaultHeaders.remove(key);
  }
}
