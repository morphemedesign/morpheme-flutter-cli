import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/local2dart/generators/base_generator.dart';
import 'package:morpheme_cli/generate/local2dart/templates/service_template.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Generator for service classes.
///
/// This generator creates service classes with CRUD operations
/// for each table defined in the configuration.
class ServiceGenerator extends BaseGenerator {
  /// Creates a new ServiceGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  ServiceGenerator(super.config, super.packagePath);

  @override
  Future<void> generate() async {
    await generateServices();
  }

  /// Generates service classes for all tables.
  Future<void> generateServices() async {
    config.table.forEach((tableName, tableConfig) async {
      if (tableConfig is Map<String, dynamic>) {
        final columns = tableConfig['column'] as Map<String, dynamic>? ?? {};
        final foreigns = tableConfig['foreign'] as Map<String, dynamic>? ?? {};
        final queries = config.getQueries(tableName);

        final result = _processTable(
          tableName: tableName,
          columns: columns,
          foreigns: foreigns,
          queries: queries,
        );

        await _generateService(
          tableName: tableName,
          primaryKey: result.primaryKey,
          typePrimaryKey: result.typePrimaryKey,
          variables: result.variables,
          queryWithJoins: result.queryWithJoins,
          tableJoins: result.tableJoins,
          importQueryModel: result.importQueryModel,
          customQuery: result.customQuery,
        );
      }
    });
  }

  /// Processes a table definition and generates service code snippets.
  _ServiceProcessingResult _processTable({
    required String tableName,
    required Map<String, dynamic> columns,
    required Map<String, dynamic> foreigns,
    required Map<String, dynamic> queries,
  }) {
    String primaryKey = '';
    String typePrimaryKey = '';

    final variables = <String>[];
    final queryWithJoins = <String>[];
    final tableJoins = <String>[];

    // Process columns
    columns.forEach((columnName, column) {
      if (column is Map &&
          column['constraint']?.toString().toUpperCase() == 'PRIMARY KEY') {
        primaryKey = ReCase(columnName).snakeCase;
        typePrimaryKey = getDartType(column['type']?.toString() ?? '');
      }

      variables.add(
          "static const String column${ReCase(columnName).pascalCase} = '${ReCase(columnName).snakeCase}';");
      queryWithJoins.add(
          "${ReCase(tableName).snakeCase}.${ReCase(columnName).snakeCase} as '${ReCase(tableName).snakeCase}.${ReCase(columnName).snakeCase}'");
    });

    // Process foreign keys
    foreigns.forEach((foreignName, foreign) {
      if (foreign is Map<String, dynamic>) {
        final String columnForeign = foreign['to_column'] ?? '';
        final String tableNameForeign = foreign['to_table'] ?? '';

        // Add columns from foreign table to queryWithJoins
        final foreignTable = config.getTable(tableNameForeign);
        if (foreignTable != null) {
          final foreignColumns =
              foreignTable['column'] as Map<String, dynamic>?;
          if (foreignColumns != null) {
            foreignColumns.forEach((key, value) {
              queryWithJoins.add(
                  "${ReCase(tableNameForeign).snakeCase}.${ReCase(key).snakeCase} as '${ReCase(tableNameForeign).snakeCase}.${ReCase(key).snakeCase}'");
            });
          }
        }

        tableJoins.add(
            'LEFT JOIN ${ReCase(tableNameForeign).snakeCase} ON ${ReCase(tableName).snakeCase}.${ReCase(foreignName).snakeCase} = ${ReCase(tableNameForeign).snakeCase}.${ReCase(columnForeign).snakeCase}');
      }
    });

    // Process custom queries
    final importQueryModel = <String>[];
    final customQuery = <String>[];

    queries.forEach((queryName, query) {
      if (query is Map<String, dynamic>) {
        importQueryModel.add(
          "import '../models/${ReCase(queryName).snakeCase}_query.dart';",
        );

        final where = query['where'] ?? '';

        final int whereArgsLength = RegExp(r'\?').allMatches(where).length;
        final whereArgsParams = List.generate(
            whereArgsLength, (index) => 'Object? args${index + 1},');
        final whereArgsImpl =
            List.generate(whereArgsLength, (index) => 'args${index + 1},');

        // Generate raw query (simplified version)
        final rawQuery =
            'SELECT * FROM ${ReCase(tableName).snakeCase}'; // Simplified

        customQuery.add(
            'static Future<List<${ReCase(queryName).pascalCase}Query>> ${ReCase(queryName).camelCase}(${whereArgsParams.join()}) async {\n'
            '        final db = await getDatabase();\n'
            '${whereArgsLength == 0 ? "" : "        final where = QueryHelper.whereQuery(\n          where: \"\$where\",\n          whereArgs: [${whereArgsImpl.join()}],\n        );\n"}'
            '        final query = await db.rawQuery("$rawQuery",);\n'
            '        List<${ReCase(queryName).pascalCase}Query> result = [];\n'
            '        for (var element in query) {\n'
            '          result.add(${ReCase(queryName).pascalCase}Query.fromMap(element));\n'
            '        }\n'
            '        return result;\n'
            '      }');
      }
    });

    return _ServiceProcessingResult(
      primaryKey: primaryKey,
      typePrimaryKey: typePrimaryKey,
      variables: variables,
      queryWithJoins: queryWithJoins,
      tableJoins: tableJoins,
      importQueryModel: importQueryModel,
      customQuery: customQuery,
    );
  }

  /// Generates a service class file.
  Future<void> _generateService({
    required String tableName,
    required String primaryKey,
    required String typePrimaryKey,
    required List<String> variables,
    required List<String> queryWithJoins,
    required List<String> tableJoins,
    required List<String> importQueryModel,
    required List<String> customQuery,
  }) async {
    final path = join(packagePath, 'lib', 'services',
        '${ReCase(tableName).snakeCase}_local_service.dart');
    final content = ServiceTemplate.generate(
      tableName: tableName,
      primaryKey: primaryKey,
      typePrimaryKey: typePrimaryKey,
      variables: variables,
      queryWithJoins: queryWithJoins,
      tableJoins: tableJoins,
      importQueryModel: importQueryModel,
      customQuery: customQuery,
    );
    await writeFile(path, content);
  }
}

/// Result of service processing.
class _ServiceProcessingResult {
  final String primaryKey;
  final String typePrimaryKey;
  final List<String> variables;
  final List<String> queryWithJoins;
  final List<String> tableJoins;
  final List<String> importQueryModel;
  final List<String> customQuery;

  _ServiceProcessingResult({
    required this.primaryKey,
    required this.typePrimaryKey,
    required this.variables,
    required this.queryWithJoins,
    required this.tableJoins,
    required this.importQueryModel,
    required this.customQuery,
  });
}
