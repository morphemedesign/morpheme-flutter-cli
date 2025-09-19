import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Service for validating page generation inputs and paths.
///
/// This service handles all validation logic for page generation,
/// including checking for existing pages, validating feature existence,
/// and ensuring required directories exist.
class PageValidationService {
  /// Validates paths and checks for conflicts.
  ///
  /// Ensures required directories exist and the target page doesn't already exist.
  ///
  /// Parameters:
  /// - [config]: Configuration containing path information
  ///
  /// Returns true if validation passes, false otherwise.
  bool validatePaths(PageConfig config) {
    // Validate apps context if specified
    if (config.appsName.isNotEmpty && !exists(config.pathApps)) {
      StatusHelper.failed(
          'Apps with "${config.appsName}" does not exists, create a new apps with "morpheme apps <apps-name>"');
      return false;
    }

    // Validate feature exists
    if (!exists(config.pathFeature)) {
      StatusHelper.failed(
          'Feature with "${config.featureName}" does not exists, create a new feature with "morpheme feature <feature-name>"');
      return false;
    }

    // Check for existing page
    if (exists(config.pathPage)) {
      StatusHelper.failed('Page already exists.');
      return false;
    }

    return true;
  }
}
