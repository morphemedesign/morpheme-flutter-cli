import 'dart:async';

import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

import '../generators/body_model_generator.dart';
import '../generators/entity_generator.dart';
import '../generators/mapper_generator.dart';
import '../generators/response_model_generator.dart';
import '../models/json2dart_config.dart';
import '../services/file_operation_service.dart';
import '../services/api_generation_service.dart';

/// Processes individual APIs within the Json2Dart generation workflow
///
/// This processor handles API-specific code generation including
/// body models, response models, entities, and mappers.
class ApiProcessor {
  final BodyModelGenerator _bodyGenerator;
  final ResponseModelGenerator _responseGenerator;
  final EntityGenerator _entityGenerator;
  final MapperGenerator _mapperGenerator;
  final FileOperationService _fileService;
  final ApiGenerationService _apiGenerationService; // Add the new service
  final bool _verbose;
  final Set<String> _extraDirectories; // Reference to track extra directories

  // Remove the queue for sequential execution since we're not using terminal commands anymore
  // static final _apiCommandQueue = _ApiCommandQueue();

  ApiProcessor({
    required BodyModelGenerator bodyGenerator,
    required ResponseModelGenerator responseGenerator,
    required EntityGenerator entityGenerator,
    required MapperGenerator mapperGenerator,
    required FileOperationService fileService,
    required Set<String> extraDirectories, // Inject the extra directories set
    bool verbose = false,
  })  : _bodyGenerator = bodyGenerator,
        _responseGenerator = responseGenerator,
        _entityGenerator = entityGenerator,
        _mapperGenerator = mapperGenerator,
        _fileService = fileService,
        _apiGenerationService =
            ApiGenerationService(), // Initialize the new service
        _extraDirectories = extraDirectories,
        _verbose = verbose;

  /// Processes a single API and generates all required code
  ///
  /// [featurePath] - Path to the feature directory
  /// [featureName] - Name of the feature
  /// [pageName] - Name of the page
  /// [pagePath] - Path to the page directory
  /// [apiName] - Name of the API
  /// [bodyData] - JSON body data
  /// [responseData] - JSON response data
  /// [method] - HTTP method
  /// [pathUrl] - API path URL
  /// [paramPath] - URL parameters
  /// [header] - Header configuration file path
  /// [cacheStrategy] - Cache strategy configuration
  /// [globalConfig] - Global configuration settings
  /// [returnData] - Return data type
  /// [dirExtra] - Extra directory for additional files
  /// Returns true if successful, false otherwise
  Future<bool> processApi({
    required String featurePath,
    required String featureName,
    required String pageName,
    required String pagePath,
    required String apiName,
    required dynamic bodyData,
    required dynamic responseData,
    required String method,
    required String pathUrl,
    required List<String> paramPath,
    required String? header,
    required Map<String, dynamic>? cacheStrategy,
    required Json2DartConfig globalConfig,
    required String returnData,
    required String? dirExtra,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Processing API: $apiName');
      }

      final isMultipart = method.toLowerCase().contains('multipart');
      final isReturnModel = _isReturnDataModel(returnData);

      // Generate body model if body data exists
      if (bodyData != null) {
        final bodySuccess = _generateBodyModel(
          pagePath,
          apiName,
          bodyData,
          isMultipart,
          paramPath,
        );

        if (!bodySuccess) {
          StatusHelper.failed(
              'Failed to generate body model for API: $apiName');
          return false;
        }
      }

      // Generate response model if response data exists and return type is model
      if (responseData != null && isReturnModel) {
        final responseSuccess = _generateResponseModel(
          pagePath,
          apiName,
          responseData,
        );

        if (!responseSuccess) {
          StatusHelper.failed(
              'Failed to generate response model for API: $apiName');
          return false;
        }

        // Generate domain entity
        final entitySuccess = _generateDomainEntity(
          pagePath,
          apiName,
          responseData,
        );

        if (!entitySuccess) {
          StatusHelper.failed(
              'Failed to generate domain entity for API: $apiName');
          return false;
        }

        // Generate mapper
        final mapperSuccess = _generateMapper(
          pagePath,
          apiName,
          responseData,
        );

        if (!mapperSuccess) {
          StatusHelper.failed('Failed to generate mapper for API: $apiName');
          return false;
        }

        // Generate extra model if directory specified
        if (dirExtra != null && dirExtra.isNotEmpty) {
          final extraSuccess = _generateExtraModel(
            featureName,
            dirExtra,
            apiName,
            responseData,
          );

          if (!extraSuccess) {
            StatusHelper.warning(
                'Failed to generate extra model for API: $apiName');
            // Don't fail the entire process for extra model failure
          }
        }
      }

      // Generate API implementation if enabled
      if (globalConfig.isApi) {
        final apiSuccess = await _generateApiImplementation(
          featureName: featureName,
          pageName: pageName,
          apiName: apiName,
          method: method,
          pathUrl: pathUrl,
          header: header,
          cacheStrategy: cacheStrategy,
          returnData: returnData,
          globalConfig: globalConfig,
        );

        if (!apiSuccess) {
          StatusHelper.failed(
              'Failed to generate API implementation for: $apiName');
          return false;
        }
      }

      if (_verbose) {
        StatusHelper.success('Successfully processed API: $apiName');
      }

      return true;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error processing API $apiName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Generates body model for API request
  bool _generateBodyModel(
    String pagePath,
    String apiName,
    dynamic bodyData,
    bool isMultipart,
    List<String> paramPath,
  ) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating body model for: $apiName');
      }

