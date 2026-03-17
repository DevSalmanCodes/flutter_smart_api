<div align="center">

# 🚀 flutter_smart_api

**Eliminate 80% of your API boilerplate. One package. Zero friction.**

[![pub.dev](https://img.shields.io/pub/v/flutter_smart_api.svg)](https://pub.dev/packages/flutter_smart_api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Flutter 3.10+](https://img.shields.io/badge/Flutter-3.10+-54C5F8?logo=flutter)](https://flutter.dev)

</div>

---

## ✨ What is flutter_smart_api?

`flutter_smart_api` is a production-ready HTTP API layer for Flutter that takes care of everything you'd normally write by hand:

| Without `flutter_smart_api` | With `flutter_smart_api` |
|---|---|
| Initialise Dio | ✅ Done automatically |
| Configure base URL & headers | ✅ Done automatically |
| Inject `Authorization` header | ✅ Done automatically |
| `try/catch` every request | ✅ Done automatically |
| Map HTTP status codes to exceptions | ✅ Done automatically |
| Parse JSON → Dart model | ✅ Done automatically |
| Retry on network failure | ✅ Done automatically |
| Log requests & responses | ✅ Done automatically |
| In-memory cache | ✅ Built in |

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_smart_api: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## ⚡ Quick Start

### 1. Initialise (once, in `main.dart`)

```dart
import 'package:flutter_smart_api/flutter_smart_api.dart';

void main() {
  ApiConfig.init(
    baseUrl: 'https://api.example.com',
    timeout: Duration(seconds: 30),
    retryAttempts: 3,
    enableLogging: true,
  );

  runApp(const MyApp());
}
```

### 2. Register your models

```dart
ModelFactory.register<User>((json) => User.fromJson(json));
ModelFactory.register<Post>((json) => Post.fromJson(json));
```

### 3. Make requests — that's it 🎉

```dart
// GET a list
final users = await Api.get<List<User>>('/users');

// GET a single object
final user = await Api.get<User>('/users/1');

// POST with a body
await Api.post('/posts', body: {'title': 'Hello', 'body': 'World'});

// PUT / PATCH / DELETE
await Api.put('/users/1', body: updatedUser.toJson());
await Api.patch('/users/1', body: {'name': 'New Name'});
await Api.delete('/users/1');
```

---

## 🔧 Configuration

### `ApiConfig.init()`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `baseUrl` | `String` | **required** | Base URL for all requests |
| `timeout` | `Duration` | `30s` | Connection / receive / send timeout |
| `retryAttempts` | `int` | `3` | Max retry attempts on network failure |
| `enableLogging` | `bool` | `true` | Enable pretty request/response logs |
| `defaultHeaders` | `Map<String, dynamic>?` | `null` | Headers merged into every request |

### Runtime header mutations

```dart
ApiConfig.addHeader('X-App-Version', '2.0.0');
ApiConfig.removeHeader('X-App-Version');
```

---

## 🔑 Token / Authentication

Set the bearer token once after login — it is automatically injected into every subsequent request:

```dart
// After login
ApiConfig.setToken(response.accessToken);

// On logout
ApiConfig.clearToken();
```

The `Authorization: Bearer <token>` header is managed by the built-in `AuthInterceptor`.

---

## 🛡️ Error Handling

### Throwing style (try/catch)

```dart
try {
  final user = await Api.get<User>('/users/1');
} on UnauthorizedException catch (e) {
  // 401 / 403 — redirect to login
} on NetworkException catch (e) {
  // No internet / timeout
} on ServerException catch (e) {
  // 5xx
} on ParsingException catch (e) {
  // JSON ↔ model conversion failed
} on ApiException catch (e) {
  // All other API errors
}
```

### Safe style (no try/catch)

```dart
final result = await Api.getSafe<User>('/users/1');

result.when(
  success: (user) => print(user.name),
  failure: (error) => print(error.message),
);

// Or check manually
if (result.isSuccess) {
  final user = result.dataOrNull!;
}
```

### Exception hierarchy

```
ApiException
├── NetworkException     (timeout, no internet)
├── UnauthorizedException (401, 403)
├── ServerException      (5xx)
└── ParsingException     (JSON ↔ model)
```

---

## 🧩 Model Parsing

Your model only needs a standard `fromJson` constructor:

```dart
class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}
```

Register it once:

```dart
ModelFactory.register<User>((json) => User.fromJson(json));
```

Now both `User` and `List<User>` are resolved automatically:

```dart
final user  = await Api.get<User>('/users/1');          // single
final users = await Api.get<List<User>>('/users');       // list
```

---

## 💾 Caching

Enable in-memory caching per request:

```dart
// Cached with default TTL (5 minutes)
final users = await Api.get<List<User>>('/users', cache: true);

// Custom TTL
final users = await Api.get<List<User>>(
  '/users',
  cache: true,
  cacheTtl: Duration(minutes: 10),
);
```

### Cache management

```dart
// Invalidate a specific key
ApiCache.instance.invalidate('/users');

// Invalidate by prefix (e.g. all user-related keys)
ApiCache.instance.invalidatePrefix('/users');

// Clear everything
ApiCache.instance.clear();

// Change default TTL globally
ApiCache.instance.defaultTtl = Duration(minutes: 10);
```

---

## 🔁 Retry Logic

Retries happen automatically for network errors (timeouts, no internet).  
Configure the number of attempts in `ApiConfig.init`:

```dart
ApiConfig.init(
  baseUrl: 'https://api.example.com',
  retryAttempts: 3,  // will attempt up to 3 times with exponential back-off
);
```

Back-off schedule:
- Attempt 1 → 500 ms
- Attempt 2 → 1 000 ms
- Attempt 3 → 2 000 ms

**Note:** 4xx and 5xx responses are NOT retried — those are definitive failures.

---

## 🔍 Logging

Logging is enabled by default and prints colourised output to the debug console:

```
┌──── 🚀 REQUEST ─────────────────────────────────────
│ GET https://api.example.com/users
│ Headers: {Authorization: Bearer eyJ...}
└────────────────────────────────────────────────────
┌──── ✅ RESPONSE ────────────────────────────────────
│ 200 https://api.example.com/users
│ Body: [{id: 1, name: Alice, ...}, ...]
└────────────────────────────────────────────────────
```

Disable in production:

```dart
ApiConfig.init(
  baseUrl: 'https://api.example.com',
  enableLogging: false,
);
```

---

## 🎯 Result Type

Every request has a **safe** variant that returns `Result<T>` instead of throwing:

```dart
// Method naming convention: add 'Safe' suffix
Api.getSafe<T>(...)
Api.postSafe<T>(...)
Api.putSafe<T>(...)
Api.patchSafe<T>(...)
Api.deleteSafe(...)
```

`Result<T>` is a sealed class with two variants:

```dart
// Pattern matching (Dart 3)
switch (result) {
  case Success(:final data):  print(data);
  case Failure(:final exception): print(exception.message);
}

// when() helper
result.when(
  success: (data) => ...,
  failure: (error) => ...,
);

// map() transform
final names = result.map((users) => users.map((u) => u.name).toList());
```

---

## 🗂️ Architecture

```
lib/
├── flutter_smart_api.dart          # Barrel export
└── src/
    ├── core/
    │   ├── api_client.dart         # Api — the main public interface
    │   ├── api_config.dart         # Global configuration singleton
    │   ├── api_exception.dart      # Exception hierarchy
    │   └── api_response.dart       # ApiResponse<T> wrapper
    ├── network/
    │   ├── dio_client.dart         # Singleton Dio builder
    │   └── interceptors/
    │       ├── auth_interceptor.dart     # Bearer token injection
    │       ├── logging_interceptor.dart  # Pretty request/response logs
    │       └── retry_interceptor.dart    # Exponential back-off retry
    ├── parser/
    │   ├── json_parser.dart        # JSON → Dart model conversion
    │   └── model_factory.dart      # fromJson factory registry
    ├── cache/
    │   └── api_cache.dart          # In-memory TTL cache
    └── utils/
        └── result.dart             # Result<T> sealed type
```

---

## 🚀 Advanced Usage

### Per-request headers

```dart
final data = await Api.get<Map<String, dynamic>>(
  '/admin/stats',
  headers: {'X-Admin-Key': 'secret'},
);
```

### Query parameters

```dart
final users = await Api.get<List<User>>(
  '/users',
  query: {'page': 1, 'limit': 20, 'sort': 'name'},
);
```

### ApiResponse wrapper

```dart
final response = await Api.getResponse<User>('/users/1');
if (response.isSuccess) {
  final user = response.data!;
} else {
  final error = response.error!;
}
```

### Custom interceptors (advanced)

```dart
DioClient.instance.dio.interceptors.add(MyCustomInterceptor());
```

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
Made with ❤️ for Flutter developers who hate boilerplate.
</div>
