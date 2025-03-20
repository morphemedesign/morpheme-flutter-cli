import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

void clearLog() {
  final logFile = File(join(current, 'morpheme_log.txt'));
  logFile.writeAsStringSync('');
}

void appendLogToFile(String message) {
  final logFile = File(join(current, 'morpheme_log.txt'));
  final sink = logFile.openWrite(mode: FileMode.append);
  sink.write(message);
  sink.close();
}
