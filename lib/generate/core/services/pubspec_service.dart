import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../models/package_configuration.dart';

/// Service for managing pubspec.yaml file operations
///
/// This service handles updating both the core pubspec.yaml file and
/// the root project pubspec.yaml file to include the new package.
class PubspecService {
  /// Updates the core pubspec.yaml to include the new package as a dependency
  ///
  /// [config] - Configuration for the package to add
  void updateCorePubspec(PackageConfiguration config) {
    try {
      String pubspec = File(join(current, 'core', 'pubspec.yaml')).readAsStringSync();
      pubspec = pubspec.replaceAll(
        RegExp(r'(^\n?dev_dependencies)', multiLine: true),
        '''  ${config.snakeCaseName}:
    path: ./packages/${config.snakeCaseName}

dev_dependencies''',
      );
      join(current, 'core', 'pubspec.yaml').write(pubspec);

      StatusHelper.generated(join(current, 'core', 'pubspec.yaml'));
    } catch (e) {
      StatusHelper.failed(
        'Failed to update core pubspec.yaml',
        suggestion: 'Check file permissions and ensure core/pubspec.yaml exists',
      );
      rethrow;
    }
  }

  /// Updates the root project pubspec.yaml to include the new package
  ///
  /// [config] - Configuration for the package to add
  void updateRootPubspec(PackageConfiguration config) {
    try {
      String pubspec = File(join(current, 'pubspec.yaml')).readAsStringSync();
      pubspec = pubspec.replaceAll(
        RegExp(r'(^\n?dependencies)', multiLine: true),
        '''  - core/packages/${config.snakeCaseName}

dependencies''',
      );
      join(current, 'pubspec.yaml').write(pubspec);

      StatusHelper.generated(join(current, 'pubspec.yaml'));
    } catch (e) {
      StatusHelper.failed(
        'Failed to update root pubspec.yaml',
        suggestion: 'Check file permissions and ensure pubspec.yaml exists',
      );
      rethrow;
    }
  }
}