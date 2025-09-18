import 'dart:async';

import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../models/json2dart_config.dart';
import '../services/file_operation_service.dart';
import '../services/unit_test_generation_service.dart';
import 'api_processor.dart';
import 'unit_test_processor.dart';

/// Processes pages within features for Json2Dart generation
///
/// This processor handles individual page processing, including
/// API generation, model creation, and test generation for each page.
class PageProcessor {
  final ApiProcessor _apiProcessor;
  final FileOperationService _fileService;
  final UnitTestProcessor _unitTestProcessor;
  final bool _verbose;
  final Map<String, dynamic> _jsonCache = {}; // Cache for loaded JSON data

  PageProcessor({
    required ApiProcessor apiProcessor,
    required FileOperationService fileService,
    required UnitTestGenerationService testService,
    bool verbose = false,
  })  : _apiProcessor = apiProcessor,
        _fileService = fileService,
        _unitTestProcessor = UnitTestProcessor(
          testService: testService,
          verbose: verbose,
        ),
        _verbose = verbose;

  /// Processes a single page within a feature
  ///
  /// [featurePath] - Path to the feature directory
  /// [featureName] - Name of the feature
  /// [pageName] - Name of the page
  /// [pageConfig] - Configuration for the page
  /// [globalConfig] - Global configuration settings
  /// [projectName] - Name of the project
  /// Returns true if successful, false otherwise
  Future<bool> processPage({
    required String featurePath,
    required String featureName,
    required String pageName,
    required dynamic pageConfig,
    required Json2DartConfig globalConfig,
    required String projectName,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success(
            'Processing page: $pageName in feature: $featureName');
      }

      // Validate page configuration
      if (pageConfig is! Map) {
        StatusHelper.warning('Invalid page configuration for: $pageName');
        return false;
      }

      // Convert pageConfig to Map<String, dynamic> to ensure type safety
      final pageMap = _convertMapToStringDynamic(pageConfig);
      final pagePath = join(featurePath, 'lib', pageName);
      final testPagePath = join(featurePath, 'test', '${pageName}_test');

      // Validate page directory exists
      if (!exists(pagePath)) {
        StatusHelper.warning('Page directory not found: $pagePath');
        return false;
      }

      // Cleanup existing files if needed
      await _cleanupExistingFiles(
        pagePath,
        testPagePath,
        pageName,
        pageMap,
        globalConfig,
        featureName,
      );

      // Create mapper file
      if (!globalConfig.isOnlyUnitTest) {
        _createMapperFile(pagePath, pageMap);
      }

      // Process APIs
      final testResults = <Map<String, String>>[];
      bool allApisSuccessful = true;

      // Clear JSON cache for this page
      _jsonCache.clear();

      if (globalConfig.isApi || !globalConfig.isOnlyUnitTest) {
        // Process APIs in parallel for better performance
        final apiFutures = <Future<bool>>[];
        final testDataFutures = <Future<Map<String, String>?>>[];

        for (final entry in pageMap.entries) {
          final apiName = entry.key;
          final apiConfig = entry.value;

          if (apiConfig is! Map) {
            StatusHelper.warning('Invalid API configuration for: $apiName');
            allApisSuccessful = false;
            continue;
          }

          // Convert API config to ensure type safety
          final convertedApiConfig = _convertMapToStringDynamic(apiConfig);
          final apiFuture = _processApiAsync(
            featurePath: featurePath,
            featureName: featureName,
            pageName: pageName,
            pagePath: pagePath,
            testPagePath: testPagePath,
            apiName: apiName,
            apiConfig: convertedApiConfig,
            globalConfig: globalConfig,
            projectName: projectName,
          );

          apiFutures.add(apiFuture);

          // Prepare test data if needed
          if (globalConfig.isOnlyUnitTest || globalConfig.isUnitTest) {
            final testFuture = _prepareTestDataAsync(
              testPagePath: testPagePath,
              featureName: featureName,
              pageName: pageName,
              pagePath: pagePath,
              apiName: apiName,
              apiConfig: convertedApiConfig,
              globalConfig: globalConfig,
            );
            testDataFutures.add(testFuture);
          }
        }

        // Wait for all API processing to complete
        final apiResults = await Future.wait(apiFutures);
        for (final result in apiResults) {
          if (!result) {
            allApisSuccessful = false;
          }
        }

        // Process test data if needed
        if (globalConfig.isOnlyUnitTest || globalConfig.isUnitTest) {
          final testDataResults = await Future.wait(testDataFutures);
          for (final result in testDataResults) {
            if (result != null) {
              testResults.add(result);
            }
          }
        }
      } else if (globalConfig.isOnlyUnitTest || globalConfig.isUnitTest) {
        // Only process test data
        for (final entry in pageMap.entries) {
          final apiName = entry.key;
          final apiConfig = entry.value;

          if (apiConfig is! Map) {
            continue;
          }

          // Convert API config to ensure type safety
          final convertedApiConfig = _convertMapToStringDynamic(apiConfig);
          final testResult = await _prepareTestData(
            testPagePath: testPagePath,
            featureName: featureName,
            pageName: pageName,
            pagePath: pagePath,
            apiName: apiName,
            apiConfig: convertedApiConfig,
            bodyData: await _loadJsonDataCached(apiConfig['body'] as String?),
            responseData:
                await _loadJsonDataCached(apiConfig['response'] as String?),
            paramPath: [..._extractParamPath(apiConfig['path'] as String?)],
            cacheStrategy: _extractCacheStrategy(apiConfig['cache_strategy']),
            returnData: apiConfig['return_data'] as String? ?? 'model',
            projectName: projectName,
          );

          if (testResult != null) {
            testResults.add(testResult);
          }
        }
      }

      // Generate unit tests if requested
      if (globalConfig.isOnlyUnitTest || globalConfig.isUnitTest) {
        final testSuccess = await _unitTestProcessor.generateUnitTests(
          testPagePath: testPagePath,
          featureName: featureName,
          pageName: pageName,
          testData: testResults,
          globalConfig: globalConfig,
        );

        if (!testSuccess) {
          StatusHelper.warning(
              'Failed to generate unit tests for page: $pageName');
        }
      }

      // Clear JSON cache after processing
      _jsonCache.clear();

      if (_verbose && allApisSuccessful) {
        StatusHelper.success('Successfully processed page: $pageName');
      }

      return allApisSuccessful;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error processing page $pageName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Processes a single API asynchronously
  Future<bool> _processApiAsync({
    required String featurePath,
    required String featureName,
    required String pageName,
    required String pagePath,
    required String testPagePath,
    required String apiName,
    required Map<String, dynamic> apiConfig,
    required Json2DartConfig globalConfig,
    required String projectName,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Processing API: $apiName');
      }

      // Extract API configuration
      final pathUrl = apiConfig['path'] as String?;
      final paramPath = _extractParamPath(pathUrl);

      // Load JSON data with caching
      final bodyData = await _loadJsonDataCached(apiConfig['body'] as String?);
      final responseData =
          await _loadJsonDataCached(apiConfig['response'] as String?);

      // Extract API settings
      final method = apiConfig['method'] as String?;
      final returnData = apiConfig['return_data'] as String? ?? 'model';
      final cacheStrategy = _extractCacheStrategy(apiConfig['cache_strategy']);

      // Process API generation
      if (!globalConfig.isOnlyUnitTest) {
        final apiSuccess = await _apiProcessor.processApi(
          featurePath: featurePath,
          featureName: featureName,
          pageName: pageName,
          pagePath: pagePath,
          apiName: apiName,
          bodyData: bodyData,
          responseData: responseData,
          method: method ?? 'get',
          pathUrl: pathUrl ?? '',
          paramPath: paramPath,
          header: apiConfig['header'] as String?,
          cacheStrategy: cacheStrategy,
          globalConfig: globalConfig,
          returnData: returnData,
          dirExtra: apiConfig['dir_extra'] as String?,
        );

        if (!apiSuccess) {
          StatusHelper.failed('Failed to process API: $apiName');
          return false;
        }
      }

      return true;
    } catch (e) {
      StatusHelper.failed('Error processing API $apiName: $e');
      return false;
    }
  }

