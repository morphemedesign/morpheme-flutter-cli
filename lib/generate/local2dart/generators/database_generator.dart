import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/local2dart/generators/base_generator.dart';
import 'package:morpheme_cli/generate/local2dart/templates/database_template.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Generator for database instance code.
///
/// This generator creates the database instance class that handles
/// database initialization, table creation, and seed data insertion.
class DatabaseGenerator extends BaseGenerator {
  /// Creates a new DatabaseGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  DatabaseGenerator(super.config, super.packagePath);

  @override
  Future<void> generate() async {
    await generateDatabaseInstance();
  }

  /// Generates the database instance class.
  Future<void> generateDatabaseInstance() async {
    final dbPath = join(packagePath, 'lib', 'utils', 'database_instance.dart');
    final content = DatabaseTemplate.generate(
      dirDatabase: config.dirDatabase,
      foreignKeyConstrainSupport: config.foreignKeyConstrainSupport,
      version: config.version,
      tableCreationSql: _generateTableCreationSql(),
      viewCreationSql: _generateViewCreationSql(),
      triggerCreationSql: _generateTriggerCreationSql(),
      seedSql: _generateSeedSql(),
    );
    await writeFile(dbPath, content);
  }

  /// Generates SQL for table creation.
  String _generateTableCreationSql() {
    final buffer = StringBuffer();
    config.table.forEach((tableName, tableConfig) {
      if (tableConfig is Map<String, dynamic>) {
        final sql = _generateTableSql(
          name: tableName,
          createIfNotExists:
              tableConfig['create_if_not_exists'] as bool? ?? true,
          columns: tableConfig['column'] as Map<String, dynamic>? ?? {},
          foreignKeys: tableConfig['foreign'] as Map<String, dynamic>? ?? {},
        );
        buffer.writeln("await db.execute('$sql');");
      }
    });
    return buffer.toString();
  }

  /// Generates SQL for a single table.
  String _generateTableSql({
    required String name,
    required bool createIfNotExists,
    required Map<String, dynamic> columns,
    required Map<String, dynamic> foreignKeys,
  }) {
    final createTable =
        createIfNotExists ? 'CREATE TABLE IF NOT EXISTS' : 'CREATE TABLE';

    final bufferColumn = <String>[];
    columns.forEach((columnName, column) {
      if (column is String) {
        // Simple type definition
        String type = column;
        final isTypeBool = type == 'BOOL';
        if (isTypeBool) {
          type = 'INTEGER';
        }
        bufferColumn
            .add('${ReCase(columnName).snakeCase} ${type.toUpperCase()}');
      } else if (column is Map) {
        // Detailed definition
        String type = column['type'].toString().toUpperCase();
        final isTypeBool = type == 'BOOL';
        if (isTypeBool) {
          type = 'INTEGER';
        }

        final String constraint = column['constraint'] != null
            ? ' ${column['constraint'].toString().toUpperCase()}'
            : '';

        final String autoincrement =
            (column['autoincrement'] as bool? ?? false) == true
                ? ' AUTOINCREMENT'
                : '';

        final String nullable =
            (column['nullable'] as bool? ?? true) == true ? '' : ' NOT NULL';

        String defaultValue =
            column['default'] != null ? ' DEFAULT ${column['default']}' : '';
        if (isTypeBool && column['default'] != null) {
          final value = column['default'] == true ? 1 : 0;
          defaultValue = ' DEFAULT $value';
        }

        bufferColumn.add(
            '${ReCase(columnName).snakeCase} $type$constraint$autoincrement$nullable$defaultValue');
      }
    });

    final relation = <String>[];
    foreignKeys.forEach((foreignKey, foreign) {
      if (foreign is Map<String, dynamic>) {
        final String toTable = ReCase(foreign['to_table'].toString()).snakeCase;
        final String toColumn =
            ReCase(foreign['to_column'].toString()).snakeCase;
        final String onUpdate = foreign['on_update'] != null
            ? ' ON UPDATE ${foreign['on_update'].toString().toUpperCase()}'
            : '';
        final String onDelete = foreign['on_delete'] != null
            ? ' ON DELETE ${foreign['on_delete'].toString().toUpperCase()}'
            : '';

        relation.add(
            'FOREIGN KEY (${ReCase(foreignKey.toString()).snakeCase}) REFERENCES $toTable ($toColumn)$onUpdate$onDelete');
      }
    });

    return '$createTable ${name.snakeCase} (${bufferColumn.join(', ')}${relation.isEmpty ? '' : ', ${relation.join(', ')}'})';
  }

