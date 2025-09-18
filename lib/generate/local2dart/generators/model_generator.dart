import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/local2dart/generators/base_generator.dart';
import 'package:morpheme_cli/generate/local2dart/templates/model_template.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Generator for model classes.
///
/// This generator creates model classes for tables, views, and queries
/// based on the configuration.
class ModelGenerator extends BaseGenerator {
  /// Creates a new ModelGenerator instance.
  ///
  /// Parameters:
  /// - [config]: The configuration for generation.
  /// - [packagePath]: The path where the package should be generated.
  ModelGenerator(super.config, super.packagePath);

  @override
  Future<void> generate() async {
    await generateTableModels();
    await generateQueryModels();
    await generateViewModels();
  }

  /// Generates model classes for tables.
  Future<void> generateTableModels() async {
    config.table.forEach((tableName, tableConfig) async {
      if (tableConfig is Map<String, dynamic>) {
        final columns = tableConfig['column'] as Map<String, dynamic>? ?? {};
        final foreigns = tableConfig['foreign'] as Map<String, dynamic>? ?? {};

        final result = _processColumns(
          columns: columns,
          tableName: tableName,
          foreigns: foreigns,
        );

        await _generateModel(
          fileName: '${tableName.snakeCase}_table.dart',
          className: '${tableName.pascalCase}Table',
          importForeign: result.importForeign,
          constructor: result.constructor,
          constructorAssign: result.constructorAssign,
          variables: result.variables,
          toMap: result.toMap,
          fromMap: result.fromMap,
          fromMapWithJoin: result.fromMapWithJoin,
          paramCopyWith: result.paramCopyWith,
          valueCopyWith: result.valueCopyWith,
          props: result.props,
        );
      }
    });
  }

  /// Generates model classes for queries.
  Future<void> generateQueryModels() async {
    config.query.forEach((tableName, queries) async {
      if (queries is Map<String, dynamic>) {
        queries.forEach((queryName, query) async {
          if (query is Map<String, dynamic>) {
            final columns = query['column'] as Map<String, dynamic>? ?? {};

            final result = _processColumns(
              columns: columns,
              tableName: queryName,
              foreigns: {}, // Queries don't have foreign keys
            );

            await _generateModel(
              fileName: '${queryName.snakeCase}_query.dart',
              className: '${queryName.pascalCase}Query',
              importForeign: result.importForeign,
              constructor: result.constructor,
              constructorAssign: result.constructorAssign,
              variables: result.variables,
              toMap: result.toMap,
              fromMap: result.fromMap,
              fromMapWithJoin: result.fromMapWithJoin,
              paramCopyWith: result.paramCopyWith,
              valueCopyWith: result.valueCopyWith,
              props: result.props,
            );
          }
        });
      }
    });
  }

  /// Generates model classes for views.
  Future<void> generateViewModels() async {
    config.view.forEach((viewName, view) async {
      if (view is Map<String, dynamic>) {
        final columns = view['column'] as Map<String, dynamic>? ?? {};

        final result = _processColumns(
          columns: columns,
          tableName: viewName,
          foreigns: {}, // Views don't have foreign keys in this context
        );

        await _generateModel(
          fileName: '${viewName.snakeCase}_view.dart',
          className: '${viewName.pascalCase}View',
          importForeign: result.importForeign,
          constructor: result.constructor,
          constructorAssign: result.constructorAssign,
          variables: result.variables,
          toMap: result.toMap,
          fromMap: result.fromMap,
          fromMapWithJoin: result.fromMapWithJoin,
          paramCopyWith: result.paramCopyWith,
          valueCopyWith: result.valueCopyWith,
          props: result.props,
        );
      }
    });
  }

