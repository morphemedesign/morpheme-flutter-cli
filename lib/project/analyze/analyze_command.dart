import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Analyzes code quality across all packages in the project.
///
/// The AnalyzeCommand runs static analysis on the main project,
/// core packages, and feature modules using Flutter's analyzer.
/// It respects concurrency settings from morpheme.yaml and provides
/// detailed feedback on code quality issues.
///
/// ## Usage
///
/// Basic analysis:
/// ```bash
/// morpheme analyze
/// ```
///
/// With custom configuration:
/// ```bash
/// morpheme analyze --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Configuration
///
/// The command reads concurrency settings from morpheme.yaml:
/// ```yaml
/// concurrent: 4  # Number of parallel analysis processes
/// ```
///
/// ## Output
///
/// - Displays analysis results for each package
/// - Reports lint warnings and errors
/// - Shows overall success/failure status
///
/// ## Dependencies
///
/// - Requires valid morpheme.yaml configuration
/// - Uses ModularHelper for package discovery
/// - Integrates with Flutter analyzer
///
/// ## Exceptions
///
/// Throws [FileSystemException] if morpheme.yaml is missing or invalid.
/// Throws [ProcessException] if Flutter analyzer fails to execute.
class AnalyzeCommand extends Command {
  /// Creates a new instance of AnalyzeCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--morpheme-yaml`: Path to the morpheme.yaml configuration file
  AnalyzeCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Analyze code quality in all packages using Flutter analyzer.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      if (!_validateInputs()) return;

      final config = _prepareConfiguration();
      await _executeAnalysis(config);
      _reportSuccess();
    } catch (e) {
      StatusHelper.failed('Analysis failed: ${e.toString()}',
          suggestion:
              'Check your morpheme.yaml configuration and ensure Flutter analyzer is available',
          examples: ['morpheme doctor', 'flutter doctor']);
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
      StatusHelper.failed(
          'Invalid morpheme.yaml configuration: ${e.toString()}',
          suggestion: 'Ensure morpheme.yaml exists and has valid syntax',
          examples: ['morpheme init', 'morpheme config']);
      return false;
    }
  }

  /// Prepares the analysis configuration from morpheme.yaml.
  ///
  /// Returns a map containing the concurrency setting and other
  /// analysis parameters extracted from the configuration file.
  Map<String, dynamic> _prepareConfiguration() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    return {
      'concurrent': yaml.concurrent,
      'yamlPath': argMorphemeYaml,
    };
  }

  /// Executes the code analysis across all packages.
  ///
  /// Uses ModularHelper to run analysis on the main project,
  /// core packages, and feature modules in parallel based on
  /// the concurrency setting.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing analysis settings
  Future<void> _executeAnalysis(Map<String, dynamic> config) async {
    await ModularHelper.analyze(concurrent: config['concurrent']);
  }

  /// Reports successful completion of the analysis.
  ///
  /// Displays a success message indicating that code analysis
  /// has completed across all packages.
  void _reportSuccess() {
    StatusHelper.success('morpheme analyze');
  }
}
