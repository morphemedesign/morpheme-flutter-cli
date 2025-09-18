import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Service for updating pubspec.yaml with feature dependencies.
///
/// This service handles adding the feature to the main pubspec.yaml file
/// as both a dependency and in the assets section.
class PubspecService {
  /// Adds the feature to the main pubspec.yaml file.
  ///
  /// This method updates the pubspec.yaml to include the feature as both
  /// a dependency and in the assets section.
  void addFeatureToPubspec(String pathFeature, String featureName, String appsName) {
    String pathPubspec = join(current, 'pubspec.yaml');

    if (!exists(pathPubspec)) {
      return;
    }
    
    String pubspec = File(pathPubspec).readAsStringSync();
    
    // Add to assets section
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dependencies)', multiLine: true),
      '''  - features/$featureName

dependencies''',
    );
    
    // Add as dependency
    pubspec = pubspec.replaceAll(
      RegExp(r'(^\n?dev_dependencies)', multiLine: true),
      '''  $featureName:
    path: ./features/$featureName

dev_dependencies''',
    );
    
    pathPubspec.write(pubspec);
    StatusHelper.generated(pathPubspec);
  }
}