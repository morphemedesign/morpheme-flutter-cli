import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Common validation patterns for project commands.
///
/// Provides reusable validation logic that can be shared
/// across multiple commands to ensure consistency.
abstract class CommonValidators {
  /// Validates that a directory exists and is accessible.
  ///
  /// Parameters:
  /// - [path]: Directory path to validate
  /// - [name]: Human-readable name for error messages
  /// - [createCommand]: Suggested command to create the directory
  ///
  /// Returns: ValidationResult indicating success or failure
  static ValidationResult<String> validateDirectoryExists(
    String path,
    String name,
    String createCommand,
  ) {
    if (!exists(path)) {
      return ValidationResult.error(
        '$name does not exist',
        suggestion: 'Create the $name first or check the path',
        examples: [createCommand, 'ls ${dirname(path)}/'],
      );
    }

    return ValidationResult.success(path);
  }

  /// Validates project structure prerequisites.
  ///
  /// Checks that required directories and files exist
  /// for the current working directory to be a valid project.
  ///
  /// Returns: ValidationResult indicating project validity
  static ValidationResult<String> validateProjectStructure() {
    final pubspecPath = join(current, 'pubspec.yaml');

    if (!exists(pubspecPath)) {
      return ValidationResult.error(
        'Not a valid Flutter project',
        suggestion: 'Run this command from a Flutter project root directory',
        examples: ['cd /path/to/flutter/project', 'flutter create my_app'],
      );
    }

    return ValidationResult.success(current);
  }

  /// Validates that required tools are available.
  ///
  /// Checks for the presence of specified command-line tools
  /// that are required for command execution.
  ///
  /// Parameters:
  /// - [tools]: Map of tool names to installation commands
  ///
  /// Returns: ValidationResult indicating tool availability
  static ValidationResult<bool> validateRequiredTools(
      Map<String, String> tools) {
    for (final entry in tools.entries) {
      final toolName = entry.key;
      final installCommand = entry.value;

      if (which(toolName).notfound) {
        return ValidationResult.error(
          '$toolName command-line tool not found',
          suggestion: 'Install $toolName to use this feature',
          examples: [installCommand],
        );
      }
    }

    return ValidationResult.success(true);
  }
}
