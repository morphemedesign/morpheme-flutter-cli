import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

/// Helper class for Shorebird configuration operations.
///
/// This class provides utilities for retrieving Shorebird configuration
/// from the morpheme.yaml file and generating shorebird.yaml files.
abstract class ShorebirdHelper {
  /// Retrieves Shorebird configuration for a specific flavor.
  ///
  /// This method extracts the Shorebird configuration for a given flavor
  /// from the morpheme.yaml configuration file, including the Flutter version
  /// and flavor-specific settings.
  ///
  /// Parameters:
  /// - [flavor]: The flavor name to retrieve configuration for
  /// - [pathMorphemeYaml]: The path to the morpheme.yaml configuration file
  ///
  /// Returns: A tuple containing:
  ///   - The Flutter version string (may be null)
  ///   - A map containing flavor-specific configuration (may be null)
  ///
  /// Example:
  /// ```dart
  /// final (version, config) = ShorebirdHelper.byFlavor('prod', './morpheme.yaml');
  /// if (version != null) {
  ///   print('Shorebird Flutter version: $version');
  /// }
  /// if (config != null && config.isNotEmpty) {
  ///   final appId = config['app_id'];
  ///   print('Shorebird app ID: $appId');
  /// }
  /// ```
  static (String? version, Map<dynamic, dynamic>? map) byFlavor(
    String flavor,
    String pathMorphemeYaml,
  ) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapShorebird = yaml['shorebird'] ?? {};
    final flutterVersion = mapShorebird['flutter_version'];

    // Get the flavor configuration and handle type safety
    final flavorData = mapShorebird['flavor'];
    Map<dynamic, dynamic>? mapFlavor;

    if (flavorData is Map && flavorData.containsKey(flavor)) {
      final flavorValue = flavorData[flavor];
      if (flavorValue is Map) {
        mapFlavor = flavorValue;
      } else {
        // If the flavor value is not a Map (e.g., it's a String), create an empty map
        mapFlavor = <dynamic, dynamic>{};
      }
    } else {
      mapFlavor = <dynamic, dynamic>{};
    }

    return (flutterVersion, mapFlavor);
  }

  /// Writes a shorebird.yaml configuration file.
  ///
  /// This method generates a shorebird.yaml file with the provided
  /// configuration settings. The generated file includes the app_id
  /// and auto_update settings required by the Shorebird updater.
  ///
  /// Parameters:
  /// - [map]: A map containing the Shorebird configuration settings
  ///   - Must include 'app_id' key
  ///   - May include 'auto_update' key (defaults to true)
  ///
  /// Example:
  /// ```dart
  /// final config = {
  ///   'app_id': 'your-shorebird-app-id',
  ///   'auto_update': true,
  /// };
  /// ShorebirdHelper.writeShorebirdYaml(config);
  /// ```
  ///
  /// Throws: ArgumentError if 'app_id' is not provided in the configuration
  static void writeShorebirdYaml(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) return;

    final appId = map['app_id'];
    if (appId == null) {
      throw ArgumentError('app_id is required in shorebird configuration');
    }

    final autoUpdate = map['auto_update'] ?? true;
    join(current, 'shorebird.yaml').write(
        '''# This file is used to configure the Shorebird updater used by your app.
# Learn more at https://docs.shorebird.dev
# This file does not contain any sensitive information and should be checked into version control.

# Your app_id is the unique identifier assigned to your app.
# It is used to identify your app when requesting patches from Shorebird's servers.
# It is not a secret and can be shared publicly.
app_id: $appId

# auto_update controls if Shorebird should automatically update in the background on launch.
# If auto_update: false, you will need to use package:shorebird_code_push to trigger updates.
# https://pub.dev/packages/shorebird_code_push
# Uncomment the following line to disable automatic updates.
auto_update: $autoUpdate
''');
  }
}
