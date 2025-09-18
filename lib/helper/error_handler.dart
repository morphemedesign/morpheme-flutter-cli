/// Centralized error handling and validation framework for Morpheme CLI.
///
/// This module provides standardized error types, validation patterns,
/// and consistent error reporting across all project commands.
///
/// ## Usage
///
/// ```dart
/// // Validate app name
/// final result = ArgumentValidator.validateAppName('my_app');
/// if (!result.isValid) {
///   ErrorHandler.handleValidationError(result);
///   return;
/// }
///
/// // Handle exceptions
/// try {
///   await someOperation();
/// } catch (e) {
///   ErrorHandler.handleException(
///     ProjectCommandError.buildFailure,
///     e,
///     'Build operation failed'
///   );
/// }
/// ```
library;

import 'package:morpheme_cli/helper/status_helper.dart';

/// Standard error categories for project commands.
///
/// Each error type corresponds to a specific failure scenario
/// with associated resolution guidance.
enum ProjectCommandError {
  /// Configuration file is missing or invalid
  ///
  /// This error occurs when the morpheme.yaml configuration file
  /// is missing, corrupted, or contains invalid syntax.
  ///
  /// Resolution:
  /// - Run `morpheme init` to create a new configuration file
  /// - Check the syntax of existing morpheme.yaml file
  /// - Refer to documentation for proper configuration format
  ///
  /// Example:
  /// ```
  /// // This will trigger configurationMissing if morpheme.yaml doesn't exist
  /// morpheme build apk
  /// ```
  configurationMissing,

  /// File or directory path is invalid
  ///
  /// This error occurs when a specified file or directory path
  /// does not exist, is inaccessible, or has incorrect permissions.
  ///
  /// Resolution:
  /// - Verify the path exists using `ls` or file explorer
  /// - Check file/directory permissions
  /// - Use absolute paths when relative paths are problematic
  ///
  /// Example:
  /// ```
  /// // This will trigger invalidPath if ./lib/nonexistent.dart doesn't exist
  /// morpheme generate page nonexistent --path ./lib/nonexistent.dart
  /// ```
  invalidPath,

  /// Dependency installation or resolution failed
  ///
  /// This error occurs when package dependencies cannot be installed
  /// or resolved, typically due to network issues or package conflicts.
  ///
  /// Resolution:
  /// - Check internet connectivity
  /// - Run `flutter pub get` manually
  /// - Clear pub cache with `flutter pub cache repair`
  /// - Check for package version conflicts in pubspec.yaml
  ///
  /// Example:
  /// ```
  /// // This may trigger dependencyFailure if packages can't be resolved
  /// morpheme get
  /// ```
  dependencyFailure,

  /// Build process failed
  ///
  /// This error occurs when the Flutter build process encounters
  /// compilation errors, missing assets, or configuration issues.
  ///
  /// Resolution:
  /// - Run `flutter clean` to clear build artifacts
  /// - Check for Dart compilation errors
  /// - Verify all required assets are present
  /// - Ensure proper signing configuration for release builds
  ///
  /// Example:
  /// ```
  /// // This may trigger buildFailure if there are compilation errors
  /// morpheme build apk
  /// ```
  buildFailure,

  /// Network connectivity issues
  ///
  /// This error occurs when network operations fail due to
  /// connectivity problems, timeouts, or unreachable servers.
  ///
  /// Resolution:
  /// - Check internet connection
  /// - Verify firewall settings
  /// - Try again later if servers are temporarily unavailable
  /// - Use VPN if geographic restrictions apply
  ///
  /// Example:
  /// ```
  /// // This may trigger networkError if pub.dev is unreachable
  /// morpheme upgrade
  /// ```
  networkError,

  /// File system permission denied
  ///
  /// This error occurs when the CLI lacks necessary permissions
  /// to read, write, or execute files in the specified locations.
  ///
  /// Resolution:
  /// - Run command with appropriate privileges (sudo on Unix systems)
  /// - Check file and directory permissions
  /// - Ensure write access to project directory
  /// - Verify ownership of files and directories
  ///
  /// Example:
  /// ```
  /// // This may trigger permissionDenied if writing to protected directories
  /// morpheme create my_app --path /usr/local/bin
  /// ```
  permissionDenied,

