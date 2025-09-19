/// Data model for Firebase configuration parameters.
///
/// This class encapsulates all Firebase configuration parameters
/// needed for the Firebase generation process.
class FirebaseConfig {
  /// Firebase project ID
  final String projectId;

  /// Optional authentication token
  final String? token;

  /// Target platforms for configuration
  final String? platform;

  /// Output path for firebase_options.dart
  final String? output;

  /// Android application package name
  final String androidPackageName;

  /// iOS bundle identifier
  final String iosBundleId;

  /// Web application ID
  final String? webAppId;

  /// Path to service account JSON file
  final String? serviceAccount;

  /// Flag to enable service account in CI/CD
  final bool enableCiUseServiceAccount;

  /// Flag to force overwrite existing configuration
  final bool overwrite;

  /// Creates a new FirebaseConfig instance.
  ///
  /// All required parameters must be provided. Optional parameters
  /// can be null or have default values.
  FirebaseConfig({
    required this.projectId,
    this.token,
    this.platform,
    this.output,
    required this.androidPackageName,
    required this.iosBundleId,
    this.webAppId,
    this.serviceAccount,
    this.enableCiUseServiceAccount = false,
    this.overwrite = false,
  });

  /// Creates a FirebaseConfig from a map of configuration values.
  ///
  /// This factory constructor is useful for creating configurations
  /// from YAML data or other map-based sources.
  ///
  /// Parameters:
  /// - [map]: Map containing configuration values
  /// - [flavor]: Map containing flavor-specific values for defaults
  factory FirebaseConfig.fromMap(
      Map<dynamic, dynamic> map, Map<dynamic, dynamic> flavor) {
    return FirebaseConfig(
      projectId: map['project_id'] as String,
      token: map['token'] as String?,
      platform: map['platform'] as String?,
      output: map['output'] as String?,
      androidPackageName: map['android_package_name'] as String? ??
          flavor['ANDROID_APPLICATION_ID'] as String? ??
          '',
      iosBundleId: map['ios_bundle_id'] as String? ??
          flavor['IOS_APPLICATION_ID'] as String? ??
          '',
      webAppId: map['web_app_id'] as String?,
      serviceAccount: map['service_account'] as String?,
      enableCiUseServiceAccount: map['enable_ci_use_service_account'] is bool
          ? map['enable_ci_use_service_account'] as bool
          : false,
      overwrite: false, // This will be set from command line flag
    );
  }

  @override
  String toString() {
    return 'FirebaseConfig(projectId: $projectId, token: $token, platform: $platform, output: $output, androidPackageName: $androidPackageName, iosBundleId: $iosBundleId, webAppId: $webAppId, serviceAccount: $serviceAccount, enableCiUseServiceAccount: $enableCiUseServiceAccount, overwrite: $overwrite)';
  }
}
