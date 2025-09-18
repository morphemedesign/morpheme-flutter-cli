/// Base class for all Shorebird-related errors providing consistent error
/// handling and reporting across the command system.
///
/// This abstract class ensures that all Shorebird errors follow a consistent
/// pattern for error reporting, exit codes, and context information.
abstract class ShorebirdError extends Error {
  /// Human-readable error message
  final String message;

  /// Exit code to return to the shell
  final int exitCode;

  /// The command that was being executed when the error occurred
  final String? command;

  /// Additional context information about the error
  final Map<String, dynamic> context;

  /// Creates a new Shorebird error with the specified details.
  ///
  /// Parameters:
  /// - [message]: A human-readable description of the error
  /// - [exitCode]: The exit code to return to the shell (defaults to 1)
  /// - [command]: The command being executed when the error occurred
  /// - [context]: Additional context information for debugging
  ShorebirdError({
    required this.message,
    this.exitCode = 1,
    this.command,
    this.context = const {},
  });

  @override
  String toString() => 'ShorebirdError: $message';

  /// Creates a formatted error report for logging.
  ///
  /// Returns a detailed string representation of the error including
  /// the message, exit code, command, and context information.
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('Error: $message');
    buffer.writeln('Exit Code: $exitCode');

    if (command != null) {
      buffer.writeln('Command: $command');
    }

    if (context.isNotEmpty) {
      buffer.writeln('Context:');
      context.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    return buffer.toString();
  }
}
