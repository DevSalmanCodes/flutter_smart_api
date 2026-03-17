/// Flutter Smart API — a production-ready API layer that eliminates
/// repetitive boilerplate in Flutter applications.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_smart_api/flutter_smart_api.dart';
///
/// // 1. Initialize once (e.g. in main.dart)
/// ApiConfig.init(
///   baseUrl: 'https://api.example.com',
///   timeout: Duration(seconds: 30),
/// );
///
/// // 2. Register model factories
/// ModelFactory.register<User>((json) => User.fromJson(json));
///
/// // 3. Make requests — that's it!
/// final users = await Api.get<List<User>>('/users');
/// final user  = await Api.get<User>('/users/1');
/// await Api.post('/login', body: loginData);
/// ```
library flutter_smart_api;

// Core
export 'src/core/api_client.dart';
export 'src/core/api_config.dart';
export 'src/core/api_exception.dart';
export 'src/core/api_response.dart';

// Parser
export 'src/parser/json_parser.dart';
export 'src/parser/model_factory.dart';

// Cache
export 'src/cache/api_cache.dart';
export 'src/cache/cache_manager.dart';

// Utils
export 'src/utils/result.dart';
