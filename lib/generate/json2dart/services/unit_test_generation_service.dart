import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

/// Service for generating comprehensive unit tests for JSON2Dart models
///
/// This service handles the generation of unit tests for data sources, repositories,
/// entities, use cases, blocs, and mapper extensions.
class UnitTestGenerationService {
  final String _projectName;
  final String _bodyDateFormat;
  final String _responseDateFormat;
  final List<ModelClassName> _listClassNameUnitTest = [];

  UnitTestGenerationService({
    required String projectName,
    String bodyDateFormat = '.toIso8601String()',
    String responseDateFormat = '.toIso8601String()',
  })  : _projectName = projectName,
        _bodyDateFormat = bodyDateFormat,
        _responseDateFormat = responseDateFormat;

  /// Generates all unit tests for a page
  ///
  /// [testPath] - Base path for test files
  /// [featureName] - Feature name
  /// [pageName] - Page name
  /// [testData] - Test data for all APIs
  void generatePageTests({
    required String testPath,
    required String featureName,
    required String pageName,
    required List<Map<String, String>> testData,
  }) {
    _createDataSourceTests(testPath, featureName, pageName, testData);
    _createRepositoryTests(testPath, featureName, pageName, testData);
    _createEntityTests(testPath, featureName, pageName, testData);
    _createRepositoryInterfaceTests(testPath, featureName, pageName, testData);
    _createUseCaseTests(testPath, featureName, pageName, testData);
    _createBlocTests(testPath, featureName, pageName, testData);
    _createCubitTests(testPath, featureName, pageName, testData);
    _createPageTests(testPath, featureName, pageName, testData);
    _createWidgetTests(testPath, featureName, pageName, testData);
    _createMapperTests(testPath, featureName, pageName, testData);
  }

  /// Generates individual API test data
  ///
  /// [testPath] - Path for test files
  /// [featureName] - Feature name
  /// [pageName] - Page name
  /// [apiName] - API name
  /// [bodyData] - Request body data
  /// [responseData] - Response data
  /// [method] - HTTP method
  /// [paramPath] - URL parameters
  /// [headers] - Request headers
  /// [cacheStrategy] - Caching strategy
  /// [ttl] - Cache TTL
  /// [keepExpiredCache] - Whether to keep expired cache
  /// [returnData] - Return data type
  /// Returns test data map
  Map<String, String> generateApiTestData({
    required String testPath,
    required String featureName,
    required String pageName,
    required String apiName,
    required String jsonBody,
    required String jsonResponse,
    required dynamic bodyData,
    required dynamic responseData,
    required String method,
    required List<String> paramPath,
    required String? pathHeader,
    required String? cacheStrategy,
    required int? ttl,
    required bool? keepExpiredCache,
    required String returnData,
  }) {
    final result = <String, String>{};

    // Generate endpoint
    final endpoint =
        'final url${apiName.pascalCase} = ${_projectName.pascalCase}Endpoints.${apiName.camelCase}${paramPath.isEmpty ? '' : '(${paramPath.map((e) => "'$e',").join()})'};';

    // Generate test variables
    final bodyVariable = _generateBodyVariable(apiName, bodyData, paramPath);
    final responseVariable = _isReturnDataModel(returnData)
        ? _generateResponseVariable(apiName, responseData, 'Response')
        : '';
    final entityVariable = _isReturnDataModel(returnData)
        ? _generateResponseVariable(apiName, responseData, 'Entity')
        : '';

    // Create test files
    _createBodyModelTest(testPath, featureName, pageName, apiName, jsonBody,
        bodyVariable, bodyData is List);

    String formattedJsonResponse = '';
    if (_isReturnDataModel(returnData)) {
      formattedJsonResponse = _createJsonResponseTest(
          testPath, featureName, pageName, apiName, jsonResponse);
      _createResponseModelTest(testPath, featureName, pageName, apiName,
          formattedJsonResponse, responseVariable, responseData is List);
    }

    // Handle headers
    String? headers;
    if (pathHeader != null && exists(pathHeader)) {
      try {
        headers = read(pathHeader).join('\n');
        headers =
            'headers: $headers.map((key, value) => MapEntry(key, value.toString()))';
      } catch (e) {
        StatusHelper.warning('Failed to read headers: $e');
      }
    }

    // Populate result
    result['apiName'] = apiName;
    result['body'] = bodyVariable;
    result['response'] = responseVariable;
    result['entity'] = entityVariable;
    result['jsonBody'] = jsonBody;
    result['jsonResponse'] = jsonResponse;
    result['method'] = method;
    result['endpoint'] = endpoint;
    result['header'] = headers ?? '';
    result['isBodyList'] = bodyData is List ? 'true' : 'false';
    result['isResponseList'] = responseData is List ? 'true' : 'false';
    result['cacheStrategy'] = cacheStrategy ?? '';
    result['ttl'] = ttl?.toString() ?? '';
    result['keepExpiredCache'] = keepExpiredCache?.toString() ?? '';
    result['returnData'] = returnData;

    return result;
  }

