import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';

class RemovePageCommand extends Command {
  RemovePageCommand() {
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature to be remove page',
      mandatory: true,
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the apps to be remove page',
    );
  }

  @override
  String get name => 'remove-page';

  @override
  String get description => 'Remove code page in spesific feature.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed('Page name is empty');
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
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

    final pageName = (argResults?.rest.first ?? '').snakeCase;
    final pathPage = join(pathFeature, 'lib', pageName);

    if (!exists(pathPage)) {
      StatusHelper.failed(
          'Page with "$pageName" does not exists in feature $featureName"');
    }

    final pathTest = join(pathFeature, 'test', '${pageName}_test');

    if (exists(pathPage)) {
      deleteDir(pathPage);
    }

    if (exists(pathTest)) {
      deleteDir(pathTest);
    }

    final pathFeatureLocator = join(pathFeature, 'lib', 'locator.dart');
    String data = File(pathFeatureLocator).readAsStringSync();

    data = data.replaceAll("import '${pageName.snakeCase}/locator.dart';", '');
    data = data.replaceAll("setupLocator${pageName.pascalCase}();", '');

    pathFeatureLocator.write(data);

    await ModularHelper.format([pathFeature]);

    StatusHelper.success('removed page $pageName in feature $featureName');
  }
}
