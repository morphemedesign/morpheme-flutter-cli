import 'dart:convert';
import 'dart:io';

import 'package:morpheme_cli/core/src/commandline_converter.dart';

extension StringExtension on String {
  Future<int> get run async {
    final commandCli = CommandlineConverter().convert(this);

    final executable = commandCli.first;
    final arguments = commandCli.sublist(1);

    final process = await Process.start(
      executable,
      arguments,
      runInShell: true,
      environment: Platform.environment,
    );
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    process.stderr.transform(utf8.decoder).listen(stderr.write);
    return process.exitCode;
  }

  Future<int> start({
    String? workingDirectory,
    void Function(String line)? progressOut,
    void Function(String line)? progressErr,
    bool showLog = true,
  }) async {
    final commandCli = CommandlineConverter().convert(this);

    final executable = commandCli.first;
    final arguments = commandCli.sublist(1);

    final process = await Process.start(
      executable,
      arguments,
      runInShell: true,
      workingDirectory: workingDirectory,
      environment: Platform.environment,
    );

    process.stdout.transform(utf8.decoder).listen(((line) {
      progressOut?.call(line);
      if (showLog) stdout.write(line);
    }));

    process.stderr.transform(utf8.decoder).listen(((line) {
      progressErr?.call(line);
      if (showLog) stderr.write(line);
    }));

    return process.exitCode;
  }

  void write(String line) =>
      File(this).writeAsStringSync(line + Platform.lineTerminator);
  void append(String line) => File(this)
      .writeAsStringSync(line + Platform.lineTerminator, mode: FileMode.append);
}
