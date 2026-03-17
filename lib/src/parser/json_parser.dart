import 'package:flutter_smart_api/src/core/api_exception.dart';
import 'package:flutter_smart_api/src/parser/model_factory.dart';

/// Parses raw JSON (Map or List) into a strongly-typed Dart value of type [T].
///
/// Supports:
/// - Primitive types (`String`, `int`, `double`, `bool`, `num`)
/// - `Map<String, dynamic>`
/// - Any model registered with [ModelFactory]
/// - `List<T>` where `T` is any registered model
///
/// ## How List<T> parsing works
///
/// Dart erases generic type parameters at runtime, so `List<Post>` looks
/// identical to `List<dynamic>` to the VM.  To work around this, [ModelFactory]
/// stores a typed list-parser closure keyed on the *runtime type token* of
/// `List<T>` captured at registration time.  [JsonParser] retrieves that
/// closure and invokes it, which gives back a correctly typed `List<Post>`.
class JsonParser {
  JsonParser._();

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Converts [json] into an instance of [T].
  ///
  /// When [parserOverride] is supplied it is called instead of the automatic
  /// type resolution logic, which lets callers handle uncommon shapes without
  /// subclassing [JsonParser]:
  ///
  /// ```dart
  /// Api.get<List<Post>>(
  ///   '/posts',
  ///   parser: (json) => (json as List)
  ///       .map((e) => Post.fromJson(e as Map<String, dynamic>))
  ///       .toList(),
  /// );
  /// ```
  ///
  /// Throws a [ParsingException] when conversion fails.
  static T parse<T>(dynamic json, {T Function(dynamic json)? parserOverride}) {
    try {
      if (parserOverride != null) return parserOverride(json);
      return _convert<T>(json);
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(
        message: 'Failed to parse response to $T: $e',
        data: json,
      );
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  static T _convert<T>(dynamic json) {
    // ── void / null ─────────────────────────────────────────────────────────
    if (T == Null || T.toString() == 'void') {
      return null as T;
    }

    // ── Primitive passthrough ───────────────────────────────────────────────
    if (T == String || T == int || T == double || T == bool || T == num) {
      if (json is T) return json;
      return _castPrimitive<T>(json);
    }

    // ── Dynamic / Object passthrough ────────────────────────────────────────
    if (T == dynamic || T == Object) {
      return json as T;
    }

    // ── Map<String, dynamic> ────────────────────────────────────────────────
    if (T == _typeOf<Map<String, dynamic>>()) {
      if (json is Map<String, dynamic>) return json as T;
      throw ParsingException(
        message:
            'Expected a JSON object for type $T but got ${json.runtimeType}.',
        data: json,
      );
    }

    // ── List<SomeModel> — use the registered typed list parser ───────────────
    //
    // ModelFactory.register<Post>(...) stores a closure that does:
    //   (jsonList) => jsonList.map<Post>((e) => Post.fromJson(e)).toList()
    //
    // The closure is keyed on <Post>[].runtimeType == List<Post>, so calling
    // listParserFor<List<Post>>() finds it without any string manipulation.
    final listParser = ModelFactory.listParserFor<T>();
    if (listParser != null) {
      if (json is! List) {
        throw ParsingException(
          message:
              'Expected a JSON array for type $T but got ${json.runtimeType}.',
          data: json,
        );
      }
      // listParser returns the correctly typed List<Post> (or List<X>).
      // The cast to T is safe here because the closure was registered with
      // the exact type token that T matched on.
      return listParser(json) as T;
    }

    // ── Registered single model ─────────────────────────────────────────────
    if (ModelFactory.isRegistered<T>()) {
      if (json is! Map<String, dynamic>) {
        throw ParsingException(
          message:
              'Expected a JSON object for type $T but got ${json.runtimeType}.',
          data: json,
        );
      }
      return ModelFactory.fromJson<T>(json);
    }

    // ── Fallback — straight cast (handles raw List/Map the caller owns) ─────
    return json as T;
  }

  static T _castPrimitive<T>(dynamic value) {
    if (T == int) return int.parse(value.toString()) as T;
    if (T == double) return double.parse(value.toString()) as T;
    if (T == bool) return (value.toString() == 'true') as T;
    if (T == String) return value.toString() as T;
    return value as T;
  }

  /// Captures the [Type] token for [T] at compile time.
  static Type _typeOf<T>() => T;
}
