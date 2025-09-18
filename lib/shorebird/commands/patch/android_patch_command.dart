import '../../constants/command_names.dart';
import '../../constants/descriptions.dart';
import '../../core/base_patch_command.dart';

/// Command for creating patches for Android applications through Shorebird.
///
/// This command creates a Shorebird patch for Android applications,
/// allowing for over-the-air updates to be deployed to existing
/// Android app installations without requiring a full app update
/// through the app store.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird patch android --flavor dev
/// morpheme shorebird patch android --flavor prod --build-number 123
/// ```
///
/// ## Options
///
/// All standard Shorebird options are supported:
/// - `--flavor`: The build flavor (dev, staging, prod)
/// - `--target`: The main entry point file
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--build-number`: Build number for targeting specific release
/// - `--build-name`: Build name for targeting specific release
/// - `--obfuscate`: Enable code obfuscation (must match original release)
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// ## Patch Targeting
///
/// Patches are applied to specific releases. You can target a release by:
/// - Specifying build number and build name
/// - Using the release version string format
///
/// ## Examples
///
/// Create a patch for the current development version:
/// ```bash
/// morpheme shorebird patch android --flavor dev
/// ```
///
/// Create a patch targeting a specific production release:
/// ```bash
/// morpheme shorebird patch android --flavor prod --build-number 42 --build-name 1.2.0
/// ```
///
/// Create a patch with obfuscation (matching original release):
/// ```bash
/// morpheme shorebird patch android --flavor prod --obfuscate
/// ```
///
/// ## Important Notes
///
/// - The patch must be compatible with the target release
/// - Obfuscation settings should match the original release
/// - Dart defines and environment must match the target release
/// - Some code changes may not be patchable and require a full release
class PatchAndroidCommand extends ShorebirdPatchBaseCommand {
  @override
  String get name => ShorebirdCommandNames.android;

  @override
  String get description => ShorebirdDescriptions.patchAndroid;

  @override
  String get platformType => 'android';
}
