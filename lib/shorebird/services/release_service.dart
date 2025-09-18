import '../core/models/android_config.dart';
import '../core/models/ios_config.dart';
import 'command_service.dart';

/// Service for executing Shorebird release commands.
///
/// This service handles the execution of Shorebird release commands for
/// different platforms (Android APK, App Bundle, iOS, IPA) with proper
/// configuration and error handling.
///
/// ## Usage
///
/// ```dart
/// final config = AndroidCommandConfig(
///   artifact: 'apk',
///   flavor: 'dev',
///   target: 'lib/main.dart',
///   // ... other configuration
/// );
///
/// final service = ShorebirdReleaseService(config);
/// final result = await service.execute();
/// ```
class ShorebirdReleaseService extends ShorebirdCommandService {
  /// Creates a new release service with the provided configuration.
  ///
  /// Parameters:
  /// - [config]: The command configuration (must be Android or iOS config)
  ShorebirdReleaseService(super.config);

  @override
  Future<void> validate() async {
    logValidation('release service configuration');

    // Validate that we have a platform-specific configuration
    if (config is! AndroidCommandConfig && config is! IosCommandConfig) {
      throw ArgumentError(
          'Release service requires AndroidCommandConfig or IosCommandConfig, '
          'but got ${config.runtimeType}');
    }

    // Validate base configuration
    config.validate();

    // Platform-specific validation
    if (config is AndroidCommandConfig) {
      _validateAndroidConfig(config as AndroidCommandConfig);
    } else if (config is IosCommandConfig) {
      _validateIosConfig(config as IosCommandConfig);
    }
  }

  @override
  String buildCommand() {
    if (config is AndroidCommandConfig) {
      return _buildAndroidReleaseCommand(config as AndroidCommandConfig);
    } else if (config is IosCommandConfig) {
      return _buildIosReleaseCommand(config as IosCommandConfig);
    } else {
      throw ArgumentError(
          'Unsupported configuration type: ${config.runtimeType}');
    }
  }

  /// Validates Android-specific configuration.
  void _validateAndroidConfig(AndroidCommandConfig androidConfig) {
    requireConfigValue(androidConfig.artifact, 'artifact');

    const validArtifacts = ['apk', 'aab'];
    if (!validArtifacts.contains(androidConfig.artifact)) {
      throw ArgumentError(
          'Invalid Android artifact: ${androidConfig.artifact}. '
          'Valid values are: ${validArtifacts.join(', ')}');
    }
  }

  /// Validates iOS-specific configuration.
  void _validateIosConfig(IosCommandConfig iosConfig) {
    // iOS release validation - could add specific checks here
    logValidation('iOS release configuration');
  }

  /// Builds the Android release command.
  String _buildAndroidReleaseCommand(AndroidCommandConfig androidConfig) {
    final args = androidConfig.buildAndroidCommand('release');
    return 'shorebird ${formatCommandArgs(args)}';
  }

  /// Builds the iOS release command.
  String _buildIosReleaseCommand(IosCommandConfig iosConfig) {
    final args = iosConfig.buildIosCommand('release');
    return 'shorebird ${formatCommandArgs(args)}';
  }
}
