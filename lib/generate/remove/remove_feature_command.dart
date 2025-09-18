import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';
import 'helpers/path_helper.dart';
import 'helpers/config_helper.dart';

/// Command to remove a feature module from the project.
///
/// This command removes a feature module, with optional app scoping:
/// - Deletes the feature directory
/// - Removes feature references from locator files
/// - Updates pubspec.yaml files
///
/// Usage:
/// ```
/// morpheme remove-feature <feature_name>
/// morpheme remove-feature <feature_name> --apps-name <app_name>
/// ```
class RemoveFeatureCommand extends Command {
  RemoveFeatureCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the app containing the feature to remove',
    );
  }

  @override
  String get name => 'remove-feature';

  @override
  String get description => 'Remove a feature module from the project.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    // Validate inputs
    if (argResults?.rest.isEmpty ?? true) {
      _handleError('Feature name is required');
      return;
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final featureName = (argResults?.rest.first ?? '').snakeCase;

    // Validate app exists (if specified)
    if (appsName.isNotEmpty) {
      final pathApps = PathHelper.getAppsPath(appsName);
      if (!exists(pathApps)) {
        _handleError('App "$appsName" does not exist');
        return;
      }
    }

    // Validate feature exists
    final pathFeature = PathHelper.getFeaturePath(appsName, featureName);
    if (!exists(pathFeature)) {
      _handleError('Feature "$featureName" does not exist');
      return;
    }

    try {
      // Remove feature directory
      _removeFeatureDirectory(pathFeature);

      // Update locator file
      ConfigHelper.removeFeatureFromLocator(appsName, featureName);

      // Update pubspec.yaml
      ConfigHelper.removeFeatureFromPubspec(appsName, featureName);

      // Format code
      await _formatCode(appsName);

      StatusHelper.success('Successfully removed feature "$featureName"');
    } catch (e) {
      _handleError('Failed to remove feature "$featureName": ${e.toString()}');
    }
  }

  /// Removes the feature directory.
  void _removeFeatureDirectory(String pathFeature) {
    deleteDir(pathFeature);
  }

  /// Formats the code after removal.
  Future<void> _formatCode(String appsName) async {
    final paths = <String>[];
    if (appsName.isEmpty) {
      paths.add('.');
    } else {
      paths.add(join(current, 'apps', appsName));
    }
    await ModularHelper.format(paths);
  }

  /// Handles errors with consistent messaging.
  void _handleError(String message) {
    StatusHelper.failed(message);
  }
}
