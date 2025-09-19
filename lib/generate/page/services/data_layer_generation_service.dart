import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Service for generating data layer components for pages.
///
/// This service handles the creation of all data layer components
/// for a new page, including data sources, models, and repositories.
class DataLayerGenerationService {
  /// Creates all data layer components for the page.
  ///
  /// Generates directories and placeholder files for:
  /// - Data sources
  /// - Model bodies
  /// - Model responses
  /// - Repositories
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void createDataLayer(PageConfig config) {
    _createDataDataSource(config);
    _createDataModelBody(config);
    _createDataModelResponse(config);
    _createDataRepository(config);
  }

  /// Generates a .gitkeep file in the specified directory.
  ///
  /// Creates the directory if it doesn't exist and adds a .gitkeep
  /// file to ensure the directory is tracked by Git.
  ///
  /// Parameters:
  /// - [path]: Path to the directory where .gitkeep should be created
  void _generateGitKeep(String path) {
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  /// Creates the data sources directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDataDataSource(PageConfig config) {
    final path = join(config.pathPage, 'data', 'datasources');
    _generateGitKeep(path);
  }

  /// Creates the model body directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDataModelBody(PageConfig config) {
    final path = join(config.pathPage, 'data', 'models', 'body');
    _generateGitKeep(path);
  }

  /// Creates the model response directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDataModelResponse(PageConfig config) {
    final path = join(config.pathPage, 'data', 'models', 'response');
    _generateGitKeep(path);
  }

  /// Creates the repositories directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDataRepository(PageConfig config) {
    final path = join(config.pathPage, 'data', 'repositories');
    _generateGitKeep(path);
  }
}
