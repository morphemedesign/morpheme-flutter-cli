import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';
import '../templates/api_code_templates.dart';

/// Generates data layer components for API integration.
///
/// Creates remote data sources, models (body/response), and repository
/// implementations with proper error handling and caching support.
class DataLayerGenerator {
  DataLayerGenerator({
    required this.typeResolver,
    required this.codeTemplates,
  });

  final ApiTypeResolver typeResolver;
  final ApiCodeTemplates codeTemplates;

  /// Generates complete data layer for the API.
  ///
  /// Components generated:
  /// - Remote data source interface and implementation
  /// - Request body models (if not using json2dart)
  /// - Response models (if return data is model type)
  /// - Repository implementation with error handling
  void generateDataLayer(ApiGenerationConfig config) {
    generateDataSource(config);

    if (!config.json2dart) {
      generateModelBody(config);
    }

    if (!config.json2dart && config.isReturnDataModel) {
      generateModelResponse(config);
    }

    generateRepositoryImpl(config);
  }

  /// Generates remote data source interface and implementation.
  ///
  /// Creates the data source that handles HTTP communication with proper
  /// method handling, headers, and caching support.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateDataSource(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'data', 'datasources');
    createDir(path);

    final filePath = join(path, '${config.pageName}_remote_data_source.dart');

    // Load headers from file if specified
    String? headers;
    if (config.headerPath != null && exists(config.headerPath!)) {
      try {
        headers = read(config.headerPath!).join('\n');
      } catch (e) {
        StatusHelper.warning(e.toString());
      }
    }

    if (!exists(filePath)) {
      // Create new data source file
      _createNewDataSourceFile(config, filePath, headers);
    } else {
      // Update existing data source file
      _updateExistingDataSourceFile(config, filePath, headers);
    }

    StatusHelper.generated(filePath);
  }

  /// Generates request body model.
  ///
  /// Creates a basic model class with sample fields for the API request body.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateModelBody(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'data', 'models', 'body');
    createDir(path);

    final filePath = join(path, '${config.apiName}_body.dart');
    final content = codeTemplates.generateDataModelBodyTemplate(config);

    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Generates response model.
  ///
  /// Creates a basic model class with sample fields for the API response.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateModelResponse(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'data', 'models', 'response');
    createDir(path);

    final filePath = join(path, '${config.apiName}_response.dart');
    final content = codeTemplates.generateDataModelResponseTemplate(config);

    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Generates repository implementation.
  ///
  /// Creates the repository implementation that connects data sources
  /// to domain layer with proper error handling and data transformation.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateRepositoryImpl(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'data', 'repositories');
    createDir(path);

    final filePath = join(path, '${config.pageName}_repository_impl.dart');

    if (!exists(filePath)) {
      // Create new repository implementation file
      _createNewRepositoryImplFile(config, filePath);
    } else {
      // Update existing repository implementation file
      _updateExistingRepositoryImplFile(config, filePath);
    }

    StatusHelper.generated(filePath);
  }

  /// Creates a new data source file with the generated template
  void _createNewDataSourceFile(
      ApiGenerationConfig config, String filePath, String? headers) {
    final content =
        codeTemplates.generateDataSourceTemplate(config, headers: headers);
    filePath.write(content);
  }

  /// Updates an existing data source file by adding new method
  void _updateExistingDataSourceFile(
      ApiGenerationConfig config, String filePath, String? headers) {
    String data = read(filePath).join('\n');

    // Check if we need to add typed_data import
    final isNeedImportTypeData = config.returnData == 'body_bytes' &&
        !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

    if (isNeedImportTypeData) {
      data = '''import 'dart:typed_data';
        
        $data''';
    }

    // Update imports section
    data = data.replaceAll(
        RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
        '''import 'package:core/core.dart';
    
import '../models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../models/response/${config.apiName}_response.dart';''' : ''}''');

    // Update abstract class with new method
    final responseClass = typeResolver.whenMethod(
      config.method,
      onStream: () => typeResolver.resolveStreamResponseClass(config),
      onFuture: () => typeResolver.resolveResponseClass(config),
    );
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);

    data = data.replaceAll(
        RegExp(
            'abstract\\s?class\\s?${config.pageClassName}RemoteDataSource\\s?{',
            multiLine: true),
        '''abstract class ${config.pageClassName}RemoteDataSource {
  ${typeResolver.resolveFlutterClassOfMethod(config.method)}<$responseClass> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}});''');

    // Add implementation method
    final methodOfDataSource =
        codeTemplates.generateDataSourceMethod(config, headers: headers);
    data = data.replaceAll(RegExp(r'\}(?![\s\S]*\})', multiLine: true),
        '''      $methodOfDataSource
}''');

    filePath.write(data);
  }

  /// Creates a new repository implementation file
  void _createNewRepositoryImplFile(
      ApiGenerationConfig config, String filePath) {
    final content = codeTemplates.generateRepositoryImplTemplate(config);
    filePath.write(content);
  }

  /// Updates an existing repository implementation file
  void _updateExistingRepositoryImplFile(
      ApiGenerationConfig config, String filePath) {
    String data = read(filePath).join();

    final isDataDatasourceAlready =
        RegExp(r'remote_data_source\.dart').hasMatch(data);
    final isDomainRepositoryAlready =
        RegExp(r'repository\.dart').hasMatch(data);

    final isNeedMapper =
        (RegExp(r'.toEntity()').hasMatch(data) || config.isReturnDataModel) &&
            !RegExp(r'''import '../../mapper.dart';''').hasMatch(data);

    final isNeedImportTypeData = config.returnData == 'body_bytes' &&
        !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

    if (isNeedImportTypeData) {
      data = '''import 'dart:typed_data';
        
        $data''';
    }

    // Update imports
    data = data.replaceAll(
        RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
        '''import 'package:core/core.dart';

${isNeedMapper ? '''import '../../mapper.dart';''' : ''}          
${isDataDatasourceAlready ? '' : "import '../datasources/${config.pageName}_remote_data_source.dart';"}
${isDomainRepositoryAlready ? '' : "import '../../domain/repositories/${config.pageName}_repository.dart';"}
${config.isReturnDataModel ? '''import '../../domain/entities/${config.apiName}_entity.dart';''' : ''}
import '../models/body/${config.apiName}_body.dart';''');

    // Add new method
    final isEmpty = RegExp(r'remoteDataSource;(\s+)?}(\s+)?}').hasMatch(data);
    final newMethod = _generateRepositoryMethod(config);

    data = data.replaceAll(RegExp(r'}(\s+)?}(\s+)?}'), '''${isEmpty ? '' : '}}'}

  $newMethod
}''');

    filePath.write(data);
  }

  /// Generates the repository method implementation
  String _generateRepositoryMethod(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);
    final entityImpl = typeResolver.generateEntityReturn(config);

    return '''@override
  ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers,}) async* {
    try {
      final response = remoteDataSource.${config.apiMethodName}(
        body,
        headers: headers,
      );
      await for (final data in response) {
        yield Right($entityImpl);
      }
    } on MorphemeException catch (e) {
      yield Left(e.toMorphemeFailure());
    } catch (e) {
      yield Left(InternalFailure(e.toString()));
    }
  }''';
      },
      onFuture: () {
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}}) async {
    try {
      final data = await remoteDataSource.${config.apiMethodName}(body, headers: headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'cacheStrategy: cacheStrategy,' : ''});
      return Right($entityImpl);
    } on MorphemeException catch (e) {
      return Left(e.toMorphemeFailure());
    } catch (e) {
      return Left(InternalFailure(e.toString()));
    }
  }''';
      },
    )}''';
  }
}
