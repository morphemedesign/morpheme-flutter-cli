import 'dart:io';

import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';

import '../../helper/helper.dart';

class RemoveFeatureCommand extends Command {
  RemoveFeatureCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the apps to be remove feature',
    );
  }
  @override
  String get name => 'remove-feature';

  @override
  String get description => 'Remove code feature.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed('Feature name is empty');
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final featureName = (argResults?.rest.first ?? '').snakeCase;
    final pathApps = join(current, 'apps', appsName);

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed('Apps with "$appsName" does not exists"');
    }

    String pathFeature = join(current, 'features', featureName);
    if (appsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', featureName);
    }

    if (!exists(pathFeature)) {
      StatusHelper.failed('Feature with "$featureName" does not exists"');
    }

    if (exists(pathFeature)) {
      deleteDir(pathFeature);
    }

    final workingDir = appsName.isEmpty ? current : pathApps;

    final pathLibLocator = join(workingDir, 'lib', 'locator.dart');
    String data = File(pathLibLocator).readAsStringSync();

    data = data.replaceAll(
        "import 'package:${featureName.snakeCase}/locator.dart';", '');
    data =
        data.replaceAll("setupLocatorFeature${featureName.pascalCase}();", '');

    pathLibLocator.write(data);

    final pathPubspec = join(workingDir, 'pubspec.yaml');
    String pubspec = File(pathPubspec).readAsStringSync();

    pubspec = pubspec.replaceAll(
      RegExp(
          "\\s+${featureName.snakeCase}:\\s+path: ./features/${featureName.snakeCase}"),
      '',
    );

    pathPubspec.write(pubspec);

    await ModularHelper.format([
      if (appsName.isEmpty) '.',
      if (appsName.isNotEmpty) pathApps,
    ]);

    StatusHelper.success('removed feature $featureName');
  }
}
