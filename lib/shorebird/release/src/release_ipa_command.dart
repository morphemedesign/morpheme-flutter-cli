import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/helper/shorebird_helper.dart';

class ReleaseIpaCommand extends Command {
  ReleaseIpaCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionExportMethod();
    argParser.addOptionExportOptionsPlist();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  @override
  String get name => 'ipa';

  @override
  String get description => 'Shorebird ios ipa with flavor.';

  @override
  void run() async {
    CucumberHelper.removeNdjsonGherkin();
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argExportMethod = argResults.getOptionExportMethod();
    final argExportOptionsPlist = argResults.getOptionExportOptionsPlist();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    // final argObfuscate = argResults.getFlagObfuscate(); // TODO: used when the shorebird command supports obfuscation
    final argSplitDebugInfo = argResults.getOptionSplitDebugInfo();
    final argGenerateL10n = argResults.getFlagGenerateL10n();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    if (argGenerateL10n) {
      await 'morpheme l10n --morpheme-yaml "$argMorphemeYaml"'.run;
    }

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);

    FirebaseHelper.run(argFlavor, argMorphemeYaml);

    final shorebird = ShorebirdHelper.byFlavor(argFlavor, argMorphemeYaml);
    final argFlutterVersion = shorebird.$1?.isEmpty ?? true
        ? ''
        : '--flutter-version ${shorebird.$1}';
    ShorebirdHelper.writeShorebirdYaml(shorebird.$2);

    List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });

    final command =
        'shorebird release ios -t $argTarget ${dartDefines.join(' ')} $argExportMethod $argExportOptionsPlist $argBuildNumber $argBuildName $argSplitDebugInfo $argFlutterVersion --no-confirm';
    printMessage(command);

    await command.run;

    StatusHelper.success('shorebird release ipa');
  }
}
