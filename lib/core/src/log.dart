import 'package:morpheme_cli/dependency_manager.dart';

/// Logging utilities for CLI applications.
///
/// This module provides simple file-based logging functionality for
/// debugging and monitoring CLI operations. Logs are written to a
/// 'morpheme_log.txt' file in the current working directory.
///
/// Note: Logging is automatically disabled in CI/CD environments
/// to avoid unnecessary file operations.

/// Clear the log file contents.
///
/// This function removes all existing content from the log file,
/// effectively starting with a clean log. The operation is skipped
/// in CI/CD environments.
///
/// Example:
/// ```dart
/// // Start with a fresh log file
/// clearLog();
///
/// // Continue with normal operations
/// appendLogToFile('Starting application');
/// ```

void clearLog() {
  if (isCiCdEnvironment) return;

  join(current, 'morpheme_log.txt').write('');
}

/// Append a message to the log file.
///
/// This function adds a new message to the end of the log file,
/// automatically adding a newline. The operation is skipped in
/// CI/CD environments to avoid unnecessary file I/O.
///
/// Parameters:
/// - [message]: The message to append to the log
///
/// The log file ('morpheme_log.txt') is created automatically if
/// it doesn't exist. If logging fails, the error is written to
/// stderr but doesn't interrupt the main application flow.
///
/// Example:
/// ```dart
/// // Log application events
/// appendLogToFile('Application started');
/// appendLogToFile('Processing file: example.txt');
/// appendLogToFile('Operation completed successfully');
///
/// // Log error information
/// appendLogToFile('Error: ${error.toString()}');
/// ```
void appendLogToFile(String message) {
  if (isCiCdEnvironment) return;

  join(current, 'morpheme_log.txt').append(message);
}
