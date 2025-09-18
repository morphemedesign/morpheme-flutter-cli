import 'package:morpheme_cli/helper/helper.dart';

/// Resolves type information for code generation
///
/// This resolver handles type detection, conversion, and validation
/// for various data types in the Json2Dart generation process.
class TypeResolver {
  final List<ModelClassName> _classNames = [];

  /// Gets the appropriate Dart type for a given value
  ///
  /// [key] - Property key name
  /// [value] - Property value
  /// [suffix] - Class suffix for complex types
  /// [parent] - Parent class name
  /// Returns the Dart type string
  String getTypeVariable(
    String key,
    dynamic value,
    String suffix,
    String parent,
  ) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';

    if (value is Map) {
      return ModelClassNameHelper.getClassName(
        _classNames,
        suffix,
        key.pascalCase,
        false,
        false,
        parent,
      );
    }

    if (value is List) {
      if (value.isNotEmpty) {
        return 'List<${getTypeVariable(key, value.first, suffix, parent)}>';
      }
      return 'List<dynamic>';
    }

    if (value is String) {
      if (_isDateTime(value)) {
        return 'DateTime';
      }
      return 'String';
    }

    return 'dynamic';
  }

  /// Checks if a string value represents a DateTime
  bool _isDateTime(String value) {
    return RegExp(
            r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
        .hasMatch(value);
  }

  /// Gets appropriate serialization format for a variable
  String getVariableToMapFormat(
    String key,
    dynamic value,
    String dateFormat,
  ) {
    final variable = key.camelCase;

    if (value is Map) {
      return '$variable?.toMap()';
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return '$variable?.map((e) => e.toMap(),).toList()';
    }

    if (value is String && _isDateTime(value)) {
      return '$variable?$dateFormat';
    }

    return variable;
  }

  /// Gets appropriate deserialization format for a variable
  String getVariableFromMapFormat(
    String key,
    dynamic value,
    String suffix,
    String parent,
  ) {
    final variable = "map['$key']";

    if (value is int) {
      return "int.tryParse($variable?.toString() ?? '')";
    }

    if (value is double) {
      return "double.tryParse($variable?.toString() ?? '')";
    }

    if (value is bool) {
      return variable;
    }

    if (value is Map) {
      final className = ModelClassNameHelper.getClassName(
        _classNames,
        suffix,
        key.pascalCase,
        false,
        false,
        parent,
      );
      return '$variable == null ? null : $className.fromMap($variable)';
    }

    if (value is List && value.isNotEmpty) {
      if (value.first is Map) {
        final className = ModelClassNameHelper.getClassName(
          _classNames,
          suffix,
          key.pascalCase,
          false,
          false,
          parent,
        );
        return '$variable is List ? '
            'List.from(($variable as List).where((element) => element != null)'
            '.map((e) => $className.fromMap(e))) : null';
      } else {
        return _handlePrimitiveList(variable, value.first);
      }
    }

    if (value is String && _isDateTime(value)) {
      return "DateTime.tryParse($variable ?? '')";
    }

    return variable;
  }

  /// Handles primitive list deserialization
  String _handlePrimitiveList(String variable, dynamic firstElement) {
    if (firstElement is int) {
      return '$variable is List ? '
          'List.from(($variable as List).where((element) => element != null)'
          '.map((e) => int.tryParse(e.toString()) ?? 0)) : null';
    }

    if (firstElement is double) {
      return '$variable is List ? '
          'List.from(($variable as List).where((element) => element != null)'
          '.map((e) => double.tryParse(e.toString()) ?? 0.0)) : null';
    }

    return '$variable is List ? List.from($variable) : null';
  }

  /// Clears internal class name tracking
  void clearClassNames() {
    _classNames.clear();
  }

  /// Gets the current class names for external use
  List<ModelClassName> get classNames => List.unmodifiable(_classNames);
}
