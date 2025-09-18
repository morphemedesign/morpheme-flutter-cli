import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';
import 'helpers/path_helper.dart';
import 'helpers/config_helper.dart';

/// Command to remove an app module from the project.
///
/// This command removes an entire app module including:
/// - Deleting the app directory
/// - Removing app references from the main locator file
/// - Removing app entries from pubspec.yaml
///
/// Usage:
/// ```
/// morpheme remove-apps <app_name>
/// ```
class RemoveAppsCommand extends Command {
  @override
  String get name => 'remove-apps';

  @override
  String get description => 'Remove an app module from the project.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    // Validate inputs
    if (argResults?.rest.isEmpty ?? true) {
      _handleError('App name is required');
      return;
    }

    final appsName = (argResults?.rest.first ?? '').snakeCase;

    // Validate app exists
    final pathApps = PathHelper.getAppsPath(appsName);
    if (!exists(pathApps)) {
      _handleError('App "$appsName" does not exist');
      return;
    }

    try {
      // Remove app directory
      _removeAppDirectory(pathApps);

      // Update locator file
      ConfigHelper.removeAppFromLocator(appsName);

      // Update pubspec.yaml
      ConfigHelper.removeAppFromPubspec(appsName);

      // Format code
      await _formatCode();

      StatusHelper.success('Successfully removed app "$appsName"');
    } catch (e) {
      _handleError('Failed to remove app "$appsName": ${e.toString()}');
    }
  }

  /// Removes the app directory.
  void _removeAppDirectory(String pathApps) {
    deleteDir(pathApps);
  }

  /// Formats the code after removal.
  Future<void> _formatCode() async {
    await '${FlutterHelper.getCommandDart()} format .'.run;
  }

  /// Handles errors with consistent messaging.
  void _handleError(String message) {
    StatusHelper.failed(message);
  }
}
