/// Specialized error categories for build operations.
///
/// Provides comprehensive error categorization for build command failures
/// with associated resolution guidance and diagnostic information.
library;

import 'package:morpheme_cli/helper/error_handler.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Specialized error categories for build operations.
///
/// Each error type corresponds to a specific build failure scenario
/// with tailored resolution guidance and diagnostic commands.
enum BuildCommandError {
  /// Platform-specific tools missing (Xcode, Android SDK)
  platformToolsMissing,

  /// Invalid build configuration (flavors, certificates)
  buildConfigurationInvalid,

  /// Compilation or linking failures
  buildProcessFailure,

  /// Insufficient system resources
  systemResourcesInsufficient,

  /// Network connectivity issues during dependency resolution
  dependencyResolutionFailure,

  /// Code signing or provisioning profile issues
  signingConfigurationInvalid,

  /// Localization generation failure
  localizationGenerationFailure,

  /// Environment setup failure (Firebase, dependencies)
  environmentSetupFailure,

  /// Platform validation failure (macOS requirement, etc.)
  platformValidationFailure,

  /// Build artifact generation failure
  artifactGenerationFailure,

  /// Unknown build error
  unknownBuildError,
}

/// Build command exception with recovery guidance.
///
/// Provides detailed context about build failures including
/// platform-specific resolution steps and diagnostic commands.
class BuildCommandException extends ProjectCommandException {
  /// The specific build platform that failed
  final String? platform;

  /// Diagnostic commands to gather more information
  final List<String>? diagnosticCommands;

  /// Platform-specific recovery steps
  final List<String>? recoverySteps;

  /// Creates a new BuildCommandException.
  ///
  /// Parameters:
  /// - [type]: Build error category
  /// - [message]: Primary error description
  /// - [platform]: Optional platform context
  /// - [suggestion]: Optional resolution guidance
  /// - [examples]: Optional example commands
  /// - [diagnosticCommands]: Optional diagnostic commands
  /// - [recoverySteps]: Optional recovery procedures
  BuildCommandException(
    BuildCommandError type,
    String message, {
    this.platform,
    String? suggestion,
    List<String>? examples,
    this.diagnosticCommands,
    this.recoverySteps,
  }) : super(
          _mapBuildErrorToProjectError(type),
          message,
          suggestion: suggestion,
          examples: examples,
        );

  /// Maps build error types to project error types.
  static ProjectCommandError _mapBuildErrorToProjectError(
    BuildCommandError buildError,
  ) {
    switch (buildError) {
      case BuildCommandError.platformToolsMissing:
        return ProjectCommandError.missingDependencies;
      case BuildCommandError.buildConfigurationInvalid:
        return ProjectCommandError.configurationMissing;
      case BuildCommandError.buildProcessFailure:
        return ProjectCommandError.buildFailure;
      case BuildCommandError.systemResourcesInsufficient:
        return ProjectCommandError.timeout;
      case BuildCommandError.dependencyResolutionFailure:
        return ProjectCommandError.dependencyFailure;
      case BuildCommandError.signingConfigurationInvalid:
        return ProjectCommandError.configurationMissing;
      case BuildCommandError.localizationGenerationFailure:
        return ProjectCommandError.buildFailure;
      case BuildCommandError.environmentSetupFailure:
        return ProjectCommandError.configurationMissing;
      case BuildCommandError.platformValidationFailure:
        return ProjectCommandError.missingDependencies;
      case BuildCommandError.artifactGenerationFailure:
        return ProjectCommandError.buildFailure;
      case BuildCommandError.unknownBuildError:
        return ProjectCommandError.unknown;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (platform != null) {
      buffer.write(' (Platform: $platform)');
    }

    return buffer.toString();
  }
}

/// Enhanced error handling utilities for build commands.
///
/// Provides specialized error handling for build operations with
/// platform-specific guidance and enhanced diagnostic information.
abstract class BuildErrorHandler {
  /// Handles build command exceptions with enhanced context.
  ///
  /// Parameters:
  /// - [exception]: BuildCommandException to handle
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleBuildException(
    BuildCommandException exception, {
    bool isExit = true,
  }) {
    final errorInfo = _getBuildErrorInfo(exception);

    StatusHelper.failed(
      exception.message,
      suggestion: exception.suggestion ?? errorInfo['suggestion'],
      examples: exception.examples ?? errorInfo['examples'],
      isExit: isExit,
    );

    // Display additional build-specific information
    if (exception.diagnosticCommands != null &&
        exception.diagnosticCommands!.isNotEmpty) {
      print('\n🔍 Diagnostic commands:');
      for (final command in exception.diagnosticCommands!) {
        print('   $command');
      }
    }

    if (exception.recoverySteps != null &&
        exception.recoverySteps!.isNotEmpty) {
      print('\n🔧 Recovery steps:');
      for (var i = 0; i < exception.recoverySteps!.length; i++) {
        print('   ${i + 1}. ${exception.recoverySteps![i]}');
      }
    }
  }

