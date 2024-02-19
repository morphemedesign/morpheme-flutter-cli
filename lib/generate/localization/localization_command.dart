import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/extensions/extensions.dart';
import 'package:morpheme/helper/arb_helper.dart';
import 'package:morpheme/helper/helper.dart';

class LocalizationCommand extends Command {
  LocalizationCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'l10n';

  @override
  String get description => 'Generate localizations for the current project.';

  @override
  String get category => Constants.generate;

  @override
  void run() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final morphemeYamlHelper = LocalizationHelper(argMorphemeYaml);

    final dir = find(
      '*',
      recursive: false,
      workingDirectory: morphemeYamlHelper.arbDir,
      types: [Find.directory],
    );

    dir.forEach((pathDir) {
      final dirName = pathDir.split(separator).last;
      final pathArbDefault = join(morphemeYamlHelper.arbDir, '$dirName.arb');

      final filesArb = find(
        '*.arb',
        workingDirectory: pathDir,
        recursive: true,
        types: [Find.file],
      );

      String merged = '{"@@locale": "$dirName"}';

      if (morphemeYamlHelper.replace && exists(pathArbDefault)) {
        merged = readFile(pathArbDefault);
      }

      filesArb.forEach((pathArb) {
        final arb = readFile(pathArb);
        final sorted = sortARB(arb);
        pathArb.write(sorted);

        merged = mergeARBs(merged, sorted);
      });

      pathArbDefault.write(merged);
    });

    FlutterHelper.run(
        'gen-l10n --arb-dir="${morphemeYamlHelper.arbDir}" --template-arb-file="${morphemeYamlHelper.templateArbFile}" --output-localization-file="${morphemeYamlHelper.outputLocalizationFile}" --output-class="${morphemeYamlHelper.outputClass}" --output-dir="${morphemeYamlHelper.outputDir}" --no-synthetic-package');

    StatusHelper.success('generate l10n to ${morphemeYamlHelper.outputDir}');
  }
}
