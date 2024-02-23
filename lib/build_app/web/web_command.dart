import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/cucumber_helper.dart';
import 'package:morpheme_cli/helper/helper.dart';

class WebCommand extends Command {
  WebCommand() {
    argParser.addFlagDebug();
    argParser.addFlagProfile();
    argParser.addFlagRelease();

    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagGenerateL10n();
    argParser.addOptionBaseHref();
    argParser.addOptionPwaStrategy();
    argParser.addOptionWebRenderer();
    argParser.addFlagWebResourcesCdn();
    argParser.addFlagCsp();
    argParser.addFlagSourceMaps();
    argParser.addOptionDart2JsOptimization();
    argParser.addFlagDumpInfo();
    argParser.addFlagFrequencyBasedMinification();
  }

  @override
  String get name => 'web';

  @override
  String get description => 'Build a web application bundle with flavor.';

  @override
  void run() async {
    CucumberHelper.removeNdjsonGherkin();
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    final argBaseHref = argResults.getOptionBaseHref();
    final argPwaStrategy = argResults.getOptionPwaStrategy();
    final argWebRenderer = argResults.getOptionWebRenderer();
    final argWebResourcesCdn = argResults.getFlagWebResourcesCdn();
    final argCsp = argResults.getFlagCsp();
    final argSourcesMap = argResults.getFlagSourceMaps();
    final argDart2JsOptimization = argResults.getOptionDart2JsOptimization();
    final argDumpInfo = argResults.getFlagDumpInfo();
    final argFrequencyBasedMinification =
        argResults.getFlagFrequencyBasedMinification();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    if (argGenerateL10n) {
      await 'morpheme l10n --morpheme-yaml "$argMorphemeYaml"'.run;
    }

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);

    FirebaseHelper.run(argFlavor, argMorphemeYaml);

    List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });
    final mode = argResults.getMode();

    await FlutterHelper.run(
      'build web -t $argTarget ${dartDefines.join(' ')} $mode $argBuildNumber $argBuildName $argBaseHref $argPwaStrategy $argWebRenderer $argWebResourcesCdn $argCsp $argSourcesMap $argDart2JsOptimization $argDumpInfo $argFrequencyBasedMinification',
      showLog: true,
    );

    StatusHelper.success('build web');
  }
}
