import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/firebase/models/firebase_config.dart';

/// Generates Firebase configuration for both Android & iOS platforms.
///
/// The FirebaseCommand sets up Firebase configuration files for Flutter applications
/// by running the flutterfire CLI tool with appropriate parameters. It supports:
/// - Flavor-specific Firebase configuration
/// - Multiple platform targeting (Android, iOS, Web)
/// - CI/CD environment integration with service accounts
/// - Configuration regeneration control
/// - Automatic flutterfire installation validation
///
/// ## Usage
///
/// Basic Firebase setup:
/// ```bash
/// morpheme generate firebase
/// ```
///
/// Setup for specific flavor:
/// ```bash
/// morpheme generate firebase --flavor dev
/// ```
///
/// Force overwrite existing configuration:
/// ```bash
/// morpheme generate firebase --overwrite
/// ```
///
/// With custom morpheme.yaml path:
/// ```bash
/// morpheme generate firebase --morpheme-yaml path/to/morpheme.yaml
/// ```
///
/// ## Configuration
///
/// The command reads Firebase configuration from morpheme.yaml:
/// ```yaml
/// flavors:
///   dev:
///     firebase:
///       project_id: "your-project-id"
///       token: "optional-auth-token"
///       platform: "android,ios"
///       output: "lib/firebase_options.dart"
///       android_package_name: "com.example.app"
///       ios_bundle_id: "com.example.app"
///       web_app_id: "web-app-id"
///       service_account: "path/to/service-account.json"
///       enable_ci_use_service_account: true
/// ```
///
/// ## Output
///
/// - Generates firebase_options.dart with Firebase configuration
/// - Reports success or failure with detailed feedback
/// - Handles CI/CD environments with service account authentication
///
/// ## Dependencies
///
/// - Requires flutterfire_cli to be installed globally
/// - Valid morpheme.yaml configuration file
/// - Service account JSON file for CI/CD environments (optional)
///
/// ## Exceptions
///
/// Throws [FileSystemException] if morpheme.yaml is missing or invalid.
/// Throws [ProcessException] if flutterfire command fails to execute.
class FirebaseCommand extends Command {
  /// Creates a new instance of FirebaseCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--flavor`: Select flavor apps (defaults to 'dev')
  /// - `--morpheme-yaml`: Path to the morpheme.yaml configuration file
  /// - `--overwrite`: Force overwrite firebase configuration
  FirebaseCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'overwrite',
      abbr: 'o',
      help: 'Force overwrite firebase configuration',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'firebase';

  @override
  String get description => 'Generate google service both android & ios.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    try {
      // Validate inputs
      if (!_validateInputs()) return;

      // Prepare configuration
      final config = _prepareConfiguration();

      // Execute generation
      final success = await _executeGeneration(config);

      if (success) {
        _reportSuccess();
      }
    } catch (e) {
      StatusHelper.failed(
        'Firebase setup failed: ${e.toString()}',
        suggestion: 'Check your configuration and try again',
        examples: [
          'morpheme generate firebase --help',
          'dart pub global activate flutterfire_cli',
        ],
      );
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    try {
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    } catch (e) {
      StatusHelper.failed(
        'Invalid morpheme.yaml configuration: ${e.toString()}',
        suggestion: 'Ensure morpheme.yaml exists and has valid syntax',
        examples: ['morpheme init', 'morpheme config'],
      );
      return false;
    }

    return true;
  }

  /// Prepares the Firebase configuration from morpheme.yaml.
  ///
  /// Returns a map containing all Firebase configuration parameters
  /// extracted from the configuration file for the specified flavor.
  Map<String, dynamic> _prepareConfiguration() {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argOverwrite = argResults?['overwrite'] as bool? ?? false;

    final firebase = FirebaseHelper.byFlavor(argFlavor, argMorphemeYaml);

    if (firebase.isEmpty) {
      StatusHelper.warning(
          'Cannot setup flavor firebase, You don\'t have config "firebase" with flavor "$argFlavor" in morpheme.yaml');
    }

    // Add overwrite flag to the configuration
    final config = Map<String, dynamic>.from(firebase);
    config['overwrite'] = argOverwrite;

    return config;
  }

  /// Executes the Firebase configuration generation process.
  ///
  /// Coordinates the complete Firebase setup workflow including:
  /// - FlutterFire installation validation
  /// - Regeneration decision logic
  /// - CI/CD environment handling
  /// - Command execution
  ///
  /// Parameters:
  /// - [config]: The configuration for Firebase setup
  ///
  /// Returns: true if generation was successful, false otherwise
  Future<bool> _executeGeneration(Map<String, dynamic> config) async {
    // Check if we have Firebase configuration
    if (config.isEmpty) {
      return false;
    }

    // Validate flutterfire installation
    if (!FirebaseHelper.validateFlutterFireInstallation()) {
      StatusHelper.failed(
        'flutterfire not installed, You can install with \'dart pub global activate flutterfire_cli\'',
        suggestion: 'Install the flutterfire CLI tool to use this feature',
        examples: ['dart pub global activate flutterfire_cli'],
      );
      return false;
    }

    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argOverwrite = config['overwrite'] as bool;

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);
    final firebaseConfig = FirebaseConfig.fromMap(config, flavor);

    // Check if regeneration is needed
    final shouldRegenerate = FirebaseHelper.shouldRegenerate(
        firebaseConfig.projectId, firebaseConfig.output);

    if (!shouldRegenerate && !argOverwrite) {
      StatusHelper.generated('you already have lib/firebase_options.dart');
      return true;
    }

    // Check CI/CD environment
    final isCiCdEnvironment = FirebaseHelper.isCiCdEnvironment();
    final isExistServiceAccount = firebaseConfig.serviceAccount != null &&
        firebaseConfig.serviceAccount!.isNotEmpty &&
        exists(firebaseConfig.serviceAccount!);

    final commandFlutterFire =
        FirebaseHelper.buildFlutterFireCommand(firebaseConfig);

    // Handle CI/CD with service account
    if ((isCiCdEnvironment && firebaseConfig.enableCiUseServiceAccount ||
            !isCiCdEnvironment) &&
        isExistServiceAccount &&
        (shouldRegenerate || argOverwrite)) {
      final filename = join(current, 'firebase_command.sh');

      filename.write('''#!/bin/bash
        
export GOOGLE_APPLICATION_CREDENTIALS="${firebaseConfig.serviceAccount}"

$commandFlutterFire
''');

      await 'chmod +x $filename'.run;
      await filename.run;

      delete(filename);
      return true;
    }

    // Handle local development or CI/CD without service account
    if ((!isExistServiceAccount) && (shouldRegenerate || argOverwrite)) {
      await commandFlutterFire.run;
      return true;
    }

    return true;
  }

  /// Reports successful completion of the Firebase setup.
  ///
  /// Displays a success message indicating that Firebase configuration
  /// has been completed successfully.
  void _reportSuccess() {
    StatusHelper.success('Firebase configuration generated successfully!');
  }
}
