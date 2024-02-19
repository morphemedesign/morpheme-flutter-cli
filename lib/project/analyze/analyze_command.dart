import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class AnalyzeCommand extends Command {
  AnalyzeCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Analyze code in all packages.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    await ModularHelper.analyze(concurrent: yaml.concurrent);
    StatusHelper.success('morpheme analyze');
  }
}
