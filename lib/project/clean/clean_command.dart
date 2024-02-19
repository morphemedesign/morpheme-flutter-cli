import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/extensions/extensions.dart';
import 'package:morpheme/helper/helper.dart';

class CleanCommand extends Command {
  CleanCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'remove-lock',
      abbr: 'l',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'clean';

  @override
  String get description =>
      'Delete the l10n, build/ and .dart_tool/ in main, core & features directories.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final removeLock = argResults?['remove-lock'] ?? false;

    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final localizationHelper = LocalizationHelper(argMorphemeYaml);
    if (exists(join(current, localizationHelper.outputDir))) {
      deleteDir(join(current, localizationHelper.outputDir));
    }
    if (removeLock && exists(join(current, 'ios', 'Podfile.lock'))) {
      delete(join(current, 'ios', 'Podfile.lock'));
    }

    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    await ModularHelper.clean(
      concurrent: yaml.concurrent,
      removeLock: removeLock,
    );

    StatusHelper.success('morpheme clean');
  }
}
