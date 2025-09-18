/// Abstract base class for all build commands.
///
/// Provides standardized build workflow, argument parsing,
/// and error handling for platform-specific build operations.
///
/// ## Workflow
/// 1. Argument validation and parsing
/// 2. Environment prerequisite checks
/// 3. Configuration preparation (flavors, dart defines)
/// 4. Optional localization generation
/// 5. Platform-specific build execution
/// 6. Progress reporting and status updates
///
/// ## Usage
/// ```dart
/// class MyBuildCommand extends BaseBuildCommand {
///   @override
///   String get platformName => 'my-platform';
///
///   @override
///   Future<void> executeBuild(BuildConfiguration config) async {
///     // Platform-specific build logic
///   }
/// }
/// ```
library;

import 'dart:io';

import 'package:morpheme_cli/build_app/base/build_command_mixin.dart';
import 'package:morpheme_cli/build_app/base/build_configuration.dart';
import 'package:morpheme_cli/build_app/base/build_error_handler.dart';
import 'package:morpheme_cli/build_app/base/build_progress_reporter.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Abstract base class for all build commands.
///
/// Implements the common build workflow pattern while allowing
/// platform-specific customization through abstract methods.
abstract class BaseBuildCommand extends Command with BuildCommandMixin {
  /// The name of the platform this command builds for.
  ///
  /// Used for progress reporting and error messages.
  String get platformName;

  /// Whether this platform requires macOS host system.
  ///
  /// Used for validation in iOS/macOS specific builds.
  bool get requiresMacOS => false;

  /// Platform-specific build arguments to add.
  ///
  /// Override this method to add platform-specific command arguments
  /// beyond the standard build options.
  void configurePlatformArguments() {
    // Default implementation does nothing
    // Subclasses should override to add platform-specific args
  }

  /// Validates platform-specific build environment.
  ///
  /// Override this method to perform platform-specific validation
  /// such as checking for required tools or SDKs.
  ///
  /// Returns: ValidationResult indicating environment validity
  ValidationResult<bool> validatePlatformEnvironment() {
    return ValidationResult.success(true);
  }

  /// Executes the platform-specific build process.
  ///
  /// This method must be implemented by subclasses to perform
  /// the actual build operation for their target platform.
  ///
  /// Parameters:
  /// - [config]: Build configuration containing all parameters
  Future<void> executePlatformBuild(BuildConfiguration config);

  @override
  String get category => Constants.build;

  /// Base constructor that sets up common argument parsing.
  BaseBuildCommand() {
    addStandardBuildOptions();
    configurePlatformArguments();
  }

  @override
  void run() async {
    final stopwatch = Stopwatch()..start();

    try {
      BuildProgressReporter.reportPhase('Initializing $platformName build');

      // Step 1: Validate prerequisites
      if (!await _validatePrerequisites()) return;

      // Step 2: Parse and validate configuration
      final config = await _prepareBuildConfiguration();
      if (config == null) return;

      // Step 3: Generate localization if requested
      if (config.generateL10n) {
        await _generateLocalization(config);
      }

      // Step 4: Setup platform-specific environment
      await _setupPlatformEnvironment(config);

      // Step 5: Execute platform-specific build
      BuildProgressReporter.reportPhase('Building $platformName application');
      await executePlatformBuild(config);

      stopwatch.stop();
      BuildProgressReporter.reportCompletion(
        '$platformName build',
        stopwatch.elapsed,
      );

      StatusHelper.success('build $platformName');
    } catch (e) {
      stopwatch.stop();
      _handleBuildException(e);
    }
  }

  /// Validates build prerequisites including environment and configuration.
  ///
  /// Performs comprehensive validation of build requirements including
  /// morpheme.yaml validation and platform-specific environment checks.
  ///
  /// Returns: true if all validation passes, false otherwise
  Future<bool> _validatePrerequisites() async {
    // Remove any existing ndjson gherkin files
    CucumberHelper.removeNdjsonGherkin();

    // Validate morpheme.yaml configuration
    try {
      final morphemeYaml = argResults.getOptionMorphemeYaml();
      YamlHelper.validateMorphemeYaml(morphemeYaml);
    } catch (e) {
      BuildErrorHandler.handleConfigurationError(
          e, 'Invalid morpheme.yaml configuration');
      return false;
    }

    // Validate platform-specific environment
    final envValidation = validatePlatformEnvironment();
    if (!envValidation.isValid) {
      BuildErrorHandler.handleValidationError(envValidation);
      return false;
    }

    // Validate macOS requirement if needed
    if (requiresMacOS && !Platform.isMacOS) {
      BuildErrorHandler.handlePlatformError(
        'macOS host system required for $platformName builds',
        suggestion: 'Use a macOS system to build for $platformName',
      );
      return false;
    }

    return true;
  }

  /// Prepares build configuration from command arguments and morpheme.yaml.
  ///
  /// Extracts and validates all build-related parameters including
  /// flavors, build modes, and platform-specific options.
  ///
  /// Returns: BuildConfiguration object or null if validation fails
  Future<BuildConfiguration?> _prepareBuildConfiguration() async {
    try {
      final config = extractBuildConfiguration();

      // Validate build configuration
      final validation = validateBuildConfiguration(config);
      if (!validation.isValid) {
        BuildErrorHandler.handleValidationError(validation);
        return null;
      }

      return config;
    } catch (e) {
      BuildErrorHandler.handleConfigurationError(
          e, 'Failed to prepare build configuration');
      return null;
    }
  }

  /// Generates localization files if requested.
  ///
  /// Executes the morpheme l10n command to ensure all localization
  /// files are up to date before build execution.
  ///
  /// Parameters:
  /// - [config]: Build configuration containing morpheme.yaml path
  Future<void> _generateLocalization(BuildConfiguration config) async {
    BuildProgressReporter.reportPhase('Generating localization files');

    try {
      await 'morpheme l10n --morpheme-yaml "${config.morphemeYamlPath}"'.run;
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.localizationGenerationFailure,
        'Failed to generate localization files',
        suggestion: 'Check localization configuration in morpheme.yaml',
        examples: ['morpheme l10n --help', 'morpheme config'],
      );
    }
  }

  /// Sets up platform-specific build environment.
  ///
  /// Performs platform-specific preparation including Firebase
  /// configuration setup and environment variable preparation.
  ///
  /// Parameters:
  /// - [config]: Build configuration containing flavor and paths
  Future<void> _setupPlatformEnvironment(BuildConfiguration config) async {
    BuildProgressReporter.reportPhase('Setting up $platformName environment');

    try {
      // Setup Firebase configuration for the specified flavor
      FirebaseHelper.run(config.flavor, config.morphemeYamlPath);
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.environmentSetupFailure,
        'Failed to setup $platformName build environment',
        suggestion: 'Check Firebase configuration and morpheme.yaml',
        examples: ['morpheme doctor', 'firebase --version'],
      );
    }
  }

  /// Handles build exceptions with appropriate error categorization.
  ///
  /// Provides centralized exception handling with platform-specific
  /// error context and resolution guidance.
  ///
  /// Parameters:
  /// - [exception]: The caught exception
  void _handleBuildException(dynamic exception) {
    if (exception is BuildCommandException) {
      BuildErrorHandler.handleBuildException(exception);
    } else {
      BuildErrorHandler.handleGenericBuildError(
        exception,
        'Unexpected error during $platformName build',
        platformName,
      );
    }
  }
}
