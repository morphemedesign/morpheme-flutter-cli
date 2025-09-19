/// Represents a column definition in a table.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The SQL type of the column.
  final String type;

  /// The constraint for the column.
  final String? constraint;

  /// Whether the column should autoincrement.
  final bool autoincrement;

  /// Whether the column can be null.
  final bool nullable;

  /// The default value for the column.
  final dynamic defaultValue;

  /// Creates a new ColumnDefinition.
  ColumnDefinition({
    required this.name,
    required this.type,
    this.constraint,
    this.autoincrement = false,
    this.nullable = true,
    this.defaultValue,
  });

  /// Whether this column is a primary key.
  bool get isPrimaryKey => constraint?.toUpperCase() == 'PRIMARY KEY';

  /// Whether this column is a foreign key.
  bool get isForeignKey => constraint?.toUpperCase() == 'FOREIGN KEY';

  /// Whether this column is of boolean type.
  bool get isTypeBool => type.toUpperCase() == 'BOOL';

  /// The Dart type equivalent of the SQL type.
  String get dartType => _convertToDartType(type);

  /// The SQL type (with BOOL converted to INTEGER).
  String get sqlType => isTypeBool ? 'INTEGER' : type.toUpperCase();

  /// Converts an SQL type to its Dart equivalent.
  ///
  /// Parameters:
  /// - [sqlType]: The SQL type to convert.
  ///
  /// Returns: The Dart type as a string.
  String _convertToDartType(String sqlType) {
    switch (sqlType.toUpperCase()) {
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

  @override
  String toString() {
    return 'ColumnDefinition(name: $name, type: $type, constraint: $constraint, '
        'autoincrement: $autoincrement, nullable: $nullable, '
        'defaultValue: $defaultValue)';
  }
}

/// Represents a foreign key definition.
class ForeignKeyDefinition {
  /// The column that is the foreign key.
  final String columnName;

  /// The table that is referenced.
  final String toTable;

  /// The column that is referenced.
  final String toColumn;

  /// The action to take on update.
  final String? onUpdate;

  /// The action to take on delete.
  final String? onDelete;

  /// Creates a new ForeignKeyDefinition.
  ForeignKeyDefinition({
    required this.columnName,
    required this.toTable,
    required this.toColumn,
    this.onUpdate,
    this.onDelete,
  });

  @override
  String toString() {
    return 'ForeignKeyDefinition(columnName: $columnName, toTable: $toTable, '
        'toColumn: $toColumn, onUpdate: $onUpdate, onDelete: $onDelete)';
  }
}

/// Represents a table definition.
class TableDefinition {
  /// The name of the table.
  final String name;

  /// Whether to create the table if it doesn't exist.
  final bool createIfNotExists;

  /// The columns in the table.
  final Map<String, ColumnDefinition> columns;

  /// The foreign keys in the table.
  final Map<String, ForeignKeyDefinition> foreignKeys;

  /// Creates a new TableDefinition.
  TableDefinition({
    required this.name,
    required this.createIfNotExists,
    required this.columns,
    required this.foreignKeys,
  });

  /// Whether the table has foreign keys.
  bool get hasForeignKeys => foreignKeys.isNotEmpty;

  /// Gets the primary key column name.
  String? get primaryKey {
    for (final entry in columns.entries) {
      if (entry.value.isPrimaryKey) {
        return entry.key;
      }
    }
    return null;
  }

  /// Gets the primary key column definition.
  ColumnDefinition? get primaryKeyColumn {
    for (final column in columns.values) {
      if (column.isPrimaryKey) {
        return column;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'TableDefinition(name: $name, createIfNotExists: $createIfNotExists, '
        'columnCount: ${columns.length}, foreignKeyCount: ${foreignKeys.length})';
  }
}
