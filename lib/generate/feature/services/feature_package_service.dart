import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Service for creating and configuring Flutter feature packages.
///
/// This service handles the creation of new Flutter packages for features,
/// including setting up the pubspec.yaml, directory structure, and initial files.
class FeaturePackageService {
  /// Creates a new Flutter package for the feature.
  ///
  /// This method creates the package directory structure, initializes the pubspec.yaml,
  /// and sets up the basic files needed for a feature module.
  Future<void> createFeaturePackage(
      String pathFeature, String featureName, String appsName) async {
    await FlutterHelper.run('create --template=package "$pathFeature"');

    // Update pubspec.yaml with feature-specific configuration
    final pubspecPath = join(pathFeature, 'pubspec.yaml');
    pubspecPath.write('''name: $featureName
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

  core:
    path: ${appsName.isEmpty ? "../../core" : "../../../../core"}

dev_dependencies:
  dev_dependency_manager:
    path: ${appsName.isEmpty ? "../../core/packages/dev_dependency_manager" : "../../../../core/packages/dev_dependency_manager"}

flutter:
  uses-material-design: true
''');

    // Clean up default directories and create new structure
    deleteDir(join(pathFeature, 'lib'), recursive: true);
    deleteDir(join(pathFeature, 'test'), recursive: true);

    createDir(join(pathFeature, 'lib'), recursive: true);
    createDir(join(pathFeature, 'test'), recursive: true);

    // Create a placeholder file to ensure the test directory is tracked by git
    touch(join(pathFeature, 'test', '.gitkeep'), create: true);

    // Create the locator file
    final locatorPath = join(pathFeature, 'lib', 'locator.dart');
    locatorPath.write('''//
// Generated file. Edit just you manually add or delete a page.
//

void setupLocatorFeature${featureName.pascalCase}() {

}''');

    StatusHelper.generated(pathFeature);
    StatusHelper.generated(locatorPath);
  }
}
