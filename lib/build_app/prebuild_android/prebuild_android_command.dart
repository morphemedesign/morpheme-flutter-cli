import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class PreBuildAndroidCommand extends Command {
  PreBuildAndroidCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'android';

  @override
  String get description => 'Prepare setup android before build';

  @override
  void run() async {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    final packageName =
        morphemeYaml['flavor'][argFlavor]['ANDROID_APPLICATION_ID'];

    setupFastlane(packageName);

    StatusHelper.success('prebuild android');
  }

  void setupFastlane(String packageName) {
    final path = join(current, 'android', 'fastlane', 'Appfile');
    path.write('''json_key_file("fastlane/play-store.json")
package_name("$packageName")''');

    StatusHelper.generated(path);
  }
}
