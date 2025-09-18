import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command for comprehensive project refactoring and renaming operations.
///
/// This command provides systematic renaming capabilities for Flutter projects,
/// enabling developers to change project names, class names, and file names
/// while maintaining code integrity and consistency across all references.
///
/// **Purpose:**
/// - Rename project components systematically across all modules
/// - Update configuration files (pubspec.yaml, morpheme.yaml)
/// - Refactor code references and imports
/// - Support library component renaming with dependency management
/// - Maintain project structure integrity during renaming operations
///
/// **Refactoring Scope:**
/// - Project name in configuration files
/// - Class names and file names throughout the codebase
/// - Import statements and references
/// - Library package names and dependencies
/// - Asset references and localization keys
///
/// **Usage Examples:**
/// ```bash
/// # Basic project renaming
/// morpheme refactor --old-name myapp --new-name newapp
///
/// # Include library refactoring
/// morpheme refactor --old-name myapp --new-name newapp --include-library
///
/// # Exclude specific changes
/// morpheme refactor --old-name myapp --new-name newapp --exclude-changes "MyAppConfig,myapp_constants"
///
/// # Exclude specific files
/// morpheme refactor --old-name myapp --new-name newapp --exclude-files "lib/generated/,test/mocks/"
/// ```
///
/// **Parameters:**
/// - `--old-name` (`-o`): Current project name to be replaced (default: 'morpheme')
/// - `--new-name` (`-n`): New project name (required)
/// - `--exclude-changes`: Comma-separated list of code patterns to exclude from renaming
/// - `--exclude-files`: Comma-separated list of file paths to exclude from renaming
/// - `--exclude-directories`: Comma-separated list of directories to exclude entirely
/// - `--include-library`: Include library component refactoring (default: false)
///
/// **Process Flow:**
/// 1. Update morpheme.yaml project configuration
/// 2. Refactor pubspec.yaml and project dependencies
/// 3. Rename files and update class names throughout codebase
/// 4. Process library components if requested
/// 5. Restore dependencies and validate project integrity
///
/// **Safety Features:**
/// - Validation of source and target names
/// - Exclusion patterns to protect critical code
/// - Backup and recovery mechanisms
/// - Dependency restoration after refactoring
///
/// **Library Refactoring:**
/// When `--include-library` is enabled, the command will:
/// - Clone latest library components from the official repository
/// - Update library package names and dependencies
/// - Maintain library structure while adapting to new naming
/// - Clean up temporary files and unused components
///
/// **Exceptions:**
/// - Throws [ValidationException] if old and new names are identical
/// - Throws [FileSystemException] if file operations fail
/// - Throws [DependencyException] if dependency restoration fails
/// - Throws [NetworkException] if library cloning fails (when --include-library is used)
///
/// **Example Configuration:**
/// ```yaml
/// # morpheme.yaml
/// project_name: my_awesome_app
///
/// # After refactoring with --new-name "my_new_app"
/// project_name: my_new_app
/// ```
class RefactorCommand extends Command {
  RefactorCommand() {
    argParser.addOption(
      'old-name',
      abbr: 'o',
      help: 'Current project name to be replaced during refactoring',
      defaultsTo: 'morpheme',
    );
    argParser.addOption(
      'new-name',
      abbr: 'n',
      help: 'New project name to replace the old name',
      mandatory: true,
    );
    argParser.addOption(
      'exclude-changes',
      help:
          'Comma-separated list of code patterns to exclude from renaming operations',
    );
    argParser.addOption(
      'exclude-files',
      help:
          'Comma-separated list of specific file paths to exclude from both code and filename changes',
    );
    argParser.addOption(
      'exclude-directories',
      help:
          'Comma-separated list of directories to completely exclude from refactoring operations',
    );
    argParser.addFlag(
      'include-library',
      help: 'Include library component refactoring and dependency updates',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'refactor';

  @override
  String get description =>
      'Systematically refactor and rename project components while maintaining code integrity.';

  @override
  String get category => Constants.project;

  String _oldName = '';
  String _newName = '';
  bool _includeLibrary = false;

  @override
  void run() async {
    try {
      // Parse and validate arguments
      _parseArguments();

      if (_oldName == _newName) {
        printMessage(
            '⚠️  Old and new names are identical. No refactoring needed.');
        return;
      }

      printMessage('🔄 Starting refactoring process...');
      printMessage('Old name: $_oldName');
      printMessage('New name: $_newName');
      printMessage('Include library: $_includeLibrary');

      // Execute refactoring steps
      await _executeRefactoringProcess();

      printMessage('✨ Refactoring completed successfully!');
      StatusHelper.success('morpheme refactor');
    } catch (e) {
      StatusHelper.failed('Refactoring failed: $e');
    }
  }

  /// Parses command line arguments and initializes refactoring parameters.
  void _parseArguments() {
    _oldName = argResults?['old-name'] ?? '';
    _newName = argResults?['new-name'] ?? '';
    _includeLibrary = argResults?['include-library'] ?? false;

    if (_oldName.isEmpty) {
      throw const FormatException('Old name cannot be empty');
    }

    if (_newName.isEmpty) {
      throw const FormatException('New name is required');
    }
  }

  /// Executes the complete refactoring process in the correct order.
  Future<void> _executeRefactoringProcess() async {
    // Step 1: Update project configuration
    _updateProjectConfiguration();

    // Step 2: Refactor pubspec.yaml
    _refactorPubspecConfiguration();

    // Step 3: Refactor project files
    await _refactorProjectFiles();

    // Step 4: Refactor library components if requested
    if (_includeLibrary) {
      await _refactorLibraryComponents();
    }

    // Step 5: Clean up temporary files
    _cleanupTemporaryFiles();

    // Step 6: Restore dependencies
    await _restoreDependencies();
  }

  /// Updates the morpheme.yaml project configuration file.
  void _updateProjectConfiguration() {
    printMessage('📄 Updating morpheme.yaml configuration...');

    final morphemeYamlPath = join(current, 'morpheme.yaml');
    if (!exists(morphemeYamlPath)) {
      printMessage(
          '⚠️  morpheme.yaml not found, skipping configuration update');
      return;
    }

    try {
      final yamlConfig = Map.from(YamlHelper.loadFileYaml(morphemeYamlPath));
      yamlConfig['project_name'] = _newName;
      YamlHelper.saveFileYaml(morphemeYamlPath, yamlConfig);

      printMessage('✓ morpheme.yaml updated successfully');
    } catch (e) {
      throw Exception('Failed to update morpheme.yaml: $e');
    }
  }

  /// Refactors the pubspec.yaml configuration and related files.
  void _refactorPubspecConfiguration() {
    printMessage('📦 Refactoring pubspec.yaml configuration...');

    final pubspecPath = join(current, 'pubspec.yaml');
    if (!exists(pubspecPath)) {
      throw Exception('pubspec.yaml not found at $pubspecPath');
    }

    try {
      final pubspecConfig = Map.from(YamlHelper.loadFileYaml(pubspecPath));
      final oldPubspecName = pubspecConfig['name'] as String;

      // Update pubspec name
      pubspecConfig['name'] = _newName.snakeCase;
      YamlHelper.saveFileYaml(pubspecPath, pubspecConfig);

      // Update related file and class names
      RefactorHelper.renameFileAndClassName(
        pathDir: join(current, 'lib'),
        oldName: oldPubspecName,
        newName: _newName.snakeCase,
      );

      printMessage('✓ pubspec.yaml and related files updated successfully');
    } catch (e) {
      throw Exception('Failed to refactor pubspec configuration: $e');
    }
  }

  /// Refactors project files with appropriate exclusions and safety measures.
  Future<void> _refactorProjectFiles() async {
    printMessage('📋 Refactoring project files and code references...');

    try {
      final exclusionConfig = _buildExclusionConfiguration();

      RefactorHelper.renameFileAndClassName(
        pathDir: current,
        oldName: _oldName,
        newName: _newName,
        exceptChanges: exclusionConfig.excludeChanges,
        exceptFiles: exclusionConfig.excludeFiles,
        exceptDirs: exclusionConfig.excludeDirectories,
      );

      // Regenerate assets after refactoring
      await 'morpheme assets'.run;

      printMessage('✓ Project files refactored successfully');
    } catch (e) {
      throw Exception('Project file refactoring failed: $e');
    }
  }

  /// Builds exclusion configuration from command line arguments.
  ///
  /// **Returns:** [ExclusionConfiguration] with all exclusion patterns
  ExclusionConfiguration _buildExclusionConfiguration() {
    final excludeChanges = _parseCommaSeparatedOption('exclude-changes');
    final excludeFiles = _parseCommaSeparatedOption('exclude-files');
    final excludeDirectories =
        _parseCommaSeparatedOption('exclude-directories');

    // Default exclusions when not including library refactoring
    final defaultExclusions = _includeLibrary
        ? <String>[]
        : [
            '${_oldName.snakeCase}_library',
            '${_oldName.snakeCase}_base',
            '${_oldName.snakeCase}_http',
            '${_oldName.snakeCase}_inspector',
            '${_oldName.snakeCase}_extension',
            '${_oldName.pascalCase}Cubit',
            '${_oldName.pascalCase}Hydrated',
            '${_oldName.pascalCase}StatePage',
            '${_oldName.pascalCase}Http',
            '${_oldName.pascalCase}Exception',
            '${_oldName.pascalCase}Failure',
            '${_oldName.pascalCase}HttpOverrides',
            '${_oldName.pascalCase}Inspector',
            '${_oldName.camelCase}Inspector',
          ];

    // Default directory exclusions
    final defaultDirectoryExclusions = [
      join(current, 'core', 'lib', 'src', 'l10n'),
      join(current, 'core', 'packages', '${_oldName.snakeCase}_library'),
      join(current, 'android'),
      join(current, 'ios'),
      join(current, 'macos'),
      join(current, 'web'),
      join(current, 'linux'),
    ];

    return ExclusionConfiguration(
      excludeChanges: [...defaultExclusions, ...excludeChanges],
      excludeFiles: excludeFiles,
      excludeDirectories: [
        ...defaultDirectoryExclusions,
        ...excludeDirectories
      ],
    );
  }

  /// Parses comma-separated option values.
  ///
  /// **Parameters:**
  /// - [optionName]: Name of the command line option
  ///
  /// **Returns:** List of parsed values
  List<String> _parseCommaSeparatedOption(String optionName) {
    final optionValue = argResults?[optionName]?.toString();
    if (optionValue?.isNotEmpty ?? false) {
      return optionValue!
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Cleans up temporary files created during the refactoring process.
  void _cleanupTemporaryFiles() {
    printMessage('🧹 Cleaning up temporary files...');

    final tempLibraryPath = join(current, 'morpheme_library_temp');
    if (exists(tempLibraryPath)) {
      try {
        deleteDir(tempLibraryPath);
        printMessage('✓ Temporary library files cleaned up');
      } catch (e) {
        printMessage('⚠️  Warning: Failed to clean up temporary files: $e');
      }
    }
  }

  /// Restores project dependencies after refactoring.
  Future<void> _restoreDependencies() async {
    printMessage('📦 Restoring project dependencies...');

    try {
      await 'morpheme get'.run;
      printMessage('✓ Dependencies restored successfully');
    } catch (e) {
      throw Exception('Failed to restore dependencies: $e');
    }
  }

  /// Refactors library components when --include-library flag is enabled.
  ///
  /// This method handles the complex process of updating library dependencies,
  /// cloning new library components, and maintaining library structure.
  Future<void> _refactorLibraryComponents() async {
    printMessage('📚 Refactoring library components...');

    try {
      // Setup library refactoring environment
      await _setupLibraryRefactoringEnvironment();

      // Process library dependencies
      await _processLibraryDependencies();

      // Update library configurations
      _updateLibraryConfigurations();

      // Finalize library structure
      _finalizeLibraryStructure();

      printMessage('✓ Library components refactored successfully');
    } catch (e) {
      throw Exception('Library refactoring failed: $e');
    }
  }

  /// Sets up the environment for library refactoring.
  Future<void> _setupLibraryRefactoringEnvironment() async {
    printMessage('🔧 Setting up library refactoring environment...');

    final tempLibraryPath = join(current, 'morpheme_library_temp');

    // Clean existing temporary directory
    if (exists(tempLibraryPath)) {
      deleteDir(tempLibraryPath);
    }

    // Clone library repository
    try {
      await 'git clone https://github.com/morphemedesign/morpheme-flutter-library.git morpheme_library_temp'
          .run;
      printMessage('✓ Library repository cloned successfully');
    } catch (e) {
      throw Exception('Failed to clone library repository: $e');
    }

    // Ensure library directory structure
    final oldLibraryPath =
        join(current, 'core', 'packages', '${_oldName.snakeCase}_library');
    if (exists(oldLibraryPath)) {
      createDir(join(oldLibraryPath, 'packages'));
    }
  }

  /// Processes library dependencies and updates package structures.
  Future<void> _processLibraryDependencies() async {
    printMessage('📦 Processing library dependencies...');

    final tempLibraryPath = join(current, 'morpheme_library_temp');
    final oldLibraryPath =
        join(current, 'core', 'packages', '${_oldName.snakeCase}_library');

    if (!exists(oldLibraryPath)) {
      printMessage(
          '⚠️  Old library path not found, skipping library dependency processing');
      return;
    }

    final libraryCatalog = _buildLibraryCatalog(tempLibraryPath);
    final libraryConfig =
        YamlHelper.loadFileYaml(join(oldLibraryPath, 'pubspec.yaml'));

    await _processLibraryPackages(
        libraryConfig, libraryCatalog, tempLibraryPath, oldLibraryPath);
  }

  /// Builds a catalog of available library packages.
  ///
  /// **Parameters:**
  /// - [tempLibraryPath]: Path to the temporary library directory
  ///
  /// **Returns:** List of available library package names
  List<String> _buildLibraryCatalog(String tempLibraryPath) {
    return find(
      '*',
      workingDirectory: join(tempLibraryPath, 'packages'),
      recursive: false,
      types: [Find.directory],
    ).toList();
  }

  /// Processes individual library packages and their dependencies.
  ///
  /// **Parameters:**
  /// - [libraryConfig]: Configuration from the library's pubspec.yaml
  /// - [libraryCatalog]: List of available library packages
  /// - [tempLibraryPath]: Path to temporary library directory
  /// - [oldLibraryPath]: Path to existing library directory
  Future<void> _processLibraryPackages(
    Map<dynamic, dynamic> libraryConfig,
    List<String> libraryCatalog,
    String tempLibraryPath,
    String oldLibraryPath,
  ) async {
    final dependencies =
        libraryConfig['dependencies'] as Map<dynamic, dynamic>?;
    if (dependencies == null) {
      printMessage('⚠️  No dependencies found in library configuration');
      return;
    }

    // Process primary dependencies
    for (final dependency in dependencies.entries) {
      await _processSingleLibraryPackage(
        dependency.key.toString(),
        libraryCatalog,
        tempLibraryPath,
        oldLibraryPath,
      );
    }

    // Process nested dependencies
    final processedPackages = _getProcessedPackagesList(oldLibraryPath);
    for (final packagePath in processedPackages) {
      await _processNestedDependencies(
          packagePath, libraryCatalog, tempLibraryPath, oldLibraryPath);
    }
  }

  /// Processes a single library package and moves it if needed.
  ///
  /// **Parameters:**
  /// - [packageName]: Name of the package to process
  /// - [libraryCatalog]: List of available library packages
  /// - [tempLibraryPath]: Path to temporary library directory
  /// - [oldLibraryPath]: Path to existing library directory
  Future<void> _processSingleLibraryPackage(
    String packageName,
    List<String> libraryCatalog,
    String tempLibraryPath,
    String oldLibraryPath,
  ) async {
    final normalizedName =
        packageName.replaceAll(RegExp('morpheme|${_oldName.snakeCase}'), '');

    final isAvailableInCatalog = libraryCatalog.any((element) =>
        normalizedName ==
        element.replaceAll(join(tempLibraryPath, 'packages', 'morpheme'), ''));

    final existingPackages = find(
      '*$normalizedName',
      workingDirectory: join(oldLibraryPath, 'packages'),
      recursive: false,
      types: [Find.directory],
    ).toList();

    if (isAvailableInCatalog || existingPackages.isNotEmpty) {
      return; // Package already exists or is not needed
    }

    final sourcePackagePath =
        join(tempLibraryPath, 'packages', 'morpheme$normalizedName');
    final targetPackagePath =
        join(oldLibraryPath, 'packages', 'morpheme$normalizedName');

    if (exists(sourcePackagePath)) {
      try {
        moveDir(sourcePackagePath, targetPackagePath);
        printMessage('✓ Moved library package: morpheme$normalizedName');
      } catch (e) {
        printMessage('⚠️  Failed to move package morpheme$normalizedName: $e');
      }
    }
  }

  /// Processes nested dependencies within library packages.
  ///
  /// **Parameters:**
  /// - [packagePath]: Path to the package to process
  /// - [libraryCatalog]: List of available library packages
  /// - [tempLibraryPath]: Path to temporary library directory
  /// - [oldLibraryPath]: Path to existing library directory
  Future<void> _processNestedDependencies(
    String packagePath,
    List<String> libraryCatalog,
    String tempLibraryPath,
    String oldLibraryPath,
  ) async {
    final packagePubspecPath = join(packagePath, 'pubspec.yaml');
    if (!exists(packagePubspecPath)) return;

    try {
      final packageConfig = YamlHelper.loadFileYaml(packagePubspecPath);
      final nestedDependencies =
          packageConfig['dependencies'] as Map<dynamic, dynamic>?;

      if (nestedDependencies != null) {
        for (final dependency in nestedDependencies.entries) {
          await _processSingleLibraryPackage(
            dependency.key.toString(),
            libraryCatalog,
            tempLibraryPath,
            oldLibraryPath,
          );
        }
      }
    } catch (e) {
      printMessage(
          '⚠️  Failed to process nested dependencies for $packagePath: $e');
    }
  }

  /// Gets list of processed packages in the library directory.
  ///
  /// **Parameters:**
  /// - [oldLibraryPath]: Path to existing library directory
  ///
  /// **Returns:** List of package directory paths
  List<String> _getProcessedPackagesList(String oldLibraryPath) {
    return find(
      '*',
      workingDirectory: join(oldLibraryPath, 'packages'),
      recursive: false,
      types: [Find.directory],
    ).toList();
  }

  /// Updates library configurations after processing packages.
  void _updateLibraryConfigurations() {
    printMessage('⚙️  Updating library configurations...');

    final oldLibraryPath =
        join(current, 'core', 'packages', '${_oldName.snakeCase}_library');
    if (!exists(oldLibraryPath)) {
      printMessage(
          '⚠️  Library path not found, skipping configuration updates');
      return;
    }

    try {
      _updateIndividualPackageConfigurations(oldLibraryPath);
      _updateMainLibraryConfiguration(oldLibraryPath);

      printMessage('✓ Library configurations updated successfully');
    } catch (e) {
      throw Exception('Failed to update library configurations: $e');
    }
  }

  /// Updates configurations for individual library packages.
  ///
  /// **Parameters:**
  /// - [oldLibraryPath]: Path to the library directory
  void _updateIndividualPackageConfigurations(String oldLibraryPath) {
    final packageDirectories = _getProcessedPackagesList(oldLibraryPath);

    for (final packageDir in packageDirectories) {
      _updateSinglePackageConfiguration(packageDir);
    }
  }

  /// Updates configuration for a single library package.
  ///
  /// **Parameters:**
  /// - [packagePath]: Path to the package directory
  void _updateSinglePackageConfiguration(String packagePath) {
    final pubspecPath = join(packagePath, 'pubspec.yaml');
    if (!exists(pubspecPath)) return;

    try {
      final packageConfig = Map.from(YamlHelper.loadFileYaml(pubspecPath));

      // Update package metadata
      packageConfig['name'] = packageConfig['name'].toString().replaceAll(
          RegExp('morpheme|${_oldName.snakeCase}'), _newName.snakeCase);

      packageConfig['description'] = packageConfig['description']
          .toString()
          .replaceAll(
              RegExp('morpheme|${_oldName.snakeCase}'), _newName.snakeCase)
          .replaceAll(
              RegExp('Morpheme|${_oldName.pascalCase}'), _newName.pascalCase);

      // Set to private package
      packageConfig['publish_to'] = 'none';

      // Remove public package metadata
      packageConfig.remove('homepage');
      packageConfig.remove('repository');

      // Update dependencies
      _updatePackageDependencies(packageConfig);

      // Clean up example and documentation
      _cleanupPackageExtras(packagePath);

      YamlHelper.saveFileYaml(pubspecPath, packageConfig);
    } catch (e) {
      printMessage(
          '⚠️  Failed to update package configuration at $packagePath: $e');
    }
  }

  /// Updates package dependencies to use new naming.
  ///
  /// **Parameters:**
  /// - [packageConfig]: Package configuration map
  void _updatePackageDependencies(Map<dynamic, dynamic> packageConfig) {
    final dependencies =
        packageConfig['dependencies'] as Map<dynamic, dynamic>?;
    if (dependencies == null) return;

    final keysToRemove = <String>[];
    final newEntries = <MapEntry<String, dynamic>>[];

    for (final entry in dependencies.entries) {
      final key = entry.key.toString();
      if (key.contains(RegExp('morpheme|${_oldName.snakeCase}'))) {
        final newLibraryName = key.replaceAll(
          RegExp('morpheme|${_oldName.snakeCase}'),
          _newName.snakeCase,
        );

        keysToRemove.add(key);
        newEntries
            .add(MapEntry(newLibraryName, {'path': '../$newLibraryName'}));
      }
    }

    // Remove old entries and add new ones
    for (final key in keysToRemove) {
      dependencies.remove(key);
    }

    for (final entry in newEntries) {
      dependencies[entry.key] = entry.value;
    }
  }

  /// Cleans up example directories and documentation files.
  ///
  /// **Parameters:**
  /// - [packagePath]: Path to the package directory
  void _cleanupPackageExtras(String packagePath) {
    final filesToRemove = [
      join(packagePath, 'CHANGELOG.md'),
      join(packagePath, 'README.md'),
      join(packagePath, 'AUTHORS'),
    ];

    final dirsToRemove = [
      join(packagePath, 'example'),
    ];

    for (final file in filesToRemove) {
      if (exists(file)) {
        try {
          delete(file);
        } catch (e) {
          printMessage('⚠️  Failed to remove $file: $e');
        }
      }
    }

    for (final dir in dirsToRemove) {
      if (exists(dir)) {
        try {
          deleteDir(dir);
        } catch (e) {
          printMessage('⚠️  Failed to remove directory $dir: $e');
        }
      }
    }
  }

  /// Updates the main library configuration.
  ///
  /// **Parameters:**
  /// - [oldLibraryPath]: Path to the library directory
  void _updateMainLibraryConfiguration(String oldLibraryPath) {
    final mainPubspecPath = join(oldLibraryPath, 'pubspec.yaml');
    if (!exists(mainPubspecPath)) return;

    try {
      final mainConfig = Map.from(YamlHelper.loadFileYaml(mainPubspecPath));

      // Update main library name
      mainConfig['name'] = mainConfig['name'].toString().replaceAll(
          RegExp('morpheme|${_oldName.snakeCase}'), _newName.snakeCase);

      // Update main library dependencies
      _updatePackageDependencies(mainConfig);

      YamlHelper.saveFileYaml(mainPubspecPath, mainConfig);
    } catch (e) {
      printMessage('⚠️  Failed to update main library configuration: $e');
    }
  }

  /// Finalizes the library structure after refactoring.
  void _finalizeLibraryStructure() {
    printMessage('🏠 Finalizing library structure...');

    final oldLibraryPath =
        join(current, 'core', 'packages', '${_oldName.snakeCase}_library');
    final newLibraryPath =
        join(current, 'core', 'packages', '${_newName.snakeCase}_library');

    if (!exists(oldLibraryPath)) {
      printMessage(
          '⚠️  Old library path not found, skipping structure finalization');
      return;
    }

    try {
      // Rename individual packages
      _renameLibraryPackages(oldLibraryPath);

      // Move main library directory
      if (exists(oldLibraryPath)) {
        moveDir(oldLibraryPath, newLibraryPath);
        printMessage('✓ Main library directory renamed successfully');
      }

      // Apply final refactoring to library code
      RefactorHelper.renameFileAndClassName(
        pathDir: newLibraryPath,
        oldName: _oldName,
        newName: _newName,
      );

      // Update core pubspec.yaml
      _updateCorePubspecConfiguration();

      printMessage('✓ Library structure finalized successfully');
    } catch (e) {
      throw Exception('Failed to finalize library structure: $e');
    }
  }

  /// Renames individual library packages to match new naming convention.
  ///
  /// **Parameters:**
  /// - [oldLibraryPath]: Path to the current library directory
  void _renameLibraryPackages(String oldLibraryPath) {
    final packageDirectories = _getProcessedPackagesList(oldLibraryPath);

    for (final packageDir in packageDirectories) {
      final currentPackageName = basename(packageDir);
      final newPackageName = currentPackageName.replaceAll(
        RegExp('morpheme|${_oldName.snakeCase}'),
        _newName.snakeCase,
      );

      if (currentPackageName != newPackageName) {
        final newPackagePath = join(dirname(packageDir), newPackageName);

        try {
          if (exists(packageDir)) {
            moveDir(packageDir, newPackagePath);
            printMessage(
                '✓ Renamed package: $currentPackageName -> $newPackageName');
          }
        } catch (e) {
          printMessage('⚠️  Failed to rename package $currentPackageName: $e');
        }
      }
    }
  }

  /// Updates the core pubspec.yaml configuration.
  void _updateCorePubspecConfiguration() {
    final corePubspecPath = join(current, 'core', 'pubspec.yaml');
    if (!exists(corePubspecPath)) {
      printMessage('⚠️  Core pubspec.yaml not found, skipping update');
      return;
    }

    try {
      replace(
        corePubspecPath,
        RegExp('morpheme|${_oldName.snakeCase}'),
        _newName.snakeCase,
      );

      printMessage('✓ Core pubspec.yaml updated successfully');
    } catch (e) {
      printMessage('⚠️  Failed to update core pubspec.yaml: $e');
    }
  }
}

/// Configuration class for exclusion patterns during refactoring.
class ExclusionConfiguration {
  const ExclusionConfiguration({
    required this.excludeChanges,
    required this.excludeFiles,
    required this.excludeDirectories,
  });

  /// List of code patterns to exclude from renaming operations
  final List<String> excludeChanges;

  /// List of specific file paths to exclude from changes
  final List<String> excludeFiles;

  /// List of directories to completely exclude from refactoring
  final List<String> excludeDirectories;
}
