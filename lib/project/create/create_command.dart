import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Creates a new Flutter application using the Morpheme Flutter Starter Kit.
///
/// The CreateCommand clones the Morpheme Flutter Starter Kit repository
/// and initializes a new Flutter project with the specified name and
/// configuration. It supports automatic refactoring to rename the project
/// and setting custom application IDs.
///
/// ## Usage
///
/// Basic project creation:
/// ```bash
/// morpheme create my_app
/// ```
///
/// Create with specific tag version:
/// ```bash
/// morpheme create my_app --tag v1.0.0
/// ```
///
/// Create with automatic refactoring:
/// ```bash
/// morpheme create my_app --refactor
/// ```
///
/// Create with custom application ID:
/// ```bash
/// morpheme create my_app --application-id com.example.myapp
/// ```
///
/// ## Options
///
/// - `--tag, -t`: Clone specific tag version (default: master branch)
/// - `--refactor`: Automatically rename 'morpheme' to app name
/// - `--include-library`: Include library dependencies during refactor
/// - `--application-id`: Set custom application ID (default: design.morpheme)
///
/// ## Project Structure
///
/// Creates a modular Flutter project with:
/// - Core packages for shared functionality
/// - Feature-based architecture
/// - Pre-configured build system
/// - Integrated testing setup
///
/// ## Dependencies
///
/// - Requires Git for repository cloning
/// - Requires internet connection for template download
/// - Uses morpheme init and config commands
///
/// ## Exceptions
///
/// Throws [ProcessException] if Git is not available or clone fails.
/// Throws [FileSystemException] if target directory already exists.
/// Throws [ArgumentError] if app name is empty or invalid.
class CreateCommand extends Command {
  /// Creates a new instance of CreateCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--tag, -t`: Specific tag version to clone
  /// - `--refactor`: Flag for automatic project renaming
  /// - `--include-library`: Flag to include library dependencies
  /// - `--application-id`: Custom application identifier
  CreateCommand() {
    argParser.addOption(
      'tag',
      abbr: 't',
      help:
          'Clone specific tag version of Morpheme Flutter Starter Kit (default: master)',
    );
    argParser.addFlag(
      'refactor',
      help: 'Automatically refactor and rename morpheme references to app name',
      defaultsTo: false,
    );
    argParser.addFlag(
      'include-library',
      help: 'Include library dependencies during refactoring process',
      defaultsTo: false,
    );
    argParser.addOption(
      'application-id',
      help: 'Set custom application ID for the project',
      defaultsTo: 'design.morpheme',
    );
  }

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create a new Flutter application with Morpheme Flutter Starter Kit';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      final appName = _validateAndGetAppName();
      if (appName == null) return;

