import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/managers/page_config_manager.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';
import 'package:morpheme_cli/generate/page/orchestrators/page_generation_orchestrator.dart';

/// Command for generating page structures within feature modules.
///
/// This command creates a complete page structure following Clean Architecture principles,
/// including data, domain, and presentation layers. It also sets up locator files for
/// dependency injection and integrates with the feature's locator system.
///
/// ## Usage
///
/// Basic usage:
/// ```bash
/// morpheme page <page-name> -f <feature-name>
/// ```
///
/// With apps context:
/// ```bash
/// morpheme page <page-name> -f <feature-name> -a <apps-name>
/// ```
///
/// ## Generated Structure
///
/// The command generates the following directory structure:
/// ```
/// <page-name>/
/// ├── data/
/// │   ├── datasources/
/// │   ├── models/
/// │   │   ├── body/
/// │   │   └── response/
/// │   └── repositories/
/// ├── domain/
/// │   ├── entities/
/// │   ├── repositories/
/// │   └── usecases/
/// ├── presentation/
/// │   ├── bloc/
/// │   ├── cubit/
/// │   ├── pages/
/// │   └── widgets/
/// ├── locator.dart
/// ```
///
/// ## Dependencies
///
/// - Requires a valid feature module to exist
/// - Requires morpheme CLI core utilities
/// - Uses ModularHelper for code formatting
class PageCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final PageConfigManager _configManager;

  /// Orchestrator for coordinating the page generation workflow.
  late final PageGenerationOrchestrator _orchestrator;

  /// Creates a new PageCommand instance.
  ///
  /// Configures the command-line argument parser with required and optional parameters:
  /// - `page-name`: Positional argument for the page name (required)
  /// - `-f, --feature-name`: Name of the feature to add the page to (required)
  /// - `-a, --apps-name`: Name of the apps context (optional)
  PageCommand() {
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature to be added page',
      mandatory: true,
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the apps to be added page.',
    );

    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'page';

  @override
  String get description => 'Create a new page in feature module.';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = PageConfigManager();
    _orchestrator = PageGenerationOrchestrator();
  }

  @override
  void run() async {
    try {
      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration
      final config = _prepareConfiguration();

      // Validate configuration
      if (!_configManager.validateInputs(argResults)) return;

      // Execute generation
      final success = await _executeGeneration(config);

      if (success) {
        _reportSuccess(config.pageName, config.featureName);
      }
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Page generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme page <page-name> --help',
          'morpheme generate page <page-name>',
        ],
      );
      print('Stack trace: $stackTrace');
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    return _configManager.validateInputs(argResults);
  }

  /// Prepares configuration for the generation execution.
  ///
  /// Returns a validated PageConfig object.
  PageConfig _prepareConfiguration() {
    return _configManager.loadConfig(argResults!);
  }

  /// Executes the page generation process.
  ///
  /// This method coordinates the complete generation workflow through the orchestrator.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(PageConfig config) async {
    printMessage('🚀 Generating page structure...');
    final success = await _orchestrator.generatePage(config);

    if (success) {
      printMessage('✅ Page generation completed successfully');
    } else {
      printMessage('❌ Page generation failed');
    }

    return success;
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays success message with the generated page and feature names.
  void _reportSuccess(String pageName, String featureName) {
    StatusHelper.success('generate page $pageName in feature $featureName');
  }
}