import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/shorebird/patch/src/patch_android_command.dart';
import 'package:morpheme_cli/shorebird/patch/src/patch_ios_command.dart';

class ShorebirdPatchCommand extends Command {
  ShorebirdPatchCommand() {
    addSubcommand(PatchAndroidCommand());
    addSubcommand(PatchIosCommand());
  }

  @override
  String get name => 'patch';

  @override
  String get description =>
      'Creates a shorebird patch for the provided target platforms';
}
