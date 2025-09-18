import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/feature/managers/feature_config_manager.dart';
import 'package:morpheme_cli/generate/feature/models/feature_config.dart';
import 'package:morpheme_cli/generate/feature/orchestrators/feature_orchestrator.dart';

/// Command for generating feature modules.
///
/// The FeatureCommand creates new feature modules for Flutter applications.
/// It supports creating features both at the project level and within apps modules.
///
/// ## Usage
///
/// Create a new feature at the project level:
/// ```bash
/// morpheme feature user_profile
/// ```
///
/// Create a new feature within an apps module:
/// ```bash
/// morpheme feature user_profile --apps-name main_app
/// ```
///
/// ## Generated Structure
///
/// The command creates the following structure:
/// ```
/// features/
/// └── feature_name/
///     ├── lib/
///     │   └── locator.dart
///     ├── test/
///     │   └── .gitkeep
///     ├── .gitignore
///     ├── analysis_options.yaml
///     └── pubspec.yaml
/// ```
///
/// It also updates:
/// - The main locator.dart file to import and register the feature
/// - The main pubspec.yaml to include the feature as a dependency
///
class FeatureCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final FeatureConfigManager _configManager;

  /// Orchestrator for coordinating the feature generation workflow.
  late final FeatureOrchestrator _orchestrator;

  /// Creates a new FeatureCommand instance.
  ///
  /// Configures the command-line argument parser with all required options.
  FeatureCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Create a new feature module in apps.',
      defaultsTo: '',
    );

    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Create a new feature module.';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = FeatureConfigManager();
    _orchestrator = FeatureOrchestrator();
  }

  @override
  void run() async {
    try {
      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration
      final config = _prepareConfiguration();

      // Validate configuration
      if (!_configManager.validateConfig(config)) return;

      // Execute generation
      final success = await _executeGeneration(config);

      if (success) {
        _reportSuccess(config.featureName);
      }
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Feature generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme feature <feature-name> --help',
          'morpheme generate feature <feature-name>',
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
    final featureName = argResults?.rest.firstOrNull;
    final appsName = argResults?['apps-name'] as String? ?? '';
    final pathApps = join(current, 'apps', appsName);

    return _configManager.validateInputs(featureName, appsName, pathApps);
  }

  /// Prepares configuration for the generation execution.
  ///
  /// Returns a validated FeatureConfig object.
  FeatureConfig _prepareConfiguration() {
    final featureName = argResults?.rest.firstOrNull;
    final appsName = argResults?['apps-name'] as String? ?? '';

    return _configManager.loadConfig(featureName!, appsName);
  }

  /// Executes the feature generation process.
  ///
  /// This method coordinates the complete generation workflow through the orchestrator.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(FeatureConfig config) async {
    printMessage('🚀 Generating feature module...');
    final success = await _orchestrator.execute(config);

    if (success) {
      printMessage('✅ Feature generation completed successfully');
    } else {
      printMessage('❌ Feature generation failed');
    }

    return success;
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays success message with the generated feature name.
  void _reportSuccess(String featureName) {
    StatusHelper.success('generate feature $featureName');
  }
}
