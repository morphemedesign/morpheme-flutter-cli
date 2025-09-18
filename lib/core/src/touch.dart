import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

import 'is.dart';
import 'truepath.dart';

/// Create a file or update its timestamps.
///
/// This function creates a new empty file or updates the access and modification
/// times of an existing file, similar to the Unix 'touch' command.
///
/// Parameters:
/// - [path]: The file path to touch
/// - [create]: If true, creates the file if it doesn't exist (defaults to false)
///
/// Returns the absolute path of the touched file.
///
/// Throws:
/// - Exception if the file doesn't exist and [create] is false
/// - Exception if the parent directory doesn't exist
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// // Update timestamps of existing file
/// touch('/path/to/existing/file.txt');
///
/// // Create new file or update timestamps
/// final touchedPath = touch('/path/to/new/file.txt', create: true);
/// ```

String touch(String path, {bool create = false}) {
  // Validate input
  if (path.isEmpty) {
    StatusHelper.failed('File path cannot be empty.');
  }

  final absolutePath = truepath(path);
  final parentDir = p.dirname(absolutePath);

  if (!exists(parentDir)) {
    StatusHelper.failed('The parent directory $parentDir does not exist.');
  }

  if (!create && !exists(absolutePath)) {
    StatusHelper.failed(
        'The file $absolutePath does not exist. Use create: true to create it.');
  }

  try {
    final file = File(absolutePath);

    if (file.existsSync()) {
      // Update timestamps for existing file
      final now = DateTime.now();
      file
        ..setLastAccessedSync(now)
        ..setLastModifiedSync(now);
    } else if (create) {
      // Create new file
      file.createSync();
    }
  } on FileSystemException catch (e) {
    StatusHelper.failed('Failed to touch file $absolutePath: ${e.message}');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred touching $absolutePath: $e');
  }

  return absolutePath;
}
