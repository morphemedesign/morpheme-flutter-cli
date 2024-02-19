import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';

class RemoveAppsCommand extends Command {
  @override
  String get name => 'remove-apps';

  @override
  String get description => 'Remove code apps.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed('Apps name is empty');
    }

    final appsName = (argResults?.rest.first ?? '').snakeCase;

    final pathApps = join(current, 'apps', appsName);

    if (!exists(pathApps)) {
      StatusHelper.failed('Apps with "$appsName" does not exists"');
    }

    if (exists(pathApps)) {
      deleteDir(pathApps);
    }

    final pathLibLocator = join(current, 'lib', 'locator.dart');
    String data = File(pathLibLocator).readAsStringSync();

    data = data.replaceAll(
        "import 'package:${appsName.snakeCase}/locator.dart';", '');
    data = data.replaceAll("setupLocatorApps${appsName.pascalCase}();", '');

    pathLibLocator.write(data);

    final pathPubspec = join(current, 'pubspec.yaml');
    String pubspec = File(pathPubspec).readAsStringSync();

    pubspec = pubspec.replaceAll(
      RegExp(
          "\\s+${appsName.snakeCase}:\\s+path: ./apps/${appsName.snakeCase}"),
      '',
    );

    pathPubspec.write(pubspec);

    '${FlutterHelper.getCommandDart()} format .'.run;

    StatusHelper.success('removed apps $appsName');
  }
}
