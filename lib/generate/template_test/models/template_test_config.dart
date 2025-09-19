import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Configuration model for the template test generation command.
///
/// This class encapsulates all configuration data needed for test generation,
/// including paths, names, and configuration maps.
class TemplateTestConfig {
  /// Optional apps name for generating tests within apps context.
  final String? appsName;

  /// Required feature name for generating tests.
  final String featureName;

  /// Required page name for generating tests.
  final String pageName;

  /// Name of the json2dart configuration file to search for.
  final String searchFileJson2Dart;

  /// Path where test files will be generated.
  final String pathTestPage;

  /// Map containing json2dart configuration data.
  final Map json2DartMap;

  /// Creates a new TemplateTestConfig instance.
  ///
  /// All parameters are required except [appsName] which is optional.
  TemplateTestConfig({
    this.appsName,
    required this.featureName,
    required this.pageName,
    required this.searchFileJson2Dart,
    required this.pathTestPage,
    required this.json2DartMap,
  });

  /// Creates a TemplateTestConfig from command arguments.
  ///
  /// Parameters:
  /// - [argResults]: Command-line argument results
  /// - [currentPath]: Current working directory path
  ///
  /// Returns: A new TemplateTestConfig instance with parsed configuration
  factory TemplateTestConfig.fromArgs(
      ArgResults argResults, String currentPath) {
    final appsName = argResults['apps-name']?.toString().snakeCase;
    final featureName = argResults['feature-name']?.toString().snakeCase ?? '';
    final pageName = argResults['page-name']?.toString().snakeCase ?? '';

    final searchFileJson2Dart = appsName?.isNotEmpty ?? false
        ? '${appsName}_json2dart.yaml'
        : 'json2dart.yaml';

    String pathTestPage = join(
      currentPath,
      'features',
      featureName,
      'test',
      '${pageName}_test',
    );

    if (appsName?.toString().isNotEmpty ?? false) {
      pathTestPage = join(
        currentPath,
        'apps',
        appsName,
        'features',
        featureName,
        'test',
        '${pageName}_test',
      );
    }

    // Default empty map for json2DartMap, will be populated during execution
    final json2DartMap = <String, dynamic>{};

    return TemplateTestConfig(
      appsName: appsName,
      featureName: featureName,
      pageName: pageName,
      searchFileJson2Dart: searchFileJson2Dart,
      pathTestPage: pathTestPage,
      json2DartMap: json2DartMap,
    );
  }
}
