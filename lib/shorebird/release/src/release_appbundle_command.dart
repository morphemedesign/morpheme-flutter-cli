import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/helper/shorebird_helper.dart';

class ReleaseAppbundleCommand extends Command {
  ReleaseAppbundleCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  @override
  String get name => 'appbundle';

  @override
  String get description => 'Shorebird release android aab with flavor.';

  @override
  void run() async {
    CucumberHelper.removeNdjsonGherkin();
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    final argObfuscate = argResults.getFlagObfuscate();
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
        'shorebird release android --artifact aab -t $argTarget ${dartDefines.join(' ')} $argBuildNumber $argBuildName $argSplitDebugInfo $argFlutterVersion --no-confirm -- $argObfuscate';
    printMessage(command);

    await command.run;

    StatusHelper.success('shorebird release appbundle');
  }
}
