import 'dart:convert';

/// Command-line string parsing utilities.
///
/// This module provides functionality to parse command-line strings into
/// individual argument components, handling quotes and escaping properly.

/// Converts a command-line string into a list of individual arguments.
///
/// This converter handles quoted arguments and properly splits command lines
/// while respecting shell quoting rules.
///
/// Supports:
/// - Single quotes ('): Preserves content literally
/// - Double quotes ("): Preserves content literally
/// - Space separation: Splits arguments on unquoted spaces
/// - Empty arguments: Handles quoted empty strings
///
/// Example:
/// ```dart
/// final converter = CommandlineConverter();
///
/// // Simple command
/// final args1 = converter.convert('dart --version');
/// // Result: ['dart', '--version']
///
/// // Command with quoted arguments
/// final args2 = converter.convert('echo "hello world" \'single quoted\'');
/// // Result: ['echo', 'hello world', 'single quoted']
///
/// // Complex command with parameters
/// final args3 = converter.convert('flutter build apk --target-platform android-arm64');
/// // Result: ['flutter', 'build', 'apk', '--target-platform', 'android-arm64']
/// ```
class CommandlineConverter extends Converter<String, List<String>> {
  /// Convert a command-line string into a list of arguments.
  ///
  /// Parameters:
  /// - [input]: The command line string to parse (null or empty returns empty list)
  ///
  /// Returns a list of individual command arguments.
  ///
  /// Throws [Exception] if there are unbalanced quotes in the input.
  @override
  List<String> convert(String? input) {
    if (input == null || input.isEmpty) {
      return [];
    }

    final result = <String>[];
    var current = '';
    String? inQuote;
    var lastTokenHasBeenQuoted = false;

    for (var index = 0; index < input.length; index++) {
      final token = input[index];

      if (inQuote != null) {
        // Inside quotes - add everything except the closing quote
        if (token == inQuote) {
          lastTokenHasBeenQuoted = true;
          inQuote = null;
        } else {
          current += token;
        }
      } else {
        // Outside quotes - handle special characters
        switch (token) {
          case "'":
          case '"':
            // Start quoted section
            inQuote = token;
            break;
          case ' ':
            // Space separator - add current token if not empty or was quoted
            if (lastTokenHasBeenQuoted || current.isNotEmpty) {
              result.add(current);
              current = '';
            }
            lastTokenHasBeenQuoted = false;
            break;
          default:
            // Regular character
            current += token;
            lastTokenHasBeenQuoted = false;
        }
      }
    }

    // Add final token if it exists
    if (lastTokenHasBeenQuoted || current.isNotEmpty) {
      result.add(current);
    }

    // Check for unbalanced quotes
    if (inQuote != null) {
      throw Exception('Unbalanced quote $inQuote in command line: $input');
    }

    return result;
  }
}
