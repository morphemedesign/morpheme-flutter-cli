import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import 'is.dart';
import 'truepath.dart';

/// Resolves a symbolic link to its target path.
///
/// This function follows symbolic links to their ultimate destination,
/// whether they point to files or directories.
///
/// [pathToLink] - The path to the symbolic link to resolve
///
/// Returns the absolute path to the target of the symbolic link.
///
/// Example:
/// ```dart
/// final target = resolveSymLink('/path/to/symlink');
/// print('Symlink points to: $target');
/// ```

String resolveSymLink(String pathToLink) {
  final normalised = canonicalize(pathToLink);

  String resolved;
  if (isDirectory(normalised)) {
    resolved = Directory(normalised).resolveSymbolicLinksSync();
  } else {
    resolved = canonicalize(File(normalised).resolveSymbolicLinksSync());
  }

  return resolved;
}

/// Copy a file from one location to another.
///
/// This function copies a single file from [from] to [to]. If [to] is a directory,
/// the file will be copied into that directory with its original name.
///
/// Parameters:
/// - [from]: Source file path (must be a file, not a directory)
/// - [to]: Destination path (can be a file path or directory)
/// - [overwrite]: If true, overwrites existing files (defaults to false)
///
/// Throws:
/// - Exception if the source file doesn't exist
/// - Exception if the target already exists and [overwrite] is false
/// - Exception if the target directory doesn't exist
/// - Exception if [from] is a directory
///
/// Example:
/// ```dart
/// copy('/path/to/source.txt', '/path/to/destination.txt');
/// copy('/path/to/source.txt', '/path/to/directory/'); // Copies into directory
/// copy('/path/to/source.txt', '/path/to/existing.txt', overwrite: true);
/// ```
void copy(String from, String to, {bool overwrite = false}) {
  var finalto = to;
  if (isDirectory(finalto)) {
    finalto = join(finalto, basename(from));
  }

  if (overwrite == false && exists(finalto, followLinks: false)) {
    StatusHelper.failed('The target file ${truepath(finalto)} already exists.');
  }

  try {
    // Validate input parameters
    if (from.isEmpty) {
      StatusHelper.failed('Source path cannot be empty.');
    }
    if (to.isEmpty) {
      StatusHelper.failed('Destination path cannot be empty.');
    }
    if (!exists(from)) {
      StatusHelper.failed("The source file ${truepath(from)} does not exist.");
    }
    if (isDirectory(from)) {
      StatusHelper.failed(
          "The source ${truepath(from)} is a directory. Use copyTree for directories.");
    }
    if (!exists(dirname(finalto))) {
      StatusHelper.failed(
        "The destination directory ${truepath(dirname(finalto))} does not exist.",
      );
    }
    // Handle symbolic links by copying the target file instead of the link
    // This mimics the behavior of GNU 'cp'
    if (isLink(from)) {
      final resolvedFrom = resolveSymLink(from);
      File(resolvedFrom).copySync(finalto);
    } else {
      File(from).copySync(finalto);
    }
  } on FileSystemException catch (e) {
    StatusHelper.failed(
        'Failed to copy ${truepath(from)} to ${truepath(finalto)}: ${e.message}');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred copying ${truepath(from)} to ${truepath(finalto)}: $e');
  }
}
