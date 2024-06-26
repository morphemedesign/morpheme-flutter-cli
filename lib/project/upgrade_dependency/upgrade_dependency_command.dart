import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class UpgradeDependencyCommand extends Command {
  UpgradeDependencyCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Upgrade all project package\'s dependencies to latest versions...',
      negatable: false,
    );
    argParser.addFlag(
      'dependency',
      abbr: 'd',
      help:
          'Upgrade all dependency_manager package\'s dependencies to latest versions...',
      negatable: false,
    );
    argParser.addFlag(
      'morpheme',
      abbr: 'g',
      help:
          'Upgrade all morpheme_library package\'s dependencies to latest versions... (default)',
      negatable: false,
    );
  }

  @override
  String get name => 'upgrade-dependency';

  @override
  String get description =>
      'Upgrade the current package\'s dependencies to latest versions..';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    if (argResults?.wasParsed('all') ?? false) {
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();

      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

      await ModularHelper.upgrade(concurrent: yaml.concurrent);
      return;
    }
    var directory = 'morpheme_library';
    if (argResults?.wasParsed('dependency') ?? false) {
      directory = 'dependency_manager';
    }
    final path = join(current, 'core', 'packages', directory);
    if (!exists(path)) {
      StatusHelper.failed(
          'You don\'t have directory "$directory" in project, make sure to have "$directory" first');
    }
    await FlutterHelper.start('packages upgrade', workingDirectory: path);
    await FlutterHelper.start('packages get', workingDirectory: path);

    StatusHelper.success();
  }
}
