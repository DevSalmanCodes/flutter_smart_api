
/// A simple in-memory cache with optional TTL (time-to-live) per entry.
///
/// Used by [Api.get] when `cache: true` is passed.
///
/// The cache is keyed by a composite of the request path + query parameters,
/// so identical requests return the cached value instead of hitting the network.
class ApiCache {
  ApiCache._();

  static final ApiCache _instance = ApiCache._();

  /// The global [ApiCache] instance.
  static ApiCache get instance => _instance;

  final Map<String, _CacheEntry> _store = {};

  /// Default time-to-live for a cached value.
  Duration defaultTtl = const Duration(minutes: 5);

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Stores [value] under [key] with an optional [ttl].
  void set(String key, dynamic value, {Duration? ttl}) {
    _store[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  /// Returns the cached value associated with [key], or `null` if:
  /// - the key does not exist, or
  /// - the entry has expired (expired entries are evicted on read).
  dynamic get(String key) {
    final entry = _store[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Returns `true` if [key] is cached and not expired.
  bool has(String key) => get(key) != null;

  /// Removes the entry for [key].
  void invalidate(String key) => _store.remove(key);

  /// Removes all entries whose keys begin with [prefix].
  ///
  /// Useful for invalidating a whole resource collection:
  /// ```dart
  /// ApiCache.instance.invalidatePrefix('/users');
  /// ```
  void invalidatePrefix(String prefix) {
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Clears the entire cache.
  void clear() => _store.clear();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Builds a cache key from a [path] and optional [query] parameters.
  static String buildKey(
    String path, [
    Map<String, dynamic>? query,
  ]) {
    if (query == null || query.isEmpty) return path;
    final sorted = Map.fromEntries(
      query.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final queryString =
        sorted.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$queryString';
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  const _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
