import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class Local2DartCommand extends Command {
  @override
  String get name => 'local2dart';

  @override
  String get description => 'Generate sqlite yaml to dart sqlite class helper';

  @override
  String get category => Constants.generate;

  Map local2dart = {};

  @override
  void run() async {
    if (argResults?.rest.firstOrNull == 'init') {
      init();
      return;
    }

    final pathPackageLocal2dart =
        join(current, 'core', 'packages', 'local2dart');
    if (!exists(pathPackageLocal2dart)) {
      'morpheme core local2dart'.run;
      FlutterHelper.start('pub add sqflite path equatable',
          workingDirectory: join(pathPackageLocal2dart));
    }

    local2dart =
        YamlHelper.loadFileYaml(join(current, 'local2dart', 'local2dart.yaml'));

    generateCore(pathPackageLocal2dart);
    generateTableHelper(pathPackageLocal2dart);
    generateQueryTableHelper(pathPackageLocal2dart);
    generateViewHelper(pathPackageLocal2dart);
    generateService(pathPackageLocal2dart);
    generateDatabaseInstance(pathPackageLocal2dart);
    generateLocal2dart(pathPackageLocal2dart);

    '${FlutterHelper.getCommandDart()} format .'
        .start(workingDirectory: pathPackageLocal2dart);

    StatusHelper.success('morpheme local2dart');
  }

  void init() {
    final path = join(current, 'local2dart');
    DirectoryHelper.createDir(path, recursive: true);

    if (!exists(join(path, 'local2dart.yaml'))) {
      join(path, 'local2dart.yaml').write('''# local2dart
#
# Version: Version database
# Dir Database: Directory for open database by default value is morpheme
# Foreign Key Constrain Support: boolean by default value is true
#
# table:
#   create_if_not_exists: bool, by default is true
#   column:
#     type: INTEGER, REAL, TEXT, BLOB, BOOL
#     constraint: PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK
#     autoincrement: boolean by default value is null
#     nullable: boolean by default value is true
#     default: Default value if insert with null
#  foreign:
#    column_name:
#      to_table: references table
#      to_column: references column
#      on_update: constraint actions values SET NULL, SET DEFAULT, RESTRICT, NO ACTION, CASCADE
#      on_update: constraint actions values SET NULL, SET DEFAULT, RESTRICT, NO ACTION, CASCADE
#
# query:
#   table_name:
#     custom_query_name:
#       disticnt: boolean by default value is false
#       column:
#         example_id:
#           type: "INTEGER"
#           origin: "id"
#         example_name:
#           type: "TEXT"
#           origin: "name"
#         example_total:
#           type: "INT"
#           origin: "SUM(quantity)"
#         example_count:
#           type: "INT"
#           origin: "count(*)"
#       join:
#          - "INNER JOIN example ON example.id = table_name.example_id"
#       where: "create_at BEETWEEN ? AND ?"
#       group_by: "example_id"
#       order_by: ""
#       limit: 10
#       offset: 0
#       having: ""
#
# seed:
#   status:
#     column:
#       - "id"
#       - "name"
#     value:
#       - "1,pending"
#       - "2,onprogress"
#       - "3,done"
#       - "4,cancel"
#
# view:
#   view_name:
#     create_if_not_exists: bool, by default is true
#     disticnt: boolean by default value is false
#     column:
#       example_id:
#         type: "INTEGER"
#         origin: "id"
#       example_name:
#         type: "TEXT"
#         origin: "name"
#       example_total:
#         type: "INT"
#         origin: "SUM(quantity)"
#       example_count:
#         type: "INT"
#         origin: "count(*)"
#     from: table_name
#     join:
#         - "INNER JOIN example ON example.id = table_name.example_id"
#     where: "create_at BEETWEEN ? AND ?"
#     group_by: "example_id"
#     order_by: ""
#     limit: 10
#     offset: 0
#     having: ""
# 
# trigger:
#   example:
#     raw_sql: >
#       CREATE TRIGGER [IF NOT EXISTS] trigger_name
#         [BEFORE|AFTER|INSTEAD OF] [INSERT|UPDATE|DELETE]
#         ON table_name
#         [WHEN condition]
#       BEGIN
#         statements;
#       END;
#   validate_email_before_insert_user:
#     raw_sql: >
#       CREATE TRIGGER validate_email_before_insert_users
#         BEFORE INSERT ON users
#       BEGIN
#         SELECT
#             CASE
#         WHEN NEW.email NOT LIKE '%_@__%.__%' THEN
#             RAISE (ABORT,'Invalid email address')
#             END;
#       END;
#   log_contact_after_update:
#     raw_sql: >
#       CREATE TRIGGER log_contact_after_update
#         AFTER UPDATE ON users
#         WHEN old.phone <> new.phone
#               OR old.email <> new.email
#       BEGIN
#         INSERT INTO lead_logs (
#           old_id,
#           new_id,
#           old_phone,
#           new_phone,
#           old_email,
#           new_email,
#           user_action,
#           created_at
#         )
#       VALUES
#         (
#           old.id,
#           new.id,
#           old.phone,
#           new.phone,
#           old.email,
#           new.email,
#           'UPDATE',
#           DATETIME('NOW')
#         ) ;
#       END;
#
# No validity check is done on values yet so please avoid non supported types https://www.sqlite.org/datatype3.html
# DateTime is not a supported SQLite type. Personally I store them as int (millisSinceEpoch) or string (iso8601)
# bool is not a supported SQLite type. Use INTEGER and 0 and 1 values.
# More information on supported types https://github.com/tekartik/sqflite/blob/master/sqflite/doc/supported_types.md
#
# Avoid table / field name keyword:
#   "add","all","alter","and","as","autoincrement","between","case","check","collate","commit",
#   "constraint","create","default","deferrable","delete","distinct","drop","else","escape","except",
#   "exists","foreign","from","group","having","if","in","index","insert","intersect","into","is","isnull",
#   "join","limit","not","notnull","null","on","or","order","primary","references","select","set","table",
#   "then","to","transaction","union","unique","update","using","values","when","where"

version: 1
dir_database: "morpheme"
foreign_key_constrain_support: true
table:
  category:
    create_if_not_exists: true
    column:
      id:
        type: "INTEGER"
        constraint: "PRIMARY KEY"
        autoincrement: true
      name:
        type: "TEXT"
        nullable: false
        default: "Other"
  todo:
    create_if_not_exists: true
    column:
      id:
        type: "INTEGER"
        constraint: "PRIMARY KEY"
        autoincrement: true
      name:
        type: "TEXT"
        nullable: false
      category_id:
        type: "INTEGER"
    foreign:
      category_id: # Column name
        to_table: "category"
        to_column: "id"
        on_update: "CASCADE"
        on_delete: "CASCADE"
''');
    }

    StatusHelper.success('morpheme local2dart init');
  }

  void generateDatabaseInstance(String pathPackageLocal2dart) {
    final String dirDatabase = local2dart['dir_database'] ?? 'morpheme';
    final bool foreignKeyConstrainSupport =
        local2dart['foreign_key_constrain_support'] ?? true;
    final dir = join(pathPackageLocal2dart, 'lib', 'utils');
    DirectoryHelper.createDir(dir);
    join(dir, 'database_instance.dart')
        .write('''import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInstance {
  static DatabaseInstance? _instance;
  final Database db;

  static Future<DatabaseInstance> getInstance() async {
    if (_instance == null) {
      final db = await _open();
      _instance = DatabaseInstance._(db);
    }
    return _instance!;
  }

  DatabaseInstance._(Database database) : db = database;

  static Future<String> pathDatabase() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, '$dirDatabase', 'local2dart.db');
  }

  static Future<Database> _open() async {
    return await openDatabase(
      await pathDatabase(),
      version: ${local2dart['version']},
      onConfigure: (db) => db.execute("PRAGMA foreign_keys = ${foreignKeyConstrainSupport ? 'ON' : 'OFF'}"),
      onCreate: (Database db, int version) async {
        ${generateTable()}
        ${generateView()}
        ${generateTrigger()}

        ${generateSeed()}
      },
    );
  }

  static Future<void> close() async {
    if (_instance?.db.isOpen ?? false) {
      await _instance?.db.close();
      _instance = null;
    }
  }
}''');
  }

  String generateSeed() {
    final Map seed = local2dart['seed'] ?? {};
    StringBuffer buffer = StringBuffer();
    seed.forEach((key, value) {
      final table = value as Map;
      List keys = table['column'];
      List values = table['value'];

      List<String> sqlValue = [];
      for (var element in values) {
        final split = element.toString().split(',');

        List<String> types = [];
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
        "await db.execute('INSERT INTO ${key.toString().snakeCase} (${keys.join(', ')}) VALUES ${sqlValue.join(', ')};');",
      );
    });

    return buffer.toString();
  }

  String generateView() {
    final Map views = local2dart['view'] ?? {};
    StringBuffer bufferView = StringBuffer();

    views.forEach((viewName, view) {
      String rawQuery = getRawQuery(
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

      final createView = view['create_if_not_exists'] ?? true
          ? 'CREATE VIEW IF NOT EXISTS'
          : 'CREATE VIEW';

      final rawView =
          '$createView ${viewName.toString().snakeCase}_view AS $rawQuery';

      bufferView.writeln("await db.execute('$rawView');");
    });

    return bufferView.toString();
  }

  String generateTrigger() {
    final Map views = local2dart['trigger'] ?? {};
    StringBuffer bufferView = StringBuffer();

    views.forEach((viewName, view) {
      String rawSql = view['raw_sql'] ?? '';
      rawSql = rawSql.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (rawSql.contains("'")) {
        rawSql = rawSql.replaceAll("'", r"\'");
      }

      bufferView.writeln("await db.execute('$rawSql');");
    });

    return bufferView.toString();
  }

  String generateTable() {
    final Map tables = local2dart['table'] ?? {};
    StringBuffer bufferTable = StringBuffer();

    tables.forEach((tableName, table) {
      final String createTable =
          (table['create_if_not_exists'] as bool? ?? true)
              ? 'CREATE TABLE IF NOT EXISTS'
              : 'CREATE TABLE';
      final Map columns = table['column'] ?? {};
      final Map foreigns = table['foreign'] ?? {};

      List<String> bufferColumn = [];
      columns.forEach((columnName, column) {
        if (column is String) {
          String type = column;
          final isTypeBool = type == 'BOOL';
          if (isTypeBool) {
            type = 'INTEGER';
          }
          bufferColumn
              .add('${columnName.toString().snakeCase} ${type.toUpperCase()}');
        } else if (column is Map) {
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
              '${columnName.toString().snakeCase} $type$constraint$autoincrement$nullable$defaultValue');
        }
      });

      List<String> relation = [];
      foreigns.forEach((foreignKey, foreign) {
        final String toTable = foreign['to_table'].toString().snakeCase;
        final String toColumn = foreign['to_column'].toString().snakeCase;
        final String onUpdate = foreign['on_update'] != null
            ? ' ON UPDATE ${foreign['on_update'].toString().toUpperCase()}'
            : '';
        final String onDelete = foreign['on_delete'] != null
            ? ' ON DELETE ${foreign['on_delete'].toString().toUpperCase()}'
            : '';

        relation.add(
            'FOREIGN KEY (${foreignKey.toString().snakeCase}) REFERENCES $toTable ($toColumn)$onUpdate$onDelete');
      });

      bufferTable.writeln(
          'await db.execute("$createTable ${tableName.toString().snakeCase} (${bufferColumn.join(', ')}${relation.isEmpty ? '' : ', ${relation.join(', ')}'})");');
    });

    return bufferTable.toString();
  }

  String getType(String type) {
    switch (type.toUpperCase()) {
      case 'INTEGER':
        return 'int';
      case 'REAL':
        return 'double';
      case 'TEXT':
        return 'String';
      case 'BLOB':
        return 'Uint8List';
      case 'BOOL':
        return 'bool';
      default:
        return 'String';
    }
  }

  String getDefaultType(String type) {
    switch (type) {
      case 'int':
        return '0';
      case 'double':
        return '0';
      case 'String':
        return "''";
      case 'Uint8List':
        return 'Uint8List(0)';
      case 'bool':
        return 'false';
      default:
        return "''";
    }
  }

  void generateTableHelper(String pathPackageLocal2dart) {
    final dir = join(pathPackageLocal2dart, 'lib', 'models');
    DirectoryHelper.createDir(dir);

    final Map tables = local2dart['table'] ?? {};

    tables.forEach((tableName, table) {
      final Map columns = table['column'] ?? {};
      final Map foreigns = table['foreign'] ?? {};

      List<String> importForeign = [];
      List<String> constructor = [];
      List<String> constructorAssign = [];
      List<String> variables = [];
      List<String> toMap = [];
      List<String> fromMap = [];
      List<String> fromMapWithJoin = [];
      List<String> props = [];
      List<String> paramCopyWith = [];
      List<String> valueCopyWith = [];

      columnToList(
          columns: columns,
          tables: tables,
          tableName: tableName,
          foreigns: foreigns,
          callback: (
            importForeignCallback,
            constructorCallback,
            constructorAssignCallback,
            variablesCallback,
            toMapCallback,
            fromMapCallback,
            fromMapWithJoinCallback,
            propsCallback,
            paramCopyWithCallback,
            valueCopyWithCallback,
          ) {
            importForeign = importForeignCallback;
            constructor = constructorCallback;
            constructorAssign = constructorAssignCallback;
            variables = variablesCallback;
            toMap = toMapCallback;
            fromMap = fromMapCallback;
            fromMapWithJoin = fromMapWithJoinCallback;
            props = propsCallback;
            paramCopyWith = paramCopyWithCallback;
            valueCopyWith = valueCopyWithCallback;
          });

      generateModel(
        path: join(dir, '${tableName.toString().snakeCase}_table.dart'),
        className: '${tableName.toString().pascalCase}Table',
        importForeign: importForeign,
        constructor: constructor,
        constructorAssign: constructorAssign,
        variables: variables,
        toMap: toMap,
        fromMap: fromMap,
        fromMapWithJoin: fromMapWithJoin,
        paramCopyWith: paramCopyWith,
        valueCopyWith: valueCopyWith,
        props: props,
      );
    });
  }

  String getFromMap({
    required String columnName,
    required String type,
    required bool isRequired,
  }) {
    String value =
        "map['${columnName.snakeCase}']${isRequired ? ' ?? ${getDefaultType(type)}' : ''}";
    if (type == 'int') {
      value =
          "int.tryParse(map['${columnName.snakeCase}']?.toString() ?? '') ${isRequired ? ' ?? ${getDefaultType(type)}' : ''}";
    } else if (type == 'double') {
      value =
          "double.tryParse(map['${columnName.snakeCase}']?.toString() ?? '') ${isRequired ? ' ?? ${getDefaultType(type)}' : ''}";
    } else if (type == 'bool') {
      value = "map['${columnName.snakeCase}'] == 1";
    }
    return "${columnName.camelCase}:  $value,";
  }

  void columnToList({
    required Map columns,
    dynamic tableName,
    Map tables = const {},
    Map foreigns = const {},
    required void Function(
      List<String> importForeignCallback,
      List<String> constructorCallback,
      List<String> constructorAssignCallback,
      List<String> variablesCallback,
      List<String> toMapCallback,
      List<String> fromMapCallback,
      List<String> fromMapWithJoinCallback,
      List<String> propsCallback,
      List<String> paramCopyWithCallback,
      List<String> valueCopyWithCallback,
    ) callback,
  }) {
    List<String> importForeign = [];
    List<String> constructor = [];
    List<String> constructorAssign = [];
    List<String> variables = [];
    List<String> toMap = [];
    List<String> fromMap = [];
    List<String> fromMapWithJoin = [];
    List<String> props = [];
    List<String> paramCopyWith = [];
    List<String> valueCopyWith = [];

    columns.forEach((columnName, column) {
      String type = 'String';
      bool isTypeBool = false;
      bool isRequired = false;
      bool isPrimary = false;

      if (column is String) {
        type = getType(column);
        isTypeBool = type == 'bool';

        constructor.add('this.${columnName.toString().camelCase},');
        variables.add('final $type? ${columnName.toString().camelCase};');
      } else if (column is Map) {
        isPrimary =
            column['constraint']?.toString().toUpperCase() == 'PRIMARY KEY';
        isRequired = isPrimary || column['nullable']?.toString() == 'false';
        type = getType(column['type']?.toString() ?? '');
        isTypeBool = type == 'bool';

        variables.add(
            'final $type${isRequired ? '' : '?'} ${columnName.toString().camelCase};');

        if (isPrimary) {
          constructor.add('$type? ${columnName.toString().camelCase},');
          constructorAssign.add(
              '${columnName.toString().camelCase} = ${columnName.toString().camelCase} ?? ${getDefaultType(type)}');
        } else {
          constructor.add(
              '${isRequired ? 'required' : ''} this.${columnName.toString().camelCase},');
        }
      }

      if (isPrimary) {
        toMap.add(
            "if (${columnName.toString().camelCase} != ${getDefaultType(type)}) '${columnName.toString().snakeCase}': ${columnName.toString().camelCase},");
      } else {
        toMap.add(
            "${isRequired ? '' : 'if (${columnName.toString().camelCase} != null)'} '${columnName.toString().snakeCase}':  ${isTypeBool ? '${columnName.toString().camelCase} == true ? 1 : 0' : columnName.toString().camelCase},");
      }

      fromMap.add(getFromMap(
          columnName: columnName, type: type, isRequired: isRequired));
      props.add(columnName.toString().camelCase);
      paramCopyWith.add('$type? ${columnName.toString().camelCase},');
      valueCopyWith.add(
          '${columnName.toString().camelCase}: ${columnName.toString().camelCase} ?? this.${columnName.toString().camelCase},');

      if (foreigns.isNotEmpty) {
        fromMapWithJoin.add(
            "${columnName.toString().camelCase}:  map['${isTypeBool ? '${tableName.toString().snakeCase}}.${columnName.toString().snakeCase}} == 1' : '${tableName.toString().snakeCase}.${columnName.toString().snakeCase}'}']${isRequired ? ' ?? ${getDefaultType(type)}' : ''},");
      }
    });

    foreigns.forEach((foreignName, foreign) {
      final String tableNameForeign = foreign['to_table'];
      final String toTable = '${tableNameForeign}_table';
      importForeign.add("import '${toTable.snakeCase}.dart';");
      constructor.add('this.${toTable.camelCase},');
      variables.add('final ${toTable.pascalCase}? ${toTable.camelCase};');
      props.add(toTable.camelCase);
      paramCopyWith.add('${toTable.pascalCase}? ${toTable.camelCase},');
      valueCopyWith.add(
          '${toTable.camelCase}: ${toTable.camelCase} ?? this.${toTable.camelCase},');

      List<String> fromMapWithJoinForign = [];
      final Map references = tables[tableNameForeign];
      final Map columnsForeign = references['column'];
      columnsForeign.forEach((columnName, columnForeign) {
        if (columnForeign is String) {
          final type = getType(columnForeign);
          final isTypeBool = type == 'bool';

          fromMapWithJoinForign.add(
              "${columnName.toString().camelCase}:  map['${isTypeBool ? '${tableNameForeign.toString().snakeCase}}.${columnName.toString().snakeCase}} == 1' : '${tableNameForeign.toString().snakeCase}.${columnName.toString().snakeCase}'}'],");
        } else if (columnForeign is Map) {
          final isRequired =
              columnForeign['constraint']?.toString().toUpperCase() ==
                      'PRIMARY KEY' ||
                  columnForeign['nullable']?.toString() == 'false';
          final type = getType(columnForeign['type']?.toString() ?? '');
          final isTypeBool = type == 'bool';

          fromMapWithJoinForign.add(
              "${columnName.toString().camelCase}:  map['${isTypeBool ? '${tableNameForeign.toString().snakeCase}}.${columnName.toString().snakeCase}} == 1' : '${tableNameForeign.toString().snakeCase}.${columnName.toString().snakeCase}'}']${isRequired ? ' ?? ${getDefaultType(type)}' : ''},");
        }
      });

      toMap.add(
          "if (withJoin) '${toTable.snakeCase}': ${toTable.camelCase}?.toMap(withJoin: withJoin),");
      fromMap.add(
          "${toTable.camelCase}: !withJoin || map['${toTable.snakeCase}'] == null ? null : ${toTable.pascalCase}.fromMap(map['${toTable.snakeCase}'], withJoin: withJoin),");
      fromMapWithJoin.add(
          '''${toTable.camelCase}: map['${tableName.toString().snakeCase}.${foreignName.toString().snakeCase}'] == null ? null : ${toTable.pascalCase}(
  ${fromMapWithJoinForign.join('\n')}
),''');
    });

    callback.call(importForeign, constructor, constructorAssign, variables,
        toMap, fromMap, fromMapWithJoin, props, paramCopyWith, valueCopyWith);
  }

  void generateModel({
    required String path,
    required String className,
    List<String> importForeign = const [],
    required List<String> constructor,
    required List<String> constructorAssign,
    required List<String> variables,
    required List<String> toMap,
    required List<String> fromMap,
    List<String> fromMapWithJoin = const [],
    required List<String> paramCopyWith,
    required List<String> valueCopyWith,
    required List<String> props,
  }) {
    path.write('''import 'dart:convert';

import 'package:equatable/equatable.dart';

${importForeign.join('\n')}

class ${className.toString().pascalCase} extends Equatable {
  const ${className.toString().pascalCase}({
    ${constructor.join('\n')}
  }) ${constructorAssign.isNotEmpty ? ': ${constructorAssign.join(',')}' : ''};

  ${variables.join('\n')}

  Map<String, dynamic> toMap({bool withJoin = false}) {
    return {
      ${toMap.join('\n')}
    };
  }

  factory ${className.toString().pascalCase}.fromMap(Map<String, dynamic> map, {bool withJoin = false,}) {
    return ${className.toString().pascalCase}(
      ${fromMap.join('\n')}
    );
  }

  ${fromMapWithJoin.isEmpty ? '' : '''factory ${className.toString().pascalCase}.fromMapWithJoin(Map<String, dynamic> map, {bool withJoin = false,}) {
    return ${className.toString().pascalCase}(
       ${fromMapWithJoin.join('\n')}
    );
  }'''}

  String toJson({bool withJoin = false}) => json.encode(toMap(withJoin: withJoin));

  factory ${className.toString().pascalCase}.fromJson(String source) =>
      ${className.toString().pascalCase}.fromMap(json.decode(source));

  ${className.toString().pascalCase} copyWith({
    ${paramCopyWith.join('\n')}
  }) {
    return ${className.toString().pascalCase}(
      ${valueCopyWith.join('\n')}
    );
  }

  @override
  List<Object?> get props => [${props.join(',')}];
}
''');
  }

  void generateCore(String pathPackageLocal2dart) {
    final dirPagination = join(pathPackageLocal2dart, 'lib', 'paginations');
    final dirUtil = join(pathPackageLocal2dart, 'lib', 'utils');
    DirectoryHelper.createDir(dirPagination);
    DirectoryHelper.createDir(dirUtil);

    join(dirPagination, 'local_meta_pagination.dart')
        .write('''import 'package:equatable/equatable.dart';

class LocalMetaPagination extends Equatable {
  const LocalMetaPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.offset,
    required this.currentPage,
    required this.totalPage,
  });

  final int total;
  final int limit;
  final int page;
  final int offset;
  final int currentPage;
  final int totalPage;

  @override
  List<Object?> get props => [
        total,
        limit,
        page,
        offset,
        currentPage,
        totalPage,
      ];
}
''');

    join(dirPagination, 'local_pagination.dart')
        .write('''import 'package:equatable/equatable.dart';
import 'package:local2dart/paginations/local_meta_pagination.dart';

class LocalPagination<T> extends Equatable {
  const LocalPagination({
    required this.data,
    required this.meta,
  });

  final T data;
  final LocalMetaPagination meta;

  @override
  List<Object?> get props => [data, meta];
}
''');

    join(dirUtil, 'query_helper.dart')
        .write('''import '../paginations/local_meta_pagination.dart';

abstract class QueryHelper {
  static String whereQuery({
    String? where,
    List<Object?>? whereArgs,
  }) {
    if (where == null) return '';
    String whereQuery = 'WHERE \$where';
    whereArgs?.forEach((element) {
      String args = element.toString();
      if (element is String) {
        args = '"\$args"';
      }
      whereQuery = whereQuery.replaceFirst('?', args);
    });
    return whereQuery;
  }

  static String distinctQuery({bool? distinct}) =>
      (distinct ?? false) ? 'DISTINCT' : '';
  static String groupByQuery({String? groupBy}) =>
      groupBy != null ? 'GROUP BY \$groupBy' : '';
  static String havingQuery({String? having}) =>
      having != null ? 'HAVING \$having' : '';
  static String orderByQuery({String? orderBy}) =>
      orderBy != null ? 'ORDER BY \$orderBy' : '';
  static String limitQuery({int? limit}) => limit != null ? 'LIMIT \$limit' : '';
  static String offsetQuery({int? offset}) =>
      offset != null ? 'OFFSET \$offset' : '';

  static String allConditionalQuery({
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    final whereQuery =
        QueryHelper.whereQuery(where: where, whereArgs: whereArgs);
    final groupByQuery = QueryHelper.groupByQuery(groupBy: groupBy);
    final havingQuery = QueryHelper.havingQuery(having: having);
    final orderByQuery = QueryHelper.orderByQuery(orderBy: orderBy);
    final limitQuery = QueryHelper.limitQuery(limit: limit);
    final offsetQuery = QueryHelper.offsetQuery(offset: offset);
    return '\$whereQuery \$groupByQuery \$havingQuery \$orderByQuery \$limitQuery \$offsetQuery';
  }

  static String countQuery({
    required String tableName,
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    final distinctQuery =
        (distinct ?? false) ? 'SELECT DISTINCT * FROM \$tableName' : tableName;
    final allConditionalQuery = QueryHelper.allConditionalQuery(
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return 'SELECT COUNT(*) FROM \$distinctQuery \$allConditionalQuery';
  }

  static int offset({required int page, required int limit}) =>
      (page - 1) * limit;

  static LocalMetaPagination metaPagination({
    required int total,
    required int page,
    required int limit,
    required int offset,
  }) {
    int totalPage = 1;
    if (limit > 0) {
      totalPage = total ~/ limit;
    }
    if (totalPage % limit > 0) {
      totalPage++;
    }
    return LocalMetaPagination(
      total: total,
      limit: limit,
      page: page,
      offset: offset,
      currentPage: page,
      totalPage: totalPage,
    );
  }
}
''');

    join(dirUtil, 'bulk_insert.dart')
        .write('''import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

class BulkInsert<T> extends Equatable {
  const BulkInsert({
    required this.data,
    this.nullColumnHack,
    this.conflictAlgorithm,
  });

  final T data;
  final String? nullColumnHack;
  final ConflictAlgorithm? conflictAlgorithm;

  @override
  List<Object?> get props => [data, nullColumnHack, conflictAlgorithm];
}
''');

    join(dirUtil, 'bulk_update.dart')
        .write('''import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

class BulkUpdate<T> extends Equatable {
  const BulkUpdate({
    required this.data,
    this.where,
    this.whereArgs,
    this.conflictAlgorithm,
  });

  final T data;
  final String? where;
  final List<Object?>? whereArgs;
  final ConflictAlgorithm? conflictAlgorithm;

  @override
  List<Object?> get props => [data, where, whereArgs, conflictAlgorithm];
}
''');

    join(dirUtil, 'bulk_delete.dart')
        .write('''import 'package:equatable/equatable.dart';

class BulkDelete extends Equatable {
  const BulkDelete({
    this.where,
    this.whereArgs,
  });
  final String? where;
  final List<Object?>? whereArgs;

  @override
  List<Object?> get props => [where, whereArgs];
}
''');
  }

  String getRawQuery({
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

    List<String> columnList = [];
    if (column is Map) {
      column.forEach((key, value) {
        final origin = value['origin'];
        if (origin == null) return;
        columnList.add("$origin as '${key.toString().snakeCase}'");
      });
    }

    final List joins = [];
    if (join is String) {
      joins.add(join);
    } else if (join is List) {
      joins.addAll(join);
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

  void generateService(String pathPackageLocal2dart) {
    final dirService = join(pathPackageLocal2dart, 'lib', 'services');

    DirectoryHelper.createDir(dirService);

    final Map tables = local2dart['table'] ?? {};
    final Map query = local2dart['query'] ?? {};

    tables.forEach((tableName, table) {
      final Map columns = table['column'] ?? {};
      final Map foreigns = table['foreign'] ?? {};

      String primaryKey = '';
      String typePrimaryKey = '';

      List<String> variables = [];
      List<String> queryWithJoins = [];
      List<String> tableJoins = [];
      columns.forEach((columnName, column) {
        if (column is Map &&
            column['constraint']?.toString().toUpperCase() == 'PRIMARY KEY') {
          primaryKey = columnName.toString().snakeCase;
          typePrimaryKey = getType(column['type']?.toString() ?? '');
        }

        variables.add(
            "static const String column${columnName.toString().pascalCase} = '${columnName.toString().snakeCase}';");
        queryWithJoins.add(
            "${tableName.toString().snakeCase}.${columnName.toString().snakeCase} as '${tableName.toString().snakeCase}.${columnName.toString().snakeCase}'");
      });

      foreigns.forEach((foreignName, foreign) {
        final String columnForeign = foreign['to_column'] ?? '';
        final String tableNameForeign = foreign['to_table'] ?? '';
        final Map references = tables[tableNameForeign] ?? {};
        final Map columnsForeign = references['column'] ?? {};

        columnsForeign.forEach((key, value) {
          queryWithJoins.add(
              "${tableNameForeign.toString().snakeCase}.${key.toString().snakeCase} as '${tableNameForeign.toString().snakeCase}.${key.toString().snakeCase}'");
        });

        tableJoins.add(
            'LEFT JOIN ${tableNameForeign.snakeCase} ON ${tableName.toString().snakeCase}.${foreignName.toString().snakeCase} = ${tableNameForeign.snakeCase}.${columnForeign.snakeCase}');
      });

      List<String> importQueryModel = [];
      List<String> customQuery = [];

      final Map selectedQuery = query[tableName.toString().snakeCase] ?? {};
      selectedQuery.forEach((queryName, query) {
        importQueryModel.add(
          "import '../models/${queryName.toString().snakeCase}_query.dart';",
        );

        final where = query['where'] ?? '';

        final int whereArgsLength = RegExp(r'\?').allMatches(where).length;
        List<String> whereArgsParams = List.generate(
            whereArgsLength, (index) => 'Object? args${index + 1},');
        List<String> whereArgsImpl =
            List.generate(whereArgsLength, (index) => 'args${index + 1},');

        String rawQuery = getRawQuery(
          distinct: query['disticnt'] ?? false,
          column: query['column'],
          from: tableName,
          join: query['join'],
          where: query['where'],
          isWhereArgs: true,
          orderBy: query['order_by'],
          limit: query['limit'],
          offset: query['offset'],
          groupBy: query['group_by'],
          having: query['having'],
        );

        customQuery.add(
            '''static Future<List<${queryName.toString().pascalCase}Query>> ${queryName.toString().camelCase}(${whereArgsParams.join()}) async {
        final db = await getDatabase();
        ${whereArgsLength == 0 ? '' : '''final where = QueryHelper.whereQuery(
          where: '$where',
          whereArgs: [${whereArgsImpl.join()}],
        );'''}
        final query = await db.rawQuery("$rawQuery",);
        List<${queryName.toString().pascalCase}Query> result = [];
        for (var element in query) {
          result.add(${queryName.toString().pascalCase}Query.fromMap(element));
        }
        return result;
      }''');
      });

      join(dirService, '${tableName.toString().snakeCase}_local_service.dart')
          .write('''import 'package:local2dart/utils/database_instance.dart';
import 'package:sqflite/sqflite.dart';

import '../paginations/local_pagination.dart';
import '../utils/query_helper.dart';
import '../models/${tableName.toString().snakeCase}_table.dart';
import '../utils/bulk_insert.dart';
import '../utils/bulk_update.dart';
import '../utils/bulk_delete.dart';

${importQueryModel.join('\n')}

abstract class ${tableName.toString().pascalCase}LocalService {
  static const String tableName = '${tableName.toString().snakeCase}';

  ${variables.join('\n')}

  static Future<Database> getDatabase() async => (await DatabaseInstance.getInstance()).db;

  ${foreigns.isEmpty ? '' : '''static String _queryWithJoin({
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    final allConditionalQuery = QueryHelper.allConditionalQuery(
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return "SELECT \${QueryHelper.distinctQuery(distinct: distinct)} ${queryWithJoins.join(', ')} FROM ${tableName.toString().snakeCase} ${tableJoins.join(' ')} \$allConditionalQuery";
  }
'''}
  

  static Future<int> count({
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await getDatabase();
    final countQuery = QueryHelper.countQuery(
      tableName: tableName,
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    final count = Sqflite.firstIntValue(await db.rawQuery(countQuery));
    return count ?? 0;
  }

  static Future<List<${tableName.toString().pascalCase}Table>> get({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await getDatabase();
    final query = await db.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    List<${tableName.toString().pascalCase}Table> result = [];
    for (var element in query) {
      result.add(${tableName.toString().pascalCase}Table.fromMap(element));
    }
    return result;
  }

  static Future<LocalPagination<List<${tableName.toString().pascalCase}Table>>> getWithPagination({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    required int limit,
    required int page,
  }) async {
    final db = await getDatabase();
    final offset = QueryHelper.offset(page: page, limit: limit);
    final total = await count(
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    final query = await db.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    List<${tableName.toString().pascalCase}Table> result = [];
    for (var element in query) {
      result.add(${tableName.toString().pascalCase}Table.fromMap(element));
    }

    final meta = QueryHelper.metaPagination(
      total: total,
      page: page,
      limit: limit,
      offset: offset,
    );
    return LocalPagination(data: result, meta: meta);
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<${tableName.toString().pascalCase}Table?> getBy${primaryKey.pascalCase}($typePrimaryKey ${primaryKey.camelCase}) async {
    final db = await getDatabase();
    final query = await db.query(tableName, where: '\$column${primaryKey.pascalCase} = ?', whereArgs: [${primaryKey.camelCase}]);
    if (query.isEmpty) return null;
    return ${tableName.toString().pascalCase}Table.fromMap(query.first);
  }
'''}


  ${foreigns.isEmpty ? '' : '''  static Future<List<${tableName.toString().pascalCase}Table>> getWithJoin({
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await getDatabase();
    final queryWithJoin = _queryWithJoin(
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    final query = await db.rawQuery(queryWithJoin);
    List<${tableName.toString().pascalCase}Table> result = [];
    for (var element in query) {
      result.add(${tableName.toString().pascalCase}Table.fromMapWithJoin(element));
    }
    return result;
  }

  static Future<LocalPagination<List<${tableName.toString().pascalCase}Table>>> getWithJoinPagination({
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    required int limit,
    required int page,
  }) async {
    final db = await getDatabase();
    final offset = QueryHelper.offset(page: page, limit: limit);
    final total = await count(
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    final queryWithJoin = _queryWithJoin(
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    final query = await db.rawQuery(queryWithJoin);
    List<${tableName.toString().pascalCase}Table> result = [];
    for (var element in query) {
      result.add(${tableName.toString().pascalCase}Table.fromMapWithJoin(element));
    }
    final meta = QueryHelper.metaPagination(
      total: total,
      page: page,
      limit: limit,
      offset: offset,
    );
    return LocalPagination(data: result, meta: meta);
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<${tableName.toString().pascalCase}Table?> getBy${primaryKey.pascalCase}WithJoin($typePrimaryKey ${primaryKey.camelCase}) async {
    final db = await getDatabase();
    final queryWithJoin = _queryWithJoin(where: '\$tableName.\$column${primaryKey.pascalCase} = ?', whereArgs: [${primaryKey.camelCase}]);
    final query = await db.rawQuery(queryWithJoin);
    if (query.isEmpty) return null;
    return ${tableName.toString().pascalCase}Table.fromMapWithJoin(query.first);
  }'''}
'''}

  static Future<int> insert({
    required ${tableName.toString().pascalCase}Table ${tableName.toString().camelCase}Table,
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.insert(
      tableName,
      ${tableName.toString().camelCase}Table.toMap(),
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  static Future<List<Object?>> bulkInsert({
    required List<BulkInsert<${tableName.toString().pascalCase}Table>> bulkInsertTable,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var element in bulkInsertTable) {
      batch.insert(
        tableName,
        element.data.toMap(),
        nullColumnHack: element.nullColumnHack,
        conflictAlgorithm: element.conflictAlgorithm,
      );
    }
    return batch.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<int> upsert({required ${tableName.toString().pascalCase}Table ${tableName.toString().camelCase}Table}) async {
    final countData = await count(
      where: '\$column${primaryKey.pascalCase} = ?',
      whereArgs: [${tableName.toString().camelCase}Table.${primaryKey.camelCase}],
    );
    if (countData > 0) {
      return updateBy${primaryKey.pascalCase}(${primaryKey.camelCase}: ${tableName.toString().camelCase}Table.${primaryKey.camelCase}, ${tableName.toString().camelCase}Table: ${tableName.toString().camelCase}Table,);
    }
    return insert(${tableName.toString().camelCase}Table: ${tableName.toString().camelCase}Table);
  }'''}

  static Future<int> update({
    required ${tableName.toString().pascalCase}Table ${tableName.toString().camelCase}Table,
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.update(
      tableName,
      ${tableName.toString().camelCase}Table.toMap(),
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  static Future<List<Object?>> bulkUpdate({
    required List<BulkUpdate<${tableName.toString().pascalCase}Table>> bulkUpdateTables,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var element in bulkUpdateTables) {
      batch.update(
        tableName,
        element.data.toMap(),
        where: element.where,
        whereArgs: element.whereArgs,
        conflictAlgorithm: element.conflictAlgorithm,
      );
    }
    return batch.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<int> updateBy${primaryKey.pascalCase}({
    required $typePrimaryKey ${primaryKey.camelCase},
    required ${tableName.toString().pascalCase}Table ${tableName.toString().camelCase}Table,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.update(
      tableName,
      ${tableName.toString().camelCase}Table.toMap(),
      where: '\$column${primaryKey.pascalCase} = ?',
      whereArgs: [${primaryKey.camelCase}],
      conflictAlgorithm: conflictAlgorithm,
    );
  }'''}

  ${primaryKey.isEmpty ? '' : '''  static Future<List<Object?>> bulkUpdateBy${primaryKey.pascalCase}({
    required List<$typePrimaryKey> ${primaryKey.camelCase}s,
    required List<BulkUpdate<${tableName.toString().pascalCase}Table>> bulkUpdateTables,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var i = 0; i < ${primaryKey.camelCase}s.length; i++) {
      batch.update(
        tableName,
        bulkUpdateTables[i].data.toMap(),
        where: '\$column${primaryKey.pascalCase} = ?',
        whereArgs: [${primaryKey.camelCase}s[i]],
        conflictAlgorithm: bulkUpdateTables[i].conflictAlgorithm,
      );
    }
    return batch.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
  }'''}
  

  static Future<int> delete({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await getDatabase();
    return db.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  static Future<List<Object?>> bulkDelete({
    required List<BulkDelete> bulkDelete,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var element in bulkDelete) {
      batch.delete(
        tableName,
        where: element.where,
        whereArgs: element.whereArgs,
      );
    }
    return batch.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<int> deleteBy${primaryKey.pascalCase}({required $typePrimaryKey ${primaryKey.camelCase}}) async {
    final db = await getDatabase();
    return db.delete(
      tableName,
      where: '\$column${primaryKey.pascalCase} = ?',
      whereArgs: [${primaryKey.camelCase}],
    );
  }'''}

  ${primaryKey.isEmpty ? '' : '''  static Future<List<Object?>> bulkDeleteBy${primaryKey.pascalCase}({
    required List<$typePrimaryKey> ${primaryKey.camelCase}s,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var element in ${primaryKey.camelCase}s) {
      batch.delete(
        tableName,
        where: '\$column${primaryKey.pascalCase} = ?',
        whereArgs: [element],
      );
    }
    return batch.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
  }'''}

  ${customQuery.isEmpty ? '' : customQuery.join('\n')}
}
''');
    });
  }

  void generateLocal2dart(String pathPackageLocal2dart) {
    final path = join(pathPackageLocal2dart, 'lib', 'local2dart.dart');

    List<String> export = [];

    final Map tables = local2dart['table'] ?? {};
    final Map querys = local2dart['query'] ?? {};

    for (var element in tables.keys) {
      export.add("export 'models/${element.toString().snakeCase}_table.dart';");
      export.add(
          "export 'services/${element.toString().snakeCase}_local_service.dart';");
    }

    querys.forEach((key, value) {
      if (value == null && value is! Map) return;
      for (var element in value.keys) {
        export
            .add("export 'models/${element.toString().snakeCase}_query.dart';");
      }
    });

    path.write('''library local2dart;

export 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

export 'paginations/local_meta_pagination.dart';
export 'paginations/local_pagination.dart';
export 'utils/database_instance.dart';
export 'utils/query_helper.dart';
export 'utils/bulk_insert.dart';
export 'utils/bulk_update.dart';
export 'utils/bulk_delete.dart';
${export.join('\n')}
''');
  }

  void generateQueryTableHelper(String pathPackageLocal2dart) {
    final dir = join(pathPackageLocal2dart, 'lib', 'models');
    DirectoryHelper.createDir(dir);

    final Map queries = local2dart['query'] ?? {};

    queries.forEach((key, value) {
      if (value is! Map) return;
      value.forEach((queryName, query) {
        final Map columns = query['column'] ?? {};

        List<String> importForeign = [];
        List<String> constructor = [];
        List<String> constructorAssign = [];
        List<String> variables = [];
        List<String> toMap = [];
        List<String> fromMap = [];
        List<String> fromMapWithJoin = [];
        List<String> props = [];
        List<String> paramCopyWith = [];
        List<String> valueCopyWith = [];

        columnToList(
            columns: columns,
            tables: queries,
            tableName: queryName,
            foreigns: {},
            callback: (
              importForeignCallback,
              constructorCallback,
              constructorAssignCallback,
              variablesCallback,
              toMapCallback,
              fromMapCallback,
              fromMapWithJoinCallback,
              propsCallback,
              paramCopyWithCallback,
              valueCopyWithCallback,
            ) {
              importForeign = importForeignCallback;
              constructor = constructorCallback;
              constructorAssign = constructorAssignCallback;
              variables = variablesCallback;
              toMap = toMapCallback;
              fromMap = fromMapCallback;
              fromMapWithJoin = fromMapWithJoinCallback;
              props = propsCallback;
              paramCopyWith = paramCopyWithCallback;
              valueCopyWith = valueCopyWithCallback;
            });

        generateModel(
          path: join(dir, '${queryName.toString().snakeCase}_query.dart'),
          className: '${queryName.toString().pascalCase}Query',
          importForeign: importForeign,
          constructor: constructor,
          constructorAssign: constructorAssign,
          variables: variables,
          toMap: toMap,
          fromMap: fromMap,
          fromMapWithJoin: fromMapWithJoin,
          paramCopyWith: paramCopyWith,
          valueCopyWith: valueCopyWith,
          props: props,
        );
      });
    });
  }

  void generateViewHelper(String pathPackageLocal2dart) {
    final dir = join(pathPackageLocal2dart, 'lib', 'models');
    DirectoryHelper.createDir(dir);

    final Map views = local2dart['view'] ?? {};

    views.forEach((viewName, view) {
      final Map columns = view['column'] ?? {};

      List<String> importForeign = [];
      List<String> constructor = [];
      List<String> constructorAssign = [];
      List<String> variables = [];
      List<String> toMap = [];
      List<String> fromMap = [];
      List<String> fromMapWithJoin = [];
      List<String> props = [];
      List<String> paramCopyWith = [];
      List<String> valueCopyWith = [];

      columnToList(
          columns: columns,
          tables: views,
          tableName: viewName,
          foreigns: {},
          callback: (
            importForeignCallback,
            constructorCallback,
            constructorAssignCallback,
            variablesCallback,
            toMapCallback,
            fromMapCallback,
            fromMapWithJoinCallback,
            propsCallback,
            paramCopyWithCallback,
            valueCopyWithCallback,
          ) {
            importForeign = importForeignCallback;
            constructor = constructorCallback;
            constructorAssign = constructorAssignCallback;
            variables = variablesCallback;
            toMap = toMapCallback;
            fromMap = fromMapCallback;
            fromMapWithJoin = fromMapWithJoinCallback;
            props = propsCallback;
            paramCopyWith = paramCopyWithCallback;
            valueCopyWith = valueCopyWithCallback;
          });

      generateModel(
        path: join(dir, '${viewName.toString().snakeCase}_view.dart'),
        className: '${viewName.toString().pascalCase}View',
        importForeign: importForeign,
        constructor: constructor,
        constructorAssign: constructorAssign,
        variables: variables,
        toMap: toMap,
        fromMap: fromMap,
        fromMapWithJoin: fromMapWithJoin,
        paramCopyWith: paramCopyWith,
        valueCopyWith: valueCopyWith,
        props: props,
      );
    });
  }
}
