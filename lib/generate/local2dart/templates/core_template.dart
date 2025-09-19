/// Template for core utility class code generation.
///
/// This class provides static methods for generating core
/// utility classes such as pagination models and query helpers.
class CoreTemplate {
  /// Generates the LocalMetaPagination class.
  ///
  /// Returns: The generated LocalMetaPagination class code.
  static String generateLocalMetaPagination() {
    return '''
import 'package:equatable/equatable.dart';

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
''';
  }

  /// Generates the LocalPagination class.
  ///
  /// Returns: The generated LocalPagination class code.
  static String generateLocalPagination() {
    return '''
import 'package:equatable/equatable.dart';
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
''';
  }

  /// Generates the QueryHelper class.
  ///
  /// Returns: The generated QueryHelper class code.
  static String generateQueryHelper() {
    return '''
import '../paginations/local_meta_pagination.dart';

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
''';
  }

  /// Generates the BulkInsert class.
  ///
  /// Returns: The generated BulkInsert class code.
  static String generateBulkInsert() {
    return '''
import 'package:equatable/equatable.dart';
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
''';
  }

  /// Generates the BulkUpdate class.
  ///
  /// Returns: The generated BulkUpdate class code.
  static String generateBulkUpdate() {
    return '''
import 'package:equatable/equatable.dart';
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
''';
  }

  /// Generates the BulkDelete class.
  ///
  /// Returns: The generated BulkDelete class code.
  static String generateBulkDelete() {
    return '''
import 'package:equatable/equatable.dart';

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
''';
  }
}
