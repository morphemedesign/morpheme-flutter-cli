import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class ConfigCommand extends Command {
  ConfigCommand() {
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'config';

  @override
  String get description =>
      'Generate launch.json & tasks.json related with config.';

  @override
  String get category => Constants.generate;

  String projectName = '';

  @override
  void run() {
    final argTarget = argResults.getOptionTarget();
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    projectName = yaml.projectName;

    Map<String, List<String>> dartDefines = {};

    yaml['flavor'].forEach((key, value) {
      final list = <String>[];
      value.forEach((key, value) {
        list.add('"${Constants.dartDefine}"');
        list.add('"$key=$value"');
      });
      dartDefines[key] = list;
    });

    if (!exists(join(current, '.vscode'))) {
      createDir(join(current, '.vscode'), recursive: true);
    }

    join(current, '.vscode', 'launch.json').write('''{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
${dartDefines.entries.map((e) => '''        {
            "name": "${projectName.titleCase} Debug ${e.key.titleCase}",
            "request": "launch",
            "type": "dart",
            "flutterMode": "debug",
            "preLaunchTask": "build-${e.key.paramCase}",
            "program": "$argTarget",
            "args": [
                ${e.value.join(',\n\t\t\t\t')}
            ]
        },
        {
            "name": "${projectName.titleCase} Profile ${e.key.titleCase}",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile",
            "preLaunchTask": "build-${e.key.paramCase}",
            "program": "$argTarget",
            "args": [
                ${e.value.join(',\n\t\t\t\t')}
            ]
        },
        {
            "name": "${projectName.titleCase} Release ${e.key.titleCase}",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release",
            "preLaunchTask": "build-${e.key.paramCase}",
            "program": "$argTarget",
            "args": [
                ${e.value.join(',\n\t\t\t\t')}
            ]
        },''').join('\n')}
    ]
}''');

    join(current, '.vscode', 'tasks.json').write('''{
    "version": "2.0.0",
    "tasks": [
${dartDefines.entries.map((e) => '''        {
            "label": "firebase-${e.key.paramCase}",
            "command": "morpheme firebase -f ${e.key}",
            "type": "shell"
        },
        {
            "label": "build-${e.key.paramCase}",
            "dependsOn": [
                "firebase-${e.key.paramCase}",
            ],
        },''').join('\n')}
    ]
}''');

    StatusHelper.generated(join(current, '.vscode', 'launch.json'));
    StatusHelper.generated(join(current, '.vscode', 'tasks.json'));

    StatusHelper.success('morpheme config');
  }
}
