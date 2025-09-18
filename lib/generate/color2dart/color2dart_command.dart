import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/color2dart/managers/color2dart_config_manager.dart';
import 'package:morpheme_cli/generate/color2dart/processors/color2dart_processor.dart';
import 'package:morpheme_cli/generate/color2dart/models/color2dart_config.dart';

/// Generates Dart color classes from YAML configuration.
///
/// The Color2DartCommand processes color definitions in YAML format and generates
/// corresponding Dart classes for use in Flutter applications. It supports:
/// - Multiple themes (light, dark, etc.)
/// - Flavor-specific color configurations
/// - MaterialColor and regular Color generation
/// - Automatic code formatting
/// - Library export file generation
///
/// ## Usage
///
/// Basic color generation:
/// ```bash
/// morpheme generate color2dart
/// ```
///
/// Generate for all flavors:
/// ```bash
/// morpheme generate color2dart --all-flavor
/// ```
///
/// Clear existing files before generation:
/// ```bash
/// morpheme generate color2dart --clear-files
/// ```
///
/// Initialize color2dart configuration:
/// ```bash
/// morpheme generate color2dart init
/// ```
///
/// ## Configuration
///
/// The command reads configuration from morpheme.yaml:
/// ```yaml
/// color2dart:
///   color2dart_dir: "color2dart"  # Directory containing color definitions
///   output_dir: "lib/themes"      # Output directory for generated files
/// ```
///
/// Color definitions are stored in color2dart.yaml files:
/// ```yaml
/// light:
///   brightness: "light"
///   colors:
///     primary: "0xFF006778"
///     secondary: "0xFFFFD124"
/// ```
class Color2DartCommand extends Command {
  /// Configuration manager for loading and validating configuration.
  late final Color2DartConfigManager _configManager;

  /// Processor for handling the generation workflow.
  late final Color2DartProcessor _processor;

  /// Creates a new Color2DartCommand instance.
  ///
  /// Configures the command-line argument parser with all required options.
  Color2DartCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'clear-files',
      abbr: 'c',
      help: 'Clear files before generated new files.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'all-flavor',
      abbr: 'a',
      help: 'Generate all flavor with the same time.',
      defaultsTo: false,
    );
    argParser.addOptionFlavor(defaultsTo: '');

    // Initialize services
    _initializeServices();
  }

  @override
  String get name => 'color2dart';

  @override
  String get description => 'Generate dart color class from yaml.';

  @override
  String get category => Constants.generate;

  /// Initializes all service dependencies.
  ///
  /// This method sets up all the service classes needed for the command to function.
  void _initializeServices() {
    _configManager = Color2DartConfigManager();
    _processor = Color2DartProcessor();
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
    } catch (e) {
      StatusHelper.failed(
        'Color generation failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme generate color2dart --help',
          'morpheme generate color2dart init',
        ],
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
    } catch (e) {
      StatusHelper.failed(
        'Invalid morpheme.yaml configuration: ${e.toString()}',
        suggestion: 'Ensure morpheme.yaml exists and has valid syntax',
        examples: ['morpheme init', 'morpheme config'],
      );
      return false;
    }

    return true;
  }

  /// Prepares configuration for the generation execution.
  ///
  /// Returns a validated Color2DartConfig object.
  Color2DartConfig _prepareConfiguration() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    return _configManager.loadConfig(argResults, argMorphemeYaml);
  }

  /// Executes the color generation process.
  ///
  /// This method coordinates the complete generation workflow through the processor.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(Color2DartConfig config) async {
    printMessage('🎨 Generating color classes...');
    final success = await _processor.processGeneration(config, false);
    
    if (success) {
      printMessage('✅ Color generation completed successfully');
    } else {
      printMessage('❌ Color generation failed');
    }
    
    return success;
  }

  /// Handles the init command.
  ///
  /// This method processes the init command to create initial configuration.
  Future<void> _handleInitCommand() async {
    printMessage('🔧 Initializing color2dart configuration...');
    
    try {
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      
      final config = _prepareConfiguration();
      final success = await _processor.processGeneration(config, true);
      
      if (success) {
        printMessage('✅ Color2Dart initialization completed successfully');
      }
    } catch (e) {
      StatusHelper.failed(
        'Initialization failed: $e',
        suggestion: 'Check your configuration and try again',
        examples: ['morpheme init', 'morpheme config'],
      );
    }
  }

  /// Reports successful completion of the generation.
  ///
  /// Displays summary information and completion status.
  void _reportSuccess() {
    StatusHelper.success('Color2Dart generation completed successfully!');
  }
}