  /// Generates body variable for testing
  String _generateBodyVariable(
      String apiName, dynamic body, List<String> paramPath) {
    final List<Map> data = [];
    if (body is List) {
      data.addAll(body.cast<Map>());
    } else if (body is Map) {
      data.add(body);
    }

    final results = <String>[];
    _listClassNameUnitTest.clear();

    for (final element in data) {
      final keys = element.keys;
      final variables = keys
          .map((e) => _generateValueUnitTest(e.toString(), element[e],
              apiName.pascalCase, '', 'body_${apiName.snakeCase}'))
          .join(',');
      results.add(
          'body_${apiName.snakeCase}.${apiName.pascalCase}Body(${paramPath.map((e) => "${e.camelCase}: '$e',").join()} $variables${variables.isNotEmpty ? ',' : ''})');
    }

    return results.length > 1
        ? '[${results.join(',')}];'
        : '${results.join(',')};';
  }

  /// Generates response variable for testing
  String _generateResponseVariable(
      String apiName, dynamic body, String suffix) {
    final List<Map> data = [];
    if (body is List) {
      data.addAll(body.cast<Map>());
    } else if (body is Map) {
      data.add(body);
    }

    final results = <String>[];
    _listClassNameUnitTest.clear();

    for (final element in data) {
      final keys = element.keys;
      final variables = keys
          .map((e) => _generateValueUnitTest(
              e.toString(),
              element[e],
              apiName.pascalCase,
              '',
              '${suffix.toLowerCase()}_${apiName.snakeCase}'))
          .join(',');
      results.add(
          '${suffix.toLowerCase()}_${apiName.snakeCase}.${apiName.pascalCase}$suffix($variables${variables.isNotEmpty ? ',' : ''})');
    }

    return results.length > 1
        ? '[${results.join(',')}];'
        : '${results.join(',')};';
  }

  /// Generates unit test values for complex objects
  String _generateValueUnitTest(
    String key,
    dynamic value,
    String suffix,
    String parent,
    String asImport, [
    String? parentList,
  ]) {
    final variable = key.camelCase;

    if (value is Map<String, dynamic>) {
      final apiClassName = ModelClassNameHelper.getClassName(
        _listClassNameUnitTest,
        suffix,
        key.pascalCase,
        false,
        true,
        parent,
        parentList,
      );

      final children = <String>[];
      _processMapChildren(
          value, suffix, apiClassName, asImport, parentList, children);

      return '$variable: $asImport.$apiClassName(${children.join(',')})';
    }

    if (value is List) {
      return _processListValue(
          key, value, suffix, parent, asImport, parentList);
    }

    if (value is String) {
      if (_isDateTime(value)) {
        return '$variable: DateTime.tryParse(\'$value\')';
      }
      return "$variable: '$value'";
    }

    return '$variable: ${value.toString()}';
  }

  /// Processes map children for unit test generation
  void _processMapChildren(
    Map<String, dynamic> value,
    String suffix,
    String apiClassName,
    String asImport,
    String? parentList,
    List<String> children,
  ) {
    // Process Maps first
    value.forEach((key, child) {
      if (child is Map) {
        children.add(_generateValueUnitTest(
            key.toString(), child, suffix, apiClassName, asImport, parentList));
      }
    });

    // Process Lists
    value.forEach((key, child) {
      if (child is List) {
        children.add(_generateValueUnitTest(
            key.toString(), child, suffix, apiClassName, asImport, parentList));
      }
    });

    // Process primitives
    value.forEach((key, child) {
      if (child is! List && child is! Map) {
        children.add(_generateValueUnitTest(
            key.toString(), child, suffix, apiClassName, asImport, parentList));
      }
    });
  }

  /// Processes list values for unit test generation
  String _processListValue(
    String key,
    List<dynamic> value,
    String suffix,
    String parent,
    String asImport,
    String? parentList,
  ) {
    final variable = key.camelCase;

    if (value.isEmpty) {
      return '$variable: []';
    }

    if (value.first is Map) {
      String list = '[';
      final apiClassName = ModelClassNameHelper.getClassName(
        _listClassNameUnitTest,
        suffix,
        key.pascalCase,
        false,
        true,
        parent,
        parentList != null ? parentList + parent : parent,
      );

      final parentOfChild =
          parentList != null ? parentList + apiClassName : apiClassName;

      for (final element in value) {
        final children = <String>[];
        final elementMap = element as Map<String, dynamic>;
        _processMapChildren(elementMap, suffix, apiClassName, asImport,
            parentOfChild, children);
        list += '$asImport.$apiClassName(${children.join(',')}),';
      }

      list += ']';
      return '$variable: $list';
    } else if (value.first is String) {
      return '$variable: [${value.map((e) => "'$e'").join(',')}]';
    } else {
      return '$variable: [${value.join(',')}]';
    }
  }

