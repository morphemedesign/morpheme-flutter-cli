import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/local2dart/models/local2dart_config.dart';
import 'package:morpheme_cli/generate/local2dart/models/table_definition.dart';

/// Configuration manager for Local2Dart command.
///
/// This class is responsible for loading, parsing, and validating
/// the local2dart configuration from YAML files.
class Local2DartConfigManager {
  /// Creates a new Local2DartConfigManager instance.
  Local2DartConfigManager();

  /// Loads configuration from a YAML file.
  ///
  /// Parameters:
  /// - [yamlPath]: The path to the YAML configuration file.
  ///
  /// Returns: A Local2DartConfig object with the parsed configuration.
  Local2DartConfig loadConfig(String yamlPath) {
    final yaml = YamlHelper.loadFileYaml(yamlPath);
    return Local2DartConfig.fromMap(_convertMapToStringDynamic(yaml));
  }

  /// Converts a `Map<dynamic, dynamic>` to `Map<String, dynamic>`
  ///
  /// This method ensures type safety when working with YAML parsed data
  /// which often comes as `Map<dynamic, dynamic>` but our APIs expect
  /// `Map<String, dynamic>`.
  Map<String, dynamic> _convertMapToStringDynamic(Map<dynamic, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  /// Validates the configuration.
  ///
  /// Parameters:
  /// - [config]: The configuration to validate.
  ///
  /// Returns: True if the configuration is valid, false otherwise.
  bool validateConfig(Local2DartConfig config) {
    // Check that version is a positive integer
    if (config.version <= 0) {
      StatusHelper.failed('Version must be a positive integer');
      return false;
    }

    // Validate table definitions
    for (final entry in config.table.entries) {
      if (!_validateTableDefinition(
          entry.key, entry.value as Map<String, dynamic>)) {
        return false;
      }
    }

    // Validate query definitions
    for (final entry in config.query.entries) {
      if (!_validateQueryDefinition(
          entry.key, entry.value as Map<String, dynamic>)) {
        return false;
      }
    }

    // Validate view definitions
    for (final entry in config.view.entries) {
      if (!_validateViewDefinition(
          entry.key, entry.value as Map<String, dynamic>)) {
        return false;
      }
    }

    return true;
  }

  /// Validates a table definition.
  ///
  /// Parameters:
  /// - [name]: The name of the table.
  /// - [definition]: The table definition to validate.
  ///
  /// Returns: True if the definition is valid, false otherwise.
  bool _validateTableDefinition(String name, Map<String, dynamic> definition) {
    // Check that the table has columns
    final columns = definition['column'] as Map<String, dynamic>?;
    if (columns == null || columns.isEmpty) {
      StatusHelper.failed('Table $name must have at least one column');
      return false;
    }

    // Validate each column
    for (final columnEntry in columns.entries) {
      if (!_validateColumnDefinition(columnEntry.key, columnEntry.value)) {
        return false;
      }
    }

    return true;
  }

  /// Validates a column definition.
  ///
  /// Parameters:
  /// - [name]: The name of the column.
  /// - [definition]: The column definition to validate.
  ///
  /// Returns: True if the definition is valid, false otherwise.
  bool _validateColumnDefinition(String name, dynamic definition) {
    // Column can be either a string (type) or a map (detailed definition)
    if (definition is String) {
      // Just a type, that's fine
      return true;
    } else if (definition is Map) {
      // Detailed definition
      final type = definition['type'] as String?;
      if (type == null || type.isEmpty) {
        StatusHelper.failed('Column $name must have a type');
        return false;
      }

      // Validate constraint if present
      final constraint = definition['constraint'] as String?;
      if (constraint != null) {
        final upperConstraint = constraint.toUpperCase();
        if (upperConstraint != 'PRIMARY KEY' &&
            upperConstraint != 'FOREIGN KEY' &&
            upperConstraint != 'UNIQUE' &&
            upperConstraint != 'CHECK') {
          StatusHelper.failed(
              'Column $name has invalid constraint: $constraint');
          return false;
        }
      }

      return true;
    } else {
      StatusHelper.failed('Column $name has invalid definition');
      return false;
    }
  }

  /// Validates a query definition.
  ///
  /// Parameters:
  /// - [name]: The name of the query.
  /// - [definition]: The query definition to validate.
  ///
  /// Returns: True if the definition is valid, false otherwise.
  bool _validateQueryDefinition(String name, Map<String, dynamic> definition) {
    // Check that the query has columns
    final columns = definition['column'] as Map<String, dynamic>?;
    if (columns == null || columns.isEmpty) {
      StatusHelper.failed('Query $name must have at least one column');
      return false;
    }

    return true;
  }

  /// Validates a view definition.
  ///
  /// Parameters:
  /// - [name]: The name of the view.
  /// - [definition]: The view definition to validate.
  ///
  /// Returns: True if the definition is valid, false otherwise.
  bool _validateViewDefinition(String name, Map<String, dynamic> definition) {
    // Check that the view has columns
    final columns = definition['column'] as Map<String, dynamic>?;
    if (columns == null || columns.isEmpty) {
      StatusHelper.failed('View $name must have at least one column');
      return false;
    }

    // Check that the view has a source table
    final from = definition['from'] as String?;
    if (from == null || from.isEmpty) {
      StatusHelper.failed('View $name must have a source table (from)');
      return false;
    }

    return true;
  }

  /// Parses table definitions from configuration.
  ///
  /// Parameters:
  /// - [config]: The configuration containing table definitions.
  ///
  /// Returns: A map of table names to TableDefinition objects.
  Map<String, TableDefinition> parseTableDefinitions(Local2DartConfig config) {
    final tables = <String, TableDefinition>{};

    config.table.forEach((tableName, tableConfig) {
      if (tableConfig is Map<String, dynamic>) {
        final createIfNotExists =
            tableConfig['create_if_not_exists'] as bool? ?? true;

        // Parse columns
        final columns = <String, ColumnDefinition>{};
        final columnConfig = tableConfig['column'] as Map<String, dynamic>?;
        if (columnConfig != null) {
          columnConfig.forEach((columnName, columnDef) {
            if (columnDef is String) {
              // Simple type definition
              columns[columnName] = ColumnDefinition(
                name: columnName,
                type: columnDef,
              );
            } else if (columnDef is Map<String, dynamic>) {
              // Detailed definition
              columns[columnName] = ColumnDefinition(
                name: columnName,
                type: columnDef['type'] as String? ?? 'TEXT',
                constraint: columnDef['constraint'] as String?,
                autoincrement: columnDef['autoincrement'] as bool? ?? false,
                nullable: columnDef['nullable'] as bool? ?? true,
                defaultValue: columnDef['default'],
              );
            }
          });
        }

        // Parse foreign keys
        final foreignKeys = <String, ForeignKeyDefinition>{};
        final foreignConfig = tableConfig['foreign'] as Map<String, dynamic>?;
        if (foreignConfig != null) {
          foreignConfig.forEach((foreignKeyName, foreignDef) {
            if (foreignDef is Map<String, dynamic>) {
              foreignKeys[foreignKeyName] = ForeignKeyDefinition(
                columnName: foreignKeyName,
                toTable: foreignDef['to_table'] as String? ?? '',
                toColumn: foreignDef['to_column'] as String? ?? '',
                onUpdate: foreignDef['on_update'] as String?,
                onDelete: foreignDef['on_delete'] as String?,
              );
            }
          });
        }

        tables[tableName] = TableDefinition(
          name: tableName,
          createIfNotExists: createIfNotExists,
          columns: columns,
          foreignKeys: foreignKeys,
        );
      }
    });

    return tables;
  }
}
