import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

class WebCommand extends BuildCommandBase {
  WebCommand() : super() {
    argParser.addOptionBaseHref();
    argParser.addOptionPwaStrategy();
    argParser.addOptionWebRenderer();
    argParser.addFlagWebResourcesCdn();
    argParser.addFlagCsp();
    argParser.addFlagSourceMaps();
    argParser.addOptionDart2JsOptimization();
    argParser.addFlagDumpInfo();
    argParser.addFlagFrequencyBasedMinification();
  }

  @override
  String get name => 'web';

  @override
  String get description => 'Build a web application bundle with flavor.';

  @override
  String get buildTarget => 'web';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argBaseHref = argResults.getOptionBaseHref();
    final argPwaStrategy = argResults.getOptionPwaStrategy();
    final argWebRenderer = argResults.getOptionWebRenderer();
    final argWebResourcesCdn = argResults.getFlagWebResourcesCdn();
    final argCsp = argResults.getFlagCsp();
    final argSourcesMap = argResults.getFlagSourceMaps();
    final argDart2JsOptimization = argResults.getOptionDart2JsOptimization();
    final argDumpInfo = argResults.getFlagDumpInfo();
    final argFrequencyBasedMinification = argResults.getFlagFrequencyBasedMinification();
    
    return '$baseCommand $argBaseHref $argPwaStrategy $argWebRenderer '
           '$argWebResourcesCdn $argCsp $argSourcesMap $argDart2JsOptimization '
           '$argDumpInfo $argFrequencyBasedMinification';
  }
}