  /// Handles configuration errors during build setup.
  ///
  /// Parameters:
  /// - [exception]: The caught exception
  /// - [context]: Additional context about the operation
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleConfigurationError(
    dynamic exception,
    String context, {
    bool isExit = true,
  }) {
    final buildException = BuildCommandException(
      BuildCommandError.buildConfigurationInvalid,
      context,
      suggestion: 'Check morpheme.yaml configuration and build parameters',
      examples: [
        'morpheme doctor',
        'morpheme config',
        'cat morpheme.yaml',
      ],
      diagnosticCommands: [
        'morpheme doctor',
        'flutter doctor',
        'cat morpheme.yaml',
      ],
      recoverySteps: [
        'Verify morpheme.yaml exists and has correct syntax',
        'Check flavor configuration in morpheme.yaml',
        'Ensure all required build parameters are specified',
        'Run "morpheme doctor" to check environment setup',
      ],
    );

    handleBuildException(buildException, isExit: isExit);
  }

  /// Handles platform-specific validation errors.
  ///
  /// Parameters:
  /// - [message]: Error message
  /// - [platform]: Optional platform name
  /// - [suggestion]: Optional resolution guidance
  /// - [isExit]: Whether to exit the process (default: true)
  static void handlePlatformError(
    String message, {
    String? platform,
    String? suggestion,
    bool isExit = true,
  }) {
    final buildException = BuildCommandException(
      BuildCommandError.platformValidationFailure,
      message,
      platform: platform,
      suggestion: suggestion ?? 'Check platform requirements and system setup',
      examples: [
        'morpheme doctor',
        'flutter doctor',
      ],
      diagnosticCommands: [
        'morpheme doctor',
        'flutter doctor',
        'uname -a',
      ],
    );

    handleBuildException(buildException, isExit: isExit);
  }

  /// Handles generic build errors with platform context.
  ///
  /// Parameters:
  /// - [exception]: The caught exception
  /// - [context]: Additional context about the operation
  /// - [platform]: Platform being built for
  /// - [isExit]: Whether to exit the process (default: true)
  static void handleGenericBuildError(
    dynamic exception,
    String context,
    String platform, {
    bool isExit = true,
  }) {
    final buildException = BuildCommandException(
      BuildCommandError.unknownBuildError,
      '$context: ${exception.toString()}',
      platform: platform,
      suggestion: 'Check build logs and system configuration',
      examples: [
        'morpheme doctor',
        'flutter clean',
        'flutter pub get',
      ],
      diagnosticCommands: [
        'morpheme doctor',
        'flutter doctor',
        'flutter clean',
        'flutter pub get',
      ],
      recoverySteps: [
        'Clean the project with "flutter clean"',
        'Get dependencies with "flutter pub get"',
        'Check system resources and available disk space',
        'Retry the build operation',
      ],
    );

    handleBuildException(buildException, isExit: isExit);
  }

  /// Handles validation errors with ValidationResult.
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

  /// Gets enhanced error information for build exceptions.
  ///
  /// Returns contextual information including suggestions and
  /// diagnostic commands based on the exception details.
  static Map<String, dynamic> _getBuildErrorInfo(
    BuildCommandException exception,
  ) {
    final errorType = _getBuildErrorTypeFromProjectError(exception.type);

    switch (errorType) {
      case BuildCommandError.platformToolsMissing:
        return {
          'suggestion': 'Install required platform development tools',
          'examples': [
            'xcode-select --install',
            'flutter doctor',
            'morpheme doctor',
          ],
        };

      case BuildCommandError.buildConfigurationInvalid:
        return {
          'suggestion': 'Verify build configuration and parameters',
          'examples': [
            'morpheme config',
            'cat morpheme.yaml',
            'flutter doctor',
          ],
        };

      case BuildCommandError.buildProcessFailure:
        return {
          'suggestion': 'Check build logs and resolve compilation errors',
          'examples': [
            'flutter clean',
            'flutter pub get',
            'morpheme clean',
          ],
        };

      case BuildCommandError.dependencyResolutionFailure:
        return {
          'suggestion': 'Check internet connectivity and dependencies',
          'examples': [
            'flutter pub get',
            'morpheme get',
            'ping pub.dev',
          ],
        };

      case BuildCommandError.signingConfigurationInvalid:
        return {
          'suggestion': 'Check code signing certificates and provisioning',
          'examples': [
            'security find-identity -v -p codesigning',
            'ls ~/Library/MobileDevice/Provisioning\\ Profiles/',
          ],
        };

      default:
        return {
          'suggestion': 'Check system configuration and try again',
          'examples': [
            'morpheme doctor',
            'flutter doctor',
            'flutter clean',
          ],
        };
    }
  }

  /// Maps project error types back to build error types.
  ///
  /// Used for error information lookup when handling exceptions.
  static BuildCommandError _getBuildErrorTypeFromProjectError(
    ProjectCommandError projectError,
  ) {
    switch (projectError) {
      case ProjectCommandError.missingDependencies:
        return BuildCommandError.platformToolsMissing;
      case ProjectCommandError.configurationMissing:
        return BuildCommandError.buildConfigurationInvalid;
      case ProjectCommandError.buildFailure:
        return BuildCommandError.buildProcessFailure;
      case ProjectCommandError.dependencyFailure:
        return BuildCommandError.dependencyResolutionFailure;
      case ProjectCommandError.timeout:
        return BuildCommandError.systemResourcesInsufficient;
      default:
        return BuildCommandError.unknownBuildError;
    }
  }
}
