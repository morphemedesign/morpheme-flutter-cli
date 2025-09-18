/// Command name constants for Shorebird commands.
///
/// This class contains all the command names used throughout the Shorebird
/// CLI module to ensure consistency and avoid magic strings.
class ShorebirdCommandNames {
  /// The main shorebird command name
  static const String shorebird = 'shorebird';

  /// Release command names
  static const String release = 'release';
  static const String apk = 'apk';
  static const String appbundle = 'appbundle';
  static const String ios = 'ios';
  static const String ipa = 'ipa';

  /// Patch command names
  static const String patch = 'patch';
  static const String android = 'android';

  /// Prevent instantiation
  ShorebirdCommandNames._();
}
