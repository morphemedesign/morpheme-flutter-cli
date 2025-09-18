import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

/// Generates the file structure for new app modules.
///
/// This class handles the creation of all files and directories required
/// for a new app module, including pubspec.yaml, locator.dart, and directory structure.
class AppsGenerator {
  /// Creates a new app module with all required files and directories.
  ///
  /// This method creates the complete file structure for a new app module,
  /// including the pubspec.yaml, lib directory, test directory, and locator.dart.
  ///
  /// Parameters:
  /// - [pathApps]: The path where the new app module should be created
  /// - [appsName]: The name of the new app module
  ///
  /// Throws:
  /// - Exception if there are file I/O errors
  /// - Exception if Flutter command execution fails
  static Future<void> addNewApps(String pathApps, String appsName) async {
    try {
      // Create the Flutter package
      await FlutterHelper.run('create --template=package "$pathApps"');

      // Create custom pubspec.yaml
      final pubspecContent = '''name: $appsName
description: A new Flutter package project.
version: 0.0.1

publish_to: "none"

environment:
  sdk: "^3.6.0"
  flutter: "^3.27.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter

  core:
    path: ../../core

dev_dependencies:
  dev_dependency_manager:
    path: ../../core/packages/dev_dependency_manager

flutter:
  uses-material-design: true
''';

      p.join(pathApps, 'pubspec.yaml').write(pubspecContent);

      // Remove default directories
      deleteDir(p.join(pathApps, 'lib'), recursive: true);
      deleteDir(p.join(pathApps, 'test'), recursive: true);

      // Create new directories
      createDir(p.join(pathApps, 'lib'), recursive: true);
      createDir(p.join(pathApps, 'test'), recursive: true);

      // Create test placeholder
      touch(p.join(pathApps, 'test', '.gitkeep'), create: true);

      // Create locator.dart
      final locatorContent = '''//
// Generated file. Edit just you manually add or delete a page.
//

void setupLocatorApps${appsName.pascalCase}() {

}''';

      p.join(pathApps, 'lib', 'locator.dart').write(locatorContent);

      StatusHelper.generated(pathApps);
      StatusHelper.generated(p.join(pathApps, 'lib', 'locator.dart'));
    } catch (e) {
      StatusHelper.failed('Failed to generate app module: $e');
    }
  }
}
