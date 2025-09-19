/// Configuration model for Local2Dart command.
///
/// This class represents the parsed YAML configuration for local2dart generation.
/// It provides type-safe access to configuration values and handles default values.
class Local2DartConfig {
  /// Database version.
  final int version;

  /// Directory for database files.
  final String dirDatabase;

  /// Whether foreign key constraints are supported.
  final bool foreignKeyConstrainSupport;

  /// Table definitions.
  final Map<String, dynamic> table;

  /// Query definitions.
  final Map<String, dynamic> query;

  /// View definitions.
  final Map<String, dynamic> view;

  /// Seed data definitions.
  final Map<String, dynamic> seed;

  /// Trigger definitions.
  final Map<String, dynamic> trigger;

  /// Creates a new Local2DartConfig instance.
  ///
  /// All parameters are required to ensure proper configuration.
  Local2DartConfig({
    required this.version,
    required this.dirDatabase,
    required this.foreignKeyConstrainSupport,
    required this.table,
    required this.query,
    required this.view,
    required this.seed,
    required this.trigger,
  });

  /// Creates a Local2DartConfig from a map.
  ///
  /// This factory method parses a map (typically from YAML) and creates
  /// a properly typed configuration object with default values for missing keys.
  ///
  /// Parameters:
  /// - [map]: The map containing configuration values.
  ///
  /// Returns: A new Local2DartConfig instance.
  factory Local2DartConfig.fromMap(Map<String, dynamic> map) {
    return Local2DartConfig(
      version: map['version'] as int? ?? 1,
      dirDatabase: map['dir_database'] as String? ?? 'morpheme',
      foreignKeyConstrainSupport:
          map['foreign_key_constrain_support'] as bool? ?? true,
      table: Map<String, dynamic>.from(map['table'] ?? {}),
      query: Map<String, dynamic>.from(map['query'] ?? {}),
      view: Map<String, dynamic>.from(map['view'] ?? {}),
      seed: Map<String, dynamic>.from(map['seed'] ?? {}),
      trigger: Map<String, dynamic>.from(map['trigger'] ?? {}),
    );
  }

  /// Gets a table definition by name.
  ///
  /// Parameters:
  /// - [name]: The name of the table to retrieve.
  ///
  /// Returns: The table definition or null if not found.
  Map<String, dynamic>? getTable(String name) {
    return table[name] as Map<String, dynamic>?;
  }

  /// Gets a query definition by table name.
  ///
  /// Parameters:
  /// - [tableName]: The name of the table to retrieve queries for.
  ///
  /// Returns: The query definitions or an empty map if not found.
  Map<String, dynamic> getQueries(String tableName) {
    return Map<String, dynamic>.from(query[tableName] ?? {});
  }

  /// Gets a view definition by name.
  ///
  /// Parameters:
  /// - [name]: The name of the view to retrieve.
  ///
  /// Returns: The view definition or null if not found.
  Map<String, dynamic>? getView(String name) {
    return view[name] as Map<String, dynamic>?;
  }

  /// Gets seed data for a table.
  ///
  /// Parameters:
  /// - [tableName]: The name of the table to retrieve seed data for.
  ///
  /// Returns: The seed data or null if not found.
  Map<String, dynamic>? getSeed(String tableName) {
    return seed[tableName] as Map<String, dynamic>?;
  }

  /// Gets a trigger definition by name.
  ///
  /// Parameters:
  /// - [name]: The name of the trigger to retrieve.
  ///
  /// Returns: The trigger definition or null if not found.
  Map<String, dynamic>? getTrigger(String name) {
    return trigger[name] as Map<String, dynamic>?;
  }

  @override
  String toString() {
    return 'Local2DartConfig(version: $version, dirDatabase: $dirDatabase, '
        'foreignKeyConstrainSupport: $foreignKeyConstrainSupport, '
        'tableCount: ${table.length}, queryCount: ${query.length}, '
        'viewCount: ${view.length}, seedCount: ${seed.length}, '
        'triggerCount: ${trigger.length})';
  }
}
