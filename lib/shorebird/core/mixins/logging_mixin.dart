import 'package:morpheme_cli/core/core.dart';

/// Mixin that provides logging functionality for Shorebird commands.
///
/// This mixin provides consistent logging methods that are used across
/// all Shorebird commands for status updates, information, and errors.
mixin ShorebirdLoggingMixin {
  /// Logs an informational message.
  ///
  /// Parameters:
  /// - [message]: The message to log
  /// - [prefix]: Optional prefix for the message (defaults to 'Info')
  void logInfo(String message, {String prefix = 'Info'}) {
    printMessage('[$prefix] $message');
  }

  /// Logs a warning message.
  ///
  /// Parameters:
  /// - [message]: The warning message to log
  void logWarning(String message) {
    printMessage('[Warning] $message');
  }

  /// Logs an error message.
  ///
  /// Parameters:
  /// - [message]: The error message to log
  void logError(String message) {
    printMessage('[Error] $message');
  }

  /// Logs a success message.
  ///
  /// Parameters:
  /// - [message]: The success message to log
  void logSuccess(String message) {
    printMessage('[Success] $message');
  }

  /// Logs the command that is about to be executed.
  ///
  /// Parameters:
  /// - [command]: The command string to log
  void logCommand(String command) {
    logInfo('Executing command: $command', prefix: 'Command');
  }

  /// Logs a step in the execution process.
  ///
  /// Parameters:
  /// - [step]: Description of the step being executed
  void logStep(String step) {
    logInfo(step, prefix: 'Step');
  }

  /// Logs debug information (only when debug mode is enabled).
  ///
  /// Parameters:
  /// - [message]: The debug message to log
  void logDebug(String message) {
    // Could add debug mode check here
    logInfo(message, prefix: 'Debug');
  }

  /// Logs the start of a command execution.
  ///
  /// Parameters:
  /// - [commandName]: Name of the command being started
  /// - [flavor]: The flavor being used
  void logCommandStart(String commandName, String flavor) {
    logInfo('Starting $commandName for flavor: $flavor', prefix: 'Start');
  }

  /// Logs the completion of a command execution.
  ///
  /// Parameters:
  /// - [commandName]: Name of the command that completed
  /// - [duration]: How long the command took to execute
  void logCommandComplete(String commandName, Duration duration) {
    logSuccess('$commandName completed in ${duration.inMilliseconds}ms');
  }

  /// Logs a validation step.
  ///
  /// Parameters:
  /// - [item]: The item being validated
  void logValidation(String item) {
    logStep('Validating $item');
  }

  /// Logs a setup step.
  ///
  /// Parameters:
  /// - [component]: The component being set up
  void logSetup(String component) {
    logStep('Setting up $component');
  }
}
