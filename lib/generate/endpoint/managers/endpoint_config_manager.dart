import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/endpoint/models/endpoint_config.dart';

/// Manages loading and validating endpoint generation configuration.
///
/// This class handles parsing command-line arguments, validating inputs,
/// and creating a validated [EndpointConfig] object.
class EndpointConfigManager {
  /// Validates input parameters and project prerequisites.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool validateInputs(String? morphemeYamlPath) {
    try {
      YamlHelper.validateMorphemeYaml(morphemeYamlPath);
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

  /// Loads and prepares configuration for endpoint generation.
  ///
  /// Parses command-line arguments and constructs a [EndpointConfig] object
  /// with all necessary parameters for endpoint generation.
  EndpointConfig loadConfig(String morphemeYamlPath) {
    final yamlData = YamlHelper.loadFileYaml(morphemeYamlPath);
    final projectName =
        yamlData['project_name'] ?? yamlData['name'] ?? 'morpheme';

    final pathDir = join(
      current,
      'core',
      'lib',
      'src',
      'data',
      'remote',
    );

    final pathOutput = join(
      pathDir,
      '${projectName.toString().snakeCase}_endpoints.dart',
    );

    // Always look for json2dart files
    final json2DartPaths = <String>[];
    json2DartPaths.addAll(
      find(
        '*json2dart.yaml',
        workingDirectory: join(current, 'json2dart'),
      ).toList(),
    );

    return EndpointConfig(
      projectName: projectName,
      outputPath: pathOutput,
      json2DartPaths: json2DartPaths,
    );
  }

  /// Validates the loaded configuration.
  ///
  /// Returns true if configuration is valid, false otherwise.
  /// Displays specific error messages when no json2dart files are found.
  bool validateConfig(EndpointConfig config) {
    // Check if any json2dart files were found
    if (config.json2DartPaths.isEmpty) {
      StatusHelper.failed(
        'No json2dart.yaml files found',
        suggestion: 'Create json2dart.yaml files in the json2dart directory',
        examples: [
          'Create a json2dart directory at the project root',
          'Add json2dart.yaml files with API endpoint definitions',
          'Run "morpheme json2dart" to generate initial files',
        ],
      );
      return false;
    }

    return true;
  }
}
