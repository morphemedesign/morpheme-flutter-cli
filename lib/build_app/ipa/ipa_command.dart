import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/extensions/extensions.dart';
import 'package:morpheme/helper/cucumber_helper.dart';
import 'package:morpheme/helper/helper.dart';

class IpaCommand extends Command {
  IpaCommand() {
    argParser.addFlagDebug();
    argParser.addFlagProfile();
    argParser.addFlagRelease();

    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionExportMethod();
    argParser.addOptionExportOptionsPlist();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
  }

  @override
  String get name => 'ipa';

  @override
  String get description => 'Archive ios ipa with flavor.';

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
    final argObfuscate = argResults.getFlagObfuscate();
    final argSplitDebugInfo = argResults.getOptionSplitDebugInfo();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    'morpheme l10n --morpheme-yaml "$argMorphemeYaml"'.run;

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);

    FirebaseHelper.run(argFlavor, argMorphemeYaml);

    List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });
    final mode = argResults.getMode();

    FlutterHelper.run(
      'build ipa -t $argTarget ${dartDefines.join(' ')} $mode $argExportMethod $argExportOptionsPlist $argBuildNumber $argBuildName $argObfuscate $argSplitDebugInfo',
      showLog: true,
    );

    StatusHelper.success('build ipa');
  }
}
