import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_smart_api/src/cache/api_cache.dart';
import 'package:flutter_smart_api/src/cache/cache_manager.dart';
import 'package:flutter_smart_api/src/cache/hive_cache.dart';

void main() {
  setUpAll(() async {
    // Setup temporary hive box for tests
    final directory = Directory.systemTemp.createTempSync('hive_tests');
    await HiveCache.instance.init(testDirectory: directory.path);
  });

  tearDownAll(() async {
    await HiveCache.instance.clear();
  });

  tearDown(() async {
    // Clear both configs after each run
    await CacheManager.instance.clearAll();
  });

  group('CacheManager & HiveCache ->', () {
    test('1. Saves to both Memory and Disk when persistent is true', () async {
      await CacheManager.instance.set(
        key: '/users',
        value: {'id': 1, 'name': 'Salman'},
        ttl: const Duration(minutes: 5),
        persistent: true,
      );

      // Verify RAM
      expect(ApiCache.instance.has('/users'), isTrue);
      // Verify Disk
      expect(await HiveCache.instance.has('/users'), isTrue);

      final val = await CacheManager.instance.get('/users', persistent: true);
      expect(val['name'], 'Salman');
    });

    test('2. Saves only to Memory when persistent is false', () async {
      await CacheManager.instance.set(
        key: '/posts',
        value: {'id': 101},
        ttl: const Duration(minutes: 5),
        persistent: false,
      );

      expect(ApiCache.instance.has('/posts'), isTrue);
      expect(await HiveCache.instance.has('/posts'), isFalse);
    });

    test('3. Disk Hydration - missing from RAM but exists on Disk', () async {
      // Step A: Store with persistent true
      await CacheManager.instance.set(
        key: '/hydration',
        value: {'hydrated': true},
        ttl: const Duration(minutes: 5),
        persistent: true,
      );

      // Step B: Wipe RAM strictly imitating app restart
      ApiCache.instance.clear();
      expect(ApiCache.instance.has('/hydration'), isFalse);

      // Step C: Fetch via Cache Manager with persistent querying
      final result = await CacheManager.instance.get('/hydration', persistent: true);
      
      expect(result, isNotNull);
      expect(result['hydrated'], isTrue);
      
      // Verification: The fetch from Disk should have hydrated it back into RAM
      expect(ApiCache.instance.has('/hydration'), isTrue);
    });

    test('4. Expiration check - ensures disk data deletes post-ttl', () async {
      await CacheManager.instance.set(
        key: '/expired',
        value: {'status': 'old'},
        ttl: const Duration(milliseconds: 50),
        persistent: true,
      );

      expect(await HiveCache.instance.has('/expired'), isTrue);

      // Wait out the TTL
      await Future.delayed(const Duration(milliseconds: 100));

      final value = await CacheManager.instance.get('/expired', persistent: true);
      expect(value, isNull);

      // Value should be eradicated from disk upon reading an expired token
      expect(await HiveCache.instance.has('/expired'), isFalse);
    });
  });
}
