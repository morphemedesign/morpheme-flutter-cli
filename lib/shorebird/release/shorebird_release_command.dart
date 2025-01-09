import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/shorebird/release/src/release_apk_command.dart';
import 'package:morpheme_cli/shorebird/release/src/release_appbundle_command.dart';
import 'package:morpheme_cli/shorebird/release/src/release_ios_command.dart';
import 'package:morpheme_cli/shorebird/release/src/release_ipa_command.dart';

class ShorebirdReleaseCommand extends Command {
  ShorebirdReleaseCommand() {
    addSubcommand(ReleaseApkCommand());
    addSubcommand(ReleaseAppbundleCommand());
    addSubcommand(ReleaseIosCommand());
    addSubcommand(ReleaseIpaCommand());
  }

  @override
  String get name => 'release';

  @override
  String get description =>
      'Creates a shorebird release for the provided target platforms';
}