  /// Invalid command arguments
  ///
  /// This error occurs when command-line arguments are missing,
  /// malformed, or contain invalid values for the specified command.
  ///
  /// Resolution:
  /// - Check command syntax with `morpheme help [command]`
  /// - Verify all required arguments are provided
  /// - Ensure argument values are in correct format
  /// - Use proper quoting for arguments with spaces
  ///
  /// Example:
  /// ```
  /// // This will trigger invalidArguments due to missing required argument
  /// morpheme generate feature
  /// ```
  invalidArguments,

  /// Required tools or dependencies missing
  ///
  /// This error occurs when essential tools like Flutter, Dart SDK,
  /// or third-party dependencies are not installed or not in PATH.
  ///
  /// Resolution:
  /// - Install missing tools (Flutter, Dart, etc.)
  /// - Add tools to system PATH
  /// - Run `morpheme doctor` to diagnose environment issues
  /// - Check tool versions for compatibility
  ///
  /// Example:
  /// ```
  /// // This will trigger missingDependencies if Flutter is not installed
  /// morpheme create my_app
  /// ```
  missingDependencies,

  /// Operation timeout
  ///
  /// This error occurs when operations exceed the allowed time limit,
  /// typically due to slow network, heavy computation, or system load.
  ///
  /// Resolution:
  /// - Try the operation again
  /// - Check system resources (CPU, memory, disk I/O)
  /// - Increase timeout values if configurable
  /// - Optimize project structure for faster operations
  ///
  /// Example:
  /// ```
  /// // This may trigger timeout during long-running builds
  /// morpheme build appbundle
  /// ```
  timeout,

  /// Unknown or unexpected error
  ///
  /// This error occurs when an unexpected exception is caught that
  /// doesn't fit into any of the predefined error categories.
  ///
  /// Resolution:
  /// - Check the detailed error message and stack trace
  /// - Report the issue to Morpheme CLI team with reproduction steps
  /// - Try alternative approaches to achieve the same goal
  /// - Check for updates that may fix the issue
  ///
  /// Example:
  /// ```
  /// // This may trigger unknown for unhandled exceptions
  /// morpheme [any_command]
  /// ```
  unknown,
}

/// Enhanced error reporting with context and suggestions.
///
/// Provides detailed error information including resolution
/// steps and example commands to fix common issues.
class ProjectCommandException implements Exception {
  /// The category of error that occurred
  final ProjectCommandError type;

  /// Primary error message
  final String message;

  /// Optional suggestion for resolving the error
  final String? suggestion;

  /// Optional list of example commands to fix the issue
  final List<String>? examples;

  /// Creates a new ProjectCommandException.
  ///
  /// Parameters:
  /// - [type]: The error category
  /// - [message]: Primary error description
  /// - [suggestion]: Optional resolution guidance
  /// - [examples]: Optional example commands
  const ProjectCommandException(
    this.type,
    this.message, {
    this.suggestion,
    this.examples,
  });

  @override
  String toString() => message;
}

/// Result of a validation operation.
///
/// Contains validation status, error details, and
/// the validated value if successful.
class ValidationResult<T> {
  /// Whether the validation passed
  final bool isValid;

  /// The validated value (if validation passed)
  final T? value;

  /// Error message (if validation failed)
  final String? error;

  /// Suggestion for fixing the error
  final String? suggestion;

  /// Example commands to resolve the issue
  final List<String>? examples;

  const ValidationResult._({
    required this.isValid,
    this.value,
    this.error,
    this.suggestion,
    this.examples,
  });

  /// Creates a successful validation result.
  ///
  /// Parameters:
  /// - [value]: The validated value
  factory ValidationResult.success(T value) {
    return ValidationResult._(isValid: true, value: value);
  }

  /// Creates a failed validation result.
  ///
  /// Parameters:
  /// - [error]: Error message
  /// - [suggestion]: Optional resolution guidance
  /// - [examples]: Optional example commands
  factory ValidationResult.error(
    String error, {
    String? suggestion,
    List<String>? examples,
  }) {
    return ValidationResult._(
      isValid: false,
      error: error,
      suggestion: suggestion,
      examples: examples,
    );
  }
}

