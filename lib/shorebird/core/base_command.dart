import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/constants.dart';

import 'mixins/configuration_mixin.dart';
import 'mixins/validation_mixin.dart';
import 'mixins/logging_mixin.dart';
import 'models/command_config.dart';
import 'models/shorebird_result.dart';
import 'exceptions/shorebird_error.dart';

/// Abstract base class for all Shorebird commands providing common functionality
/// for argument parsing, validation, and execution workflow.
///
/// This class implements the Template Method pattern to define a consistent
/// execution workflow while allowing subclasses to customize specific steps.
///
/// ## Usage
///
/// Subclass this class and implement the required abstract methods:
///
/// ```dart
/// class MyCommand extends ShorebirdBaseCommand {
///   @override
///   String get name => 'my-command';
///
///   @override
///   String get description => 'My custom command';
///
///   @override
///   Future<ShorebirdCommandConfig> validateAndBuildConfig() async {
///     // Build configuration from arguments
///   }
///
///   @override
///   Future<ShorebirdResult> executeCommand(ShorebirdCommandConfig config) async {
///     // Execute the actual command
///   }
/// }
/// ```
///
/// ## Execution Workflow
///
/// The base class defines the following execution workflow:
/// 1. Validate arguments and build configuration
/// 2. Perform pre-execution setup (localization, Firebase, etc.)
/// 3. Execute the actual Shorebird command
/// 4. Perform post-execution cleanup
/// 5. Handle success or error
abstract class ShorebirdBaseCommand extends Command
    with
        ShorebirdCommandConfiguration,
        ShorebirdValidationMixin,
        ShorebirdLoggingMixin {
  /// Creates a new Shorebird command with standard argument configuration.
  ShorebirdBaseCommand() {
    addStandardOptions(argParser);
    addPlatformSpecificOptions(argParser);
  }

  /// Template method defining the command execution workflow.
  ///
  /// This method implements the standard execution flow that all Shorebird
  /// commands follow. Subclasses should not override this method unless
  /// they need to completely change the execution workflow.
  @override
  Future<void> run() async {
    final startTime = DateTime.now();

    try {
      logCommandStart(name, 'starting');

      // Step 1: Clean up previous cucumber artifacts
      CucumberHelper.removeNdjsonGherkin();

      // Step 2: Validate arguments and build configuration
      logStep('Validating arguments and building configuration');
      final config = await validateAndBuildConfig();

      // Step 3: Perform pre-execution setup
      logStep('Performing pre-execution setup');
      await preExecutionSetup(config);

      // Step 4: Execute the actual command
      logStep('Executing Shorebird command');
      final result = await executeCommand(config);

      // Step 5: Perform post-execution cleanup
      logStep('Performing post-execution cleanup');
      await postExecutionCleanup(result);

      // Step 6: Handle success
      final duration = DateTime.now().difference(startTime);
      handleSuccess(result, duration);
    } catch (error) {
      final duration = DateTime.now().difference(startTime);
      handleError(error, duration);
      rethrow;
    }
  }

  /// Validates command arguments and builds the command configuration.
  ///
  /// This method should parse command line arguments, validate them,
  /// and return a [ShorebirdCommandConfig] object that contains all
  /// the necessary configuration for command execution.
  ///
  /// Returns:
  /// - A [ShorebirdCommandConfig] with validated configuration
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If argument validation fails
  /// - [ShorebirdConfigurationError]: If configuration is invalid
  Future<ShorebirdCommandConfig> validateAndBuildConfig();

  /// Performs pre-execution setup tasks.
  ///
  /// This method handles common setup tasks like localization generation,
  /// Firebase configuration, and Shorebird YAML setup. Subclasses can
  /// override this method to add additional setup steps.
  ///
  /// Parameters:
  /// - [config]: The validated command configuration
  ///
  /// The default implementation:
  /// 1. Validates morpheme.yaml
  /// 2. Generates localization files (if enabled)
  /// 3. Sets up Firebase configuration
  /// 4. Configures Shorebird settings
  Future<void> preExecutionSetup(ShorebirdCommandConfig config) async {
    // Validate morpheme.yaml
    logValidation('morpheme.yaml');
    validateMorphemeYaml(config.morphemeYaml);

    // Generate localization if requested
    if (config.generateL10n) {
      logSetup('localization');
      await 'morpheme l10n --morpheme-yaml "${config.morphemeYaml}"'.run;
    }

    // Setup Firebase
    logSetup('Firebase configuration');
    FirebaseHelper.run(config.flavor, config.morphemeYaml);

    // Setup Shorebird
    logSetup('Shorebird configuration');
    final shorebird =
        validateShorebirdConfig(config.flavor, config.morphemeYaml);
    if (shorebird.$2 != null) {
      ShorebirdHelper.writeShorebirdYaml(shorebird.$2);
    }
  }

  /// Executes the actual Shorebird command.
  ///
  /// This is the core method that subclasses must implement to define
  /// their specific command behavior. This method should build and
  /// execute the appropriate Shorebird CLI command.
  ///
  /// Parameters:
  /// - [config]: The validated command configuration
  ///
  /// Returns:
  /// - A [ShorebirdResult] containing the execution outcome
  ///
  /// Throws:
  /// - [ShorebirdExecutionError]: If command execution fails
  Future<ShorebirdResult> executeCommand(ShorebirdCommandConfig config);

  /// Performs post-execution cleanup tasks.
  ///
  /// This method handles cleanup tasks after command execution.
  /// The default implementation does nothing, but subclasses can
  /// override this method to add cleanup logic.
  ///
  /// Parameters:
  /// - [result]: The result of command execution
  Future<void> postExecutionCleanup(ShorebirdResult result) async {
    // Default implementation does nothing
    // Subclasses can override to add cleanup logic
  }

  /// Handles successful command execution.
  ///
  /// This method is called when the command executes successfully.
  /// It logs the success and displays appropriate status messages.
  ///
  /// Parameters:
  /// - [result]: The successful execution result
  /// - [duration]: How long the command took to execute
  void handleSuccess(ShorebirdResult result, Duration duration) {
    logCommandComplete(name, duration);
    StatusHelper.success('shorebird $name');
  }

  /// Handles command execution errors.
  ///
  /// This method is called when the command fails. It logs the error
  /// and provides appropriate error messages to the user.
  ///
  /// Parameters:
  /// - [error]: The error that occurred
  /// - [duration]: How long the command ran before failing
  void handleError(dynamic error, Duration duration) {
    if (error is ShorebirdError) {
      logError(error.toDetailedString());
    } else {
      logError('Command failed after ${duration.inMilliseconds}ms: $error');
    }
  }

  /// Extracts common arguments from command line results.
  ///
  /// This helper method extracts the standard arguments that are
  /// common to all Shorebird commands.
  ///
  /// Returns a map containing the extracted arguments.
  Map<String, dynamic> extractCommonArguments() {
    return {
      'target': argResults!.getOptionTarget(),
      'flavor': argResults!.getOptionFlavor(defaultTo: Constants.dev),
      'morphemeYaml': argResults!.getOptionMorphemeYaml(),
      'buildNumber': argResults!.getOptionBuildNumber(),
      'buildName': argResults!.getOptionBuildName(),
      'obfuscate': argResults!['obfuscate'] as bool? ?? false,
      'splitDebugInfo': argResults!.getOptionSplitDebugInfo(),
      'generateL10n': argResults!.getFlagGenerateL10n(),
    };
  }

  /// Builds dart defines list from flavor configuration.
  ///
  /// Parameters:
  /// - [flavorConfig]: The flavor configuration map
  ///
  /// Returns a list of dart define strings.
  List<String> buildDartDefines(Map<String, String> flavorConfig) {
    return flavorConfig.entries
        .map((entry) => '${Constants.dartDefine} "${entry.key}=${entry.value}"')
        .toList();
  }
}
