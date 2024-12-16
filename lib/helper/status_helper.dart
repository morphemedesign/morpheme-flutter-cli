import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

abstract class StatusHelper {
  static void success([String? message]) {
    if (message != null) {
      printMessage(message);
    }
    printMessage(green('SUCCESS'));
  }

  static void warning(String message) {
    printerrMessage(orange(message));
  }

  static void failed(String message, {bool isExit = true, int statusExit = 1}) {
    printerrMessage(red(message));
    printerrMessage(red('FAILED'));
    if (isExit) {
      exit(statusExit);
    }
  }

  static void generated(String path) {
    printMessage('${green('generated')} $path');
  }

  static void refactor(String path) {
    printMessage('${green('refactor')} $path');
  }
}
