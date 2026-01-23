import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// A command that generates IDE configurations for VS Code and Android Studio.
///
/// This command reads flavor configurations from a morpheme.yaml file and
/// generates corresponding launch configurations for both VS Code and
/// Android Studio IDEs. It creates launch.json and tasks.json for VS Code
/// and XML configuration files for Android Studio run configurations.
class ConfigCommand extends Command {
  /// Creates a new config command with required arguments.
  ///
  /// Adds the target option for specifying the main Dart file and
  /// the morpheme-yaml option for specifying the configuration file path.
  ConfigCommand() {
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'config';

  @override
  String get description =>
      'Generate VS Code and Android Studio IDE configurations.';

  @override
  String get category => Constants.generate;

  /// Stores the project name read from the morpheme.yaml file.
  String projectName = '';

  /// Stores the isFirebase read from the morpheme.yaml file.
  bool isFirebase = false;

  /// Executes the config command.
  ///
  /// This method:
  /// 1. Parses command line arguments
  /// 2. Validates and loads the morpheme.yaml configuration
  /// 3. Extracts flavor-specific dart defines
  /// 4. Generates VS Code configurations
  /// 5. Generates Android Studio configurations
  ///
  /// Throws an exception if the morpheme.yaml file is invalid or missing.
  @override
  void run() {
    final argTarget = argResults.getOptionTarget();
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    projectName = yaml.projectName;
    isFirebase = yaml['flavor'].containsKey('firebase');

    Map<String, List<String>> dartDefines = {};

    yaml['flavor'].forEach((key, value) {
      final list = <String>[];
      value.forEach((key, value) {
        list.add('"${Constants.dartDefine}"');
        list.add('"$key=$value"');
      });
      dartDefines[key] = list;
    });

    // Generate VS Code configurations
    _generateVSCodeConfigurations(argTarget, dartDefines);

    // Generate Android Studio configurations
    _generateAndroidStudioConfigurations(argTarget, dartDefines, projectName);

    StatusHelper.success('morpheme config');
  }

  /// Generates VS Code configuration files (launch.json and tasks.json).
  ///
  /// Creates or overwrites the .vscode/launch.json file with debug, profile,
  /// and release configurations for each flavor defined in the morpheme.yaml.
  /// Also creates .vscode/tasks.json with build tasks for each flavor.
  ///
  /// [target] The path to the main Dart file (usually lib/main.dart)
  /// [dartDefines] A map of flavor names to their corresponding dart define arguments
  void _generateVSCodeConfigurations(
      String target, Map<String, List<String>> dartDefines) {
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
            ${isFirebase ? '"preLaunchTask": "build-${e.key.paramCase}",' : ""}
            "program": "$target",
            "args": [
                ${e.value.join(',\n\t\t\t\t')}
            ]
        },
        {
            "name": "${projectName.titleCase} Profile ${e.key.titleCase}",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile",
            ${isFirebase ? '"preLaunchTask": "build-${e.key.paramCase}",' : ""}
            "program": "$target",
            "args": [
                ${e.value.join(',\n\t\t\t\t')}
            ]
        },
        {
            "name": "${projectName.titleCase} Release ${e.key.titleCase}",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release",
            ${isFirebase ? '"preLaunchTask": "build-${e.key.paramCase}",' : ""}
            "program": "$target",
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
            "command": "morpheme_lite firebase -f ${e.key}",
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
  }

  /// Generates Android Studio run configuration files.
  ///
  /// Creates XML configuration files in .idea/runConfigurations/ for each
  /// flavor and mode (Debug, Profile, Release). First deletes any existing
  /// configuration directory and creates a fresh one.
  ///
  /// [target] The path to the main Dart file (usually lib/main.dart)
  /// [dartDefines] A map of flavor names to their corresponding dart define arguments
  /// [projectName] The name of the project from morpheme.yaml
  void _generateAndroidStudioConfigurations(String target,
      Map<String, List<String>> dartDefines, String projectName) {
    // Create .idea/runConfigurations directory if needed
    final ideaDir = join(current, '.idea', 'runConfigurations');

    if (exists(ideaDir)) {
      deleteDir(ideaDir);
    }

    createDir(ideaDir, recursive: true);

    // First generate the pre-launch tasks (firebase configurations)
    for (final entry in dartDefines.entries) {
      final flavor = entry.key;
      _generateAndroidStudioFirebaseTask(flavor, projectName);
    }

    // Generate XML files for each flavor and mode
    final modes = ['Debug', 'Profile', 'Release'];
    for (final entry in dartDefines.entries) {
      final flavor = entry.key;
      final defines = entry.value;

      // Convert VS Code format to Android Studio format
      final androidDefines = _convertDartDefinesForAndroidStudio(defines);

      for (var mode in modes) {
        _generateAndroidStudioConfigFile(
            flavor, mode, androidDefines, target, projectName);
      }
    }
  }

  /// Generates a Firebase setup task for Android Studio.
  ///
  /// Creates an XML configuration file for the Firebase setup task
  /// that can be used as a pre-launch task.
  ///
  /// [flavor] The flavor name (e.g., 'dev', 'staging', 'prod')
  /// [projectName] The project name from morpheme.yaml
  void _generateAndroidStudioFirebaseTask(String flavor, String projectName) {
    final fileName = 'Firebase ${flavor.titleCase}.run.xml';
    final filePath = join(current, '.idea', 'runConfigurations', fileName);

    final xmlContent = '''<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="${projectName.titleCase} Firebase ${flavor.titleCase}" type="ShConfigurationType">
    <option name="SCRIPT_TEXT" value="morpheme firebase -f $flavor" />
    <option name="INDEPENDENT_SCRIPT_PATH" value="true" />
    <option name="SCRIPT_PATH" value="" />
    <option name="INDEPENDENT_SCRIPT_WORKING_DIRECTORY" value="true" />
    <option name="SCRIPT_WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="INDEPENDENT_INTERPRETER_PATH" value="true" />
    <option name="INTERPRETER_PATH" value="/bin/sh" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="EXECUTE_IN_TERMINAL" value="true" />
    <option name="EXECUTE_SCRIPT_FILE" value="false" />
    <envs />
    <method v="2" />
  </configuration>
</component>''';

    filePath.write(xmlContent);
    StatusHelper.generated(filePath);
  }

  /// Generates a single Android Studio run configuration XML file.
  ///
  /// Creates an XML file with the appropriate configuration for a specific
  /// flavor and mode combination.
  ///
  /// [flavor] The flavor name (e.g., 'dev', 'staging', 'prod')
  /// [mode] The Flutter mode ('Debug', 'Profile', or 'Release')
  /// [dartDefines] The dart define arguments formatted for Android Studio
  /// [target] The path to the main Dart file
  /// [projectName] The project name from morpheme.yaml
  void _generateAndroidStudioConfigFile(String flavor, String mode,
      String dartDefines, String target, String projectName) {
    // Generate individual XML configuration file
    final fileName = '$mode ${flavor.titleCase}.run.xml';
    final filePath = join(current, '.idea', 'runConfigurations', fileName);

    // Add pre-launch task that runs the Firebase configuration
    final xmlContent = '''<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="${projectName.titleCase} $mode ${flavor.titleCase}" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="additionalArgs" value="$dartDefines" />
    <option name="filePath" value="$target" />
    ${isFirebase ? '''<method v="2">
      <option name="RunConfigurationTask" enabled="true" run_configuration_name="${projectName.titleCase} Firebase ${flavor.titleCase}" />
    </method>''' : ''}
  </configuration>
</component>''';

    filePath.write(xmlContent);
    StatusHelper.generated(filePath);
  }

  /// Converts VS Code style dart defines to Android Studio format.
  ///
  /// Transforms the array format used in VS Code configurations to the
  /// space-separated string format required by Android Studio.
  ///
  /// Example:
  /// Input: ['"--dart-define"', '"FLAVOR=dev"', '"--dart-define"', '"APP_NAME=MyApp Dev"']
  /// Output: "--dart-define=FLAVOR=dev --dart-define=APP_NAME=MyApp Dev"
  ///
  /// [dartDefines] List of dart define arguments in VS Code format
  /// Returns: Space-separated string of dart define arguments for Android Studio
  String _convertDartDefinesForAndroidStudio(List<String> dartDefines) {
    // Convert from VS Code format to Android Studio format
    // From: ['"--dart-define"', '"FLAVOR=dev"', '"--dart-define"', '"APP_NAME=MyApp Dev"']
    // To: "--dart-define=FLAVOR=dev --dart-define=APP_NAME=MyApp Dev"

    final args = <String>[];
    for (int i = 0; i < dartDefines.length; i += 2) {
      if (i + 1 < dartDefines.length) {
        // Remove quotes and combine
        final flag = dartDefines[i].replaceAll('"', '');
        final value = dartDefines[i + 1].replaceAll('"', '');
        args.add('$flag=$value');
      }
    }
    return args.join(' ');
  }
}
