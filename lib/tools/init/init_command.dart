import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to initialize a new Morpheme project with default configuration.
///
/// This command creates a `morpheme.yaml` configuration file with sensible
/// defaults for flavors, Firebase integration, localization, assets, and
/// code coverage settings. It validates the Flutter project structure
/// before initialization.
class InitCommand extends Command {
  InitCommand() {
    argParser.addOption(
      'app-name',
      help: 'The application name used in configuration',
      defaultsTo: 'morpheme',
      valueHelp: 'name',
    );
    argParser.addOption(
      'application-id',
      help: 'The base application identifier (reverse domain notation)',
      defaultsTo: 'design.morpheme',
      valueHelp: 'com.example.app',
    );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize a new project with Morpheme configuration';

  @override
  String get category => Constants.tools;

  /// Default base URL for API endpoints
  static const String _defaultBaseUrl = 'https://reqres.in/api';

  /// Configuration file name
  static const String _configFileName = 'morpheme.yaml';

  /// Required project file to validate Flutter project
  static const String _pubspecFileName = 'pubspec.yaml';

  @override
  void run() {
    final String appName =
        _validateAppName(argResults?['app-name'] ?? 'morpheme');
    final String applicationId = _validateApplicationId(
      argResults?['application-id'] ?? 'design.morpheme',
    );

    _validateFlutterProject();
    _checkExistingConfiguration();
    _createConfiguration(appName, applicationId);

    StatusHelper.success('Morpheme project initialized successfully!');
    _printNextSteps();
  }

  /// Validates that the app name is not empty and contains valid characters.
  String _validateAppName(String appName) {
    if (appName.trim().isEmpty) {
      StatusHelper.failed('App name cannot be empty');
      throw ArgumentError('Invalid app name: $appName');
    }

    // Basic validation - could be enhanced based on requirements
    if (appName.length > 50) {
      StatusHelper.warning('App name is quite long: $appName');
    }

    return appName.trim();
  }

  /// Validates the application ID format (reverse domain notation).
  String _validateApplicationId(String applicationId) {
    if (applicationId.trim().isEmpty) {
      StatusHelper.failed('Application ID cannot be empty');
      throw ArgumentError('Invalid application ID: $applicationId');
    }

    final trimmedId = applicationId.trim();

    // Basic validation for reverse domain notation
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$')
        .hasMatch(trimmedId)) {
      StatusHelper.warning(
          'Application ID should follow reverse domain notation (e.g., com.example.app): $trimmedId');
    }

    return trimmedId;
  }

  /// Validates that this is a Flutter project by checking for pubspec.yaml.
  void _validateFlutterProject() {
    final pubspecPath = join(current, _pubspecFileName);

    if (!exists(pubspecPath)) {
      StatusHelper.failed(
          'No "$_pubspecFileName" found in the current directory.\n'
          'Please ensure you are in the root of a Flutter project.');
      throw StateError('Not a Flutter project directory');
    }

    printMessage(green('Flutter project detected ✓'));
  }

  /// Checks if a Morpheme configuration already exists and warns the user.
  void _checkExistingConfiguration() {
    final configPath = join(current, _configFileName);

    if (exists(configPath)) {
      StatusHelper.warning(
          'Configuration file "$_configFileName" already exists in your project root.\n'
          'The existing file will be overwritten.');
    }
  }

  /// Creates the Morpheme configuration file with the specified parameters.
  void _createConfiguration(String appName, String applicationId) {
    final androidApplicationId = _formatAndroidApplicationId(applicationId);
    final iosApplicationId = _formatIosApplicationId(applicationId);

    final configContent = _generateConfigurationContent(
      appName: appName,
      androidApplicationId: androidApplicationId,
      iosApplicationId: iosApplicationId,
    );

    final configPath = join(current, _configFileName);

    try {
      configPath.write(configContent);
      StatusHelper.generated(configPath);
    } catch (e) {
      StatusHelper.failed('Failed to create configuration file: $e');
      rethrow;
    }
  }

