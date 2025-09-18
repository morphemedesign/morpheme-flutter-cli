import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';

/// Configuration model for page generation.
///
/// This class encapsulates all the parameters needed for generating a new page
/// within a feature module, including paths, names, and other configuration data.
class PageConfig {
  /// The name of the apps module (if applicable).
  final String appsName;

  /// The path to the apps module.
  final String pathApps;

  /// The name of the feature module.
  final String featureName;

  /// The name of the page being created.
  final String pageName;

  /// The path to the feature module.
  final String pathFeature;

  /// The path where the page will be created.
  final String pathPage;

  /// The class name in PascalCase.
  final String className;

  /// The method name in camelCase.
  final String methodName;

  /// Creates a new PageConfig instance.
  ///
  /// All parameters are required to ensure complete configuration.
  PageConfig({
    required this.appsName,
    required this.pathApps,
    required this.featureName,
    required this.pageName,
    required this.pathFeature,
    required this.pathPage,
    required this.className,
    required this.methodName,
  });

  /// Creates a PageConfig from command arguments.
  ///
  /// This factory constructor processes command-line arguments and creates
  /// a validated PageConfig object with all necessary parameters.
  ///
  /// Parameters:
  /// - [argResults]: The parsed command-line arguments
  factory PageConfig.fromArguments(ArgResults? argResults) {
    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final pathApps = join(current, 'apps', appsName);
    String featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    final pageName = (argResults?.rest.first ?? '').snakeCase;

    // Adjust feature name if apps context is provided
    if (appsName.isNotEmpty && !RegExp('^${appsName}_').hasMatch(featureName)) {
      featureName = '${appsName}_$featureName';
    }

    String pathFeature = join(current, 'features', featureName);
    if (appsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', featureName);
    }

    final className = pageName.pascalCase;
    final methodName = pageName.camelCase;

    return PageConfig(
      appsName: appsName,
      pathApps: pathApps,
      featureName: featureName,
      pageName: pageName,
      pathFeature: pathFeature,
      pathPage: join(pathFeature, 'lib', pageName),
      className: className,
      methodName: methodName,
    );
  }

  @override
  String toString() {
    return 'PageConfig(appsName: $appsName, pathApps: $pathApps, '
        'featureName: $featureName, pageName: $pageName, '
        'pathFeature: $pathFeature, pathPage: $pathPage, '
        'className: $className, methodName: $methodName)';
  }
}