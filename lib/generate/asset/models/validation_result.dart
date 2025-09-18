/// Represents the result of a validation operation.
///
/// Contains validation status, error messages, warnings, and suggestions
/// for resolving any issues found during validation.
class ValidationResult {
  /// Whether the validation passed successfully.
  final bool isValid;

  /// List of validation errors that prevent operation from proceeding.
  final List<ValidationError> errors;

  /// List of validation warnings that don't prevent operation but should be noted.
  final List<ValidationWarning> warnings;

  /// List of suggestions for resolving validation issues.
  final List<String> suggestions;

  /// Creates a new ValidationResult instance.
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
  });

  /// Creates a successful validation result.
  factory ValidationResult.success({
    List<ValidationWarning> warnings = const [],
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Creates a failed validation result.
  factory ValidationResult.failure({
    required List<ValidationError> errors,
    List<ValidationWarning> warnings = const [],
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Creates a validation result with a single error.
  factory ValidationResult.singleError({
    required String message,
    String? field,
    ValidationErrorType? type,
    List<String> suggestions = const [],
  }) {
    return ValidationResult.failure(
      errors: [
        ValidationError(
          message: message,
          field: field,
          type: type ?? ValidationErrorType.general,
        ),
      ],
      suggestions: suggestions,
    );
  }

  /// Checks if there are any validation errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Checks if there are any validation warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Checks if there are any suggestions.
  bool get hasSuggestions => suggestions.isNotEmpty;

  /// Gets the total number of issues (errors + warnings).
  int get totalIssues => errors.length + warnings.length;

  /// Gets all error messages as a list of strings.
  List<String> get errorMessages => errors.map((e) => e.message).toList();

  /// Gets all warning messages as a list of strings.
  List<String> get warningMessages => warnings.map((w) => w.message).toList();

  /// Combines this validation result with another one.
  ///
  /// The combined result is valid only if both results are valid.
  ValidationResult combine(ValidationResult other) {
    return ValidationResult(
      isValid: isValid && other.isValid,
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
      suggestions: [...suggestions, ...other.suggestions],
    );
  }

  /// Gets a formatted string representation of all validation issues.
  String getFormattedErrors() {
    final buffer = StringBuffer();

    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - ${error.message}');
      }
    }

    if (warnings.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - ${warning.message}');
      }
    }

    if (suggestions.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('Suggestions:');
      for (final suggestion in suggestions) {
        buffer.writeln('  - $suggestion');
      }
    }

    return buffer.toString().trim();
  }

  @override
  String toString() {
    return 'ValidationResult{'
        'isValid: $isValid, '
        'errors: ${errors.length}, '
        'warnings: ${warnings.length}, '
        'suggestions: ${suggestions.length}'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          errors == other.errors &&
          warnings == other.warnings &&
          suggestions == other.suggestions;

  @override
  int get hashCode =>
      isValid.hashCode ^
      errors.hashCode ^
      warnings.hashCode ^
      suggestions.hashCode;
}

/// Represents a validation error with detailed information.
class ValidationError {
  /// The error message describing what went wrong.
  final String message;

  /// The field or property that failed validation (optional).
  final String? field;

  /// The type of validation error.
  final ValidationErrorType type;

  /// Additional context or details about the error (optional).
  final String? details;

  /// Creates a new ValidationError instance.
  const ValidationError({
    required this.message,
    this.field,
    required this.type,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (field != null) {
      buffer.write(' (field: $field)');
    }
    if (details != null) {
      buffer.write(' - $details');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          field == other.field &&
          type == other.type &&
          details == other.details;

  @override
  int get hashCode =>
      message.hashCode ^ field.hashCode ^ type.hashCode ^ details.hashCode;
}

/// Represents a validation warning that doesn't prevent operation.
class ValidationWarning {
  /// The warning message describing the potential issue.
  final String message;

  /// The field or property that triggered the warning (optional).
  final String? field;

  /// The type of validation warning.
  final ValidationWarningType type;

  /// Creates a new ValidationWarning instance.
  const ValidationWarning({
    required this.message,
    this.field,
    required this.type,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (field != null) {
      buffer.write(' (field: $field)');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationWarning &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          field == other.field &&
          type == other.type;

  @override
  int get hashCode => message.hashCode ^ field.hashCode ^ type.hashCode;
}

/// Types of validation errors.
enum ValidationErrorType {
  /// General validation error.
  general,

  /// Missing required field or file.
  missing,

  /// Invalid format or structure.
  format,

  /// Permission or access issue.
  permission,

  /// Configuration-related error.
  configuration,

  /// File system related error.
  fileSystem,
}

/// Types of validation warnings.
enum ValidationWarningType {
  /// General warning.
  general,

  /// Performance-related warning.
  performance,

  /// Deprecated feature or configuration.
  deprecated,

  /// Best practice recommendation.
  bestPractice,

  /// Potential compatibility issue.
  compatibility,
}
