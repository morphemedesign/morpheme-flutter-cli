/// Represents the result of a Shorebird command execution.
///
/// This class encapsulates the outcome of running a Shorebird command,
/// including success/failure status, output, and execution metadata.
class ShorebirdResult {
  /// Whether the command executed successfully
  final bool isSuccess;

  /// The command that was executed
  final String command;

  /// Output from the command execution
  final String output;

  /// Error message if the command failed
  final String? error;

  /// Exit code from the command execution
  final int exitCode;

  /// How long the command took to execute
  final Duration executionTime;

  /// Additional metadata about the execution
  final Map<String, dynamic> metadata;

  /// Creates a new Shorebird command result.
  ///
  /// Parameters:
  /// - [isSuccess]: Whether the command succeeded
  /// - [command]: The command that was executed
  /// - [output]: Output from command execution
  /// - [error]: Error message if command failed
  /// - [exitCode]: Exit code from execution
  /// - [executionTime]: Duration of command execution
  /// - [metadata]: Additional execution metadata
  ShorebirdResult({
    required this.isSuccess,
    required this.command,
    required this.output,
    this.error,
    required this.exitCode,
    required this.executionTime,
    this.metadata = const {},
  });

  /// Creates a successful result.
  ///
  /// Parameters:
  /// - [command]: The command that was executed
  /// - [output]: Output from the successful execution
  /// - [executionTime]: Duration of command execution
  /// - [metadata]: Additional execution metadata
  factory ShorebirdResult.success({
    required String command,
    required String output,
    required Duration executionTime,
    Map<String, dynamic> metadata = const {},
  }) {
    return ShorebirdResult(
      isSuccess: true,
      command: command,
      output: output,
      exitCode: 0,
      executionTime: executionTime,
      metadata: metadata,
    );
  }

  /// Creates a failure result.
  ///
  /// Parameters:
  /// - [command]: The command that failed
  /// - [error]: Error message describing the failure
  /// - [exitCode]: Exit code from the failed execution
  /// - [output]: Any output produced before failure
  /// - [executionTime]: Duration before failure occurred
  /// - [metadata]: Additional execution metadata
  factory ShorebirdResult.failure({
    required String command,
    required String error,
    required int exitCode,
    String output = '',
    Duration? executionTime,
    Map<String, dynamic> metadata = const {},
  }) {
    return ShorebirdResult(
      isSuccess: false,
      command: command,
      output: output,
      error: error,
      exitCode: exitCode,
      executionTime: executionTime ?? Duration.zero,
      metadata: metadata,
    );
  }

  /// Whether the command failed
  bool get isFailure => !isSuccess;

  /// Gets a summary of the execution result
  String getSummary() {
    if (isSuccess) {
      return 'Command "$command" completed successfully in ${executionTime.inMilliseconds}ms';
    } else {
      return 'Command "$command" failed with exit code $exitCode: ${error ?? "Unknown error"}';
    }
  }

  @override
  String toString() => getSummary();
}
