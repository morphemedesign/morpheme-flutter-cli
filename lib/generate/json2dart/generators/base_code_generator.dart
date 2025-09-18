import 'package:morpheme_cli/helper/helper.dart';

/// Base class for all code generators
///
/// Provides common functionality and interface for different types of code generators
abstract class BaseCodeGenerator {
  /// Generates class content from a map structure
  ///
  /// [suffix] - Class name suffix
  /// [name] - Base class name
  /// [parent] - Parent class name for nested structures
  /// [map] - Data structure to generate from
  /// [isRoot] - Whether this is a root class
  /// Returns the generated class string
  String generateClass(
    String suffix,
    String name,
    String parent,
    Map<String, dynamic>? map, [
    bool isRoot = false,
  ]);

  /// Gets the appropriate type for a given value
  ///
  /// [key] - Property key name
  /// [value] - Property value
  /// [suffix] - Class suffix for complex types
  /// [listClassName] - List of class names for collision detection
  /// [parent] - Parent class name
  /// Returns the Dart type string
  String getTypeVariable(
    String key,
    dynamic value,
    String suffix,
    List<ModelClassName> listClassName,
    String parent,
  ) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';

    if (value is Map) {
      return ModelClassNameHelper.getClassName(
        listClassName,
        suffix,
        key.pascalCase,
        false,
        false,
        parent,
      );
    }

    if (value is List) {
      if (value.isNotEmpty) {
        return 'List<${getTypeVariable(key, value.first, suffix, listClassName, parent)}>';
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

  /// Generates constructor parameters
  String generateConstructor(
    String className,
    Map<String, dynamic> map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final variables = map.keys;
    if (variables.isEmpty && paramPath.isEmpty) {
      return 'const $className(${isMultipart ? '{ this.files }' : ''});';
    }

    return '''const $className({
    ${isMultipart ? 'this.files,' : ''}
    ${paramPath.map((e) => 'this.${e.camelCase},').join('    \n')}
    ${variables.map((e) => 'this.${e.toString().camelCase},').join('    \n')}
  });''';
  }

  /// Generates Equatable props
  String generateProps(
    Map<String, dynamic> map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
    String rawVariable = '',
  ]) {
    final variables = map.keys;

    if (variables.isEmpty && paramPath.isEmpty && !isMultipart) {
      return '''@override
  List<Object?> get props => [${rawVariable.isNotEmpty ? rawVariable : ''}];''';
    }

    return '''@override
  List<Object?> get props => [${rawVariable.isNotEmpty ? rawVariable : ''} ${isMultipart ? 'files,' : ''} ${paramPath.isEmpty ? '' : paramPath.map((e) => '${e.camelCase},').join()} ${variables.map((e) => '${e.toString().camelCase},').join()}];''';
  }
}
