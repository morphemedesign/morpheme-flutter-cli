import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Applies automated fixes to Dart source code across project modules.
///
/// The FixCommand uses `dart fix` to apply safe, automated fixes
/// to Dart code issues identified by the analyzer. It supports
/// targeting specific apps, features, or pages, or fixing the entire project.
///
/// ## Usage
///
/// Fix entire project:
/// ```bash
/// morpheme fix
/// ```
///
/// Fix specific app:
/// ```bash
/// morpheme fix --apps-name my_app
/// ```
///
/// Fix specific feature:
/// ```bash
/// morpheme fix --feature-name user_profile
/// ```
///
/// Fix specific page:
/// ```bash
/// morpheme fix --page-name login_page --feature-name auth
/// ```
///
/// ## Options
///
/// - `--apps-name, -a`: Target specific app for fixes
/// - `--feature-name, -f`: Target specific feature for fixes
/// - `--page-name, -p`: Target specific page for fixes
///
/// ## Fixes Applied
///
/// - Removes unused imports
/// - Adds missing type annotations
/// - Converts to modern language features
/// - Applies safe refactoring suggestions
///
/// ## Dependencies
///
/// - Uses ModularHelper for multi-package operations
/// - Requires dart fix tool (included with Dart SDK)
///
/// ## Exceptions
///
/// Throws [ArgumentError] if page is specified without feature.
/// Throws [FileSystemException] if target paths don't exist.
/// Throws [ProcessException] if dart fix fails.
class FixCommand extends Command {
  /// Creates a new instance of FixCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--apps-name, -a`: Specific app to fix
  /// - `--feature-name, -f`: Specific feature to fix
  /// - `--page-name, -p`: Specific page to fix
  FixCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Apply dart fix to specific app',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Apply dart fix to specific feature',
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Apply dart fix to specific page',
    );
    argParser.addFlag(
      'dry-run',
      help: 'Show what fixes would be applied without making changes',
      defaultsTo: false,
    );
  }
  @override
  String get name => 'fix';

  @override
  String get description =>
      'Apply automated fixes to Dart source code across project modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      ProgressReporter.reportPhase('Preparing fix operation');

      final config = _prepareConfiguration();
      if (!_validateConfiguration(config)) return;

      if (config['dryRun']) {
        ProgressReporter.reportPhase('Running dry-run analysis');
      } else {
        final confirmed = await _confirmDestructiveOperation(config);
        if (!confirmed) {
          printMessage('Fix operation cancelled by user.');
          return;
        }
      }

      final pathsToFix = _determinePaths(config);
      await _executeFixes(pathsToFix, config);
      _reportSuccess();
    } catch (e) {
      ErrorHandler.handleException(
        ProjectCommandError.buildFailure,
        e,
        'Code fix operation failed',
      );
    }
  }

  /// Prepares the fix configuration from command arguments.
  ///
  /// Extracts and normalizes app, feature, and page names from
  /// command line arguments using snake_case conversion.
  ///
  /// Returns: Configuration map with normalized names and paths
  Map<String, dynamic> _prepareConfiguration() {
    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    final pageName = (argResults?['page-name'] as String? ?? '').snakeCase;
    final dryRun = argResults?['dry-run'] as bool? ?? false;

    final pathApps = join(current, 'apps', appsName);
    final pathFeature = appsName.isNotEmpty
        ? join(pathApps, 'features', featureName)
        : join(current, 'features', featureName);
    final pathPage = join(pathFeature, 'lib', pageName);

    return {
      'appsName': appsName,
      'featureName': featureName,
      'pageName': pageName,
      'dryRun': dryRun,
      'pathApps': pathApps,
      'pathFeature': pathFeature,
      'pathPage': pathPage,
    };
  }

  /// Validates the fix configuration.
  ///
  /// Checks that specified apps, features, and pages exist
  /// before attempting to apply fixes.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing paths and names
  ///
  /// Returns: true if validation passes, false otherwise
  bool _validateConfiguration(Map<String, dynamic> config) {
    final appsName = config['appsName'] as String;
    final featureName = config['featureName'] as String;
    final pageName = config['pageName'] as String;
    final pathApps = config['pathApps'] as String;
    final pathFeature = config['pathFeature'] as String;
    final pathPage = config['pathPage'] as String;

    if (appsName.isNotEmpty) {
      final result = CommonValidators.validateDirectoryExists(
        pathApps,
        'App "$appsName"',
        'morpheme apps $appsName',
      );
      if (!result.isValid) {
        ErrorHandler.handleValidationError(result);
        return false;
      }
    }

    if (featureName.isNotEmpty) {
      final result = CommonValidators.validateDirectoryExists(
        pathFeature,
        'Feature "$featureName"',
        'morpheme feature $featureName',
      );
      if (!result.isValid) {
        ErrorHandler.handleValidationError(result);
        return false;
      }
    }

    if (pageName.isNotEmpty) {
      final result = CommonValidators.validateDirectoryExists(
        pathPage,
        'Page "$pageName"',
        'morpheme page $pageName -f $featureName',
      );
      if (!result.isValid) {
        ErrorHandler.handleValidationError(result);
        return false;
      }
    }

    return true;
  }

  /// Confirms destructive operation with user.
  ///
  /// For non-dry-run operations, prompts the user to confirm
  /// that they want to apply automated fixes to their code.
  ///
  /// Parameters:
  /// - [config]: Configuration containing operation details
  ///
  /// Returns: true if user confirms, false if cancelled
  Future<bool> _confirmDestructiveOperation(Map<String, dynamic> config) async {
    final scope = _getOperationScope(config);

    printMessage('⚠️  This operation will apply automated fixes to $scope.');
    printMessage('   Fixes may modify your source code.');
    printMessage('');
    print('Do you want to continue? (y/N): ');

    final input = stdin.readLineSync()?.toLowerCase().trim() ?? '';
    return input == 'y' || input == 'yes';
  }

  /// Gets a human-readable description of the operation scope.
  ///
  /// Parameters:
  /// - [config]: Configuration containing scope information
  ///
  /// Returns: Description of what will be affected
  String _getOperationScope(Map<String, dynamic> config) {
    final appsName = config['appsName'] as String;
    final featureName = config['featureName'] as String;
    final pageName = config['pageName'] as String;

    if (appsName.isNotEmpty && featureName.isNotEmpty && pageName.isNotEmpty) {
      return 'page "$pageName" in feature "$featureName" of app "$appsName"';
    } else if (appsName.isNotEmpty && featureName.isNotEmpty) {
      return 'feature "$featureName" in app "$appsName"';
    } else if (appsName.isNotEmpty) {
      return 'app "$appsName"';
    } else if (featureName.isNotEmpty && pageName.isNotEmpty) {
      return 'page "$pageName" in feature "$featureName"';
    } else if (featureName.isNotEmpty) {
      return 'feature "$featureName"';
    } else {
      return 'the entire project';
    }
  }

  /// Determines which paths should be fixed based on configuration.
  ///
  /// Applies fix scope rules to determine the appropriate
  /// paths for the dart fix operation.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing path information
  ///
  /// Returns: List of paths to fix
  List<String> _determinePaths(Map<String, dynamic> config) {
    final appsName = config['appsName'] as String;
    final featureName = config['featureName'] as String;
    final pageName = config['pageName'] as String;
    final pathApps = config['pathApps'] as String;
    final pathFeature = config['pathFeature'] as String;
    final pathPage = config['pathPage'] as String;

    // Determine scope based on specified parameters
    if (appsName.isNotEmpty && featureName.isNotEmpty && pageName.isNotEmpty) {
      return [pathPage];
    } else if (appsName.isNotEmpty && featureName.isNotEmpty) {
      return [pathFeature];
    } else if (appsName.isNotEmpty) {
      return [pathApps];
    } else if (featureName.isNotEmpty && pageName.isNotEmpty) {
      return [pathPage];
    } else if (featureName.isNotEmpty) {
      return [pathFeature];
    } else {
      return [];
    }
  }

  /// Executes the code fix operation.
  ///
  /// Uses ModularHelper to apply dart fix to the specified
  /// paths or the entire project if no specific paths are given.
  ///
  /// Parameters:
  /// - [paths]: List of paths to fix (empty for project-wide)
  /// - [config]: Configuration containing operation settings
  Future<void> _executeFixes(
      List<String> paths, Map<String, dynamic> config) async {
    final dryRun = config['dryRun'] as bool;

    if (dryRun) {
      ProgressReporter.reportPhase('Analyzing potential fixes (dry-run)');
    } else {
      ProgressReporter.reportPhase('Applying automated fixes');
    }

    await ModularHelper.fix(paths, dryRun);
  }

  /// Reports successful completion of the fix operation.
  ///
  /// Displays a success message indicating that code fixes
  /// have been applied successfully.
  void _reportSuccess() {
    ProgressReporter.reportCompletion('Code fix operation');
    StatusHelper.success('morpheme fix');
  }
}
