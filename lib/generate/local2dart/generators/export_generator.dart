import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/local2dart/generators/base_generator.dart';
import 'package:morpheme_cli/generate/local2dart/templates/export_template.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Generator for the main export file.
///
/// This generator creates the main library export file that
/// exports all generated classes for easy import.
class ExportGenerator extends BaseGenerator {
  /// Creates a new ExportGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  ExportGenerator(super.config, super.packagePath);

  @override
  Future<void> generate() async {
    await generateExportFile();
  }

  /// Generates the main export file.
  Future<void> generateExportFile() async {
    final exportStatements = _generateExportStatements();
    final path = join(packagePath, 'lib', 'local2dart.dart');
    final content = ExportTemplate.generate(exportStatements);
    await writeFile(path, content);
  }

  /// Generates export statements for all generated files.
  List<String> _generateExportStatements() {
    final export = <String>[];

    // Export core packages
    export.add("export 'package:sqflite/sqflite.dart' show ConflictAlgorithm;");
    export.add("export 'paginations/local_meta_pagination.dart';");
    export.add("export 'paginations/local_pagination.dart';");
    export.add("export 'utils/database_instance.dart';");
    export.add("export 'utils/query_helper.dart';");
    export.add("export 'utils/bulk_insert.dart';");
    export.add("export 'utils/bulk_update.dart';");
    export.add("export 'utils/bulk_delete.dart';");

    // Export table models and services
    config.table.forEach((tableName, tableConfig) {
      export.add("export 'models/${ReCase(tableName).snakeCase}_table.dart';");
      export.add(
          "export 'services/${ReCase(tableName).snakeCase}_local_service.dart';");
    });

    // Export query models
    config.query.forEach((tableName, queries) {
      if (queries is Map<String, dynamic>) {
        queries.forEach((queryName, query) {
          export.add(
              "export 'models/${ReCase(queryName).snakeCase}_query.dart';");
        });
      }
    });

    // Export view models
    config.view.forEach((viewName, view) {
      export.add("export 'models/${ReCase(viewName).snakeCase}_view.dart';");
    });

    return export;
  }
}
