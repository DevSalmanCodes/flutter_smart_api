import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A persistent disk cache implementation utilizing Hive.
/// 
/// Data is stored serialized as a Map containing the raw JSON
/// payload alongside an expiry timestamp.
class HiveCache {
  HiveCache._();

  static final HiveCache _instance = HiveCache._();

  /// Gets the global [HiveCache] instance.
  static HiveCache get instance => _instance;

  static const String _boxName = 'api_cache';
  Box<dynamic>? _box;

  /// Initializes the Hive database and opens the cache box.
  /// Must be called before any read / write operations.
  ///
  /// Provide [testDirectory] strictly when running under headless unit test suites.
  Future<void> init({String? testDirectory}) async {
    if (_box != null && _box!.isOpen) return;
    
    if (testDirectory != null) {
      Hive.init(testDirectory);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  /// Stores [value] under [key] on disk.
  /// The [value] must be JSON encodable (Lists, Maps, primitives).
  Future<void> set(String key, dynamic value, Duration ttl) async {
    if (_box == null) return; // Fail silently if uninitialized

    try {
      final expiryMs = DateTime.now().add(ttl).millisecondsSinceEpoch;
      final payload = {
        'data': jsonEncode(value),
        'expiry': expiryMs,
      };
      await _box!.put(key, payload);
    } catch (e) {
      debugPrint('HiveCache error during save: $e');
    }
  }

  /// Returns the cached value associated with [key] if it exists
  /// and has not expired. Returns `null` otherwise.
  Future<dynamic> get(String key) async {
    if (_box == null) return null;

    final entry = _box!.get(key);
    if (entry == null || entry is! Map) return null;

    final expiryMs = entry['expiry'] as int?;
    final jsonData = entry['data'] as String?;

    if (expiryMs == null || jsonData == null) {
      await remove(key);
      return null;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    if (DateTime.now().isAfter(expiresAt)) {
      // Data expired
      await remove(key);
      return null;
    }

    try {
      return jsonDecode(jsonData);
    } catch (e) {
      debugPrint('HiveCache error during read: $e');
      await remove(key);
      return null;
    }
  }

  /// Returns `true` if the [key] exists and is valid.
  Future<bool> has(String key) async {
    final value = await get(key);
    return value != null;
  }

  /// Removes the entry for [key] from disk.
  Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  /// Clears the entire Hive cache box.
  Future<void> clear() async {
    await _box?.clear();
  }
}
