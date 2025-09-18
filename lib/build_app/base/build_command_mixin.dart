/// Mixin providing shared build command functionality.
///
/// Implements common argument parsing, validation patterns,
/// and configuration management used across all build commands.
///
/// ## Usage
/// ```dart
/// class MyBuildCommand extends Command with BuildCommandMixin {
///   // Implementation
/// }
/// ```
library;

import 'package:morpheme_cli/build_app/base/build_configuration.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Mixin providing shared build command functionality.
///
/// Contains common patterns for argument parsing, configuration extraction,
/// and validation that are used across all build command implementations.
mixin BuildCommandMixin on Command {
  /// Adds standard build-related command arguments.
  ///
  /// Includes common arguments like target, flavor, build mode,
  /// build numbers, obfuscation, and localization options.
  void addStandardBuildOptions() {
    // Build mode flags
    argParser.addFlagDebug();
    argParser.addFlagProfile();
    argParser.addFlagRelease();

    // Core build options
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();

    // Advanced build options
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  /// Extracts and validates build configuration from command arguments.
  ///
  /// Parses all command-line arguments and morpheme.yaml to create
  /// a comprehensive build configuration object.
  ///
  /// Returns: BuildConfiguration with all parsed parameters
  BuildConfiguration extractBuildConfiguration() {
    final argTarget = argResults.getOptionTarget();
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argBuildNumber = argResults.getOptionBuildNumber();
    final argBuildName = argResults.getOptionBuildName();
    final argObfuscate = argResults.getFlagObfuscate();
    final argSplitDebugInfo = argResults.getOptionSplitDebugInfo();
    final argGenerateL10n = argResults.getFlagGenerateL10n();

    // Extract build mode
    final mode = argResults.getMode();

    // Extract flavor configuration
    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);

    // Build dart-define parameters
    final dartDefines = <String, String>{};
    flavor.forEach((key, value) {
      dartDefines[key] = value.toString();
    });

    return BuildConfiguration(
      target: argTarget,
      flavor: argFlavor,
      mode: _parseBuildMode(mode),
      morphemeYamlPath: argMorphemeYaml,
      buildNumber: argBuildNumber,
      buildName: argBuildName,
      obfuscate: argObfuscate as bool,
      splitDebugInfo: argSplitDebugInfo,
      generateL10n: argGenerateL10n,
      dartDefines: dartDefines,
    );
  }

  /// Validates build configuration for completeness and correctness.
  ///
  /// Performs comprehensive validation of the build configuration
  /// including required parameters and logical consistency checks.
  ///
  /// Parameters:
  /// - [config]: Build configuration to validate
  ///
  /// Returns: ValidationResult indicating configuration validity
  ValidationResult<BuildConfiguration> validateBuildConfiguration(
    BuildConfiguration config,
  ) {
    // Validate target file exists
    if (!exists(config.target)) {
      return ValidationResult.error(
        'Target file "${config.target}" does not exist',
        suggestion: 'Ensure the target file path is correct',
        examples: ['ls ${config.target}', 'find . -name "main.dart"'],
      );
    }

    // Validate obfuscation requirements
    if (config.obfuscate &&
        (config.splitDebugInfo == null || config.splitDebugInfo!.isEmpty)) {
      return ValidationResult.error(
        'Obfuscation requires split-debug-info option',
        suggestion: 'Provide --split-debug-info when using --obfuscate',
        examples: ['--split-debug-info=./.symbols/'],
      );
    }

    // Validate build mode consistency
    if (config.mode == BuildMode.debug && config.obfuscate) {
      return ValidationResult.error(
        'Obfuscation is not recommended for debug builds',
        suggestion: 'Use obfuscation only with release or profile builds',
        examples: ['--release --obfuscate', '--profile --obfuscate'],
      );
    }

    return ValidationResult.success(config);
  }

  /// Parses build mode from command arguments.
  ///
  /// Determines the build mode based on the flags provided,
  /// with release as the default mode.
  ///
  /// Parameters:
  /// - [mode]: Mode string from argument parsing
  ///
  /// Returns: BuildMode enum value
  BuildMode _parseBuildMode(String mode) {
    switch (mode.toLowerCase()) {
      case '--debug':
        return BuildMode.debug;
      case '--profile':
        return BuildMode.profile;
      case '--release':
      default:
        return BuildMode.release;
    }
  }

  /// Builds Flutter command arguments from configuration.
  ///
  /// Constructs the complete set of Flutter build command arguments
  /// based on the provided build configuration.
  ///
  /// Parameters:
  /// - [config]: Build configuration
  /// - [platform]: Target platform (e.g., 'apk', 'ios', 'web')
  ///
  /// Returns: List of command arguments for Flutter build
  List<String> buildFlutterArguments(
    BuildConfiguration config,
    String platform,
  ) {
    final arguments = <String>[
      'build',
      platform,
      '-t',
      config.target,
    ];

    // Add dart-define parameters
    for (final entry in config.dartDefines.entries) {
      arguments.addAll([(Constants.dartDefine), '${entry.key}=${entry.value}']);
    }

    // Add build mode
    arguments.add(config.mode.toArgumentString());

    // Add build numbers if specified
    if (config.buildNumber != null && config.buildNumber!.isNotEmpty) {
      arguments.addAll(['--build-number', config.buildNumber!]);
    }

    if (config.buildName != null && config.buildName!.isNotEmpty) {
      arguments.addAll(['--build-name', config.buildName!]);
    }

    // Add obfuscation settings
    if (config.obfuscate) {
      arguments.add('--obfuscate');
    }

    if (config.splitDebugInfo != null && config.splitDebugInfo!.isNotEmpty) {
      arguments.addAll(['--split-debug-info', config.splitDebugInfo!]);
    }

    return arguments;
  }
}

/// Build mode enumeration.
///
/// Represents the different build modes supported by Flutter
/// with corresponding command-line argument strings.
enum BuildMode {
  /// Debug build mode with debugging information
  debug,

  /// Profile build mode for performance profiling
  profile,

  /// Release build mode optimized for production
  release;

  /// Converts build mode to Flutter command argument string.
  ///
  /// Returns: Command-line argument string for this build mode
  String toArgumentString() {
    switch (this) {
      case BuildMode.debug:
        return '--debug';
      case BuildMode.profile:
        return '--profile';
      case BuildMode.release:
        return '--release';
    }
  }

  /// Gets display name for this build mode.
  ///
  /// Returns: Human-readable name for this build mode
  String get displayName {
    switch (this) {
      case BuildMode.debug:
        return 'Debug';
      case BuildMode.profile:
        return 'Profile';
      case BuildMode.release:
        return 'Release';
    }
  }
}
