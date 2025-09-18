import '../core/models/command_config.dart';
import '../core/models/android_config.dart';
import '../core/models/ios_config.dart';
import '../core/mixins/logging_mixin.dart';

/// Service for building Shorebird command strings from configuration.
///
/// This service provides utility methods for constructing properly formatted
/// Shorebird command strings based on different configuration types.
///
/// ## Usage
///
/// ```dart
/// final builder = ShorebirdCommandBuilderService();
///
/// final androidConfig = AndroidCommandConfig(/* ... */);
/// final command = builder.buildReleaseCommand(androidConfig);
///
/// final iosConfig = IosCommandConfig(/* ... */);
/// final patchCommand = builder.buildPatchCommand(iosConfig);
/// ```
class ShorebirdCommandBuilderService with ShorebirdLoggingMixin {
  /// Builds a release command string from the provided configuration.
  ///
  /// Parameters:
  /// - [config]: The command configuration (Android or iOS)
  ///
  /// Returns:
  /// - A complete Shorebird release command string
  ///
  /// Throws:
  /// - [ArgumentError]: If the configuration type is not supported
  String buildReleaseCommand(ShorebirdCommandConfig config) {
    logDebug('Building release command for ${config.runtimeType}');

    if (config is AndroidCommandConfig) {
      return _buildAndroidReleaseCommand(config);
    } else if (config is IosCommandConfig) {
      return _buildIosReleaseCommand(config);
    } else {
      throw ArgumentError(
          'Unsupported configuration type for release: ${config.runtimeType}');
    }
  }

  /// Builds a patch command string from the provided configuration.
  ///
  /// Parameters:
  /// - [config]: The command configuration (Android or iOS)
  ///
  /// Returns:
  /// - A complete Shorebird patch command string
  ///
  /// Throws:
  /// - [ArgumentError]: If the configuration type is not supported
  String buildPatchCommand(ShorebirdCommandConfig config) {
    logDebug('Building patch command for ${config.runtimeType}');

    if (config is AndroidCommandConfig) {
      return _buildAndroidPatchCommand(config);
    } else if (config is IosCommandConfig) {
      return _buildIosPatchCommand(config);
    } else {
      throw ArgumentError(
          'Unsupported configuration type for patch: ${config.runtimeType}');
    }
  }

  /// Builds an Android release command.
  String _buildAndroidReleaseCommand(AndroidCommandConfig config) {
    final args = config.buildAndroidCommand('release');
    final command = 'shorebird ${_formatArgs(args)}';
    logDebug('Built Android release command: $command');
    return command;
  }

  /// Builds an iOS release command.
  String _buildIosReleaseCommand(IosCommandConfig config) {
    final args = config.buildIosCommand('release');
    final command = 'shorebird ${_formatArgs(args)}';
    logDebug('Built iOS release command: $command');
    return command;
  }

  /// Builds an Android patch command.
  String _buildAndroidPatchCommand(AndroidCommandConfig config) {
    final args = config.buildAndroidCommand('patch');
    final command = 'shorebird ${_formatArgs(args)}';
    logDebug('Built Android patch command: $command');
    return command;
  }

  /// Builds an iOS patch command.
  String _buildIosPatchCommand(IosCommandConfig config) {
    final args = config.buildIosCommand('patch');
    final command = 'shorebird ${_formatArgs(args)}';
    logDebug('Built iOS patch command: $command');
    return command;
  }

  /// Formats command arguments into a single string.
  String _formatArgs(List<String> args) {
    return args.where((arg) => arg.isNotEmpty).join(' ');
  }

  /// Validates that a command configuration is suitable for the operation.
  ///
  /// Parameters:
  /// - [config]: The configuration to validate
  /// - [operation]: The operation type ('release' or 'patch')
  ///
  /// Throws:
  /// - [ArgumentError]: If the configuration is not valid for the operation
  void validateConfigForOperation(
      ShorebirdCommandConfig config, String operation) {
    if (config is! AndroidCommandConfig && config is! IosCommandConfig) {
      throw ArgumentError(
          'Configuration must be AndroidCommandConfig or IosCommandConfig '
          'for $operation operations, but got ${config.runtimeType}');
    }

    // Additional validation could be added here for specific operations
    logValidation('$operation configuration for ${config.runtimeType}');
  }
}
