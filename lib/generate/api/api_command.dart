import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

import 'managers/api_configuration_manager.dart';
import 'orchestrators/api_generation_orchestrator.dart';
import 'resolvers/api_type_resolver.dart';
import 'templates/api_code_templates.dart';
import 'validators/api_arguments_validator.dart';

/// Main command class for generating API integration code.
///
/// This command creates a complete API integration layer following clean
/// architecture principles, including data sources, repositories, use cases,
/// and presentation layer components.
///
/// Usage:
/// ```bash
/// morpheme api <api-name> -f <feature-name> -p <page-name> [options]
/// ```
///
/// Generates:
/// - Data layer: Remote data sources, models, repository implementations
/// - Domain layer: Entities, repository interfaces, use cases
/// - Presentation layer: BLoC pattern implementation with states and events
/// - Infrastructure: Dependency injection setup and data mappers
class ApiCommand extends Command {
  ApiCommand() {
    _setupArgumentParser();
    _initializeComponents();
  }

  // Component dependencies
  late final ApiArgumentsValidator _validator;
  late final ApiConfigurationManager _configManager;
  late final ApiGenerationOrchestrator _orchestrator;

  /// Sets up the command line argument parser with all available options.
  void _setupArgumentParser() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature to be added api',
      mandatory: true,
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Name of the page to be added api',
      mandatory: true,
    );
    argParser.addFlag(
      'json2dart',
      help: 'Generate models handle by json2dart',
      defaultsTo: false,
    );
    argParser.addOption(
      'method',
      abbr: 'm',
      allowed: [
        'get',
        'post',
        'put',
        'patch',
        'delete',
        'multipart',
        'postMultipart',
        'patchMultipart',
        'head',
        'getSse',
        'postSse',
        'putSse',
        'patchSse',
        'deleteSse',
        'download',
      ],
      defaultsTo: 'post',
    );
    argParser.addOption('path');
    argParser.addOption(
      'header',
      help: 'path file json additional header fetch api',
    );
    argParser.addOption(
      'return-data',
      abbr: 'r',
      help:
          'Specify the type of data to return from the API response. Options include: model, header, body_bytes, body_string, status_code, and raw.',
      allowed: [
        'model',
        'header',
        'body_bytes',
        'body_string',
        'status_code',
        'raw',
      ],
      defaultsTo: 'model',
    );
    argParser.addFlag(
      'body-list',
      help: 'body for api is list',
      defaultsTo: false,
    );
    argParser.addFlag(
      'response-list',
      help: 'response for api is list',
      defaultsTo: false,
    );
    argParser.addOption(
      'cache-strategy',
      help: 'Strategy for caching response api',
      allowed: ['async_or_cache', 'cache_or_async', 'just_async', 'just_cache'],
    );
    argParser.addOption(
      'ttl',
      help: 'Duration of expired cache in cache strategy in minutes',
    );
    argParser.addOption(
      'keep-expired-cache',
      help: 'Keep cache without expired.',
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate spesific apps (Optional)',
    );
  }

  /// Initializes the component dependencies.
  void _initializeComponents() {
    final typeResolver = ApiTypeResolver();
    final codeTemplates = ApiCodeTemplates(typeResolver: typeResolver);

    _validator = ApiArgumentsValidator();
    _configManager = ApiConfigurationManager();
    _orchestrator = ApiGenerationOrchestrator(
      typeResolver: typeResolver,
      codeTemplates: codeTemplates,
    );
  }

  @override
  String get name => 'api';

  @override
  String get description => 'Create a new api in page.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    try {
      // Step 1: Load project configuration
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();
      final projectName = YamlHelper.loadFileYaml(argMorphemeYaml).projectName;

      // Step 2: Validate arguments and create configuration
      final config = _validator.validate(argResults, projectName);

      // Step 3: Process and validate configuration
      final processedConfig = _configManager.processConfiguration(config);
      _configManager.validateConfiguration(processedConfig);

      // Step 4: Validate generation sequence
      _orchestrator.validateGenerationSequence(processedConfig);

      // Step 5: Generate API components
      await _orchestrator.generateApi(processedConfig);
    } catch (e) {
      StatusHelper.failed('API generation failed: $e');
      rethrow;
    }
  }
}
