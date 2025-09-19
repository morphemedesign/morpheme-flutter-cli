import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

class IosCommand extends BuildCommandBase {
  IosCommand() : super() {
    argParser.addFlagCodesign();
  }

  @override
  String get name => 'ios';

  @override
  String get description => 'Build an iOS application bundle (Mac OS X host only).';

  @override
  String get buildTarget => 'ios';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argCodesign = argResults.getFlagCodesign();
    return '$baseCommand $argCodesign';
  }
}