  /// Prepares test data asynchronously
  Future<Map<String, String>?> _prepareTestDataAsync({
    required String testPagePath,
    required String featureName,
    required String pageName,
    required String pagePath,
    required String apiName,
    required Map<String, dynamic> apiConfig,
    required Json2DartConfig globalConfig,
  }) async {
    try {
      // Load JSON data with caching
      final bodyData = await _loadJsonDataCached(apiConfig['body'] as String?);
      final responseData =
          await _loadJsonDataCached(apiConfig['response'] as String?);

      // Extract param path
      final paramPath = _extractParamPath(apiConfig['path'] as String?);

      // Extract API settings
      final cacheStrategy = _extractCacheStrategy(apiConfig['cache_strategy']);
      final returnData = apiConfig['return_data'] as String? ?? 'model';

      return await _prepareTestData(
        testPagePath: testPagePath,
        featureName: featureName,
        pageName: pageName,
        pagePath: pagePath,
        apiName: apiName,
        apiConfig: apiConfig,
        bodyData: bodyData,
        responseData: responseData,
        paramPath: paramPath,
        cacheStrategy: cacheStrategy,
        returnData: returnData,
        projectName:
            featureName, // Using featureName as projectName for simplicity
      );
    } catch (e) {
      StatusHelper.warning('Failed to prepare test data for API $apiName: $e');
      return null;
    }
  }

  /// Extracts parameter path from URL
  List<String> _extractParamPath(String? pathUrl) {
    final paramPath = <String>[];
    if (pathUrl != null) {
      parse(pathUrl, parameters: paramPath);
    }
    return paramPath;
  }

  /// Loads JSON data from file with caching
  Future<dynamic> _loadJsonDataCached(String? filePath) async {
    if (filePath == null) return {};

    // Check cache first
    if (_jsonCache.containsKey(filePath)) {
      return _jsonCache[filePath] ?? {};
    }

    // Load from file if not in cache
    final data = await _loadJsonData(filePath);
    _jsonCache[filePath] = data;
    return data ?? {};
  }

