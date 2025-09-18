import 'package:morpheme_cli/dependency_manager.dart';

/// Service for handling template test file and directory operations.
///
/// This class provides methods for creating directory structures and
/// managing file system operations related to template test generation.
class TemplateTestService {
  /// Creates the data test directory structure.
  ///
  /// Parameters:
  /// - [pathTestPage]: Base path for test files
  /// - [featureName]: Name of the feature
  /// - [pageName]: Name of the page
  void createDataTest(
    String pathTestPage,
    String featureName,
    String pageName,
  ) {
    final dirs = [
      'datasources',
      'model/body',
      'model/response',
      'repositories'
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'data', dir);
      createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }
  }

  /// Creates the domain test directory structure.
  ///
  /// Parameters:
  /// - [pathTestPage]: Base path for test files
  /// - [featureName]: Name of the feature
  /// - [pageName]: Name of the page
  void createDomainTest(
    String pathTestPage,
    String featureName,
    String pageName,
  ) {
    final dirs = [
      'entities',
      'repositories',
      'usecases',
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'domain', dir);
      createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }
  }

  /// Creates the presentation test directory structure.
  ///
  /// Parameters:
  /// - [pathTestPage]: Base path for test files
  /// - [featureName]: Name of the feature
  /// - [pageName]: Name of the page
  /// - [json2DartMap]: JSON to Dart configuration map
  void createPresentationTest(
    String pathTestPage,
    String featureName,
    String pageName,
    Map json2DartMap,
  ) {
    final dirs = [
      'bloc',
      'cubit',
      'pages',
      'widgets',
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'presentation', dir);
      createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }
  }
}