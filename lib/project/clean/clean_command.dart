import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Cleans generated files and build artifacts from the project.
///
/// The CleanCommand removes build directories, localization files,
/// and Dart tool cache across the main project, core packages,
/// and feature modules. It supports removing iOS Podfile.lock
/// for complete dependency refresh.
///
/// ## Usage
///
/// Basic cleaning:
/// ```bash
/// morpheme clean
/// ```
///
/// Clean with lock file removal:
/// ```bash
/// morpheme clean --remove-lock
/// ```
///
/// With custom configuration:
/// ```bash
/// morpheme clean --morpheme-yaml custom/path/morpheme.yaml
/// ```
///
/// ## Options
///
/// - `--remove-lock, -l`: Remove iOS Podfile.lock file
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
///
/// ## Files Removed
///
/// - `l10n/` directory (generated localization files)
/// - `build/` directories in all packages
/// - `.dart_tool/` directories in all packages
/// - `ios/Podfile.lock` (when --remove-lock is specified)
///
/// ## Safety
///
/// This command only removes generated files and build artifacts.
/// Source code and configuration files are preserved.
///
/// ## Dependencies
///
/// - Requires valid morpheme.yaml configuration
/// - Uses ModularHelper for package discovery
///
/// ## Exceptions
///
/// Throws [FileSystemException] if morpheme.yaml is missing or invalid.
/// Throws [ProcessException] if file deletion fails due to permissions.
class CleanCommand extends Command {
  /// Creates a new instance of CleanCommand.
  ///
  /// Configures the command-line argument parser to accept:
  /// - `--morpheme-yaml`: Path to the morpheme.yaml configuration file
  /// - `--remove-lock, -l`: Flag to remove iOS Podfile.lock
  CleanCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'remove-lock',
      abbr: 'l',
      defaultsTo: false,
      help: 'Remove iOS Podfile.lock file for complete dependency refresh',
    );
  }

  @override
  String get name => 'clean';

  @override
  String get description =>
      'Clean generated files, build artifacts, and cache from all packages.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      if (!_validateInputs()) return;

      final config = _prepareConfiguration();
      await _executeCleanup(config);
      _reportSuccess();
    } catch (e) {
      StatusHelper.failed('Cleanup failed: ${e.toString()}',
          suggestion:
              'Check file permissions and ensure no processes are using the files',
          examples: ['sudo morpheme clean', 'morpheme doctor']);
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
      return true;
    } catch (e) {
      StatusHelper.failed(
          'Invalid morpheme.yaml configuration: ${e.toString()}',
          suggestion: 'Ensure morpheme.yaml exists and has valid syntax',
          examples: ['morpheme init', 'morpheme config']);
      return false;
    }
  }

  /// Prepares the cleanup configuration from arguments and morpheme.yaml.
  ///
  /// Returns a map containing cleanup settings including concurrency
  /// and lock removal preferences.
  Map<String, dynamic> _prepareConfiguration() {
    final removeLock = argResults?['remove-lock'] ?? false;
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    return {
      'removeLock': removeLock,
      'concurrent': yaml.concurrent,
      'yamlPath': argMorphemeYaml,
    };
  }

  /// Executes the cleanup process across all packages.
  ///
  /// Removes localization files, iOS lock files (if requested),
  /// and delegates to ModularHelper for package-specific cleanup.
  ///
  /// Parameters:
  /// - [config]: Configuration map containing cleanup settings
  Future<void> _executeCleanup(Map<String, dynamic> config) async {
    final removeLock = config['removeLock'] as bool;
    final argMorphemeYaml = config['yamlPath'] as String;

    // Clean localization files
    _cleanLocalizationFiles(argMorphemeYaml);

    // Clean iOS lock file if requested
    if (removeLock) {
      _cleanIosLockFile();
    }

    // Clean all packages
    await ModularHelper.clean(
      concurrent: config['concurrent'],
      removeLock: removeLock,
    );
  }

  /// Removes generated localization files.
  ///
  /// Deletes the l10n directory that contains generated
  /// localization files to force regeneration.
  ///
  /// Parameters:
  /// - [yamlPath]: Path to morpheme.yaml configuration
  void _cleanLocalizationFiles(String yamlPath) {
    final localizationHelper = LocalizationHelper(yamlPath);
    final outputDir = join(current, localizationHelper.outputDir);

    if (exists(outputDir)) {
      deleteDir(outputDir);
    }
  }

  /// Removes iOS Podfile.lock file if it exists.
  ///
  /// This forces CocoaPods to resolve dependencies fresh
  /// on the next iOS build.
  void _cleanIosLockFile() {
    final lockFilePath = join(current, 'ios', 'Podfile.lock');

    if (exists(lockFilePath)) {
      delete(lockFilePath);
    }
  }

  /// Reports successful completion of the cleanup.
  ///
  /// Displays a success message indicating that cleanup
  /// has completed across all packages.
  void _reportSuccess() {
    StatusHelper.success('morpheme clean');
  }
}
