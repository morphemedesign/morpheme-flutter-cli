import 'dart:io';

import 'package:archive/archive.dart';

/// Helper class for archive operations.
///
/// This class provides utilities for extracting archive files, particularly
/// ZIP files, to a specified destination directory.
abstract class ArchiveHelper {
  /// Extracts a ZIP file to the specified destination path.
  ///
  /// This method reads a ZIP file and extracts all its contents to the
  /// specified destination directory, preserving the directory structure
  /// and creating any necessary directories.
  ///
  /// Parameters:
  /// - [file]: The ZIP file to extract
  /// - [destinationPath]: The directory path where files should be extracted
  ///
  /// Example:
  /// ```dart
  /// final zipFile = File('my_archive.zip');
  /// await ArchiveHelper.extractFile(zipFile, './extracted_files');
  /// // All files from my_archive.zip are now in the ./extracted_files directory
  /// ```
  ///
  /// Note: This method will overwrite existing files with the same names
  /// in the destination directory.
  static Future<void> extractFile(File file, String destinationPath) async {
    try {
      var bytes = await file.readAsBytes();
      var archive = ZipDecoder().decodeBytes(bytes);
      for (var file in archive) {
        var filename = file.name;
        if (file.isFile) {
          var data = file.content as List<int>;
          File('$destinationPath/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('$destinationPath/$filename').create(recursive: true);
        }
      }
    } catch (e) {
      // Re-throw the exception to allow callers to handle extraction errors
      throw Exception('Failed to extract archive: ${e.toString()}');
    }
  }
}