/// Centralized error handling utilities.
///
/// Provides consistent error reporting and exception handling
/// across all project commands.
abstract class ErrorHandler {
  /// Handles validation errors with standardized reporting.
  ///
  /// Parameters:
  /// - [result]: Validation result containing error details
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleValidationError<T>(
    ValidationResult<T> result, {
    bool isExit = true,
  }) {
    if (result.isValid) return;

    StatusHelper.failed(
      result.error!,
      suggestion: result.suggestion,
      examples: result.examples,
      isExit: isExit,
    );
  }

  /// Handles exceptions with contextual error information.
  ///
  /// Parameters:
  /// - [type]: Error category
  /// - [exception]: The caught exception
  /// - [context]: Additional context about the operation
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleException(
    ProjectCommandError type,
    dynamic exception,
    String context, {
    bool isExit = true,
  }) {
    final errorInfo = _getErrorInfo(type);

    StatusHelper.failed(
      '$context: ${exception.toString()}',
      suggestion: errorInfo['suggestion'],
      examples: errorInfo['examples'],
      isExit: isExit,
    );
  }

  /// Handles project command exceptions.
  ///
  /// Parameters:
  /// - [exception]: ProjectCommandException to handle
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleProjectException(
    ProjectCommandException exception, {
    bool isExit = true,
  }) {
    StatusHelper.failed(
      exception.message,
      suggestion: exception.suggestion,
      examples: exception.examples,
      isExit: isExit,
    );
  }

  /// Gets error information for a specific error type.
  ///
  /// Returns a map containing suggestion and examples for
  /// the specified error category.
  ///
  /// Parameters:
  /// - [type]: The error category to get information for
  ///
  /// Returns: Map with 'suggestion' and 'examples' keys
  static Map<String, dynamic> _getErrorInfo(ProjectCommandError type) {
    switch (type) {
      case ProjectCommandError.configurationMissing:
        return _getConfigurationMissingErrorInfo();
      case ProjectCommandError.invalidPath:
        return _getInvalidPathErrorInfo();
      case ProjectCommandError.dependencyFailure:
        return _getDependencyFailureErrorInfo();
      case ProjectCommandError.buildFailure:
        return _getBuildFailureErrorInfo();
      case ProjectCommandError.networkError:
        return _getNetworkErrorInfo();
      case ProjectCommandError.permissionDenied:
        return _getPermissionDeniedErrorInfo();
      case ProjectCommandError.invalidArguments:
        return _getInvalidArgumentsErrorInfo();
      case ProjectCommandError.missingDependencies:
        return _getMissingDependenciesErrorInfo();
      case ProjectCommandError.timeout:
        return _getTimeoutErrorInfo();
      case ProjectCommandError.unknown:
        return _getUnknownErrorInfo();
    }
  }

  /// Gets error information for configuration missing errors.
  ///
  /// Returns suggestion and examples for resolving configuration issues.
  static Map<String, dynamic> _getConfigurationMissingErrorInfo() {
    return {
      'suggestion': 'Ensure morpheme.yaml exists and has valid syntax',
      'examples': ['morpheme init', 'morpheme config'],
    };
  }

  /// Gets error information for invalid path errors.
  ///
  /// Returns suggestion and examples for resolving path issues.
  static Map<String, dynamic> _getInvalidPathErrorInfo() {
    return {
      'suggestion':
          'Check that the specified path exists and is accessible',
      'examples': ['ls -la', 'pwd'],
    };
  }

  /// Gets error information for dependency failure errors.
  ///
  /// Returns suggestion and examples for resolving dependency issues.
  static Map<String, dynamic> _getDependencyFailureErrorInfo() {
    return {
      'suggestion':
          'Check internet connectivity and run dependency installation',
      'examples': ['flutter pub get', 'morpheme get'],
    };
  }

