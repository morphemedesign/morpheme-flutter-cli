import 'package:morpheme_cli/helper/helper.dart';

import 'base_code_generator.dart';

/// Generates Dart model classes for API responses
///
/// This generator creates model classes for API response handling,
/// with built-in JSON serialization and deserialization support.
class ResponseModelGenerator extends BaseCodeGenerator {
  final List<ModelClassName> _listClassName = [];
  final String _responseDateFormat;

  ResponseModelGenerator({
    required String responseDateFormat,
  }) : _responseDateFormat = responseDateFormat;

  /// Generates a complete response model file
  ///
  /// [className] - Main class name
  /// [data] - JSON data structure
  /// Returns the complete file content
  String generateResponseModel(
    String className,
    Map<String, dynamic> data,
  ) {
    _listClassName.clear();

    String imports = '''import 'dart:convert';

import 'package:core/core.dart';

''';

    final classContent = generateClass(className, 'Response', '', data, true);
    return imports + classContent;
  }

  @override
  String generateClass(
    String suffix,
    String name,
    String parent,
    Map<String, dynamic>? map, [
    bool isRoot = false,
  ]) {
    if (map == null) return '';

    final apiClassName = ModelClassNameHelper.getClassName(
      _listClassName,
      suffix,
      name,
      isRoot,
      true,
      parent,
    );

    final classContent = '''class $apiClassName extends Equatable {
  ${generateConstructor(apiClassName, map)}

  ${_generateFromMap(apiClassName, map, suffix, apiClassName)}

  factory $apiClassName.fromJson(String source) =>
      $apiClassName.fromMap(json.decode(source));

  ${_generateTypeData(map, suffix, apiClassName)}

  ${_generateToMap(map)}

  String toJson() => json.encode(toMap());

  ${generateProps(map)}
}

${_generateNestedClasses(map, suffix, apiClassName)}''';

    return classContent;
  }

  /// Generates a complete response model file
  ///
  /// [className] - Main class name
  /// [data] - JSON data structure
  /// Returns the complete file content
  String generateExtraModel(
    String className,
    Map<String, dynamic> data,
  ) {
    _listClassName.clear();

    String imports = '''import 'dart:convert';

import 'package:core/core.dart';

''';

    final classContent = generateExtraClass(className, 'Extra', '', data, true);
    return imports + classContent;
  }

  String generateExtraClass(
    String suffix,
    String name,
    String parent,
    Map<String, dynamic>? map, [
    bool isRoot = false,
  ]) {
    if (map == null) return '';

    String apiClassName = ModelClassNameHelper.getClassName(
      _listClassName,
      suffix,
      name,
      isRoot,
      true,
      parent,
    );

    apiClassName = '${apiClassName.replaceAll('Extra', '')}Extra';

    final classContent = '''class $apiClassName extends Equatable {
  ${generateConstructor(apiClassName, map)}

  ${_generateFromExtraMap(apiClassName, map, suffix, apiClassName)}

  factory $apiClassName.fromJson(String source) =>
      $apiClassName.fromMap(json.decode(source));

  ${_generateTypeExtraData(map, suffix, apiClassName)}

  ${_generateToMap(map)}

  String toJson() => json.encode(toMap());

  ${generateProps(map)}
}

${_generateNestedExtraClasses(map, suffix, apiClassName)}''';

    return classContent;
  }

  /// Generates fromMap factory constructor
  String _generateFromMap(
    String className,
    Map<String, dynamic> map,
    String suffix,
    String parent,
  ) {
    final variables = map.keys;

    return '''factory $className.fromMap(Map<String, dynamic> map,) {
    return ${variables.isEmpty ? 'const' : ''} $className(
      ${variables.map((e) => "${e.toString().camelCase}: ${_getVariableFromMap(e, map[e], suffix, parent)}").join(',      \n')}${variables.isNotEmpty ? ',' : ''}
    );
  }''';
  }

  /// Generates fromMap factory constructor
  String _generateFromExtraMap(
    String className,
    Map<String, dynamic> map,
    String suffix,
    String parent,
  ) {
    final variables = map.keys;

    return '''factory $className.fromMap(Map<String, dynamic> map,) {
    return ${variables.isEmpty ? 'const' : ''} $className(
      ${variables.map((e) => "${e.toString().camelCase}: ${_getVariableFromExtraMap(e, map[e], suffix, parent)}").join(',      \n')}${variables.isNotEmpty ? ',' : ''}
    );
  }''';
  }

  /// Generates type definitions for response model
  String _generateTypeData(
    Map<String, dynamic> map,
    String suffix,
    String parent,
  ) {
    final variables = map.keys;

    String result = '';
    for (final variable in variables) {
      final type = getTypeVariable(
          variable, map[variable], suffix, _listClassName, parent);
      final isNullable = type != 'dynamic' ? '?' : '';
      result += '  final $type$isNullable ${variable.toString().camelCase};\n';
    }

    return result;
  }

