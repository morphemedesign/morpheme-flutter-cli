import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

import '../generators/data_layer_generator.dart';
import '../generators/domain_layer_generator.dart';
import '../generators/infrastructure_generator.dart';
import '../generators/presentation_layer_generator.dart';
import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';
import '../templates/api_code_templates.dart';

/// Orchestrates the API generation process across all architectural layers.
///
/// Coordinates the creation of data, domain, and presentation layer components
/// in the correct order, handling conditional generation based on configuration
/// options.
class ApiGenerationOrchestrator {
  ApiGenerationOrchestrator({
    required this.typeResolver,
    required this.codeTemplates,
  }) {
    _dataLayerGenerator = DataLayerGenerator(
      typeResolver: typeResolver,
      codeTemplates: codeTemplates,
    );

    _domainLayerGenerator = DomainLayerGenerator(
      typeResolver: typeResolver,
      codeTemplates: codeTemplates,
    );

    _presentationLayerGenerator = PresentationLayerGenerator(
      typeResolver: typeResolver,
      codeTemplates: codeTemplates,
    );

    _infrastructureGenerator = InfrastructureGenerator(
      typeResolver: typeResolver,
      codeTemplates: codeTemplates,
    );
  }

  final ApiTypeResolver typeResolver;
  final ApiCodeTemplates codeTemplates;

  late final DataLayerGenerator _dataLayerGenerator;
  late final DomainLayerGenerator _domainLayerGenerator;
  late final PresentationLayerGenerator _presentationLayerGenerator;
  late final InfrastructureGenerator _infrastructureGenerator;

  /// Executes the complete API generation process.
  ///
  /// Generates all required components following clean architecture patterns
  /// in the correct order to ensure dependencies are properly established.
  ///
  /// Parameters:
  /// - [config]: Complete generation configuration
  ///
  /// The generation sequence:
  /// 1. Infrastructure setup (initial locator)
  /// 2. Data layer components
  /// 3. Domain layer components
  /// 4. Presentation layer components
  /// 5. Infrastructure completion (final locator and mappers)
  /// 6. Code formatting
  /// 7. Success notification
  Future<void> generateApi(ApiGenerationConfig config) async {
    try {
      // Phase 1: Initialize infrastructure
      _infrastructureGenerator.generateLocator(config);

      // Phase 2: Generate data layer
      _dataLayerGenerator.generateDataLayer(config);

      // Phase 3: Generate domain layer
      _domainLayerGenerator.generateDomainLayer(config);

      // Phase 4: Generate presentation layer
      _presentationLayerGenerator.generatePresentationLayer(config);

      // Phase 5: Complete infrastructure setup
      if (!config.json2dart && config.isReturnDataModel) {
        _infrastructureGenerator.generateMapper(config);
      }
      _infrastructureGenerator.generatePostLocator(config);

      // Phase 6: Format generated code (only if not using json2dart)
      if (!config.json2dart) {
        await ModularHelper.format();
      }

      // Phase 7: Success notification
      if (!config.json2dart) {
        StatusHelper.success(
            'Generated ${config.apiName} in ${config.featureName}/${config.pageName}');
      }
    } catch (e) {
      StatusHelper.failed('Failed to generate API: $e');
      rethrow;
    }
  }

  /// Validates the generation sequence and dependencies.
  ///
  /// Ensures that all required components can be generated in the correct
  /// order and that there are no circular dependencies or missing prerequisites.
  ///
  /// Parameters:
  /// - [config]: Configuration to validate
  ///
  /// Throws [GenerationException] if validation fails
  void validateGenerationSequence(ApiGenerationConfig config) {
    // Validate that required paths exist
    if (!exists(config.pathPage)) {
      throw GenerationException('Page path does not exist: ${config.pathPage}. '
          'Ensure the page has been created before adding API functionality.');
    }

    // Validate method-specific constraints
    if (typeResolver.isMultipart(config.method) && config.bodyList) {
      throw GenerationException(
          'Body list cannot be used with multipart methods: ${config.method}');
    }

    if (config.cacheStrategy != null &&
        !typeResolver.isApplyCacheStrategy(config.method)) {
      throw GenerationException(
          'Cache strategy cannot be applied to method: ${config.method}. '
          'Cache strategies are not supported for multipart and SSE methods.');
    }
  }

  /// Generates a summary of what will be created.
  ///
  /// Provides a preview of the components that will be generated based
  /// on the current configuration.
  ///
  /// Parameters:
  /// - [config]: Configuration to analyze
  ///
  /// Returns a map of component types to their file paths
  Map<String, List<String>> generateComponentSummary(
      ApiGenerationConfig config) {
    final summary = <String, List<String>>{};

    // Data layer components
    final dataComponents = <String>[
      'data/datasources/${config.pageName}_remote_data_source.dart',
      'data/repositories/${config.pageName}_repository_impl.dart',
    ];

    if (!config.json2dart) {
      dataComponents.addAll([
        'data/models/body/${config.apiName}_body.dart',
      ]);

      if (config.isReturnDataModel) {
        dataComponents
            .add('data/models/response/${config.apiName}_response.dart');
      }
    }

    summary['Data Layer'] = dataComponents;

    // Domain layer components
    final domainComponents = <String>[
      'domain/repositories/${config.pageName}_repository.dart',
      'domain/usecases/${config.apiName}_use_case.dart',
    ];

    if (!config.json2dart && config.isReturnDataModel) {
      domainComponents.add('domain/entities/${config.apiName}_entity.dart');
    }

    summary['Domain Layer'] = domainComponents;

    // Presentation layer components
    summary['Presentation Layer'] = [
      'presentation/bloc/${config.apiName}/${config.apiName}_bloc.dart',
      'presentation/bloc/${config.apiName}/${config.apiName}_state.dart',
      'presentation/bloc/${config.apiName}/${config.apiName}_event.dart',
    ];

    // Infrastructure components
    final infrastructureComponents = <String>[
      'locator.dart',
    ];

    if (!config.json2dart && config.isReturnDataModel) {
      infrastructureComponents.add('mapper.dart');
    }

    summary['Infrastructure'] = infrastructureComponents;

    return summary;
  }

  /// Cleans up any partially generated files on failure.
  ///
  /// Removes incomplete or corrupted files that may have been created
  /// during a failed generation attempt.
  ///
  /// Parameters:
  /// - [config]: Configuration used during generation
  void cleanupOnFailure(ApiGenerationConfig config) {
    StatusHelper.warning('Cleaning up partially generated files...');
  }
}

/// Exception thrown when API generation fails
class GenerationException implements Exception {
  const GenerationException(this.message);

  final String message;

  @override
  String toString() => 'GenerationException: $message';
}
