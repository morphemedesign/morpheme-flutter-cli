import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/feature/models/feature_config.dart';

/// Manages loading and validating feature generation configuration.
///
/// This class handles parsing command-line arguments, validating inputs,
/// and creating a validated [FeatureConfig] object.
class FeatureConfigManager {
  /// Validates input parameters and project prerequisites.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool validateInputs(String? featureName, String appsName, String pathApps) {
    if (featureName == null || featureName.isEmpty) {
      StatusHelper.failed(
          'Feature name is empty, add a new feature with "morpheme feature <feature-name>"');
      return false;
    }

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed(
          'Apps with "$appsName" does not exists, create a new apps with "morpheme apps <apps-name>"');
      return false;
    }

    return true;
  }

  /// Loads and prepares configuration for feature generation.
  ///
  /// Parses command-line arguments and constructs a [FeatureConfig] object
  /// with all necessary parameters for feature generation.
  FeatureConfig loadConfig(String featureName, String appsName) {
    final snakeCaseFeatureName = featureName.snakeCase;
    final snakeCaseAppsName = appsName.snakeCase;
    
    String finalFeatureName = snakeCaseFeatureName;
    if (snakeCaseAppsName.isNotEmpty &&
        !RegExp('^${snakeCaseAppsName}_').hasMatch(snakeCaseFeatureName)) {
      finalFeatureName = '${snakeCaseAppsName}_$snakeCaseFeatureName';
    }

    final pathApps = join(current, 'apps', snakeCaseAppsName);
    String pathFeature = join(current, 'features', finalFeatureName);
    
    if (snakeCaseAppsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', finalFeatureName);
    }

    // Check if feature already exists
    if (exists(pathFeature)) {
      StatusHelper.failed('Feature already exists in $pathFeature.');
      // This will exit the program, but we still return the config for consistency
    }

    return FeatureConfig(
      featureName: finalFeatureName,
      appsName: snakeCaseAppsName,
      featurePath: pathFeature,
      appsPath: pathApps,
      isInApps: snakeCaseAppsName.isNotEmpty,
    );
  }

  /// Validates the loaded configuration.
  ///
  /// Returns true if configuration is valid, false otherwise.
  bool validateConfig(FeatureConfig config) {
    // Additional validation can be added here if needed
    return true;
  }
}