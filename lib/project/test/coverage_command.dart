import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to generate comprehensive test coverage reports for Flutter projects.
///
/// This command extends the basic test functionality by running tests with
/// coverage analysis, processing LCOV files to remove ignored paths, and
/// generating HTML coverage reports for easy visualization.
///
/// **Purpose:**
/// - Execute comprehensive test coverage analysis across all project modules
/// - Generate clean coverage reports by excluding ignored files
/// - Produce HTML visualization of coverage data
/// - Support selective coverage analysis by app, feature, or page
///
/// **Coverage Process:**
/// 1. Execute tests with coverage enabled across all modules
/// 2. Merge LCOV files from all modules into a unified report
/// 3. Remove ignored files/patterns as configured in morpheme.yaml
/// 4. Generate HTML coverage report for visualization
///
/// **Configuration (morpheme.yaml):**
/// ```yaml
/// coverage:
///   output_html_dir: "coverage/html"
///   remove:
///     - "**/generated/**"
///     - "**/mock/**"
///     - "**/*.g.dart"
///     - "**/*.freezed.dart"
/// ```
///
/// **Usage Examples:**
/// ```bash
/// # Generate coverage for entire project
/// morpheme coverage
///
/// # Coverage for specific feature
/// morpheme coverage --feature authentication
///
/// # Coverage with custom reporter
/// morpheme coverage --reporter json --file-reporter json:coverage/report.json
/// ```
///
/// **Requirements:**
/// - `lcov` tool must be installed for processing coverage files
/// - `genhtml` tool must be installed for generating HTML reports
/// - Valid coverage configuration in morpheme.yaml
///
/// **Parameters:**
/// - `--apps` (`-a`): Target specific app for coverage analysis
/// - `--feature` (`-f`): Target specific feature for coverage analysis
/// - `--page` (`-p`): Target specific page for coverage analysis
/// - `--reporter` (`-r`): Set test result output format
/// - `--file-reporter`: Save test results to file
///
/// **Output:**
/// - Merged LCOV file: `coverage/merge_lcov.info`
/// - HTML report: Configured output directory (default: `coverage/html`)
///
/// **Exceptions:**
/// - Throws [ConfigurationException] if coverage config is missing
/// - Throws [ToolException] if lcov/genhtml tools are not found
/// - Throws [ProcessException] if coverage processing fails
class CoverageCommand extends Command {
  CoverageCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'apps',
      abbr: 'a',
      help: 'Generate coverage for specific app (optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Generate coverage for specific feature (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Generate coverage for specific page (optional)',
    );
    argParser.addOption(
      'reporter',
      abbr: 'r',
      help: '''Test result output format:

          [compact]       Single line, updated continuously (default)
          [expanded]      Separate line for each update, ideal for CI
          [failures-only] Only show failing tests
          [github]        GitHub Actions compatible format
          [json]          Machine-readable JSON format
          [silent]        No output, exit code only''',
      allowed: [
        'compact',
        'expanded',
        'failures-only',
        'github',
        'json',
        'silent',
      ],
    );
    argParser.addOption(
      'file-reporter',
      help: '''Save test results to file in specified format.
                                                             Format: <reporter>:<filepath>
                                                             Example: "json:reports/tests.json"''',
    );
  }

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Generate comprehensive test coverage reports with HTML visualization for the project and all modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      // Parse and validate arguments
      final coverageConfig = _parseCoverageConfiguration();
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();

      // Validate morpheme.yaml and coverage configuration
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      final morphemeConfig = YamlHelper.loadFileYaml(argMorphemeYaml);
      final coverageSettings = _validateCoverageSettings(morphemeConfig);

      printMessage('🏃 Starting comprehensive coverage analysis...');

      // Execute tests with coverage
      await _executeTestsWithCoverage(coverageConfig, argMorphemeYaml);

      // Validate required tools are available
      _validateCoverageTools();

      // Process coverage data
      await _processCoverageData(coverageSettings);

      // Generate HTML report
      await _generateHtmlReport(coverageSettings);

      printMessage('✨ Coverage analysis completed successfully!');
      StatusHelper.success(
          'Coverage report generated to ${coverageSettings.outputHtmlDir}');
    } catch (e) {
      StatusHelper.failed('Coverage analysis failed: $e');
    }
  }

  /// Parses command line arguments for coverage configuration.
  ///
  /// **Returns:** [CoverageConfiguration] with parsed parameters
  CoverageConfiguration _parseCoverageConfiguration() {
    final apps = argResults?['apps']?.toString().snakeCase;
    final feature = argResults?['feature']?.toString().snakeCase;
    final page = argResults?['page']?.toString().snakeCase;
    final reporter = argResults?['reporter'] as String?;
    final fileReporter = argResults?['file-reporter'] as String?;

    return CoverageConfiguration(
      apps: apps,
      feature: feature,
      page: page,
      reporter: reporter,
      fileReporter: fileReporter,
    );
  }

  /// Validates and extracts coverage settings from morpheme.yaml.
  ///
  /// **Parameters:**
  /// - [morphemeConfig]: The loaded morpheme.yaml configuration
  ///
  /// **Returns:** [CoverageSettings] with validated configuration
  ///
  /// **Throws:**
  /// - [ConfigurationException] if coverage configuration is missing or invalid
  CoverageSettings _validateCoverageSettings(
      Map<dynamic, dynamic> morphemeConfig) {
    if (!morphemeConfig.containsKey('coverage')) {
      throw const FormatException(
          'Coverage configuration missing in morpheme.yaml. '
          'Please add a "coverage" section with required settings.');
    }

    final coverageConfig = morphemeConfig['coverage'] as Map<dynamic, dynamic>;

    final outputHtmlDir =
        coverageConfig['output_html_dir']?.toString() ?? 'coverage/html';
    final removePatterns =
        (coverageConfig['remove'] as List?)?.cast<String>() ?? [];

    if (removePatterns.isEmpty) {
      printMessage(
          '⚠️  Warning: No file removal patterns configured in coverage settings');
    }

    return CoverageSettings(
      outputHtmlDir: outputHtmlDir,
      removePatterns: removePatterns,
    );
  }

  /// Executes tests with coverage enabled.
  ///
  /// **Parameters:**
  /// - [config]: Coverage configuration with test parameters
  /// - [morphemeYamlPath]: Path to morpheme.yaml file
  Future<void> _executeTestsWithCoverage(
    CoverageConfiguration config,
    String morphemeYamlPath,
  ) async {
    printMessage('🧠 Running tests with coverage analysis...');

    // Build test command arguments
    final testArgs = _buildTestArguments(config, morphemeYamlPath);

    // Execute the test command with coverage
    await testArgs.run;

    printMessage('✓ Test execution with coverage completed');
  }

  /// Builds test command arguments including coverage flags.
  ///
  /// **Parameters:**
  /// - [config]: Coverage configuration
  /// - [morphemeYamlPath]: Path to morpheme.yaml file
  ///
  /// **Returns:** Test command string with all necessary arguments
  String _buildTestArguments(
    CoverageConfiguration config,
    String morphemeYamlPath,
  ) {
    final args = <String>[
      'morpheme test',
      '--morpheme-yaml $morphemeYamlPath',
      '--coverage',
    ];

    if (config.apps != null) args.add('-a ${config.apps}');
    if (config.feature != null) args.add('-f ${config.feature}');
    if (config.page != null) args.add('-p ${config.page}');
    if (config.reporter != null) args.add('--reporter ${config.reporter}');
    if (config.fileReporter != null) {
      args.add('--file-reporter ${config.fileReporter}');
    }

    return args.where((arg) => arg.isNotEmpty).join(' ');
  }

  /// Validates that required coverage processing tools are available.
  ///
  /// **Throws:**
  /// - [ToolException] if required tools are missing
  void _validateCoverageTools() {
    printMessage('🔧 Validating coverage processing tools...');

    if (Platform.isWindows) {
      printMessage(
          '⚠️  Windows detected: You must install Perl and LCOV manually. '
          'Some features may require manual processing.');
      return;
    }

    if (which('lcov').notfound) {
      throw const ProcessException(
          'lcov',
          [],
          'LCOV tool not found. Please install LCOV to process coverage data. '
              'On macOS: brew install lcov, On Ubuntu: apt-get install lcov');
    }

    printMessage('✓ LCOV tool found and ready');
  }

  /// Processes coverage data by removing ignored files and patterns.
  ///
  /// **Parameters:**
  /// - [settings]: Coverage settings with removal patterns
  Future<void> _processCoverageData(CoverageSettings settings) async {
    printMessage('📁 Processing coverage data...');

    final lcovPath = join(current, 'coverage', 'merge_lcov.info')
        .toString()
        .replaceAll('/', separator);

    if (!exists(lcovPath)) {
      throw Exception(
          'Coverage data file not found at $lcovPath. Please ensure tests were run with coverage enabled');
    }

    if (settings.removePatterns.isNotEmpty) {
      await _removeIgnoredFiles(lcovPath, settings.removePatterns);
    } else {
      printMessage('⚠️  No file patterns to remove from coverage');
    }

    printMessage('✓ Coverage data processing completed');
  }

  /// Removes ignored files from the LCOV coverage data.
  ///
  /// **Parameters:**
  /// - [lcovPath]: Path to the LCOV file
  /// - [removePatterns]: List of file patterns to remove
  Future<void> _removeIgnoredFiles(
      String lcovPath, List<String> removePatterns) async {
    final removeArgs = removePatterns.join(' ');
    final lcovCommand =
        'lcov --remove $lcovPath $removeArgs -o $lcovPath --ignore-errors unused';

    printMessage('🧹 Removing ignored files from coverage data...');
    printMessage('Executing: $lcovCommand');

    try {
      await lcovCommand.run;
      printMessage('✓ Successfully removed ignored files from coverage');
    } catch (e) {
      throw ProcessException('lcov', ['--remove'],
          'Failed to remove ignored files from coverage data: $e');
    }
  }

  /// Generates HTML coverage report.
  ///
  /// **Parameters:**
  /// - [settings]: Coverage settings with output directory
  Future<void> _generateHtmlReport(CoverageSettings settings) async {
    printMessage('🎨 Generating HTML coverage report...');

    // Validate genhtml tool availability
    if (which('genhtml').notfound) {
      throw const ProcessException(
          'genhtml',
          [],
          'genhtml tool not found. Please install LCOV package which includes genhtml. '
              'On macOS: brew install lcov, On Ubuntu: apt-get install lcov');
    }

    final lcovPath = join(current, 'coverage', 'merge_lcov.info')
        .toString()
        .replaceAll('/', separator);
    final outputDir = settings.outputHtmlDir.replaceAll('/', separator);

    final genhtmlCommand = 'genhtml $lcovPath -o $outputDir';

    try {
      await genhtmlCommand.run;
      printMessage('✓ HTML coverage report generated successfully');
      printMessage(
          '🌎 Open $outputDir/index.html in your browser to view the report');
    } catch (e) {
      throw ProcessException('genhtml', [lcovPath, '-o', outputDir],
          'Failed to generate HTML coverage report: $e');
    }
  }
}

/// Configuration class for coverage command parameters.
class CoverageConfiguration {
  const CoverageConfiguration({
    this.apps,
    this.feature,
    this.page,
    this.reporter,
    this.fileReporter,
  });

  final String? apps;
  final String? feature;
  final String? page;
  final String? reporter;
  final String? fileReporter;
}

/// Data class for coverage settings from morpheme.yaml.
class CoverageSettings {
  const CoverageSettings({
    required this.outputHtmlDir,
    required this.removePatterns,
  });

  final String outputHtmlDir;
  final List<String> removePatterns;
}
