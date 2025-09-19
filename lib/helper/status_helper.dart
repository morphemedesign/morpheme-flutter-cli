import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

/// Provides standardized status reporting with enhanced error messages.
///
/// StatusHelper offers consistent feedback mechanisms across all commands
/// with support for actionable error messages, suggestions, and examples.
abstract class StatusHelper {
  /// Reports successful completion of an operation.
  ///
  /// Displays a success message followed by a green "SUCCESS" indicator.
  ///
  /// Parameters:
  /// - [message]: Optional success message to display
  ///
  /// Example:
  /// ```dart
  /// StatusHelper.success('Operation completed successfully');
  /// // Output:
  /// // Operation completed successfully
  /// // SUCCESS
  /// ```
  static void success([String? message]) {
    if (message != null) {
      printMessage(message);
    }
    printMessage(green('SUCCESS'));
  }

  /// Reports a warning message.
  ///
  /// Displays a warning message in orange text.
  ///
  /// Parameters:
  /// - [message]: Warning message to display
  ///
  /// Example:
  /// ```dart
  /// StatusHelper.warning('This is a warning message');
  /// // Output: (in orange text)
  /// // This is a warning message
  /// ```
  static void warning(String message) {
    printerrMessage(orange(message));
  }

  /// Reports operation failure with enhanced error information.
  ///
  /// Displays an error message followed by optional suggestions and examples,
  /// and terminates the application with a red "FAILED" indicator.
  ///
  /// Parameters:
  /// - [message]: Primary error message to display
  /// - [suggestion]: Optional suggestion for resolving the error
  /// - [examples]: Optional list of example commands to fix the issue
  /// - [isExit]: Whether to exit the process (default: true)
  /// - [statusExit]: Exit code to use (default: 1)
  ///
  /// Example:
  /// ```dart
  /// StatusHelper.failed(
  ///   'Configuration file not found',
  ///   suggestion: 'Run "morpheme init" to create a new configuration file',
  ///   examples: ['morpheme init', 'morpheme config'],
  /// );
  /// // Output: (in red text)
  /// // Configuration file not found
  /// //
  /// // Suggestion: Run "morpheme init" to create a new configuration file
  /// //
  /// // Example commands:
  /// //   morpheme init
  /// //   morpheme config
  /// //
  /// // FAILED
  /// ```
  static void failed(
    String message, {
    String? suggestion,
    List<String>? examples,
    bool isExit = true,
    int statusExit = 1,
  }) {
    printerrMessage(red(message));

    if (suggestion != null) {
      printerrMessage(yellow('\nSuggestion: $suggestion'));
    }

    if (examples != null && examples.isNotEmpty) {
      printerrMessage(cyan('\nExample commands:'));
      for (final example in examples) {
        printerrMessage(cyan('  $example'));
      }
    }

    printerrMessage(red('\nFAILED'));
    if (isExit) {
      exit(statusExit);
    }
  }

  /// Reports successful file or directory generation.
  ///
  /// Displays a green "generated" message followed by the path.
  ///
  /// Parameters:
  /// - [path]: Path to the generated file or directory
  ///
  /// Example:
  /// ```dart
  /// StatusHelper.generated('./lib/models/user.dart');
  /// // Output:
  /// // generated ./lib/models/user.dart
  /// ```
  static void generated(String path) {
    printMessage('${green('generated')} $path');
  }

  /// Reports successful refactoring operation.
  ///
  /// Displays a green "refactor" message followed by the path.
  ///
  /// Parameters:
  /// - [path]: Path to the refactored file or directory
  ///
  /// Example:
  /// ```dart
  /// StatusHelper.refactor('./lib/models/user.dart');
  /// // Output:
  /// // refactor ./lib/models/user.dart
  /// ```
  static void refactor(String path) {
    printMessage('${green('refactor')} $path');
  }
}
