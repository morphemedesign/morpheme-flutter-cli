import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/read_json_file.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

class AppsCommand extends Command {
  @override
  String get name => 'apps';

  @override
  String get description => 'Create a new apps module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Apps name is empty, add a new apps with "morpheme apps <apps-name>"');
    }

    final appsName = (argResults?.rest.first ?? '').snakeCase;

    if (exists(join(current, 'apps', appsName))) {
      StatusHelper.failed('Apps already exists.');
    }

    final pathApp = join(current, 'apps', appsName);

    addNewApps(pathApp, appsName);
    addNewAppsInLocator(pathApp, appsName);
    addNewAppsInPubspec(pathApp, appsName);
    addNewGitIgnore(pathApp, appsName);

    removeUnusedDir(pathApp, appsName);

    await ModularHelper.format([pathApp, '.']);

    FlutterHelper.start('pub get', workingDirectory: pathApp);
    FlutterHelper.run('pub get');

    StatusHelper.success('generate apps $appsName');
  }

  void addNewApps(String pathApps, String appsName) {
    FlutterHelper.run('create --template=package "$pathApps"');

    join(pathApps, 'pubspec.yaml').write('''name: $appsName
description: A new Flutter package project.
version: 0.0.1

publish_to: "none"

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  core:
    path: ../../core

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
''');

    deleteDir(join(pathApps, 'lib'), recursive: true);
    deleteDir(join(pathApps, 'test'), recursive: true);

    createDir(join(pathApps, 'lib'), recursive: true);
    createDir(join(pathApps, 'test'), recursive: true);

    touch(join(pathApps, 'test', '.gitkeep'), create: true);

    join(pathApps, 'lib', 'locator.dart').write('''//
// Generated file. Edit just you manually add or delete a page.
//

void setupLocatorApps${appsName.pascalCase}() {

}''');

    StatusHelper.generated(pathApps);
    StatusHelper.generated(join(pathApps, 'lib', 'locator.dart'));
  }

  void addNewAppsInLocator(String pathApps, String appsName) {
    if (!exists(join(current, 'lib', 'locator.dart'))) {
      return;
    }
    String locator =
        File(join(current, 'lib', 'locator.dart')).readAsStringSync();

    locator = locator.replaceAll(
      RegExp(r'(^(\s+)?void setup)', multiLine: true),
      '''import 'package:$appsName/locator.dart';

void setup''',
    );
    locator = locator.replaceAll(
      '}',
      '''  setupLocatorApps${appsName.pascalCase}();
}''',
    );
    join(current, 'lib', 'locator.dart').write(locator);

    StatusHelper.generated(join(current, 'lib', 'locator.dart'));
  }

  void addNewAppsInPubspec(String pathApps, String appsName) {
    if (!exists(join(current, 'pubspec.yaml'))) {
      return;
    }
    String pubspec = File(join(current, 'pubspec.yaml')).readAsStringSync();
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dev_dependencies)', multiLine: true),
      '''  $appsName:
    path: ./apps/$appsName

dev_dependencies''',
    );
    join(current, 'pubspec.yaml').write(pubspec);

    StatusHelper.generated(join(current, 'pubspec.yaml'));
  }

  void addNewGitIgnore(String pathApps, String appsName) {
    final path = join(pathApps, '.gitignore');
    if (exists(path)) {
      String gitignore = readFile(path);
      gitignore = '''$gitignore
coverage/
test/coverage_helper_test.dart''';

      path.write(gitignore);
    } else {
      path.write('''# Miscellaneous
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

  void removeUnusedDir(String pathApps, String appsName) {
    for (var element in [
      join(pathApps, 'android'),
      join(pathApps, 'ios'),
      join(pathApps, 'web'),
      join(pathApps, 'macos'),
      join(pathApps, 'linux'),
      join(pathApps, 'windows'),
    ]) {
      if (exists(element)) {
        deleteDir(element);
      }
    }
  }
}
