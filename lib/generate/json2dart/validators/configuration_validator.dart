import 'dart:io';

import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

import '../models/json2dart_config.dart';

/// Validates Json2Dart configuration and settings
///
/// This validator ensures configuration files are properly formatted,
/// contain valid settings, and have accessible file paths.
class ConfigurationValidator {
  final bool _verbose;

  ConfigurationValidator({bool verbose = false}) : _verbose = verbose;

  /// Validates a Json2Dart configuration
  ///
  /// [config] - Configuration to validate
  /// Returns validation result with any errors found
  ValidationResult<void> validateConfiguration(Json2DartConfig config) {
    try {
      final errors = <String>[];

      // Validate feature and page name consistency
      _validateFeaturePageConsistency(config, errors);

      // Validate file paths
      _validateFilePaths(config, errors);

      // Validate configuration combinations
      _validateConfigurationCombinations(config, errors);

      // Validate format patterns
      _validateFormatPatterns(config, errors);

      if (errors.isNotEmpty) {
        return ValidationResult.error(
          'Configuration validation failed:\n${errors.join('\n')}',
        );
      }

      if (_verbose) {
        StatusHelper.success('Configuration validation passed');
      }

      return ValidationResult.success(null);
    } catch (e, stackTrace) {
      final error = 'Unexpected error during configuration validation: $e';
      if (_verbose) {
        StatusHelper.failed('$error\nStack trace: $stackTrace');
      }
      return ValidationResult.error(error);
    }
  }

  /// Validates feature and page name consistency
  void _validateFeaturePageConsistency(
      Json2DartConfig config, List<String> errors) {
    // If page name is specified, feature name must also be specified
    if (config.pageName != null && config.featureName == null) {
      errors.add(
        'Page name "${config.pageName}" specified without feature name. '
        'Feature name is required when specifying a page name.',
      );
    }

    // Validate naming conventions
    if (config.featureName != null) {
      if (!_isValidIdentifier(config.featureName!)) {
        errors.add(
          'Feature name "${config.featureName}" is not a valid identifier. '
          'Use alphanumeric characters and underscores only.',
        );
      }
    }

    if (config.pageName != null) {
      if (!_isValidIdentifier(config.pageName!)) {
        errors.add(
          'Page name "${config.pageName}" is not a valid identifier. '
          'Use alphanumeric characters and underscores only.',
        );
      }
    }

    if (config.appsName != null) {
      if (!_isValidIdentifier(config.appsName!)) {
        errors.add(
          'Apps name "${config.appsName}" is not a valid identifier. '
          'Use alphanumeric characters and underscores only.',
        );
      }
    }
  }

  /// Validates file paths and accessibility
  void _validateFilePaths(Json2DartConfig config, List<String> errors) {
    // Check if json2dart directory exists when not initializing
    final json2dartDir = join(current, 'json2dart');
    if (!Directory(json2dartDir).existsSync()) {
      errors.add(
        'Json2dart directory not found: $json2dartDir. '
        'Run "morpheme json2dart init" to create the initial structure.',
      );
      return; // No point checking further if base directory doesn't exist
    }

    // Validate configuration file existence
    final configFile = config.appsName?.isNotEmpty ?? false
        ? '${config.appsName}_json2dart.yaml'
        : 'json2dart.yaml';

    final configPath = join(json2dartDir, configFile);
    if (!File(configPath).existsSync()) {
      errors.add(
        'Configuration file not found: $configPath. '
        'Create the configuration file or run "morpheme json2dart init".',
      );
    }

    // Validate feature directories if specific feature is requested
    if (config.featureName != null) {
      final featurePath = _getFeaturePath(config);
      if (featurePath != null && !Directory(featurePath).existsSync()) {
        errors.add(
          'Feature directory not found: $featurePath. '
          'Create the feature directory first.',
        );
      }
    }
  }