      final config = _prepareConfiguration(appName);
      await _executeProjectCreation(config);
      _reportSuccess(config['workingDirectory']);
    } catch (e) {
      StatusHelper.failed('Project creation failed: ${e.toString()}',
          suggestion:
              'Ensure Git is installed and you have internet connectivity',
          examples: ['git --version', 'morpheme doctor']);
    }
  }

  /// Validates and extracts the app name from command arguments.
  ///
  /// Returns the app name if valid, null if validation fails.
  /// Displays specific error messages for invalid app names.
  String? _validateAndGetAppName() {
    final rest = argResults?.rest ?? [];

    if (rest.isEmpty) {
      StatusHelper.failed('App name is required',
          suggestion: 'Provide an app name as the first argument',
          examples: ['morpheme create my_awesome_app']);
      return null;
    }

    final appName = rest.first;

    // Validate app name format
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appName)) {
      StatusHelper.failed('Invalid app name format: $appName',
          suggestion:
              'App name must use snake_case format with lowercase letters, numbers, and underscores only',
          examples: ['my_awesome_app', 'todo_app', 'weather_tracker']);
      return null;
    }

    final workingDirectory = join(current, appName);

    if (exists(workingDirectory)) {
      StatusHelper.failed('Directory "$appName" already exists',
          suggestion:
              'Choose a different app name or remove the existing directory',
          examples: ['morpheme create ${appName}_v2', 'rm -rf $appName']);
      return null;
    }

    return appName;
  }

  /// Prepares the project creation configuration from arguments.
  ///
  /// Returns a map containing all configuration options for
  /// the project creation process.
  ///
  /// Parameters:
  /// - [appName]: Validated application name
  Map<String, dynamic> _prepareConfiguration(String appName) {
    final refactor = argResults?['refactor'] ?? false;
    final includeLibrary = argResults?['include-library'] ?? false;
    final tag = argResults?['tag'];
    final applicationId = argResults?['application-id'];

    return {
      'appName': appName,
      'workingDirectory': join(current, appName),
      'refactor': refactor,
      'includeLibrary': includeLibrary,
      'tag': tag,
      'applicationId': applicationId,
    };
  }

  /// Executes the complete project creation process.
  ///
  /// Performs Git clone, project initialization, refactoring (if requested),
  /// and final configuration setup.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing creation settings
  Future<void> _executeProjectCreation(Map<String, dynamic> config) async {
    await _cloneRepository(config);
    await _initializeProject(config);
    await _setupProjectStructure(config);
    await _configureProject(config);
  }

  /// Clones the Morpheme Flutter Starter Kit repository.
  ///
  /// Downloads the template repository from GitHub with optional
  /// tag specification for version control.
  ///
  /// Parameters:
  /// - [config]: Configuration containing app name and tag options
  Future<void> _cloneRepository(Map<String, dynamic> config) async {
    final appName = config['appName'];
    final tag = config['tag'];
    final workingDirectory = config['workingDirectory'];

    final tagOption = tag != null ? '-b $tag --depth 1' : '';

    await 'git clone https://github.com/morphemedesign/morpheme-flutter.git $appName $tagOption'
        .run;

    // Remove .git directory to disconnect from template repository
    deleteDir(join(workingDirectory, '.git'));
  }

  /// Initializes the project with morpheme init command.
  ///
  /// Sets up the basic project structure and configuration
  /// with the specified app name and application ID.
  ///
  /// Parameters:
  /// - [config]: Configuration containing initialization options
  Future<void> _initializeProject(Map<String, dynamic> config) async {
    final appName = config['appName'];
    final applicationId = config['applicationId'];
    final workingDirectory = config['workingDirectory'];

    final applicationIdOption =
        applicationId != null ? '--application-id "$applicationId"' : '';

    await 'morpheme init --app-name "$appName" $applicationIdOption'
        .start(workingDirectory: workingDirectory);
  }

  /// Sets up the project structure through refactoring or dependency management.
  ///
  /// Either performs automatic refactoring to rename project references
  /// or runs dependency resolution based on configuration.
  ///
  /// Parameters:
  /// - [config]: Configuration containing refactoring options
  Future<void> _setupProjectStructure(Map<String, dynamic> config) async {
    final appName = config['appName'];
    final refactor = config['refactor'];
    final includeLibrary = config['includeLibrary'];
    final workingDirectory = config['workingDirectory'];

    if (refactor) {
      final includeLibraryOption = includeLibrary ? '--include-library' : '';
      await 'morpheme refactor --old-name="morpheme" --new-name="$appName" $includeLibraryOption'
          .start(workingDirectory: workingDirectory);
    } else {
      await 'morpheme get'.start(workingDirectory: workingDirectory);
    }
  }

  /// Configures the project with morpheme config command.
  ///
  /// Finalizes the project setup by running configuration
  /// commands to ensure everything is properly initialized.
  ///
  /// Parameters:
  /// - [config]: Configuration containing project options
  Future<void> _configureProject(Map<String, dynamic> config) async {
    final workingDirectory = config['workingDirectory'];

    await 'morpheme config'.start(workingDirectory: workingDirectory);
  }

  /// Reports successful project creation.
  ///
  /// Displays the path to the newly created project directory.
  ///
  /// Parameters:
  /// - [projectPath]: Path to the created project directory
  void _reportSuccess(String projectPath) {
    StatusHelper.generated(projectPath);
  }
}
