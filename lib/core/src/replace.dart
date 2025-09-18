import 'package:morpheme_cli/core/src/move.dart';
import 'package:morpheme_cli/core/src/string_extension.dart';

import 'delete.dart';
import 'is.dart';
import 'read.dart';
import 'touch.dart';

/// Text replacement utilities for file content modification.
///
/// This module provides functions for finding and replacing text within files
/// while maintaining file integrity through safe backup and restore operations.

/// Replace text patterns in a file with new content.
///
/// This function performs in-place text replacement in a file, creating
/// a temporary backup during the operation to ensure data safety.
///
/// Parameters:
/// - [path]: Path to the file to modify
/// - [existing]: Pattern to search for (can be String or RegExp)
/// - [replacement]: Text to replace matches with
/// - [all]: If true, replaces all occurrences; if false, only the first (default: false)
///
/// Returns the number of lines that were modified.
///
/// The function uses a safe replacement strategy:
/// 1. Creates a temporary file with replacements
/// 2. Creates a backup of the original file
/// 3. Replaces the original with the temporary file
/// 4. Removes the backup if successful
/// 5. Restores from backup if any errors occur
///
/// Example:
/// ```dart
/// // Replace first occurrence of 'old' with 'new'
/// final changes = replace('/path/to/file.txt', 'old', 'new');
/// print('Modified $changes lines');
///
/// // Replace all occurrences using regex
/// final pattern = RegExp(r'version:\s*\d+\.\d+\.\d+');
/// replace('/path/to/config.yaml', pattern, 'version: 2.0.0', all: true);
///
/// // Replace all instances of a string
/// replace('/path/to/code.dart', 'oldClassName', 'NewClassName', all: true);
/// ```

int replace(
  String path,
  Pattern existing,
  String replacement, {
  bool all = false,
}) {
  // Validate input
  if (path.isEmpty) {
    throw ArgumentError('File path cannot be empty.');
  }
  if (!exists(path)) {
    throw ArgumentError('File $path does not exist.');
  }
  if (isDirectory(path)) {
    throw ArgumentError('Path $path is a directory, not a file.');
  }

  var changes = 0;
  final tmp = '$path.tmp';
  final backup = '$path.bak';

  try {
    // Clean up any existing temporary files
    if (exists(tmp)) {
      delete(tmp);
    }
    if (exists(backup)) {
      delete(backup);
    }

    // Create temporary file for new content
    touch(tmp, create: true);

    // Process each line
    for (final line in read(path)) {
      String newline;
      if (all) {
        newline = line.replaceAll(existing, replacement);
      } else {
        newline = line.replaceFirst(existing, replacement);
      }

      if (newline != line) {
        changes++;
      }

      tmp.append(newline);
    }

    // Only replace if changes were made
    if (changes > 0) {
      // Create backup of original
      move(path, backup);
      // Move new content to original location
      move(tmp, path);
      // Clean up backup
      delete(backup);
    } else {
      // No changes, just clean up temporary file
      delete(tmp);
    }
  } catch (e) {
    // Error occurred, attempt to restore from backup if it exists
    try {
      if (exists(tmp)) delete(tmp);
      if (exists(backup)) {
        if (exists(path)) delete(path);
        move(backup, path);
      }
    } catch (restoreError) {
      throw Exception(
          'Failed to replace text in $path and could not restore backup: $restoreError. Original error: $e');
    }
    throw Exception('Failed to replace text in $path: $e');
  }

  return changes;
}
