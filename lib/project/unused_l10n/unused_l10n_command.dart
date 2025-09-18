import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

const lineNumber = 'line-number';

/// Result of processing a chunk of files in an isolate.
class ProcessingResult {
  final Set<String> usedTerms;
  final int filesProcessed;
  final int chunkId;
  final Duration processingTime;

  ProcessingResult({
    required this.usedTerms,
    required this.filesProcessed,
    required this.chunkId,
    required this.processingTime,
  });
}

/// Configuration for isolate-based file processing.
class IsolateProcessingConfig {
  final List<String> filePaths;
  final Set<String> translationTerms;
  final Map<String, RegExp> regexPatterns;
  final int chunkId;
  final SendPort responsePort;

  IsolateProcessingConfig({
    required this.filePaths,
    required this.translationTerms,
    required this.regexPatterns,
    required this.chunkId,
    required this.responsePort,
  });
}

/// Information about an ARB file and its terms.
class ArbFileInfo {
  final String filePath;
  final Map<String, dynamic> content;
  final Set<String> terms;

  ArbFileInfo({
    required this.filePath,
    required this.content,
    required this.terms,
  });
}

/// Entry point for the isolate that processes files.
///
/// This static method runs in a separate isolate and processes
/// files independently of the main thread.
///
/// Parameters:
/// - [config]: Configuration containing files and patterns to process
void isolateEntryPoint(IsolateProcessingConfig config) async {
  final startTime = DateTime.now();
  final usedTerms = <String>{};
  final termsToCheck = config.translationTerms.toSet();

  int filesProcessed = 0;

  for (final filePath in config.filePaths) {
    if (termsToCheck.isEmpty) {
      // Early termination if all terms are found
      break;
    }

    try {
      // Use streaming for large files to reduce memory usage
      final file = File(filePath);
      final stat = await file.stat();

      String content;
      if (stat.size > 1024 * 1024) {
        // Files > 1MB
        // Stream large files
        content = await readFileStreaming(file);
      } else {
        content = await file.readAsString();
      }

      // Check for term usage with pre-compiled patterns
      final foundTerms = <String>{};
      for (final term in termsToCheck) {
        final pattern = config.regexPatterns[term]!;
        if (pattern.hasMatch(content)) {
          foundTerms.add(term);
        }
      }

      // Add found terms and remove from check list
      usedTerms.addAll(foundTerms);
      termsToCheck.removeAll(foundTerms);

      filesProcessed++;
    } catch (e) {
      // Continue processing other files if one fails
      filesProcessed++;
    }
  }

  final endTime = DateTime.now();
  final result = ProcessingResult(
    usedTerms: usedTerms,
    filesProcessed: filesProcessed,
    chunkId: config.chunkId,
    processingTime: endTime.difference(startTime),
  );

  config.responsePort.send(result);
}

/// Reads large files using streaming to reduce memory usage.
///
/// For files larger than 1MB, this method reads the content
/// in chunks to avoid loading the entire file into memory.
///
/// Parameters:
/// - [file]: The file to read
///
/// Returns: File content as string
Future<String> readFileStreaming(File file) async {
  final buffer = StringBuffer();
  final stream = file.openRead();

  await for (final chunk in stream.transform(utf8.decoder)) {
    buffer.write(chunk);
  }

  return buffer.toString();
}

