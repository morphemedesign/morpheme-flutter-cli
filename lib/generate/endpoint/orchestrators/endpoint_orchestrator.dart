import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/endpoint/models/endpoint_config.dart';
import 'package:morpheme_cli/generate/endpoint/services/endpoint_service.dart';

/// Orchestrates the endpoint generation workflow.
///
/// This class coordinates all the steps needed to generate endpoint files,
/// delegating to the specialized service class for the core operations.
class EndpointOrchestrator {
  /// Service for handling endpoint generation logic.
  final EndpointService _endpointService;

  /// Creates a new EndpointOrchestrator instance.
  ///
  /// Initializes all required service dependencies.
  EndpointOrchestrator({
    EndpointService? endpointService,
  }) : _endpointService = endpointService ?? EndpointService();

  /// Executes the complete endpoint generation workflow.
  ///
  /// This method coordinates all the steps needed to generate endpoint files:
  /// 1. Delete old endpoint files
  /// 2. Generate new endpoint methods
  /// 3. Format the generated code
  ///
  /// Parameters:
  /// - [config]: The endpoint configuration
  ///
  /// Returns true if the generation was successful, false otherwise.
  Future<bool> execute(EndpointConfig config) async {
    try {
      printMessage('🚀 Generating endpoints...');
      
      // Delete old endpoint files
      final pathDir = join(
        current,
        'core',
        'lib',
        'src',
        'data',
        'remote',
      );
      _endpointService.deleteOldEndpoints(pathDir);

      // Generate new endpoints
      await _endpointService.generateEndpoints(config);

      printMessage('✅ Endpoint generation completed successfully');
      return true;
    } catch (e) {
      StatusHelper.failed('Endpoint generation failed: $e');
      return false;
    }
  }
}