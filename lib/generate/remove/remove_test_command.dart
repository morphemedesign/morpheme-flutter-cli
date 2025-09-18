import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';
import 'helpers/path_helper.dart';

/// Command to remove test helper files from the project.
///
/// This command removes test helper files:
/// - Deletes bundle_test.dart files
/// - Removes coverage_helper_test.dart files
///
/// Usage:
/// ```
/// morpheme remove-test
/// morpheme remove-test --apps-name <app_name>
/// morpheme remove-test --feature <feature_name>
/// morpheme remove-test --page <page_name>
/// ```
class RemoveTestCommand extends Command {
  RemoveTestCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Remove tests from a specific app (optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Remove tests from a specific feature (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Remove tests from a specific page (optional)',
    );
  }

  @override
  String get name => 'remove-test';

  @override
  String get description => 'Remove test helper files from the project.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    final String? apps = argResults?['apps-name']?.toString().snakeCase;
    final String? feature = argResults?['feature']?.toString().snakeCase;
    final String? page = argResults?['page']?.toString().snakeCase;

    try {
      if (page != null) {
        _deleteTestHelpersForPath(PathHelper.getPageTestPath(apps ?? '', feature ?? '', page));
      } else if (feature != null) {
        _deleteTestHelpersForPath(PathHelper.getFeatureTestPath(apps ?? '', feature));
      } else if (apps != null) {
        _deleteTestHelpersForPath(PathHelper.getAppsTestPath(apps));
      } else {
        _deleteTestHelpersForPath(current);
      }

      StatusHelper.success('Successfully removed test helper files');
    } catch (e) {
      _handleError('Failed to remove test helper files: ${e.toString()}');
    }
  }
  
  /// Deletes test helper files from the specified path.
  void _deleteTestHelpersForPath(String path) {
    final files = find(
      'bundle_test.dart',
      workingDirectory: path,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (var i = 0; i < files.length; i++) {
      delete(files[i]);
    }

    final fileCoverages = find(
      'coverage_helper_test.dart',
      workingDirectory: path,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (var i = 0; i < fileCoverages.length; i++) {
      delete(fileCoverages[i]);
    }
  }
  
  /// Handles errors with consistent messaging.
  void _handleError(String message) {
    StatusHelper.failed(message);
  }
}