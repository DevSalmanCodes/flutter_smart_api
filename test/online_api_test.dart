// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_api/flutter_smart_api.dart';

class TestUser {
  final int id;
  final String name;

  TestUser({required this.id, required this.name});

  factory TestUser.fromJson(Map<String, dynamic> json) {
    return TestUser(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

void main() {
  setUpAll(() {
    ApiConfig.init(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      enableLogging: true,
      // Test shorter timeout
      timeout: const Duration(seconds: 10),
    );
    ModelFactory.register<TestUser>((json) => TestUser.fromJson(json));
  });

  group('Online Fake API Critical Tests', () {
    test('1. GET request for List of dynamic json should succeed', () async {
      final result = await Api.getSafe<List<dynamic>>('/users');
      
      result.when(
        success: (data) {
          expect(data, isNotEmpty);
          expect(data.first['id'], isNotNull);
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('2. GET request for specific User model should succeed', () async {
      final result = await Api.getSafe<TestUser>('/users/1');
      
      result.when(
        success: (user) {
          expect(user.id, 1);
          expect(user.name, isNotEmpty);
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('3. POST request should succeed', () async {
      final requestBody = {'title': 'foo', 'body': 'bar', 'userId': 1};

      final result = await Api.postSafe<Map<String, dynamic>>('/posts', body: requestBody);
      
      result.when(
        success: (response) {
          expect(response['id'], isNotNull);
          expect(response['title'], 'foo');
        },
        failure: (e) => fail('API request failed: ${e.message}'),
      );
    });

    test('4. 404 Not Found error handling', () async {
      final result = await Api.getSafe<dynamic>('/invalid-endpoint-12345');
      
      result.when(
        success: (_) => fail('Should have failed with 404'),
        failure: (e) {
          expect(e.statusCode, 404);
          print('✅ Successfully caught 404: ${e.message}');
        },
      );
    });

    test('5. Query Parameters formatting', () async {
      final result = await Api.getSafe<List<dynamic>>(
        '/posts',
        query: {'userId': 1},
      );
      
      result.when(
        success: (posts) {
          expect(posts, isNotEmpty);
          // Verify all returned posts belong to userId 1
          for (var post in posts) {
            expect(post['userId'], 1);
          }
          print('✅ Query parameters correctly applied');
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('6. Custom Headers override', () async {
      final result = await Api.getSafe<dynamic>(
        '/users/1',
        headers: {'X-Custom-Test-Header': 'Hello API'},
      );
      
      result.when(
        success: (user) {
          expect(user, isNotNull);
          print('✅ Request with custom headers succeeded');
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('7. Token Injection (Auth Interceptor)', () async {
      // Set a dummy token
      ApiConfig.setToken('dummy_test_token_123');
      
      // Request should include Authorization: Bearer dummy_test_token_123
      final result = await Api.getSafe<TestUser>('/users/2');
      
      result.when(
        success: (user) {
          expect(user.id, 2);
          print('✅ Request with injected Bearer token succeeded');
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
      
      // Cleanup token
      ApiConfig.clearToken();
    });

    test('8. PUT/PATCH update endpoints', () async {
      final updateBody = {'id': 1, 'title': 'updated title'};
      
      // JSONPlaceholder supports PUT/PATCH but fakes the response
      final result = await Api.putSafe<Map<String, dynamic>>('/posts/1', body: updateBody);
      
      result.when(
        success: (response) {
          expect(response['id'], 1);
          print('✅ PUT update succeeded');
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('9. DELETE request', () async {
      final result = await Api.deleteSafe('/posts/1');
      
      result.when(
        success: (_) {
          print('✅ DELETE request succeeded');
        },
        failure: (e) => fail('API Error: ${e.message}'),
      );
    });

    test('10. Concurrent Parallel Requests', () async {
      print('Starting 5 parallel requests...');
      
      final futures = [
        Api.getSafe<TestUser>('/users/1'),
        Api.getSafe<TestUser>('/users/2'),
        Api.getSafe<TestUser>('/users/3'),
        Api.getSafe<TestUser>('/users/4'),
        Api.getSafe<TestUser>('/users/5'),
      ];
      
      final results = await Future.wait(futures);
      
      for (var i = 0; i < results.length; i++) {
        results[i].when(
          success: (user) {
            expect(user.id, i + 1);
          },
          failure: (e) => fail('Parallel request ${i + 1} failed: ${e.message}'),
        );
      }
      print('✅ 5 parallel requests completed successfully');
    });
  });
}

