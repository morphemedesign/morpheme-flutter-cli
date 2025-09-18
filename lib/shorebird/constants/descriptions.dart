/// Command descriptions for Shorebird commands.
///
/// This class contains all the command descriptions used throughout the
/// Shorebird CLI module to ensure consistency and proper documentation.
class ShorebirdDescriptions {
  /// Main shorebird command description
  static const String shorebird =
      'Shorebird Code Push is a tool that allows you to update your Flutter '
      'app instantly over the air, without going through the store update process.';

  /// Release command descriptions
  static const String release =
      'Creates a shorebird release for the provided target platforms';
  static const String releaseApk = 'Shorebird release android apk with flavor.';
  static const String releaseAppbundle =
      'Shorebird release android app bundle with flavor.';
  static const String releaseIos =
      'Shorebird an iOS application bundle (Mac OS X host only).';
  static const String releaseIpa =
      'Shorebird release IPA with flavor (Mac OS X host only).';

  /// Patch command descriptions
  static const String patch =
      'Creates a shorebird patch for the provided target platforms';
  static const String patchAndroid = 'Shorebird patch android with flavor.';
  static const String patchIos = 'Shorebird ios with flavor.';

  /// Prevent instantiation
  ShorebirdDescriptions._();
}
