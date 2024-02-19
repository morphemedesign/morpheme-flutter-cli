import 'package:morpheme/build_app/prebuild_ios/prebuild_ios_command.dart';
import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';

class PreBuildCommand extends Command {
  PreBuildCommand() {
    addSubcommand(PreBuildIosCommand());
  }

  @override
  String get name => 'prebuild';

  @override
  String get description => 'Prepare setup ios before build';

  @override
  String get category => Constants.build;
}
