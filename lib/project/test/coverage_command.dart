import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class CoverageCommand extends Command {
  CoverageCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'apps',
      abbr: 'a',
      help: 'Test with spesific apps (Optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Test with spesific feature (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Test with spesific page (optional)',
    );
    argParser.addOption(
      'reporter',
      abbr: 'r',
      help:
          '''Set how to print test results. If unset, value will default to either compact or expanded.

          [compact]                                          A single line, updated continuously (the default).
          [expanded]                                         A separate line for each update. May be preferred when logging to a file or in continuous integration.
          [failures-only]                                    A separate line for failing tests, with no output for passing tests.
          [github]                                           A custom reporter for GitHub Actions (the default reporter when running on GitHub Actions).
          [json]                                             A machine-readable format. See: https://dart.dev/go/test-docs/json_reporter.md
          [silent]                                           A reporter with no output. May be useful when only the exit code is meaningful.''',
      allowed: [
        'compact',
        'expanded',
        'failures-only',
        'github',
        'json',
        'silent',
      ],
    );
    argParser.addOption(
      'file-reporter',
      help: '''Enable an additional reporter writing test results to a file.
                                                             Should be in the form <reporter>:<filepath>, Example: "json:reports/tests.json".''',
    );
  }

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Run Flutter test coverage for the current project & all modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    final String? apps = argResults?['apps']?.toString().snakeCase;
    final String? feature = argResults?['feature']?.toString().snakeCase;
    final String? page = argResults?['page']?.toString().snakeCase;

    final argApps = apps != null ? '-a $apps' : '';
    final argFeature = feature != null ? '-f $feature' : '';
    final argPage = page != null ? '-p $page' : '';

    final String? reporter = argResults?['reporter'];
    final argReporter = reporter != null ? '--reporter $reporter' : '';

    final String? fileReporter = argResults?['file-reporter'];
    final argFileReporter =
        fileReporter != null ? '--file-reporter $fileReporter' : '';

    final command =
        'morpheme test --morpheme-yaml $argMorphemeYaml $argApps $argFeature $argPage --coverage $argReporter $argFileReporter';

    await command.run;

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    if (!morphemeYaml.containsKey('coverage')) {
      StatusHelper.failed('morpheme.yaml not contain coverage config!');
    }

    if (Platform.isWindows) {
      printMessage(
          'you must install perl and lcov then lcov remove file will be ignore to coverage manually & generate report to html manually.');
    }

    if (which('lcov').notfound) {
      StatusHelper.failed(
          'lcov not found, failed to remove ignore file to test.');
    }

    final lcovDir = join(current, 'coverage', 'merge_lcov.info')
        .toString()
        .replaceAll('/', separator);
    final outputHtmlDir = morphemeYaml['coverage']['output_html_dir']
        ?.toString()
        .replaceAll('/', separator);
    final removeFile = (morphemeYaml['coverage']['remove'] as List).join(' ');

    printMessage(
        "lcov --remove $lcovDir $removeFile -o $lcovDir --ignore-errors unused");

    await "lcov --remove $lcovDir $removeFile -o $lcovDir --ignore-errors unused"
        .run;

    if (which('genhtml').notfound) {
      StatusHelper.failed('failed cannot generate report lcov html.');
    }
    await 'genhtml $lcovDir -o $outputHtmlDir'.run;

    StatusHelper.success('Coverage report generated to $outputHtmlDir');
  }
}
