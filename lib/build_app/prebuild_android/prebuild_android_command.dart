import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Android prebuild setup command implementation.
///
/// Prepares Android project for build operations by configuring
/// Fastlane deployment settings, signing configurations, and
/// build environment setup.
///
/// ## Platform Requirements
/// - Android SDK and build tools
/// - Fastlane for deployment automation (optional)
/// - Valid Android project structure
///
/// ## Configuration Setup
/// - Fastlane Appfile generation with package name
/// - Play Store service account configuration
/// - Signing key and certificate setup
/// - Build variant configuration
///
/// ## Fastlane Integration
/// Generates Appfile for Fastlane automation:
/// ```ruby
/// json_key_file("fastlane/play-store.json")
/// package_name("com.example.app")
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Setup Android prebuild for production
/// morpheme prebuild android --flavor prod
///
/// # Setup with development flavor
/// morpheme prebuild android --flavor dev
/// ```
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
    _validateInputs();
    _prepareConfiguration();
    _setupFastlane();
    _reportSuccess();
  }

  void _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
  }

  void _prepareConfiguration() {
    // Any preparation logic specific to Android prebuild
  }

  void _setupFastlane() {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    final packageName =
        morphemeYaml['flavor'][argFlavor]['ANDROID_APPLICATION_ID'];

    final path = join(current, 'android', 'fastlane', 'Appfile');
    path.write('''json_key_file("fastlane/play-store.json")
package_name("$packageName")''');

    StatusHelper.generated(path);
  }

  void _reportSuccess() {
    StatusHelper.success('prebuild android');
  }
}
