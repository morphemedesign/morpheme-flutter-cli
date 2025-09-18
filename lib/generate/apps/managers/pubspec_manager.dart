import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Manages pubspec.yaml file modifications for app modules.
///
/// This class handles adding new app modules to the main pubspec.yaml file,
/// including both workspace resolution and dependency declarations.
class PubspecManager {
  /// Adds a new app module to the main pubspec.yaml file.
  ///
  /// This method updates the pubspec.yaml file to include the new app module
  /// in both the workspace resolution and dependencies sections.
  ///
  /// Parameters:
  /// - [pathApps]: The path to the new app module
  /// - [appsName]: The name of the new app module
  ///
  /// Throws:
  /// - Exception if the pubspec.yaml file doesn't exist
  /// - Exception if there are file I/O errors
  static void addNewAppsInPubspec(String pathApps, String appsName) {
    final pubspecPath = join(current, 'pubspec.yaml');
    if (!exists(pubspecPath)) {
      StatusHelper.warning('pubspec.yaml not found. Skipping pubspec update.');
      return;
    }

    try {
      String pubspec = File(pubspecPath).readAsStringSync();

      // Add to feature workspace
      pubspec = pubspec.replaceAll(
        RegExp(r'(^\n?dependencies)', multiLine: true),
        '''  - apps/$appsName

dependencies''',
      );

      // Add to dependencies
      pubspec = pubspec.replaceAll(
        RegExp(r'(^\n?dev_dependencies)', multiLine: true),
        '''  $appsName:
    path: ./apps/$appsName

dev_dependencies''',
      );

      pubspecPath.write(pubspec);
      StatusHelper.generated(pubspecPath);
    } catch (e) {
      StatusHelper.failed('Failed to update pubspec.yaml: $e');
    }
  }
}
