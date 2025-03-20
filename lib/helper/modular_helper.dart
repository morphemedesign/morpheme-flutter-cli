import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

abstract class ModularHelper {
  static const int defaultConcurrent = 6;

  static Future<void> execute(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String)? customCommand,
    void Function(String line)? stdout,
    bool ignorePubWorkspaces = false,
  }) async {
    final workingDirectoryFlutter = find('pubspec.yaml', workingDirectory: '.')
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
                    logs.add((true, line));
                  },
                );
              }
              customCommand?.call(e);

              isSuccess = true;
            } catch (e) {
              isSuccess = false;
            }

            return (path, isSuccess, logs);
          }
        ),
      );
    }

    bool isAllExecutedSuccess = true;
    int runnable = 0;
    final length = futures.length;
    printMessage('📦 Total Packages: $length');
    printMessage('---------------------------------------');
    for (runnable = 0; runnable < length; runnable += concurrent) {
      int take =
          runnable + concurrent > length ? length % concurrent : concurrent;

      final isolate = futures.getRange(runnable, runnable + take).map((e) {
        final path = e.$1;
        printMessage('🚀 $path: ${commands.join(', ')}');

        return Isolate.run<(String, bool, List<(bool, String)>)>(e.$2);
      });

      final results = await Future.wait(isolate);
      for (var i = 0; i < results.length; i++) {
        final path = results[i].$1;
        final isSuccess = results[i].$2;
        final logs = results[i].$3;
        if (isSuccess) {
          printMessage('✅  $path: ${commands.join(', ')}');
        } else {
          isAllExecutedSuccess = false;
          printMessage('❌  $path: ${commands.join(', ')}');
          printMessage('📝  Logs: $path');

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
      }
    }

    if (!isAllExecutedSuccess) {
      throw Exception('Some packages failed to execute');
    }
  }

  static Future<void> executeCommand(
    List<String> commands, {
    int concurrent = defaultConcurrent,
    void Function(String line)? stdout,
    bool ignorePubWorkspaces = false,
  }) async {
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
                  logs.add((true, line));
                },
              );

              isSuccess = true;
            } catch (e) {
              isSuccess = false;
            }

            return (command, isSuccess, logs);
          }
        ),
      );
    }

    bool isAllExecutedSuccess = true;
    int runnable = 0;
    final length = futures.length;
    printMessage('📦 Total Command: $length');
    printMessage('---------------------------------------');
    for (runnable = 0; runnable < length; runnable += concurrent) {
      int take =
          runnable + concurrent > length ? length % concurrent : concurrent;

      final isolate = futures.getRange(runnable, runnable + take).map((e) {
        final command = e.$1;
        printMessage('🚀 $command');

        return Isolate.run<(String, bool, List<(bool, String)>)>(e.$2);
      });

      final results = await Future.wait(isolate);
      for (var i = 0; i < results.length; i++) {
        final command = results[i].$1;
        final isSuccess = results[i].$2;
        final logs = results[i].$3;
        if (isSuccess) {
          printMessage('✅  $command');
        } else {
          isAllExecutedSuccess = false;
          printMessage('❌  $command');
          printMessage('📝  Logs: $command');

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
      }
    }

    if (!isAllExecutedSuccess) {
      throw Exception('Some packages failed to execute');
    }
  }

  static Future<void> runSequence(
    void Function(String path) runner, {
    bool ignorePubWorkspaces = false,
  }) async {
    final workingDirectoryFlutter = find('pubspec.yaml', workingDirectory: '.')
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
        await '${FlutterHelper.getCommandDart()} format .'.start(
          workingDirectory: element,
        );
      }
    }
  }

  static Future<void> fix([List<String>? paths]) async {
    if (paths == null || paths.isEmpty) {
      return execute(['${FlutterHelper.getCommandDart()} fix --apply']);
    } else {
      for (var element in paths) {
        await '${FlutterHelper.getCommandDart()} fix --apply'.start(
          workingDirectory: element,
        );
      }
    }
  }

  static Future<void> get({int concurrent = defaultConcurrent}) => execute(
        ['${FlutterHelper.getCommandFlutter()} pub get'],
        concurrent: concurrent,
      );
  static Future<void> test(
          {int concurrent = defaultConcurrent, bool isCoverage = false}) =>
      execute(
        [
          '${FlutterHelper.getCommandFlutter()} test test/bundle_test.dart --no-pub ${isCoverage ? '--coverage' : ''}'
        ],
        concurrent: concurrent,
        ignorePubWorkspaces: true,
      );
  static Future<void> upgrade({int concurrent = defaultConcurrent}) => execute(
        [
          '${FlutterHelper.getCommandFlutter()} packages upgrade',
          '${FlutterHelper.getCommandFlutter()} packages get',
        ],
        concurrent: concurrent,
      );
}
