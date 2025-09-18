import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

import 'generators/body_model_generator.dart';
import 'generators/entity_generator.dart';
import 'generators/mapper_generator.dart';
import 'generators/response_model_generator.dart';
import 'managers/json2dart_config_manager.dart';
import 'orchestrators/generation_orchestrator.dart';
import 'processors/api_processor.dart';
import 'processors/command_processor.dart';
import 'processors/feature_processor.dart';
import 'processors/page_processor.dart';
import 'services/file_operation_service.dart';
import 'services/unit_test_generation_service.dart';

/// Json2Dart command with new modular architecture
///
/// This command uses a clean, modular architecture with separation of concerns:
/// - CommandProcessor: Handles CLI interface and argument processing
/// - GenerationOrchestrator: Coordinates overall generation workflow
/// - FeatureProcessor: Processes individual features
/// - ConfigManager: Manages configuration loading and validation
/// - FileOperationService: Handles all file operations
class Json2DartCommand extends Command {
  Json2DartCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'api',
      help: 'Generate models with implement api.',
    );
    argParser.addFlag(
      'endpoint',
      help: 'Generate endpoint from path json2dart.yaml.',
    );
    argParser.addFlag(
      'unit-test',
      help: 'Generate unit test for api implementation.',
    );
    argParser.addFlag(
      'only-unit-test',
      help: 'Generate only unit test for api implementation.',
    );
    argParser.addFlag(
      'cubit',
      help: 'Generate with cubit. for api implementation.',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Generate specific feature (Optional)',
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Generate specific page, must include --feature-name (Optional)',
    );
    argParser.addFlag(
      'replace',
      help:
          'Replace value generated. if set to false will be delete all directory generated json2dart before.',
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate specific apps (Optional)',
    );
    argParser.addFlag(
      'format',
      help: 'Format file dart generated.',
    );
    // Add verbose flag for debugging
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose output for debugging.',
      negatable: false,
    );
  }

  @override
  String get name => 'json2dart';

  @override
  String get description => 'Generate dart data class from json.';

  @override
  String get category => Constants.generate;

  // Service instances
  late final Json2DartConfigManager _configManager;
  late final FileOperationService _fileService;
  late final FeatureProcessor _featureProcessor;
  late final GenerationOrchestrator _orchestrator;
  late final CommandProcessor _commandProcessor;
  final Set<String> _extraDirectories =
      <String>{}; // Track extra directories for formatting

  @override
  void run() async {
    try {
      // Get project name for context first
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();
      final projectName = YamlHelper.loadFileYaml(argMorphemeYaml).projectName;

      // Initialize services with dependency injection
      _initializeServices(projectName);

      // Execute command through processor
      final success = await _commandProcessor.execute(
        argResults: argResults,
        projectName: projectName,
      );

      // Report final result
      if (success) {
        StatusHelper.success('morpheme json2dart');
      } else {
        StatusHelper.failed('json2dart command failed');
      }
    } catch (e, stackTrace) {
      StatusHelper.failed('Json2Dart command error: $e');
      // Print stack trace in debug mode
      if (argResults?['verbose'] == true) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
    }
  }

  /// Initializes all service dependencies using dependency injection pattern
  void _initializeServices(String projectName) {
    // Check if verbose mode is enabled
    final isVerbose = argResults?['verbose'] == true;

    // Clear extra directories from previous runs
    _extraDirectories.clear();

    // Core services
    _configManager = Json2DartConfigManager();
    _fileService = FileOperationService();

    // Code generators (with default date formats)
    final bodyGenerator = BodyModelGenerator(
      bodyDateFormat: '.toIso8601String()',
    );
    final responseGenerator = ResponseModelGenerator(
      responseDateFormat: '.toIso8601String()',
    );
    final entityGenerator = EntityGenerator();
    final mapperGenerator = MapperGenerator();

    // Unit testing service (requires project name)
    final testService = UnitTestGenerationService(
      projectName: projectName,
    );

    // API processing layer
    final apiProcessor = ApiProcessor(
      bodyGenerator: bodyGenerator,
      responseGenerator: responseGenerator,
      entityGenerator: entityGenerator,
      mapperGenerator: mapperGenerator,
      fileService: _fileService,
      extraDirectories: _extraDirectories, // Pass the extra directories set
      verbose: isVerbose,
    );

    // Page processing layer
    final pageProcessor = PageProcessor(
      apiProcessor: apiProcessor,
      fileService: _fileService,
      testService: testService,
      verbose: isVerbose,
    );

    // Feature processing layer
    _featureProcessor = FeatureProcessor(
      pageProcessor: pageProcessor,
      fileService: _fileService,
      verbose: isVerbose,
    );

    // Orchestration layer
    _orchestrator = GenerationOrchestrator(
      featureProcessor: _featureProcessor,
      verbose: isVerbose,
    );

    // Command processing layer (top-level coordination)
    _commandProcessor = CommandProcessor(
      configManager: _configManager,
      fileService: _fileService,
      orchestrator: _orchestrator,
      verbose: isVerbose,
    );
  }
}
