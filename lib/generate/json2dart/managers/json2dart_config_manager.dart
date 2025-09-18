import 'package:morpheme_cli/dependency_manager.dart';

import '../models/json2dart_config.dart';

/// Manages configuration loading and parsing for Json2Dart command
///
/// This class handles loading configuration from YAML files, command line arguments,
/// and provides methods to merge and validate configurations.
class Json2DartConfigManager {
  static const String _defaultBodyDateFormat = '.toIso8601String()';
  static const String _defaultResponseDateFormat = '.toIso8601String()';

  /// Loads configuration from YAML file and command line arguments
  ///
  /// [yamlConfig] - Configuration from the YAML file
  /// [argResults] - Command line arguments
  /// Returns a validated [Json2DartConfig] instance
  Json2DartConfig loadConfig(
    Map<dynamic, dynamic> yamlConfig,
    ArgResults? argResults,
  ) {
    // Extract YAML configuration
    final config = _extractYamlConfig(yamlConfig);

    // Override with command line arguments
    final finalConfig = _mergeWithArguments(config, argResults);

    // Validate configuration
    final errors = finalConfig.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError(
          'Configuration validation failed:\n${errors.join('\n')}');
    }

    return finalConfig;
  }

  /// Extracts configuration from YAML content
  Json2DartConfig _extractYamlConfig(Map<dynamic, dynamic> yamlConfig) {
    // Convert the dynamic map to string map to ensure type safety
    final convertedConfig = _convertMapToStringDynamic(yamlConfig);
    final json2DartSection =
        convertedConfig['json2dart'] as Map<String, dynamic>?;

    if (json2DartSection == null) {
      return const Json2DartConfig();
    }

    return Json2DartConfig(
      isApi: _getBoolValue(json2DartSection, 'api', true),
      isEndpoint: _getBoolValue(json2DartSection, 'endpoint', true),
      isUnitTest: _getBoolValue(json2DartSection, 'unit-test', false),
      isReplace: _getBoolValue(json2DartSection, 'replace', false),
      isFormat: _getBoolValue(json2DartSection, 'format', true),
      isCubit: _getBoolValue(json2DartSection, 'cubit', true),
      bodyDateFormat: _getDateFormat(
        json2DartSection,
        'body_format_date_time',
        _defaultBodyDateFormat,
      ),
      responseDateFormat: _getDateFormat(
        json2DartSection,
        'response_format_date_time',
        _defaultResponseDateFormat,
      ),
    );
  }

  /// Merges YAML configuration with command line arguments
  Json2DartConfig _mergeWithArguments(
    Json2DartConfig yamlConfig,
    ArgResults? argResults,
  ) {
    if (argResults == null) return yamlConfig;

    return yamlConfig.copyWith(
      isApi: _getArgBool(argResults, 'api') ?? yamlConfig.isApi,
      isEndpoint: _getArgBool(argResults, 'endpoint') ?? yamlConfig.isEndpoint,
      isUnitTest: _getArgBool(argResults, 'unit-test') ?? yamlConfig.isUnitTest,
      isOnlyUnitTest: _getArgBool(argResults, 'only-unit-test') ??
          yamlConfig.isOnlyUnitTest,
      isReplace: _getArgBool(argResults, 'replace') ?? yamlConfig.isReplace,
      isFormat: _getArgBool(argResults, 'format') ?? yamlConfig.isFormat,
      isCubit: _getArgBool(argResults, 'cubit') ?? yamlConfig.isCubit,
      featureName: argResults['feature-name'] as String?,
      pageName: argResults['page-name'] as String?,
      appsName: argResults['apps-name'] as String?,
    );
  }

  /// Safely gets boolean value from YAML section
  static bool _getBoolValue(
      Map<String, dynamic> section, String key, bool defaultValue) {
    final value = section[key];
    return value is bool ? value : defaultValue;
  }

  /// Gets date format configuration
  static String _getDateFormat(
      Map<String, dynamic> section, String key, String defaultFormat) {
    final value = section[key] as String?;
    if (value == null) return defaultFormat;

    return key.contains('body')
        ? ".toFormatDateTimeBody('$value')"
        : ".toFormatDateTimeResponse('$value')";
  }

  /// Safely gets boolean value from command line arguments
  static bool? _getArgBool(ArgResults argResults, String name) {
    if (!argResults.arguments.any((arg) => arg.contains(name))) {
      return null;
    }
    return argResults[name] as bool?;
  }

  /// Converts a Map&lt;dynamic, dynamic&gt; to Map&lt;String, dynamic&gt;
  ///
  /// This method ensures type safety when working with YAML parsed data
  /// which often comes as Map&lt;dynamic, dynamic&gt; but our APIs expect
  /// Map&lt;String, dynamic&gt;.
  Map<String, dynamic> _convertMapToStringDynamic(Map<dynamic, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }
}
