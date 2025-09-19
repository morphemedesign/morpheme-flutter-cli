/// Configuration model for feature generation.
///
/// This class encapsulates all the parameters needed for generating a new feature module.
class FeatureConfig {
  /// The name of the feature being created.
  final String featureName;

  /// The name of the apps module (if applicable).
  final String appsName;

  /// The path where the feature will be created.
  final String featurePath;

  /// The path to the apps module (if applicable).
  final String appsPath;

  /// Indicates if the feature is within an apps module.
  final bool isInApps;

  /// Creates a new FeatureConfig instance.
  ///
  /// All parameters are required to ensure complete configuration.
  FeatureConfig({
    required this.featureName,
    required this.appsName,
    required this.featurePath,
    required this.appsPath,
    required this.isInApps,
  });

  @override
  String toString() {
    return 'FeatureConfig(featureName: $featureName, appsName: $appsName, '
        'featurePath: $featurePath, appsPath: $appsPath, isInApps: $isInApps)';
  }
}
