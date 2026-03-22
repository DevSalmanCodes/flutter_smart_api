import 'dart:async';

import 'package:flutter_smart_api/src/cache/api_cache.dart';
import 'package:flutter_smart_api/src/cache/hive_cache.dart';

/// Orchestrates caching strategies prioritizing Memory -> Disk caching.
///
/// Ensures tight synchronization between [ApiCache] (RAM) and [HiveCache] (Disk).
class CacheManager {
  CacheManager._();

  static final CacheManager _instance = CacheManager._();

  /// The global [CacheManager] orchestrator instance.
  static CacheManager get instance => _instance;

  /// Retrieves data by first checking RAM. If missing but disk caching
  /// is enabled via [persistent], it falls back to parsing Hive records.
  ///
  /// Returns `null` if the data does not exist or has expired.
  Future<dynamic> get(String key, {bool persistent = false}) async {
    // 1. Check ultra-fast RAM cache
    final memoryData = ApiCache.instance.get(key);
    if (memoryData != null) {
      return memoryData;
    }

    // 2. Check Disk Cache if requested
    if (persistent) {
      final diskData = await HiveCache.instance.get(key);
      if (diskData != null) {
        // Hydrate RAM cache so subsequent identical requests are instantaneous
        ApiCache.instance.set(key, diskData);
        return diskData;
      }
    }

    return null;
  }

  /// Stores [value] securely into memory, and additionally writes to disk
  /// if [persistent] is `true`.
  Future<void> set({
    required String key,
    required dynamic value,
    required Duration ttl,
    bool persistent = false,
  }) async {
    // 1. Always store to memory first
    ApiCache.instance.set(key, value, ttl: ttl);

    // 2. Persist to Disk asynchronously
    if (persistent) {
      // Do not await this so we don't block the caller thread unnecessarily
      unawaited(HiveCache.instance.set(key, value, ttl));
    }
  }

  /// Invalidates an entry globally spanning across memory and disk.
  Future<void> invalidate(String key) async {
    ApiCache.instance.invalidate(key);
    await HiveCache.instance.remove(key);
  }

  /// Atomically drops all tracked API data across RAM and Disk architectures.
  Future<void> clearAll() async {
    ApiCache.instance.clear();
    await HiveCache.instance.clear();
  }
}
