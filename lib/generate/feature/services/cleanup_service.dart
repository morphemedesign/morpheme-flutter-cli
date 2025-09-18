import 'package:morpheme_cli/dependency_manager.dart';

/// Service for cleaning up unnecessary directories in feature packages.
///
/// This service removes platform-specific directories that are not needed
/// for Flutter package modules.
class CleanupService {
  /// Removes unused platform directories from the feature package.
  ///
  /// This method cleans up directories like android, ios, web, etc. that are
  /// created by default but not needed for Flutter package modules.
  void removeUnusedDirs(String pathFeature, String featureName, String appsName) {
    for (var element in [
      join(pathFeature, 'android'),
      join(pathFeature, 'ios'),
      join(pathFeature, 'web'),
      join(pathFeature, 'macos'),
      join(pathFeature, 'linux'),
      join(pathFeature, 'windows'),
    ]) {
      if (exists(element)) {
        deleteDir(element);
      }
    }
  }
}