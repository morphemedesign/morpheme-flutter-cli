import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/template_test/models/template_test_config.dart';
import 'package:morpheme_cli/generate/template_test/services/template_test_service.dart';
import 'package:morpheme_cli/generate/template_test/generators/template_test_file_generator.dart';

/// Orchestrator for coordinating the template test generation workflow.
///
/// This class manages the sequence of operations for generating template tests,
/// coordinating between services and generators to produce the complete test structure.
class TemplateTestOrchestrator {
  /// Service for handling directory and file operations.
  late final TemplateTestService _service;

  /// Generator for creating template test files.
  late final TemplateTestFileGenerator _generator;

  /// Creates a new TemplateTestOrchestrator instance.
  TemplateTestOrchestrator() {
    _initializeServices();
  }

  /// Initializes all service dependencies.
  void _initializeServices() {
    _service = TemplateTestService();
    _generator = TemplateTestFileGenerator();
  }

  /// Generates the complete template test structure.
  ///
  /// This method coordinates the complete generation workflow, including:
  /// 1. Finding and loading json2dart configuration files
  /// 2. Creating directory structures
  /// 3. Generating test files
  /// 4. Formatting generated code
  ///
  /// Parameters:
  /// - [config]: The configuration for generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> generateTemplateTest(TemplateTestConfig config) async {
    try {
      // Find json2dart configuration files
      final workingDirectory = find(
        config.searchFileJson2Dart,
        workingDirectory: join(current, 'json2dart'),
      ).toList();

      for (var pathJson2Dart in workingDirectory) {
        final yml = YamlHelper.loadFileYaml(pathJson2Dart);
        final json2DartMap = Map.from(yml);

        // Update the config with the loaded map
        final updatedConfig = TemplateTestConfig(
          appsName: config.appsName,
          featureName: config.featureName,
          pageName: config.pageName,
          searchFileJson2Dart: config.searchFileJson2Dart,
          pathTestPage: config.pathTestPage,
          json2DartMap: json2DartMap,
        );

        Map map = json2DartMap[config.featureName] ?? {};

        if (map.isNotEmpty) {
          map = map[config.pageName] ?? {};
        }

        // Create directory structures
        _service.createDataTest(
          updatedConfig.pathTestPage,
          updatedConfig.featureName,
          updatedConfig.pageName,
        );

        _service.createDomainTest(
          updatedConfig.pathTestPage,
          updatedConfig.featureName,
          updatedConfig.pageName,
        );

        _service.createPresentationTest(
          updatedConfig.pathTestPage,
          updatedConfig.featureName,
          updatedConfig.pageName,
          map,
        );

        // Generate cubit test file
        _generator.createPresentationCubitTest(
          join(updatedConfig.pathTestPage, 'presentation', 'cubit'),
          updatedConfig.featureName,
          updatedConfig.pageName,
          map,
        );

        // Format generated code
        await ModularHelper.format([updatedConfig.pathTestPage]);
      }

      return true;
    } catch (e) {
      print('Error generating template test: $e');
      return false;
    }
  }
}
