import '../../../constants/command_names.dart';
import '../../../constants/descriptions.dart';
import '../../../core/base_release_command.dart';

/// Command for releasing Android App Bundle files through Shorebird.
///
/// This command creates a Shorebird release for Android App Bundle (AAB)
/// artifacts, allowing for over-the-air updates to be deployed to
/// AAB-based Android applications distributed through Google Play Store.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird release appbundle --flavor dev
/// morpheme shorebird release appbundle --flavor prod --build-number 123
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
/// Basic App Bundle release:
/// ```bash
/// morpheme shorebird release appbundle
/// ```
///
/// Production App Bundle release for Play Store:
/// ```bash
/// morpheme shorebird release appbundle --flavor prod --build-number 42 --build-name 1.2.0 --obfuscate
/// ```
///
/// App Bundle release with split debug info:
/// ```bash
/// morpheme shorebird release appbundle --flavor staging --split-debug-info build/symbols
/// ```
class ReleaseAppbundleCommand extends ShorebirdReleaseBaseCommand {
  @override
  String get name => ShorebirdCommandNames.appbundle;

  @override
  String get description => ShorebirdDescriptions.releaseAppbundle;

  @override
  String get artifactType => 'aab';
}
