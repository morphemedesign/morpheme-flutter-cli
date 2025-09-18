import 'dart:convert';
import 'dart:io';

import 'package:morpheme_cli/core/src/commandline_converter.dart';

import 'loading.dart';

/// String extensions for command execution and file operations.
///
/// This module extends the String class with useful utilities for
/// command-line operations, process execution, and file manipulation.
///
/// Example usage:
/// ```dart
/// // Execute a command and wait for completion
/// await 'dart --version'.run;
///
/// // Start a process with custom options
/// await 'flutter build apk'.start(
///   workingDirectory: '/path/to/project',
///   showLog: false,
/// );
///
/// // Write to a file
/// '/path/to/file.txt'.write('Hello World');
///
/// // Append to a file
/// '/path/to/log.txt'.append('New log entry');
/// ```

/// String extensions for enhanced command-line and file operations.
extension StringExtension on String {
  Future<int> get run async {
    final commandCli = CommandlineConverter().convert(this);

    if (commandCli.isEmpty) {
      throw ArgumentError('Command cannot be empty');
    }

    final executable = commandCli.first;
    final arguments = commandCli.sublist(1);

    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: true,
        environment: Platform.environment,
      );

      process.stdout.transform(utf8.decoder).listen(
        (line) {
          printMessage(line.replaceAll(RegExp(r'[\s\n]+$'), ''));
        },
      );

      process.stderr.transform(utf8.decoder).listen(
        (line) {
          printerrMessage(line.replaceAll(RegExp(r'[\s\n]+$'), ''));
        },
      );

      final exitCode = await process.exitCode;

      if (exitCode > 0) {
        throw Exception('Command "$this" exited with code $exitCode');
      }

      return exitCode;
    } catch (e) {
      if (e is ProcessException) {
        throw Exception('Failed to execute command "$this": ${e.message}');
      }
      rethrow;
    }
  }

  Future<int> start({
    String? workingDirectory,
    void Function(String line)? progressOut,
    void Function(String line)? progressErr,
    bool showLog = true,
  }) async {
    final commandCli = CommandlineConverter().convert(this);

    if (commandCli.isEmpty) {
      throw ArgumentError('Command cannot be empty');
    }

    final executable = commandCli.first;
    final arguments = commandCli.sublist(1);

    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: true,
        workingDirectory: workingDirectory,
        environment: Platform.environment,
      );

      process.stdout.transform(utf8.decoder).listen((line) {
        final cleanLine = line.replaceAll(RegExp(r'[\s\n]+$'), '');
        progressOut?.call(cleanLine);
        if (showLog) printMessage(cleanLine);
      });

      process.stderr.transform(utf8.decoder).listen((line) {
        final cleanLine = line.replaceAll(RegExp(r'[\s\n]+$'), '');
        progressErr?.call(cleanLine);
        if (showLog) printerrMessage(cleanLine);
      });

      final exitCode = await process.exitCode;

      if (exitCode > 0) {
        throw Exception('Command "$this" exited with code $exitCode');
      }

      return exitCode;
    } catch (e) {
      if (e is ProcessException) {
        throw Exception('Failed to start command "$this": ${e.message}');
      }
      rethrow;
    }
  }

  /// Starts a process with stdin forwarding for interactive commands.
  ///
  /// This method is specifically designed for interactive commands that require
  /// user input (like Flutter run with hot reload support).
  ///
  /// Parameters:
  /// - [workingDirectory]: The working directory for the process
  /// - [progressOut]: Callback for stdout lines
  /// - [progressErr]: Callback for stderr lines
  /// - [showLog]: Whether to show log output
  Future<int> startWithStdin({
    String? workingDirectory,
    void Function(String line)? progressOut,
    void Function(String line)? progressErr,
    bool showLog = true,
    bool singleCharacterMode = false,
  }) async {
    final commandCli = CommandlineConverter().convert(this);

    if (commandCli.isEmpty) {
      throw ArgumentError('Command cannot be empty');
    }

    final executable = commandCli.first;
    final arguments = commandCli.sublist(1);

    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: true,
        workingDirectory: workingDirectory,
        environment: Platform.environment,
      );

      // Forward stdout
      process.stdout.transform(utf8.decoder).listen((line) {
        final cleanLine = line.replaceAll(RegExp(r'[\s\n]+$'), '');
        progressOut?.call(cleanLine);
        if (showLog) printMessage(cleanLine);
      });

      // Forward stderr
      process.stderr.transform(utf8.decoder).listen((line) {
        final cleanLine = line.replaceAll(RegExp(r'[\s\n]+$'), '');
        progressErr?.call(cleanLine);
        if (showLog) printerrMessage(cleanLine);
      });

      // Enable single character mode for stdin
      if (singleCharacterMode) {
        stdin.lineMode = false;
        stdin.echoMode = false;
      }

      // Forward stdin - this is the key part for interactive features
      // Use a more robust approach for stdin forwarding
      final subscription = stdin.listen(
        (data) {
          try {
            process.stdin.add(data);
          } catch (e) {
            // Ignore errors when writing to stdin (process might have exited)
          }
        },
        onError: (error) {
          // Handle stdin errors
        },
        onDone: () {
          // Close stdin when done
          process.stdin.close();
        },
      );

      // Handle process exit
      final exitCode = await process.exitCode;

      // Cancel stdin subscription
      await subscription.cancel();

      if (exitCode > 0) {
        throw Exception('Command "$this" exited with code $exitCode');
      }

      return exitCode;
    } catch (e) {
      if (e is ProcessException) {
        throw Exception('Failed to start command "$this": ${e.message}');
      }
      rethrow;
    }
  }

  void write(String line) {
    try {
      File(this).writeAsStringSync(line + Platform.lineTerminator);
    } catch (e) {
      throw Exception('Failed to write to file "$this": $e');
    }
  }

  void append(String line) {
    try {
      File(this).writeAsStringSync(
        line + Platform.lineTerminator,
        mode: FileMode.append,
      );
    } catch (e) {
      throw Exception('Failed to append to file "$this": $e');
    }
  }
}
