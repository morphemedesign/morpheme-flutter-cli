import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Runs integration tests using Cucumber/Gherkin feature files.
///
/// The CucumberCommand generates and executes integration tests from
/// .feature files written in Gherkin syntax. It supports device targeting,
/// flavor-specific testing, and generates HTML reports for test results.
///
/// ## Usage
///
/// Run all feature tests:
/// ```bash
/// morpheme cucumber
/// ```
///
/// Run specific feature tests:
/// ```bash
/// morpheme cucumber login,checkout
/// ```
///
/// Run with specific flavor:
/// ```bash
/// morpheme cucumber --flavor production
/// ```
///
/// Run on specific device:
/// ```bash
/// morpheme cucumber --device-id emulator-5554
/// ```
///
/// ## Options
///
/// - `--flavor`: Target environment flavor (default: dev)
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--generate-l10n`: Generate localization files before testing
/// - `--device-id`: Target device identifier for testing
///
/// ## Feature Files
///
/// Tests are discovered from `integration_test/features/*.feature` files.
/// Each .feature file should contain Gherkin scenarios describing
/// the integration test behavior.
///
/// ## Report Generation
///
/// - Generates NDJSON output for test processing
/// - Creates HTML reports when npm is available
/// - Reports are saved to `integration_test/report/`
///
/// ## Dependencies
///
/// - Requires `gherkin` command-line tool
/// - Uses Flutter integration test framework
/// - Optional: npm for HTML report generation
/// - Requires valid morpheme.yaml configuration
///
/// ## Exceptions
///
/// Throws [ProcessException] if gherkin tool is not found.
/// Throws [FileSystemException] if feature files are missing.
/// Throws [TestFailureException] if integration tests fail.
class CucumberCommand extends Command {
  /// Creates a new instance of CucumberCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--flavor`: Environment flavor for testing
  /// - `--morpheme-yaml`: Path to morpheme.yaml configuration
  /// - `--generate-l10n`: Flag to generate localization files
  /// - `--device-id`: Target device for integration testing
  CucumberCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
    argParser.addFlagGenerateL10n();
    argParser.addOptionDeviceId();
  }
  @override
  String get name => 'cucumber';

  @override
  String get description =>
      'Run integration tests from Gherkin .feature files with comprehensive reporting';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      if (!_validateDependencies()) return;
      if (!_validateInputs()) return;

      final now = DateTime.now();
      final config = _prepareConfiguration();

      if (config['generateL10n']) {
        await _generateLocalization(config);
      }

      await _prepareFirebaseConfiguration(config);
      final features = _discoverFeatureFiles(config);
      final ndjsons = await _processFeatureFiles(features);
      _saveTestOutput(ndjsons);

      await _executeIntegrationTests(config);

      final totalTime = DateTime.now().difference(now);
      printMessage('⏰ Total Time: ${formatDurationInHhMmSs(totalTime)}');
    } catch (e) {
      StatusHelper.failed('Cucumber testing failed: ${e.toString()}',
          suggestion: 'Ensure gherkin is installed and feature files exist',
          examples: [
            'npm install -g @cucumber/gherkin-cli',
            'morpheme doctor'
          ]);
    }
  }

  /// Validates that required dependencies are available.
  ///
  /// Checks for the presence of the gherkin command-line tool
  /// which is required for processing .feature files.
  ///
  /// Returns true if all dependencies are available, false otherwise.
  bool _validateDependencies() {
    if (which('gherkin').notfound) {
      StatusHelper.failed('gherkin command-line tool not found',
          suggestion: 'Install the gherkin CLI tool to process .feature files',
          examples: ['npm install -g @cucumber/gherkin-cli']);
      return false;
    }
    return true;
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

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

  /// Prepares the testing configuration from command arguments.
  ///
  /// Returns a map containing all testing parameters including
  /// flavor settings, device options, and feature specifications.
  Map<String, dynamic> _prepareConfiguration() {
    final specificFeature =
        argResults?.rest.firstOrNull?.replaceAll('.feature', '').split(',');
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argGenerateL10n = argResults.getFlagGenerateL10n();
    final deviceId = argResults.getDeviceId();

    return {
      'specificFeature': specificFeature,
      'flavor': argFlavor,
      'yamlPath': argMorphemeYaml,
      'generateL10n': argGenerateL10n,
      'deviceId': deviceId,
    };
  }

  /// Generates localization files if requested.
  ///
  /// Runs the morpheme l10n command to ensure all localization
  /// files are up to date before running integration tests.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing localization settings
  Future<void> _generateLocalization(Map<String, dynamic> config) async {
    final yamlPath = config['yamlPath'];
    await 'morpheme l10n --morpheme-yaml "$yamlPath"'.run;
  }

  /// Prepares Firebase configuration for the specified flavor.
  ///
  /// Sets up environment-specific Firebase settings and creates
  /// dart-define arguments for the Flutter test runner.
  ///
  /// Parameters:
  /// - [config]: Configuration map that will be updated with dart defines
  Future<void> _prepareFirebaseConfiguration(
      Map<String, dynamic> config) async {
    final flavor = FlavorHelper.byFlavor(config['flavor'], config['yamlPath']);
    FirebaseHelper.run(config['flavor'], config['yamlPath']);

    final List<String> dartDefines = [];
    flavor.forEach((key, value) {
      dartDefines.add('${Constants.dartDefine} "$key=$value"');
    });

    config['dartDefines'] = dartDefines;
  }

  /// Discovers feature files to be processed.
  ///
  /// Scans the integration_test/features directory for .feature files,
  /// either all files or specific ones if specified in arguments.
  ///
  /// Parameters:
  /// - [config]: Configuration containing feature specifications
  ///
  /// Returns: List of feature file paths
  List<String> _discoverFeatureFiles(Map<String, dynamic> config) {
    final specificFeature = config['specificFeature'] as List<String>?;

    final pattern =
        specificFeature?.map((e) => '$e.feature').join('|') ?? '*.feature';

    return find(
      pattern,
      workingDirectory: join(current, 'integration_test', 'features'),
    ).toList();
  }

  /// Processes feature files through the gherkin command.
  ///
  /// Runs the gherkin processor on each feature file and collects
  /// the NDJSON output for test generation.
  ///
  /// Parameters:
  /// - [features]: List of feature file paths to process
  ///
  /// Returns: List of NDJSON maps containing processed feature data
  Future<List<Map<String, String>>> _processFeatureFiles(
      List<String> features) async {
    final List<Map<String, String>> ndjsons = [];

    for (var element in features) {
      await 'gherkin "$element"'.start(
        progressOut: (line) {
          ndjsons.add({'ndjson': line});
        },
      );
    }

    return ndjsons;
  }

  /// Saves the processed test output to files.
  ///
  /// Creates the ndjson directory and writes the processed
  /// feature data for use by the integration test runner.
  ///
  /// Parameters:
  /// - [ndjsons]: List of processed feature data
  void _saveTestOutput(List<Map<String, String>> ndjsons) {
    final pathNdjson = join(current, 'integration_test', 'ndjson');
    createDir(pathNdjson);
    join(pathNdjson, 'ndjson_gherkin.json').write(jsonEncode(ndjsons));

    StatusHelper.generated(pathNdjson);
  }

  /// Executes the integration tests using Flutter test framework.
  ///
  /// Runs the cucumber_test.dart file with appropriate dart-define
  /// arguments and processes the output for report generation.
  ///
  /// Parameters:
  /// - [config]: Configuration containing test execution settings
  Future<void> _executeIntegrationTests(Map<String, dynamic> config) async {
    final dartDefines = config['dartDefines'] as List<String>;
    final deviceId = config['deviceId'] ?? '';

    printMessage('Starting cucumber integration test....');

    await FlutterHelper.start(
      'test integration_test/cucumber_test.dart ${dartDefines.join(' ')} --dart-define "INTEGRATION_TEST=true" --no-pub $deviceId',
      progressOut: (line) async {
        await _processTestOutput(line);
      },
    );
  }

  /// Processes individual lines of test output.
  ///
  /// Handles different types of output including cucumber reports,
  /// stdout messages, and failure notifications.
  ///
  /// Parameters:
  /// - [line]: Individual line of test output
  Future<void> _processTestOutput(String line) async {
    if (line.contains('cucumber-report')) {
      await _generateHtmlReport(line);
    } else if (line.contains('morpheme-cucumber-stdout')) {
      final message = line.replaceAll('morpheme-cucumber-stdout: ', '');
      printMessage(message);
    } else if (line.toLowerCase().contains('failed')) {
      StatusHelper.failed(isExit: false, line);
    } else if (RegExp(r'\d{0,2}:\d{0,2}').hasMatch(line) ||
        line.trim().isEmpty) {
      // Skip timestamp and empty lines
    } else {
      printMessage(line);
    }
  }

  /// Generates HTML report from cucumber test results.
  ///
  /// Creates an HTML report if npm is available and processes
  /// the cucumber report JSON output.
  ///
  /// Parameters:
  /// - [reportLine]: Line containing cucumber report data
  Future<void> _generateHtmlReport(String reportLine) async {
    final dir = join(current, 'integration_test', 'report');
    createDir(dir);

    final cucumberReport = reportLine.replaceAll('cucumber-report: ', '');
    join(dir, 'cucumber-report.json').write(cucumberReport);

    if (which('npm').found) {
      await 'npm install'.start(
        workingDirectory: dir,
        showLog: false,
      );
      await 'node index.js'.start(
        workingDirectory: dir,
        showLog: false,
      );

      printMessage(
          '🚀 Cucumber HTML report cucumber-report.html generated successfully 👍');
    }
  }

  /// Formats duration in HH:MM:SS format for display.
  ///
  /// Converts a Duration object to a human-readable time format
  /// showing hours, minutes, and seconds with zero padding.
  ///
  /// Parameters:
  /// - [duration]: Duration to format
  ///
  /// Returns: Formatted time string in HH:MM:SS format
  String formatDurationInHhMmSs(Duration duration) {
    final hh = (duration.inHours).toString().padLeft(2, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }
}
