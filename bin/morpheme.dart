/// Morpheme CLI - Main Entry Point
///
/// A powerful productivity tool for Flutter development that provides modular
/// project creation, API generation, folder structuring, and comprehensive
/// build management capabilities.
///
/// ## Features
///
/// ### Code Generation
/// - **Feature Generation**: Complete feature modules with bloc patterns
/// - **Page Generation**: UI pages with routing and state management
/// - **API Integration**: Automated API client generation
/// - **Asset Management**: Automated asset class generation
/// - **Localization**: Multi-language support with automated l10n
/// - **JSON to Dart**: Convert JSON schemas to Dart classes
/// - **Color Management**: Generate color constants from design tokens
///
/// ### Project Management
/// - **Project Creation**: Bootstrap new Flutter projects with best practices
/// - **Dependency Management**: Automated package management and updates
/// - **Code Quality**: Formatting, linting, and analysis tools
/// - **Testing**: Comprehensive testing framework integration
/// - **Refactoring**: Safe code transformation utilities
///
/// ### Build & Deployment
/// - **Multi-platform Builds**: Android APK/AAB, iOS IPA, Web builds
/// - **CI/CD Integration**: Automated build pipelines
/// - **Shorebird Integration**: Over-the-air update capabilities
/// - **Environment Management**: Multi-flavor build configurations
///
/// ### Developer Tools
/// - **Project Initialization**: Quick project setup and configuration
/// - **Health Checks**: Environment validation and diagnostics
/// - **Version Management**: Automated version bumping and changelog generation
/// - **Rename Utilities**: Safe project and package renaming
///
/// ## Usage
///
/// ```bash
/// # Create a new project
/// morpheme create my_app
///
/// # Generate a new feature
/// morpheme feature user_profile
///
/// # Build for production
/// morpheme build apk --release
///
/// # Check environment health
/// morpheme doctor
/// ```
///
/// ## Architecture
///
/// The CLI follows a modular command-based architecture where each major
/// functionality is encapsulated in dedicated command classes. Commands are
/// organized by category and follow consistent patterns for argument parsing,
/// validation, and execution.
///
/// ## Error Handling
///
/// The CLI provides comprehensive error handling with contextual messages
/// and suggestions for resolution. All commands support detailed logging
/// and progress reporting for complex operations.
library;

import 'dart:io';

import 'package:morpheme_cli/build_app/build_command.dart';
import 'package:morpheme_cli/build_app/prebuild_command.dart';
import 'package:morpheme_cli/core/src/log.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/generate.dart';
import 'package:morpheme_cli/project/project.dart';
import 'package:morpheme_cli/shorebird/shorebird_command.dart';
import 'package:morpheme_cli/tools/tools.dart';

/// Application metadata and configuration constants.
class _AppConfig {
  static const String version = '4.0.1';
  static const String name = 'morpheme';
  static const String description =
      'Morpheme CLI Boost productivity with modular project creation, '
      'API generation & folder structuring tools. Simplify Flutter dev! '
      '#Flutter #CLI';
}

/// Main entry point for the Morpheme CLI application.
///
/// Initializes the command runner, registers all available commands,
/// handles global arguments, and manages the application lifecycle
/// including error handling and cleanup.
///
/// Parameters:
/// - [arguments]: Command-line arguments passed to the application
void main(List<String> arguments) async {
  // Initialize logging system
  clearLog();

  try {
    // Create and configure the command runner
    final runner = _createCommandRunner();

    // Register all available commands
    _registerCommands(runner);

    // Configure global arguments
    _configureGlobalArguments(runner);

    // Handle version flag before command execution
    if (await _handleVersionFlag(runner, arguments)) {
      return;
    }

    // Execute the requested command with progress indication
    await _executeCommand(runner, arguments);
  } catch (error) {
    _handleGlobalError(error);
  }
}

/// Creates and configures the main command runner.
///
/// Returns a [CommandRunner] instance configured with application metadata.
CommandRunner<void> _createCommandRunner() {
  return CommandRunner<void>(
    _AppConfig.name,
    _AppConfig.description,
  );
}

/// Registers all available commands with the command runner.
///
/// Commands are organized by category for better maintainability:
/// - Code Generation Commands
/// - Project Management Commands
/// - Build & Deployment Commands
/// - Developer Tools Commands
///
/// Parameters:
/// - [runner]: The command runner to register commands with
void _registerCommands(CommandRunner<void> runner) {
  // Register all available commands
  _registerGenerationCommands(runner);
  _registerProjectCommands(runner);
  _registerBuildCommands(runner);
  _registerToolsCommands(runner);
}

/// Registers code generation and scaffolding commands.
///
/// These commands handle automated code generation for features,
/// pages, APIs, assets, and other development artifacts.
///
/// Parameters:
/// - [runner]: The command runner to register commands with
void _registerGenerationCommands(CommandRunner<void> runner) {
  // Core generation commands
  runner.addCommand(FeatureCommand());
  runner.addCommand(PageCommand());
  runner.addCommand(ApiCommand());
  runner.addCommand(CoreCommand());
  runner.addCommand(ConfigCommand());

  // Asset and resource generation
  runner.addCommand(AssetCommand());
  runner.addCommand(Color2DartCommand());
  runner.addCommand(Json2DartCommand());
  runner.addCommand(Json2DartLegacyCommand());
  runner.addCommand(EndpointCommand());

  // Localization and internationalization
  runner.addCommand(LocalizationCommand());
  runner.addCommand(Local2DartCommand());

  // Integration and configuration
  runner.addCommand(FirebaseCommand());
  runner.addCommand(AppsCommand());

  // Template and testing utilities
  runner.addCommand(TemplateTestCommand());

  // Removal and cleanup commands
  runner.addCommand(RemovePageCommand());
  runner.addCommand(RemoveFeatureCommand());
  runner.addCommand(RemoveAppsCommand());
  runner.addCommand(RemoveTestCommand());
}

