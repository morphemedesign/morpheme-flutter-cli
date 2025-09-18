import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';
import 'package:morpheme_cli/generate/page/services/data_layer_generation_service.dart';
import 'package:morpheme_cli/generate/page/services/domain_layer_generation_service.dart';
import 'package:morpheme_cli/generate/page/services/presentation_layer_generation_service.dart';
import 'package:morpheme_cli/generate/page/services/locator_generation_service.dart';
import 'package:morpheme_cli/generate/page/services/page_validation_service.dart';

/// Orchestrates the page generation workflow.
///
/// This class coordinates the complete page generation process by:
/// - Managing the overall generation workflow
/// - Validating paths and inputs
/// - Generating all layer components (data, domain, presentation)
/// - Creating locator files
/// - Formatting generated code
/// - Handling errors gracefully with appropriate logging
class PageGenerationOrchestrator {
  /// The validation service for checking paths and inputs.
  final PageValidationService _validationService;

  /// The data layer generation service.
  final DataLayerGenerationService _dataService;

  /// The domain layer generation service.
  final DomainLayerGenerationService _domainService;

  /// The presentation layer generation service.
  final PresentationLayerGenerationService _presentationService;

  /// The locator generation service.
  final LocatorGenerationService _locatorService;

  /// Creates a new PageGenerationOrchestrator instance.
  ///
  /// Parameters:
  /// - [validationService]: Optional custom validation service for testing
  /// - [dataService]: Optional custom data layer service for testing
  /// - [domainService]: Optional custom domain layer service for testing
  /// - [presentationService]: Optional custom presentation layer service for testing
  /// - [locatorService]: Optional custom locator service for testing
  PageGenerationOrchestrator({
    PageValidationService? validationService,
    DataLayerGenerationService? dataService,
    DomainLayerGenerationService? domainService,
    PresentationLayerGenerationService? presentationService,
    LocatorGenerationService? locatorService,
  })  : _validationService = validationService ?? PageValidationService(),
        _dataService = dataService ?? DataLayerGenerationService(),
        _domainService = domainService ?? DomainLayerGenerationService(),
        _presentationService = presentationService ?? PresentationLayerGenerationService(),
        _locatorService = locatorService ?? LocatorGenerationService();

  /// Generates a complete page structure based on the configuration.
  ///
  /// This method coordinates the complete page generation workflow:
  /// 1. Validates paths and inputs
  /// 2. Generates data layer components
  /// 3. Generates domain layer components
  /// 4. Generates presentation layer components
  /// 5. Creates locator files
  /// 6. Updates feature locator
  /// 7. Formats generated code
  ///
  /// Parameters:
  /// - [config]: The configuration for page generation
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> generatePage(PageConfig config) async {
    try {
      // Validate paths
      if (!_validationService.validatePaths(config)) {
        return false;
      }

      // Generate page structure
      await _generatePageStructure(config);

      // Format generated code
      await _formatGeneratedCode(config);

      // Report success
      _reportSuccess(config);

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate page: $e');
      return false;
    }
  }

  /// Generates the complete page structure.
  ///
  /// Creates all directories, files, and content for the new page following
  /// Clean Architecture principles.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  Future<void> _generatePageStructure(PageConfig config) async {
    // Create all page components
    _dataService.createDataLayer(config);
    _domainService.createDomainLayer(config);
    _presentationService.createPresentationLayer(config);

    // Create locator files
    _locatorService.createLocatorFile(config);
    _locatorService.updateFeatureLocator(config);
  }

  /// Formats all generated code files.
  ///
  /// Uses ModularHelper to format the generated code according to
  /// project standards.
  ///
  /// Parameters:
  /// - [config]: Configuration containing path information
  Future<void> _formatGeneratedCode(PageConfig config) async {
    await ModularHelper.format([config.pathFeature]);
  }

  /// Reports successful completion of page generation.
  ///
  /// Displays a success message with details about what was generated.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation details
  void _reportSuccess(PageConfig config) {
    StatusHelper.success('generate page ${config.pageName} in feature ${config.featureName}');
  }
}