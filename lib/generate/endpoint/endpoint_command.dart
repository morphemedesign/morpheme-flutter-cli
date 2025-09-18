import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/endpoint/managers/endpoint_config_manager.dart';
import 'package:morpheme_cli/generate/endpoint/orchestrators/endpoint_orchestrator.dart';
import 'package:morpheme_cli/generate/endpoint/models/endpoint_config.dart';

/// Command for generating endpoint files from json2dart.yaml configurations.
///
/// The EndpointCommand processes json2dart.yaml files and generates corresponding
/// Dart endpoint classes with static URI methods for API endpoints.
///
/// ## Usage
///
/// Generate endpoints from all json2dart.yaml files:
/// ```bash
/// morpheme generate endpoint
/// ```
///
/// Generate endpoints with custom configuration:
/// ```bash
/// morpheme generate endpoint --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Generated Structure
///
/// The command creates the following file:
/// ```
/// core/lib/src/data/remote/{project_name}_endpoints.dart
/// ```
///
/// With content like:
/// ```dart
/// abstract class ProjectEndpoints {
///   static Uri _createUriBASE_URL(String path) => Uri.parse(const String.fromEnvironment('BASE_URL') + path,);
///   
///   static Uri login = _createUriBASE_URL('/auth/login',);
///   static Uri getUserProfile(String id,) => _createUriBASE_URL('/users/$id',);
/// }
/// ```
class EndpointCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final EndpointConfigManager _configManager;

  /// Orchestrator for coordinating the endpoint generation workflow.
  late final EndpointOrchestrator _orchestrator;

  /// Creates a new EndpointCommand instance.
  ///
  /// Configures the command-line argument parser with all required options.
  EndpointCommand() {
    argParser.addOptionMorphemeYaml();

    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'endpoint';

  @override
  String get description => 'Generate endpoint from json2dart.yaml.';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = EndpointConfigManager();
    _orchestrator = EndpointOrchestrator();
  }

  @override
  void run() async {
    try {
      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration (always generate from json2dart)
      final config = _prepareConfiguration();

      // Validate configuration
      if (!_configManager.validateConfig(config)) return;

      // Execute generation
      final success = await _executeGeneration(config);

      if (success) {
        _reportSuccess();
      }
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Endpoint generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme generate endpoint --help',
          'morpheme generate endpoint',
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
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    return _configManager.validateInputs(argMorphemeYaml);
  }

  /// Prepares configuration for the generation execution.
  ///
  /// Returns a validated EndpointConfig object.
  EndpointConfig _prepareConfiguration() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    return _configManager.loadConfig(argMorphemeYaml);
  }

  /// Executes the endpoint generation process.
  ///
  /// This method coordinates the complete generation workflow through the orchestrator.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(EndpointConfig config) async {
    printMessage('🚀 Generating endpoint files...');
    final success = await _orchestrator.execute(config);

    if (success) {
      printMessage('✅ Endpoint generation completed successfully');
    } else {
      printMessage('❌ Endpoint generation failed');
    }

    return success;
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays success message with the generated endpoint file path.
  void _reportSuccess() {
    StatusHelper.success('Endpoint generation completed successfully');
  }
}