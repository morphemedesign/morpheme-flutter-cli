import 'package:morpheme_cli/helper/helper.dart';

import '../models/json2dart_config.dart';
import '../services/unit_test_generation_service.dart';

/// Processes unit tests within the Json2Dart generation workflow
///
/// This processor handles unit test generation for pages, including
/// data source tests, repository tests, use case tests, bloc tests, and mapper tests.
class UnitTestProcessor {
  final UnitTestGenerationService _testService;
  final bool _verbose;

  UnitTestProcessor({
    required UnitTestGenerationService testService,
    bool verbose = false,
  })  : _testService = testService,
        _verbose = verbose;

  /// Generates unit tests for a page
  ///
  /// [testPagePath] - Path to the test directory for the page
  /// [featureName] - Name of the feature
  /// [pageName] - Name of the page
  /// [testData] - Test data for all APIs
  /// Returns true if successful, false otherwise
  Future<bool> generateUnitTests({
    required String testPagePath,
    required String featureName,
    required String pageName,
    required List<Map<String, String>> testData,
    required Json2DartConfig globalConfig,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Generating unit tests for page: $pageName');
      }

      // Generate all page tests using the service
      _testService.generatePageTests(
        testPath: testPagePath,
        featureName: featureName,
        pageName: pageName,
        testData: testData,
      );

      if (_verbose) {
        StatusHelper.success(
            'Successfully generated unit tests for page: $pageName');
      }

      return true;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error generating unit tests for page $pageName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Generates test data for a single API
  ///
  /// [testPagePath] - Path to the test directory for the page
  /// [featureName] - Name of the feature
  /// [pageName] - Name of the page
  /// [apiName] - Name of the API
  /// [jsonBody] - Raw JSON body string
  /// [jsonResponse] - Raw JSON response string
  /// [bodyData] - Parsed body data
  /// [responseData] - Parsed response data
  /// [method] - HTTP method
  /// [paramPath] - URL parameters
  /// [pathHeader] - Path to header file
  /// [cacheStrategy] - Cache strategy
  /// [ttl] - Cache TTL
  /// [keepExpiredCache] - Whether to keep expired cache
  /// [returnData] - Return data type
  /// [projectName] - Project name
  /// Returns test data map
  Map<String, String> generateApiTestData({
    required String testPagePath,
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
    required String projectName,
  }) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating test data for API: $apiName');
      }

      // Generate API test data using the service
      final testData = _testService.generateApiTestData(
        testPath: testPagePath,
        featureName: featureName,
        pageName: pageName,
        apiName: apiName,
        jsonBody: jsonBody,
        jsonResponse: jsonResponse,
        bodyData: bodyData,
        responseData: responseData,
        method: method,
        paramPath: paramPath,
        pathHeader: pathHeader,
        cacheStrategy: cacheStrategy,
        ttl: ttl,
        keepExpiredCache: keepExpiredCache,
        returnData: returnData,
      );

      if (_verbose) {
        StatusHelper.success(
            'Successfully generated test data for API: $apiName');
      }

      return testData;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error generating test data for API $apiName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return {};
    }
  }
}
