import 'package:morpheme_cli/helper/yaml_helper.dart';

import '../models/api_generation_config.dart';
import '../models/project_configuration.dart';

/// Manages API generation configuration and project settings.
///
/// Loads project configuration from morpheme.yaml and processes
/// generation-specific options like cache strategies and return data types.
class ApiConfigurationManager {
  /// Loads and processes project configuration.
  ///
  /// Parameters:
  /// - [morphemeYamlPath]: Path to morpheme.yaml configuration file
  /// - [generationConfig]: API generation configuration
  ///
  /// Returns [ProjectConfiguration] with loaded settings
  ProjectConfiguration loadConfiguration(
    String morphemeYamlPath,
    ApiGenerationConfig generationConfig,
  ) {
    try {
      final yamlData = YamlHelper.loadFileYaml(morphemeYamlPath);

      return ProjectConfiguration(
        projectName: yamlData['project_name'] ?? yamlData['name'] ?? 'morpheme',
        morphemeYamlPath: morphemeYamlPath,
        additionalSettings: _extractAdditionalSettings(yamlData),
      );
    } catch (e) {
      throw ConfigurationException(
          'Failed to load project configuration from $morphemeYamlPath: $e');
    }
  }

  /// Validates configuration compatibility and constraints.
  ///
  /// Ensures that the combination of configuration options is valid
  /// and follows the expected patterns.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration to validate
  ///
  /// Throws [ConfigurationException] if configuration is invalid
  void validateConfiguration(ApiGenerationConfig config) {
    // Validate cache strategy is only used with compatible methods
    if (config.cacheStrategy != null && !_isApplyCacheStrategy(config.method)) {
      throw ConfigurationException(
          'Cache strategy cannot be used with method "${config.method}". '
          'Cache strategies are not supported for multipart and SSE methods.');
    }

    // Validate TTL is only provided when cache strategy is set
    if (config.ttl != null && config.cacheStrategy == null) {
      throw ConfigurationException(
          'TTL can only be specified when a cache strategy is provided.');
    }

    // Validate keep expired cache is only provided when cache strategy is set
    if (config.keepExpiredCache != null && config.cacheStrategy == null) {
      throw ConfigurationException(
          'Keep expired cache can only be specified when a cache strategy is provided.');
    }

    // Validate body list is not used with multipart methods
    if (config.bodyList && _isMultipart(config.method)) {
      throw ConfigurationException(
          'Body list cannot be used with multipart methods.');
    }
  }

  /// Processes and normalizes configuration options.
  ///
  /// Applies business rules and defaults to ensure configuration
  /// is consistent and ready for generation.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration to process
  ///
  /// Returns processed [ApiGenerationConfig]
  ApiGenerationConfig processConfiguration(ApiGenerationConfig config) {
    // Apply method-specific adjustments
    // Determine if cache strategy should be applied
    final shouldApplyCacheStrategy = isApplyCacheStrategy(config.method);

    // Create a new config with appropriate values
    return ApiGenerationConfig(
      apiName: config.apiName,
      featureName: config.featureName,
      pageName: config.pageName,
      method: config.method,
      pathPage: config.pathPage,
      projectName: config.projectName,
      returnData: config.returnData,
      appsName: config.appsName,
      pathUrl: config.pathUrl,
      headerPath: config.headerPath,
      json2dart: config.json2dart,
      bodyList: config.bodyList && !isMultipart(config.method),
      responseList: config.responseList,
      // Remove cache strategy for methods that don't support it
      cacheStrategy: shouldApplyCacheStrategy ? config.cacheStrategy : null,
      ttl: shouldApplyCacheStrategy ? config.ttl : null,
      keepExpiredCache:
          shouldApplyCacheStrategy ? config.keepExpiredCache : null,
    );
  }

  /// Extracts additional settings from the YAML data
  Map<String, dynamic>? _extractAdditionalSettings(dynamic yamlData) {
    if (yamlData == null) return null;

    // This can be extended to extract additional project-specific settings
    // from the morpheme.yaml file as needed
    return <String, dynamic>{};
  }

  /// Checks if the method supports cache strategies
  bool isApplyCacheStrategy(String method) {
    return !_isMultipart(method) && !_isSse(method);
  }

  /// Checks if the method is a multipart method
  bool isMultipart(String method) {
    return method.toLowerCase().contains('multipart');
  }

  /// Checks if the method is a Server-Sent Events method
  bool isSse(String method) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return true;
      default:
        return false;
    }
  }

  /// Checks if the method supports cache strategies (private helper)
  bool _isApplyCacheStrategy(String method) {
    return !isMultipart(method) && !isSse(method);
  }

  /// Checks if the method is a multipart method (private helper)
  bool _isMultipart(String method) {
    return method.toLowerCase().contains('multipart');
  }

  /// Checks if the method is a Server-Sent Events method (private helper)
  bool _isSse(String method) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return true;
      default:
        return false;
    }
  }
}

/// Exception thrown when configuration loading or validation fails
class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}