      // Avoid unnecessary Map conversion if already a Map
      final bodyMap = bodyData is Map<String, dynamic>
          ? bodyData
          : Map<String, dynamic>.from(bodyData);

      final bodyModel = _bodyGenerator.generateBodyModel(
        apiName.pascalCase,
        bodyMap,
        isMultipart,
        paramPath,
      );

      final bodyPath = join(pagePath, 'data', 'models', 'body');
      _fileService.writeGeneratedFile(
        bodyPath,
        '${apiName.snakeCase}_body.dart',
        bodyModel,
      );

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate body model for $apiName: $e');
      return false;
    }
  }

  /// Generates response model for API response
  bool _generateResponseModel(
    String pagePath,
    String apiName,
    dynamic responseData,
  ) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating response model for: $apiName');
      }

      // Avoid unnecessary Map conversion if already a Map
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData);

      final responseModel = _responseGenerator.generateResponseModel(
        apiName.pascalCase,
        responseMap,
      );

      final responsePath = join(pagePath, 'data', 'models', 'response');
      _fileService.writeGeneratedFile(
        responsePath,
        '${apiName.snakeCase}_response.dart',
        responseModel,
      );

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate response model for $apiName: $e');
      return false;
    }
  }

  /// Generates domain entity for API
  bool _generateDomainEntity(
    String pagePath,
    String apiName,
    dynamic responseData,
  ) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating domain entity for: $apiName');
      }

      // Avoid unnecessary Map conversion if already a Map
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData);

      final entity = _entityGenerator.generateEntity(
        apiName.pascalCase,
        responseMap,
      );

      final entityPath = join(pagePath, 'domain', 'entities');
      _fileService.writeGeneratedFile(
        entityPath,
        '${apiName.snakeCase}_entity.dart',
        entity,
      );

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate domain entity for $apiName: $e');
      return false;
    }
  }

  /// Generates mapper for converting between models and entities
  bool _generateMapper(
    String pagePath,
    String apiName,
    dynamic responseData,
  ) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating mapper for: $apiName');
      }

      // Avoid unnecessary Map conversion if already a Map
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData);

      final mapperExtensions = _mapperGenerator.generateMapperExtensions(
        apiName,
        responseMap,
      );

      _fileService.appendToFile(
        join(pagePath, 'mapper.dart'),
        mapperExtensions,
      );

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate mapper for $apiName: $e');
      return false;
    }
  }

  /// Generates extra model in specified directory
  bool _generateExtraModel(
    String featureName,
    String dirExtra,
    String apiName,
    dynamic responseData,
  ) {
    try {
      if (_verbose) {
        StatusHelper.success('Generating extra model for: $apiName');
      }

      // Avoid unnecessary Map conversion if already a Map
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData);

      final extraModel = _responseGenerator.generateExtraModel(
        apiName.pascalCase,
        responseMap,
      );

      // Track the extra directory for formatting
      _extraDirectories.add(dirExtra);

      _fileService.writeGeneratedFile(
        dirExtra,
        '${apiName.snakeCase}_extra.dart',
        extraModel,
      );

      return true;
    } catch (e) {
      StatusHelper.failed('Failed to generate extra model for $apiName: $e');
      return false;
    }
  }

  /// Generates API implementation using the dedicated API generation service
  Future<bool> _generateApiImplementation({
    required String featureName,
    required String pageName,
    required String apiName,
    required String method,
    required String pathUrl,
    required String? header,
    required Map<String, dynamic>? cacheStrategy,
    required String returnData,
    required Json2DartConfig globalConfig,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Generating API implementation for: $apiName');
      }

      // Extract cache strategy parameters
      String? strategy;
      int? ttl;
      bool? keepExpiredCache;

      if (cacheStrategy != null) {
        strategy = cacheStrategy['strategy'] as String?;
        ttl = cacheStrategy['ttl'] as int?;
        keepExpiredCache = cacheStrategy['keep_expired_cache'] as bool?;
      }

      // Generate API using the dedicated service
      final result = await _apiGenerationService.generateApi(
        apiName: apiName,
        featureName: featureName,
        pageName: pageName,
        method: method,
        pathUrl: pathUrl,
        returnData: returnData,
        header: header,
        cacheStrategy: strategy,
        ttl: ttl,
        keepExpiredCache: keepExpiredCache,
        appsName: globalConfig.appsName,
      );

      return result;
    } catch (e) {
      StatusHelper.failed(
          'Failed to generate API implementation for $apiName: $e');
      return false;
    }
  }

  /// Checks if return data should be a model
  bool _isReturnDataModel(String returnData) => returnData == 'model';
}