  /// Creates body model test file
  void _createBodyModelTest(
    String testPath,
    String featureName,
    String pageName,
    String apiName,
    String jsonBody,
    String bodyVariable,
    bool isBodyList,
  ) {
    final path = join(testPath, 'data', 'models', 'body');
    createDir(path);

    final content =
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import
        
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';
import 'package:$featureName/$pageName/data/models/body/${apiName.snakeCase}_body.dart' as body_${apiName.snakeCase};

Future<void> main() async {
  initializeDateFormatting();

  test('Test body convert to map', () {
    ${_getConstOrFinalValue(bodyVariable)} body${apiName.pascalCase} = $bodyVariable

    final map = ${isBodyList ? 'body${apiName.pascalCase}.map((e) => e.toMap()).toList()' : 'body${apiName.pascalCase}.toMap()'};

    expect(map, ${_changeDateTimeFromMapJsonBody(jsonBody)});
  });
}''';

    final filePath = join(path, '${apiName.snakeCase}_body_test.dart');
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Creates response model test file
  void _createResponseModelTest(
    String testPath,
    String featureName,
    String pageName,
    String apiName,
    String jsonResponse,
    String responseVariable,
    bool isResponseList,
  ) {
    final path = join(testPath, 'data', 'models', 'response');
    createDir(path);

    final content =
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import

${isResponseList ? "import 'dart:convert';" : ''}
        
import 'package:core/core.dart';
import 'package:$featureName/$pageName/mapper.dart';
import 'package:$featureName/$pageName/data/models/response/${apiName.snakeCase}_response.dart' as response_${apiName.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${apiName.snakeCase}_entity.dart' as entity_${apiName.snakeCase};
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

Future<void> main() async {
  initializeDateFormatting();

  ${_getConstOrFinalValue(responseVariable)} response${apiName.pascalCase} = $responseVariable
  final ${isResponseList ? 'List<Map<String, dynamic>>' : 'Map<String, dynamic>'} map = ${_changeDateTimeFromMapJson(jsonResponse)};

  ${_generateMapperTests(apiName, isResponseList)}

  ${_generateFromJsonTests(apiName, pageName, isResponseList)}

  ${_generateFromMapTests(apiName, isResponseList)}

  ${_generateToMapTests(apiName, isResponseList)}

  ${_generateToJsonTests(apiName, isResponseList)}
}''';

    final filePath = join(path, '${apiName.snakeCase}_response_test.dart');
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Creates JSON response test file
  String _createJsonResponseTest(
    String testPath,
    String featureName,
    String pageName,
    String apiName,
    String jsonResponse,
  ) {
    final path = join(testPath, 'json');
    createDir(path);

    String formattedJsonString = jsonResponse;
    try {
      final jsonObject = json.decode(jsonResponse) as Map<String, dynamic>;
      final processedJson = _processJsonForTest(jsonObject);
      formattedJsonString = json.encode(processedJson);
    } catch (_) {
      // Keep original if parsing fails
    }

    final filePath = join(path, '${apiName.snakeCase}_success.json');
    filePath.write(formattedJsonString);
    StatusHelper.generated(filePath);

    return formattedJsonString;
  }

  // Helper methods for test generation

  /// Generates mapper test cases
  String _generateMapperTests(String apiName, bool isResponseList) {
    return isResponseList
        ? '''test('mapper response model to ${apiName.pascalCase}Entity entity', () async {
    expect(response${apiName.pascalCase}.map((e) => e.toEntity()).toList(), isA<List<entity_${apiName.snakeCase}.${apiName.pascalCase}Entity>>());
  });'''
        : '''test('mapper response model to ${apiName.pascalCase}Entity entity', () async {
    expect(response${apiName.pascalCase}.toEntity(), isA<entity_${apiName.snakeCase}.${apiName.pascalCase}Entity>());
  });''';
  }

  /// Generates fromJson test cases
  String _generateFromJsonTests(
      String apiName, String pageName, bool isResponseList) {
    return '''group('fromJson', () {
    test(
      'should return a valid model when the JSON is real data',
      () async {
        // arrange
        final json = readJsonFile('test/${pageName}_test/json/${apiName}_success.json');
        // act
        ${isResponseList ? '''final mapResponse = jsonDecode(json);
        final result = mapResponse is List
            ? List.from(
                mapResponse.map((e) => response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(e)))
            : [response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(mapResponse)];''' : 'final result = response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromJson(json);'}
        // assert
        expect(result, response${apiName.pascalCase});
      },
    );
  });''';
  }

  /// Generates fromMap test cases
  String _generateFromMapTests(String apiName, bool isResponseList) {
    return '''group('fromMap', () {
    test(
      'should return a valid model when the Map is an map of response model',
      () async {
        // act
        ${isResponseList ? '''final result = map
            .map((e) =>
                response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(e))
            .toList();''' : 'final result = response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(map);'}
        // assert
        expect(result, response${apiName.pascalCase});
      },
    );
  });''';
  }

  /// Generates toMap test cases
  String _generateToMapTests(String apiName, bool isResponseList) {
    return '''group('toMap', () {
    test(
      'should return a map containing the proper model',
      () async {
        // act
        ${isResponseList ? 'final result = response${apiName.pascalCase}.map((e) => e.toMap()).toList();' : 'final result = response${apiName.pascalCase}.toMap();'}
        // assert
        expect(result, map);
      },
    );
  });''';
  }

  /// Generates toJson test cases
  String _generateToJsonTests(String apiName, bool isResponseList) {
    return '''group('toJson', () {
    test(
      'should return a JSON String containing the proper model',
      () async {
        // act
        ${isResponseList ? 'final result = jsonEncode(response${apiName.pascalCase});' : 'final result = response${apiName.pascalCase}.toJson();'}
        // assert
        expect(result, isA<String>());
      },
    );
  });''';
  }

  // Data source test generation methods
  void _createDataSourceTests(String testPath, String featureName,
      String pageName, List<Map<String, String>> testData) {
    final path = join(testPath, 'data', 'datasources');
    createDir(path);

    final content =
        _generateDataSourceTestContent(featureName, pageName, testData);
    final filePath = join(path, '${pageName}_remote_data_source_test.dart');
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  // Repository test generation methods
  void _createRepositoryTests(String testPath, String featureName,
      String pageName, List<Map<String, String>> testData) {
    final path = join(testPath, 'data', 'repositories');
    createDir(path);

    final content =
        _generateRepositoryTestContent(featureName, pageName, testData);
    final filePath = join(path, '${pageName}_repository_impl_test.dart');
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  // Other test generation methods
  void _createEntityTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'domain', 'entities');
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void _createRepositoryInterfaceTests(String testPath, String featureName,
      String pageName, List<Map<String, String>> testData) {
    final path = join(testPath, 'domain', 'repositories');
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void _createUseCaseTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'domain', 'usecases');
    createDir(path);

    for (final testItem in testData) {
      final apiName = testItem['apiName'];
      if (apiName != null && _shouldCreateUseCase(testItem)) {
        final content =
            _generateUseCaseTestContent(featureName, pageName, testItem);
        final filePath = join(path, '${apiName.snakeCase}_use_case_test.dart');
        filePath.write(content);
        StatusHelper.generated(filePath);
      }
    }
  }

  void _createBlocTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'presentation', 'bloc');
    createDir(path);

