import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to execute Flutter unit tests across the project and all modules.
///
/// This command provides comprehensive testing capabilities for modular Flutter
/// projects, supporting selective testing of specific apps, features, or pages.
/// It automatically generates bundle test files and handles coverage reporting.
///
/// **Purpose:**
/// - Execute unit tests across modular project structure
/// - Generate and manage bundle test files for efficient test execution
/// - Support selective testing by app, feature, or page
/// - Provide code coverage analysis and reporting
/// - Combine coverage data from multiple modules
///
/// **Test Hierarchy:**
/// ```
/// Project
/// ├── Apps (Optional)
/// │   └── Features
/// │       └── Pages
/// └── Features (Global)
///     └── Pages
/// ```
///
/// **Usage Examples:**
/// ```bash
/// # Run all tests
/// morpheme test
///
/// # Test specific feature
/// morpheme test --feature authentication
///
/// # Test specific page in feature
/// morpheme test --feature authentication --page login
///
/// # Run with coverage
/// morpheme test --coverage
///
/// # Custom reporter
/// morpheme test --reporter json --file-reporter json:reports/tests.json
/// ```
///
/// **Parameters:**
/// - `--apps` (`-a`): Target specific app for testing
/// - `--feature` (`-f`): Target specific feature for testing
/// - `--page` (`-p`): Target specific page for testing
/// - `--coverage` (`-c`): Enable code coverage reporting
/// - `--reporter` (`-r`): Set test result output format
/// - `--file-reporter`: Save test results to file
///
/// **Bundle Test Generation:**
/// The command automatically generates `bundle_test.dart` files that import
/// and execute all individual test files within a module, enabling efficient
/// batch test execution.
///
/// **Coverage Integration:**
/// When coverage is enabled, the command collects LCOV data from all modules
/// and combines it into a unified coverage report at the project root.
///
/// **Exceptions:**
/// - Throws [ValidationException] if invalid test targets are specified
/// - Throws [FileSystemException] if test file operations fail
/// - Throws [TestExecutionException] if test runs fail
class TestCommand extends Command {
  TestCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'apps',
      abbr: 'a',
      help: 'Target specific app for testing (optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target specific feature for testing (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Target specific page within a feature (optional)',
    );
    argParser.addFlag(
      'coverage',
      abbr: 'c',
      help: 'Enable code coverage analysis and reporting',
      defaultsTo: false,
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
  String get name => 'test';

  @override
  String get description =>
      'Execute Flutter unit tests for the project and all modules with optional coverage analysis.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      // Parse command line arguments
      final testConfig = _parseTestConfiguration();
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();

      // Validate morpheme.yaml configuration
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
      final morphemeConfig = YamlHelper.loadFileYaml(argMorphemeYaml);

      printMessage('🧠 Preparing test environment...');

      // Generate bundle test files based on test scope
      await _generateBundleTestFiles(testConfig);

      // Execute tests based on configuration
      await _executeTests(testConfig, morphemeConfig);

      // Handle coverage data if enabled
      if (testConfig.isCoverage) {
        _handleCoverageData(testConfig);
      }

      printMessage('✨ Test execution completed successfully!');
      StatusHelper.success('morpheme test');
    } on TestDependencyError catch (e) {
      StatusHelper.failed('Test dependency validation failed');
      printMessage('');
      printMessage('❌ ${e.message}');
      printMessage('');
      printMessage('🔧 Resolution steps:');
      for (final step in e.resolutionSteps) {
        printMessage('   • $step');
      }
      printMessage('');
    } catch (e) {
      StatusHelper.failed('Test execution failed: $e');
    }
  }

  /// Parses and validates command line arguments for test configuration.
  ///
  /// **Returns:** [TestConfiguration] object with parsed parameters
  ///
  /// **Throws:**
  /// - [ValidationException] if invalid parameter combinations are provided
  TestConfiguration _parseTestConfiguration() {
    final apps = argResults?['apps']?.toString().snakeCase;
    final feature = argResults?['feature']?.toString().snakeCase;
    final page = argResults?['page']?.toString().snakeCase;
    final isCoverage = argResults?['coverage'] as bool? ?? false;
    final reporter = argResults?['reporter'] as String?;
    final fileReporter = argResults?['file-reporter'] as String?;

    // Validate parameter combinations
    if (page != null && feature == null) {
      throw const FormatException(
          'Feature parameter is required when specifying a page');
    }

    // Validate feature parameter is not empty
    if (feature != null && feature.isEmpty) {
      throw const FormatException('Feature name cannot be empty');
    }

    // Validate page parameter is not empty when provided
    if (page != null && page.isEmpty) {
      throw const FormatException('Page name cannot be empty');
    }

    return TestConfiguration(
      apps: apps?.isEmpty == true ? null : apps,
      feature: feature,
      page: page,
      isCoverage: isCoverage,
      reporter: reporter,
      fileReporter: fileReporter,
    );
  }

  /// Generates bundle test files based on the test configuration.
  ///
  /// Bundle test files aggregate individual test files within modules,
  /// enabling efficient batch test execution.
  ///
  /// **Parameters:**
  /// - [config]: Test configuration specifying the scope
  Future<void> _generateBundleTestFiles(TestConfiguration config) async {
    // Validate dependencies before generating bundle files
    await _validateTestDependencies();

    if (_isFullProjectTest(config)) {
      await _generateFullProjectBundles();
    } else if (config.page != null) {
      await _generatePageTestBundle(config);
    } else if (config.feature != null) {
      await _generateFeatureTestBundle(config);
    } else if (config.apps != null) {
      throw UnimplementedError('App-specific testing is not yet available');
    }
  }

  /// Checks if this is a full project test (no specific targets).
  bool _isFullProjectTest(TestConfiguration config) {
    return config.apps == null && config.feature == null && config.page == null;
  }

  /// Generates bundle test files for the entire project.
  Future<void> _generateFullProjectBundles() async {
    printMessage('📁 Generating test bundles for all modules...');

    await ModularHelper.runSequence(
      (modulePath) {
        final testDirectory = join(modulePath, 'test');
        createDir(testDirectory);

        final pageTestDirs = _findPageTestDirectories(testDirectory);

        // Generate bundles for each page
        for (final pageDir in pageTestDirs) {
          _cleanExistingBundleTests(pageDir);
          _createPageBundle(pageDir);
        }

        // Generate feature-level bundle
        _createFeatureBundle(testDirectory);
      },
      ignorePubWorkspaces: true,
    );
  }

  /// Generates bundle test files for a specific page.
  Future<void> _generatePageTestBundle(TestConfiguration config) async {
    if (config.feature == null || config.feature!.isEmpty) {
      throw Exception('Feature name is required for page testing');
    }

    if (config.page == null || config.page!.isEmpty) {
      throw Exception('Page name is required for page testing');
    }

    final testPaths = _buildTestPaths(config);

    if (!exists(testPaths.featurePath)) {
      throw Exception(
          'Feature test directory not found: ${testPaths.featurePath}\n'
          'Feature "${config.feature}" may not exist or may not have tests configured.\n\n'
          'Suggestions:\n'
          '- Verify feature exists: ls features/\n'
          '- Create feature: morpheme generate feature ${config.feature}\n'
          '- Check test directory: ls features/${config.feature}/');
    }

    if (!exists(testPaths.pagePath)) {
      throw Exception('Page test directory not found: ${testPaths.pagePath}\n'
          'Page "${config.page}" may not exist in feature "${config.feature}".\n\n'
          'Suggestions:\n'
          '- Verify page exists: ls features/${config.feature}/lib/\n'
          '- Create page: morpheme generate page ${config.page} --feature ${config.feature}\n'
          '- Check page test directory: ls features/${config.feature}/test/');
    }

    printMessage('📄 Generating bundle for page: ${config.page}');

    createDir(testPaths.featurePath);
    _cleanExistingBundleTests(testPaths.pagePath);
    _createPageBundle(testPaths.pagePath);
    _createFeatureBundle(testPaths.featurePath);
  }

  /// Generates bundle test files for a specific feature.
  Future<void> _generateFeatureTestBundle(TestConfiguration config) async {
    if (config.feature == null || config.feature!.isEmpty) {
      throw Exception('Feature name is required for feature testing');
    }

    final testPaths = _buildTestPaths(config);

    if (!exists(testPaths.featurePath)) {
      throw Exception(
          'Feature test directory not found: ${testPaths.featurePath}\n'
          'Feature "${config.feature}" may not exist or may not have tests configured.\n\n'
          'Suggestions:\n'
          '- Verify feature exists: ls features/\n'
          '- Create feature: morpheme generate feature ${config.feature}\n'
          '- Check test directory: ls features/${config.feature}/');
    }

    printMessage('🏠 Generating bundles for feature: ${config.feature}');

    createDir(testPaths.featurePath);

    final pageTestDirs = _findPageTestDirectories(testPaths.featurePath);
    for (final pageDir in pageTestDirs) {
      _cleanExistingBundleTests(pageDir);
      _createPageBundle(pageDir);
    }

    _createFeatureBundle(testPaths.featurePath);
  }

  /// Executes tests based on the provided configuration.
  ///
  /// **Parameters:**
  /// - [config]: Test configuration specifying scope and options
  /// - [morphemeConfig]: Project configuration from morpheme.yaml
  Future<void> _executeTests(
      TestConfiguration config, Map<dynamic, dynamic> morphemeConfig) async {
    printMessage('🏃 Executing tests...');

    final testArgs = _buildTestArguments(config);

    if (config.page != null) {
      await _executePageTests(config, testArgs);
    } else if (config.feature != null) {
      await _executeFeatureTests(config, testArgs);
    } else {
      await _executeFullProjectTests(morphemeConfig, config);
    }
  }

  /// Builds test command arguments from configuration.
  String _buildTestArguments(TestConfiguration config) {
    final args = <String>[];

    if (config.isCoverage) args.add('--coverage');
    if (config.reporter != null) args.add('--reporter ${config.reporter}');
    if (config.fileReporter != null) {
      args.add('--file-reporter ${config.fileReporter}');
    }

    return args.join(' ');
  }

  /// Executes tests for a specific page.
  Future<void> _executePageTests(
      TestConfiguration config, String testArgs) async {
    if (config.feature == null || config.page == null) {
      throw Exception(
          'Both feature and page names are required for page testing');
    }

    final workingDir = join(current, 'features', config.feature);
    final testFile = 'test/${config.page}_test/bundle_test.dart';

    await FlutterHelper.start(
      'test $testFile --no-pub $testArgs',
      workingDirectory: workingDir,
    );
  }

  /// Executes tests for a specific feature.
  Future<void> _executeFeatureTests(
      TestConfiguration config, String testArgs) async {
    if (config.feature == null) {
      throw Exception('Feature name is required for feature testing');
    }

    final workingDir = join(current, 'features', config.feature);

    await FlutterHelper.start(
      'test test/bundle_test.dart --no-pub $testArgs',
      workingDirectory: workingDir,
    );
  }

  /// Executes tests for the entire project.
  Future<void> _executeFullProjectTests(
      Map<dynamic, dynamic> morphemeConfig, TestConfiguration config) async {
    await ModularHelper.test(
      concurrent: morphemeConfig.concurrent,
      isCoverage: config.isCoverage,
      reporter: config.reporter,
      fileReporter: config.fileReporter,
    );
  }

  /// Builds test directory paths based on configuration.
  TestPaths _buildTestPaths(TestConfiguration config) {
    if (config.feature == null) {
      throw Exception('Feature name is required for building test paths');
    }

    final hasApps = config.apps != null && config.apps!.isNotEmpty;
    final pathApps = hasApps
        ? join(current, 'apps', '${config.apps}_test')
        : join(current, 'apps', '_test'); // Fallback for empty case

    final pathFeature = hasApps
        ? join(pathApps, 'features', config.feature, 'test')
        : join(current, 'features', config.feature, 'test');

    final pathPage = config.page != null
        ? join(pathFeature, '${config.page}_test')
        : pathFeature; // Use feature path when page is null

    return TestPaths(
      appsPath: pathApps,
      featurePath: pathFeature,
      pagePath: pathPage,
    );
  }

  /// Finds page test directories within a feature test directory.
  List<String> _findPageTestDirectories(String testDirectory) {
    return find(
      '*_test',
      workingDirectory: testDirectory,
      recursive: false,
      types: [Find.directory],
    ).toList();
  }

  /// Handles coverage data processing and aggregation.
  void _handleCoverageData(TestConfiguration config) {
    final workingDir = _determineWorkingDirectory(config);
    final isDeleteRootFirst = config.feature != null;

    printMessage('📊 Processing coverage data...');

    _combineLcovToRoot(
      workingDirectory: workingDir,
      isDeleteRootCoverageFirst: isDeleteRootFirst,
    );

    printMessage('✓ Coverage data processed successfully');
  }

  /// Determines the working directory for coverage processing.
  String _determineWorkingDirectory(TestConfiguration config) {
    if (config.page != null || config.feature != null) {
      if (config.feature == null) {
        throw Exception('Feature name is required for coverage processing');
      }
      return join(current, 'features', config.feature);
    }
    return current;
  }

  /// Removes existing bundle test files from the specified directory.
  ///
  /// **Parameters:**
  /// - [directory]: Directory to clean bundle test files from
  void _cleanExistingBundleTests(String directory) {
    final bundleFiles = find(
      'bundle_test.dart',
      workingDirectory: directory,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (final file in bundleFiles) {
      delete(file);
    }
  }

  /// Creates a bundle test file for a page directory.
  ///
  /// Aggregates all individual test files within the page directory
  /// into a single bundle test file for efficient execution.
  ///
  /// **Parameters:**
  /// - [pageDirectory]: Directory containing page test files
  void _createPageBundle(String pageDirectory) {
    final testFiles = find(
      '*_test.dart',
      workingDirectory: pageDirectory,
      recursive: true,
      types: [Find.file],
    ).toList().map((file) => file.replaceAll('$pageDirectory/', '')).toList();

    final imports = <String>[];
    final mainCalls = <String>[];

    for (int i = 0; i < testFiles.length; i++) {
      imports.add("import '${testFiles[i]}' as test$i;");
      mainCalls.add("test$i.main();");
    }

    final bundleContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';
${imports.join('\n')}

/// Generated bundle test file for page tests.
/// This file aggregates all individual test files for efficient execution.
Future<void> main() async {
  test('generated helper test', () {
    expect(1, 1);
  });
  ${mainCalls.join('\n  ')}
}
''';

    join(pageDirectory, 'bundle_test.dart').write(bundleContent);
  }

  /// Creates a bundle test file for a feature directory.
  ///
  /// Aggregates all page bundle test files within the feature
  /// into a single feature-level bundle test file.
  ///
  /// **Parameters:**
  /// - [featureDirectory]: Feature test directory
  void _createFeatureBundle(String featureDirectory) {
    final bundleFiles = find(
      'bundle_test.dart',
      workingDirectory: featureDirectory,
      recursive: true,
      types: [Find.file],
    )
        .toList()
        .map((file) => file.replaceAll('$featureDirectory/', '').replaceAll(
            '$current/${featureDirectory.replaceAll('./', '')}/', ''))
        .toList();

    // Remove the main bundle file from the list
    bundleFiles.remove('bundle_test.dart');

    final imports = <String>[];
    final mainCalls = <String>[];

    for (int i = 0; i < bundleFiles.length; i++) {
      imports.add("import '${bundleFiles[i]}' as test$i;");
      mainCalls.add("test$i.main();");
    }

    final bundleContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';
${imports.join('\n')}

/// Generated bundle test file for feature tests.
/// This file aggregates all page bundle tests within the feature.
Future<void> main() async {
  test('generated helper test', () {
    expect(1, 1);
  });
  ${mainCalls.join('\n  ')}
}
''';

    join(featureDirectory, 'bundle_test.dart').write(bundleContent);
  }

  /// Combines LCOV coverage files from multiple modules into a single root file.
  ///
  /// This method aggregates coverage data from all modules and creates a
  /// unified coverage report at the project root level.
  ///
  /// **Parameters:**
  /// - [workingDirectory]: Directory to search for coverage files
  /// - [isDeleteRootCoverageFirst]: Whether to clear existing root coverage
  void _combineLcovToRoot({
    required String workingDirectory,
    bool isDeleteRootCoverageFirst = false,
  }) {
    final rootCoveragePath = join(current, 'coverage', 'merge_lcov.info');

    // Initialize or clear root coverage file
    if (!exists(rootCoveragePath)) {
      touch(rootCoveragePath, create: true);
    } else if (isDeleteRootCoverageFirst) {
      delete(rootCoveragePath);
      touch(rootCoveragePath, create: true);
    }

    // Find all LCOV files in the working directory
    final lcovFiles = find(
      'lcov.info',
      recursive: true,
      types: [Find.file],
      workingDirectory: workingDirectory,
    ).toList();

    // Process each LCOV file
    for (final lcovPath in lcovFiles) {
      _processLcovFile(lcovPath, rootCoveragePath);
    }
  }

  /// Processes a single LCOV file and appends it to the root coverage file.
  ///
  /// **Parameters:**
  /// - [lcovPath]: Path to the LCOV file to process
  /// - [rootCoveragePath]: Path to the root coverage file
  void _processLcovFile(String lcovPath, String rootCoveragePath) {
    final lcovDir = dirname(lcovPath);
    final mergedFileName = 'merge_${basename(lcovPath)}';
    final mergedFilePath = join(lcovDir, mergedFileName);

    // Create a copy of the LCOV file
    copy(lcovPath, mergedFilePath, overwrite: true);

    // Calculate relative path for source file paths
    final relativePath = mergedFilePath
        .replaceAll('$current/', '')
        .replaceAll(RegExp(r'(\/)?coverage\/merge_lcov.info(\/)?'), '')
        .replaceAll(RegExp(r'(\/)?coverage\/lcov.info(\/)?'), '');

    // Update source file paths in the LCOV file
    replace(mergedFilePath, RegExp(r'SF:lib\/'), 'SF:$relativePath/lib/');

    // Append to root coverage file
    rootCoveragePath.append(readFile(mergedFilePath));
  }

  /// Validates that required test dependencies are available.
  ///
  /// This method checks for the presence of essential test packages
  /// and provides clear error messages if dependencies are missing.
  ///
  /// **Throws:**
  /// - [TestDependencyError] if required dependencies are missing
  Future<void> _validateTestDependencies() async {
    final pubspecPath = join(current, 'pubspec.yaml');

    if (!exists(pubspecPath)) {
      throw TestDependencyError(
        'pubspec.yaml not found in project root.',
        [
          'Ensure you are running the command from the Flutter project root',
          'Verify the project structure is correct',
        ],
      );
    }

    try {
      final pubspecContent = YamlHelper.loadFileYaml(pubspecPath);
      final devDependencies =
          pubspecContent['dev_dependencies'] as Map<dynamic, dynamic>?;

      if (devDependencies == null) {
        throw TestDependencyError(
          'No dev_dependencies section found in pubspec.yaml.',
          [
            'Add dev_dependencies section to pubspec.yaml',
            'Run "flutter pub add --dev flutter_test"',
            'Run "flutter pub get" to install dependencies',
          ],
        );
      }

      // Check for flutter_test dependency
      final hasFlutterTest = devDependencies.containsKey('flutter_test') ||
          devDependencies.values.any((dep) =>
              dep is Map && dep.containsKey('sdk') && dep['sdk'] == 'flutter');

      if (!hasFlutterTest) {
        throw TestDependencyError(
          'flutter_test dependency not found in dev_dependencies.',
          [
            'Add flutter_test to dev_dependencies in pubspec.yaml:',
            '  dev_dependencies:',
            '    flutter_test:',
            '      sdk: flutter',
            'Run "flutter pub get" to install dependencies',
          ],
        );
      }

      // Check for dev_dependency_manager if it's expected
      final hasDevDependencyManager =
          devDependencies.containsKey('dev_dependency_manager');

      if (!hasDevDependencyManager) {
        printMessage(
            '⚠️  Warning: dev_dependency_manager not found. Bundle tests will use direct flutter_test imports.');
      }
    } catch (e) {
      if (e is TestDependencyError) {
        rethrow;
      }

      throw TestDependencyError(
        'Failed to validate test dependencies: $e',
        [
          'Verify pubspec.yaml format is correct',
          'Check for YAML syntax errors',
          'Ensure file permissions allow reading',
        ],
      );
    }
  }
}

/// Configuration class for test execution parameters.
class TestConfiguration {
  const TestConfiguration({
    this.apps,
    this.feature,
    this.page,
    required this.isCoverage,
    this.reporter,
    this.fileReporter,
  });

  final String? apps;
  final String? feature;
  final String? page;
  final bool isCoverage;
  final String? reporter;
  final String? fileReporter;
}

/// Data class for test directory paths.
class TestPaths {
  const TestPaths({
    required this.appsPath,
    required this.featurePath,
    required this.pagePath,
  });

  final String appsPath;
  final String featurePath;
  final String pagePath;
}

/// Exception thrown when test dependencies are missing or invalid.
class TestDependencyError implements Exception {
  const TestDependencyError(this.message, this.resolutionSteps);

  final String message;
  final List<String> resolutionSteps;

  @override
  String toString() {
    final steps = resolutionSteps.map((step) => '  • $step').join('\n');
    return '''
$message

Resolution steps:
$steps
''';
  }
}
