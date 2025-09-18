import 'command_config.dart';

/// Android-specific configuration for Shorebird commands.
///
/// This class extends the base command configuration with Android-specific
/// settings like artifact type and obfuscation handling.
class AndroidCommandConfig extends ShorebirdCommandConfig {
  /// The Android artifact type (apk, aab)
  final String artifact;

  /// Creates a new Android command configuration.
  ///
  /// Parameters:
  /// - [artifact]: The Android artifact type to build
  /// - All other parameters are inherited from [ShorebirdCommandConfig]
  AndroidCommandConfig({
    required this.artifact,
    required super.flavor,
    required super.target,
    required super.morphemeYaml,
    super.buildNumber,
    super.buildName,
    super.obfuscate = false,
    super.splitDebugInfo,
    super.generateL10n = false,
    required super.dartDefines,
    super.flutterVersion,
    super.releaseVersion,
  });

  /// Builds the Android-specific command arguments.
  ///
  /// Returns command arguments with Android-specific flags and options.
  List<String> buildAndroidCommand(String commandType) {
    final args = <String>[];

    // Add platform and artifact
    args.addAll([commandType, 'android']);

    // Add artifact type for release commands
    if (commandType == 'release') {
      args.addAll(['--artifact', artifact]);
    }

    // Add base configuration
    args.addAll(toCommandArgs());

    // Add obfuscation flag for Android (after base args)
    if (obfuscate) {
      args.addAll(['--', '--obfuscate']);
    }

    return args;
  }

  @override
  AndroidCommandConfig copyWith({
    String? artifact,
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
    return AndroidCommandConfig(
      artifact: artifact ?? this.artifact,
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

  @override
  String toString() {
    return 'AndroidCommandConfig('
        'artifact: $artifact, '
        'flavor: $flavor, '
        'target: $target, '
        'obfuscate: $obfuscate'
        ')';
  }
}
