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

    final command =
        'morpheme test --morpheme-yaml $argMorphemeYaml $argApps $argFeature $argPage --coverage';

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

    final lcovDir = morphemeYaml['coverage']['lcov_dir']
        ?.toString()
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
