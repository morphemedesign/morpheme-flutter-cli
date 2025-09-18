import 'package:morpheme_cli/helper/helper.dart';

/// Generates mapper extensions for converting between response and entity models
///
/// This generator creates extension methods that provide seamless conversion
/// between data layer models and domain layer entities.
class MapperGenerator {
  final List<ModelClassName> _listClassName = [];

  /// Generates mapper extensions for a given API
  ///
  /// [apiName] - API name for the mapper
  /// [data] - JSON data structure
  /// Returns the mapper extension content
  String generateMapperExtensions(
    String apiName,
    Map<String, dynamic> data,
  ) {
    _listClassName.clear();

    return _generateExtensionMapper(
      apiName.pascalCase,
      '',
      '',
      data,
      null,
      false,
      true,
    );
  }

  /// Generates extension mapper classes
  String _generateExtensionMapper(
    String suffix,
    String name,
    String parent,
    Map<String, dynamic>? map,
    String? parentList,
    bool fromList, [
    bool isRoot = false,
  ]) {
    if (map == null) return '';

    final variables = map.keys;
    final asClassNameResponse = '${suffix.snakeCase}_response';
    final asClassNameEntity = '${suffix.snakeCase}_entity';

    final apiClassName = ModelClassNameHelper.getClassName(
      _listClassName,
      suffix,
      name,
      isRoot,
      true,
      parent,
      parentList != null && fromList ? parentList + parent : parent,
    );

    final apiClassNameResponse = '$apiClassName${isRoot ? 'Response' : ''}';
    final apiClassNameEntity = '$apiClassName${isRoot ? 'Entity' : ''}';

    final parentOfChild = parentList != null && fromList
        ? parentList + apiClassName
        : apiClassName;

    // Register nested class names
    _registerNestedClassNames(
        variables, map, suffix, apiClassName, parentOfChild);

    final classString =
        '''extension $apiClassNameResponse${isRoot ? '' : 'Response'}Mapper on $asClassNameResponse.$apiClassNameResponse {
  $asClassNameEntity.$apiClassNameEntity toEntity() => ${variables.isEmpty ? 'const' : ''} $asClassNameEntity.$apiClassNameEntity(${_generateVariableMapping(map, TypeMapper.toEntity)});
}

extension $apiClassNameEntity${isRoot ? '' : 'Entity'}Mapper on $asClassNameEntity.$apiClassNameEntity {
  $asClassNameResponse.$apiClassNameResponse toResponse() => ${variables.isEmpty ? 'const' : ''} $asClassNameResponse.$apiClassNameResponse(${_generateVariableMapping(map, TypeMapper.toResponse)});
}

${_generateNestedMappers(map, suffix, apiClassName, parentOfChild)}''';

    return classString;
  }

  /// Registers nested class names for collision detection
  void _registerNestedClassNames(
    Iterable<String> variables,
    Map<String, dynamic> map,
    String suffix,
    String apiClassName,
    String parentOfChild,
  ) {
    for (final variable in variables) {
      if (map[variable] is Map) {
        ModelClassNameHelper.getClassName(
          _listClassName,
          suffix,
          variable.toString().pascalCase,
          false,
          false,
          apiClassName,
          parentOfChild,
        );
      }
    }

    for (final variable in variables) {
      final list = map[variable];
      if (list is List && list.isNotEmpty && list.first is Map) {
        ModelClassNameHelper.getClassName(
          _listClassName,
          suffix,
          variable.toString().pascalCase,
          false,
          false,
          apiClassName,
          parentOfChild,
        );
      }
    }
  }

  /// Generates variable mapping for conversions
  String _generateVariableMapping(
      Map<String, dynamic> map, TypeMapper typeMapper) {
    final variables = map.keys;
    return '${variables.map((e) => '${e.toString().camelCase}: ${_getVariableMappingValue(e, map[e], typeMapper)}').join(',\n')}${variables.isNotEmpty ? ',' : ''}';
  }

  /// Gets the appropriate mapping value for a variable
  String _getVariableMappingValue(
      String key, dynamic value, TypeMapper typeMapper) {
    if (value is List && value.firstOrNull is Map) {
      return '${key.camelCase}?.map((e) => e.${typeMapper == TypeMapper.toEntity ? 'toEntity' : 'toResponse'}()).toList()';
    } else if (value is Map) {
      return '${key.camelCase}?.${typeMapper == TypeMapper.toEntity ? 'toEntity' : 'toResponse'}()';
    } else {
      return key.camelCase;
    }
  }

  /// Generates nested mapper extensions
  String _generateNestedMappers(
    Map<String, dynamic> map,
    String suffix,
    String apiClassName,
    String parentOfChild,
  ) {
    final nestedMappers = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        nestedMappers.add(_generateExtensionMapper(
          suffix,
          key.toString().pascalCase,
          apiClassName,
          value,
          parentOfChild,
          false,
        ));
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        nestedMappers.add(_generateExtensionMapper(
          suffix,
          key.toString().pascalCase,
          apiClassName,
          value.first,
          parentOfChild,
          true,
        ));
      }
    }

    return nestedMappers.join('');
  }
}

/// Enum for mapper type direction
enum TypeMapper { toEntity, toResponse }