  /// Validates configuration combinations for logical consistency
  void _validateConfigurationCombinations(
      Json2DartConfig config, List<String> errors) {
    // Only unit test mode should not generate API
    if (config.isOnlyUnitTest && config.isApi) {
      errors.add(
        'Conflicting configuration: "only-unit-test" mode should not generate API. '
        'Set "api" to false when using "only-unit-test".',
      );
    }

    // Only unit test mode should not generate endpoints
    if (config.isOnlyUnitTest && config.isEndpoint) {
      errors.add(
        'Conflicting configuration: "only-unit-test" mode should not generate endpoints. '
        'Set "endpoint" to false when using "only-unit-test".',
      );
    }

    // Unit test requires API to be enabled unless only-unit-test
    if (config.isUnitTest && !config.isApi && !config.isOnlyUnitTest) {
      errors.add(
        'Invalid configuration: Unit test generation requires API generation to be enabled. '
        'Set "api" to true or use "only-unit-test" mode.',
      );
    }

    // Cubit generation requires API
    if (config.isCubit && !config.isApi && !config.isOnlyUnitTest) {
      errors.add(
        'Invalid configuration: Cubit generation requires API generation to be enabled. '
        'Set "api" to true when using cubit generation.',
      );
    }

    // Replace mode requires API generation
    if (config.isReplace && !config.isApi && !config.isOnlyUnitTest) {
      errors.add(
        'Invalid configuration: Replace mode requires API generation to be enabled. '
        'Set "api" to true when using replace mode.',
      );
    }
  }

  /// Validates date format patterns
  void _validateFormatPatterns(Json2DartConfig config, List<String> errors) {
    // Validate body date format
    if (!_isValidDateFormat(config.bodyDateFormat)) {
      errors.add(
        'Invalid body date format: "${config.bodyDateFormat}". '
        'Use a valid format like ".toIso8601String()" or ".toFormatDateTimeBody(\'yyyy-MM-dd\')".',
      );
    }

    // Validate response date format
    if (!_isValidDateFormat(config.responseDateFormat)) {
      errors.add(
        'Invalid response date format: "${config.responseDateFormat}". '
        'Use a valid format like ".toIso8601String()" or ".toFormatDateTimeResponse(\'yyyy-MM-dd\')".',
      );
    }
  }

  /// Validates API configuration within a page
  ValidationResult<void> validateApiConfiguration(
    String apiName,
    Map<String, dynamic> apiConfig,
  ) {
    try {
      final errors = <String>[];

      // Validate required fields
      _validateRequiredApiFields(apiName, apiConfig, errors);

      // Validate method
      _validateHttpMethod(apiName, apiConfig, errors);

      // Validate file paths
      _validateApiFilePaths(apiName, apiConfig, errors);

      // Validate cache strategy
      _validateCacheStrategy(apiName, apiConfig, errors);

      // Validate return data type
      _validateReturnDataType(apiName, apiConfig, errors);

      if (errors.isNotEmpty) {
        return ValidationResult.error(
          'API "$apiName" validation failed:\n${errors.join('\n')}',
        );
      }

      return ValidationResult.success(null);
    } catch (e) {
      return ValidationResult.error(
        'Unexpected error validating API "$apiName": $e',
      );
    }
  }

  /// Validates required API fields
  void _validateRequiredApiFields(
    String apiName,
    Map<String, dynamic> apiConfig,
    List<String> errors,
  ) {
    final requiredFields = ['method', 'path'];

    for (final field in requiredFields) {
      if (!apiConfig.containsKey(field) || apiConfig[field] == null) {
        errors.add('Missing required field "$field" in API "$apiName"');
      }
    }
  }

  /// Validates HTTP method
  void _validateHttpMethod(
    String apiName,
    Map<String, dynamic> apiConfig,
    List<String> errors,
  ) {
    final method = apiConfig['method'] as String?;
    if (method == null) return;

    final validMethods = {
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'getSse',
      'postSse',
      'putSse',
      'patchSse',
      'deleteSse',
      'multipart',
      'postMultipart',
      'patchMultipart',
    };

    if (!validMethods.contains(method.toLowerCase())) {
      errors.add(
        'Invalid HTTP method "$method" in API "$apiName". '
        'Valid methods: ${validMethods.join(', ')}',
      );
    }
  }

