import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';

class RemoveTestCommand extends Command {
  RemoveTestCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Test with spesific apps (Optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Test with spesific feature (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Test with spesific page (optional)',
    );
  }

  @override
  String get name => 'remove-test';

  @override
  String get description => 'Remove code helper test in spesific feature.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    final String? apps = argResults?['apps-name']?.toString().snakeCase;
    final String? feature = argResults?['feature']?.toString().snakeCase;
    final String? page = argResults?['page']?.toString().snakeCase;

    final pathApps = join(current, 'apps', '${apps}_test');
    final pathFeature = apps?.isEmpty ?? true
        ? join(current, 'features', '$feature', 'test')
        : join(pathApps, 'features', '$feature', 'test');
    final pathPage = join(pathFeature, '${page}_test');

    String path = current;
    if (page != null) {
      deleteAllTestHelper(pathPage);
    } else if (feature != null) {
      deleteAllTestHelper(pathFeature);
    } else if (apps != null) {
      deleteAllTestHelper(pathApps);
    } else {
      deleteAllTestHelper(path);
    }

    StatusHelper.success('Remove test success');
  }

  void deleteAllTestHelper(String? dir) {
    final files = find(
      'bundle_test.dart',
      workingDirectory: dir ?? current,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (var i = 0; i < files.length; i++) {
      delete(files[i]);
    }

    final fileCoverages = find(
      'coverage_helper_test.dart',
      workingDirectory: dir ?? current,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (var i = 0; i < fileCoverages.length; i++) {
      delete(fileCoverages[i]);
    }
  }
}
