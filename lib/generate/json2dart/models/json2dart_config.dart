/// Configuration model for Json2Dart generation process
///
/// This class encapsulates all configuration options for the Json2Dart command,
/// providing a centralized way to manage settings and validation.
class Json2DartConfig {
  /// Whether to generate API implementation files
  final bool isApi;

  /// Whether to generate endpoint configurations
  final bool isEndpoint;

  /// Whether to generate unit tests
  final bool isUnitTest;

  /// Whether to generate only unit tests (skip other files)
  final bool isOnlyUnitTest;

  /// Whether to replace existing files
  final bool isReplace;

  /// Whether to format generated files
  final bool isFormat;

  /// Whether to generate with Cubit state management
  final bool isCubit;

  /// Specific feature name to generate (optional)
  final String? featureName;

  /// Specific page name to generate (optional)
  final String? pageName;

  /// Specific apps name to generate (optional)
  final String? appsName;

  /// Date format for request body serialization
  final String bodyDateFormat;

  /// Date format for response deserialization
  final String responseDateFormat;

  const Json2DartConfig({
    this.isApi = true,
    this.isEndpoint = true,
    this.isUnitTest = false,
    this.isOnlyUnitTest = false,
    this.isReplace = false,
    this.isFormat = true,
    this.isCubit = true,
    this.featureName,
    this.pageName,
    this.appsName,
    this.bodyDateFormat = '.toIso8601String()',
    this.responseDateFormat = '.toIso8601String()',
  });

  /// Creates a copy of this config with updated values
  Json2DartConfig copyWith({
    bool? isApi,
    bool? isEndpoint,
    bool? isUnitTest,
    bool? isOnlyUnitTest,
    bool? isReplace,
    bool? isFormat,
    bool? isCubit,
    String? featureName,
    String? pageName,
    String? appsName,
    String? bodyDateFormat,
    String? responseDateFormat,
  }) {
    return Json2DartConfig(
      isApi: isApi ?? this.isApi,
      isEndpoint: isEndpoint ?? this.isEndpoint,
      isUnitTest: isUnitTest ?? this.isUnitTest,
      isOnlyUnitTest: isOnlyUnitTest ?? this.isOnlyUnitTest,
      isReplace: isReplace ?? this.isReplace,
      isFormat: isFormat ?? this.isFormat,
      isCubit: isCubit ?? this.isCubit,
      featureName: featureName ?? this.featureName,
      pageName: pageName ?? this.pageName,
      appsName: appsName ?? this.appsName,
      bodyDateFormat: bodyDateFormat ?? this.bodyDateFormat,
      responseDateFormat: responseDateFormat ?? this.responseDateFormat,
    );
  }

  /// Validates the configuration and returns any errors
  List<String> validate() {
    final errors = <String>[];

    if (pageName != null && featureName == null) {
      errors.add(
          'Page name specified but feature name is missing. Both are required.');
    }

    return errors;
  }

  @override
  String toString() {
    return 'Json2DartConfig('
        'isApi: $isApi, '
        'isEndpoint: $isEndpoint, '
        'isUnitTest: $isUnitTest, '
        'isOnlyUnitTest: $isOnlyUnitTest, '
        'isReplace: $isReplace, '
        'isFormat: $isFormat, '
        'isCubit: $isCubit, '
        'featureName: $featureName, '
        'pageName: $pageName, '
        'appsName: $appsName'
        ')';
  }
}
