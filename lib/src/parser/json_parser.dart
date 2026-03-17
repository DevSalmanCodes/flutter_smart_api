import 'package:flutter_smart_api/src/core/api_exception.dart';
import 'package:flutter_smart_api/src/parser/model_factory.dart';

/// Parses raw JSON (Map or List) into a strongly-typed Dart value of type [T].
///
/// Supports:
/// - Primitive types (`String`, `int`, `double`, `bool`)
/// - `Map<String, dynamic>`
/// - Any registered model (`ModelFactory.register<T>(...)`)
/// - `List<T>` where `T` is any registered model
class JsonParser {
  JsonParser._();

  /// Converts [json] into an instance of [T].
  ///
  /// Throws a [ParsingException] when conversion fails.
  static T parse<T>(dynamic json) {
    try {
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

  static T _convert<T>(dynamic json) {
    // ── void / null ────────────────────────────────────────────────────────
    if (T == Null || T.toString() == 'void') {
      return null as T;
    }

    // ── Primitive passthrough ──────────────────────────────────────────────
    if (T == String || T == int || T == double || T == bool || T == num) {
      if (json is T) return json;
      return _castPrimitive<T>(json);
    }

    // ── Dynamic / Object passthrough ──────────────────────────────────────
    if (T == dynamic || T == Object) {
      return json as T;
    }

    // ── Map<String, dynamic> ──────────────────────────────────────────────
    if (json is Map<String, dynamic> && T == _typeOf<Map<String, dynamic>>()) {
      return json as T;
    }

    // ── List — try the registered list parser first ───────────────────────
    final listParser = ModelFactory.listParserFor<T>();
    if (listParser != null) {
      if (json is! List) {
        throw ParsingException(
          message:
              'Expected a JSON array for type $T but got ${json.runtimeType}.',
          data: json,
        );
      }
      return listParser(json) as T;
    }

    // ── Registered single model ───────────────────────────────────────────
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

    // ── Fallback cast ─────────────────────────────────────────────────────
    return json as T;
  }

  static T _castPrimitive<T>(dynamic value) {
    if (T == int) return int.parse(value.toString()) as T;
    if (T == double) return double.parse(value.toString()) as T;
    if (T == bool) return (value.toString() == 'true') as T;
    if (T == String) return value.toString() as T;
    return value as T;
  }

  /// Helper to capture a generic type token.
  static Type _typeOf<T>() => T;
}
