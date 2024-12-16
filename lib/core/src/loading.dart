import 'dart:async';
import 'dart:io';

import 'print.dart';

void printMessage(String? message) {
  Loading().printMessage(message);
}

void printerrMessage(String? message) {
  Loading().printerrMessage(message);
}

class Loading {
  // Singleton instance
  static final Loading _instance = Loading._internal();

  // Private constructor
  Loading._internal()
      : _isCiCdEnvironment = Platform.environment.containsKey('CI') &&
            Platform.environment['CI'] == 'true';

  // Factory constructor
  factory Loading() {
    return _instance;
  }

  Timer? _timer;
  int _progress = 0;
  bool _isRunning = false;
  final List<String> _loadingStates = ['-', '\\', '|', '/'];

  final bool _isCiCdEnvironment;

  void start() {
    if (_isRunning || _isCiCdEnvironment) {
      return; // Prevent starting multiple timers
    }

    _isRunning = true;
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _update();
    });
  }

  void _update() {
    if (!_isRunning || _isCiCdEnvironment) return;

    // Move to the next loading state
    _progress = (_progress + 1) % _loadingStates.length;
    stdout.write(
        '\r${_loadingStates[_progress]} Loading...'); // '\r' returns to the start of the line
  }

  void stop() {
    if (!_isRunning || _isCiCdEnvironment) return;

    stdout.write('\r${' ' * 20}\r'); // Clear the current loading line

    _isRunning = false;
    _timer?.cancel();
  }

  void printMessage(Object? message) {
    if (RegExp(r'[\-\\|\/] Loading\.\.\.').hasMatch(message.toString())) {
      return; // Prevent printing loading states
    }

    if (_isRunning && !_isCiCdEnvironment) {
      // Temporarily stop the loading bar to print a clean message
      stdout.write('\r${' ' * 20}\r'); // Clear the current loading line
    }
    print(message);
    if (_isRunning && !_isCiCdEnvironment) {
      // Resume the loading bar after printing the message
      _update();
    }
  }

  void printerrMessage(String? message) {
    if (RegExp(r'[\-\\|\/] Loading\.\.\.').hasMatch(message.toString())) {
      return; // Prevent printing loading states
    }

    if (_isRunning && !_isCiCdEnvironment) {
      // Temporarily stop the loading bar to print a clean message
      stdout.write('\r${' ' * 20}\r'); // Clear the current loading line
    }
    printerr(message);
    if (_isRunning && !_isCiCdEnvironment) {
      // Resume the loading bar after printing the message
      _update();
    }
  }
}
