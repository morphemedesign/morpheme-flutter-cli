import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

class IpaCommand extends BuildCommandBase {
  IpaCommand() : super() {
    argParser.addOptionExportMethod();
    argParser.addOptionExportOptionsPlist();
  }

  @override
  String get name => 'ipa';

  @override
  String get description => 'Archive ios ipa with flavor.';

  @override
  String get buildTarget => 'ipa';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argExportMethod = argResults.getOptionExportMethod();
    final argExportOptionsPlist = argResults.getOptionExportOptionsPlist();
    return '$baseCommand $argExportMethod $argExportOptionsPlist';
  }
}