  /// Gets error information for build failure errors.
  ///
  /// Returns suggestion and examples for resolving build issues.
  static Map<String, dynamic> _getBuildFailureErrorInfo() {
    return {
      'suggestion': 'Check build configuration and dependencies',
      'examples': ['flutter clean', 'morpheme clean', 'flutter doctor'],
    };
  }

  /// Gets error information for network errors.
  ///
  /// Returns suggestion and examples for resolving network issues.
  static Map<String, dynamic> _getNetworkErrorInfo() {
    return {
      'suggestion': 'Check internet connectivity and try again',
      'examples': ['ping google.com', 'curl -I https://pub.dev'],
    };
  }

  /// Gets error information for permission denied errors.
  ///
  /// Returns suggestion and examples for resolving permission issues.
  static Map<String, dynamic> _getPermissionDeniedErrorInfo() {
    return {
      'suggestion':
          'Check file permissions or run with appropriate privileges',
      'examples': ['chmod +x file', 'sudo command'],
    };
  }

  /// Gets error information for invalid arguments errors.
  ///
  /// Returns suggestion and examples for resolving argument issues.
  static Map<String, dynamic> _getInvalidArgumentsErrorInfo() {
    return {
      'suggestion': 'Check command syntax and argument format',
      'examples': ['morpheme help', 'morpheme command --help'],
    };
  }

  /// Gets error information for missing dependencies errors.
  ///
  /// Returns suggestion and examples for resolving dependency issues.
  static Map<String, dynamic> _getMissingDependenciesErrorInfo() {
    return {
      'suggestion': 'Install required tools and dependencies',
      'examples': ['morpheme doctor', 'flutter doctor'],
    };
  }

  /// Gets error information for timeout errors.
  ///
  /// Returns suggestion and examples for resolving timeout issues.
  static Map<String, dynamic> _getTimeoutErrorInfo() {
    return {
      'suggestion':
          'Operation timed out, try again or check system resources',
      'examples': ['morpheme clean', 'flutter clean'],
    };
  }

  /// Gets error information for unknown errors.
  ///
  /// Returns suggestion and examples for resolving unknown issues.
  static Map<String, dynamic> _getUnknownErrorInfo() {
    return {
      'suggestion': 'Check system configuration and try again',
      'examples': ['morpheme doctor', 'flutter doctor'],
    };
  }
}

