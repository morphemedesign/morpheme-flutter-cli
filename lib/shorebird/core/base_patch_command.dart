import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import 'base_command.dart';
import 'models/command_config.dart';
import 'models/android_config.dart';
import 'models/ios_config.dart';
import 'models/shorebird_result.dart';
import '../services/patch_service.dart';

/// Abstract base class for Shorebird patch commands.
///
/// This class provides common functionality for all patch commands
/// (Android, iOS) including configuration building, validation,
/// and execution through the patch service.
///
/// ## Usage
///
/// Subclass this class to create specific patch commands:
///
/// ```dart
/// class PatchAndroidCommand extends ShorebirdPatchBaseCommand {
///   @override
///   String get name => 'android';
///
///   @override
///   String get description => 'Patch Android application';
///
///   @override
///   String get platformType => 'android';
/// }
/// ```
abstract class ShorebirdPatchBaseCommand extends ShorebirdBaseCommand {
  /// The platform type for this patch command (android, ios).
  ///
  /// This property must be implemented by subclasses to specify
  /// what platform this command patches.
  String get platformType;

  /// Whether this is an Android patch command.
  bool get isAndroid => platformType == 'android';

  /// Whether this is an iOS patch command.
  bool get isIos => platformType == 'ios';

  @override
  void addPlatformSpecificOptions(ArgParser argParser) {
    if (isIos) {
      // Add iOS-specific options for patch
      argParser.addOptionExportMethod();
      argParser.addOptionExportOptionsPlist();
      // Note: Codesign is not typically used for patches
    }
    // Android patch options are already covered by base options
  }

  @override
  Future<ShorebirdCommandConfig> validateAndBuildConfig() async {
    final commonArgs = extractCommonArguments();

    if (isAndroid) {
      return _buildAndroidConfig(commonArgs);
    } else if (isIos) {
      return _buildIosConfig(commonArgs);
    } else {
      throw ArgumentError('Unsupported platform type: $platformType');
    }
  }

  @override
  Future<ShorebirdResult> executeCommand(ShorebirdCommandConfig config) async {
    logCommand('Executing patch command for $platformType');

    final service = ShorebirdPatchService(config);
    return await service.execute();
  }

  /// Builds Android-specific configuration for patches.
  AndroidCommandConfig _buildAndroidConfig(Map<String, dynamic> args) {
    // Validate and get flavor configuration
    final flavorConfig = validateAndGetFlavorConfig(
      args['flavor'] as String,
      args['morphemeYaml'] as String,
    );

    // Build dart defines from flavor configuration
    final dartDefines = <String, String>{};
    flavorConfig.forEach((key, value) {
      dartDefines[key] = value;
    });

    // Get and validate Shorebird configuration
    final shorebird = validateShorebirdConfig(
      args['flavor'] as String,
      args['morphemeYaml'] as String,
    );

    // Build release version string for patch targeting
    final releaseVersion = _buildReleaseVersion(
      args['buildName'] as String?,
      args['buildNumber'] as String?,
    );

    return AndroidCommandConfig(
      artifact: 'apk', // Default artifact for patches - not used in command
      flavor: args['flavor'] as String,
      target: args['target'] as String,
      morphemeYaml: args['morphemeYaml'] as String,
      buildNumber: args['buildNumber'] as String?,
      buildName: args['buildName'] as String?,
      obfuscate: args['obfuscate'] as bool,
      splitDebugInfo: args['splitDebugInfo'] as String?,
      generateL10n: args['generateL10n'] as bool,
      dartDefines: dartDefines,
      flutterVersion: shorebird.$1,
      releaseVersion: releaseVersion,
    );
  }

  /// Builds iOS-specific configuration for patches.
  IosCommandConfig _buildIosConfig(Map<String, dynamic> args) {
    // Validate and get flavor configuration
    final flavorConfig = validateAndGetFlavorConfig(
      args['flavor'] as String,
      args['morphemeYaml'] as String,
    );

    // Build dart defines from flavor configuration
    final dartDefines = <String, String>{};
    flavorConfig.forEach((key, value) {
      dartDefines[key] = value;
    });

    // Get and validate Shorebird configuration
    final shorebird = validateShorebirdConfig(
      args['flavor'] as String,
      args['morphemeYaml'] as String,
    );

    // Build release version string for patch targeting
    final releaseVersion = _buildReleaseVersion(
      args['buildName'] as String?,
      args['buildNumber'] as String?,
    );

    // Extract iOS-specific arguments for patches
    final exportMethod = argResults?.getOptionExportMethod();
    final exportOptionsPlist = argResults?.getOptionExportOptionsPlist();

    // Validate iOS-specific options
    validateExportMethod(exportMethod);
    validateExportOptionsPlist(exportOptionsPlist);

    return IosCommandConfig(
      exportMethod: exportMethod,
      exportOptionsPlist: exportOptionsPlist,
      codesign: false, // Codesign is typically not used for patches
      flavor: args['flavor'] as String,
      target: args['target'] as String,
      morphemeYaml: args['morphemeYaml'] as String,
      buildNumber: args['buildNumber'] as String?,
      buildName: args['buildName'] as String?,
      obfuscate: args['obfuscate'] as bool,
      splitDebugInfo: args['splitDebugInfo'] as String?,
      generateL10n: args['generateL10n'] as bool,
      dartDefines: dartDefines,
      flutterVersion: shorebird.$1,
      releaseVersion: releaseVersion,
    );
  }

  /// Builds the release version string from build name and number.
  ///
  /// For patches, this is used to target a specific release version.
  String? _buildReleaseVersion(String? buildName, String? buildNumber) {
    final name = buildName ?? '';
    final number = buildNumber ?? '';

    if (name.isEmpty && number.isEmpty) {
      return null;
    }

    final version = '$name+$number';
    return version == '+' ? null : version;
  }
}
