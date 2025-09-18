import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../models/package_configuration.dart';

/// Service for creating Flutter packages in the core directory
///
/// This service handles the creation of new Flutter packages including
/// setting up the initial directory structure and cleaning up unnecessary files.
class CorePackageService {
  /// Creates a new Flutter package using the Flutter CLI
  ///
  /// [config] - Configuration for the package to create
  ///
  /// Throws [ProcessException] if the Flutter command fails
  /// Throws [FileSystemException] if file operations fail
  Future<void> createFlutterPackage(PackageConfiguration config) async {
    try {
      // Execute Flutter create command
      await FlutterHelper.run(
          'create --template=package "core/packages/${config.snakeCaseName}"');

      // Customize pubspec.yaml
      _customizePubspec(config);

      // Setup directory structure
      _setupDirectories(config);

      // Clean up unnecessary files
      _cleanupUnnecessaryFiles(config);

      StatusHelper.generated(config.path);
    } on ProcessException {
      // Handle process execution errors
      StatusHelper.failed(
        'Failed to create Flutter package',
        suggestion: 'Ensure Flutter is properly installed and accessible',
        examples: ['flutter --version', 'flutter doctor'],
      );
      rethrow;
    } on FileSystemException {
      // Handle file system errors
      StatusHelper.failed(
        'Failed to modify package files',
        suggestion: 'Check file permissions and available disk space',
      );
      rethrow;
    }
  }

  /// Customizes the pubspec.yaml file for the new package
  ///
  /// [config] - Configuration for the package
  void _customizePubspec(PackageConfiguration config) {
    config.pubspecPath.write('''name: ${config.name}
description: A new Flutter package project.
version: 0.0.1

publish_to: "none"

environment:
  sdk: "^3.6.0"
  flutter: "^3.27.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  dev_dependency_manager:
    path: ../dev_dependency_manager

flutter:''');
  }

  /// Sets up the initial directory structure for the package
  ///
  /// [config] - Configuration for the package
  void _setupDirectories(PackageConfiguration config) {
    // Delete existing lib and test directories if they exist
    final libDir = join(config.path, 'lib');
    final testDir = join(config.path, 'test');

    if (exists(libDir)) {
      deleteDir(libDir);
    }
    if (exists(testDir)) {
      deleteDir(testDir);
    }

    // Recreate lib and test directories
    createDir(libDir);
    createDir(testDir);

    // Add .gitkeep files to ensure directories are tracked
    touch(join(libDir, '.gitkeep'), create: true);
    touch(join(testDir, '.gitkeep'), create: true);
  }

  /// Cleans up unnecessary platform-specific directories
  ///
  /// [config] - Configuration for the package
  void _cleanupUnnecessaryFiles(PackageConfiguration config) {
    // Remove platform-specific directories that aren't needed for packages
    for (var element in [
      join(config.path, 'android'),
      join(config.path, 'ios'),
      join(config.path, 'web'),
      join(config.path, 'macos'),
      join(config.path, 'linux'),
      join(config.path, 'windows'),
    ]) {
      if (exists(element)) {
        deleteDir(element);
      }
    }
  }
}