  /// Formats the application ID for Android (snake_case segments).
  String _formatAndroidApplicationId(String applicationId) {
    return applicationId
        .split('.')
        .map((segment) => segment.snakeCase)
        .join('.');
  }

  /// Formats the application ID for iOS (camelCase segments).
  String _formatIosApplicationId(String applicationId) {
    return applicationId
        .split('.')
        .map((segment) => segment.camelCase)
        .join('.');
  }

  /// Generates the complete YAML configuration content.
  String _generateConfigurationContent({
    required String appName,
    required String androidApplicationId,
    required String iosApplicationId,
  }) {
    final titleCaseAppName = appName.titleCase;

    return '''# Morpheme CLI Configuration
# This file contains all the configuration needed for Morpheme CLI commands
# Learn more: https://github.com/morphemedesign/morpheme-flutter-cli

# Flavor configurations for different build environments
flavor:
  dev:
    FLAVOR: dev
    APP_NAME: $titleCaseAppName Dev
    ANDROID_APPLICATION_ID: $androidApplicationId.dev
    IOS_APPLICATION_ID: $iosApplicationId.dev
    BASE_URL: $_defaultBaseUrl
  stag:
    FLAVOR: stag
    APP_NAME: $titleCaseAppName Stag
    ANDROID_APPLICATION_ID: $androidApplicationId.stag
    IOS_APPLICATION_ID: $iosApplicationId.stag
    BASE_URL: $_defaultBaseUrl
  prod:
    FLAVOR: prod
    APP_NAME: $titleCaseAppName
    ANDROID_APPLICATION_ID: $androidApplicationId
    IOS_APPLICATION_ID: $iosApplicationId
    BASE_URL: $_defaultBaseUrl

# Firebase configuration (uncomment and configure when needed)
#firebase:
#  dev:
#    project_id: "${appName.toLowerCase()}-dev"
#    token: "YOUR FIREBASE TOKEN: firebase login:ci"
#  stag:
#    project_id: "${appName.toLowerCase()}-stag"
#    token: "YOUR FIREBASE TOKEN: firebase login:ci"
#  prod:
#    project_id: "${appName.toLowerCase()}"
#    token: "YOUR FIREBASE TOKEN: firebase login:ci"

# Color to Dart code generation configuration
color2dart:
  color2dart_dir: color2dart
  output_dir: core/lib/src/themes

# Localization configuration
localization:
  arb_dir: assets/assets/l10n
  template_arb_file: id.arb
  output_localization_file: s.dart
  output_class: S
  output_dir: core/lib/src/l10n
  replace: false

# Asset generation configuration
assets:
  pubspec_dir: assets
  output_dir: assets/lib
  create_library_file: true
  
# Code coverage configuration
coverage:
  lcov_dir: coverage/lcov.info
  output_html_dir: coverage/html
  remove:
    - "*/mock/*"
    - "*.freezed.*"
    - "*.g.*"
    - "*/l10n/*"
    - "*_state.dart"
    - "*_event.dart"
    - "**/locator.dart"
    - "**/environtment.dart"
    - "core/lib/src/test/*"
    - "core/lib/src/constants/*"
    - "core/lib/src/themes/*"
    - "lib/routes/routes.dart"
    - "lib/generated_plugin_registrant.dart"
''';
  }

  /// Prints helpful next steps for the user after initialization.
  void _printNextSteps() {
    printMessage('\n${blue('Next Steps:')}');
    printMessage('• Review and customize the generated $_configFileName file');
    printMessage('• Configure Firebase settings if needed');
    printMessage(
        '• Run ${cyan('morpheme doctor')} to check your development environment');
    printMessage(
        '• Use ${cyan('morpheme generate')} commands to scaffold your project');
    printMessage('\n${grey('For more information, visit:')}');
    printMessage(
        cyan('https://github.com/morphemedesign/morpheme-flutter-cli'));
  }
}
