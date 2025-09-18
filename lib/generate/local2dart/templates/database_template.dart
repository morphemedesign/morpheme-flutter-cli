/// Template for database instance code generation.
///
/// This class provides static methods for generating the database
/// instance class code with proper formatting and structure.
class DatabaseTemplate {
  /// Generates the database instance class.
  ///
  /// Parameters:
  /// - [dirDatabase]: The directory for the database.
  /// - [foreignKeyConstrainSupport]: Whether foreign key constraints are supported.
  /// - [version]: The database version.
  /// - [tableCreationSql]: SQL for table creation.
  /// - [viewCreationSql]: SQL for view creation.
  /// - [triggerCreationSql]: SQL for trigger creation.
  /// - [seedSql]: SQL for seed data insertion.
  ///
  /// Returns: The generated database instance class code.
  static String generate({
    required String dirDatabase,
    required bool foreignKeyConstrainSupport,
    required int version,
    required String tableCreationSql,
    required String viewCreationSql,
    required String triggerCreationSql,
    required String seedSql,
  }) {
    return '''
import 'package:path/path.dart';
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
      version: $version,
      onConfigure: (db) => db.execute("PRAGMA foreign_keys = ${foreignKeyConstrainSupport ? 'ON' : 'OFF'}"),
      onCreate: (Database db, int version) async {
        $tableCreationSql
        $viewCreationSql
        $triggerCreationSql

        $seedSql
      },
    );
  }

  static Future<void> close() async {
    if (_instance?.db.isOpen ?? false) {
      await _instance?.db.close();
      _instance = null;
    }
  }
}''';
  }
}