  /// Validates API file paths
  void _validateApiFilePaths(
    String apiName,
    Map<String, dynamic> apiConfig,
    List<String> errors,
  ) {
    // Validate body file
    final bodyPath = apiConfig['body'] as String?;
    if (bodyPath != null && !File(bodyPath).existsSync()) {
      errors.add('Body file not found for API "$apiName": $bodyPath');
    }

    // Validate response file
    final responsePath = apiConfig['response'] as String?;
    if (responsePath != null && !File(responsePath).existsSync()) {
      errors.add('Response file not found for API "$apiName": $responsePath');
    }

    // Validate header file
    final headerPath = apiConfig['header'] as String?;
    if (headerPath != null && !File(headerPath).existsSync()) {
      errors.add('Header file not found for API "$apiName": $headerPath');
    }
  }

  /// Validates cache strategy configuration
  void _validateCacheStrategy(
    String apiName,
    Map<String, dynamic> apiConfig,
    List<String> errors,
  ) {
    final cacheStrategy = apiConfig['cache_strategy'];
    if (cacheStrategy == null) return;

    if (cacheStrategy is String) {
      _validateCacheStrategyString(apiName, cacheStrategy, errors);
    } else if (cacheStrategy is Map) {
      _validateCacheStrategyMap(apiName, cacheStrategy, errors);
    } else {
      errors.add(
        'Invalid cache strategy type in API "$apiName". '
        'Must be a string or object.',
      );
    }
  }

  /// Validates string cache strategy
  void _validateCacheStrategyString(
    String apiName,
    String strategy,
    List<String> errors,
  ) {
    final validStrategies = {
      'async_or_cache',
      'cache_or_async',
      'just_async',
      'just_cache',
    };

    if (!validStrategies.contains(strategy)) {
      errors.add(
        'Invalid cache strategy "$strategy" in API "$apiName". '
        'Valid strategies: ${validStrategies.join(', ')}',
      );
    }
  }

  /// Validates map cache strategy
  void _validateCacheStrategyMap(
    String apiName,
    Map<dynamic, dynamic> strategyMap,
    List<String> errors,
  ) {
    final strategy = strategyMap['strategy'] as String?;
    if (strategy != null) {
      _validateCacheStrategyString(apiName, strategy, errors);
    }

    final ttl = strategyMap['ttl'];
    if (ttl != null && ttl is! int) {
      errors.add(
        'Invalid TTL value in API "$apiName". Must be an integer.',
      );
    }

    final keepExpiredCache = strategyMap['keep_expired_cache'];
    if (keepExpiredCache != null && keepExpiredCache is! bool) {
      errors.add(
        'Invalid keep_expired_cache value in API "$apiName". Must be a boolean.',
      );
    }
  }

  /// Validates return data type
  void _validateReturnDataType(
    String apiName,
    Map<String, dynamic> apiConfig,
    List<String> errors,
  ) {
    final returnData = apiConfig['return_data'] as String?;
    if (returnData == null) return;

    final validReturnTypes = {
      'model',
      'header',
      'body_bytes',
      'body_string',
      'status_code',
      'raw',
    };

    if (!validReturnTypes.contains(returnData)) {
      errors.add(
        'Invalid return data type "$returnData" in API "$apiName". '
        'Valid types: ${validReturnTypes.join(', ')}',
      );
    }
  }

  /// Gets the feature path based on configuration
  String? _getFeaturePath(Json2DartConfig config) {
    if (config.featureName == null) return null;

    if (config.appsName?.isNotEmpty ?? false) {
      return join(
          current, 'apps', config.appsName!, 'features', config.featureName!);
    }

    return join(current, 'features', config.featureName!);
  }

  /// Checks if a string is a valid identifier
  bool _isValidIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }

  /// Checks if a date format is valid
  bool _isValidDateFormat(String format) {
    // Check for common valid formats
    return format == '.toIso8601String()' ||
        format.startsWith('.toFormatDateTimeBody(') ||
        format.startsWith('.toFormatDateTimeResponse(');
  }
}

/// Represents the result of a validation operation
class ValidationResult<T> {
  final T? data;
  final String? error;
  final bool isValid;

  const ValidationResult._(this.data, this.error, this.isValid);

  factory ValidationResult.success(T? data) {
    return ValidationResult._(data, null, true);
  }

  factory ValidationResult.error(String error) {
    return ValidationResult._(null, error, false);
  }
}
