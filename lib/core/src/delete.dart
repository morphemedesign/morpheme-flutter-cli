import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';

import 'is.dart';
import 'truepath.dart';

/// Delete a file from the file system.
///
/// This function removes a single file. For directories, use [deleteDir].
///
/// Parameters:
/// - [path]: The file path to delete
///
/// Throws:
/// - Exception if the file doesn't exist
/// - Exception if the path is a directory
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// delete('/path/to/file.txt');
/// ```

void delete(String path) {
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
        'The path $absolutePath is a directory. Use deleteDir for directories.');
  }

  try {
    File(absolutePath).deleteSync();
  } on FileSystemException catch (e) {
    StatusHelper.failed('Failed to delete file $absolutePath: ${e.message}');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred deleting $absolutePath: $e');
  }
}

/// Delete a directory from the file system.
///
/// This function removes a directory and optionally its contents.
///
/// Parameters:
/// - [path]: The directory path to delete
/// - [recursive]: If true, deletes directory contents recursively (defaults to true)
///
/// Throws:
/// - Exception if the directory doesn't exist
/// - Exception if the path is not a directory
/// - Exception if the directory is not empty and [recursive] is false
/// - Exception if there are insufficient permissions
///
/// Example:
/// ```dart
/// deleteDir('/path/to/directory'); // Deletes recursively
/// deleteDir('/path/to/empty/dir', recursive: false); // Only if empty
/// ```
void deleteDir(String path, {bool recursive = true}) {
  // Validate input
  if (path.isEmpty) {
    StatusHelper.failed('Directory path cannot be empty.');
  }

  final absolutePath = truepath(path);

  if (!exists(absolutePath)) {
    StatusHelper.failed('The directory $absolutePath does not exist.');
  }

  if (!isDirectory(absolutePath)) {
    StatusHelper.failed(
        'The path $absolutePath is not a directory. Use delete for files.');
  }

  try {
    Directory(absolutePath).deleteSync(recursive: recursive);
  } on FileSystemException catch (e) {
    if (!recursive && e.osError?.errorCode == 39) {
      // Directory not empty
      StatusHelper.failed(
          'Directory $absolutePath is not empty. Use recursive: true to delete contents.');
    } else {
      StatusHelper.failed(
          'Failed to delete directory $absolutePath: ${e.message}');
    }
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred deleting directory $absolutePath: $e');
  }
}
