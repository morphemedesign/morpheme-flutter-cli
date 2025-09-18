import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

import '../models/models.dart';

/// Manages all configuration-related operations for asset generation.
///
/// Handles loading and merging configuration from multiple sources:
/// - morpheme.yaml (primary configuration)
/// - pubspec.yaml (Flutter asset definitions)
/// - Command-line arguments (flavor selection)
///
/// Provides a centralized point for configuration validation and access.
class ConfigurationManager {
  /// Creates a new ConfigurationManager instance.
  const ConfigurationManager();

  /// Loads the complete asset configuration from morpheme.yaml and command arguments.
  ///
  /// Parameters:
  /// - [morphemeYamlPath]: Path to the morpheme.yaml file
  /// - [flavor]: Optional flavor name for environment-specific configuration
  ///
  /// Returns an [AssetConfig] instance with all configuration settings.
  ///
  /// Throws [ConfigurationException] if required configuration is missing or invalid.
  AssetConfig loadAssetConfiguration({
    String? morphemeYamlPath,
    String? flavor,
  }) {
    // Validate and load morpheme.yaml
    final morphemeYaml = _loadMorphemeYaml(morphemeYamlPath);

    // Extract project name
    final projectName = morphemeYaml.projectName;
    if (projectName.isEmpty) {
      throw ConfigurationException(
        'Project name not found in morpheme.yaml',
        suggestions: [
          'Add "project_name: your_project_name" to morpheme.yaml',
          'Ensure morpheme.yaml is properly formatted',
        ],
      );
    }

    // Extract assets configuration
    final assetsConfig = morphemeYaml['assets'];
    if (assetsConfig == null) {
      throw ConfigurationException(
        'Assets configuration not found in morpheme.yaml',
        suggestions: [
          'Add an "assets:" section to morpheme.yaml',
          'Run "morpheme init" to generate a basic configuration',
        ],
      );
    }

    // Create asset configuration
    return AssetConfig.fromMorphemeConfig(
      projectName: projectName,
      assetsConfig: assetsConfig,
      flavor: flavor,
    );
  }

  /// Loads and validates the pubspec.yaml configuration.
  ///
  /// Parameters:
  /// - [config]: The asset configuration containing pubspec directory path
  ///
  /// Returns a list of asset paths defined in pubspec.yaml.
  ///
  /// Throws [ConfigurationException] if pubspec.yaml is invalid or missing.
  List<String> loadPubspecAssets(AssetConfig config) {
    final pubspecPath = config.getPubspecPath();

    if (!exists(pubspecPath)) {
      throw ConfigurationException(
        'pubspec.yaml not found at: $pubspecPath',
        suggestions: [
          'Ensure the pubspec_dir in morpheme.yaml points to the correct directory',
          'Create a pubspec.yaml file in the specified directory',
          'Check that the path is relative to the project root',
        ],
      );
    }

    final pubspecYaml = YamlHelper.loadFileYaml(pubspecPath);

    if (!pubspecYaml.containsKey('flutter')) {
      throw ConfigurationException(
        'Flutter configuration not found in pubspec.yaml',
        suggestions: [
          'Add a "flutter:" section to pubspec.yaml',
          'Ensure this is a Flutter project with proper pubspec.yaml structure',
        ],
      );
    }

    final flutter = pubspecYaml['flutter'];
    if (flutter is! Map || !flutter.containsKey('assets')) {
      throw ConfigurationException(
        'Assets configuration not found in flutter section of pubspec.yaml',
        suggestions: [
          'Add an "assets:" list under the "flutter:" section',
          'Example: flutter:\\n  assets:\\n    - assets/images/',
        ],
      );
    }

    final assetsRaw = flutter['assets'];
    if (assetsRaw is! List) {
      throw ConfigurationException(
        'Assets must be defined as a list in pubspec.yaml',
        suggestions: [
          'Ensure assets is a YAML list, not a single value',
          'Example: assets:\\n  - assets/images/\\n  - assets/icons/',
        ],
      );
    }

    // Filter out density-specific image directories (e.g., 2.0x, 3.0x)
    final assets = assetsRaw
        .cast<String>()
        .where((asset) => !_isDensitySpecificPath(asset))
        .toList();

    if (assets.isEmpty) {
      throw ConfigurationException(
        'No valid asset paths found in pubspec.yaml',
        suggestions: [
          'Add asset directory paths to the assets list',
          'Ensure asset paths exist and are accessible',
          'Example: assets:\\n  - assets/images/\\n  - assets/fonts/',
        ],
      );
    }

    return assets;
  }

