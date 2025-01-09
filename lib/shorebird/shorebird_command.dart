import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/shorebird/patch/shorebird_patch_command.dart';
import 'package:morpheme_cli/shorebird/release/shorebird_release_command.dart';

class ShorebirdCommand extends Command {
  ShorebirdCommand() {
    addSubcommand(ShorebirdReleaseCommand());
    addSubcommand(ShorebirdPatchCommand());
  }

  @override
  String get name => 'shorebird';

  @override
  String get description =>
      'Shorebird Code Push is a tool that allows you to update your Flutter app instantly over the air, without going through the store update process.';

  @override
  String get category => Constants.shorebird;
}
