import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/color2dart/models/color2dart_config.dart';
import 'package:morpheme_cli/generate/color2dart/services/color2dart_file_service.dart';

/// Orchestrates the color generation workflow.
///
/// This class coordinates the complete color generation process by:
/// - Managing the overall generation workflow
/// - Generating base color and theme files
/// - Generating flavor-specific files for each flavor path
/// - Creating library export files
/// - Handling errors gracefully with appropriate logging
class Color2DartOrchestrator {
  /// The file service for handling file operations.
  final Color2DartFileService _fileService;

  /// Creates a new Color2DartOrchestrator instance.
  ///
  /// Parameters:
  /// - [fileService]: Optional custom file service for testing
  Color2DartOrchestrator({
    Color2DartFileService? fileService,
  }) : _fileService = fileService ?? Color2DartFileService();

  /// Generates all color and theme files based on the configuration.
  ///
  /// This method coordinates the complete generation workflow:
  /// 1. Clears existing files if requested
  /// 2. Generates base files
  /// 3. Generates theme and color files for each flavor
  /// 4. Creates library export files
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> generateColors(Color2DartConfig config) async {
    try {
      // Clear existing files if requested
      _fileService.clearExistingFiles(config);

      // Load the first flavor's YAML to generate base files
      final baseYaml = YamlHelper.loadFileYaml(config.flavorPaths.first);
      _fileService.generateBaseFiles(config, baseYaml.entries.firstOrNull);

      // Generate files for each flavor path
      for (var path in config.flavorPaths) {
        final flavor = path
            .replaceAll('${separator}color2dart.yaml', '')
            .split(separator)
            .last;

        final colorYaml = YamlHelper.loadFileYaml(path);

        colorYaml.forEach((theme, value) {
          _fileService.generateThemeFiles(config, theme, value, flavor);
          _fileService.generateColorFiles(config, theme, value, flavor);
        });
      }

      // Generate library export files
      _fileService.generateLibraryExports(config);

      // Format generated code
      await ModularHelper.format([config.pathColors, config.pathThemes]);

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate colors: $e');
      return false;
    }
  }
}