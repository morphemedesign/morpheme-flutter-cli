import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

abstract class FlutterHelper {
  static String getCommandFlutter() {
    if (Platform.isWindows) {
      return 'flutter.bat';
    } else {
      return 'flutter';
    }
  }

  static String getCommandDart() {
    if (Platform.isWindows) {
      return 'dart.bat';
    } else {
      return 'dart';
    }
  }

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
}
