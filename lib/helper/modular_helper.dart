import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

abstract class ModularHelper {
  static const int defaultConcurrent = 6;

  /// Executes commands in multiple Flutter project directories concurrently.
  ///
  /// This method finds all Flutter project directories (those containing pubspec.yaml)
  /// and executes the specified commands in each directory concurrently.
  ///
  /// Parameters:
  /// - [commands]: List of commands to execute in each directory
  /// - [concurrent]: Number of concurrent executions (default: 6)
  /// - [customCommand]: Optional custom command to execute after main commands
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  /// - [ignorePubWorkspaces]: Whether to ignore pub workspaces (default: false)
  ///
  /// Example:
  /// ```dart
  /// // Run 'flutter pub get' in all Flutter project directories
  /// await ModularHelper.execute(['flutter pub get']);
  /// ```
  static Future<void> execute(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String)? customCommand,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
    bool ignorePubWorkspaces = false,
  }) async {
    await _executeConcurrentCommands(
      commands,
      concurrent: concurrent,
      customCommand: customCommand,
      stdout: stdout,
      stdoutErr: stdoutErr,
      ignorePubWorkspaces: ignorePubWorkspaces,
    );
  }

  /// Finds all Flutter project directories in the current working directory.
  ///
  /// Looks for directories containing pubspec.yaml files and filters out
  /// pub workspaces based on the ignorePubWorkspaces parameter.
  ///
  /// Parameters:
  /// - [ignorePubWorkspaces]: Whether to ignore pub workspaces
  ///
  /// Returns: List of Flutter project directory paths
  static List<String> _findFlutterProjects(bool ignorePubWorkspaces) {
    return find('pubspec.yaml', workingDirectory: '.')
        .toList()
        .where(
          (element) {
            if (ignorePubWorkspaces) {
              return true;
            }

            final resolution = 'resolution';

            final yaml = YamlHelper.loadFileYaml(element);
            final hasResolution = yaml.containsKey(resolution);

            return !hasResolution;
          },
        )
        .map((e) => e.replaceAll('${separator}pubspec.yaml', ''))
        .sorted((a, b) =>
            b.split(separator).length.compareTo(a.split(separator).length));
  }

  /// Handles command execution errors.
  ///
  /// Processes exceptions that occur during command execution and
  /// converts them to appropriate error responses.
  ///
  /// Parameters:
  /// - [e]: The exception that occurred
  /// - [logs]: List of log entries collected during execution
  ///
  /// Returns: Tuple of (isSuccess, logs) where isSuccess is false
  static (bool, List<(bool, String)>) _handleCommandExecutionError(
    dynamic e,
    List<(bool, String)> logs,
  ) {
    // Log the exception
    logs.add((true, 'Exception occurred: $e'));
    return (false, logs);
  }

  /// Creates command futures for concurrent execution.
  ///
  /// Prepares a list of futures that will execute the specified commands
  /// in each Flutter project directory.
  ///
  /// Parameters:
  /// - [workingDirectoryFlutter]: List of Flutter project directory paths
  /// - [commands]: List of commands to execute
  /// - [customCommand]: Optional custom command to execute
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  ///
  /// Returns: List of futures for concurrent execution
  static List<(String, Future<(String, bool, List<(bool, String)>)> Function())>
      _createCommandFutures(
    List<String> workingDirectoryFlutter,
    List<String> commands,
    void Function(String)? customCommand,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
  ) {
    List<(String, Future<(String, bool, List<(bool, String)>)> Function())>
        futures = [];

    for (var e in workingDirectoryFlutter) {
      final path = e.replaceAll(current, '.');

      futures.add(
        (
          path,
          () async {
            final path = e.replaceAll(current, '.');
            List<(bool, String)> logs = [];
            bool isSuccess = false;

            try {
              for (var command in commands) {
                await command.start(
                  workingDirectory: e,
                  showLog: false,
                  progressOut: (line) {
                    stdout?.call(line);
                    logs.add((false, line));
                  },
                  progressErr: (line) {
                    if (line.isEmpty) return;
                    if (line.contains('Waiting for another flutter command')) {
                      return;
                    }
                    stdoutErr?.call(line);
                    logs.add((true, line));
                  },
                );
              }
              customCommand?.call(e);

              isSuccess = true;
            } catch (e) {
              final result = _handleCommandExecutionError(e, logs);
              isSuccess = result.$1;
              logs = result.$2;
            }

            return (path, isSuccess, logs);
          }
        ),
      );
    }

    return futures;
  }

  /// Handles the final exception when command execution fails.
  ///
  /// Throws an appropriate exception when one or more commands fail
  /// during concurrent execution.
  ///
  /// Parameters:
  /// - [isAllExecutedSuccess]: Whether all commands executed successfully
  static void _handleFinalExecutionException(bool isAllExecutedSuccess) {
    if (!isAllExecutedSuccess) {
      throw Exception('Some packages failed to execute');
    }
  }

  /// Processes log entries with appropriate formatting and coloring.
  ///
  /// Handles the display of log entries with color coding based on
  /// log type (error, info, warning, etc.).
  ///
  /// Parameters:
  /// - [logs]: List of log entries to process
  static void _processLogs(List<(bool, String)> logs) {
    for (var element in logs) {
      final isErrorMessage = element.$1;
      final line = element.$2;

      if (line.isEmpty ||
          RegExp(r'^\d{2}:\d{2}\s+\+\d+:').hasMatch(line) ||
          RegExp(r'^(\s)+$').hasMatch(line)) {
        continue;
      }

      if (isErrorMessage) {
        printerrMessage(red(element.$2));
        continue;
      }

      if (line.contains(RegExp(r'error'))) {
        printMessage(red(line));
      } else if (line.contains(RegExp(r'info'))) {
        printMessage(blue(line));
      } else if (line.contains(RegExp(r'warning'))) {
        printMessage(orange(line));
      } else {
        printMessage(element.$2);
      }
    }
  }

  /// Executes commands with common logic for both directory and command execution.
  ///
  /// This is a consolidated method that handles the common logic for
  /// executing commands in directories or as standalone commands.
  ///
  /// Parameters:
  /// - [futures]: List of command execution futures
  /// - [items]: List of items (paths or commands) being processed
  /// - [isDirectoryExecution]: Whether this is directory execution (true) or command execution (false)
  /// - [concurrent]: Number of concurrent executions
  static Future<void> _executeCommon(
    List<(String, Future<(String, bool, List<(bool, String)>)> Function())>
        futures,
    List<String> items,
    bool isDirectoryExecution,
    int concurrent,
  ) async {
    final length = futures.length;
    final itemType = isDirectoryExecution ? 'Packages' : 'Command';
    printMessage('📦 Total $itemType: $length');
    printMessage('---------------------------------------');

    for (int runnable = 0; runnable < length; runnable += concurrent) {
      int take =
          runnable + concurrent > length ? length % concurrent : concurrent;

      final isolate = futures.getRange(runnable, runnable + take).map((e) {
        final item = e.$1;
        final itemLabel =
            isDirectoryExecution ? '$item: ${items.join(', ')}' : item;
        printMessage('🚀 $itemLabel');

        return Isolate.run<(String, bool, List<(bool, String)>)>(e.$2);
      });

      final results = await Future.wait(isolate);
      bool isAllExecutedSuccess = true;

      for (var i = 0; i < results.length; i++) {
        final item = results[i].$1;
        final isSuccess = results[i].$2;
        final logs = results[i].$3;

        final itemLabel =
            isDirectoryExecution ? '$item: ${items.join(', ')}' : item;

        if (isSuccess) {
          printMessage('✅  $itemLabel');
        } else {
          isAllExecutedSuccess = false;
          printMessage('❌  $itemLabel');
          if (isDirectoryExecution) {
            printMessage('📝  Logs: $item');
          }
          _processLogs(logs);
        }
      }

      _handleFinalExecutionException(isAllExecutedSuccess);
    }
  }

  /// Executes commands concurrently with proper error handling and reporting.
  ///
  /// Manages the concurrent execution of command futures and handles
  /// the results, including success/failure reporting and logging.
  ///
  /// Parameters:
  /// - [commands]: List of commands to execute
  /// - [concurrent]: Number of concurrent executions
  /// - [customCommand]: Optional custom command to execute
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  /// - [ignorePubWorkspaces]: Whether to ignore pub workspaces
  static Future<void> _executeConcurrentCommands(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String)? customCommand,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
    bool ignorePubWorkspaces = false,
  }) async {
    final workingDirectoryFlutter = _findFlutterProjects(ignorePubWorkspaces);
    final futures = _createCommandFutures(
      workingDirectoryFlutter,
      commands,
      customCommand,
      stdout,
      stdoutErr,
    );

    await _executeCommon(futures, commands, true, concurrent);
  }

  /// Executes command futures with proper error handling and reporting.
  ///
  /// Manages the concurrent execution of command futures and handles
  /// the results, including success/failure reporting and logging.
  ///
  /// Parameters:
  /// - [commands]: List of commands to execute
  /// - [concurrent]: Number of concurrent executions
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  static Future<void> _executeCommandFutures(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
  }) async {
    final futures = _createCommandFuturesForCommands(
      commands,
      stdout,
      stdoutErr,
    );

    await _executeCommon(futures, commands, false, concurrent);
  }

  /// Executes commands concurrently in the current directory.
  ///
  /// This method executes the specified commands concurrently in the
  /// current directory, handling results and errors appropriately.
  ///
  /// Parameters:
  /// - [commands]: List of commands to execute
  /// - [concurrent]: Number of concurrent executions (default: 6)
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  /// - [ignorePubWorkspaces]: Whether to ignore pub workspaces (default: false)
  ///
  /// Example:
  /// ```dart
  /// // Run multiple Flutter commands concurrently
  /// await ModularHelper.executeCommand(['flutter pub get', 'flutter analyze']);
  /// ```
  static Future<void> executeCommand(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
    bool ignorePubWorkspaces = false,
  }) async {
    await _executeCommandFutures(
      commands,
      concurrent: concurrent,
      stdout: stdout,
      stdoutErr: stdoutErr,
    );
  }

  /// Creates command futures for concurrent command execution.
  ///
  /// Prepares a list of futures that will execute the specified commands
  /// in the current directory.
  ///
  /// Parameters:
  /// - [commands]: List of commands to execute
  /// - [stdout]: Callback for stdout lines
  /// - [stdoutErr]: Callback for stderr lines
  ///
  /// Returns: List of futures for concurrent execution
  static List<(String, Future<(String, bool, List<(bool, String)>)> Function())>
      _createCommandFuturesForCommands(
    List<String> commands,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
  ) {
    List<(String, Future<(String, bool, List<(bool, String)>)> Function())>
        futures = [];

    for (var command in commands) {
      futures.add(
        (
          command,
          () async {
            List<(bool, String)> logs = [];
            bool isSuccess = false;

            try {
              await command.start(
                workingDirectory: '.',
                showLog: false,
                progressOut: (line) {
                  stdout?.call(line);
                  logs.add((false, line));
                },
                progressErr: (line) {
                  if (line.isEmpty) return;
                  if (line.contains('Waiting for another flutter command')) {
                    return;
                  }
                  stdoutErr?.call(line);
                  logs.add((true, line));
                },
              );

              isSuccess = true;
            } catch (e) {
              final result = _handleCommandExecutionError(e, logs);
              isSuccess = result.$1;
              logs = result.$2;
            }

            return (command, isSuccess, logs);
          }
        ),
      );
    }

    return futures;
  }

  /// Runs a sequence of operations in Flutter project directories.
  ///
  /// This method finds all Flutter project directories and runs the
  /// specified runner function in each directory sequentially.
  ///
  /// Parameters:
  /// - [runner]: Function to execute in each Flutter project directory
  /// - [ignorePubWorkspaces]: Whether to ignore pub workspaces (default: false)
  ///
  /// Example:
  /// ```dart
  /// // Run a custom function in all Flutter project directories
  /// await ModularHelper.runSequence((path) {
  ///   print('Processing $path');
  ///   // Custom processing logic here
  /// });
  /// ```
  static Future<void> runSequence(
    void Function(String path) runner, {
    bool ignorePubWorkspaces = false,
  }) async {
    final workingDirectoryFlutter = _findFlutterProjects(ignorePubWorkspaces);
    final futures = _createSequenceFutures(workingDirectoryFlutter, runner);

    await _executeSequence(futures);
  }

  /// Creates futures for sequential execution.
  ///
  /// Prepares a list of futures that will execute the runner function
  /// in each Flutter project directory.
  ///
  /// Parameters:
  /// - [workingDirectoryFlutter]: List of Flutter project directory paths
  /// - [runner]: Function to execute in each directory
  ///
  /// Returns: List of futures for sequential execution
  static List<Future Function()> _createSequenceFutures(
    List<String> workingDirectoryFlutter,
    void Function(String path) runner,
  ) {
    List<Future Function()> futures = [];

    for (var e in workingDirectoryFlutter) {
      futures.add(() async {
        final path = e.replaceAll(current, '.');
        try {
          printMessage('🚀 $path');
          runner.call(path);
          printMessage('✅  $path');
        } catch (e) {
          printMessage('❌  $path');
          rethrow;
        }
      });
    }

    return futures;
  }

  /// Executes futures sequentially.
  ///
  /// Executes the prepared futures sequentially and handles
  /// progress reporting.
  ///
  /// Parameters:
  /// - [futures]: List of futures to execute sequentially
  static Future<void> _executeSequence(List<Future Function()> futures) async {
    final length = futures.length;
    printMessage('📦 Total Packages: $length');
    printMessage('---------------------------------------');
    for (var element in futures) {
      await element.call();
    }
  }

  static Future<void> analyze({int concurrent = defaultConcurrent}) => execute(
        ['${FlutterHelper.getCommandFlutter()} analyze . --no-pub'],
        concurrent: concurrent,
      );
  static Future<void> clean(
          {int concurrent = defaultConcurrent, bool removeLock = false}) =>
      execute(
        ['${FlutterHelper.getCommandFlutter()} clean'],
        customCommand: (workingDirectory) {
          if (!removeLock) return;
          final path = join(workingDirectory, 'pubspec.lock');
          if (exists(path)) {
            delete(path);
          }
        },
        concurrent: concurrent,
      );
  static Future<void> format([List<String>? paths]) async {
    if (paths == null || paths.isEmpty) {
      return execute(['${FlutterHelper.getCommandDart()} format .']);
    } else {
      for (var element in paths) {
        final isFile = File(element).existsSync();

        if (isFile) {
          await '${FlutterHelper.getCommandDart()} format $element'.start(
            workingDirectory: '.',
          );
        } else {
          await '${FlutterHelper.getCommandDart()} format .'.start(
            workingDirectory: element,
          );
        }
      }
    }
  }

  static Future<void> fix([List<String>? paths, bool dryRun = false]) async {
    final dryRunFlag = dryRun ? '--dry-run' : '--apply';

    if (paths == null || paths.isEmpty) {
      return execute(['${FlutterHelper.getCommandDart()} fix $dryRunFlag']);
    } else {
      for (var element in paths) {
        final isFile = File(element).existsSync();

        if (isFile) {
          await '${FlutterHelper.getCommandDart()} fix $dryRunFlag $element'
              .start(
            workingDirectory: '.',
          );
        } else {
          await '${FlutterHelper.getCommandDart()} fix $dryRunFlag'.start(
            workingDirectory: element,
          );
        }
      }
    }
  }

  static Future<void> get({int concurrent = defaultConcurrent}) => execute(
        ['${FlutterHelper.getCommandFlutter()} pub get'],
        concurrent: concurrent,
      );
  static Future<void> test({
    int concurrent = defaultConcurrent,
    bool isCoverage = false,
    String? reporter,
    String? fileReporter,
    void Function(String line)? stdout,
    void Function(String line)? stdoutErr,
  }) {
    final argReporter = reporter != null ? '--reporter $reporter' : '';
    final argFileReporter =
        fileReporter != null ? '--file-reporter $fileReporter' : '';
    return execute(
      [
        '${FlutterHelper.getCommandFlutter()} test test/bundle_test.dart --no-pub ${isCoverage ? '--coverage' : ''} $argReporter $argFileReporter'
      ],
      concurrent: concurrent,
      ignorePubWorkspaces: true,
      stdout: stdout,
      stdoutErr: stdoutErr,
    );
  }

  static Future<void> upgrade({int concurrent = defaultConcurrent}) => execute(
        [
          '${FlutterHelper.getCommandFlutter()} packages upgrade',
          '${FlutterHelper.getCommandFlutter()} packages get',
        ],
        concurrent: concurrent,
      );
}
