import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

import 'copy.dart';
import 'copy_tree.dart';
import 'delete.dart';
import 'is.dart';
import 'truepath.dart';

/// Move a file from one location to another.
///
/// This function moves a single file from [from] to [to]. If [to] is a directory,
/// the file will be moved into that directory with its original name.
/// If a cross-device move is needed, the function will copy and then delete.
///
/// Parameters:
/// - [from]: Source file path
/// - [to]: Destination path (can be a file path or directory)
/// - [overwrite]: If true, overwrites existing files (defaults to false)
///
/// Throws:
/// - Exception if the source file doesn't exist
/// - Exception if the target already exists and [overwrite] is false
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// move('/path/to/source.txt', '/path/to/destination.txt');
/// move('/path/to/source.txt', '/path/to/directory/'); // Moves into directory
/// move('/path/to/source.txt', '/path/to/existing.txt', overwrite: true);
/// ```

void move(String from, String to, {bool overwrite = false}) {
  // Validate input
  if (from.isEmpty) {
    StatusHelper.failed('Source path cannot be empty.');
  }
  if (to.isEmpty) {
    StatusHelper.failed('Destination path cannot be empty.');
  }
  if (!exists(from)) {
    StatusHelper.failed('The source ${truepath(from)} does not exist.');
  }

  var dest = to;

  if (isDirectory(to)) {
    dest = p.join(to, p.basename(from));
  }

  final absoluteDest = truepath(dest);

  if (!overwrite && exists(absoluteDest)) {
    StatusHelper.failed('The destination $absoluteDest already exists.');
  }

  try {
    File(from).renameSync(dest);
  } on FileSystemException catch (e) {
    // Check if this is a cross-device move (Invalid cross-device link)
    if (e.osError?.errorCode == 18 || e.message.contains('cross-device')) {
      // We can't move files across partitions, so do a copy/delete
      try {
        copy(from, dest, overwrite: overwrite);
        delete(from);
      } catch (copyError) {
        StatusHelper.failed(
            'Failed to move ${truepath(from)} to $absoluteDest via copy/delete: $copyError');
      }
    } else {
      StatusHelper.failed(
          'Failed to move ${truepath(from)} to $absoluteDest: ${e.message}');
    }
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred moving ${truepath(from)} to $absoluteDest: $e');
  }
}

/// Move a directory from one location to another.
///
/// This function moves an entire directory tree from [from] to [to].
/// If a cross-device move is needed, the function will copy the tree and then delete the original.
///
/// Parameters:
/// - [from]: Source directory path
/// - [to]: Destination directory path (must not exist)
///
/// Throws:
/// - Exception if the source directory doesn't exist
/// - Exception if the source is not a directory
/// - Exception if the destination already exists
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// await moveDir('/path/to/source/dir', '/path/to/destination/dir');
/// ```
Future<void> moveDir(String from, String to) async {
  // Validate input
  if (from.isEmpty) {
    StatusHelper.failed('Source directory path cannot be empty.');
  }
  if (to.isEmpty) {
    StatusHelper.failed('Destination directory path cannot be empty.');
  }

  final absoluteFrom = truepath(from);
  final absoluteTo = truepath(to);

  if (!exists(absoluteFrom)) {
    StatusHelper.failed('The source directory $absoluteFrom does not exist.');
  }
  if (!isDirectory(absoluteFrom)) {
    StatusHelper.failed(
        'The source $absoluteFrom is not a directory. Use move for files.');
  }
  if (exists(absoluteTo)) {
    StatusHelper.failed(
        'The destination directory $absoluteTo already exists.');
  }

  try {
    Directory(absoluteFrom).renameSync(absoluteTo);
  } on FileSystemException catch (e) {
    // Check if this is a cross-device move
    if (e.osError?.errorCode == 18 || e.message.contains('cross-device')) {
      try {
        // Create destination directory
        Directory(absoluteTo).createSync(recursive: true);
        // Copy the entire tree
        copyTree(absoluteFrom, absoluteTo, includeHidden: true);
        // Delete the original
        Directory(absoluteFrom).deleteSync(recursive: true);
      } catch (copyError) {
        StatusHelper.failed(
            'Failed to move directory $absoluteFrom to $absoluteTo via copy/delete: $copyError');
      }
    } else {
      StatusHelper.failed(
          'Failed to move directory $absoluteFrom to $absoluteTo: ${e.message}');
    }
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred moving directory $absoluteFrom to $absoluteTo: $e');
  }
}
