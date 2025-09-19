import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/feature/models/feature_config.dart';
import 'package:morpheme_cli/generate/feature/services/feature_package_service.dart';
import 'package:morpheme_cli/generate/feature/services/locator_service.dart';
import 'package:morpheme_cli/generate/feature/services/pubspec_service.dart';
import 'package:morpheme_cli/generate/feature/services/configuration_service.dart';
import 'package:morpheme_cli/generate/feature/services/cleanup_service.dart';

/// Orchestrates the feature generation workflow.
///
/// This class coordinates all the steps needed to create a new feature module,
/// delegating to specialized service classes for each operation.
class FeatureOrchestrator {
  /// Service for creating feature packages.
  final FeaturePackageService _packageService;

  /// Service for updating locator files.
  final LocatorService _locatorService;

  /// Service for updating pubspec files.
  final PubspecService _pubspecService;

  /// Service for setting up configuration files.
  final ConfigurationService _configurationService;

  /// Service for cleaning up unnecessary directories.
  final CleanupService _cleanupService;

  /// Creates a new FeatureOrchestrator instance.
  ///
  /// Initializes all required service dependencies.
  FeatureOrchestrator({
    FeaturePackageService? packageService,
    LocatorService? locatorService,
    PubspecService? pubspecService,
    ConfigurationService? configurationService,
    CleanupService? cleanupService,
  })  : _packageService = packageService ?? FeaturePackageService(),
        _locatorService = locatorService ?? LocatorService(),
        _pubspecService = pubspecService ?? PubspecService(),
        _configurationService = configurationService ?? ConfigurationService(),
        _cleanupService = cleanupService ?? CleanupService();

  /// Executes the complete feature generation workflow.
  ///
  /// This method coordinates all the steps needed to create a new feature module:
  /// 1. Create the feature package
  /// 2. Update locator files
  /// 3. Update pubspec files
  /// 4. Set up configuration files
  /// 5. Clean up unnecessary directories
  /// 6. Format code and run pub get
  ///
  /// Returns true if the generation was successful, false otherwise.
  Future<bool> execute(FeatureConfig config) async {
    try {
      printMessage('🚀 Creating feature package...');
      await _packageService.createFeaturePackage(
          config.featurePath, config.featureName, config.appsName);

      printMessage('🔗 Updating locator...');
      _locatorService.addFeatureToLocator(
          config.featurePath, config.featureName, config.appsName);

      printMessage('📦 Updating pubspec...');
      _pubspecService.addFeatureToPubspec(
          config.featurePath, config.featureName, config.appsName);

      printMessage('⚙️ Setting up configuration files...');
      _configurationService.setupGitIgnore(
          config.featurePath, config.featureName, config.appsName);
      _configurationService.setupAnalysisOptions(
          config.featurePath, config.featureName, config.appsName);

      printMessage('🧹 Cleaning up...');
      _cleanupService.removeUnusedDirs(
          config.featurePath, config.featureName, config.appsName);

      printMessage('✨ Formatting code...');
      await ModularHelper.format([
        config.featurePath,
        join(current, 'lib'),
        if (config.appsName.isEmpty) '.',
        if (config.appsName.isNotEmpty) config.appsPath,
      ]);

      printMessage('📥 Running pub get...');
      await FlutterHelper.start('pub get',
          workingDirectory: config.featurePath);
      await FlutterHelper.start('pub get',
          workingDirectory: config.appsName.isEmpty ? '.' : config.appsPath);

      return true;
    } catch (e) {
      StatusHelper.failed('Feature generation failed: $e');
      return false;
    }
  }
}
