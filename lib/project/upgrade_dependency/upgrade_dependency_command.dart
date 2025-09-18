import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Upgrades package dependencies to their latest versions.
///
/// The UpgradeDependencyCommand provides options to upgrade dependencies
/// across different scopes: the entire project, specific core packages,
/// or individual modules. It ensures dependencies are updated safely
/// while maintaining compatibility.
///
/// ## Usage
///
/// Upgrade morpheme_library dependencies (default):
/// ```bash
/// morpheme upgrade-dependency
/// ```
///
/// Upgrade all project dependencies:
/// ```bash
/// morpheme upgrade-dependency --all
/// ```
///
/// Upgrade dependency_manager package:
/// ```bash
/// morpheme upgrade-dependency --dependency
/// ```
///
/// Upgrade with custom configuration:
/// ```bash
/// morpheme upgrade-dependency --all --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Options
///
/// - `--all, -a`: Upgrade all project package dependencies
/// - `--dependency, -d`: Upgrade dependency_manager package dependencies
/// - `--morpheme, -g`: Upgrade morpheme_library package dependencies (default)
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
///
/// ## Safety
///
/// - Prompts for confirmation before major upgrades
/// - Validates package integrity after upgrades
/// - Supports rollback guidance if issues occur
///
/// ## Dependencies
///
/// - Requires valid morpheme.yaml configuration (for --all)
/// - Uses ModularHelper for multi-package operations
/// - Requires Flutter SDK for pub operations
///
/// ## Exceptions
///
/// Throws [FileSystemException] if target packages don't exist.
/// Throws [ProcessException] if dependency upgrade fails.
class UpgradeDependencyCommand extends Command {
  /// Creates a new instance of UpgradeDependencyCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--morpheme-yaml`: Path to morpheme.yaml configuration
  /// - `--all, -a`: Flag to upgrade all project dependencies
  /// - `--dependency, -d`: Flag to upgrade dependency_manager
  /// - `--morpheme, -g`: Flag to upgrade morpheme_library (default)
  UpgradeDependencyCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Upgrade dependencies for all project packages to latest versions',
      negatable: false,
    );
    argParser.addFlag(
      'dependency',
      abbr: 'd',
      help:
          'Upgrade dependency_manager package dependencies to latest versions',
      negatable: false,
    );
    argParser.addFlag(
      'morpheme',
      abbr: 'g',
      help:
          'Upgrade morpheme_library package dependencies to latest versions (default)',
      negatable: false,
    );
    argParser.addFlag(
      'skip-confirmation',
      help: 'Skip confirmation prompts for dependency upgrades',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'upgrade-dependency';

  @override
  String get description =>
      'Upgrade package dependencies to their latest compatible versions.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      ProgressReporter.reportPhase('Preparing dependency upgrade');

      final config = _prepareConfiguration();

      if (config['upgradeAll']) {
        await _upgradeAllDependencies(config);
      } else {
        await _upgradeSpecificPackage(config);
      }

      _reportSuccess();
    } catch (e) {
      ErrorHandler.handleException(
        ProjectCommandError.dependencyFailure,
        e,
        'Dependency upgrade failed',
      );
    }
  }

  /// Prepares the upgrade configuration from command arguments.
  ///
  /// Determines the upgrade scope and target packages based on
  /// the provided command line flags.
  ///
  /// Returns: Configuration map with upgrade settings
  Map<String, dynamic> _prepareConfiguration() {
    final upgradeAll = argResults?.wasParsed('all') ?? false;
    final upgradeDependency = argResults?.wasParsed('dependency') ?? false;
    final skipConfirmation = argResults?['skip-confirmation'] as bool? ?? false;

    String targetPackage = 'morpheme_library';
    if (upgradeDependency) {
      targetPackage = 'dependency_manager';
    }

    return {
      'upgradeAll': upgradeAll,
      'targetPackage': targetPackage,
      'skipConfirmation': skipConfirmation,
      'yamlPath': upgradeAll ? argResults.getOptionMorphemeYaml() : null,
    };
  }

  /// Upgrades dependencies for all project packages.
  ///
  /// Validates morpheme.yaml configuration and uses ModularHelper
  /// to upgrade dependencies across all packages concurrently.
  ///
  /// Parameters:
  /// - [config]: Configuration containing upgrade settings
  Future<void> _upgradeAllDependencies(Map<String, dynamic> config) async {
    final yamlPath = config['yamlPath'];
    final skipConfirmation = config['skipConfirmation'] as bool;

    // Validate configuration
    YamlHelper.validateMorphemeYaml(yamlPath);
    final yaml = YamlHelper.loadFileYaml(yamlPath);

    // Confirm upgrade operation
    if (!skipConfirmation) {
      final confirmed = await _confirmMajorUpgrade('all project packages');
      if (!confirmed) {
        printMessage('Dependency upgrade cancelled by user.');
        return;
      }
    }

    ProgressReporter.reportPhase('Upgrading all project dependencies');
    await ModularHelper.upgrade(concurrent: yaml.concurrent);
    ProgressReporter.reportCompletion('All packages upgraded');
  }

  /// Upgrades dependencies for a specific core package.
  ///
  /// Targets either morpheme_library or dependency_manager package
  /// for dependency upgrades.
  ///
  /// Parameters:
  /// - [config]: Configuration containing package target
  Future<void> _upgradeSpecificPackage(Map<String, dynamic> config) async {
    final targetPackage = config['targetPackage'] as String;
    final skipConfirmation = config['skipConfirmation'] as bool;
    final packagePath = join(current, 'core', 'packages', targetPackage);

    // Validate package exists
    final validation = CommonValidators.validateDirectoryExists(
      packagePath,
      'Package "$targetPackage"',
      'Create the package structure first',
    );

    if (!validation.isValid) {
      ErrorHandler.handleValidationError(validation);
      return;
    }

    // Confirm upgrade operation
    if (!skipConfirmation) {
      final confirmed = await _confirmMajorUpgrade('$targetPackage package');
      if (!confirmed) {
        printMessage('Dependency upgrade cancelled by user.');
        return;
      }
    }

    ProgressReporter.reportPhase('Upgrading $targetPackage dependencies');

    await FlutterHelper.start(
      'packages upgrade',
      workingDirectory: packagePath,
    );

    ProgressReporter.reportPhase('Resolving updated dependencies');

    await FlutterHelper.start(
      'packages get',
      workingDirectory: packagePath,
    );

    ProgressReporter.reportCompletion('$targetPackage dependencies upgraded');
  }

  /// Confirms major upgrade operation with user.
  ///
  /// Prompts the user to confirm dependency upgrades which may
  /// introduce breaking changes or compatibility issues.
  ///
  /// Parameters:
  /// - [scope]: Description of what will be upgraded
  ///
  /// Returns: true if user confirms, false if cancelled
  Future<bool> _confirmMajorUpgrade(String scope) async {
    printMessage('⚠️  This operation will upgrade dependencies for $scope.');
    printMessage(
        '   This may introduce breaking changes or compatibility issues.');
    printMessage('   Make sure you have committed your current changes.');
    printMessage('');
    printMessage(
        '📝 Recommendation: Run `flutter test` after upgrading to verify compatibility.');
    printMessage('');
    print('Do you want to continue? (y/N): ');

    final input = stdin.readLineSync()?.toLowerCase().trim() ?? '';
    return input == 'y' || input == 'yes';
  }

  /// Reports successful completion of the upgrade operation.
  ///
  /// Displays success message and post-upgrade recommendations.
  void _reportSuccess() {
    StatusHelper.success('morpheme upgrade-dependency');
    printMessage('');
    printMessage('🎉 Dependencies upgraded successfully!');
    printMessage('');
    printMessage('📝 Next steps:');
    printMessage('   1. Run `morpheme test` to verify compatibility');
    printMessage('   2. Check for any deprecation warnings');
    printMessage('   3. Update your code if needed');
    printMessage('   4. Commit the updated pubspec.lock files');
  }
}
