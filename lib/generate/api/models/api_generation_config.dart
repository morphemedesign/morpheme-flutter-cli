import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/helper/recase.dart';

/// Configuration class containing all parameters for API generation.
///
/// Encapsulates command line arguments, project settings, and generation
/// options in a type-safe, immutable data structure.
class ApiGenerationConfig {
  const ApiGenerationConfig({
    required this.apiName,
    required this.featureName,
    required this.pageName,
    required this.method,
    required this.pathPage,
    required this.projectName,
    required this.returnData,
    this.appsName,
    this.pathUrl,
    this.headerPath,
    this.json2dart = false,
    this.bodyList = false,
    this.responseList = false,
    this.cacheStrategy,
    this.ttl,
    this.keepExpiredCache,
  });

  // Core identification
  final String apiName;
  final String featureName;
  final String pageName;
  final String pathPage;
  final String projectName;

  // API configuration
  final String method;
  final String returnData;
  final String? pathUrl;
  final String? headerPath;
  final String? appsName;

  // Generation options
  final bool json2dart;
  final bool bodyList;
  final bool responseList;

  // Caching configuration
  final CacheStrategy? cacheStrategy;
  final int? ttl;
  final bool? keepExpiredCache;

  // Computed properties
  String get apiClassName => apiName.pascalCase;
  String get apiMethodName => apiName.camelCase;
  String get pageClassName => pageName.pascalCase;
  bool get isReturnDataModel => returnData == 'model';

  /// Creates a copy of this configuration with the given fields replaced
  /// with the new values.
  ApiGenerationConfig copyWith({
    String? apiName,
    String? featureName,
    String? pageName,
    String? method,
    String? pathPage,
    String? projectName,
    String? returnData,
    String? appsName,
    String? pathUrl,
    String? headerPath,
    bool? json2dart,
    bool? bodyList,
    bool? responseList,
    CacheStrategy? cacheStrategy,
    int? ttl,
    bool? keepExpiredCache,
  }) {
    return ApiGenerationConfig(
      apiName: apiName ?? this.apiName,
      featureName: featureName ?? this.featureName,
      pageName: pageName ?? this.pageName,
      method: method ?? this.method,
      pathPage: pathPage ?? this.pathPage,
      projectName: projectName ?? this.projectName,
      returnData: returnData ?? this.returnData,
      appsName: appsName ?? this.appsName,
      pathUrl: pathUrl ?? this.pathUrl,
      headerPath: headerPath ?? this.headerPath,
      json2dart: json2dart ?? this.json2dart,
      bodyList: bodyList ?? this.bodyList,
      responseList: responseList ?? this.responseList,
      cacheStrategy: cacheStrategy ?? this.cacheStrategy,
      ttl: ttl ?? this.ttl,
      keepExpiredCache: keepExpiredCache ?? this.keepExpiredCache,
    );
  }

  @override
  String toString() {
    return 'ApiGenerationConfig('
        'apiName: $apiName, '
        'featureName: $featureName, '
        'pageName: $pageName, '
        'method: $method, '
        'returnData: $returnData'
        ')';
  }
}