/// Analyzes unused localization keys across all packages in the project.
///
/// The UnusedL10nCommand scans all ARB (Application Resource Bundle) files to
/// extract localization keys, then searches through all Dart files in parallel
/// to identify which keys are not being used in the codebase.
/// It respects concurrency settings from morpheme.yaml for optimal performance.
///
/// ## Usage
///
/// Basic unused localization analysis (with presentation folder filtering):
/// ```bash
/// morpheme unused-l10n
/// ```
///
/// Search all Dart files without filtering:
/// ```bash
/// morpheme unused-l10n --no-filter-presentation
/// ```
///
/// Automatically remove unused keys from ARB files:
/// ```bash
/// morpheme unused-l10n --auto-remove
/// ```
///
/// Auto-remove with backup files:
/// ```bash
/// morpheme unused-l10n --auto-remove --backup
/// ```
///
/// Auto-remove without confirmation prompt:
/// ```bash
/// morpheme unused-l10n --auto-remove --confirm
/// ```
///
/// With custom configuration:
/// ```bash
/// morpheme unused-l10n --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Configuration
///
/// The command reads concurrency settings from morpheme.yaml:
/// ```yaml
/// concurrent: 4  # Number of parallel file processing tasks
/// ```
///
/// ## Auto-Remove Feature
///
/// When --auto-remove is enabled, the command will:
/// - Show a confirmation prompt (unless --confirm is used)
/// - Optionally create backup files with .backup extension (if --backup is used)
/// - Remove unused keys from all ARB files
/// - Preserve all metadata entries (@-prefixed keys)
/// - Report the number of files modified and keys removed
///
/// ## Safety Considerations
///
/// - By default, no backup files are created to avoid cluttering the workspace
/// - Use `--backup` flag when you want to preserve original ARB files
/// - Backup files use `.arb.backup` extension and can be restored if needed
///
/// Backup files can be restored using:
/// ```bash
/// find . -name "*.arb.backup" -exec sh -c 'mv "$1" "${1%.backup}"' _ {} \;
/// ```
///
/// ## Filtering Behavior
///
/// By default, the command filters feature packages to only search in presentation
/// folders (lib/presentation/**), while searching all files in non-feature packages.
/// This optimization focuses on UI-related code where localization is typically used.
///
/// Feature packages are identified by having lib/presentation, lib/data, or lib/domain
/// directories. Use --no-filter-presentation to disable this behavior.
///
/// ## Output
///
/// - Displays progress of file analysis
/// - Reports unused localization keys with counts
/// - Shows detailed analysis results
/// - If --auto-remove is used, shows removal progress and results
///
/// ## Performance
///
/// - Uses parallel processing for scanning Dart files
/// - Searches all .dart files in the project (not just lib/**)
/// - Optimized regex patterns for localization usage detection
/// - True isolate-based parallelism for handling 15k+ files
///
/// ## Dependencies
///
/// - Uses ModularHelper for package discovery
/// - Requires valid ARB files for localization keys
/// - Supports both modular and traditional project structures
///
/// ## Exceptions
///
/// Throws [FileSystemException] if ARB files cannot be read or modified.
/// Throws [FormatException] if ARB files contain invalid JSON.
/// Throws [ProcessException] if file processing fails.
class UnusedL10nCommand extends Command {
  /// Creates a new instance of UnusedL10nCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--morpheme-yaml`: Path to the morpheme.yaml configuration file
  /// - `--filter-presentation`: Filter .dart files to only presentation folders in features (default: true)
  UnusedL10nCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'filter-presentation',
      help:
          'Filter .dart files to only presentation folders in features (default: true)',
      defaultsTo: true,
    );
    argParser.addFlag(
      'auto-remove',
      help: 'Automatically remove unused localization keys from ARB files',
      defaultsTo: false,
    );
    argParser.addFlag(
      'backup',
      abbr: 'b',
      help: 'Create backup files (.arb.backup) before removing unused keys',
      defaultsTo: false,
    );
    argParser.addFlag(
      'confirm',
      help: 'Skip confirmation prompt when using --auto-remove',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'unused-l10n';

  @override
  String get description =>
      'Detect and report unused localization keys in Dart files (optimized for large codebases). '
      'Use --no-filter-presentation to search all files. '
      'Use --auto-remove to automatically delete unused keys from ARB files. '
      'Use --backup to create backup files before removal.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      if (!_validateInputs()) return;

      final config = _prepareConfiguration();
      await _executeAnalysis(config);
      _reportSuccess();
    } catch (e) {
      StatusHelper.failed(
          'Unused localization analysis failed: ${e.toString()}',
          suggestion:
              'Check your morpheme.yaml configuration and ensure ARB files are valid',
          examples: ['morpheme doctor', 'flutter doctor']);
    }
  }

  /// Validates input parameters and configuration.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final autoRemove = argResults?['auto-remove'] as bool? ?? false;
    final createBackup = argResults?['backup'] as bool? ?? false;

    try {
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    } catch (e) {
      StatusHelper.failed(
          'Invalid morpheme.yaml configuration: ${e.toString()}. '
          'Ensure morpheme.yaml exists and has valid syntax. '
          'Examples: morpheme init, morpheme config');
      return false;
    }

    // Validate backup flag usage
    if (createBackup && !autoRemove) {
      StatusHelper.warning(
          'The --backup flag only applies when --auto-remove is enabled. '
          'Use --auto-remove --backup to enable both features. '
          'Example: morpheme unused-l10n --auto-remove --backup');
    }

    return true;
  }

  // Core optimization methods for testing
  int calculateOptimalConcurrency(int fileCount, int requestedConcurrency) =>
      fileCount > 15000
          ? max(requestedConcurrency, Platform.numberOfProcessors * 2)
          : fileCount > 10000
              ? max(requestedConcurrency, Platform.numberOfProcessors)
              : fileCount > 5000
                  ? max(requestedConcurrency,
                      (Platform.numberOfProcessors * 0.75).ceil())
                  : requestedConcurrency;

  List<List<String>> createOptimizedChunks(List<String> files, int chunkCount) {
    if (files.isEmpty) return [];
    final chunks = <List<String>>[];
    final targetChunkSize = files.length > 10000
        ? (files.length / (chunkCount * 2)).ceil()
        : (files.length / chunkCount).ceil();
    for (int i = 0; i < files.length; i += targetChunkSize) {
      final end = (i + targetChunkSize < files.length)
          ? i + targetChunkSize
          : files.length;
      chunks.add(files.sublist(i, end));
    }
    return chunks;
  }

  Map<String, RegExp> compileRegexPatterns(Set<String> translationTerms) {
    final patterns = <String, RegExp>{};
    for (final term in translationTerms) {
      patterns[term] = RegExp(
        r'S\s*\.\s*of\s*\(\s*context\s*\)\s*\.\s*' +
            term +
            r'|context\s*\.\s*s\s*\.\s*' +
            term +
            r'|S\s*\.\s*current\s*\.\s*' +
            term +
            r'|s\s*\.\s*' +
            term +
            r"|'[^']*\$\{[^}]*" +
            term +
            r"[^}]*\}[^']*'" +
            r'|"[^"]*\$\{[^}]*' +
            term +
            r'[^}]*\}[^"]*"',
        multiLine: true,
        caseSensitive: true,
      );
    }
    return patterns;
  }

  Set<String> combineResults(
      Set<String> translationTerms, List<ProcessingResult> results) {
    final allUsedTerms = <String>{};
    for (var result in results) {
      allUsedTerms.addAll(result.usedTerms);
    }
    return translationTerms.difference(allUsedTerms);
  }

  /// Prepares configuration for the analysis execution.
  ///
  /// Returns a map containing analysis configuration parameters.
  Map<String, dynamic> _prepareConfiguration() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    final concurrent = morphemeYaml['concurrent'] ?? 4;
    final filterPresentation =
        argResults?['filter-presentation'] as bool? ?? true;
    final autoRemove = argResults?['auto-remove'] as bool? ?? false;
    final skipConfirm = argResults?['confirm'] as bool? ?? false;
    final createBackup = argResults?['backup'] as bool? ?? false;

    return {
      'morpheme_yaml': argMorphemeYaml,
      'concurrent': concurrent,
      'filter_presentation': filterPresentation,
      'auto_remove': autoRemove,
      'skip_confirm': skipConfirm,
      'create_backup': createBackup,
    };
  }

  /// Executes the unused localization analysis.
  ///
  /// This method performs the complete analysis workflow:
  /// 1. Discovers all packages and ARB files using morpheme.yaml configuration
  /// 2. Extracts translation terms from ARB files
  /// 3. Scans all Dart files in parallel to find term usage
  /// 4. Reports unused localization keys
  /// 5. Optionally removes unused keys from ARB files if --auto-remove is enabled
  ///
  /// Parameters:
  /// - [config]: Configuration map containing analysis parameters
  Future<void> _executeAnalysis(Map<String, dynamic> config) async {
    final startTime = DateTime.now();

    printMessage('🔍 Starting unused localization analysis...');

    // Step 1: Discover packages and ARB files using morpheme.yaml configuration
    printMessage('📦 Discovering packages and ARB files...');
    final allTranslationTerms = <String>{};
    final allArbFiles =
        <ArbFileInfo>[]; // Track ARB files for potential removal

    final argMorphemeYaml = config['morpheme_yaml'] as String;

    // Get all pubspec.yaml files to find packages
    final pubspecFiles = find('pubspec.yaml', workingDirectory: '.')
        .toList()
        .where((element) {
          final yaml = YamlHelper.loadFileYaml(element);
          final hasResolution = yaml.containsKey('resolution');
          return !hasResolution;
        })
        .map((e) => e.replaceAll('${separator}pubspec.yaml', ''))
        .toList();

    printMessage('📁 Found ${pubspecFiles.length} packages to scan');

    for (final packagePath in pubspecFiles) {
      printMessage('🔍 Scanning package: $packagePath');

      // Try to find ARB files in multiple locations
      final packageArbFiles =
          await _findArbFilesInPackageWithInfo(packagePath, argMorphemeYaml);
      allArbFiles.addAll(packageArbFiles);

      final arbTermsFromPackage =
          packageArbFiles.expand((arbFile) => arbFile.terms).toSet();
      allTranslationTerms.addAll(arbTermsFromPackage);
    }

    if (allTranslationTerms.isEmpty) {
      printMessage('\n📦 No translation terms found in any ARB files.');
      printMessage(
          '🔍 Searched in ${pubspecFiles.length} packages: ${pubspecFiles.join(', ')}');
      printMessage('\n📝 Troubleshooting tips:');
      printMessage('  1. Ensure ARB files exist in your project');
      printMessage('  2. Check morpheme.yaml localization configuration');
      printMessage('  3. Verify ARB files are in expected locations:');
      printMessage('     - {package}/lib/l10n/*.arb');
      printMessage('     - {package}/assets/l10n/*.arb');
      printMessage('     - {package}/assets/assets/l10n/*.arb');
      printMessage('  4. Ensure ARB files contain valid JSON');
      StatusHelper.warning(
          'No ARB files found or no translation terms extracted');
      return;
    }

    printMessage('📝 Found ${allTranslationTerms.length} translation terms');

    // Step 2: Find all Dart files in the project
    final filterPresentation = config['filter_presentation'] as bool;
    printMessage('🔎 Scanning for Dart files...');
    if (filterPresentation) {
      printMessage(
          '📁 Filtering enabled: Only presentation folders in feature packages will be searched');
    } else {
      printMessage('📁 No filtering: All Dart files will be searched');
    }
    final allDartFiles = <String>{};

    for (final packagePath in pubspecFiles) {
      final dartFiles = await _findDartFiles(packagePath,
          filterPresentation: config['filter_presentation'] as bool);
      final isFeature = filterPresentation && _isFeaturePackage(packagePath);
      if (isFeature) {
        printMessage(
            '  🎯 Feature package $packagePath: ${dartFiles.length} presentation files found');
      } else {
        printMessage(
            '  📦 Package $packagePath: ${dartFiles.length} files found');
      }
      allDartFiles.addAll(dartFiles);
    }

    final sortedFiles = allDartFiles.toList()..sort();
    printMessage('📁 Found ${sortedFiles.length} Dart files to analyze');

    // Step 3: Execute parallel analysis
    final concurrent = config['concurrent'] as int;
    final optimalConcurrency =
        calculateOptimalConcurrency(sortedFiles.length, concurrent);

    printMessage('⚡ Using $optimalConcurrency parallel workers for analysis');

    final chunks = createOptimizedChunks(sortedFiles, optimalConcurrency);
    final regexPatterns = compileRegexPatterns(allTranslationTerms);

    printMessage('🚀 Processing ${chunks.length} file chunks...');

    final results = await _processFilesInParallel(
        chunks, allTranslationTerms, regexPatterns);

    // Step 4: Combine results and report
    final unusedTerms = combineResults(allTranslationTerms, results);

    final endTime = DateTime.now();
    final totalTime = endTime.difference(startTime);

    printMessage('\n📊 Analysis Results:');
    printMessage('⏱️ Total analysis time: ${totalTime.inMilliseconds}ms');
    printMessage('📝 Translation terms: ${allTranslationTerms.length}');
    printMessage(
        '✅ Used terms: ${allTranslationTerms.length - unusedTerms.length}');
    printMessage('❌ Unused terms: ${unusedTerms.length}');

    if (unusedTerms.isNotEmpty) {
      printMessage('\n🗑️ Unused localization keys:');
      for (final term in unusedTerms.toList()..sort()) {
        printMessage('  • $term');
      }

      // Step 5: Auto-remove unused keys if requested
      final autoRemove = config['auto_remove'] as bool;
      if (autoRemove) {
        await _removeUnusedKeysFromArbFiles(unusedTerms, allArbFiles, config);
      } else {
        printMessage(
            '\n💡 Tip: Use --auto-remove to automatically remove these unused keys from ARB files');
      }
    } else {
      printMessage('\n🎉 All localization keys are being used!');
    }
  }

  /// Finds ARB files and extracts translation terms from a package with file info.
  ///
  /// This method searches for ARB files in multiple locations and returns detailed
  /// information about each ARB file including content for potential modification.
  ///
  /// Parameters:
  /// - [packagePath]: Path to the package to search
  /// - [morphemeYamlPath]: Path to morpheme.yaml configuration
  ///
  /// Returns: List of ArbFileInfo objects containing file details
  Future<List<ArbFileInfo>> _findArbFilesInPackageWithInfo(
      String packagePath, String morphemeYamlPath) async {
    final arbFiles = <ArbFileInfo>[];
    final searchedDirs = <String>{};

    // 1. Try to get ARB directory from morpheme.yaml configuration
    try {
      final packageMorphemeYaml = join(packagePath, 'morpheme.yaml');
      if (exists(packageMorphemeYaml)) {
        final localizationHelper = LocalizationHelper(packageMorphemeYaml);
        final configuredArbDir = join(packagePath, localizationHelper.arbDir);

        if (await Directory(configuredArbDir).exists()) {
          final arbFilesFromDir =
              await _extractArbFileInfoFromDirectory(configuredArbDir);
          arbFiles.addAll(arbFilesFromDir);
          searchedDirs.add(configuredArbDir);
          final totalTerms =
              arbFilesFromDir.fold(0, (sum, arb) => sum + arb.terms.length);
          printMessage(
              '  ✓ Found $totalTerms terms in configured ARB dir: ${localizationHelper.arbDir}');
        }
      }
    } catch (e) {
      // Continue with standard locations if config parsing fails
      printMessage(
          '  ⚠️ Warning: Failed to parse morpheme.yaml in $packagePath: $e');
    }

    // 2. Standard Flutter localization directories
    final standardDirs = [
      '$packagePath/lib/l10n',
      '$packagePath/assets/l10n',
      '$packagePath/assets/assets/l10n',
      '$packagePath/l10n',
    ];

    for (final dirPath in standardDirs) {
      if (searchedDirs.contains(dirPath)) continue; // Skip if already searched

      final arbDir = Directory(dirPath);
      if (await arbDir.exists()) {
        final arbFilesFromDir = await _extractArbFileInfoFromDirectory(dirPath);
        if (arbFilesFromDir.isNotEmpty) {
          arbFiles.addAll(arbFilesFromDir);
          searchedDirs.add(dirPath);
          final totalTerms =
              arbFilesFromDir.fold(0, (sum, arb) => sum + arb.terms.length);
          printMessage(
              '  ✓ Found $totalTerms terms in: ${dirPath.replaceAll(packagePath, '')}');
        }
      }
    }

    return arbFiles;
  }

  /// Extracts ARB file information from all ARB files in a directory.
  ///
  /// Parameters:
  /// - [directoryPath]: Path to directory containing ARB files
  ///
  /// Returns: List of ArbFileInfo objects with file details
  Future<List<ArbFileInfo>> _extractArbFileInfoFromDirectory(
      String directoryPath) async {
    final arbFiles = <ArbFileInfo>[];
    final arbDir = Directory(directoryPath);

    if (!await arbDir.exists()) return arbFiles;

    final arbFileEntities = arbDir
        .listSync(recursive: true)
        .where((f) => f is File && f.path.endsWith('.arb'))
        .cast<File>();

    for (final arbFile in arbFileEntities) {
      try {
        final content = await arbFile.readAsString();
        final Map<String, dynamic> arbData = json.decode(content);

        // Extract keys that don't start with '@' (metadata keys)
        final fileTerms =
            arbData.keys.where((key) => !key.startsWith('@')).toSet();

        arbFiles.add(ArbFileInfo(
          filePath: arbFile.path,
          content: arbData,
          terms: fileTerms,
        ));

        printMessage(
            '    - ${arbFile.path.split('/').last}: ${fileTerms.length} terms');
      } catch (e) {
        printMessage('    ⚠️ Warning: Failed to parse ${arbFile.path}: $e');
      }
    }

    return arbFiles;
  }

  /// Determines if a package is a feature package based on its structure.
  ///
  /// A feature package typically has the following characteristics:
  /// - Contains lib/data, lib/domain, and lib/presentation folders
  /// - Is not the main app or core package
  ///
  /// Parameters:
  /// - [packagePath]: Path to the package to check
  ///
  /// Returns: true if the package is a feature package
  bool _isFeaturePackage(String packagePath) {
    // Check if this is likely a feature package by looking for standard folders
    final presentationDir = Directory(join(packagePath, 'lib', 'presentation'));
    final dataDir = Directory(join(packagePath, 'lib', 'data'));
    final domainDir = Directory(join(packagePath, 'lib', 'domain'));

    // A feature package should have presentation folder at minimum
    return presentationDir.existsSync() &&
        (dataDir.existsSync() || domainDir.existsSync());
  }

  /// Determines if a Dart file is in a presentation folder.
  ///
  /// Parameters:
  /// - [filePath]: Path to the Dart file
  ///
  /// Returns: true if the file is in a presentation folder
  bool _isInPresentationFolder(String filePath) {
    // Check if the file path contains '/lib/presentation/'
    return filePath
            .contains('${separator}lib${separator}presentation$separator') ||
        filePath.contains('/lib/presentation/');
  }

  ///
  /// Parameters:
  /// - [packagePath]: Root path to search for Dart files
  ///
  /// Returns: List of absolute paths to Dart files
  Future<List<String>> _findDartFiles(String packagePath,
      {bool filterPresentation = false}) async {
    final dartFiles = <String>[];
    final packageDir = Directory(packagePath);

    if (await packageDir.exists()) {
      final isFeature = filterPresentation && _isFeaturePackage(packagePath);

      await for (final entity in packageDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // If filtering is enabled and this is a feature package,
          // only include files in presentation folders
          if (isFeature) {
            if (_isInPresentationFolder(entity.path)) {
              dartFiles.add(entity.path);
            }
          } else {
            // For non-feature packages or when filtering is disabled,
            // include all Dart files
            dartFiles.add(entity.path);
          }
        }
      }
    }

    return dartFiles;
  }

  /// Processes files in parallel using isolates.
  ///
  /// Parameters:
  /// - [chunks]: List of file chunks to process
  /// - [translationTerms]: Set of translation terms to search for
  /// - [regexPatterns]: Pre-compiled regex patterns for term matching
  ///
  /// Returns: List of processing results from all isolates
  Future<List<ProcessingResult>> _processFilesInParallel(
      List<List<String>> chunks,
      Set<String> translationTerms,
      Map<String, RegExp> regexPatterns) async {
    final completer = Completer<List<ProcessingResult>>();
    final results = <ProcessingResult>[];
    final receivePort = ReceivePort();
    int completedChunks = 0;

    receivePort.listen((data) {
      if (data is ProcessingResult) {
        results.add(data);
        completedChunks++;

        printMessage('✅ Chunk ${data.chunkId + 1}/${chunks.length} completed '
            '(${data.filesProcessed} files, ${data.processingTime.inMilliseconds}ms)');

        if (completedChunks == chunks.length) {
          receivePort.close();
          completer.complete(results);
        }
      }
    });

    // Start all isolates
    for (int i = 0; i < chunks.length; i++) {
      final config = IsolateProcessingConfig(
        filePaths: chunks[i],
        translationTerms: translationTerms,
        regexPatterns: regexPatterns,
        chunkId: i,
        responsePort: receivePort.sendPort,
      );

      await Isolate.spawn(isolateEntryPoint, config);
    }

    return completer.future;
  }

  /// Reports successful completion of the analysis.
  ///
  /// Displays summary information and completion status.
  void _reportSuccess() {
    StatusHelper.success(
        'Unused localization analysis completed successfully!');
  }

  /// Reports the results of the removal operation.
  ///
  /// Parameters:
  /// - [filesModified]: Number of ARB files that were modified
  /// - [keysRemoved]: Total number of keys removed across all files
  /// - [backupCreated]: Whether backup files were created
  void _reportRemovalResults(
      int filesModified, int keysRemoved, bool backupCreated) {
    printMessage('\n🎉 Auto-removal completed!');
    printMessage('  • Files modified: $filesModified');
    printMessage('  • Keys removed: $keysRemoved');

    if (backupCreated && filesModified > 0) {
      printMessage('  • Backup files created with .backup extension');
      printMessage('\n📝 Tip: You can restore backups if needed:');
      printMessage(
          '    find . -name "*.arb.backup" -exec sh -c \'mv "\$1" "\${1%.backup}"\' _ {} \\;');
    } else if (!backupCreated && filesModified > 0) {
      printMessage('  • No backup files created (use --backup flag to enable)');
      printMessage(
          '\n⚠️  Warning: Changes cannot be easily reverted without backups');
    }
  }

  /// Removes unused localization keys from ARB files.
  ///
  /// This method handles the complete auto-removal workflow:
  /// 1. Shows confirmation prompt (unless --confirm is used)
  /// 2. Creates backup files
  /// 3. Removes unused keys from all ARB files
  /// 4. Reports results
  ///
  /// Parameters:
  /// - [unusedTerms]: Set of unused localization keys to remove
  /// - [arbFiles]: List of ARB files containing the keys
  /// - [config]: Configuration map containing removal settings
  Future<void> _removeUnusedKeysFromArbFiles(Set<String> unusedTerms,
      List<ArbFileInfo> arbFiles, Map<String, dynamic> config) async {
    final skipConfirm = config['skip_confirm'] as bool;
    final createBackup = config['create_backup'] as bool;

    // Step 1: Show confirmation prompt
    if (!skipConfirm) {
      printMessage('\n📝 Auto-removal will:');
      if (createBackup) {
        printMessage('  • Create backup files (.arb.backup)');
      } else {
        printMessage('  • Remove keys WITHOUT creating backup files');
      }
      printMessage(
          '  • Remove ${unusedTerms.length} unused keys from ${arbFiles.length} ARB files');
      printMessage('  • Preserve all metadata entries (@-prefixed keys)');

      stdout.write('\n🔄 Do you want to proceed? (y/N): ');
      final input = stdin.readLineSync()?.toLowerCase().trim() ?? 'n';

      if (input != 'y' && input != 'yes') {
        printMessage('❌ Auto-removal cancelled by user.');
        return;
      }
    }

    printMessage('\n🛠️ Starting auto-removal process...');

    // Step 2: Process each ARB file
    int totalFilesModified = 0;
    int totalKeysRemoved = 0;

    for (final arbFile in arbFiles) {
      final fileUnusedTerms = unusedTerms.intersection(arbFile.terms);

      if (fileUnusedTerms.isEmpty) {
        // No unused terms in this file, skip
        continue;
      }

      try {
        // Conditional backup creation
        if (createBackup) {
          await _createBackupFile(arbFile.filePath);
        }

        // Remove unused keys
        final keysRemoved =
            await _removeKeysFromArbFile(arbFile, fileUnusedTerms);

        if (keysRemoved > 0) {
          totalFilesModified++;
          totalKeysRemoved += keysRemoved;
          printMessage(
              '  ✓ ${arbFile.filePath.split('/').last}: removed $keysRemoved keys');
        }
      } catch (e) {
        printMessage('  ❌ Error processing ${arbFile.filePath}: $e');
      }
    }

    // Step 3: Report results
    _reportRemovalResults(totalFilesModified, totalKeysRemoved, createBackup);
  }

  /// Creates a backup file for an ARB file.
  ///
  /// Parameters:
  /// - [filePath]: Path to the ARB file to backup
  Future<void> _createBackupFile(String filePath) async {
    final file = File(filePath);
    final backupPath = '$filePath.backup';

    if (await file.exists()) {
      await file.copy(backupPath);
    }
  }

  /// Removes unused keys from a single ARB file.
  ///
  /// This method preserves the original file structure and formatting
  /// while removing only the specified unused keys. Metadata entries
  /// (keys starting with '@') are always preserved.
  ///
  /// Parameters:
  /// - [arbFile]: ARB file information containing content and path
  /// - [unusedTerms]: Set of unused keys to remove from this file
  ///
  /// Returns: Number of keys actually removed
  Future<int> _removeKeysFromArbFile(
      ArbFileInfo arbFile, Set<String> unusedTerms) async {
    final originalContent = Map<String, dynamic>.from(arbFile.content);
    int keysRemoved = 0;

    // Remove unused keys (but preserve metadata entries)
    for (final unusedTerm in unusedTerms) {
      if (originalContent.containsKey(unusedTerm) &&
          !unusedTerm.startsWith('@')) {
        originalContent.remove(unusedTerm);
        // Also remove related metadata if it exists
        final metadataKey = '@$unusedTerm';
        if (originalContent.containsKey(metadataKey)) {
          originalContent.remove(metadataKey);
        }
        keysRemoved++;
      }
    }

    if (keysRemoved > 0) {
      // Write the modified content back to the file
      final modifiedJson =
          const JsonEncoder.withIndent('  ').convert(originalContent);
      await File(arbFile.filePath).writeAsString('$modifiedJson\n');
    }

    return keysRemoved;
  }
}
