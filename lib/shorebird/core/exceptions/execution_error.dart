import 'shorebird_error.dart';

/// Error thrown when command execution fails at runtime.
///
/// This error is used when a Shorebird command fails during execution,
/// typically due to subprocess failures or external tool issues.
class ShorebirdExecutionError extends ShorebirdError {
  /// The output from the failed command
  final String commandOutput;

  /// The exit code returned by the failed process
  final int processExitCode;

  /// How long the command ran before failing
  final Duration executionTime;

  /// Creates a new execution error.
  ///
  /// Parameters:
  /// - [message]: Description of the execution failure
  /// - [command]: The command that failed to execute
  /// - [commandOutput]: Output from the failed command
  /// - [processExitCode]: Exit code from the failed process
  /// - [executionTime]: How long the command ran before failing
  ShorebirdExecutionError({
    required super.message,
    required String super.command,
    required this.commandOutput,
    required this.processExitCode,
    required this.executionTime,
  }) : super(
          exitCode: processExitCode,
          context: {
            'output': commandOutput,
            'process_exit_code': processExitCode,
            'execution_time_ms': executionTime.inMilliseconds,
          },
        );

  /// Creates an execution error from a failed command result.
  ///
  /// Parameters:
  /// - [command]: The command that failed
  /// - [output]: Output from the command
  /// - [exitCode]: Exit code from the process
  /// - [executionTime]: Duration of command execution
  factory ShorebirdExecutionError.fromCommandFailure(
    String command,
    String output,
    int exitCode,
    Duration executionTime,
  ) {
    return ShorebirdExecutionError(
      message: 'Command "$command" failed with exit code $exitCode',
      command: command,
      commandOutput: output,
      processExitCode: exitCode,
      executionTime: executionTime,
    );
  }

  /// Creates an execution error for a timeout.
  ///
  /// Parameters:
  /// - [command]: The command that timed out
  /// - [timeout]: The timeout duration that was exceeded
  factory ShorebirdExecutionError.timeout(
    String command,
    Duration timeout,
  ) {
    return ShorebirdExecutionError(
      message:
          'Command "$command" timed out after ${timeout.inSeconds} seconds',
      command: command,
      commandOutput: '',
      processExitCode: 124, // Standard timeout exit code
      executionTime: timeout,
    );
  }
}
