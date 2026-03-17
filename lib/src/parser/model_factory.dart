import 'package:flutter_smart_api/src/core/api_exception.dart';

/// Function signature for a JSON-to-model constructor.
typedef FromJsonFactory<T> = T Function(Map<String, dynamic> json);

/// Function signature for a list-of-models parser.
typedef ListParserFn = List Function(List json);

/// Global registry that maps Dart types to their `fromJson` constructors.
///
/// Register each model **once** at startup, then [JsonParser] and [Api]
/// will use it automatically whenever you request that type.
///
/// ```dart
/// ModelFactory.register<User>((json) => User.fromJson(json));
/// ModelFactory.register<Post>((json) => Post.fromJson(json));
///
/// // The package now handles List<User> and List<Post> automatically.
/// final users = await Api.get<List<User>>('/users');
/// ```
class ModelFactory {
  ModelFactory._();

  /// Plain model registry: `T` → `fromJson` factory.
  static final Map<Type, Function> _registry = {};

  /// List-element registry: `List<T>` → list parser function.
  static final Map<Type, List Function(List)> _listRegistry = {};

  // ─── Registration ──────────────────────────────────────────────────────────

  /// Registers a [factory] for type [T] and its corresponding `List<T>`.
  ///
  /// Throws an [AssertionError] in debug mode if [T] is already registered.
  static void register<T>(FromJsonFactory<T> factory) {
    assert(
      !_registry.containsKey(T),
      'ModelFactory: $T is already registered. '
      'Call ModelFactory.unregister<$T>() first if you want to replace it.',
    );
    _registry[T] = factory;

    // Also register the list parser so `List<T>` resolves automatically.
    _listRegistry[_listTypeOf<T>()] = (jsonList) =>
        jsonList.map((e) => factory(e as Map<String, dynamic>)).toList();
  }

  /// Removes [T] from both registries (useful in tests).
  static void unregister<T>() {
    _registry.remove(T);
    _listRegistry.remove(_listTypeOf<T>());
  }

  /// Clears all registrations (useful in tests).
  static void clear() {
    _registry.clear();
    _listRegistry.clear();
  }

  // ─── Lookup ────────────────────────────────────────────────────────────────

  /// Returns `true` if type [T] has been registered.
  static bool isRegistered<T>() => _registry.containsKey(T);

  /// Deserialises [json] to [T] using the registered factory.
  ///
  /// Throws [ParsingException] when no factory is found.
  static T fromJson<T>(Map<String, dynamic> json) {
    final factory = _registry[T];
    if (factory == null) {
      throw ParsingException(
        message: 'No factory registered for $T. '
            'Did you forget ModelFactory.register<$T>(...)?\n'
            'Registered types: ${_registry.keys.join(', ')}',
        data: json,
      );
    }
    return factory(json) as T;
  }

  /// Returns a list-parser function for type `List<T>`, or `null`.
  ///
  /// Used internally by [JsonParser] to parse list responses.
  static ListParserFn? listParserFor<T>() {
    return _listRegistry[T];
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Returns the [Type] token for `List<T>` at runtime.
  static Type _listTypeOf<T>() => <T>[].runtimeType;
}
