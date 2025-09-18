import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command for generating localizations for the current project.
///
/// This command processes ARB (Application Resource Bundle) files to generate
/// localized messages for Flutter applications. It merges multiple ARB files
/// per locale, sorts the content, and then runs Flutter's built-in
/// gen-l10n command to generate the localization classes.
class LocalizationCommand extends Command {
  /// Attribute key used to identify the locale in ARB files.
  static const String _localeAttribute = '@@locale';

  LocalizationCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'l10n';

  @override
  String get description => 'Generate localizations for the current project.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    // Validate the morpheme.yaml configuration
    await _validateConfiguration();

    // Process all ARB directories
    await _processArbDirectories();

    // Execute Flutter's gen-l10n command
    await _executeFlutterGenL10n();

    // Report successful completion
    _reportSuccess();
  }

  /// Validates the morpheme.yaml configuration for localization settings.
  ///
  /// This method ensures that the required configuration exists and is valid
  /// before proceeding with the localization generation process.
  Future<void> _validateConfiguration() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
  }

  /// Processes all ARB directories defined in the localization configuration.
  ///
  /// This method iterates through each ARB directory, processing the ARB files
  /// within each directory by merging and sorting them.
  Future<void> _processArbDirectories() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final morphemeYamlHelper = LocalizationHelper(argMorphemeYaml);

    final arbDirectories = find(
      '*',
      recursive: false,
      workingDirectory: morphemeYamlHelper.arbDir,
      types: [Find.directory],
    ).toList();

    for (final directoryPath in arbDirectories) {
      await _processDirectory(directoryPath, morphemeYamlHelper);
    }
  }

  /// Processes a single ARB directory by merging and sorting ARB files.
  ///
  /// This method handles the processing of ARB files within a single directory:
  /// 1. Finds all ARB files in the directory
  /// 2. Merges the ARB files for the locale
  /// 3. Sorts the merged content
  /// 4. Writes the final merged file
  ///
  /// [directoryPath] The path to the ARB directory to process
  /// [morphemeYamlHelper] The localization helper with configuration settings
  Future<void> _processDirectory(
      String directoryPath, LocalizationHelper morphemeYamlHelper) async {
    final localeName = directoryPath.split(separator).last;
    final defaultArbFilePath =
        join(morphemeYamlHelper.arbDir, '$localeName.arb');

    final arbFiles = find(
      '*.arb',
      workingDirectory: directoryPath,
      recursive: true,
      types: [Find.file],
    ).toList();

    String mergedContent = '{"$_localeAttribute": "$localeName"}';

    if (morphemeYamlHelper.replace && exists(defaultArbFilePath)) {
      mergedContent = readFile(defaultArbFilePath);
    }

    for (final arbFilePath in arbFiles) {
      final arbContent = readFile(arbFilePath);
      final sortedContent = sortARB(arbContent);
      arbFilePath.write(sortedContent);

      mergedContent = mergeARBs(mergedContent, sortedContent);
    }

    defaultArbFilePath.write(mergedContent);
  }

  /// Executes Flutter's gen-l10n command with the configured parameters.
  ///
  /// This method runs the Flutter gen-l10n command with the parameters
  /// specified in the morpheme.yaml configuration file.
  Future<void> _executeFlutterGenL10n() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final morphemeYamlHelper = LocalizationHelper(argMorphemeYaml);

    await FlutterHelper.run(
        'gen-l10n --arb-dir="${morphemeYamlHelper.arbDir}" --template-arb-file="${morphemeYamlHelper.templateArbFile}" --output-localization-file="${morphemeYamlHelper.outputLocalizationFile}" --output-class="${morphemeYamlHelper.outputClass}" --output-dir="${morphemeYamlHelper.outputDir}"');
  }

  /// Reports successful completion of the localization generation process.
  ///
  /// This method displays a success message to the user indicating that
  /// the localization files have been generated successfully.
  void _reportSuccess() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final morphemeYamlHelper = LocalizationHelper(argMorphemeYaml);
    StatusHelper.success('generate l10n to ${morphemeYamlHelper.outputDir}');
  }
}
