import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class RunCommand extends Command {
  RunCommand() {
    argParser.addFlagDebug(defaultsTo: true);
    argParser.addFlagProfile();
    argParser.addFlagRelease(defaultsTo: false);

    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addFlagGenerateL10n();
    argParser.addOptionDeviceId();
  }

  @override
  String get name => 'run';

  @override
  String get description =>
      'Run your Flutter app on an attached device with flavor.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    CucumberHelper.removeNdjsonGherkin();
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    final deviceId = argResults.getDeviceId();

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
    String mode = argResults.getMode();

    await FlutterHelper.run(
      'run -t $argTarget ${dartDefines.join(' ')} $mode $deviceId',
      showLog: true,
    );

    StatusHelper.success('run');
  }
}
