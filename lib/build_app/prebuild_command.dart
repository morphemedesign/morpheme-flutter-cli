import 'package:morpheme_cli/build_app/prebuild_android/prebuild_android_command.dart';
import 'package:morpheme_cli/build_app/prebuild_ios/prebuild_ios_command.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

class PreBuildCommand extends Command {
  PreBuildCommand() {
    addSubcommand(PreBuildAndroidCommand());
    addSubcommand(PreBuildIosCommand());
  }

  @override
  String get name => 'prebuild';

  @override
  String get description => 'Prepare setup before build';

  @override
  String get category => Constants.build;
}