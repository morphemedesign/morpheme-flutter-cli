import 'dart:io';
import 'package:morpheme_cli/generate/local2dart/models/local2dart_config.dart';
import 'package:morpheme_cli/helper/recase.dart';

/// Base class for all Local2Dart generators.
///
/// This abstract class provides common functionality that
/// all generators can use, such as file writing and naming conventions.
abstract class BaseGenerator {
  /// The configuration for generation.
  final Local2DartConfig config;

  /// The path where the package should be generated.
  final String packagePath;

  /// Creates a new BaseGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  BaseGenerator(this.config, this.packagePath);

  /// Generates the code.
  ///
  /// This method should be implemented by subclasses to
  /// perform their specific generation logic.
  Future<void> generate();

  /// Writes content to a file.
  ///
  /// This method creates the file and any necessary directories,
  /// then writes the content to the file.
  ///
  /// Parameters:
  /// - [path]: The path to the file to write.
  /// - [content]: The content to write to the file.
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Converts a string to snake_case.
  ///
  /// Parameters:
  /// - [text]: The text to convert.
  ///
  /// Returns: The text in snake_case.
  String snakeCase(String text) {
    return ReCase(text).snakeCase;
  }

  /// Converts a string to camelCase.
  ///
  /// Parameters:
  /// - [text]: The text to convert.
  ///
  /// Returns: The text in camelCase.
  String camelCase(String text) {
    return ReCase(text).camelCase;
  }

  /// Converts a string to PascalCase.
  ///
  /// Parameters:
  /// - [text]: The text to convert.
  ///
  /// Returns: The text in PascalCase.
  String pascalCase(String text) {
    return ReCase(text).pascalCase;
  }

  /// Gets the Dart type for an SQL type.
  ///
  /// Parameters:
  /// - [sqlType]: The SQL type to convert.
  ///
  /// Returns: The Dart type as a string.
  String getDartType(String sqlType) {
    switch (sqlType.toUpperCase()) {
      case 'INTEGER':
        return 'int';
      case 'REAL':
        return 'double';
      case 'TEXT':
        return 'String';
      case 'BLOB':
        return 'Uint8List';
      case 'BOOL':
        return 'bool';
      default:
        return 'String';
    }
  }

  /// Gets the default value for a Dart type.
  ///
  /// Parameters:
  /// - [dartType]: The Dart type.
  ///
  /// Returns: The default value as a string.
  String getDefaultType(String dartType) {
    switch (dartType) {
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'String':
        return "''";
      case 'Uint8List':
        return 'Uint8List(0)';
      case 'bool':
        return 'false';
      default:
        return "''";
    }
  }
}