    for (final testItem in testData) {
      final apiName = testItem['apiName'];
      if (apiName != null && _shouldCreateBloc(testItem)) {
        final content =
            _generateBlocTestContent(featureName, pageName, testItem);
        final filePath = join(path, '${apiName.snakeCase}_bloc_test.dart');
        filePath.write(content);
        StatusHelper.generated(filePath);
      }
    }
  }

  void _createCubitTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'presentation', 'cubit');
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void _createPageTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'presentation', 'pages');
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void _createWidgetTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final path = join(testPath, 'presentation', 'widgets');
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void _createMapperTests(String testPath, String featureName, String pageName,
      List<Map<String, String>> testData) {
    final content = _generateMapperTestContent(featureName, pageName, testData);
    final filePath = join(testPath, 'mapper_test.dart');
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  // Helper methods
  bool _isReturnDataModel(String returnData) => returnData == 'model';

  bool _isDateTime(String value) {
    return RegExp(
            r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
        .hasMatch(value);
  }

  String _getConstOrFinalValue(String value) {
    return RegExp(r'\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?')
            .hasMatch(value)
        ? 'final'
        : 'const';
  }

  String _changeDateTimeFromMapJson(String json) {
    final regexDateTime =
        RegExp(r'"\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?"');
    return json.replaceAllMapped(regexDateTime,
        (match) => 'DateTime.tryParse(${match.group(0)})?$_responseDateFormat');
  }

  String _changeDateTimeFromMapJsonBody(String json) {
    final regexDateTime =
        RegExp(r'"\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?"');
    return json.replaceAllMapped(regexDateTime,
        (match) => 'DateTime.tryParse(${match.group(0)})?$_bodyDateFormat');
  }

  Map<String, dynamic> _processJsonForTest(Map<String, dynamic> jsonObject) {
    jsonObject.forEach((key, value) {
      if (value is String && _isDateTime(value)) {
        jsonObject[key] = _formatDateString(value);
      } else if (value is Map<String, dynamic>) {
        jsonObject[key] = _processJsonForTest(value);
      } else if (value is List) {
        jsonObject[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _processJsonForTest(item);
          } else if (item is String && _isDateTime(item)) {
            return _formatDateString(item);
          }
          return item;
        }).toList();
      }
    });
    return jsonObject;
  }

  String _formatDateString(String input) {
    if (_isDateTime(input)) {
      final date = DateTime.tryParse(input);
      if (date != null) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      }
    }
    return input;
  }

  bool _shouldCreateUseCase(Map<String, String> testItem) {
    final method = testItem['method'] ?? '';
    return !method.toLowerCase().contains('sse');
  }

  bool _shouldCreateBloc(Map<String, String> testItem) {
    final method = testItem['method'] ?? '';
    return !method.toLowerCase().contains('sse');
  }

  // Content generation methods
  String _generateDataSourceTestContent(
      String featureName, String pageName, List<Map<String, String>> testData) {
    final resultModelUnitTest = testData;
    return '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import

import 'dart:convert';
${resultModelUnitTest.any((element) => element['returnData'] == 'body_bytes') ? '''import 'dart:typed_data';''' : ''}
        
import 'package:${featureName.snakeCase}/$pageName/data/datasources/${pageName}_remote_data_source.dart';
${resultModelUnitTest.map((e) => '''import 'package:${featureName.snakeCase}/$pageName/data/models/body/${e['apiName']?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${_isReturnDataModel(e['returnData']!) ? '''import 'package:${featureName.snakeCase}/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};''' : ''}''').join('\n')}
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockMorphemeHttp extends Mock implements MorphemeHttp {}

Future<void> main() async {
  initializeDateFormatting();

  late MockMorphemeHttp http;
  late ${pageName.pascalCase}RemoteDataSource remoteDataSource;

  ${resultModelUnitTest.map((e) => '''${e['endpoint']}
  ${_getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}''').join('\n')}

  setUp(() {
    http = MockMorphemeHttp();
    remoteDataSource = ${pageName.pascalCase}RemoteDataSourceImpl(http: http);
  });

  ${resultModelUnitTest.map((e) {
      final className = e['apiName']?.pascalCase;
      final methodName = e['apiName']?.camelCase;
      final returnData = e['returnData'] ?? 'model';

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final isSse = e['method']?.toLowerCase().contains('sse') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];
      final header = e['header']?.isEmpty ?? true ? '' : '${e['header']},';
      final body = (e['isBodyList'] == 'true' && !isMultipart)
          ? 'jsonEncode(body$className.map((e) => e.toMap()).toList()),'
          : 'body$className.toMap()${isMultipart ? '.map((key, value) => MapEntry(key, value.toString()))' : ''},';
      final cacheStrategy = e['cacheStrategy']?.isEmpty ?? true
          ? null
          : CacheStrategy.fromString(e['cacheStrategy']!);
      final ttl =
          e['ttl']?.isEmpty ?? true ? null : int.tryParse(e['ttl'] ?? '');
      final keepExpiredCache = e['keepExpiredCache']?.isEmpty ?? true
          ? null
          : e['keepExpiredCache'] == 'true';

      final paramCacheStrategy = isSse || isMultipart
          ? ''
          : cacheStrategy.toParamCacheStrategyTest(
              ttl: ttl, keepExpiredCache: keepExpiredCache);

      final expectSuccess = switch (returnData) {
        'header' => '''expect(result, isA<Map<String, String>>());''',
        'body_bytes' => '''expect(result, isA<Uint8List>());''',
        'body_string' => '''expect(result, isA<String>());''',
        'status_code' => '''expect(result, isA<int>());''',
        'raw' => '''expect(result, isA<Response>());''',
        'model' =>
          '''expect(result, isA<${'response_${className?.snakeCase}'}.${className}Response>());''',
        _ => "''",
      };

      final isCreateTest = _whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        return '';
      }

      return '''group('$className Api Remote Data Source', () {
    test(
      'should peform fetch & return response',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenAnswer((_) async => Response('{}', 200));
        // act
        final result = await remoteDataSource.$methodName(body$className);
        // assert
        verify(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy));
        $expectSuccess
      },
    );

    test(
      'should throw a RedirectionException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(RedirectionException(statusCode: 300, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<RedirectionException>()));
      },
    );

    test(
      'should throw a ClientException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(ClientException(statusCode: 400, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<ClientException>()));
      },
    );

    test(
      'should throw a ServerException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(ServerException(statusCode: 500, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<ServerException>()));
      },
    );

    test(
      'should throw a TimeoutException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(TimeoutException());
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<TimeoutException>()));
      },
    );

    test(
      'should throw a UnauthorizedException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(UnauthorizedException(statusCode: 401, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<UnauthorizedException>()));
      },
    );

    test(
      'should throw a RefreshTokenException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(RefreshTokenException(statusCode: 401, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<RefreshTokenException>()));
      },
    );

    test(
      'should throw a NoInternetException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(NoInternetException());
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<NoInternetException>()));
      },
    );
  });
