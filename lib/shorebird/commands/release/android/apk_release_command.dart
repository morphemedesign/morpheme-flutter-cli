import '../../../constants/command_names.dart';
import '../../../constants/descriptions.dart';
import '../../../core/base_release_command.dart';

/// Command for releasing Android APK files through Shorebird.
///
/// This command creates a Shorebird release for Android APK artifacts,
/// allowing for over-the-air updates to be deployed to APK-based
/// Android applications.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird release apk --flavor dev
/// morpheme shorebird release apk --flavor prod --build-number 123
/// ```
///
/// ## Options
///
/// All standard Shorebird options are supported:
/// - `--flavor`: The build flavor (dev, staging, prod)
/// - `--target`: The main entry point file
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--build-number`: Build number for versioning
/// - `--build-name`: Build name for versioning
/// - `--obfuscate`: Enable code obfuscation
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// ## Examples
///
/// Basic APK release:
/// ```bash
/// morpheme shorebird release apk
/// ```
///
/// Production APK release with versioning:
/// ```bash
/// morpheme shorebird release apk --flavor prod --build-number 42 --build-name 1.2.0
/// ```
///
/// APK release with obfuscation:
/// ```bash
/// morpheme shorebird release apk --flavor prod --obfuscate
/// ```
class ReleaseApkCommand extends ShorebirdReleaseBaseCommand {
  @override
  String get name => ShorebirdCommandNames.apk;

  @override
  String get description => ShorebirdDescriptions.releaseApk;

  @override
  String get artifactType => 'apk';
}
