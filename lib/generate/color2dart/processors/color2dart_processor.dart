import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/color2dart/models/color2dart_config.dart';
import 'package:morpheme_cli/generate/color2dart/orchestrators/color2dart_orchestrator.dart';

/// Processes the complete color generation workflow.
///
/// This class handles the complete generation workflow including:
/// - Processing the complete generation workflow
/// - Handling init command if requested
/// - Clearing existing files if requested
/// - Generating all required files through orchestrator
/// - Formatting generated code
/// - Handling errors with appropriate feedback
class Color2DartProcessor {
  /// The orchestrator for coordinating the generation workflow.
  final Color2DartOrchestrator _orchestrator;

  /// Creates a new Color2DartProcessor instance.
  ///
  /// Parameters:
  /// - [orchestrator]: Optional custom orchestrator for testing
  Color2DartProcessor({
    Color2DartOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator ?? Color2DartOrchestrator();

  /// Processes the complete generation workflow.
  ///
  /// This method handles the complete generation workflow:
  /// 1. Handles init command if [isInit] is true
  /// 2. Clears existing files if requested
  /// 3. Generates all required files through orchestrator
  /// 4. Formats generated code
  /// 5. Handles errors with appropriate feedback
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  /// - [isInit]: Whether this is an init command
  ///
  /// Returns: true if processing was successful, false otherwise
  Future<bool> processGeneration(Color2DartConfig config, bool isInit) async {
    try {
      // Handle init command if requested
      if (isInit) {
        return handleInitCommand(config);
      }

      // Process the generation workflow
      final success = await _orchestrator.generateColors(config);

      if (success) {
        StatusHelper.success('morpheme color2dart generation completed');
      } else {
        StatusHelper.failed('morpheme color2dart generation failed');
      }

      return success;
    } catch (e) {
      StatusHelper.failed('Failed to process generation: $e');
      return false;
    }
  }

  /// Handles the init command.
  ///
  /// This method creates the initial configuration directory structure
  /// and generates a default color2dart.yaml file with sample configuration.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths
  ///
  /// Returns: true if init was successful, false otherwise
  bool handleInitCommand(Color2DartConfig config) {
    try {
      final path = join(current, config.color2dartDir);
      createDir(path);

      final initFilePath = join(path, 'color2dart.yaml');
      if (!exists(initFilePath)) {
        final initContent = '''# brightness can be 'light' or 'dark'

light:
  brightness: "light"
  colors:
    white: "0xFFFFFFFF"
    black: "0xFF1E1E1E"
    grey: "0xFF979797"
    grey1: "0xFFCFCFCF"
    grey2: "0xFFE5E5E5"
    grey3: "0xFFF5F5F5"
    grey4: "0xFFF9F9F9"
    primary: "0xFF006778"
    secondary: "0xFFFFD124"
    primaryLighter: "0xFF00AFC1"
    warning: "0xFFDAB320"
    info: "0xFF00AFC1"
    success: "0xFF22A82F"
    error: "0xFFD66767"
    bgError: "0xFFFFECEA"
    bgInfo: "0xFFDFFCFF"
    bgSuccess: "0xFFECFFEE"
    bgWarning: "0xFFFFF9E3"
dark:
  brightnes: "dark"
  colors:
    white: "0xFF1E1E1E"
    black: "0xFFFFFFFF"
    grey: "0xFF979797"
    grey1: "0xFFF9F9F9"
    grey2: "0xFFF5F5F5"
    grey3: "0xFFE5E5E5"
    grey4: "0xFFCFCFCF"
    primary: "0xFF006778"
    secondary: "0xFFFFD124"
    primaryLighter: "0xFF00AFC1"
    warning: "0xFFDAB320"
    info: "0xFF00AFC1"
    success: "0xFF22A82F"
    error: "0xFFD66767"
    bgError: "0xFFFFECEA"
    bgInfo: "0xFFDFFCFF"
    bgSuccess: "0xFFECFFEE"
    bgWarning: "0xFFFFF9E3"
''';

        initFilePath.write(initContent);
      }

      StatusHelper.success('morpheme color2dart init completed');
      return true;
    } catch (e) {
      StatusHelper.failed('Failed to initialize color2dart: $e');
      return false;
    }
  }
}
