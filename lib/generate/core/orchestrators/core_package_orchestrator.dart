import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../models/package_configuration.dart';
import '../services/analysis_options_service.dart';
import '../services/core_package_service.dart';
import '../services/gitignore_service.dart';
import '../services/pubspec_service.dart';

/// Orchestrates the core package creation workflow
///
/// This orchestrator coordinates the package creation process by managing
/// the sequence of operations and handling errors and rollback scenarios.
class CorePackageOrchestrator {
  /// Creates a new core package with all required setup
  ///
  /// [packageName] - Name of the package to create
  ///
  /// Throws exceptions if any step fails
  Future<void> createPackage(String packageName) async {
    try {
      // Create configuration
      final config = PackageConfiguration(name: packageName);

      if (exists(config.path)) {
        throw 'Package already exists with the name $packageName';
      }

      // Create package structure
      final corePackageService = CorePackageService();
      await corePackageService.createFlutterPackage(config);

      // Update pubspec files
      final pubspecService = PubspecService();
      pubspecService.updateCorePubspec(config);
      pubspecService.updateRootPubspec(config);

      // Setup configuration files
      final gitIgnoreService = GitIgnoreService();
      gitIgnoreService.setup(config);

      final analysisOptionsService = AnalysisOptionsService();
      analysisOptionsService.setup(config);
    } catch (e) {
      StatusHelper.failed(
        'Failed to create core package: $e',
        suggestion: 'Check the error message above for details',
      );
      rethrow;
    }
  }
}
