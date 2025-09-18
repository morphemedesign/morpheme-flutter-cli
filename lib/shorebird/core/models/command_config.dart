import '../exceptions/validation_error.dart';

/// Represents the complete configuration for a Shorebird command execution.
///
/// This class encapsulates all the parameters and settings needed to execute
/// a Shorebird command, including build settings, versioning, and platform-specific
/// configurations.
class ShorebirdCommandConfig {
  /// The flavor/environment to build for (dev, staging, prod)
  final String flavor;

  /// The build target (lib/main.dart, lib/main_dev.dart, etc.)
  final String target;

  /// Path to the morpheme.yaml configuration file
  final String morphemeYaml;

  /// Build number for versioning
  final String? buildNumber;

  /// Build name for versioning
  final String? buildName;

  /// Whether to enable code obfuscation
  final bool obfuscate;

  /// Path for split debug information
  final String? splitDebugInfo;

  /// Whether to generate localization files
  final bool generateL10n;

  /// Dart defines to pass to the build process
  final Map<String, String> dartDefines;

  /// Specific Flutter version to use
  final String? flutterVersion;

  /// Release version string for Shorebird
  final String? releaseVersion;

  /// Creates a new command configuration with validation.
  ///
  /// Parameters:
  /// - [flavor]: The flavor/environment to build for
  /// - [target]: The build target file
  /// - [morphemeYaml]: Path to morpheme.yaml configuration
  /// - [buildNumber]: Build number for versioning
  /// - [buildName]: Build name for versioning
  /// - [obfuscate]: Whether to enable code obfuscation
  /// - [splitDebugInfo]: Path for split debug information
  /// - [generateL10n]: Whether to generate localization files
  /// - [dartDefines]: Dart defines for build process
  /// - [flutterVersion]: Specific Flutter version to use
  /// - [releaseVersion]: Release version for Shorebird
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If any required fields are invalid
  ShorebirdCommandConfig({
    required this.flavor,
    required this.target,
    required this.morphemeYaml,
    this.buildNumber,
    this.buildName,
    this.obfuscate = false,
    this.splitDebugInfo,
    this.generateL10n = false,
    required this.dartDefines,
    this.flutterVersion,
    this.releaseVersion,
  }) {
    validate();
  }

  /// Validates the configuration parameters.
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If any validation checks fail
  void validate() {
    if (flavor.isEmpty) {
      throw ShorebirdValidationError.emptyField('flavor');
    }
    if (target.isEmpty) {
      throw ShorebirdValidationError.emptyField('target');
    }
    if (morphemeYaml.isEmpty) {
      throw ShorebirdValidationError.emptyField('morphemeYaml');
    }
  }

  /// Converts configuration to command line arguments.
  ///
  /// Returns a list of command line arguments that can be passed to
  /// the Shorebird CLI based on this configuration.
  List<String> toCommandArgs() {
    final args = <String>[];

    // Add target
    args.addAll(['-t', target]);

    // Add dart defines
    for (final define in dartDefines.entries) {
      args.addAll(['--dart-define', '${define.key}=${define.value}']);
    }

    // Add build version info
    if (buildNumber != null && buildNumber!.isNotEmpty) {
      args.addAll(['--build-number', buildNumber!]);
    }

    if (buildName != null && buildName!.isNotEmpty) {
      args.addAll(['--build-name', buildName!]);
    }

    // Add debug info
    if (splitDebugInfo != null && splitDebugInfo!.isNotEmpty) {
      args.addAll(['--split-debug-info', splitDebugInfo!]);
    }

    // Add release version
    if (releaseVersion != null && releaseVersion!.isNotEmpty) {
      args.addAll(['--release-version', releaseVersion!]);
    }

    // Add Flutter version
    if (flutterVersion != null && flutterVersion!.isNotEmpty) {
      args.addAll(['--flutter-version', flutterVersion!]);
    }

    // Add no-confirm flag
    args.add('--no-confirm');

    return args;
  }

  /// Creates a copy of this configuration with updated values.
  ///
  /// Parameters can be provided to override specific values in the copy.
  ShorebirdCommandConfig copyWith({
    String? flavor,
    String? target,
    String? morphemeYaml,
    String? buildNumber,
    String? buildName,
    bool? obfuscate,
    String? splitDebugInfo,
    bool? generateL10n,
    Map<String, String>? dartDefines,
    String? flutterVersion,
    String? releaseVersion,
  }) {
    return ShorebirdCommandConfig(
      flavor: flavor ?? this.flavor,
      target: target ?? this.target,
      morphemeYaml: morphemeYaml ?? this.morphemeYaml,
      buildNumber: buildNumber ?? this.buildNumber,
      buildName: buildName ?? this.buildName,
      obfuscate: obfuscate ?? this.obfuscate,
      splitDebugInfo: splitDebugInfo ?? this.splitDebugInfo,
      generateL10n: generateL10n ?? this.generateL10n,
      dartDefines: dartDefines ?? this.dartDefines,
      flutterVersion: flutterVersion ?? this.flutterVersion,
      releaseVersion: releaseVersion ?? this.releaseVersion,
    );
  }

  /// Creates a formatted version string from build name and number.
  ///
  /// Returns a version string in the format "buildName+buildNumber"
  /// or an empty string if both are null/empty.
  String getFormattedReleaseVersion() {
    final name = buildName ?? '';
    final number = buildNumber ?? '';

    if (name.isEmpty && number.isEmpty) {
      return '';
    }

    return '$name+$number';
  }

  @override
  String toString() {
    return 'ShorebirdCommandConfig('
        'flavor: $flavor, '
        'target: $target, '
        'obfuscate: $obfuscate, '
        'generateL10n: $generateL10n'
        ')';
  }
}
