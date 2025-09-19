import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/color2dart/models/color2dart_config.dart';

/// Manages configuration loading and validation for Color2Dart command.
///
/// This class is responsible for:
/// - Loading configuration from morpheme.yaml and command-line arguments
/// - Validating configuration parameters
/// - Preparing flavor paths for generation
/// - Creating structured configuration objects
class Color2DartConfigManager {
  /// Loads and validates configuration for the Color2Dart command.
  ///
  /// This method combines command-line arguments with morpheme.yaml configuration
  /// to create a complete configuration object.
  ///
  /// Parameters:
  /// - [argResults]: Command-line argument results
  /// - [morphemeYamlPath]: Path to the morpheme.yaml file
  ///
  /// Returns: A validated Color2DartConfig object
  ///
  /// Throws: [Exception] if configuration is invalid
  Color2DartConfig loadConfig(
    ArgResults? argResults,
    String morphemeYamlPath,
  ) {
    // Load morpheme.yaml configuration
    final morphemeYaml = YamlHelper.loadFileYaml(morphemeYamlPath);

    // Validate color2dart section exists
    if (morphemeYaml['color2dart'] == null) {
      throw Exception('color2dart not found in $morphemeYamlPath');
    }

    final morphemeColor2dart = morphemeYaml['color2dart'] as Map;

    // Extract configuration values
    final color2dartDir =
        morphemeColor2dart['color2dart_dir']?.toString() ?? 'color2dart';
    final outputDir = morphemeColor2dart['output_dir']?.toString();

    // Set default paths
    String pathColors = join('core', 'lib', 'src', 'themes', 'morpheme_colors');
    String pathThemes = join('core', 'lib', 'src', 'themes', 'morpheme_themes');

    // Override paths if output_dir is specified
    if (outputDir != null) {
      pathColors = join(outputDir, 'morpheme_colors');
      pathThemes = join(outputDir, 'morpheme_themes');
    }

    // Extract command-line arguments
    final clearFiles = argResults?['clear-files'] as bool? ?? false;
    final allFlavor = argResults?['all-flavor'] as bool? ?? false;
    final flavor = argResults.getOptionFlavor(defaultTo: '');

    // Determine color YAML path based on flavor
    String pathColorYaml = join(current, color2dartDir, 'color2dart.yaml');

    if (flavor.isNotEmpty) {
      pathColorYaml = join(current, color2dartDir, flavor, 'color2dart.yaml');
    }

    // Find all flavor paths if all-flavor flag is set
    final flavorPaths = allFlavor
        ? find(
            'color2dart.yaml',
            recursive: true,
            types: [Find.file],
            workingDirectory: join(current, color2dartDir),
          ).toList()
        : [pathColorYaml];

    // Create and return the configuration object
    return Color2DartConfig(
      morphemeYamlPath: morphemeYamlPath,
      clearFiles: clearFiles,
      allFlavor: allFlavor,
      flavor: flavor,
      outputDir: outputDir ?? '',
      color2dartDir: color2dartDir,
      pathColors: pathColors,
      pathThemes: pathThemes,
      flavorPaths: flavorPaths,
    );
  }

  /// Validates the configuration parameters.
  ///
  /// This method performs validation checks on the configuration to ensure
  /// all required parameters are present and valid.
  ///
  /// Parameters:
  /// - [config]: The configuration to validate
  ///
  /// Returns: true if configuration is valid, false otherwise
  bool validateConfig(Color2DartConfig config) {
    // Check if morpheme.yaml file exists
    if (!exists(config.morphemeYamlPath)) {
      StatusHelper.failed(
          'morpheme.yaml not found at ${config.morphemeYamlPath}');
      return false;
    }

    // Validate color2dart directory
    if (config.color2dartDir.isEmpty) {
      StatusHelper.failed('color2dart_dir is required in morpheme.yaml');
      return false;
    }

    // Validate flavor paths
    if (config.flavorPaths.isEmpty) {
      StatusHelper.failed('No flavor paths found');
      return false;
    }

    return true;
  }
}
