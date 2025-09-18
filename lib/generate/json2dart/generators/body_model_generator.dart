import 'package:morpheme_cli/helper/helper.dart';

import 'base_code_generator.dart';

/// Generates Dart model classes for request bodies
///
/// This generator creates model classes used for API request bodies,
/// with support for multipart uploads and parameter validation.
class BodyModelGenerator extends BaseCodeGenerator {
  final List<ModelClassName> _listClassName = [];
  final String _bodyDateFormat;

  BodyModelGenerator({
    required String bodyDateFormat,
  }) : _bodyDateFormat = bodyDateFormat;

  /// Generates a complete body model file
  ///
  /// [className] - Main class name
  /// [data] - JSON data structure
  /// [isMultipart] - Whether this supports multipart uploads
  /// [paramPath] - URL parameters
  /// Returns the complete file content
  String generateBodyModel(
    String className,
    Map<String, dynamic> data, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    _listClassName.clear();

    String imports = '';
    if (isMultipart) {
      imports += "import 'dart:io';\n";
    }
    imports += "import 'package:core/core.dart';\n\n";

    final classContent = generateClass(
      className,
      'Body',
      '',
      data,
      true,
      isMultipart,
      paramPath,
    );

    return imports + classContent;
  }

  @override
  String generateClass(
    String suffix,
    String name,
    String parent,
    Map<String, dynamic>? map, [
    bool isRoot = false,
    bool isMultipart = false,
    List<String> paramPath = const [],
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
  ${_generateBodyConstructor(apiClassName, map, isMultipart, paramPath)}

  ${_generateBodyTypeData(map, suffix, apiClassName, isMultipart, paramPath)}

  ${_generateBodyToMap(map)}

  ${generateProps(map, isMultipart, paramPath, 'rawBody,')}
}

${_generateNestedClasses(map, suffix, apiClassName)}''';

    return classContent;
  }

  /// Generates constructor for body classes with rawBody support
  String _generateBodyConstructor(
    String className,
    Map<String, dynamic> map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final variables = map.keys;
    if (variables.isEmpty && paramPath.isEmpty) {
      return 'const $className(${isMultipart ? '{ this.rawBody, this.files }' : '{ this.rawBody }'});';
    }

    return '''const $className({
    this.rawBody,
    ${isMultipart ? 'this.files,' : ''}
    ${paramPath.map((e) => 'required this.${e.camelCase},').join('    \n')}
    ${variables.map((e) => 'this.${e.toString().camelCase},').join('    \n')}
  });''';
  }

  /// Generates type definitions for body model
  String _generateBodyTypeData(
    Map<String, dynamic> map,
    String suffix,
    String parent, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final variables = map.keys;

    String result = '';
    result += '  final Map<String, dynamic>? rawBody;\n';

    if (isMultipart) {
      result += '  final Map<String, List<File>>? files;\n';
    }

    for (final pathParam in paramPath) {
      result += '  final String ${pathParam.camelCase};\n';
    }

    for (final variable in variables) {
      final type = getTypeVariable(
          variable, map[variable], suffix, _listClassName, parent);
      final isNullable = type != 'dynamic' ? '?' : '';
      result += '  final $type$isNullable ${variable.toString().camelCase};\n';
    }

    return result;
  }

  /// Generates toMap method for body serialization
  String _generateBodyToMap(Map<String, dynamic> map) {
    final variables = map.keys;

    return '''Map<String, dynamic> toMap() {
    return {
      if (rawBody?.isNotEmpty ?? false) ...rawBody ?? {},
      ${variables.map((e) => "if (${e.toString().camelCase} != null) '${e.toString()}': ${_getVariableToMapBody(e, map[e])}").join(',      \n')}${variables.isNotEmpty ? ',' : ''}
    };
  }''';
  }

  /// Gets the appropriate serialization format for body variables
  String _getVariableToMapBody(String key, dynamic value) {
    final variable = key.camelCase;

    if (value is Map) {
      return '$variable?.toMap()';
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return '$variable?.map((e) => e.toMap(),).toList()';
    }

    if (value is String && _isDateTime(value)) {
      return '$variable?$_bodyDateFormat';
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

  /// Checks if a string value represents a DateTime
  bool _isDateTime(String value) {
    return RegExp(
            r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
        .hasMatch(value);
  }
}
