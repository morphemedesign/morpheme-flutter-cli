import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Formats Dart source code across project modules.
///
/// The FormatCommand applies consistent code formatting to Dart files
/// using the `dart format` tool. It supports targeting specific apps,
/// features, or pages, or formatting the entire project.
///
/// ## Usage
///
/// Format entire project:
/// ```bash
/// morpheme format
/// ```
///
/// Format specific app:
/// ```bash
/// morpheme format --apps-name my_app
/// ```
///
/// Format specific feature:
/// ```bash
/// morpheme format --feature-name user_profile
/// ```
///
/// Format specific page:
/// ```bash
/// morpheme format --page-name login_page --feature-name auth
/// ```
///
/// ## Options
///
/// - `--apps-name, -a`: Target specific app for formatting
/// - `--feature-name, -f`: Target specific feature for formatting
/// - `--page-name, -p`: Target specific page for formatting
///
/// ## Scope Rules
///
/// - Page scope requires feature to be specified
/// - Feature scope can be within an app or at project level
/// - App scope formats the entire app including its features
///
/// ## Dependencies
///
/// - Uses ModularHelper for multi-package formatting
/// - Requires dart format tool (included with Dart SDK)
///
/// ## Exceptions
///
/// Throws [ArgumentError] if page is specified without feature.
/// Throws [FileSystemException] if target paths don't exist.
/// Throws [ProcessException] if dart format fails.
class FormatCommand extends Command {
  /// Creates a new instance of FormatCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--apps-name, -a`: Specific app to format
  /// - `--feature-name, -f`: Specific feature to format
  /// - `--page-name, -p`: Specific page to format
  FormatCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Format Dart files for specific app',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Format Dart files for specific feature',
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Format Dart files for specific page',
    );
  }

  @override
  String get name => 'format';

  @override
  String get description =>
      'Format Dart source code across all project modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      final config = _prepareConfiguration();
      if (!_validateConfiguration(config)) return;

      final pathsToFormat = _determinePaths(config);
      await _executeFormatting(pathsToFormat);
      _reportSuccess();
    } catch (e) {
      ErrorHandler.handleException(
        ProjectCommandError.buildFailure,
        e,
        'Code formatting failed',
      );
    }
  }

  /// Prepares the formatting configuration from command arguments.
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

    final pathApps = join(current, 'apps', appsName);
    final pathFeature = appsName.isNotEmpty
        ? join(pathApps, 'features', featureName)
        : join(current, 'features', featureName);
    final pathPage = join(pathFeature, 'lib', pageName);

    return {
      'appsName': appsName,
      'featureName': featureName,
      'pageName': pageName,
      'pathApps': pathApps,
      'pathFeature': pathFeature,
      'pathPage': pathPage,
    };
  }

  /// Validates the formatting configuration.
  ///
  /// Checks that specified apps, features, and pages exist
  /// before attempting to format them.
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

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed(
        'App "$appsName" does not exist',
        suggestion: 'Create the app first or check the app name',
        examples: ['morpheme apps $appsName', 'ls apps/'],
      );
      return false;
    }

    if (featureName.isNotEmpty && !exists(pathFeature)) {
      StatusHelper.failed(
        'Feature "$featureName" does not exist',
        suggestion: 'Create the feature first or check the feature name',
        examples: ['morpheme feature $featureName', 'ls features/'],
      );
      return false;
    }

    if (pageName.isNotEmpty && !exists(pathPage)) {
      StatusHelper.failed(
        'Page "$pageName" does not exist',
        suggestion: 'Create the page first or check the page name',
        examples: [
          'morpheme page $pageName -f $featureName',
          'ls $pathFeature/lib/'
        ],
      );
      return false;
    }

    return true;
  }

  /// Determines which paths should be formatted based on configuration.
  ///
  /// Applies formatting scope rules to determine the appropriate
  /// paths for the dart format operation.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing path information
  ///
  /// Returns: List of paths to format
  List<String> _determinePaths(Map<String, dynamic> config) {
    final appsName = config['appsName'] as String;
    final featureName = config['featureName'] as String;
    final pageName = config['pageName'] as String;
    final pathApps = config['pathApps'] as String;
    final pathFeature = config['pathFeature'] as String;
    final pathPage = config['pathPage'] as String;

    // Determine scope based on specified parameters
    if (appsName.isNotEmpty && featureName.isNotEmpty && pageName.isNotEmpty) {
      // Page-specific formatting
      return [pathPage];
    } else if (appsName.isNotEmpty && featureName.isNotEmpty) {
      // Feature-specific formatting within app
      return [pathFeature];
    } else if (appsName.isNotEmpty) {
      // App-specific formatting
      return [pathApps];
    } else if (featureName.isNotEmpty && pageName.isNotEmpty) {
      // Page-specific formatting in project feature
      return [pathPage];
    } else if (featureName.isNotEmpty) {
      // Feature-specific formatting in project
      return [pathFeature];
    } else {
      // Project-wide formatting (empty list signals ModularHelper to format all)
      return [];
    }
  }

  /// Executes the code formatting operation.
  ///
  /// Uses ModularHelper to apply dart format to the specified
  /// paths or the entire project if no specific paths are given.
  ///
  /// Parameters:
  /// - [paths]: List of paths to format (empty for project-wide)
  Future<void> _executeFormatting(List<String> paths) async {
    await ModularHelper.format(paths);
  }

  /// Reports successful completion of the formatting operation.
  ///
  /// Displays a success message indicating that code formatting
  /// has completed successfully.
  void _reportSuccess() {
    StatusHelper.success('morpheme format');
  }
}