  String _generateTypeExtraData(
    Map<String, dynamic> map,
    String suffix,
    String parent,
  ) {
    final variables = map.keys;

    String result = '';
    for (final variable in variables) {
      final type = getTypeExtraVariable(
          variable, map[variable], suffix, _listClassName, parent);
      final isNullable = type != 'dynamic' ? '?' : '';
      result += '  final $type$isNullable ${variable.toString().camelCase};\n';
    }

    return result;
  }

  /// Generates toMap method for response serialization
  String _generateToMap(Map<String, dynamic> map) {
    final variables = map.keys;

    return '''Map<String, dynamic> toMap() {
    return {
      ${variables.map((e) => "'${e.toString()}': ${_getVariableToMap(e, map[e])}").join(',      \n')}${variables.isNotEmpty ? ',' : ''}
    };
  }''';
  }

  /// Gets the appropriate deserialization format for response variables
  String _getVariableFromMap(
      String key, dynamic value, String suffix, String parent) {
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
        _listClassName,
        suffix,
        key.pascalCase,
        false,
        false,
        parent,
      );
      final data = '$className.fromMap($variable,)';
      return '$variable == null ? null : $data';
    }

    if (value is List && value.isNotEmpty) {
      if (value.first is Map) {
        final className = ModelClassNameHelper.getClassName(
          _listClassName,
          suffix,
          key.pascalCase,
          false,
          false,
          parent,
        );
        final data =
            'List.from(($variable as List).where((element) => element != null).map((e) => $className.fromMap(e)),)';
        return '$variable is List ? $data : null';
      } else {
        return _handlePrimitiveList(variable, value.first);
      }
    }

    if (value is String && _isDateTime(value)) {
      return "DateTime.tryParse($variable ?? '')";
    }

    return variable;
  }

  /// Gets the appropriate deserialization format for response variables
  String _getVariableFromExtraMap(
      String key, dynamic value, String suffix, String parent) {
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
      String className = ModelClassNameHelper.getClassName(
        _listClassName,
        suffix,
        key.pascalCase,
        false,
        false,
        parent,
      );
      className = '${className.replaceAll('Extra', '')}Extra';

      final data = '$className.fromMap($variable,)';
      return '$variable == null ? null : $data';
    }

    if (value is List && value.isNotEmpty) {
      if (value.first is Map) {
        String className = ModelClassNameHelper.getClassName(
          _listClassName,
          suffix,
          key.pascalCase,
          false,
          false,
          parent,
        );
        className = '${className.replaceAll('Extra', '')}Extra';

        final data =
            'List.from(($variable as List).where((element) => element != null).map((e) => $className.fromMap(e)),)';
        return '$variable is List ? $data : null';
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
      return '$variable is List ? List.from(($variable as List).where((element) => element != null).map((e) => int.tryParse(e.toString()) ?? 0),) : null';
    }

    if (firstElement is double) {
      return '$variable is List ? List.from(($variable as List).where((element) => element != null).map((e) => double.tryParse(e.toString()) ?? 0),) : null';
    }

    return '$variable is List ? List.from($variable) : null';
  }

  /// Gets the appropriate serialization format for response variables
  String _getVariableToMap(String key, dynamic value) {
    final variable = key.camelCase;

    if (value is Map) {
      return '$variable?.toMap()';
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return '$variable?.map((e) => e.toMap(),).toList()';
    }

    if (value is String && _isDateTime(value)) {
      return '$variable?$_responseDateFormat';
    }

    return variable;
  }

  /// Generates nested classes for complex objects
  String _generateNestedClasses(
      Map<String, dynamic> map, String suffix, String parent) {
    final nestedClasses = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        nestedClasses.add(generateClass(
          suffix,
          key.toString().pascalCase,
          parent,
          value,
          false,
        ));
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        nestedClasses.add(generateClass(
          suffix,
          key.toString().pascalCase,
          parent,
          value.first,
          false,
        ));
      }
    }

    return nestedClasses.join('\n');
  }

  /// Generates nested classes for complex objects
  String _generateNestedExtraClasses(
      Map<String, dynamic> map, String suffix, String parent) {
    final nestedClasses = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        nestedClasses.add(generateExtraClass(
          suffix,
          key.toString().pascalCase,
          parent,
          value,
          false,
        ));
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        nestedClasses.add(generateExtraClass(
          suffix,
          key.toString().pascalCase,
          parent,
          value.first,
          false,
        ));
      }
    }

    return nestedClasses.join('\n');
  }

  /// Checks if a string value represents a DateTime
  bool _isDateTime(String value) {
    return RegExp(
            r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
        .hasMatch(value);
  }
}
