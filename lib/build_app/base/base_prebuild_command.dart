/// Abstract base class for prebuild setup commands.
///
/// Provides standardized prebuild workflow, configuration management,
/// and file generation patterns for platform-specific build preparation.
///
/// ## Workflow
/// 1. Configuration validation and loading
/// 2. Platform-specific environment validation
/// 3. Deployment configuration preparation
/// 4. File generation (Fastlane, project settings, etc.)
/// 5. Status reporting and completion
///
/// ## Usage
/// ```dart
/// class MyPrebuildCommand extends BasePrebuildCommand {
///   @override
///   String get platformName => 'my-platform';
///
///   @override
///   Future<void> executePreBuildSetup(PrebuildConfiguration config) async {
///     // Platform-specific prebuild logic
///   }
/// }
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:morpheme_cli/build_app/base/build_error_handler.dart';
import 'package:morpheme_cli/build_app/base/build_progress_reporter.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Prebuild configuration containing platform setup parameters.
///
/// Encapsulates all information needed for platform-specific
/// build preparation including deployment settings and identifiers.
class PrebuildConfiguration {
  /// Build flavor for configuration selection
  final String flavor;

  /// Path to morpheme.yaml configuration file
  final String morphemeYamlPath;

  /// Morpheme YAML configuration data
  final Map<String, dynamic> morphemeYaml;

  /// Flavor-specific configuration
  final Map<String, dynamic> flavorConfig;

  /// Platform-specific deployment configuration
  final Map<String, dynamic>? deploymentConfig;

  /// Creates a new PrebuildConfiguration.
  const PrebuildConfiguration({
    required this.flavor,
    required this.morphemeYamlPath,
    required this.morphemeYaml,
    required this.flavorConfig,
    this.deploymentConfig,
  });

  @override
  String toString() {
    return 'PrebuildConfiguration('
        'flavor: $flavor, '
        'yamlPath: $morphemeYamlPath'
        ')';
  }
}

/// Abstract base class for prebuild commands.
///
/// Implements the common prebuild workflow pattern while allowing
/// platform-specific customization through abstract methods.
abstract class BasePrebuildCommand extends Command {
  /// The name of the platform this command prepares.
  ///
  /// Used for progress reporting and error messages.
  String get platformName;

  /// Whether this platform requires macOS host system.
  ///
  /// Used for validation in iOS/macOS specific prebuilds.
  bool get requiresMacOS => false;

  /// Path to platform-specific deployment configuration file.
  ///
  /// Override this to specify the deployment config file location.
  /// Return null if no deployment configuration is needed.
  String? get deploymentConfigPath => null;

  /// Validates platform-specific prebuild environment.
  ///
  /// Override this method to perform platform-specific validation
  /// such as checking for required tools or configuration files.
  ///
  /// Returns: ValidationResult indicating environment validity
  ValidationResult<bool> validatePrebuildEnvironment() {
    return ValidationResult.success(true);
  }

  /// Executes the platform-specific prebuild setup.
  ///
  /// This method must be implemented by subclasses to perform
  /// the actual prebuild preparation for their target platform.
  ///
  /// Parameters:
  /// - [config]: Prebuild configuration containing all parameters
  Future<void> executePreBuildSetup(PrebuildConfiguration config);

  @override
  String get category => Constants.build;

