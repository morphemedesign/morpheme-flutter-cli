import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/local2dart/generators/base_generator.dart';
import 'package:morpheme_cli/generate/local2dart/templates/core_template.dart';

/// Generator for core utility classes.
///
/// This generator creates core utility classes such as
/// pagination models, query helpers, and bulk operation models.
class CoreGenerator extends BaseGenerator {
  /// Creates a new CoreGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  CoreGenerator(super.config, super.packagePath);

  @override
  Future<void> generate() async {
    await generateCoreUtilities();
  }

  /// Generates core utility classes.
  Future<void> generateCoreUtilities() async {
    // Create directories
    createDir(join(packagePath, 'lib', 'paginations'));
    createDir(join(packagePath, 'lib', 'utils'));

    // Generate pagination models
    await _generatePaginationModels();

    // Generate query helper
    await _generateQueryHelper();

    // Generate bulk operation models
    await _generateBulkOperationModels();
  }

  /// Generates pagination model classes.
  Future<void> _generatePaginationModels() async {
    // Generate LocalMetaPagination
    final metaPaginationPath =
        join(packagePath, 'lib', 'paginations', 'local_meta_pagination.dart');
    final metaPaginationContent = CoreTemplate.generateLocalMetaPagination();
    await writeFile(metaPaginationPath, metaPaginationContent);

    // Generate LocalPagination
    final paginationPath =
        join(packagePath, 'lib', 'paginations', 'local_pagination.dart');
    final paginationContent = CoreTemplate.generateLocalPagination();
    await writeFile(paginationPath, paginationContent);
  }

  /// Generates the query helper class.
  Future<void> _generateQueryHelper() async {
    final queryHelperPath =
        join(packagePath, 'lib', 'utils', 'query_helper.dart');
    final queryHelperContent = CoreTemplate.generateQueryHelper();
    await writeFile(queryHelperPath, queryHelperContent);
  }

  /// Generates bulk operation model classes.
  Future<void> _generateBulkOperationModels() async {
    // Generate BulkInsert
    final bulkInsertPath =
        join(packagePath, 'lib', 'utils', 'bulk_insert.dart');
    final bulkInsertContent = CoreTemplate.generateBulkInsert();
    await writeFile(bulkInsertPath, bulkInsertContent);

    // Generate BulkUpdate
    final bulkUpdatePath =
        join(packagePath, 'lib', 'utils', 'bulk_update.dart');
    final bulkUpdateContent = CoreTemplate.generateBulkUpdate();
    await writeFile(bulkUpdatePath, bulkUpdateContent);

    // Generate BulkDelete
    final bulkDeletePath =
        join(packagePath, 'lib', 'utils', 'bulk_delete.dart');
    final bulkDeleteContent = CoreTemplate.generateBulkDelete();
    await writeFile(bulkDeletePath, bulkDeleteContent);
  }
}
