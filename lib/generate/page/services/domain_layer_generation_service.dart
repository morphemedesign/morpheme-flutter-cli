import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Service for generating domain layer components for pages.
///
/// This service handles the creation of all domain layer components
/// for a new page, including entities, repositories, and use cases.
class DomainLayerGenerationService {
  /// Creates all domain layer components for the page.
  ///
  /// Generates directories and placeholder files for:
  /// - Entities
  /// - Repositories
  /// - Use cases
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void createDomainLayer(PageConfig config) {
    _createDomainEntity(config);
    _createDomainRepository(config);
    _createDomainUseCase(config);
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

  /// Creates the entities directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDomainEntity(PageConfig config) {
    final path = join(config.pathPage, 'domain', 'entities');
    _generateGitKeep(path);
  }

  /// Creates the domain repositories directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDomainRepository(PageConfig config) {
    final path = join(config.pathPage, 'domain', 'repositories');
    _generateGitKeep(path);
  }

  /// Creates the use cases directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createDomainUseCase(PageConfig config) {
    final path = join(config.pathPage, 'domain', 'usecases');
    _generateGitKeep(path);
  }
}
