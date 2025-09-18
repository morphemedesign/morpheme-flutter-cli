/// Template for service class code generation.
///
/// This class provides static methods for generating service
/// classes with CRUD operations and other functionality.
class ServiceTemplate {
  /// Generates a service class.
  ///
  /// Parameters:
  /// - [tableName]: The name of the table.
  /// - [primaryKey]: The primary key column name.
  /// - [typePrimaryKey]: The Dart type of the primary key.
  /// - [variables]: Class variables.
  /// - [queryWithJoins]: Query with joins implementation.
  /// - [tableJoins]: Table joins implementation.
  /// - [importQueryModel]: Import statements for query models.
  /// - [customQuery]: Custom query methods.
  ///
  /// Returns: The generated service class code.
  static String generate({
    required String tableName,
    required String primaryKey,
    required String typePrimaryKey,
    required List<String> variables,
    required List<String> queryWithJoins,
    required List<String> tableJoins,
    required List<String> importQueryModel,
    required List<String> customQuery,
  }) {
    return '''
import 'package:local2dart/utils/database_instance.dart';
import 'package:sqflite/sqflite.dart';

import '../paginations/local_pagination.dart';
import '../utils/query_helper.dart';
import '../models/${tableName}_table.dart';
import '../utils/bulk_insert.dart';
import '../utils/bulk_update.dart';
import '../utils/bulk_delete.dart';

${importQueryModel.join('\n')}

abstract class ${tableName}LocalService {
  static const String tableName = '$tableName';

  ${variables.join('\n')}

  static Future<Database> getDatabase() async => (await DatabaseInstance.getInstance()).db;

  ${tableJoins.isEmpty ? '' : '''static String _queryWithJoin({
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
    return "SELECT \${QueryHelper.distinctQuery(distinct: distinct)} ${queryWithJoins.join(', ')} FROM $tableName ${tableJoins.join(' ')} \$allConditionalQuery";
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

  static Future<List<${tableName}Table>> get({
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
    List<${tableName}Table> result = [];
    for (var element in query) {
      result.add(${tableName}Table.fromMap(element));
    }
    return result;
  }

  static Future<LocalPagination<List<${tableName}Table>>> getWithPagination({
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
    List<${tableName}Table> result = [];
    for (var element in query) {
      result.add(${tableName}Table.fromMap(element));
    }

    final meta = QueryHelper.metaPagination(
      total: total,
      page: page,
      limit: limit,
      offset: offset,
    );
    return LocalPagination(data: result, meta: meta);
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<${tableName}Table?> getBy$primaryKey($typePrimaryKey $primaryKey) async {
    final db = await getDatabase();
    final query = await db.query(tableName, where: '\$column$primaryKey = ?', whereArgs: [$primaryKey]);
    if (query.isEmpty) return null;
    return ${tableName}Table.fromMap(query.first);
  }
'''}

  ${tableJoins.isEmpty ? '' : '''  static Future<List<${tableName}Table>> getWithJoin({
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
    List<${tableName}Table> result = [];
    for (var element in query) {
      result.add(${tableName}Table.fromMapWithJoin(element));
    }
    return result;
  }

  static Future<LocalPagination<List<${tableName}Table>>> getWithJoinPagination({
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
    List<${tableName}Table> result = [];
    for (var element in query) {
      result.add(${tableName}Table.fromMapWithJoin(element));
    }
    final meta = QueryHelper.metaPagination(
      total: total,
      page: page,
      limit: limit,
      offset: offset,
    );
    return LocalPagination(data: result, meta: meta);
  }

  ${primaryKey.isEmpty ? '' : '''  static Future<${tableName}Table?> getBy${primaryKey}WithJoin($typePrimaryKey $primaryKey) async {
    final db = await getDatabase();
    final queryWithJoin = _queryWithJoin(where: '\$tableName.\$column$primaryKey = ?', whereArgs: [$primaryKey]);
    final query = await db.rawQuery(queryWithJoin);
    if (query.isEmpty) return null;
    return ${tableName}Table.fromMapWithJoin(query.first);
  }'''}
'''}

  static Future<int> insert({
    required ${tableName}Table ${tableName}Table,
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.insert(
      tableName,
      ${tableName}Table.toMap(),
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  static Future<List<Object?>> bulkInsert({
    required List<BulkInsert<${tableName}Table>> bulkInsertTable,
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

  ${primaryKey.isEmpty ? '' : '''  static Future<int> upsert({required ${tableName}Table ${tableName}Table}) async {
    final countData = await count(
      where: '\$column$primaryKey = ?',
      whereArgs: [${tableName}Table.$primaryKey],
    );
    if (countData > 0) {
      return updateBy$primaryKey($primaryKey: ${tableName}Table.$primaryKey, ${tableName}Table: ${tableName}Table,);
    }
    return insert(${tableName}Table: ${tableName}Table);
  }'''}

  static Future<int> update({
    required ${tableName}Table ${tableName}Table,
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.update(
      tableName,
      ${tableName}Table.toMap(),
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  static Future<List<Object?>> bulkUpdate({
    required List<BulkUpdate<${tableName}Table>> bulkUpdateTables,
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

  ${primaryKey.isEmpty ? '' : '''  static Future<int> updateBy$primaryKey({
    required $typePrimaryKey $primaryKey,
    required ${tableName}Table ${tableName}Table,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await getDatabase();
    return db.update(
      tableName,
      ${tableName}Table.toMap(),
      where: '\$column$primaryKey = ?',
      whereArgs: [$primaryKey],
      conflictAlgorithm: conflictAlgorithm,
    );
  }'''}

  ${primaryKey.isEmpty ? '' : '''  static Future<List<Object?>> bulkUpdateBy$primaryKey({
    required List<$typePrimaryKey> ${primaryKey}s,
    required List<BulkUpdate<${tableName}Table>> bulkUpdateTables,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var i = 0; i < ${primaryKey}s.length; i++) {
      batch.update(
        tableName,
        bulkUpdateTables[i].data.toMap(),
        where: '\$column$primaryKey = ?',
        whereArgs: [${primaryKey}s[i]],
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

  ${primaryKey.isEmpty ? '' : '''  static Future<int> deleteBy$primaryKey({required $typePrimaryKey $primaryKey}) async {
    final db = await getDatabase();
    return db.delete(
      tableName,
      where: '\$column$primaryKey = ?',
      whereArgs: [$primaryKey],
    );
  }'''}

  ${primaryKey.isEmpty ? '' : '''  static Future<List<Object?>> bulkDeleteBy$primaryKey({
    required List<$typePrimaryKey> ${primaryKey}s,
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (var element in ${primaryKey}s) {
      batch.delete(
        tableName,
        where: '\$column$primaryKey = ?',
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
''';
  }
}
