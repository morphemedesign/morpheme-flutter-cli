import 'package:args/args.dart';
import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import '../models/api_generation_config.dart';

/// Validates and processes API generation command arguments.
///
/// Ensures all required arguments are present and valid before proceeding
/// with code generation. Provides clear error messages for missing or
/// invalid inputs.
class ApiArgumentsValidator {
  /// Validates command arguments and returns parsed configuration.
  ///
  /// Throws [ValidationException] if any required argument is missing
  /// or invalid.
  ///
  /// Parameters:
  /// - [argResults]: Command line argument results
  /// - [projectName]: Project name from morpheme.yaml
  ///
  /// Returns [ApiGenerationConfig] with validated parameters
  ApiGenerationConfig validate(ArgResults? argResults, String projectName) {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Api name is empty, add a new api with "morpheme api <api-name> -f <feature-name> -p <page-name>"');
    }

    // Extract and validate basic arguments
    final apiName = (argResults?.rest.first ?? '').snakeCase;
    final featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    final pageName = (argResults?['page-name'] as String? ?? '').snakeCase;

    if (apiName.isEmpty) {
      StatusHelper.failed('API name cannot be empty');
    }

    if (featureName.isEmpty) {
      StatusHelper.failed('Feature name is required');
    }

    if (pageName.isEmpty) {
      StatusHelper.failed('Page name is required');
    }

    // Validate feature and page paths exist
    final appsName = argResults?['apps-name'] as String?;
    final pathFeature = _getFeaturePath(featureName, appsName);
    final pathPage = _getPagePath(pathFeature, pageName);

    _validateFeatureExists(pathFeature, featureName);
    _validatePageExists(pathPage, pageName, featureName);

    // Extract optional arguments with validation
    final method = _validateMethod(argResults?['method'] as String?);
    final returnData =
        _validateReturnData(argResults?['return-data'] as String?);

    // Only set cache strategy for methods that support it
    CacheStrategy? cacheStrategy;
    int? ttl;
    bool? keepExpiredCache;

    if (_isApplyCacheStrategy(method)) {
      cacheStrategy =
          _validateCacheStrategy(argResults?['cache-strategy'] as String?);
      ttl = _validateTtl(argResults?['ttl'] as String?);
      keepExpiredCache = _validateKeepExpiredCache(
          argResults?['keep-expired-cache'] as String?);
    }

    // Handle multipart body list restriction
    final bodyList = (argResults?['body-list'] ?? false) &&
        !method.toLowerCase().contains('multipart');

    return ApiGenerationConfig(
      apiName: apiName,
      featureName: featureName,
      pageName: pageName,
      method: method,
      pathPage: pathPage,
      projectName: projectName,
      returnData: returnData,
      appsName: appsName,
      pathUrl: argResults?['path'] as String?,
      headerPath: argResults?['header'] as String?,
      json2dart: argResults?['json2dart'] ?? false,
      bodyList: bodyList,
      responseList: argResults?['response-list'] ?? false,
      cacheStrategy: cacheStrategy,
      ttl: ttl,
      keepExpiredCache: keepExpiredCache,
    );
  }

  /// Gets the feature path based on whether apps name is provided
  String _getFeaturePath(String featureName, String? appsName) {
    if (appsName != null) {
      return join(current, 'apps', appsName, 'features', featureName);
    }
    return join(current, 'features', featureName);
  }

  /// Gets the page path within the feature
  String _getPagePath(String pathFeature, String pageName) {
    return join(pathFeature, 'lib', pageName);
  }

  /// Validates that the feature directory exists
  void _validateFeatureExists(String pathFeature, String featureName) {
    if (!exists(pathFeature)) {
      StatusHelper.failed(
          'Feature with "$featureName" does not exists, create a new feature with "morpheme feature <feature-name>"');
    }
  }

  /// Validates that the page directory exists
  void _validatePageExists(
      String pathPage, String pageName, String featureName) {
    if (!exists(pathPage)) {
      StatusHelper.failed(
          'Page with "$pageName" does not exists, create a new page with "morpheme page <page-name> -f <feature-name>"');
    }
  }

  /// Validates HTTP method parameter
  String _validateMethod(String? method) {
    const allowedMethods = [
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'multipart',
      'postMultipart',
      'patchMultipart',
      'head',
      'getSse',
      'postSse',
      'putSse',
      'patchSse',
      'deleteSse',
      'download',
    ];

    final validatedMethod = method ?? 'post';

    if (!allowedMethods.contains(validatedMethod)) {
      StatusHelper.failed(
          'Invalid method "$validatedMethod". Allowed methods: ${allowedMethods.join(', ')}');
    }

    return validatedMethod;
  }

  /// Validates return data parameter
  String _validateReturnData(String? returnData) {
    const allowedReturnData = [
      'model',
      'header',
      'body_bytes',
      'body_string',
      'status_code',
      'raw'
    ];

    final validatedReturnData = returnData ?? 'model';

    if (!allowedReturnData.contains(validatedReturnData)) {
      StatusHelper.failed(
          'Invalid return-data "$validatedReturnData". Allowed values: ${allowedReturnData.join(', ')}');
    }

    return validatedReturnData;
  }

  /// Validates cache strategy parameter
  CacheStrategy? _validateCacheStrategy(String? cacheStrategy) {
    if (cacheStrategy == null) return null;

    try {
      return CacheStrategy.fromString(cacheStrategy);
    } catch (e) {
      StatusHelper.failed(
          'Invalid cache-strategy "$cacheStrategy". Allowed values: async_or_cache, cache_or_async, just_async, just_cache');
    }
    return null;
  }

  /// Validates TTL parameter
  int? _validateTtl(String? ttl) {
    if (ttl == null) return null;

    final parsedTtl = int.tryParse(ttl);
    if (parsedTtl == null) {
      StatusHelper.failed(
          'Invalid TTL value "$ttl". Must be a valid integer representing minutes.');
    }

    if (parsedTtl! < 0) {
      StatusHelper.failed('TTL value must be non-negative.');
    }

    return parsedTtl;
  }

  /// Validates keep expired cache parameter
  bool? _validateKeepExpiredCache(String? keepExpiredCache) {
    if (keepExpiredCache == null) return null;

    if (keepExpiredCache != 'true' && keepExpiredCache != 'false') {
      StatusHelper.failed(
          'Invalid keep-expired-cache value "$keepExpiredCache". Must be "true" or "false".');
    }

    return keepExpiredCache == 'true';
  }

  /// Checks if the method supports cache strategies
  bool _isApplyCacheStrategy(String method) {
    return !_isMultipart(method) && !_isSse(method);
  }

  /// Checks if the method is a multipart method
  bool _isMultipart(String method) {
    return method.toLowerCase().contains('multipart');
  }

  /// Checks if the method is a Server-Sent Events method
  bool _isSse(String method) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return true;
      default:
        return false;
    }
  }
}
