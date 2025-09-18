/// Template for model class code generation.
///
/// This class provides static methods for generating model
/// classes with proper formatting and structure.
class ModelTemplate {
  /// Generates a model class.
  ///
  /// Parameters:
  /// - [className]: The name of the class.
  /// - [importForeign]: Import statements for foreign models.
  /// - [constructor]: Constructor parameters.
  /// - [constructorAssign]: Constructor assignments.
  /// - [variables]: Class variables.
  /// - [toMap]: toMap method implementation.
  /// - [fromMap]: fromMap method implementation.
  /// - [fromMapWithJoin]: fromMapWithJoin method implementation.
  /// - [paramCopyWith]: copyWith method parameters.
  /// - [valueCopyWith]: copyWith method implementation.
  /// - [props]: props getter implementation.
  ///
  /// Returns: The generated model class code.
  static String generate({
    required String className,
    required List<String> importForeign,
    required List<String> constructor,
    required List<String> constructorAssign,
    required List<String> variables,
    required List<String> toMap,
    required List<String> fromMap,
    required List<String> fromMapWithJoin,
    required List<String> paramCopyWith,
    required List<String> valueCopyWith,
    required List<String> props,
  }) {
    return '''
import 'dart:convert';

import 'package:equatable/equatable.dart';

${importForeign.join('\n')}

class $className extends Equatable {
  const $className({
    ${constructor.join('\n')}
  }) ${constructorAssign.isNotEmpty ? ': ${constructorAssign.join(',')}' : ''};

  ${variables.join('\n')}

  Map<String, dynamic> toMap({bool withJoin = false}) {
    return {
      ${toMap.join('\n')}
    };
  }

  factory $className.fromMap(Map<String, dynamic> map, {bool withJoin = false,}) {
    return $className(
      ${fromMap.join('\n')}
    );
  }

  ${fromMapWithJoin.isEmpty ? '' : '''factory $className.fromMapWithJoin(Map<String, dynamic> map, {bool withJoin = false,}) {
    return $className(
       ${fromMapWithJoin.join('\n')}
    );
  }'''}

  String toJson({bool withJoin = false}) => json.encode(toMap(withJoin: withJoin));

  factory $className.fromJson(String source) =>
      $className.fromMap(json.decode(source));

  $className copyWith({
    ${paramCopyWith.join('\n')}
  }) {
    return $className(
      ${valueCopyWith.join('\n')}
    );
  }

  @override
  List<Object?> get props => [${props.join(',')}];
}
''';
  }
}