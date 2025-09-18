import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';

import 'is.dart';
import 'truepath.dart';

/// Create a directory at the specified path.
///
/// This function creates a new directory, optionally creating parent directories
/// if they don't exist when [recursive] is true.
///
/// Parameters:
/// - [path]: The directory path to create
/// - [recursive]: If true, creates parent directories as needed
///
/// Returns the created directory path.
///
/// Throws:
/// - Exception if the directory already exists
/// - Exception if parent directories don't exist and [recursive] is false
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// createDir('/path/to/new/directory', recursive: true);
/// final createdPath = createDir('/path/to/single/dir', recursive: false);
/// ```

String createDir(String path, {bool recursive = true}) {
  // Validate input
  if (path.isEmpty) {
    StatusHelper.failed('Directory path cannot be empty.');
  }

  final absolutePath = truepath(path);

  try {
    if (!exists(absolutePath)) {
      Directory(absolutePath).createSync(recursive: recursive);
    }
  } on FileSystemException catch (e) {
    StatusHelper.failed(
        'Unable to create directory $absolutePath: ${e.message}');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred creating directory $absolutePath: $e');
  }

  return absolutePath;
}
