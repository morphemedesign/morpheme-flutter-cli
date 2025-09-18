import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/template_test/managers/template_test_config_manager.dart';
import 'package:morpheme_cli/generate/template_test/models/template_test_config.dart';
import 'package:morpheme_cli/generate/template_test/orchestrators/template_test_orchestrator.dart';

/// Command for generating template test code based on json2dart.yaml.
///
/// The TemplateTestCommand creates test structures for Flutter applications
/// following Clean Architecture principles. It generates comprehensive test
/// directory structures with appropriate files for data, domain, and presentation layers.
///
/// ## Usage
///
/// Generate template tests for a page in a feature:
/// ```bash
/// morpheme template-test --feature-name user --page-name profile
/// ```
///
/// Generate template tests within an apps context:
/// ```bash
/// morpheme template-test --apps-name main_app --feature-name user --page-name profile
/// ```
///
/// ## Generated Structure
///
/// The command creates the following structure:
/// ```
/// features/
/// └── feature_name/
///     └── test/
///         └── page_name_test/
///             ├── data/
///             │   ├── datasources/
///             │   ├── model/
///             │   │   ├── body/
///             │   │   └── response/
///             │   └── repositories/
///             ├── domain/
///             │   ├── entities/
///             │   ├── repositories/
///             │   └── usecases/
///             └── presentation/
///                 ├── bloc/
///                 ├── cubit/
///                 ├── pages/
///                 └── widgets/
/// ```
///
/// It also generates a cubit test file with appropriate mocks and test structure.
///
class TemplateTestCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final TemplateTestConfigManager _configManager;

  /// Orchestrator for coordinating the template test generation workflow.
  late final TemplateTestOrchestrator _orchestrator;

  /// Creates a new TemplateTestCommand instance.
  ///
  /// Configures the command-line argument parser with all required options.
  TemplateTestCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate specific apps (Optional)',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Generate template test in specific feature',
      mandatory: true,
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Generate specific page, must include --feature-name',
      mandatory: true,
    );

    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'template-test';

  @override
  String get description =>
      'Generate template test code based on json2dart.yaml.';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = TemplateTestConfigManager();
    _orchestrator = TemplateTestOrchestrator();
  }

  @override
  void run() async {
    try {
      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration
      final config = _prepareConfiguration();

      // Execute generation
      final success = await _executeGeneration(config);

      if (success) {
        _reportSuccess(config.pageName, config.featureName);
      }
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Template test generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme template-test --help',
          'morpheme generate template-test --feature-name <feature> --page-name <page>',
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
  /// Returns a validated TemplateTestConfig object.
  TemplateTestConfig _prepareConfiguration() {
    return _configManager.loadConfig(argResults!);
  }

  /// Executes the template test generation process.
  ///
  /// This method coordinates the complete generation workflow through the orchestrator.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(TemplateTestConfig config) async {
    printMessage('🚀 Generating template test structure...');
    final success = await _orchestrator.generateTemplateTest(config);

    if (success) {
      printMessage('✅ Template test generation completed successfully');
    } else {
      printMessage('❌ Template test generation failed');
    }

    return success;
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays success message with the generated page and feature names.
  void _reportSuccess(String pageName, String featureName) {
    StatusHelper.success(
        'Generate template test code for $pageName in feature $featureName');
  }
}
