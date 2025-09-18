import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

/// Manages analysis_options.yaml file creation for app modules.
///
/// This class handles creating the analysis_options.yaml file for new app modules
/// with standard linting configuration.
class AnalysisOptionsManager {
  /// Creates the analysis_options.yaml file for a new app module.
  ///
  /// This method creates a standard analysis_options.yaml file that includes
  /// the dev_dependency_manager's Flutter linting configuration.
  ///
  /// Parameters:
  /// - [pathApps]: The path to the new app module
  /// - [appsName]: The name of the new app module (unused but kept for consistency)
  static void addNewAnalysisOption(String pathApps, String appsName) {
    final analysisOptionsPath = p.join(pathApps, 'analysis_options.yaml');

    try {
      final content = '''include: package:dev_dependency_manager/flutter.yaml
    
# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''';

      analysisOptionsPath.write(content);
      StatusHelper.generated(analysisOptionsPath);
    } catch (e) {
      StatusHelper.failed('Failed to create analysis_options.yaml: $e');
    }
  }
}
