import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/apps/generators/apps_generator.dart';
import 'package:morpheme_cli/generate/apps/managers/analysis_options_manager.dart';
import 'package:morpheme_cli/generate/apps/managers/file_system_manager.dart';
import 'package:morpheme_cli/generate/apps/managers/gitignore_manager.dart';
import 'package:morpheme_cli/generate/apps/managers/locator_manager.dart';
import 'package:morpheme_cli/generate/apps/managers/pubspec_manager.dart';
import 'package:morpheme_cli/generate/apps/validators/apps_validator.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Controller for coordinating app module creation operations.
///
/// This class orchestrates the creation of new app modules by coordinating
/// between various managers and generators.
class AppsController {
  /// Creates a new app module with all required files and configurations.
  ///
  /// This method coordinates the complete process of creating a new app module,
  /// including validation, generation, configuration updates, and post-processing.
  ///
  /// Parameters:
  /// - [rawAppName]: The raw app name provided by the user
  static Future<void> createApp(String rawAppName) async {
    try {
      // Validate input
      AppsValidator.validateAppName(rawAppName);

      final appsName = rawAppName.snakeCase;
      final pathApp = join(current, 'apps', appsName);

      // Validate path doesn't exist
      FileSystemManager.validateAppPathDoesNotExist(pathApp);

      // Generate the app module
      await AppsGenerator.addNewApps(pathApp, appsName);

      // Update locator
      LocatorManager.addNewAppsInLocator(pathApp, appsName);

      // Update pubspec
      PubspecManager.addNewAppsInPubspec(pathApp, appsName);

      // Create .gitignore
      GitIgnoreManager.addNewGitIgnore(pathApp, appsName);

      // Create analysis_options.yaml
      AnalysisOptionsManager.addNewAnalysisOption(pathApp, appsName);

      // Remove unused platform directories
      FileSystemManager.removeUnusedDir(pathApp, appsName);

      // Format the new app and project
      await ModularHelper.format(
        [
          pathApp,
          join(current, 'lib', 'locator.dart'),
        ],
      );

      // Get dependencies
      await FlutterHelper.start('pub get', workingDirectory: pathApp);
      await FlutterHelper.run('pub get');

      StatusHelper.success('Generated app module $appsName');
    } catch (e) {
      StatusHelper.failed('Failed to create app module: $e');
    }
  }
}
