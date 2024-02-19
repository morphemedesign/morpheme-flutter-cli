import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/extensions/extensions.dart';
import 'package:morpheme/helper/helper.dart';

class GetCommand extends Command {
  GetCommand() {
    argParser.addOptionMorphemeYaml();
  }
  @override
  String get name => 'get';

  @override
  String get description =>
      'Get packages in a Flutter project, Core & Features.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    'morpheme l10n --morpheme-yaml "$argMorphemeYaml"'.run;

    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    await ModularHelper.get(concurrent: yaml.concurrent);
    StatusHelper.success('morpheme get');
  }
}
