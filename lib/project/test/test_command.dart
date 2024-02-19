import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class TestCommand extends Command {
  TestCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Test with spesific feature',
    );
  }

  @override
  String get name => 'test';

  @override
  String get description =>
      'Run Flutter unit tests for the current project & all modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final String? feature = argResults?['feature'];

    if (feature != null && !feature.contains('/')) {
      String workingDirectory = join(current);
      switch (feature) {
        case 'core':
          workingDirectory = join(current, 'core');
          break;
        case 'assets':
          workingDirectory = join(current, 'assets');
          break;
        case 'asset':
          workingDirectory = join(current, 'assets');
          break;
        case 'main':
          workingDirectory = current;
          break;
        default:
          workingDirectory = join(current, 'features', feature);
      }
      FlutterHelper.start('test', workingDirectory: workingDirectory);
    } else if (feature != null && feature.contains('/')) {
      FlutterHelper.start('test', workingDirectory: feature);
    } else {
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();

      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

      await ModularHelper.test(concurrent: yaml.concurrent);
    }

    StatusHelper.success('morpheme test');
  }
}
