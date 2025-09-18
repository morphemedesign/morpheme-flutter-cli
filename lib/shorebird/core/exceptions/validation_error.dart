import 'shorebird_error.dart';

/// Error thrown when command input validation fails.
///
/// This error is used when command arguments or configuration values
/// fail validation checks before command execution.
class ShorebirdValidationError extends ShorebirdError {
  /// The field that failed validation
  final String field;

  /// The expected value or format
  final String expectedValue;

  /// The actual value that was provided
  final String actualValue;

  /// Creates a new validation error.
  ///
  /// Parameters:
  /// - [field]: The name of the field that failed validation
  /// - [expectedValue]: Description of what was expected
  /// - [actualValue]: The actual value that was provided
  /// - [message]: Optional custom error message
  /// - [command]: The command being executed when validation failed
  ShorebirdValidationError({
    required this.field,
    required this.expectedValue,
    required this.actualValue,
    String? message,
    super.command,
  }) : super(
          message: message ??
              'Validation failed for field "$field": expected $expectedValue, '
                  'but got "$actualValue"',
          exitCode: 2,
          context: {
            'field': field,
            'expected': expectedValue,
            'actual': actualValue,
          },
        );

  /// Creates a validation error for an empty required field.
  ///
  /// Parameters:
  /// - [field]: The name of the field that cannot be empty
  /// - [command]: The command being executed when validation failed
  factory ShorebirdValidationError.emptyField(
    String field, {
    String? command,
  }) {
    return ShorebirdValidationError(
      field: field,
      expectedValue: 'non-empty value',
      actualValue: 'empty',
      message: 'Field "$field" cannot be empty',
      command: command,
    );
  }

  /// Creates a validation error for an invalid value.
  ///
  /// Parameters:
  /// - [field]: The name of the field with invalid value
  /// - [actualValue]: The invalid value that was provided
  /// - [validValues]: List of valid values for the field
  /// - [command]: The command being executed when validation failed
  factory ShorebirdValidationError.invalidValue(
    String field,
    String actualValue,
    List<String> validValues, {
    String? command,
  }) {
    return ShorebirdValidationError(
      field: field,
      expectedValue: 'one of: ${validValues.join(', ')}',
      actualValue: actualValue,
      command: command,
    );
  }
}