  /// Generates SQL for view creation.
  String _generateViewCreationSql() {
    final bufferView = StringBuffer();
    config.view.forEach((viewName, view) {
      if (view is Map<String, dynamic>) {
        final rawQuery = _getRawQuery(
          distinct: view['disticnt'] ?? false,
          column: view['column'],
          from: view['from'],
          join: view['join'],
          where: view['where'],
          isWhereArgs: false,
          orderBy: view['order_by'],
          limit: view['limit'],
          offset: view['offset'],
          groupBy: view['group_by'],
          having: view['having'],
        );

        final createView = (view['create_if_not_exists'] as bool? ?? true)
            ? 'CREATE VIEW IF NOT EXISTS'
            : 'CREATE VIEW';

        final rawView =
            '$createView ${ReCase(viewName.toString()).snakeCase}_view AS $rawQuery';

        bufferView.writeln("await db.execute('$rawView');");
      }
    });
    return bufferView.toString();
  }

  /// Generates SQL for trigger creation.
  String _generateTriggerCreationSql() {
    final bufferTrigger = StringBuffer();
    config.trigger.forEach((triggerName, trigger) {
      if (trigger is Map<String, dynamic>) {
        String rawSql = trigger['raw_sql'] ?? '';
        rawSql = rawSql.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (rawSql.contains("'")) {
          rawSql = rawSql.replaceAll("'", r"\'");
        }

        bufferTrigger.writeln("await db.execute('$rawSql');");
      }
    });
    return bufferTrigger.toString();
  }

  /// Generates SQL for seed data insertion.
  String _generateSeedSql() {
    final buffer = StringBuffer();
    config.seed.forEach((tableName, seedData) {
      if (seedData is Map<String, dynamic>) {
        final columns = seedData['column'] as List?;
        final values = seedData['value'] as List?;

        if (columns != null && values != null) {
          final sqlValue = <String>[];
          for (var element in values) {
            final split = element.toString().split(',');

            final types = <String>[];
            for (var value in split) {
              if (RegExp(r'^\d+$').hasMatch(value) ||
                  RegExp(r'^\d+\.{\d+}$').hasMatch(value)) {
                types.add(value);
              } else if (RegExp(r'^true$').hasMatch(value)) {
                types.add('1');
              } else if (RegExp(r'^false$').hasMatch(value)) {
                types.add('0');
              } else {
                types.add('"$value"');
              }
            }

            sqlValue.add('(${types.join(', ')})');
          }

          buffer.writeln(
            "await db.execute('INSERT INTO ${ReCase(tableName.toString()).snakeCase} (${columns.join(', ')}) VALUES ${sqlValue.join(', ')};');",
          );
        }
      }
    });
    return buffer.toString();
  }

  /// Generates a raw SQL query.
  String _getRawQuery({
    required bool distinct,
    required dynamic column,
    required dynamic from,
    required dynamic join,
    required dynamic where,
    required bool isWhereArgs,
    required dynamic orderBy,
    required dynamic limit,
    required dynamic offset,
    required dynamic groupBy,
    required dynamic having,
  }) {
    final select = distinct ? 'SELECT DISTINCT' : 'SELECT';

    final columnList = <String>[];
    if (column is Map) {
      column.forEach((key, value) {
        final origin = value['origin'];
        if (origin == null) return;
        columnList.add("$origin as '${ReCase(key.toString()).snakeCase}'");
      });
    }

    final joins = <String>[];
    if (join is String) {
      joins.add(join);
    } else if (join is List) {
      joins.addAll(List<String>.from(join));
    }

    final whereQuery = isWhereArgs
        ? where ?? ''
        : where != null
            ? 'WHERE $where'
            : '';

    final orderByQuery = orderBy != null ? 'ORDER BY $orderBy' : '';
    final limitQuery = limit != null ? 'LIMIT $limit' : '';
    final offsetQuery = offset != null ? 'OFFSET $offset' : '';
    final groupByQuery = groupBy != null ? 'GROUP BY $groupBy' : '';
    final havingQuery = having != null ? 'HAVING $having' : '';

    final int whereArgsLength = RegExp(r'\?').allMatches(whereQuery).length;

    String rawQuery =
        '$select ${columnList.join(', ')} FROM ${from.toString().snakeCase} ${joins.join(' ')} ${isWhereArgs && whereArgsLength > 0 ? '\$where' : whereQuery} $orderByQuery $groupByQuery $limitQuery $offsetQuery $havingQuery;'
            .replaceAll(RegExp(r'\s+'), ' ');
    return rawQuery;
  }
}
