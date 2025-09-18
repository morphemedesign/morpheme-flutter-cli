import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';
import '../templates/api_code_templates.dart';

/// Generates presentation layer components using BLoC pattern.
///
/// Creates BLoC, state, and event classes for managing API call states
/// and handling user interactions with proper stream or future handling.
class PresentationLayerGenerator {
  PresentationLayerGenerator({
    required this.typeResolver,
    required this.codeTemplates,
  });

  final ApiTypeResolver typeResolver;
  final ApiCodeTemplates codeTemplates;

  /// Generates complete presentation layer for the API.
  ///
  /// Components generated:
  /// - BLoC class with state management logic
  /// - State classes for different API call states
  /// - Event classes for triggering API operations
  /// - Proper stream/future handling based on method type
  void generatePresentationLayer(ApiGenerationConfig config) {
    generateBloc(config);
  }

  /// Generates BLoC pattern implementation.
  ///
  /// Creates the complete BLoC implementation with state, event, and main
  /// BLoC files that handle API operations with proper error handling
  /// and state management.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateBloc(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'presentation', 'bloc', config.apiName);
    createDir(path);

    // Generate state file
    final stateFilePath = join(path, '${config.apiName}_state.dart');
    final stateContent = codeTemplates.generateBlocStateTemplate(config);
    stateFilePath.write(stateContent);
    StatusHelper.generated(stateFilePath);

    // Generate event file
    final eventFilePath = join(path, '${config.apiName}_event.dart');
    final eventContent = codeTemplates.generateBlocEventTemplate(config);
    eventFilePath.write(eventContent);
    StatusHelper.generated(eventFilePath);

    // Generate main BLoC file
    final blocFilePath = join(path, '${config.apiName}_bloc.dart');
    final blocContent = codeTemplates.generateBlocTemplate(config);
    blocFilePath.write(blocContent);
    StatusHelper.generated(blocFilePath);
  }
}
