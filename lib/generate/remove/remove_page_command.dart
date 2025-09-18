import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';

import 'helpers/path_helper.dart';
import 'helpers/config_helper.dart';

/// Command to remove a page from a specific feature.
///
/// This command removes a page from a specific feature:
/// - Deletes the page directory
/// - Removes test directories
/// - Updates feature locator files
///
/// Usage:
/// ```
/// morpheme remove-page <page_name> --feature-name <feature_name>
/// morpheme remove-page <page_name> --feature-name <feature_name> --apps-name <app_name>
/// ```
class RemovePageCommand extends Command {
  RemovePageCommand() {
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature containing the page to remove',
      mandatory: true,
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the app containing the feature (optional)',
    );
  }

  @override
  String get name => 'remove-page';

  @override
  String get description => 'Remove a page from a specific feature.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    // Validate inputs
    if (argResults?.rest.isEmpty ?? true) {
      _handleError('Page name is required');
      return;
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;

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

    final pageName = (argResults?.rest.first ?? '').snakeCase;
    final pathPage = PathHelper.getPagePath(appsName, featureName, pageName);

    // Validate page exists
    if (!exists(pathPage)) {
      _handleError('Page "$pageName" does not exist in feature "$featureName"');
      return;
    }

    try {
      // Remove page directory
      _removePageDirectory(appsName, featureName, pageName);

      // Update locator file
      ConfigHelper.removePageFromLocator(appsName, featureName, pageName);

      // Format code
      await _formatCode(pathFeature);

      StatusHelper.success(
          'Successfully removed page "$pageName" from feature "$featureName"');
    } catch (e) {
      _handleError('Failed to remove page "$pageName": ${e.toString()}');
    }
  }

  /// Removes the page directory and associated test directories.
  void _removePageDirectory(
      String appsName, String featureName, String pageName) {
    final pathPage = PathHelper.getPagePath(appsName, featureName, pageName);
    final pathFeature = PathHelper.getFeaturePath(appsName, featureName);
    final pathTest = join(pathFeature, 'test', '${pageName}_test');

    if (exists(pathPage)) {
      deleteDir(pathPage);
    }

    if (exists(pathTest)) {
      deleteDir(pathTest);
    }
  }

  /// Formats the code after removal.
  Future<void> _formatCode(String pathFeature) async {
    await ModularHelper.format([pathFeature]);
  }

  /// Handles errors with consistent messaging.
  void _handleError(String message) {
    StatusHelper.failed(message);
  }
}
