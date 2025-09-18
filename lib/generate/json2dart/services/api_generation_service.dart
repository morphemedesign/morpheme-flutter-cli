import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:args/args.dart';

import '../../api/managers/api_configuration_manager.dart';
import '../../api/orchestrators/api_generation_orchestrator.dart';
import '../../api/resolvers/api_type_resolver.dart';
import '../../api/templates/api_code_templates.dart';
import '../../api/validators/api_arguments_validator.dart';

/// Service class for generating API code directly without using terminal commands
///
/// This service replaces the terminal command execution with direct calls to
/// the API generation components, improving performance by avoiding process creation.
class ApiGenerationService {
  late final ApiArgumentsValidator _validator;
  late final ApiConfigurationManager _configManager;
  late final ApiGenerationOrchestrator _orchestrator;

  ApiGenerationService() {
    _initializeComponents();
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

  /// Generates API code directly using the API generation components
  ///
  /// [apiName] - Name of the API to generate
  /// [featureName] - Name of the feature
  /// [pageName] - Name of the page
  /// [method] - HTTP method
  /// [pathUrl] - API path URL
  /// [returnData] - Return data type
  /// [header] - Header configuration file path
  /// [cacheStrategy] - Cache strategy
  /// [ttl] - Time to live for cache
  /// [keepExpiredCache] - Whether to keep expired cache
  /// [appsName] - Apps name for multi-app projects
  /// [morphemeYamlPath] - Path to morpheme.yaml file
  ///
  /// Returns true if successful, false otherwise
  Future<bool> generateApi({
    required String apiName,
    required String featureName,
    required String pageName,
    required String method,
    required String pathUrl,
    required String returnData,
    String? header,
    String? cacheStrategy,
    int? ttl,
    bool? keepExpiredCache,
    String? appsName,
    String morphemeYamlPath = 'morpheme.yaml',
  }) async {
    try {
      // Create argument results manually to simulate command line arguments
      final argResults = _createArgResults(
        apiName: apiName,
        featureName: featureName,
        pageName: pageName,
        method: method,
        pathUrl: pathUrl,
        returnData: returnData,
        header: header,
        cacheStrategy: cacheStrategy,
        ttl: ttl,
        keepExpiredCache: keepExpiredCache,
        appsName: appsName,
        morphemeYamlPath: morphemeYamlPath,
      );

      // Step 1: Load project configuration
      final yamlData = YamlHelper.loadFileYaml(morphemeYamlPath);
      final projectName =
          yamlData['project_name'] ?? yamlData['name'] ?? 'morpheme';

      // Step 2: Validate arguments and create configuration
      final config = _validator.validate(argResults, projectName);

      // Step 3: Process and validate configuration
      final processedConfig = _configManager.processConfiguration(config);
      _configManager.validateConfiguration(processedConfig);

      // Step 4: Validate generation sequence
      _orchestrator.validateGenerationSequence(processedConfig);

      // Step 5: Generate API components
      await _orchestrator.generateApi(processedConfig);

      return true;
    } catch (e) {
      StatusHelper.failed('API generation failed: $e');
      // Print stack trace for debugging in verbose mode
      // print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Creates argument results manually to simulate command line arguments
  ArgResults _createArgResults({
    required String apiName,
    required String featureName,
    required String pageName,
    required String method,
    required String pathUrl,
    required String returnData,
    String? header,
    String? cacheStrategy,
    int? ttl,
    bool? keepExpiredCache,
    String? appsName,
    required String morphemeYamlPath,
  }) {
    // Create a mock ArgResults object
    final parser = ArgParser();

    // Add all the options that the ApiCommand expects
    parser.addOption('morpheme-yaml', defaultsTo: morphemeYamlPath);
    parser.addOption('feature-name', abbr: 'f');
    parser.addOption('page-name', abbr: 'p');
    parser.addFlag('json2dart', defaultsTo: true); // Always true for json2dart
    parser.addOption('method', abbr: 'm');
    parser.addOption('path');
    parser.addOption('header');
    parser.addOption('return-data', abbr: 'r');
    parser.addFlag('body-list', defaultsTo: false);
    parser.addFlag('response-list', defaultsTo: false);
    parser.addOption('cache-strategy');
    parser.addOption('ttl');
    parser.addOption('keep-expired-cache');
    parser.addOption('apps-name', abbr: 'a');

    // Parse with the provided values
    return parser.parse([
      apiName,
      '-f',
      featureName,
      '-p',
      pageName,
      '--json2dart',
      '-m',
      method,
      '--path',
      pathUrl,
      '-r',
      returnData,
      if (header != null) '--header',
      if (header != null) header,
      if (cacheStrategy != null) '--cache-strategy',
      if (cacheStrategy != null) cacheStrategy,
      if (ttl != null) '--ttl',
      if (ttl != null) '$ttl',
      if (keepExpiredCache != null) '--keep-expired-cache',
      if (keepExpiredCache != null) '$keepExpiredCache',
      if (appsName != null) '-a',
      if (appsName != null) appsName,
    ]);
  }
}
