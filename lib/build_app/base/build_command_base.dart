import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Abstract base class for all build commands.
///
/// This class encapsulates common functionality shared by all build commands
/// to reduce code duplication and improve maintainability.
abstract class BuildCommandBase extends Command {
  BuildCommandBase() {
    // Common argument definitions
    argParser.addFlagDebug();
    argParser.addFlagProfile();
    argParser.addFlagRelease();
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  @override
  void run() async {
    // Common execution flow
    _validateInputs();
    _prepareConfiguration();
    await _executeBuild();
    _reportSuccess();
  }

  /// Validates input arguments.
  void _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
  }

  /// Prepares the build configuration.
  void _prepareConfiguration() {
    CucumberHelper.removeNdjsonGherkin();
    
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    
    if (argGenerateL10n) {
      _generateLocalization(argMorphemeYaml);
    }
    
    FirebaseHelper.run(argFlavor, argMorphemeYaml);
  }

  /// Generates localization files.
  void _generateLocalization(String morphemeYaml) {
    'morpheme l10n --morpheme-yaml "$morphemeYaml"'.run;
  }

  /// Executes the build process.
  Future<void> _executeBuild() async {
    final flavor = _getFlavorConfiguration();
    final dartDefines = _prepareDartDefines(flavor);
    final buildCommand = constructBuildCommand(dartDefines);
    
    await FlutterHelper.run(buildCommand, showLog: true);
  }

  /// Gets flavor-specific configuration.
  Map<dynamic, dynamic> _getFlavorConfiguration() {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    return FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);
  }

  /// Prepares Dart defines from flavor configuration.
  List<String> _prepareDartDefines(Map<dynamic, dynamic> flavor) {
    final dartDefines = <String>[];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });
    return dartDefines;
  }

  /// Constructs the build command string.
  ///
  /// Subclasses should override this method to add platform-specific arguments.
  String constructBuildCommand(List<String> dartDefines) {
    final argTarget = argResults.getOptionTarget();
    final mode = argResults.getMode();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    final argObfuscate = argResults.getFlagObfuscate();
    final argSplitDebugInfo = argResults.getOptionSplitDebugInfo();
    
    return 'build $buildTarget -t $argTarget ${dartDefines.join(' ')} $mode '
           '$argBuildNumber $argBuildName $argObfuscate $argSplitDebugInfo';
  }

  /// Reports successful build completion.
  void _reportSuccess() {
    StatusHelper.success('build $buildTarget');
  }

  /// The target platform for this build command (e.g., 'apk', 'appbundle', 'ios').
  String get buildTarget;
}