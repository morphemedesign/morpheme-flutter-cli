import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class CucumberCommand extends Command {
  CucumberCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
    argParser.addFlagGenerateL10n();
    argParser.addOptionDeviceId();
  }
  @override
  String get name => 'cucumber';

  @override
  String get description =>
      'Generate integration test from gherkin in .feature';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    if (which('gherkin').notfound) {
      StatusHelper.failed('gherkin not found in your machine');
    }

    final now = DateTime.now();

    final specificFeature =
        argResults?.rest.firstOrNull?.replaceAll('.feature', '').split(',');

    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    final deviceId = argResults.getDeviceId();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    if (argGenerateL10n) {
      await 'morpheme l10n --morpheme-yaml "$argMorphemeYaml"'.run;
    }

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);
    FirebaseHelper.run(argFlavor, argMorphemeYaml);
    List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });

    String pattern =
        specificFeature?.map((e) => '$e.feature').join('|') ?? '*.feature';

    final features = find(
      pattern,
      workingDirectory: join(current, 'integration_test', 'features'),
    ).toList();

    List<Map<String, String>> ndjsons = [];

    for (var element in features) {
      await 'gherkin "$element"'.start(
        progressOut: (line) {
          ndjsons.add({'ndjson': line});
        },
      );
    }

    final pathNdjson = join(current, 'integration_test', 'ndjson');
    DirectoryHelper.createDir(pathNdjson);
    join(pathNdjson, 'ndjson_gherkin.json').write(jsonEncode(ndjsons));

    StatusHelper.generated(pathNdjson);

    printMessage('Starting cucumber integration test....');

    await FlutterHelper.start(
      'test integration_test/cucumber_test.dart ${dartDefines.join(' ')} --dart-define "INTEGRATION_TEST=true" --no-pub $deviceId',
      progressOut: (line) async {
        if (line.contains('cucumber-report')) {
          final dir = join(current, 'integration_test', 'report');
          DirectoryHelper.createDir(dir);

          final cucumberReport = line.replaceAll('cucumber-report: ', '');
          join(dir, 'cucumber-report.json').write(cucumberReport);

          if (which('npm').found) {
            await 'npm install'.start(
              workingDirectory: join(current, 'integration_test', 'report'),
              showLog: false,
            );
            await 'node index.js'.start(
              workingDirectory: join(current, 'integration_test', 'report'),
              showLog: false,
            );

            printMessage(
                '🚀 Cucumber HTML report cucumber-report.html generated successfully 👍');
          }
        } else if (line.contains('morpheme-cucumber-stdout')) {
          final message = line.replaceAll('morpheme-cucumber-stdout: ', '');
          printMessage(message);
        } else if (line.toLowerCase().contains('failed')) {
          StatusHelper.failed(isExit: false, line);
        } else if (RegExp(r'\d{0,2}:\d{0,2}').hasMatch(line) ||
            line.trim().isEmpty) {
          // Do nothing
        } else {
          printMessage(line);
        }
      },
    );

    final totalTime = DateTime.now().difference(now);
    printMessage('⏰ Total Time: ${formatDurationInHhMmSs(totalTime)}');
  }

  String formatDurationInHhMmSs(Duration duration) {
    final hh = (duration.inHours).toString().padLeft(2, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }
}
