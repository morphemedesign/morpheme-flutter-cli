import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class FormatCommand extends Command {
  FormatCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Dart format for spesific apps',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Dart format for spesific feature',
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Dart fix for spesific page',
    );
  }

  @override
  String get name => 'format';

  @override
  String get description => 'Format all files .dart.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final pathApps = join(current, 'apps', appsName);
    String featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    String pathFeature = join(current, 'features', featureName);
    if (appsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', featureName);
    }
    final pageName = (argResults?['page-name'] as String? ?? '').snakeCase;
    String pathPage = join(pathFeature, 'lib', pageName);

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed(
          'Apps with "$appsName" does not exists, create a new apps with "morpheme apps <apps-name>"');
    }

    if (featureName.isNotEmpty && !exists(pathFeature)) {
      StatusHelper.failed(
          'Feature with "$featureName" does not exists, create a new feature with "morpheme feature <feature-name>"');
    }

    if (pageName.isNotEmpty && !exists(pathPage)) {
      StatusHelper.failed(
          'Page with "$pageName" does not exists, create a new page with "morpheme page <apage-name> -f <feature-name>"');
    }

    final pathToFormat = [
      if (appsName.isNotEmpty && featureName.isNotEmpty && pageName.isNotEmpty)
        pathPage
      else if (appsName.isNotEmpty && featureName.isNotEmpty)
        pathFeature
      else if (appsName.isNotEmpty)
        pathApps
    ];

    await ModularHelper.format(pathToFormat);

    StatusHelper.success('morpheme format');
  }
}
