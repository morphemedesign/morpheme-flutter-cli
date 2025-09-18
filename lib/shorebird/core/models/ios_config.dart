import 'command_config.dart';

/// iOS-specific configuration for Shorebird commands.
///
/// This class extends the base command configuration with iOS-specific
/// settings like export method, export options, and codesigning.
class IosCommandConfig extends ShorebirdCommandConfig {
  /// The iOS export method (app-store, ad-hoc, development, enterprise)
  final String? exportMethod;

  /// Path to export options plist file
  final String? exportOptionsPlist;

  /// Whether to enable codesigning
  final bool codesign;

  /// Creates a new iOS command configuration.
  ///
  /// Parameters:
  /// - [exportMethod]: The iOS export method
  /// - [exportOptionsPlist]: Path to export options plist
  /// - [codesign]: Whether to enable codesigning
  /// - All other parameters are inherited from [ShorebirdCommandConfig]
  IosCommandConfig({
    this.exportMethod,
    this.exportOptionsPlist,
    this.codesign = false,
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

  /// Builds the iOS-specific command arguments.
  ///
  /// Returns command arguments with iOS-specific flags and options.
  List<String> buildIosCommand(String commandType) {
    final args = <String>[];

    // Add platform
    args.addAll([commandType, 'ios']);

    // Add base configuration
    args.addAll(toCommandArgs());

    // Add iOS-specific options
    if (exportMethod != null && exportMethod!.isNotEmpty) {
      args.addAll(['--export-method', exportMethod!]);
    }

    if (exportOptionsPlist != null && exportOptionsPlist!.isNotEmpty) {
      args.addAll(['--export-options-plist', exportOptionsPlist!]);
    }

    if (codesign) {
      args.add('--codesign');
    }

    return args;
  }

  @override
  IosCommandConfig copyWith({
    String? exportMethod,
    String? exportOptionsPlist,
    bool? codesign,
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
    return IosCommandConfig(
      exportMethod: exportMethod ?? this.exportMethod,
      exportOptionsPlist: exportOptionsPlist ?? this.exportOptionsPlist,
      codesign: codesign ?? this.codesign,
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
    return 'IosCommandConfig('
        'exportMethod: $exportMethod, '
        'codesign: $codesign, '
        'flavor: $flavor, '
        'target: $target'
        ')';
  }
}
