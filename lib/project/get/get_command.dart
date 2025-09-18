import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Retrieves dependencies for all project packages.
///
/// The GetCommand runs `flutter pub get` across the main project,
/// core packages, and feature modules to ensure all dependencies
/// are properly resolved and up to date.
///
/// ## Usage
///
/// Basic dependency retrieval:
/// ```bash
/// morpheme get
/// ```
///
/// With localization generation:
/// ```bash
/// morpheme get --generate-l10n
/// ```
///
/// With custom configuration:
/// ```bash
/// morpheme get --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Options
///
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--generate-l10n`: Generate localization files after dependency retrieval
///
/// ## Process
///
/// 1. Validates morpheme.yaml configuration
/// 2. Generates localization files (if requested)
/// 3. Runs `flutter pub get` on all packages in parallel
/// 4. Reports completion status
///
/// ## Dependencies
///
/// - Requires valid morpheme.yaml configuration
/// - Uses ModularHelper for multi-package operations
/// - Requires Flutter SDK for pub operations
///
/// ## Exceptions
///
/// Throws [FileSystemException] if morpheme.yaml is missing or invalid.
/// Throws [ProcessException] if Flutter pub get fails.
class GetCommand extends Command {
  /// Creates a new instance of GetCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--morpheme-yaml`: Path to morpheme.yaml configuration
  /// - `--generate-l10n`: Flag to generate localization files
  GetCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlagGenerateL10n();
  }
  @override
  String get name => 'get';

  @override
  String get description =>
      'Retrieve dependencies for all project packages and features.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      if (!_validateInputs()) return;

      final config = _prepareConfiguration();

      if (config['generateL10n']) {
        await _generateLocalization(config);
      }

      await _retrieveDependencies(config);
      _reportSuccess();
    } catch (e) {
      ErrorHandler.handleException(
        ProjectCommandError.dependencyFailure,
        e,
        'Dependency retrieval failed',
      );
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    try {
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      return true;
    } catch (e) {
      ErrorHandler.handleException(
        ProjectCommandError.configurationMissing,
        e,
        'Invalid morpheme.yaml configuration',
      );
      return false;
    }
  }

  /// Prepares the dependency retrieval configuration.
  ///
  /// Extracts configuration settings from morpheme.yaml and
  /// command line arguments.
  ///
  /// Returns: Configuration map with dependency settings
  Map<String, dynamic> _prepareConfiguration() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    return {
      'yamlPath': argMorphemeYaml,
      'generateL10n': argGenerateL10n,
      'concurrent': yaml.concurrent,
    };
  }

  /// Generates localization files if requested.
  ///
  /// Runs the morpheme l10n command to ensure all localization
  /// files are up to date before dependency retrieval.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing localization settings
  Future<void> _generateLocalization(Map<String, dynamic> config) async {
    final yamlPath = config['yamlPath'];
    await 'morpheme l10n --morpheme-yaml "$yamlPath"'.run;
  }

  /// Retrieves dependencies for all project packages.
  ///
  /// Uses ModularHelper to run `flutter pub get` across all
  /// packages in parallel based on the concurrency setting.
  ///
  /// Parameters:
  /// - [config]: Configuration containing concurrency settings
  Future<void> _retrieveDependencies(Map<String, dynamic> config) async {
    await ModularHelper.get(concurrent: config['concurrent']);
  }

  /// Reports successful completion of dependency retrieval.
  ///
  /// Displays a success message indicating that all packages
  /// have had their dependencies successfully retrieved.
  void _reportSuccess() {
    StatusHelper.success('morpheme get');
  }
}
