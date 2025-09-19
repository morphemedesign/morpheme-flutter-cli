import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/local2dart/models/local2dart_config.dart';
import 'package:morpheme_cli/generate/local2dart/generators/database_generator.dart';
import 'package:morpheme_cli/generate/local2dart/generators/model_generator.dart';
import 'package:morpheme_cli/generate/local2dart/generators/service_generator.dart';
import 'package:morpheme_cli/generate/local2dart/generators/core_generator.dart';
import 'package:morpheme_cli/generate/local2dart/generators/export_generator.dart';

/// Orchestrator for Local2Dart code generation.
///
/// This class coordinates the entire code generation process,
/// managing dependencies between generators and ensuring
/// proper order of generation.
class Local2DartOrchestrator {
  /// Creates a new Local2DartOrchestrator instance.
  Local2DartOrchestrator();

  /// Executes the complete code generation process.
  ///
  /// This method orchestrates all generators in the correct order
  /// to produce the complete local2dart package.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  ///
  /// Returns: True if generation was successful, false otherwise.
  Future<bool> generate(Local2DartConfig config, String packagePath) async {
    try {
      printMessage('🚀 Starting Local2Dart code generation...');

      // Create required directories
      await _createDirectories(packagePath);

      // Generate core utilities first
      printMessage('🔧 Generating core utilities...');
      final coreGenerator = CoreGenerator(config, packagePath);
      await coreGenerator.generate();

      // Generate database instance
      printMessage('🗄️ Generating database instance...');
      final databaseGenerator = DatabaseGenerator(config, packagePath);
      await databaseGenerator.generate();

      // Generate models (tables, views, queries)
      printMessage('📝 Generating models...');
      final modelGenerator = ModelGenerator(config, packagePath);
      await modelGenerator.generate();

      // Generate services
      printMessage('⚙️ Generating services...');
      final serviceGenerator = ServiceGenerator(config, packagePath);
      await serviceGenerator.generate();

      // Generate export file
      printMessage('📦 Generating export file...');
      final exportGenerator = ExportGenerator(config, packagePath);
      await exportGenerator.generate();

      // Format generated code
      printMessage('✨ Formatting generated code...');
      await _formatCode(packagePath);

      printMessage('✅ Local2Dart code generation completed successfully!');
      return true;
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Local2Dart generation failed: $e',
        suggestion: 'Check your configuration and try again',
      );
      print(stackTrace);
      return false;
    }
  }

  /// Creates the required directories for code generation.
  ///
  /// Parameters:
  /// - [packagePath]: The path where the package should be generated.
  Future<void> _createDirectories(String packagePath) async {
    final directories = [
      join(packagePath, 'lib', 'models'),
      join(packagePath, 'lib', 'services'),
      join(packagePath, 'lib', 'utils'),
      join(packagePath, 'lib', 'paginations'),
    ];

    for (final dir in directories) {
      createDir(dir);
    }
  }

  /// Formats the generated code using dart format.
  ///
  /// Parameters:
  /// - [packagePath]: The path to the generated package.
  Future<void> _formatCode(String packagePath) async {
    try {
      await '${FlutterHelper.getCommandDart()} format .'
          .start(workingDirectory: packagePath);
    } catch (e) {
      // If formatting fails, we don't want to fail the entire generation
      printMessage('⚠️ Warning: Code formatting failed: $e');
    }
  }

  /// Initializes the local2dart configuration.
  ///
  /// This method creates the initial configuration files
  /// when the user runs the init command.
  ///
  /// Parameters:
  /// - [path]: The path where the configuration should be created.
  void init(String path) {
    createDir(path);

    final configPath = join(path, 'local2dart.yaml');
    if (!exists(configPath)) {
      configPath.write('''# local2dart
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
#         [BEFORE|AFTER|INSERT|UPDATE|DELETE]
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

    StatusHelper.success('Local2Dart configuration initialized successfully!');
  }
}