  /// Base constructor that sets up common argument parsing.
  BasePrebuildCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
  }

  @override
  void run() async {
    final stopwatch = Stopwatch()..start();

    try {
      BuildProgressReporter.reportPhase(
          'Initializing $platformName prebuild setup');

      // Step 1: Validate prerequisites
      if (!await _validatePrerequisites()) return;

      // Step 2: Parse and validate configuration
      final config = await _preparePrebuildConfiguration();
      if (config == null) return;

      // Step 3: Execute platform-specific prebuild setup
      BuildProgressReporter.reportPhase(
          'Setting up $platformName build environment');
      await executePreBuildSetup(config);

      stopwatch.stop();
      BuildProgressReporter.reportCompletion(
        '$platformName prebuild setup',
        stopwatch.elapsed,
      );

      StatusHelper.success('prebuild $platformName');
    } catch (e) {
      stopwatch.stop();
      _handlePrebuildException(e);
    }
  }

  /// Validates prebuild prerequisites including environment and configuration.
  ///
  /// Performs comprehensive validation of prebuild requirements including
  /// morpheme.yaml validation and platform-specific environment checks.
  ///
  /// Returns: true if all validation passes, false otherwise
  Future<bool> _validatePrerequisites() async {
    // Validate morpheme.yaml configuration
    try {
      final morphemeYaml = argResults!.getOptionMorphemeYaml();
      YamlHelper.validateMorphemeYaml(morphemeYaml);
    } catch (e) {
      BuildErrorHandler.handleConfigurationError(
          e, 'Invalid morpheme.yaml configuration');
      return false;
    }

    // Validate platform-specific environment
    final envValidation = validatePrebuildEnvironment();
    if (!envValidation.isValid) {
      BuildErrorHandler.handleValidationError(envValidation);
      return false;
    }

    // Validate macOS requirement if needed
    if (requiresMacOS && !Platform.isMacOS) {
      BuildErrorHandler.handlePlatformError(
        'macOS host system required for $platformName prebuild',
        suggestion: 'Use a macOS system to prepare $platformName builds',
      );
      return false;
    }

    return true;
  }

  /// Prepares prebuild configuration from command arguments and files.
  ///
  /// Extracts and validates all prebuild-related parameters including
  /// flavor configuration and deployment settings.
  ///
  /// Returns: PrebuildConfiguration object or null if validation fails
  Future<PrebuildConfiguration?> _preparePrebuildConfiguration() async {
    try {
      final argFlavor = argResults!.getOptionFlavor(defaultTo: Constants.dev);
      final argMorphemeYaml = argResults!.getOptionMorphemeYaml();

      // Load morpheme.yaml
      final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

      // Extract flavor configuration
      final flavorConfig = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);
      if (flavorConfig.isEmpty) {
        BuildErrorHandler.handleConfigurationError(
          'Flavor not found: $argFlavor',
          'Invalid flavor configuration',
        );
        return null;
      }

      // Load deployment configuration if specified
      Map<String, dynamic>? deploymentConfig;
      if (deploymentConfigPath != null && exists(deploymentConfigPath!)) {
        try {
          final deploymentData = readFile(deploymentConfigPath!);
          final Map<String, dynamic> allDeploymentConfig =
              jsonDecode(deploymentData);
          deploymentConfig = allDeploymentConfig[argFlavor];

          if (deploymentConfig == null) {
            BuildProgressReporter.reportWarning(
              'No deployment configuration found for flavor: $argFlavor',
            );
          }
        } catch (e) {
          BuildErrorHandler.handleConfigurationError(
            e,
            'Failed to load deployment configuration from ${deploymentConfigPath!}',
          );
          return null;
        }
      }

      return PrebuildConfiguration(
        flavor: argFlavor,
        morphemeYamlPath: argMorphemeYaml,
        morphemeYaml: Map<String, dynamic>.from(morphemeYaml),
        flavorConfig: Map<String, dynamic>.from(flavorConfig),
        deploymentConfig: deploymentConfig,
      );
    } catch (e) {
      BuildErrorHandler.handleConfigurationError(
          e, 'Failed to prepare prebuild configuration');
      return null;
    }
  }

  /// Handles prebuild exceptions with appropriate error categorization.
  ///
  /// Provides centralized exception handling with platform-specific
  /// error context and resolution guidance.
  ///
  /// Parameters:
  /// - [exception]: The caught exception
  void _handlePrebuildException(dynamic exception) {
    if (exception is BuildCommandException) {
      BuildErrorHandler.handleBuildException(exception);
    } else {
      BuildErrorHandler.handleGenericBuildError(
        exception,
        'Unexpected error during $platformName prebuild setup',
        platformName,
      );
    }
  }

  /// Generates a file with content and reports the generation.
  ///
  /// Utility method for creating configuration files with
  /// proper error handling and status reporting.
  ///
  /// Parameters:
  /// - [filePath]: Target file path
  /// - [content]: File content to write
  /// - [description]: Description for progress reporting
  void generateConfigFile(String filePath, String content, String description) {
    try {
      // Ensure directory exists
      final directory = dirname(filePath);
      if (!exists(directory)) {
        createDir(directory, recursive: true);
      }

      // Write file content
      filePath.write(content);

      BuildProgressReporter.reportPreparationStep(
        'Generated $description',
        true,
      );

      StatusHelper.generated(filePath);
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.artifactGenerationFailure,
        'Failed to generate $description: $e',
        suggestion: 'Check file permissions and disk space',
        examples: [
          'ls -la ${dirname(filePath)}',
          'chmod +w ${dirname(filePath)}',
        ],
      );
    }
  }

  /// Validates that a required configuration value exists.
  ///
  /// Utility method for validating configuration parameters
  /// with descriptive error messages.
  ///
  /// Parameters:
  /// - [value]: Configuration value to validate
  /// - [name]: Human-readable name for error messages
  /// - [context]: Additional context for the validation
  void validateRequiredConfig(dynamic value, String name, String context) {
    if (value == null || (value is String && value.isEmpty)) {
      throw BuildCommandException(
        BuildCommandError.buildConfigurationInvalid,
        '$name is required for $context',
        suggestion: 'Add $name to your configuration',
        examples: ['Check morpheme.yaml flavor configuration'],
      );
    }
  }

  /// Updates an existing file using regex replacement patterns.
  ///
  /// Utility method for modifying configuration files with
  /// pattern-based replacements and validation.
  ///
  /// Parameters:
  /// - [filePath]: File to modify
  /// - [replacements]: Map of regex patterns to replacement values
  /// - [description]: Description for progress reporting
  void updateConfigFile(
    String filePath,
    Map<String, String> replacements,
    String description,
  ) {
    try {
      if (!exists(filePath)) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'Configuration file not found: $filePath',
          suggestion: 'Ensure the file exists before attempting to update it',
        );
      }

      String content = readFile(filePath);

      // Apply all replacements
      for (final entry in replacements.entries) {
        final pattern = RegExp(entry.key);
        content = content.replaceAll(pattern, entry.value);
      }

      // Write updated content
      filePath.write(content);

      BuildProgressReporter.reportPreparationStep(
        'Updated $description',
        true,
      );

      StatusHelper.generated(filePath);
    } catch (e) {
      if (e is BuildCommandException) rethrow;

      throw BuildCommandException(
        BuildCommandError.artifactGenerationFailure,
        'Failed to update $description: $e',
        suggestion: 'Check file permissions and syntax',
        examples: [
          'ls -la $filePath',
          'cat $filePath',
        ],
      );
    }
  }
}
