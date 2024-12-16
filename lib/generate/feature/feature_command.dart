import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/read_json_file.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

class FeatureCommand extends Command {
  FeatureCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Create a new feature module in apps.',
    );
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Create a new feature module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Feature name is empty, add a new feature with "morpheme feature <feature-name>"');
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    String featureName = (argResults?.rest.first ?? '').snakeCase;
    if (appsName.isNotEmpty && !RegExp('^${appsName}_').hasMatch(featureName)) {
      featureName = '${appsName}_$featureName';
    }
    final pathApps = join(current, 'apps', appsName);

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed(
          'Apps with "$appsName" does not exists, create a new apps with "morpheme apps <apps-name>"');
    }

    String pathFeature = join(current, 'features', featureName);
    if (appsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', featureName);
    }

    if (exists(pathFeature)) {
      StatusHelper.failed('Feature already exists in $pathFeature.');
    }

    await addNewFeature(pathFeature, featureName, appsName);
    addNewFeatureInLocator(pathFeature, featureName, appsName);
    addNewFeatureInPubspec(pathFeature, featureName, appsName);
    addNewGitIgnore(pathFeature, featureName, appsName);
    addNewAnalysisOption(pathFeature, featureName, appsName);

    removeUnusedDir(pathFeature, featureName, appsName);

    await ModularHelper.format([
      pathFeature,
      join(current, 'lib'),
      if (appsName.isEmpty) '.',
      if (appsName.isNotEmpty) pathApps,
    ]);

    await FlutterHelper.start('pub get', workingDirectory: pathFeature);
    await FlutterHelper.start('pub get',
        workingDirectory: appsName.isEmpty ? '.' : pathApps);

    StatusHelper.success('generate feature $featureName');
  }

  Future<void> addNewFeature(
      String pathFeature, String featureName, String appsName) async {
    await FlutterHelper.run('create --template=package "$pathFeature"');

    join(pathFeature, 'pubspec.yaml').write('''name: $featureName
description: A new Flutter package project.
version: 0.0.1

publish_to: "none"

environment:
  sdk: "^3.6.0"
  flutter: "^3.27.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter

  core:
    path: ${appsName.isEmpty ? "../../core" : "../../../../core"}

dev_dependencies:
  dev_dependency_manager:
    path: ${appsName.isEmpty ? "../../core/packages/dev_dependency_manager" : "../../../../core/packages/dev_dependency_manager"}

flutter:
  uses-material-design: true
''');

    deleteDir(join(pathFeature, 'lib'), recursive: true);
    deleteDir(join(pathFeature, 'test'), recursive: true);

    createDir(join(pathFeature, 'lib'), recursive: true);
    createDir(join(pathFeature, 'test'), recursive: true);

    touch(join(pathFeature, 'test', '.gitkeep'), create: true);

    join(pathFeature, 'lib', 'locator.dart').write('''//
// Generated file. Edit just you manually add or delete a page.
//

void setupLocatorFeature${featureName.pascalCase}() {

}''');

    StatusHelper.generated(pathFeature);
    StatusHelper.generated(join(pathFeature, 'lib', 'locator.dart'));
  }

  void addNewFeatureInLocator(
      String pathFeature, String featureName, String appsName) {
    String pathLocator = join(current, 'lib', 'locator.dart');
    if (appsName.isNotEmpty) {
      pathLocator = join(current, 'apps', appsName, 'lib', 'locator.dart');
    }

    if (!exists(pathLocator)) {
      return;
    }

    String locator = File(pathLocator).readAsStringSync();

    if (RegExp(r'(^(\s+)?void setup)', multiLine: true).hasMatch(locator)) {
      locator = locator.replaceAll(
        RegExp(r'(^(\s+)?void setup)', multiLine: true),
        '''import 'package:$featureName/locator.dart';

void setup''',
      );
    } else if (RegExp(r'(^(\s+)?Future<void> setup)', multiLine: true)
        .hasMatch(locator)) {
      locator = locator.replaceAll(
        RegExp(r'(^(\s+)?Future<void> setup)', multiLine: true),
        '''import 'package:$featureName/locator.dart';

Future<void> setup''',
      );
    }

    locator = locator.replaceAll(
      '}',
      '''  setupLocatorFeature${featureName.pascalCase}();
}''',
    );
    pathLocator.write(locator);

    StatusHelper.generated(pathLocator);
  }

  void addNewFeatureInPubspec(
      String pathFeature, String featureName, String appsName) {
    String pathPubspec = join(current, 'pubspec.yaml');
    if (appsName.isNotEmpty) {
      pathPubspec = join(current, 'apps', appsName, 'pubspec.yaml');
    }
    if (!exists(pathPubspec)) {
      return;
    }
    String pubspec = File(pathPubspec).readAsStringSync();
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dependencies)', multiLine: true),
      '''  - features/$featureName

dependencies''',
    );
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dev_dependencies)', multiLine: true),
      '''  $featureName:
    path: ./features/$featureName

dev_dependencies''',
    );
    pathPubspec.write(pubspec);

    StatusHelper.generated(pathPubspec);
  }

  void addNewGitIgnore(
      String pathFeature, String featureName, String appsName) {
    final pathIgnore = join(pathFeature, '.gitignore');
    if (exists(pathIgnore)) {
      String gitignore = readFile(pathIgnore);
      gitignore = '''$gitignore
coverage/
test/coverage_helper_test.dart''';

      pathIgnore.write(gitignore);
    } else {
      pathIgnore.write('''# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
# Libraries should not include pubspec.lock, per https://dart.dev/guides/libraries/private-files#pubspeclock.
/pubspec.lock
**/doc/api/
.dart_tool/
.packages
build/

coverage/
test/coverage_helper_test.dart
''');
    }
  }

  void addNewAnalysisOption(
      String pathFeature, String featureName, String appsName) {
    final path = join(pathFeature, 'analysis_options.yaml');
    path.write('''include: package:dev_dependency_manager/flutter.yaml
    
# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''');
  }

  void removeUnusedDir(
      String pathFeature, String featureName, String appsName) {
    for (var element in [
      join(pathFeature, 'android'),
      join(pathFeature, 'ios'),
      join(pathFeature, 'web'),
      join(pathFeature, 'macos'),
      join(pathFeature, 'linux'),
      join(pathFeature, 'windows'),
    ]) {
      if (exists(element)) {
        deleteDir(element);
      }
    }
  }
}
