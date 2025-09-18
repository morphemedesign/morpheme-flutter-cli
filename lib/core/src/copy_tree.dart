import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import 'copy.dart';
import 'create.dart';
import 'find.dart';
import 'is.dart';
import 'truepath.dart';

/// Default filter that allows all files.
bool _allowAll(String file) => true;

/// Copy an entire directory tree from one location to another.
///
/// This function recursively copies all files and directories from [from] to [to].
/// The destination directory must already exist.
///
/// Parameters:
/// - [from]: Source directory path (must be a directory)
/// - [to]: Destination directory path (must exist and be a directory)
/// - [overwrite]: If true, overwrites existing files (defaults to false)
/// - [filter]: Function to filter which files to copy (defaults to copying all)
/// - [includeHidden]: If true, includes hidden files/directories (defaults to false)
/// - [recursive]: If true, copies subdirectories recursively (defaults to true)
///
/// Throws:
/// - Exception if source is not a directory
/// - Exception if destination doesn't exist or is not a directory
/// - Exception if any file copy operation fails
///
/// Example:
/// ```dart
/// // Copy entire directory tree
/// copyTree('/path/to/source', '/path/to/destination');
///
/// // Copy with custom filter (only .txt files)
/// copyTree('/path/to/source', '/path/to/destination',
///   filter: (file) => file.endsWith('.txt'));
///
/// // Copy including hidden files
/// copyTree('/path/to/source', '/path/to/destination', includeHidden: true);
/// ```

void copyTree(
  String from,
  String to, {
  bool overwrite = false,
  bool Function(String file) filter = _allowAll,
  bool includeHidden = false,
  bool recursive = true,
}) {
  // Validate input parameters
  if (from.isEmpty) {
    StatusHelper.failed('Source directory path cannot be empty.');
  }
  if (to.isEmpty) {
    StatusHelper.failed('Destination directory path cannot be empty.');
  }

  final absoluteFrom = truepath(from);
  final absoluteTo = truepath(to);

  if (!isDirectory(absoluteFrom)) {
    StatusHelper.failed('The source path $absoluteFrom must be a directory.');
  }
  if (!exists(absoluteTo)) {
    StatusHelper.failed('The destination path $absoluteTo must already exist.');
  }
  if (!isDirectory(absoluteTo)) {
    StatusHelper.failed(
        'The destination path $absoluteTo must be a directory.');
  }

  try {
    final items = find(
      '*',
      workingDirectory: absoluteFrom,
      includeHidden: includeHidden,
      recursive: recursive,
    );

    items.forEach((item) {
      _process(
        item,
        filter,
        absoluteFrom,
        absoluteTo,
        overwrite: overwrite,
        recursive: recursive,
      );
    });
  } on Exception catch (e) {
    StatusHelper.failed(
        'Failed to copy directory tree from $absoluteFrom to $absoluteTo: $e');
  } catch (e) {
    StatusHelper.failed(
        'An unexpected error occurred copying directory tree from $absoluteFrom to $absoluteTo: $e');
  }
}

/// Process a single file or directory during tree copy operation.
///
/// This internal function handles the copying of individual items found during
/// the directory traversal, applying filters and creating necessary directories.
void _process(
  String file,
  bool Function(String file) filter,
  String from,
  String to, {
  required bool overwrite,
  required bool recursive,
}) {
  if (!filter(file)) {
    return; // Skip files that don't pass the filter
  }

  final target = join(to, relative(file, from: from));
  final targetDir = dirname(target);

  // Create target directory if it doesn't exist and we're in recursive mode
  if (recursive && !exists(targetDir)) {
    try {
      createDir(targetDir, recursive: true);
    } catch (e) {
      StatusHelper.failed(
          'Failed to create target directory ${truepath(targetDir)}: $e');
    }
  }

  // Check for existing target file
  if (!overwrite && exists(target)) {
    StatusHelper.failed('The target file ${truepath(target)} already exists.');
  }

  // Copy the file
  try {
    copy(file, target, overwrite: overwrite);
  } catch (e) {
    StatusHelper.failed(
        'Failed to copy ${truepath(file)} to ${truepath(target)}: $e');
  }
}
