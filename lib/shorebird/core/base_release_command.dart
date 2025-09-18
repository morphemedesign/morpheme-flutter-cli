import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import 'base_command.dart';
import 'models/command_config.dart';
import 'models/android_config.dart';
import 'models/ios_config.dart';
import 'models/shorebird_result.dart';
import '../services/release_service.dart';

/// Abstract base class for Shorebird release commands.
///
/// This class provides common functionality for all release commands
/// (APK, App Bundle, iOS, IPA) including configuration building,
/// validation, and execution through the release service.
///
/// ## Usage
///
/// Subclass this class to create specific release commands:
///
/// ```dart
/// class ReleaseApkCommand extends ShorebirdReleaseBaseCommand {
///   @override
///   String get name => 'apk';
///
///   @override
///   String get description => 'Release Android APK';
///
///   @override
///   String get artifactType => 'apk';
/// }
/// ```
abstract class ShorebirdReleaseBaseCommand extends ShorebirdBaseCommand {
  /// The artifact type for this release command (apk, aab, ios, ipa).
  ///
  /// This property must be implemented by subclasses to specify
  /// what type of artifact this command releases.
  String get artifactType;

  /// Whether this is an Android release command.
  bool get isAndroid => artifactType == 'apk' || artifactType == 'aab';

  /// Whether this is an iOS release command.
  bool get isIos => artifactType == 'ios' || artifactType == 'ipa';

  @override
  void addPlatformSpecificOptions(ArgParser argParser) {
    if (isIos) {
      // Add iOS-specific options
      argParser.addOptionExportMethod();
      argParser.addOptionExportOptionsPlist();
      argParser.addFlagCodesign();
    }
    // Android options are already covered by base options
  }

  @override
  Future<ShorebirdCommandConfig> validateAndBuildConfig() async {
    final commonArgs = extractCommonArguments();

    if (isAndroid) {
      return _buildAndroidConfig(commonArgs);
    } else if (isIos) {
      return _buildIosConfig(commonArgs);
    } else {
      throw ArgumentError('Unsupported artifact type: $artifactType');
    }
  }

  @override
  Future<ShorebirdResult> executeCommand(ShorebirdCommandConfig config) async {
    logCommand('Executing release command for $artifactType');

    final service = ShorebirdReleaseService(config);
    return await service.execute();
  }

  /// Builds Android-specific configuration.
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

    // Build release version string
    final releaseVersion = _buildReleaseVersion(
      args['buildName'] as String?,
      args['buildNumber'] as String?,
    );

    return AndroidCommandConfig(
      artifact: artifactType,
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

  /// Builds iOS-specific configuration.
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

    // Build release version string
    final releaseVersion = _buildReleaseVersion(
      args['buildName'] as String?,
      args['buildNumber'] as String?,
    );

    // Extract iOS-specific arguments
    final exportMethod = argResults?.getOptionExportMethod();
    final exportOptionsPlist = argResults?.getOptionExportOptionsPlist();
    final codesign = argResults?['codesign'] as bool? ?? false;

    // Validate iOS-specific options
    validateExportMethod(exportMethod);
    validateExportOptionsPlist(exportOptionsPlist);

    return IosCommandConfig(
      exportMethod: exportMethod,
      exportOptionsPlist: exportOptionsPlist,
      codesign: codesign,
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