  /// Loads JSON data from file
  Future<dynamic> _loadJsonData(String? filePath) async {
    if (filePath == null) return {};

    try {
      return _fileService.readJsonFile(
        filePath,
        onJsonIsList: () {
          if (_verbose) {
            StatusHelper.success('JSON file contains a list: $filePath');
          }
        },
        warningMessage: 'Invalid JSON format in file: $filePath',
      );
    } catch (e) {
      StatusHelper.warning('Failed to load JSON from: $filePath - $e');
      return {};
    }
  }

  /// Extracts cache strategy configuration
  Map<String, dynamic>? _extractCacheStrategy(dynamic cacheStrategy) {
    if (cacheStrategy == null) return null;

    if (cacheStrategy is String) {
      return {'strategy': cacheStrategy};
    }

    if (cacheStrategy is Map) {
      return Map<String, dynamic>.from(cacheStrategy);
    }

    return null;
  }

  /// Cleans up existing files based on configuration
  Future<void> _cleanupExistingFiles(
    String pagePath,
    String testPagePath,
    String pageName,
    Map<String, dynamic> pageConfig,
    Json2DartConfig globalConfig,
    String featureName,
  ) async {
    try {
      if (!globalConfig.isOnlyUnitTest && globalConfig.isApi) {
        _fileService.removeAllRelatedApiFiles(
          pagePath,
          pageName,
          pageConfig,
          globalConfig.isReplace,
        );
      }

      if (globalConfig.isOnlyUnitTest || globalConfig.isUnitTest) {
        _fileService.removeAllRelatedUnitTestFiles(featureName, pageName);
      }
    } catch (e) {
      StatusHelper.warning('Failed to cleanup existing files: $e');
    }
  }

  /// Creates mapper file for the page
  void _createMapperFile(String pagePath, Map<String, dynamic> pageConfig) {
    try {
      final imports = pageConfig.keys
          .map((apiName) {
            final apiConfig = pageConfig[apiName];
            final returnData = apiConfig is Map
                ? apiConfig['return_data'] ?? 'model'
                : 'model';

            if (returnData == 'model') {
              return """import 'data/models/response/${apiName.toString().snakeCase}_response.dart' as ${apiName.toString().snakeCase}_response;
import 'domain/entities/${apiName.toString().snakeCase}_entity.dart' as ${apiName.toString().snakeCase}_entity;""";
            }
            return '';
          })
          .where((import) => import.isNotEmpty)
          .join('\n');

      _fileService.writeGeneratedFile(pagePath, 'mapper.dart', imports);
    } catch (e) {
      StatusHelper.warning('Failed to create mapper file: $e');
    }
  }

  /// Prepares test data for unit test generation
  Future<Map<String, String>?> _prepareTestData({
    required String testPagePath,
    required String featureName,
    required String pageName,
    required String pagePath,
    required String apiName,
    required Map<String, dynamic> apiConfig,
    required dynamic bodyData,
    required dynamic responseData,
    required List<String> paramPath,
    required Map<String, dynamic>? cacheStrategy,
    required String returnData,
    required String projectName,
  }) async {
    try {
      // Load raw JSON strings for test generation
      final bodyPath = apiConfig['body'] as String?;
      final responsePath = apiConfig['response'] as String?;

      final jsonBody = bodyPath != null && _fileService.fileExists(bodyPath)
          ? read(bodyPath).join('\n')
          : '{}';

      final jsonResponse =
          responsePath != null && _fileService.fileExists(responsePath)
              ? read(responsePath).join('\n')
              : '{}';

      // Extract API settings
      final method = apiConfig['method'] as String?;
      final cacheStrategyValue = cacheStrategy?['strategy'] as String?;
      final ttl = cacheStrategy?['ttl'] as int?;
      final keepExpiredCache = cacheStrategy?['keep_expired_cache'] as bool?;
      final pathHeader = apiConfig['header'] as String?;

      // Generate test data using the unit test processor
      final testData = _unitTestProcessor.generateApiTestData(
        testPagePath: testPagePath,
        featureName: featureName,
        pageName: pageName,
        apiName: apiName,
        jsonBody: jsonBody,
        jsonResponse: jsonResponse,
        bodyData: bodyData,
        responseData: responseData,
        method: method ?? 'get',
        paramPath: paramPath,
        pathHeader: pathHeader,
        cacheStrategy: cacheStrategyValue,
        ttl: ttl,
        keepExpiredCache: keepExpiredCache,
        returnData: returnData,
        projectName: projectName,
      );

      return testData;
    } catch (e) {
      StatusHelper.warning('Failed to prepare test data for API $apiName: $e');
      return null;
    }
  }

  /// Converts a Map&ltdynamic, dynamic&gt; to Map&ltString, dynamic&gt;
  ///
  /// This method ensures type safety when working with YAML parsed data
  /// which often comes as Map&lt;dynamic, dynamic&gt; but our APIs expect
  /// Map&lt;String, dynamic&gt;.
  Map<String, dynamic> _convertMapToStringDynamic(Map<dynamic, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }
}
