import 'shorebird_error.dart';

/// Error thrown when configuration-related issues occur.
///
/// This error is used when there are problems with configuration files,
/// missing configuration values, or invalid configuration settings.
class ShorebirdConfigurationError extends ShorebirdError {
  /// The configuration file that has issues
  final String configFile;

  /// The missing or invalid field in the configuration
  final String missingField;

  /// List of valid values for the field (if applicable)
  final List<String> validValues;

  /// Creates a new configuration error.
  ///
  /// Parameters:
  /// - [message]: Description of the configuration issue
  /// - [configFile]: Path to the configuration file with issues
  /// - [missingField]: The field that is missing or invalid
  /// - [validValues]: List of valid values for the field
  /// - [command]: The command being executed when the error occurred
  ShorebirdConfigurationError({
    required super.message,
    required this.configFile,
    required this.missingField,
    this.validValues = const [],
    super.command,
  }) : super(
          exitCode: 3,
          context: {
            'config_file': configFile,
            'missing_field': missingField,
            'valid_values': validValues,
          },
        );

  /// Creates a configuration error for a missing file.
  ///
  /// Parameters:
  /// - [configFile]: Path to the missing configuration file
  /// - [command]: The command being executed when the error occurred
  factory ShorebirdConfigurationError.missingFile(
    String configFile, {
    String? command,
  }) {
    return ShorebirdConfigurationError(
      message: 'Configuration file not found: $configFile',
      configFile: configFile,
      missingField: 'file',
      command: command,
    );
  }

  /// Creates a configuration error for a missing required field.
  ///
  /// Parameters:
  /// - [configFile]: Path to the configuration file
  /// - [field]: The missing field name
  /// - [command]: The command being executed when the error occurred
  factory ShorebirdConfigurationError.missingField(
    String configFile,
    String field, {
    String? command,
  }) {
    return ShorebirdConfigurationError(
      message:
          'Missing required field "$field" in configuration file: $configFile',
      configFile: configFile,
      missingField: field,
      command: command,
    );
  }

  /// Creates a configuration error for an invalid field value.
  ///
  /// Parameters:
  /// - [configFile]: Path to the configuration file
  /// - [field]: The field with invalid value
  /// - [actualValue]: The invalid value
  /// - [validValues]: List of valid values for the field
  /// - [command]: The command being executed when the error occurred
  factory ShorebirdConfigurationError.invalidField(
    String configFile,
    String field,
    String actualValue,
    List<String> validValues, {
    String? command,
  }) {
    return ShorebirdConfigurationError(
      message:
          'Invalid value "$actualValue" for field "$field" in $configFile. '
          'Valid values are: ${validValues.join(', ')}',
      configFile: configFile,
      missingField: field,
      validValues: validValues,
      command: command,
    );
  }
}
