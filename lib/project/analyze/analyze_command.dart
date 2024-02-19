import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/extensions/extensions.dart';
import 'package:morpheme/helper/helper.dart';

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
