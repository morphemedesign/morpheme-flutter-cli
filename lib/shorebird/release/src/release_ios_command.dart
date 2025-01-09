import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/helper/shorebird_helper.dart';

class ReleaseIosCommand extends Command {
  ReleaseIosCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagCodesign();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  @override
  String get name => 'ios';

  @override
  String get description =>
      'Shorebird an iOS application bundle (Mac OS X host only).';

  @override
  void run() async {
    CucumberHelper.removeNdjsonGherkin();
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    final argCodesign = argResults.getFlagCodesign();
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
        'shorebird release ios -t $argTarget ${dartDefines.join(' ')} $argBuildNumber $argBuildName $argCodesign $argSplitDebugInfo $argFlutterVersion --no-confirm';
    printMessage(command);

    await command.run;

    StatusHelper.success('shorebird release ios');
  }
}