  /// Processes column definitions and generates code snippets.
  _ColumnProcessingResult _processColumns({
    required Map<String, dynamic> columns,
    required String tableName,
    required Map<String, dynamic> foreigns,
  }) {
    final importForeign = <String>[];
    final constructor = <String>[];
    final constructorAssign = <String>[];
    final variables = <String>[];
    final toMap = <String>[];
    final fromMap = <String>[];
    final fromMapWithJoin = <String>[];
    final props = <String>[];
    final paramCopyWith = <String>[];
    final valueCopyWith = <String>[];

    // Process regular columns
    columns.forEach((columnName, column) {
      String type = 'String';
      bool isTypeBool = false;
      bool isRequired = false;
      bool isPrimary = false;

      if (column is String) {
        // Simple type definition
        type = getDartType(column);
        isTypeBool = type == 'bool';

        constructor.add('this.${columnName.camelCase},');
        variables.add('final $type? ${columnName.camelCase};');
      } else if (column is Map) {
        // Detailed definition
        isPrimary =
            column['constraint']?.toString().toUpperCase() == 'PRIMARY KEY';
        isRequired = isPrimary || column['nullable']?.toString() == 'false';
        type = getDartType(column['type']?.toString() ?? '');
        isTypeBool = type == 'bool';

        variables.add(
            'final $type${isRequired ? '' : '?'} ${columnName.camelCase};');

        if (isPrimary) {
          constructor.add('$type? ${columnName.camelCase},');
          constructorAssign.add(
              '${columnName.camelCase} = ${columnName.camelCase} ?? ${getDefaultType(type)}');
        } else {
          constructor.add(
              '${isRequired ? 'required' : ''} this.${columnName.camelCase},');
        }
      }

      if (isPrimary) {
        toMap.add(
            "if (${columnName.camelCase} != ${getDefaultType(type)}) '${columnName.snakeCase}': ${columnName.camelCase},");
      } else {
        toMap.add(
            "${isRequired ? '' : 'if (${columnName.camelCase} != null)'} '${columnName.snakeCase}':  ${isTypeBool ? '${columnName.camelCase} == true ? 1 : 0' : columnName.camelCase},");
      }

      fromMap.add(_getFromMap(
          columnName: columnName, type: type, isRequired: isRequired));
      props.add(columnName.camelCase);
      paramCopyWith.add('$type? ${columnName.camelCase},');
      valueCopyWith.add(
          '${columnName.camelCase}: ${columnName.camelCase} ?? this.${columnName.camelCase},');
    });

    // Process foreign keys
    foreigns.forEach((foreignName, foreign) {
      if (foreign is Map<String, dynamic>) {
        final String tableNameForeign = foreign['to_table'];
        final String toTable = '${tableNameForeign}_table';
        importForeign.add("import '${toTable.snakeCase}.dart';");
        constructor.add('this.${toTable.camelCase},');
        variables.add('final ${toTable.pascalCase}? ${toTable.camelCase};');
        props.add(toTable.camelCase);
        paramCopyWith.add('${toTable.pascalCase}? ${toTable.camelCase},');
        valueCopyWith.add(
            '${toTable.camelCase}: ${toTable.camelCase} ?? this.${toTable.camelCase},');
      }
    });

    return _ColumnProcessingResult(
      importForeign: importForeign,
      constructor: constructor,
      constructorAssign: constructorAssign,
      variables: variables,
      toMap: toMap,
      fromMap: fromMap,
      fromMapWithJoin: fromMapWithJoin,
      props: props,
      paramCopyWith: paramCopyWith,
      valueCopyWith: valueCopyWith,
    );
  }

  /// Generates the fromMap code for a column.
  String _getFromMap({
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

  /// Generates a model class file.
  Future<void> _generateModel({
    required String fileName,
    required String className,
    required List<String> importForeign,
    required List<String> constructor,
    required List<String> constructorAssign,
    required List<String> variables,
    required List<String> toMap,
    required List<String> fromMap,
    required List<String> fromMapWithJoin,
    required List<String> paramCopyWith,
    required List<String> valueCopyWith,
    required List<String> props,
  }) async {
    final path = join(packagePath, 'lib', 'models', fileName);
    final content = ModelTemplate.generate(
      className: className,
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
    await writeFile(path, content);
  }
}

/// Result of column processing.
class _ColumnProcessingResult {
  final List<String> importForeign;
  final List<String> constructor;
  final List<String> constructorAssign;
  final List<String> variables;
  final List<String> toMap;
  final List<String> fromMap;
  final List<String> fromMapWithJoin;
  final List<String> props;
  final List<String> paramCopyWith;
  final List<String> valueCopyWith;

  _ColumnProcessingResult({
    required this.importForeign,
    required this.constructor,
    required this.constructorAssign,
    required this.variables,
    required this.toMap,
    required this.fromMap,
    required this.fromMapWithJoin,
    required this.props,
    required this.paramCopyWith,
    required this.valueCopyWith,
  });
}
