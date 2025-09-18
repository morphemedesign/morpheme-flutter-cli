import 'package:morpheme_cli/core/core.dart';

import '../core/models/command_config.dart';
import '../core/models/shorebird_result.dart';
import '../core/exceptions/execution_error.dart';
import '../core/mixins/logging_mixin.dart';

/// Abstract service for executing Shorebird commands with proper error handling
/// and result management.
///
/// This class provides a consistent interface for executing Shorebird commands
/// while handling errors, logging, and result processing in a standardized way.
///
/// ## Usage
///
/// Subclass this class to create specific Shorebird command services:
///
/// ```dart
/// class MyCommandService extends ShorebirdCommandService {
///   MyCommandService(super.config);
///
///   @override
///   Future<void> validate() async {
///     // Validate service-specific requirements
///   }
///
///   @override
///   String buildCommand() {
///     // Build the command string
///   }
/// }
/// ```
abstract class ShorebirdCommandService with ShorebirdLoggingMixin {
  /// The configuration for command execution
  final ShorebirdCommandConfig config;

  /// Creates a new service instance with the provided configuration.
  ///
  /// Parameters:
  /// - [config]: The command configuration to use for execution
  ShorebirdCommandService(this.config);

  /// Executes the Shorebird command and returns the result.
  ///
  /// This method implements the standard service execution flow:
  /// 1. Validate the configuration and service requirements
  /// 2. Build the command string
  /// 3. Execute the command
  /// 4. Process and return the result
  ///
  /// Returns:
  /// - A [ShorebirdResult] containing the execution outcome
  ///
  /// Throws:
  /// - [ShorebirdExecutionError]: If command execution fails
  Future<ShorebirdResult> execute() async {
    final startTime = DateTime.now();

    try {
      // Step 1: Validate configuration and requirements
      await validate();

      // Step 2: Build the command
      final command = buildCommand();
      logCommand(command);

      // Step 3: Execute the command
      final result = await _executeCommand(command, startTime);

      return result;
    } catch (error) {
      final duration = DateTime.now().difference(startTime);
      logError(
          'Service execution failed after ${duration.inMilliseconds}ms: $error');

      if (error is ShorebirdExecutionError) {
        rethrow;
      } else {
        throw ShorebirdExecutionError(
          message: 'Service execution failed: $error',
          command: 'shorebird service',
          commandOutput: error.toString(),
          processExitCode: 1,
          executionTime: duration,
        );
      }
    }
  }

  /// Validates the configuration before execution.
  ///
  /// This method should check that all required configuration values
  /// are present and valid for the specific service. Subclasses should
  /// override this method to add service-specific validation.
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If validation fails
  /// - [ShorebirdConfigurationError]: If configuration is invalid
  Future<void> validate();

  /// Builds the command string for execution.
  ///
  /// This method should construct the complete Shorebird command string
  /// based on the service configuration. Subclasses must implement this
  /// method to define their specific command structure.
  ///
  /// Returns:
  /// - A complete command string ready for execution
  String buildCommand();

  /// Executes the command and handles the result.
  Future<ShorebirdResult> _executeCommand(
      String command, DateTime startTime) async {
    try {
      // Execute the command using the core run functionality
      await command.run;

      final duration = DateTime.now().difference(startTime);

      return ShorebirdResult.success(
        command: command,
        output: 'Command executed successfully',
        executionTime: duration,
        metadata: {
          'config': config.toString(),
          'service': runtimeType.toString(),
        },
      );
    } catch (error) {
      final duration = DateTime.now().difference(startTime);

      throw ShorebirdExecutionError.fromCommandFailure(
        command,
        error.toString(),
        1, // Default exit code for failures
        duration,
      );
    }
  }

  /// Creates a formatted command argument string.
  ///
  /// This helper method formats command arguments properly for shell execution.
  ///
  /// Parameters:
  /// - [args]: List of command arguments
  ///
  /// Returns:
  /// - A properly formatted argument string
  String formatCommandArgs(List<String> args) {
    return args.where((arg) => arg.isNotEmpty).join(' ');
  }

  /// Validates that a required configuration value is present.
  ///
  /// Parameters:
  /// - [value]: The value to check
  /// - [fieldName]: Name of the field for error reporting
  ///
  /// Throws:
  /// - [ArgumentError]: If the value is null or empty
  void requireConfigValue(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      throw ArgumentError('$fieldName is required but was null or empty');
    }
  }
}
