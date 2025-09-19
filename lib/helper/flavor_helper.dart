import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

/// Helper class for flavor configuration operations.
///
/// This class provides utilities for retrieving flavor-specific
/// configuration from the morpheme.yaml file.
abstract class FlavorHelper {
  /// Retrieves flavor-specific configuration from morpheme.yaml.
  ///
  /// This method extracts the configuration for a specific flavor
  /// from the morpheme.yaml configuration file. If the specified
  /// flavor is not found, it reports an error and exits the application.
  ///
  /// Parameters:
  /// - [flavor]: The flavor name to retrieve configuration for (e.g., 'dev', 'staging', 'prod')
  /// - [pathMorphemeYaml]: The path to the morpheme.yaml configuration file
  ///
  /// Returns: A map containing the flavor-specific configuration
  ///
  /// Example:
  /// ```dart
  /// // Get configuration for the 'dev' flavor
  /// final devConfig = FlavorHelper.byFlavor('dev', './morpheme.yaml');
  /// final appId = devConfig['app_id'];
  /// print('Development app ID: $appId');
  /// ```
  ///
  /// Note: If the specified flavor is not found in the configuration,
  /// this method will terminate the application with an error message.
  static Map<dynamic, dynamic> byFlavor(
      String flavor, String pathMorphemeYaml) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapFlavor = yaml['flavor'] ?? {};
    final map = mapFlavor[flavor] ?? {};
    if (map.isEmpty) {
      StatusHelper.failed('Flavor $flavor not found in morpheme.yaml');
    }
    return map;
  }
}
