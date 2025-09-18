import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

abstract class FirebaseHelper {
  /// Runs the Morpheme Firebase command for a specific flavor.
  ///
  /// This method executes the Morpheme CLI Firebase command with the specified
  /// flavor and configuration file path. It's typically used to configure
  /// Firebase for different environments (dev, staging, prod).
  ///
  /// Parameters:
  /// - [flavor]: The flavor/environment to configure (e.g., 'dev', 'staging', 'prod')
  /// - [pathMorphemeYaml]: Path to the morpheme.yaml configuration file
  ///
  /// Returns: The exit code of the command execution
  ///
  /// Example:
  /// ```dart
  /// // Configure Firebase for development environment
  /// final exitCode = await FirebaseHelper.run('dev', './morpheme.yaml');
  /// if (exitCode == 0) {
  ///   print('Firebase configured successfully for dev environment');
  /// }
  /// ```
  static Future<int> run(String flavor, String pathMorphemeYaml) async {
    return 'morpheme firebase -f $flavor --morpheme-yaml "$pathMorphemeYaml"'
        .run;
  }

  /// Retrieves Firebase configuration for a specific flavor.
  ///
  /// This method extracts the Firebase configuration for a given flavor
  /// from the morpheme.yaml configuration file. The configuration typically
  /// includes project ID, platform settings, and other Firebase-specific options.
  ///
  /// Parameters:
  /// - [flavor]: The flavor/environment to get configuration for
  /// - [pathMorphemeYaml]: Path to the morpheme.yaml configuration file
  ///
  /// Returns: A map containing the Firebase configuration for the specified flavor
  ///
  /// Example:
  /// ```dart
  /// // Get Firebase configuration for production
  /// final config = FirebaseHelper.byFlavor('prod', './morpheme.yaml');
  /// final projectId = config['project_id'];
  /// print('Production Firebase project ID: $projectId');
  /// ```
  static Map<dynamic, dynamic> byFlavor(
      String flavor, String pathMorphemeYaml) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapFlavor = yaml['firebase'] ?? {};
    return mapFlavor[flavor] ?? {};
  }

  /// Determines if Firebase configuration regeneration is needed.
  ///
  /// Checks if the existing firebase_options.dart file contains
  /// the correct project ID. If not, regeneration is required.
  ///
  /// Parameters:
  /// - [projectId]: The Firebase project ID to check for
  /// - [output]: Optional output path for firebase_options.dart
  ///
  /// Returns: true if regeneration is needed, false otherwise
  ///
  /// Example:
  /// ```dart
  /// // Check if Firebase configuration needs regeneration
  /// final needsRegen = FirebaseHelper.shouldRegenerate('my-project-id');
  /// if (needsRegen) {
  ///   print('Firebase configuration needs to be regenerated');
  ///   // Run flutterfire configure command
  /// }
  /// ```
  static bool shouldRegenerate(String projectId, String? output) {
    final pathFirebaseOptions = output != null
        ? join(current, output)
        : join(current, 'lib', 'firebase_options.dart');
        
    if (exists(pathFirebaseOptions)) {
      final firebaseOptions = readFile(pathFirebaseOptions);
      if (RegExp('''projectId:(\\s+)?('|")$projectId('|")''')
          .hasMatch(firebaseOptions)) {
        return false;
      }
    }
    return true;
  }

  /// Checks if the command is running in a CI/CD environment.
  ///
  /// Looks for the 'CI' environment variable set to 'true'.
  ///
  /// Returns: true if running in CI/CD, false otherwise
  ///
  /// Example:
  /// ```dart
  /// // Check if running in CI/CD
  /// if (FirebaseHelper.isCiCdEnvironment()) {
  ///   print('Running in CI/CD environment');
  ///   // Use non-interactive Firebase configuration
  /// } else {
  ///   print('Running in local development environment');
  ///   // Use interactive Firebase configuration
  /// }
  /// ```
  static bool isCiCdEnvironment() {
    return Platform.environment.containsKey('CI') &&
        Platform.environment['CI'] == 'true';
  }

  /// Builds the flutterfire command string with appropriate parameters.
  ///
  /// Constructs a properly formatted flutterfire command with all
  /// the required and optional parameters.
  ///
  /// Parameters:
  /// - [config]: Firebase configuration parameters
  ///
  /// Returns: Formatted flutterfire command string
  ///
  /// Example:
  /// ```dart
  /// // Build flutterfire command from configuration
  /// final config = {
  ///   'project_id': 'my-project',
  ///   'platform': 'android,ios',
  ///   'android_package_name': 'com.example.myapp',
  ///   'ios_bundle_id': 'com.example.myapp',
  /// };
  /// final command = FirebaseHelper.buildFlutterFireCommand(config);
  /// print('Generated command: $command');
  /// // Execute the command
  /// await command.run;
  /// ```
  static String buildFlutterFireCommand(Map<dynamic, dynamic> config) {
    final project = config['project_id'];
    final token = config['token'];
    final platform = config['platform'];
    final output = config['output'];
    final androidPackageName = config['android_package_name'];
    final iosBundleId = config['ios_bundle_id'];
    final webAppId = config['web_app_id'];

    final argToken =
        token is String && token.isNotEmpty ? ' -t "$token"' : '';
    final argPlatform = platform is String && platform.isNotEmpty
        ? ' --platforms="$platform"'
        : '';
    final argWebAppId =
        webAppId is String && webAppId.isNotEmpty ? ' -w "$webAppId"' : '';
    final argOutput =
        output is String && output.isNotEmpty ? ' -o "$output"' : '';

    return 'flutterfire configure $argToken$argPlatform$argWebAppId$argOutput '
           '-p "$project" '
           '-a "$androidPackageName" '
           '-i "$iosBundleId" '
           '-m "$iosBundleId" '
           '-w "$androidPackageName" '
           '-x "$androidPackageName" '
           '-y';
  }

  /// Validates that the flutterfire CLI tool is installed.
  ///
  /// Checks if the flutterfire command is available in the system PATH.
  ///
  /// Returns: true if flutterfire is installed, false otherwise
  ///
  /// Example:
  /// ```dart
  /// // Check if flutterfire is installed before configuring Firebase
  /// if (FirebaseHelper.validateFlutterFireInstallation()) {
  ///   print('flutterfire CLI is installed');
  ///   // Proceed with Firebase configuration
  /// } else {
  ///   print('flutterfire CLI is not installed');
  ///   print('Please install it with: dart pub global activate flutterfire_cli');
  /// }
  /// ```
  static bool validateFlutterFireInstallation() {
    return which('flutterfire').found;
  }
}