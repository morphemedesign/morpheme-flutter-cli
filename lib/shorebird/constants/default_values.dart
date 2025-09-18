/// Default configuration values for Shorebird commands.
///
/// This class contains default values used across Shorebird commands
/// to ensure consistency and easier maintenance.
class ShorebirdDefaults {
  /// Default flavor for commands
  static const String flavor = 'dev';

  /// Default obfuscation setting
  static const bool obfuscate = false;

  /// Default localization generation setting
  static const bool generateL10n = false;

  /// Default codesign setting for iOS
  static const bool codesign = false;

  /// Prevent instantiation
  ShorebirdDefaults._();
}
