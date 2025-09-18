import 'dart:async';
import 'dart:io';

/// Error output utilities for CLI applications.
///
/// This module provides functions for writing error messages to stderr,
/// following CLI conventions where errors go to stderr and normal output
/// goes to stdout.

/// Callback function type for capturing stderr output.
///
/// This is used when overriding [printerr] behavior in zones.
typedef CaptureZonePrintErr = void Function(String?);

/// Zone key for capturing stderr output.
///
/// This experimental feature allows capturing stderr output within zones.
const String capturePrinterrKey = 'printerr';

/// Write a message to stderr (standard error output).
///
/// This function provides the equivalent functionality to Dart's standard
/// [print] function, but writes to stderr instead of stdout. This follows
/// CLI conventions where error messages should go to stderr.
///
/// Parameters:
/// - [line]: The message to write to stderr (null is converted to 'null')
///
/// This function cooperates with zone-based output capture if configured.
/// When running in a zone with [capturePrinterrKey] set, the output will
/// be redirected to the configured capture function.
///
/// Example:
/// ```dart
/// // Write error message to stderr
/// printerr('Error: File not found');
///
/// // Write warning to stderr
/// printerr('Warning: Deprecated function used');
///
/// // Handle null values gracefully
/// String? message = null;
/// printerr(message); // Outputs 'null'
/// ```
///
/// See also:
/// * [print] for writing to stdout
/// * [capturePrinterrKey] for zone-based output capture
void printerr(String? line) {
  /// Co-operate with runDCliZone
  final overloaded = Zone.current[capturePrinterrKey] as CaptureZonePrintErr?;
  if (overloaded != null) {
    overloaded(line);
  } else {
    stderr.writeln(line);
  }
}
