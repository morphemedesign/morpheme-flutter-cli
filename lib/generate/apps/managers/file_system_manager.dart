import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

/// Manages file system operations for app module creation.
///
/// This class handles all file system operations required for creating
/// new app modules, including directory creation, file deletion, and path validation.
class FileSystemManager {
  /// Removes platform-specific directories that are not needed for packages.
  ///
  /// This method deletes platform-specific directories that are created
  /// by 'flutter create' but are not needed for package modules.
  ///
  /// Parameters:
  /// - [pathApps]: The path to the new app module
  /// - [appsName]: The name of the new app module (unused but kept for consistency)
  static void removeUnusedDir(String pathApps, String appsName) {
    final platformDirs = [
      p.join(pathApps, 'android'),
      p.join(pathApps, 'ios'),
      p.join(pathApps, 'web'),
      p.join(pathApps, 'macos'),
      p.join(pathApps, 'linux'),
      p.join(pathApps, 'windows'),
    ];

    for (var element in platformDirs) {
      if (Directory(element).existsSync()) {
        try {
          Directory(element).deleteSync(recursive: true);
        } catch (e) {
          StatusHelper.warning('Failed to delete $element: $e');
        }
      }
    }
  }

  /// Validates that an app module does not already exist at the specified path.
  ///
  /// This method checks if a directory already exists at the intended location
  /// for the new app module and throws an error if it does.
  ///
  /// Parameters:
  /// - [pathApps]: The path where the new app module would be created
  ///
  /// Throws:
  /// - Exception if the directory already exists
  static void validateAppPathDoesNotExist(String pathApps) {
    if (Directory(pathApps).existsSync()) {
      StatusHelper.failed('App module already exists at $pathApps');
    }
  }
}
