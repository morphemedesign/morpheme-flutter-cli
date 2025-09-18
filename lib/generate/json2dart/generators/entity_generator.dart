import 'package:morpheme_cli/helper/helper.dart';

import 'base_code_generator.dart';

/// Generates Dart entity classes for domain layer
///
/// This generator creates domain entities with immutable properties
/// and copyWith methods for state management.
class EntityGenerator extends BaseCodeGenerator {
  final List<ModelClassName> _listClassName = [];

  /// Generates a complete entity file
  ///
  /// [className] - Main class name
  /// [data] - JSON data structure
  /// Returns the complete file content
  String generateEntity(
    String className,
    Map<String, dynamic> data,
  ) {
    _listClassName.clear();

    String imports = "import 'package:core/core.dart';\n\n";
    final classContent = generateClass(className, 'Entity', '', data, true);

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

  ${_generateTypeData(map, suffix, apiClassName)}

  ${_generateCopyWith(apiClassName, map, suffix)}

  ${generateProps(map)}
}

${_generateNestedClasses(map, suffix, apiClassName)}''';

    return classContent;
  }

  /// Generates type definitions for entity
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

  /// Generates copyWith method for immutable updates
  String _generateCopyWith(
    String className,
    Map<String, dynamic> map,
    String suffix,
  ) {
    final variables = map.keys;

    return '''$className copyWith({
    ${variables.map((e) {
      final type =
          getTypeVariable(e, map[e], suffix, _listClassName, className);
      final isNullable = type != 'dynamic' ? '?' : '';
      return '$type$isNullable ${e.toString().camelCase},';
    }).join('\n    ')}
  }) {
    return $className(
      ${variables.map((e) => '${e.toString().camelCase}: ${e.toString().camelCase} ?? this.${e.toString().camelCase},').join('\n      ')}
    );
  }''';
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
}
