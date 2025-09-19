import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/local2dart/models/local2dart_config.dart';
import 'package:morpheme_cli/generate/local2dart/managers/local2dart_config_manager.dart';
import 'package:morpheme_cli/generate/local2dart/orchestrators/local2dart_orchestrator.dart';

/// Generates SQLite helper classes from YAML configuration.
///
/// The Local2DartCommand processes database definitions in YAML format and generates
/// corresponding Dart classes for use in Flutter applications with SQLite.
/// It supports:
/// - Table models with CRUD operations
/// - View models
/// - Custom query models
/// - Database instance management
/// - Seed data insertion
/// - Foreign key relationships
/// - Automatic code formatting
/// - Library export file generation
///
/// ## Usage
///
/// Basic generation:
/// ```bash
/// morpheme generate local2dart
/// ```
///
/// Initialize local2dart configuration:
/// ```bash
/// morpheme generate local2dart init
/// ```
///
/// ## Configuration
///
/// The command reads configuration from local2dart/local2dart.yaml:
/// ```yaml
/// version: 1
/// dir_database: "morpheme"
/// foreign_key_constrain_support: true
/// table:
///   category:
///     create_if_not_exists: true
///     column:
///       id:
///         type: "INTEGER"
///         constraint: "PRIMARY KEY"
///         autoincrement: true
///       name:
///         type: "TEXT"
///         nullable: false
///         default: "Other"
/// ```
class Local2DartCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final Local2DartConfigManager _configManager;

  /// Orchestrator for handling the generation workflow.
  late final Local2DartOrchestrator _orchestrator;

  /// Creates a new Local2DartCommand instance.
  ///
  /// Configures the command-line argument parser with all required options.
  Local2DartCommand() {
    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'local2dart';

  @override
  String get description => 'Generate sqlite yaml to dart sqlite class helper';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = Local2DartConfigManager();
    _orchestrator = Local2DartOrchestrator();
  }

  @override
  void run() async {
    try {
      // Check if this is an init command
      final isInit = argResults?.rest.firstOrNull == 'init';

      if (isInit) {
        // Handle init command directly
        await _handleInitCommand();
        return;
      }

      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration
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
        'Local2Dart generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme generate local2dart --help',
          'morpheme generate local2dart init',
        ],
      );
      print(stackTrace);
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final configPath = join(current, 'local2dart', 'local2dart.yaml');

    if (!exists(configPath)) {
      StatusHelper.failed(
        'Configuration file not found: $configPath',
        suggestion:
            'Run "morpheme generate local2dart init" to create the configuration file',
        examples: ['morpheme generate local2dart init'],
      );
      return false;
    }

    return true;
  }

  /// Prepares configuration for the generation execution.
  ///
  /// Returns a validated Local2DartConfig object.
  Local2DartConfig _prepareConfiguration() {
    final configPath = join(current, 'local2dart', 'local2dart.yaml');
    return _configManager.loadConfig(configPath);
  }

  /// Executes the code generation process.
  ///
  /// This method coordinates the complete generation workflow through the orchestrator.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(Local2DartConfig config) async {
    printMessage('🎨 Generating Local2Dart classes...');

    final pathPackageLocal2dart =
        join(current, 'core', 'packages', 'local2dart');

    // Ensure the local2dart package exists
    if (!exists(pathPackageLocal2dart)) {
      await 'morpheme core local2dart'.run;
      await FlutterHelper.start('pub add sqflite path equatable',
          workingDirectory: pathPackageLocal2dart);
    }

    final success = await _orchestrator.generate(config, pathPackageLocal2dart);

    if (success) {
      printMessage('✅ Local2Dart generation completed successfully');
    } else {
      printMessage('❌ Local2Dart generation failed');
    }

    return success;
  }

  /// Handles the init command.
  ///
  /// This method processes the init command to create initial configuration.
  Future<void> _handleInitCommand() async {
    printMessage('🔧 Initializing Local2Dart configuration...');

    final path = join(current, 'local2dart');
    _orchestrator.init(path);
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays summary information and completion status.
  void _reportSuccess() {
    StatusHelper.success('Local2Dart generation completed successfully!');
  }
}