  /// Merges flavor-specific assets with the main assets directory.
  ///
  /// If a flavor is specified and the flavor directory exists, copies
  /// flavor-specific assets to the main assets directory before processing.
  ///
  /// Parameters:
  /// - [config]: The asset configuration
  ///
  /// Returns validation result indicating success or failure.
  ValidationResult mergeFlavorAssets(AssetConfig config) {
    if (config.flavor == null || config.flavor!.isEmpty) {
      return ValidationResult.success();
    }

    final flavorPath = config.getFlavorPath();
    if (flavorPath == null || !exists(flavorPath)) {
      return ValidationResult.success(
        warnings: [
          ValidationWarning(
            message:
                'Flavor directory not found: ${flavorPath ?? config.flavorDir}/${config.flavor}',
            type: ValidationWarningType.general,
          ),
        ],
        suggestions: [
          'Create the flavor directory: ${config.flavorDir}/${config.flavor}',
          'Ensure the flavor name is correct',
          'Check that flavor_dir is properly configured in morpheme.yaml',
        ],
      );
    }

    try {
      final assetsPath = config.getAssetsPath();
      copyTree(flavorPath, assetsPath, overwrite: true);

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure(
        errors: [
          ValidationError(
            message: 'Failed to merge flavor assets: $e',
            type: ValidationErrorType.fileSystem,
          ),
        ],
        suggestions: [
          'Check file permissions for flavor and assets directories',
          'Ensure sufficient disk space is available',
          'Verify that both source and destination paths are valid',
        ],
      );
    }
  }

  /// Validates that all required configuration paths exist and are accessible.
  ///
  /// Parameters:
  /// - [config]: The asset configuration to validate
  ///
  /// Returns a validation result with any path-related issues.
  ValidationResult validateConfigurationPaths(AssetConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    // Validate pubspec directory
    final pubspecDir = join(current, config.pubspecDir);
    if (!exists(pubspecDir)) {
      errors.add(ValidationError(
        message: 'Pubspec directory does not exist: ${config.pubspecDir}',
        field: 'pubspec_dir',
        type: ValidationErrorType.missing,
      ));
      suggestions.add('Create the pubspec directory: ${config.pubspecDir}');
    }

    // Validate assets directory
    final assetsDir = join(current, config.assetsDir);
    if (!exists(assetsDir)) {
      warnings.add(ValidationWarning(
        message: 'Assets directory does not exist: ${config.assetsDir}',
        field: 'assets_dir',
        type: ValidationWarningType.general,
      ));
      suggestions.add('Create the assets directory: ${config.assetsDir}');
    }

    // Validate flavor directory (if flavor is specified)
    if (config.flavor != null && config.flavor!.isNotEmpty) {
      final flavorPath = config.getFlavorPath();
      if (flavorPath != null && !exists(flavorPath)) {
        warnings.add(ValidationWarning(
          message: 'Flavor directory does not exist: $flavorPath',
          field: 'flavor_dir',
          type: ValidationWarningType.general,
        ));
        suggestions.add('Create the flavor directory: $flavorPath');
      }
    }

    // Check output directory write permissions
    final outputDir = config.getOutputPath();
    try {
      createDir(outputDir);
    } catch (e) {
      errors.add(ValidationError(
        message: 'Cannot create output directory: $outputDir - $e',
        field: 'output_dir',
        type: ValidationErrorType.permission,
      ));
      suggestions.add('Check write permissions for the output directory');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Loads morpheme.yaml and validates its existence.
  Map<dynamic, dynamic> _loadMorphemeYaml(String? morphemeYamlPath) {
    try {
      YamlHelper.validateMorphemeYaml(morphemeYamlPath);
      final path = morphemeYamlPath ?? join(current, 'morpheme.yaml');
      return YamlHelper.loadFileYaml(path);
    } catch (e) {
      throw ConfigurationException(
        'Failed to load morpheme.yaml: $e',
        suggestions: [
          'Ensure morpheme.yaml exists in the project root',
          'Run "morpheme init" to create a basic configuration',
          'Check that the YAML syntax is valid',
        ],
      );
    }
  }

  /// Checks if an asset path is density-specific (e.g., 2.0x, 3.0x directories).
  bool _isDensitySpecificPath(String path) {
    return RegExp(r'(0|[1-9]\d*)\.?(0|[1-9]\d*)?\.?(0|[1-9]\d*)?x')
        .hasMatch(path);
  }
}

/// Exception thrown when configuration loading or validation fails.
class ConfigurationException implements Exception {
  /// The primary error message.
  final String message;

  /// List of suggestions for resolving the configuration issue.
  final List<String> suggestions;

  /// Creates a new ConfigurationException.
  const ConfigurationException(
    this.message, {
    this.suggestions = const [],
  });

  @override
  String toString() {
    final buffer = StringBuffer('ConfigurationException: $message');

    if (suggestions.isNotEmpty) {
      buffer.write('\nSuggestions:');
      for (final suggestion in suggestions) {
        buffer.write('\n  - $suggestion');
      }
    }

    return buffer.toString();
  }
}
