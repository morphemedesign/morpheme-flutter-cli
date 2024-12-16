import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class CoreCommand extends Command {
  @override
  String get name => 'core';

  @override
  String get description => 'Create a new core packages module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Core package name is empty, add a new core package with "morpheme core <package-name>"');
    }

    final packageName = argResults?.rest.first ?? '';
    await addNewFeature(packageName);
    addNewFeatureInPubspec(packageName);
    addNewFeatureInPubspecRoot(packageName);
    addNewGitIgnore(packageName);
    addNewAnalysisOption(packageName);

    StatusHelper.success('generate package $packageName in core');
  }

  Future<void> addNewFeature(String packageName) async {
    final pathPackages =
        join(current, 'core', 'packages', packageName.snakeCase);

    await FlutterHelper.run(
        'create --template=package "core/packages/${packageName.snakeCase}"');

    join(pathPackages, 'pubspec.yaml').write('''name: $packageName
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

dev_dependencies:
  dev_dependency_manager:
    path: ../dev_dependency_manager

flutter:''');

    deleteDir(join(pathPackages, 'lib'), recursive: true);
    deleteDir(join(pathPackages, 'test'), recursive: true);

    createDir(join(pathPackages, 'lib'), recursive: true);
    createDir(join(pathPackages, 'test'), recursive: true);

    touch(join(pathPackages, 'lib', '.gitkeep'), create: true);
    touch(join(pathPackages, 'test', '.gitkeep'), create: true);

    for (var element in [
      join(pathPackages, 'android'),
      join(pathPackages, 'ios'),
      join(pathPackages, 'web'),
      join(pathPackages, 'macos'),
      join(pathPackages, 'linux'),
      join(pathPackages, 'windows'),
    ]) {
      if (exists(element)) {
        deleteDir(element);
      }
    }

    StatusHelper.generated(pathPackages);
  }

  void addNewFeatureInPubspec(String packageName) {
    String pubspec =
        File(join(current, 'core', 'pubspec.yaml')).readAsStringSync();
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dev_dependencies)', multiLine: true),
      '''  ${packageName.snakeCase}:
    path: ./packages/${packageName.snakeCase}

dev_dependencies''',
    );
    join(current, 'core', 'pubspec.yaml').write(pubspec);

    StatusHelper.generated(join(current, 'core', 'pubspec.yaml'));
  }

  void addNewFeatureInPubspecRoot(String packageName) {
    String pubspec = File(join(current, 'pubspec.yaml')).readAsStringSync();
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dependencies)', multiLine: true),
      '''  - core/packages/${packageName.snakeCase}

dependencies''',
    );
    join(current, 'pubspec.yaml').write(pubspec);

    StatusHelper.generated(join(current, 'pubspec.yaml'));
  }

  void addNewGitIgnore(String packageName) {
    final path =
        join(current, 'core', 'packages', packageName.snakeCase, '.gitignore');
    if (exists(path)) {
      String gitignore = readFile(path);
      gitignore = gitignore.replaceAll('/pubspec.lock', '');
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
**/doc/api/
.dart_tool/
.packages
build/

coverage/
test/coverage_helper_test.dart
''');
    }
  }

  void addNewAnalysisOption(String packageName) {
    final path = join(current, 'core', 'packages', packageName.snakeCase,
        'analysis_options.yaml');
    path.write('''include: package:dev_dependency_manager/flutter.yaml
    
# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''');
  }
}
