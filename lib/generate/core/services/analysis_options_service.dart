import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../models/package_configuration.dart';

/// Service for managing analysis_options.yaml file setup
///
/// This service handles creating and configuring the analysis_options.yaml file
/// for the new core package to ensure consistent code analysis rules.
class AnalysisOptionsService {
  /// Sets up the analysis_options.yaml file for the new package
  ///
  /// [config] - Configuration for the package
  void setup(PackageConfiguration config) {
    try {
      config.analysisOptionsPath.write('''include: package:dev_dependency_manager/flutter.yaml
    
# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''');
    } catch (e) {
      StatusHelper.failed(
        'Failed to setup analysis_options.yaml file',
        suggestion: 'Check file permissions and available disk space',
      );
      rethrow;
    }
  }
}