/// Input argument validation utilities.
///
/// Provides standardized validation for common command arguments
/// with descriptive error messages and resolution guidance.
abstract class ArgumentValidator {
  /// Validates application name format.
  ///
  /// Checks that the app name follows snake_case convention
  /// and contains only valid characters.
  ///
  /// Parameters:
  /// - [name]: Application name to validate
  ///
  /// Returns: ValidationResult with the normalized name or error details
  ///
  /// Example:
  /// ```dart
  /// final result = ArgumentValidator.validateAppName('my_app');
  /// if (result.isValid) {
  ///   print('Valid app name: ${result.value}');
  /// } else {
  ///   print('Invalid app name: ${result.error}');
  /// }
  /// ```
  static ValidationResult<String> validateAppName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.error(
        'App name is required',
        suggestion: 'Provide an app name as the first argument',
        examples: ['morpheme create my_app'],
      );
    }

    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return ValidationResult.error(
        'App name must use snake_case format',
        suggestion: 'Use lowercase letters, numbers, and underscores only',
        examples: ['my_awesome_app', 'todo_app', 'weather_tracker'],
      );
    }

    return ValidationResult.success(name.toLowerCase());
  }

  /// Validates feature name format.
  ///
  /// Ensures feature names follow proper naming conventions
  /// and don't conflict with reserved words.
  ///
  /// Parameters:
  /// - [name]: Feature name to validate
  ///
  /// Returns: ValidationResult with the normalized name or error details
  ///
  /// Example:
  /// ```dart
  /// final result = ArgumentValidator.validateFeatureName('user_profile');
  /// if (result.isValid) {
  ///   print('Valid feature name: ${result.value}');
  /// } else {
  ///   print('Invalid feature name: ${result.error}');
  /// }
  /// ```
  static ValidationResult<String> validateFeatureName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.error(
        'Feature name is required',
        suggestion: 'Provide a feature name as an argument',
        examples: ['morpheme feature user_profile'],
      );
    }

    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return ValidationResult.error(
        'Feature name must use snake_case format',
        suggestion: 'Use lowercase letters, numbers, and underscores only',
        examples: ['user_profile', 'shopping_cart', 'payment_system'],
      );
    }

    // Reserved feature names
    const reservedNames = ['core', 'shared', 'common', 'base'];
    if (reservedNames.contains(name.toLowerCase())) {
      return ValidationResult.error(
        'Feature name "$name" is reserved',
        suggestion: 'Choose a different feature name that is not reserved',
        examples: ['user_$name', '${name}_feature', 'custom_$name'],
      );
    }

    return ValidationResult.success(name.toLowerCase());
  }

  /// Validates page name format.
  ///
  /// Checks that page names follow naming conventions
  /// and are appropriate for code generation.
  ///
  /// Parameters:
  /// - [name]: Page name to validate
  ///
  /// Returns: ValidationResult with the normalized name or error details
  ///
  /// Example:
  /// ```dart
  /// final result = ArgumentValidator.validatePageName('login_page');
  /// if (result.isValid) {
  ///   print('Valid page name: ${result.value}');
  /// } else {
  ///   print('Invalid page name: ${result.error}');
  /// }
  /// ```
  static ValidationResult<String> validatePageName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.error(
        'Page name is required',
        suggestion: 'Provide a page name as an argument',
        examples: ['morpheme page login_page'],
      );
    }

    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return ValidationResult.error(
        'Page name must use snake_case format',
        suggestion: 'Use lowercase letters, numbers, and underscores only',
        examples: ['login_page', 'user_profile', 'settings_screen'],
      );
    }

    return ValidationResult.success(name.toLowerCase());
  }

  /// Validates file path existence and accessibility.
  ///
  /// Checks that the specified path exists and can be accessed
  /// for read/write operations.
  ///
  /// Parameters:
  /// - [path]: File path to validate
  /// - [mustExist]: Whether the path must already exist (default: true)
  ///
  /// Returns: ValidationResult with the path or error details
  ///
  /// Example:
  /// ```dart
  /// final result = ArgumentValidator.validatePath('./lib/main.dart');
  /// if (result.isValid) {
  ///   print('Valid path: ${result.value}');
  /// } else {
  ///   print('Invalid path: ${result.error}');
  /// }
  /// ```
  static ValidationResult<String> validatePath(String? path,
      {bool mustExist = true}) {
    if (path == null || path.isEmpty) {
      return ValidationResult.error(
        'Path is required',
        suggestion: 'Provide a valid file or directory path',
        examples: ['./path/to/file', '/absolute/path'],
      );
    }

    // Additional path validation can be added here
    // For now, return success - actual existence check should be done by caller
    return ValidationResult.success(path);
  }

  /// Validates application ID format.
  ///
  /// Ensures application IDs follow reverse domain notation
  /// and contain only valid characters.
  ///
  /// Parameters:
  /// - [applicationId]: Application ID to validate
  ///
  /// Returns: ValidationResult with the ID or error details
  ///
  /// Example:
  /// ```dart
  /// final result = ArgumentValidator.validateApplicationId('com.example.myapp');
  /// if (result.isValid) {
  ///   print('Valid application ID: ${result.value}');
  /// } else {
  ///   print('Invalid application ID: ${result.error}');
  /// }
  /// ```
  static ValidationResult<String> validateApplicationId(String? applicationId) {
    if (applicationId == null || applicationId.isEmpty) {
      return ValidationResult.error(
        'Application ID is required',
        suggestion: 'Provide a valid application ID in reverse domain format',
        examples: ['com.example.myapp', 'org.company.product'],
      );
    }

    if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$')
        .hasMatch(applicationId)) {
      return ValidationResult.error(
        'Application ID must use reverse domain notation',
        suggestion:
            'Use format like com.company.app with lowercase letters and dots',
        examples: [
          'com.example.myapp',
          'org.company.product',
          'dev.team.application'
        ],
      );
    }

    return ValidationResult.success(applicationId);
  }
}
