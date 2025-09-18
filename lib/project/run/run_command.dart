import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to run Flutter applications with flavor support.
///
/// This command provides a streamlined way to run Flutter applications
/// with environment-specific configurations defined in morpheme.yaml.
/// It supports various build modes, device targeting, and integration
/// with localization and Firebase services.
///
/// ## Usage Examples
/// ```bash
/// # Run with default development flavor
/// morpheme run
///
/// # Run with staging flavor
/// morpheme run --flavor stag
///
/// # Run with specific target and release mode
/// morpheme run --target lib/main_prod.dart --release
///
/// # Generate localization before running
/// morpheme run --l10n
/// ```
///
/// ## Parameters
/// - `--flavor`: Environment flavor (dev, stag, prod) - defaults to dev
/// - `--target`: Main Dart file to run - defaults to lib/main.dart
/// - `--debug`: Run in debug mode (default)
/// - `--profile`: Run in profile mode
/// - `--release`: Run in release mode
/// - `--device-id`: Target specific device
/// - `--l10n`: Generate localization files before running
/// - `--command-only`: Print command without executing
///
/// ## Configuration
/// The command reads flavor configurations from morpheme.yaml:
/// ```yaml
/// flavor:
///   dev:
///     FLAVOR: dev
///     APP_NAME: MyApp Dev
///     BASE_URL: https://dev.api.example.com
///   prod:
///     FLAVOR: prod
///     APP_NAME: MyApp
///     BASE_URL: https://api.example.com
/// ```
///
/// ## Dependencies
/// - Requires valid morpheme.yaml configuration
/// - Requires Flutter SDK to be installed and accessible
/// - Firebase integration requires firebase.json in project root
///
/// ## Exceptions
/// - Throws [FileSystemException] if morpheme.yaml is missing or invalid
/// - Throws [ProcessException] if Flutter command fails to execute

class RunCommand extends Command {
  RunCommand() {
    argParser.addFlagDebug(defaultsTo: true);
    argParser.addFlagProfile();
    argParser.addFlagRelease(defaultsTo: false);
    argParser.addFlag(
      'command-only',
      abbr: 'c',
      help: 'Run only the command without executing it',
      defaultsTo: false,
    );

    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addFlagGenerateL10n();
    argParser.addOptionDeviceId();
  }

  @override
  String get name => 'run';

  @override
  String get description =>
      'Run your Flutter app on an attached device with flavor.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      // Step 1: Validate inputs and configuration
      if (!_validateInputs()) return;

      // Step 2: Prepare configuration
      final config = _prepareConfiguration();

      // Step 3: Execute the run process
      await _executeRun(config);

      // Step 4: Report success
      _reportSuccess();
    } catch (e) {
      StatusHelper.failed('Run command failed: ${e.toString()}',
          suggestion:
              'Check your configuration and ensure Flutter is available',
          examples: ['morpheme doctor', 'flutter doctor']);
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final argTarget = argResults.getOptionTarget();
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    // Validate target file exists
    if (!exists(argTarget)) {
      StatusHelper.failed('Target file not found: $argTarget',
          suggestion: 'Ensure the target file exists or specify a valid target',
          examples: [
            'morpheme run',
            'morpheme run --target lib/main_dev.dart'
          ]);
      return false;
    }

    // Validate morpheme.yaml configuration
    try {
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      return true;
    } catch (e) {
      StatusHelper.failed(
          'Invalid morpheme.yaml configuration: ${e.toString()}',
          suggestion: 'Ensure morpheme.yaml exists and has valid syntax',
          examples: ['morpheme init', 'morpheme config']);
      return false;
    }
  }

  /// Prepares the run configuration from command arguments and morpheme.yaml.
  ///
  /// Returns a map containing all necessary configuration for execution.
  Map<String, dynamic> _prepareConfiguration() {
    return {
      'target': argResults.getOptionTarget(),
      'flavor': argResults.getOptionFlavor(defaultTo: Constants.dev),
      'morphemeYaml': argResults.getOptionMorphemeYaml(),
      'generateL10n': argResults.getFlagGenerateL10n(),
      'deviceId': argResults.getDeviceId(),
      'commandOnly': argResults?['command-only'] as bool,
      'mode': argResults.getMode(),
    };
  }

  /// Executes the Flutter run command with the prepared configuration.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing all execution parameters
  Future<void> _executeRun(Map<String, dynamic> config) async {
    CucumberHelper.removeNdjsonGherkin();

    // Generate localization if requested
    if (config['generateL10n']) {
      await 'morpheme l10n --morpheme-yaml "${config['morphemeYaml']}"'.run;
    }

    // Process flavor configuration
    final flavor =
        FlavorHelper.byFlavor(config['flavor'], config['morphemeYaml']);

    // Run Firebase helper tasks
    FirebaseHelper.run(config['flavor'], config['morphemeYaml']);

    // Prepare dart defines from flavor configuration
    List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });

    // Construct the Flutter command
    final flutterCommand =
        'run -t ${config['target']} ${dartDefines.join(' ')} ${config['mode']} ${config['deviceId']}';

    // Execute or print command based on command-only flag
    if (config['commandOnly']) {
      printMessage(flutterCommand);
      return;
    }

    // Use startWithStdin method to allow stdin to be forwarded to the Flutter process
    await FlutterHelper.startWithStdin(
      'run -t ${config['target']} ${dartDefines.join(' ')} ${config['mode']} ${config['deviceId']}',
      showLog: true,
      singleCharacterMode: true,
    );
  }

  /// Reports successful completion of the run command.
  ///
  /// Displays a success message indicating that the run command
  /// has completed successfully.
  void _reportSuccess() {
    StatusHelper.success('run');
  }
}
