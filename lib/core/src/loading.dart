import 'dart:async';
import 'dart:io';

import 'package:morpheme_cli/core/src/is.dart';
import 'package:morpheme_cli/core/src/log.dart';

import 'print.dart';

/// Global console output utilities with loading animation support.
///
/// This module provides enhanced console output functions that integrate
/// with a loading animation system. The loading animation is automatically
/// disabled in CI/CD environments to avoid cluttering logs.

/// Print a message to stdout with loading animation integration.
///
/// This function temporarily pauses any active loading animation,
/// prints the message, and then resumes the animation. The message
/// is also logged to the log file.
///
/// Parameters:
/// - [message]: The message to print (null is converted to string)
///
/// Example:
/// ```dart
/// printMessage('Processing files...');
/// printMessage('Found ${fileCount} files');
/// ```

void printMessage(String? message) {
  Loading().printMessage(message);
}

void printerrMessage(String? message) {
  Loading().printerrMessage(message);
}

/// Loading animation manager for CLI applications.
///
/// This singleton class manages a rotating loading animation that displays
/// while long-running operations are in progress. The animation is automatically
/// disabled in CI/CD environments to keep logs clean.
///
/// The animation cycles through: '-', '\\', '|', '/'
///
/// Example:
/// ```dart
/// final loading = Loading();
///
/// // Start the loading animation
/// loading.start();
///
/// try {
///   // Perform long-running operation
///   await longRunningOperation();
///
///   // Print status updates (animation pauses automatically)
///   printMessage('Step 1 complete');
///   printMessage('Step 2 complete');
/// } finally {
///   // Stop the loading animation
///   loading.stop();
/// }
/// ```
class Loading {
  // Singleton instance
  static final Loading _instance = Loading._internal();

  // Private constructor
  Loading._internal();

  // Factory constructor
  factory Loading() {
    return _instance;
  }

  Timer? _timer;
  int _progress = 0;
  bool _isRunning = false;
  final List<String> _loadingStates = ['-', '\\', '|', '/'];

  void start() {
    if (_isRunning || isCiCdEnvironment) {
      return; // Prevent starting multiple timers or running in CI/CD
    }

    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _update();
    });
  }

  void _update() {
    if (!_isRunning || isCiCdEnvironment) return;

    // Move to the next loading state
    _progress = (_progress + 1) % _loadingStates.length;
    stdout.write(
        '\r${_loadingStates[_progress]} Loading...'); // '\r' returns to start of line
  }

  void stop() {
    if (!_isRunning || isCiCdEnvironment) return;

    stdout.write('\r${' ' * 20}\r'); // Clear the current loading line

    _isRunning = false;
    _timer?.cancel();
  }

  void printMessage(Object? message) {
    if (_isLoadingStateMessage(message.toString())) {
      return; // Prevent printing loading states
    }

    if (_isRunning && !isCiCdEnvironment) {
      // Temporarily stop the loading bar to print a clean message
      stdout.write('\r${' ' * 20}\r'); // Clear the current loading line
    }
    print(message);
    appendLogToFile(message.toString());
    if (_isRunning && !isCiCdEnvironment) {
      // Resume the loading bar after printing the message
      _update();
    }
  }

  void printerrMessage(String? message) {
    if (_isLoadingStateMessage(message.toString())) {
      return; // Prevent printing loading states
    }

    if (_isRunning && !isCiCdEnvironment) {
      // Temporarily stop the loading bar to print a clean message
      stdout.write('\r${' ' * 20}\r'); // Clear the current loading line
    }
    printerr(message);
    appendLogToFile(message.toString());
    if (_isRunning && !isCiCdEnvironment) {
      // Resume the loading bar after printing the message
      _update();
    }
  }

  /// Check if a message appears to be a loading state indicator.
  ///
  /// This internal method identifies messages that match the loading animation
  /// pattern to prevent them from being printed and causing display confusion.
  bool _isLoadingStateMessage(String message) {
    return RegExp(r'[\-\\|\/] Loading\.\.\.').hasMatch(message);
  }
}
