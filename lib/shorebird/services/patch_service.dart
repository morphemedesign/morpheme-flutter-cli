import '../core/models/android_config.dart';
import '../core/models/ios_config.dart';
import 'command_service.dart';

/// Service for executing Shorebird patch commands.
///
/// This service handles the execution of Shorebird patch commands for
/// different platforms (Android, iOS) with proper configuration and
/// error handling.
///
/// ## Usage
///
/// ```dart
/// final config = AndroidCommandConfig(
///   artifact: 'apk', // Not used for patches but required by config
///   flavor: 'dev',
///   target: 'lib/main.dart',
///   // ... other configuration
/// );
///
/// final service = ShorebirdPatchService(config);
/// final result = await service.execute();
/// ```
class ShorebirdPatchService extends ShorebirdCommandService {
  /// Creates a new patch service with the provided configuration.
  ///
  /// Parameters:
  /// - [config]: The command configuration (must be Android or iOS config)
  ShorebirdPatchService(super.config);

  @override
  Future<void> validate() async {
    logValidation('patch service configuration');

    // Validate that we have a platform-specific configuration
    if (config is! AndroidCommandConfig && config is! IosCommandConfig) {
      throw ArgumentError(
          'Patch service requires AndroidCommandConfig or IosCommandConfig, '
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
      return _buildAndroidPatchCommand(config as AndroidCommandConfig);
    } else if (config is IosCommandConfig) {
      return _buildIosPatchCommand(config as IosCommandConfig);
    } else {
      throw ArgumentError(
          'Unsupported configuration type: ${config.runtimeType}');
    }
  }

  /// Validates Android-specific configuration for patches.
  void _validateAndroidConfig(AndroidCommandConfig androidConfig) {
    // Android patch validation - patches don't use artifact type
    // but the configuration still needs to be valid
    logValidation('Android patch configuration');
  }

  /// Validates iOS-specific configuration for patches.
  void _validateIosConfig(IosCommandConfig iosConfig) {
    // iOS patch validation
    logValidation('iOS patch configuration');
  }

  /// Builds the Android patch command.
  String _buildAndroidPatchCommand(AndroidCommandConfig androidConfig) {
    final args = androidConfig.buildAndroidCommand('patch');
    return 'shorebird ${formatCommandArgs(args)}';
  }

  /// Builds the iOS patch command.
  String _buildIosPatchCommand(IosCommandConfig iosConfig) {
    final args = iosConfig.buildIosCommand('patch');
    return 'shorebird ${formatCommandArgs(args)}';
  }
}