/// Registers project management and development commands.
///
/// These commands handle project lifecycle operations including
/// creation, dependency management, testing, and code quality.
///
/// Parameters:
/// - [runner]: The command runner to register commands with
void _registerProjectCommands(CommandRunner<void> runner) {
  // Project lifecycle commands
  runner.addCommand(CreateCommand());
  runner.addCommand(GetCommand());
  runner.addCommand(RunCommand());
  runner.addCommand(CleanCommand());

  // Code quality and maintenance
  runner.addCommand(FormatCommand());
  runner.addCommand(AnalyzeCommand());
  runner.addCommand(RefactorCommand());
  runner.addCommand(FixCommand());

  // Testing and validation
  runner.addCommand(TestCommand());
  runner.addCommand(CoverageCommand());
  runner.addCommand(CucumberCommand());

  // Dependency and resource management
  runner.addCommand(UpgradeDependencyCommand());
  runner.addCommand(UnusedL10nCommand());
  runner.addCommand(DownloadCommand());

  // Asset and branding utilities
  runner.addCommand(IcLauncherCommand());
}

/// Registers build and deployment commands.
///
/// These commands handle multi-platform builds, pre-build configuration,
/// and deployment-related operations.
///
/// Parameters:
/// - [runner]: The command runner to register commands with
void _registerBuildCommands(CommandRunner<void> runner) {
  // Core build system
  runner.addCommand(BuildCommand());
  runner.addCommand(PreBuildCommand());

  // Advanced deployment and updates
  runner.addCommand(ShorebirdCommand());
}

/// Registers developer tools and utilities commands.
///
/// These commands provide development utilities, environment management,
/// and developer experience enhancements.
///
/// Parameters:
/// - [runner]: The command runner to register commands with
void _registerToolsCommands(CommandRunner<void> runner) {
  // Environment and setup
  runner.addCommand(DoctorCommand());
  runner.addCommand(InitCommand());

  // Project utilities
  runner.addCommand(RenameCommand());
  runner.addCommand(UpgradeCommand());
}

/// Configures global command-line arguments.
///
/// Sets up arguments that are available across all commands,
/// such as version reporting and global flags.
///
/// Parameters:
/// - [runner]: The command runner to configure arguments for
void _configureGlobalArguments(CommandRunner<void> runner) {
  runner.argParser.addFlag(
    'version',
    abbr: 'v',
    help: 'Reports the version of this tool.',
    negatable: false,
  );
}

/// Handles the version flag if present in arguments.
///
/// Checks if the version flag was provided and displays version information
/// if requested, then exits the application.
///
/// Parameters:
/// - [runner]: The command runner instance
/// - [arguments]: Command-line arguments to parse
///
/// Returns:
/// - `true` if version was displayed and app should exit
/// - `false` if normal command execution should continue
Future<bool> _handleVersionFlag(
  CommandRunner<void> runner,
  List<String> arguments,
) async {
  try {
    final results = runner.argParser.parse(arguments);
    if (results.wasParsed('version')) {
      printMessage('Morpheme CLI ${_AppConfig.version}');
      exit(0);
    }
    return false;
  } catch (error) {
    // If parsing fails, continue to normal execution
    // The command runner will handle the parsing error appropriately
    return false;
  }
}

/// Executes the requested command with progress indication.
///
/// Starts a loading indicator, executes the command, and ensures
/// proper cleanup regardless of success or failure.
///
/// Parameters:
/// - [runner]: The configured command runner
/// - [arguments]: Command-line arguments to execute
Future<void> _executeCommand(
  CommandRunner<void> runner,
  List<String> arguments,
) async {
  final loading = Loading();

  try {
    loading.start();
    await runner.run(arguments);
  } catch (error) {
    _handleCommandError(error);
    rethrow;
  } finally {
    loading.stop();
  }
}

/// Handles command execution errors with appropriate messaging.
///
/// Provides contextual error messages and suggestions for common
/// error scenarios to improve developer experience.
///
/// Parameters:
/// - [error]: The error that occurred during command execution
void _handleCommandError(dynamic error) {
  if (error is UsageException) {
    // Handle command usage errors with helpful guidance
    printerrMessage(red('Usage Error: ${error.message}'));
    printerrMessage('\nRun "morpheme help" for available commands.');
  } else if (error is ProcessException) {
    // Handle process execution errors
    printerrMessage(red('Process Error: ${error.message}'));
    printerrMessage('\nRun "morpheme doctor" to check your environment.');
  } else {
    // Handle general command errors
    printerrMessage(red('Command failed: ${error.toString()}'));
  }
}

/// Handles global application errors and ensures graceful exit.
///
/// Catches any unhandled errors at the application level and provides
/// appropriate error reporting before terminating the application.
///
/// Parameters:
/// - [error]: The unhandled error that occurred
void _handleGlobalError(dynamic error) {
  Loading().stop();

  printerrMessage(red('Fatal error: ${error.toString()}'));
  printerrMessage('\nIf this error persists, please report it at:');
  printerrMessage(
      'https://github.com/morphemedesign/morpheme-flutter-cli/issues');

  exit(1);
}
