import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

abstract class FlutterHelper {
  /// Gets the appropriate Flutter command for the current platform.
  ///
  /// Returns 'flutter.bat' on Windows and 'flutter' on other platforms.
  ///
  /// Example:
  /// ```dart
  /// final flutterCmd = FlutterHelper.getCommandFlutter();
  /// print('Using Flutter command: $flutterCmd');
  /// ```
  static String getCommandFlutter() {
    if (Platform.isWindows) {
      return 'flutter.bat';
    } else {
      return 'flutter';
    }
  }

  /// Gets the appropriate Dart command for the current platform.
  ///
  /// Returns 'dart.bat' on Windows and 'dart' on other platforms.
  ///
  /// Example:
  /// ```dart
  /// final dartCmd = FlutterHelper.getCommandDart();
  /// print('Using Dart command: $dartCmd');
  /// ```
  static String getCommandDart() {
    if (Platform.isWindows) {
      return 'dart.bat';
    } else {
      return 'dart';
    }
  }

  /// Runs a Flutter command and waits for completion.
  ///
  /// This method executes a Flutter command and captures its output,
  /// returning the exit code when the command completes.
  ///
  /// Parameters:
  /// - [argument]: The Flutter command arguments
  /// - [showLog]: Whether to show the command being executed
  ///
  /// Returns: The exit code of the Flutter command
  ///
  /// Example:
  /// ```dart
  /// // Run Flutter analyze
  /// final exitCode = await FlutterHelper.run('analyze');
  /// if (exitCode == 0) {
  ///   print('Analysis completed successfully');
  /// } else {
  ///   print('Analysis failed with exit code: $exitCode');
  /// }
  ///
  /// // Run Flutter pub get and show the command
  /// await FlutterHelper.run('pub get', showLog: true);
  /// ```
  static Future<int> run(String argument, {bool showLog = false}) async {
    String command = '${getCommandFlutter()} $argument';
    if (showLog) printMessage(command);
    return command.start(
      showLog: false,
      progressOut: (line) =>
          printMessage(line.replaceAll(RegExp(r'[\s\n]+$'), '')),
      progressErr: (line) =>
          printerrMessage(line.replaceAll(RegExp(r'[\s\n]+$'), '')),
    );
  }

  /// Starts a Flutter process and returns immediately.
  ///
  /// This method starts a Flutter process and returns a Future that
  /// completes when the process exits. It allows for custom callbacks
  /// to handle stdout and stderr output.
  ///
  /// Parameters:
  /// - [argument]: The Flutter command arguments
  /// - [showLog]: Whether to show the command being executed
  /// - [workingDirectory]: The working directory for the process
  /// - [progressOut]: Callback for stdout lines
  /// - [progressErr]: Callback for stderr lines
  ///
  /// Returns: A Future that completes with the exit code
  ///
  /// Example:
  /// ```dart
  /// // Start Flutter pub get with custom output handling
  /// await FlutterHelper.start('pub get',
  ///   progressOut: (line) => print('OUT: $line'),
  ///   progressErr: (line) => print('ERR: $line'),
  /// );
  ///
  /// // Start Flutter build in a specific directory
  /// await FlutterHelper.start('build apk',
  ///   workingDirectory: './my_flutter_app',
  ///   showLog: true,
  /// );
  /// ```
  static Future<int> start(
    String argument, {
    bool showLog = false,
    String? workingDirectory,
    void Function(String line)? progressOut,
    void Function(String line)? progressErr,
  }) {
    String command = '${getCommandFlutter()} $argument';
    if (showLog) printMessage(command);
    return command.start(
      workingDirectory: workingDirectory,
      progressOut: progressOut,
      progressErr: progressErr,
    );
  }

  /// Starts a Flutter process with stdin forwarding for interactive commands.
  ///
  /// This method is specifically designed for interactive Flutter commands that require
  /// user input (like Flutter run with hot reload support). It forwards stdin from the
  /// parent process to the Flutter process, allowing for interactive development workflows.
  ///
  /// Parameters:
  /// - [argument]: The Flutter command arguments
  /// - [showLog]: Whether to show the command being executed
  /// - [singleCharacterMode]: Whether to enable single character input mode (for hot keys)
  /// - [workingDirectory]: The working directory for the process
  /// - [progressOut]: Callback for stdout lines
  /// - [progressErr]: Callback for stderr lines
  ///
  /// Example:
  /// ```dart
  /// // Start Flutter app with hot reload support
  /// await FlutterHelper.startWithStdin('run');
  ///
  /// // Start Flutter app with single character mode for hot keys
  /// await FlutterHelper.startWithStdin('run', singleCharacterMode: true);
  /// ```
  ///
  /// Note: This method should only be used for interactive commands that require
  /// user input. For non-interactive commands, use [run] or [start] instead.
  static Future<int> startWithStdin(
    String argument, {
    bool showLog = false,
    bool singleCharacterMode = false,
    String? workingDirectory,
    void Function(String line)? progressOut,
    void Function(String line)? progressErr,
  }) {
    String command = '${getCommandFlutter()} $argument';
    if (showLog) printMessage(command);
    return command.startWithStdin(
      workingDirectory: workingDirectory,
      progressOut: progressOut,
      progressErr: progressErr,
      singleCharacterMode: singleCharacterMode,
    );
  }
}
