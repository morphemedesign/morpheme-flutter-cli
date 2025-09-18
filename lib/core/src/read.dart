import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';

import 'is.dart';
import 'truepath.dart';

/// File reading utilities for text files.
///
/// This module provides functions for reading text files with proper
/// error handling and validation.

/// Read all lines from a text file.
///
/// This function reads the entire file and returns each line as a separate
/// string in a list. The file is expected to be a text file with line breaks.
///
/// Parameters:
/// - [path]: Path to the file to read
///
/// Returns a list of strings, one for each line in the file.
///
/// Throws:
/// - Exception if the file doesn't exist
/// - Exception if there are insufficient permissions to read the file
/// - Exception if the file is a directory
///
/// Example:
/// ```dart
/// final lines = read('/path/to/file.txt');
/// for (final line in lines) {
///   print('Line: $line');
/// }
///
/// // Process each line
/// read('/path/to/config.txt').forEach((line) {
///   if (line.startsWith('#')) {
///     // Skip comments
///     return;
///   }
///   processConfigLine(line);
/// });
/// ```

List<String> read(String path) {
  // Validate input
  if (path.isEmpty) {
    StatusHelper.failed('File path cannot be empty.');
  }

  final absolutePath = truepath(path);

  if (!exists(absolutePath)) {
    StatusHelper.failed('The file $absolutePath does not exist.');
  }

  if (isDirectory(absolutePath)) {
    StatusHelper.failed(
        'The path $absolutePath is a directory. Cannot read directories as text files.');
  }

  try {
    return File(absolutePath).readAsLinesSync();
  } on FileSystemException catch (e) {
    StatusHelper.failed('Failed to read file $absolutePath: ${e.message}');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred reading $absolutePath: $e');
  }

  // This line should never be reached due to StatusHelper.failed throwing
  throw Exception('Unexpected error in read function');
}

/// Read the entire content of a text file as a single string.
///
/// This function reads all lines from the specified file and joins them
/// with newline characters to create a single string containing the
/// complete file content.
///
/// Parameters:
/// - [path]: Path to the file to read
///
/// Returns a string containing the entire file content.
///
/// Throws:
/// - Exception if the file doesn't exist
/// - Exception if there are insufficient permissions to read the file
/// - Exception if the file is a directory
///
/// Example:
/// ```dart
/// final content = readFile('/path/to/file.txt');
/// print(content);
/// ```
String readFile(String path) {
  return read(path).join('\n');
}