''';
    }).join('\n')}
}''';
  }

  String _generateRepositoryTestContent(
      String featureName, String pageName, List<Map<String, String>> testData) {
    final resultModelUnitTest = testData;
    return '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import

${resultModelUnitTest.any((element) => element['returnData'] == 'body_bytes') ? '''import 'dart:typed_data';''' : ''}
        
import 'package:$featureName/$pageName/data/datasources/${pageName}_remote_data_source.dart';
import 'package:$featureName/$pageName/data/repositories/${pageName}_repository_impl.dart';
${resultModelUnitTest.map((e) => '''import 'package:$featureName/$pageName/data/models/body/${e['apiName']?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${_isReturnDataModel(e['returnData']!) ? '''import 'package:$featureName/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${e['apiName']?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : ''}''').join('\n')}
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockRemoteDataSource extends Mock implements ${pageName.pascalCase}RemoteDataSource {}

Future<void> main() async {
  late MockRemoteDataSource mockRemoteDatasource;
  late ${pageName.pascalCase}RepositoryImpl repository;

  setUp(() {
    mockRemoteDatasource = MockRemoteDataSource();
    repository = ${pageName.pascalCase}RepositoryImpl(
      remoteDataSource: mockRemoteDatasource,
    );
  });

  ${resultModelUnitTest.map((e) {
      final className = e['apiName']?.pascalCase;
      final methodName = e['apiName']?.camelCase;
      final returnData = e['returnData'] ?? 'model';

      final responseMock = switch (returnData) {
        'header' => '{}',
        'body_bytes' => 'Uint8List(0)',
        'body_string' => "''",
        'status_code' => '200',
        'raw' => 'Response(\'\' , 200)',
        _ => "response_${className?.snakeCase}.${className}Response()",
      };

      final expectSuccess = switch (returnData) {
        'header' =>
          '''expect(result, isA<Right<MorphemeFailure, Map<String, String>>>(),);''',
        'body_bytes' =>
          '''expect(result, isA<Right<MorphemeFailure, Uint8List>>(),);''',
        'body_string' =>
          '''expect(result, isA<Right<MorphemeFailure, String>>(),);''',
        'status_code' =>
          '''expect(result, isA<Right<MorphemeFailure, int>>(),);''',
        'raw' =>
          '''expect(result, isA<Right<MorphemeFailure, Response>>(),);''',
        'model' =>
          '''expect(result, isA<Right<MorphemeFailure, entity_${className?.snakeCase}.${className}Entity>>(),);''',
        _ => "''",
      };

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];

      final isCreateTest = _whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        return '';
      }

      return '''group('$className Api Repository', () {
    ${_getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}

    test(
        'should return response data when the call to remote data source is successful',
        () async {
      // arrange
      when(() => mockRemoteDatasource.$methodName(body$className)).thenAnswer((_) async => $responseMock);
      // act
      final result = await repository.$methodName(body$className);
      // assert
      verify(() => mockRemoteDatasource.$methodName(body$className));
      $expectSuccess
    });

    test(
      'should return redirection exception when the call to remote data source is unsuccessful',
      () async {
        final exception = RedirectionException(statusCode: 300, jsonBody: '{}');
        final failure = RedirectionFailure(
          exception.toString(),
          statusCode: 300,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return client failure when the call to remote data source is unsuccessful',
      () async {
        final exception = ClientException(statusCode: 400, jsonBody: '{}');
        final failure = ClientFailure(
          exception.toString(),
          statusCode: 400,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return server failure when the call to remote data source is unsuccessful',
      () async {
        final exception = ServerException(statusCode: 500, jsonBody: '{}');
        final failure = ServerFailure(
          exception.toString(),
          statusCode: 500,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return unauthorized failure when the call to remote data source is unsuccessful',
      () async {
        final exception =
            UnauthorizedException(statusCode: 401, jsonBody: '{}');
        final failure = UnauthorizedFailure(
          exception.toString(),
          statusCode: 401,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return timeout failure when the call to remote data source is unsuccessful',
      () async {
        final exception = TimeoutException();
        final failure = TimeoutFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return internal failure when the call to remote data source is unsuccessful',
      () async {
        final exception = InternalException();
        final failure = InternalFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return no internet failure when the call to remote data source is unsuccessful',
      () async {
        final exception = NoInternetException();
        final failure = NoInternetFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return internal failure when the call to remote data source is unknown exception',
      () async {
        final exception = Exception('unknown');
        final failure = InternalFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );
  });
''';
    }).join('\n')}
}''';
  }

  String _generateUseCaseTestContent(
      String featureName, String pageName, Map<String, String> testItem) {
    final apiName = testItem['apiName'];
    final className = apiName?.pascalCase;
    final methodName = apiName?.camelCase;
    final returnData = testItem['returnData'] ?? 'model';

    final responseMock = switch (returnData) {
      'header' => '{}',
      'body_bytes' => 'Uint8List(0)',
      'body_string' => "''",
      'status_code' => '200',
      'raw' => 'Response(\'\' , 200)',
      _ => "entity_${className?.snakeCase}.${className}Entity()",
    };

    final expectSuccess = switch (returnData) {
      'header' =>
        '''expect(result, isA<Right<MorphemeFailure, Map<String, String>>>(),);''',
      'body_bytes' =>
        '''expect(result, isA<Right<MorphemeFailure, Uint8List>>(),);''',
      'body_string' =>
        '''expect(result, isA<Right<MorphemeFailure, String>>(),);''',
      'status_code' =>
        '''expect(result, isA<Right<MorphemeFailure, int>>(),);''',
      'raw' => '''expect(result, isA<Right<MorphemeFailure, Response>>(),);''',
      'model' =>
        '''expect(result, isA<Right<MorphemeFailure, entity_${className?.snakeCase}.${className}Entity>>(),);''',
      _ => "''",
    };

    final isMultipart =
        testItem['method']?.toLowerCase().contains('multipart') ?? false;
    final httpMethod = isMultipart
        ? testItem['method'] == 'multipart'
            ? 'postMultipart'
            : testItem['method']
        : testItem['method'];

    final isCreateTest = _whenMethodHttp<bool>(
      httpMethod ?? '',
      onStream: () => false,
      onFuture: () => true,
    );

    if (!isCreateTest) {
      return '';
    }

    return '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import

${returnData == 'body_bytes' ? '''import 'dart:typed_data';''' : ''}
          
import 'package:$featureName/$pageName/domain/repositories/${pageName}_repository.dart';
import 'package:$featureName/$pageName/data/models/body/${apiName?.snakeCase}_body.dart' as body_${testItem['apiName']?.snakeCase};
${_isReturnDataModel(returnData) ? '''import 'package:$featureName/$pageName/domain/entities/${apiName?.snakeCase}_entity.dart' as entity_${testItem['apiName']?.snakeCase};''' : ''}
import 'package:$featureName/$pageName/domain/usecases/${apiName?.snakeCase}_use_case.dart';
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockRepository extends Mock implements ${pageName.pascalCase}Repository {}

Future<void> main() async {
  late ${className}UseCase usecase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    usecase = ${className}UseCase(repository: mockRepository);
  });

  ${_getConstOrFinalValue(testItem['body'] ?? '')} body${testItem['apiName']?.pascalCase} = ${testItem['body']}

  test(
    'Should fetch entity for the body from the repository',
    () async {
      // arrange
      when(() => mockRepository.$methodName(body$className))
          .thenAnswer((_) async => Right($responseMock));
      // act
      final result = await usecase(body$className);
      // assert
      $expectSuccess
      verify(() => mockRepository.$methodName(body$className));
      verifyNoMoreInteractions(mockRepository);
    },
  );
}''';
  }

  String _generateBlocTestContent(
      String featureName, String pageName, Map<String, String> testItem) {
    final apiName = testItem['apiName'];
    final className = apiName?.pascalCase;
    final returnData = testItem['returnData'] ?? 'model';

    final responseMock = switch (returnData) {
      'header' => '{}',
      'body_bytes' => 'Uint8List(0)',
      'body_string' => "''",
      'status_code' => '200',
      'raw' => 'Response(\'\' , 200)',
      _ => "entity_${className?.snakeCase}.${className}Entity()",
    };

    final isMultipart =
        testItem['method']?.toLowerCase().contains('multipart') ?? false;
    final httpMethod = isMultipart
        ? testItem['method'] == 'multipart'
            ? 'postMultipart'
            : testItem['method']
        : testItem['method'];

    final isCreateTest = _whenMethodHttp<bool>(
      httpMethod ?? '',
      onStream: () => false,
      onFuture: () => true,
    );

    if (!isCreateTest) {
      return '';
    }

    return '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import

${testItem['returnData'] == 'body_bytes' ? '''import 'dart:typed_data';''' : ''}
          
import 'package:$featureName/$pageName/data/models/body/${apiName?.snakeCase}_body.dart' as body_${testItem['apiName']?.snakeCase};
${_isReturnDataModel(returnData) ? '''import 'package:$featureName/$pageName/domain/entities/${apiName?.snakeCase}_entity.dart' as entity_${testItem['apiName']?.snakeCase};''' : ''}
import 'package:$featureName/$pageName/domain/usecases/${apiName?.snakeCase}_use_case.dart';
import 'package:$featureName/$pageName/presentation/bloc/${apiName?.snakeCase}/${apiName?.snakeCase}_bloc.dart';
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockUseCase extends Mock implements ${className}UseCase {}

Future<void> main() async {
  late ${className}Bloc bloc;
  late MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockUseCase();
    bloc = ${className}Bloc(useCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be Initial', () {
    expect(bloc.state, equals(${className}Initial()));
  });

  group('$className Bloc', () {
    ${_getConstOrFinalValue(testItem['body'] ?? '')} body${testItem['apiName']?.pascalCase} = ${testItem['body']}

    const timeoutFailed = TimeoutFailure('TimoutFailure');
    const internalFailed = InternalFailure('InternalFailure');

    const redirectionFailed = RedirectionFailure(
      'RedirectionFailure',
      statusCode: 300,
      jsonBody: '{}',
    );

    const clientFailed = ClientFailure(
      'ClientFailure',
      statusCode: 400,
      jsonBody: '{}',
    );

    const serverFailed = ServerFailure(
      'ServerFailure',
      statusCode: 500,
      jsonBody: '{}',
    );

    const unauthorizedFailed = UnauthorizedFailure(
      'UnauthorizedFailure',
      statusCode: 401,
      jsonBody: '{}',
    );

    blocTest<${className}Bloc, ${className}State>(
      'should get data from the subject use case',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer((_) async => Right($responseMock));
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Success] when data is gotten successfully',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer((_) async => Right($responseMock));
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Success(body$className, null, $responseMock, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting timeout failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(timeoutFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, timeoutFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting unauthorized failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(unauthorizedFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, unauthorizedFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting internal failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(internalFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, internalFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting redirection failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(redirectionFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, redirectionFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting client failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(clientFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, clientFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting server failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(serverFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, serverFailed, null),
      ],
    );
  });
}''';
  }

  String _generateMapperTestContent(
      String featureName, String pageName, List<Map<String, String>> testData) {
    final resultModelUnitTest = testData;
    return '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, require_trailing_commas, prefer_single_quotes, prefer_double_quotes, unused_import
        
import 'package:$featureName/$pageName/mapper.dart';
${resultModelUnitTest.map((e) => _isReturnDataModel(e['returnData']!) ? '''import 'package:$featureName/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${e['apiName']?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : '').join('\n')}
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

Future<void> main() async {
  ${resultModelUnitTest.map((e) {
      if (!_isReturnDataModel(e['returnData']!)) return '';

      final className = e['apiName']?.pascalCase;
      final isResponseList = e['isResponseList'] == 'true';

      return '''test('mapper response model to entity $className', () {
    ${_getConstOrFinalValue(e['response'] ?? '')} response${e['apiName']?.pascalCase} = ${e['response']}
    ${_getConstOrFinalValue(e['entity'] ?? '')} entity${e['apiName']?.pascalCase} = ${e['entity']}

    ${isResponseList ? 'expect(response$className.map((e) => e.toEntity()).toList(), entity$className);' : 'expect(response$className.toEntity(), entity$className);'}
  });

  test('mapper entity to response model $className', () {
    ${_getConstOrFinalValue(e['response'] ?? '')} response${e['apiName']?.pascalCase} = ${e['response']}
    ${_getConstOrFinalValue(e['entity'] ?? '')} entity${e['apiName']?.pascalCase} = ${e['entity']}

    ${isResponseList ? 'expect(entity$className.map((e) => e.toResponse()).toList(), response$className);' : 'expect(entity$className.toResponse(), response$className);'}
  });
''';
    }).join('\n')}
}''';
  }

  T _whenMethodHttp<T>(
    String method, {
    required T Function() onStream,
    required T Function() onFuture,
  }) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return onStream();
      // case 'download':
      //   return onDownload();
      default:
        return onFuture();
    }
  }
}
