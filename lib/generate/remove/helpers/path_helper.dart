import 'package:morpheme_cli/dependency_manager.dart';

/// Helper class for path construction in remove commands.
abstract class PathHelper {
  /// Gets the path for an app directory.
  static String getAppsPath(String appsName) {
    return join(current, 'apps', appsName);
  }

  /// Gets the path for a feature directory.
  static String getFeaturePath(String appsName, String featureName) {
    if (appsName.isNotEmpty) {
      return join(current, 'apps', appsName, 'features', featureName);
    }
    return join(current, 'features', featureName);
  }

  /// Gets the path for a page directory.
  static String getPagePath(
      String appsName, String featureName, String pageName) {
    return join(getFeaturePath(appsName, featureName), 'lib', pageName);
  }

  /// Gets the path for a feature test directory.
  static String getFeatureTestPath(String appsName, String featureName) {
    if (appsName.isNotEmpty) {
      return join(current, 'apps', appsName, 'features', featureName, 'test');
    }
    return join(current, 'features', featureName, 'test');
  }

  /// Gets the path for a page test directory.
  static String getPageTestPath(
      String appsName, String featureName, String pageName) {
    return join(getFeatureTestPath(appsName, featureName), '${pageName}_test');
  }

  /// Gets the path for an app test directory.
  static String getAppsTestPath(String appsName) {
    return join(current, 'apps', '${appsName}_test');
  }
}
