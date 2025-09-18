import '../../constants/command_names.dart';
import '../../constants/descriptions.dart';
import '../../core/base_patch_command.dart';

/// Command for creating patches for iOS applications through Shorebird.
///
/// This command creates a Shorebird patch for iOS applications,
/// allowing for over-the-air updates to be deployed to existing
/// iOS app installations without requiring a full app update
/// through the App Store.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird patch ios --flavor dev
/// morpheme shorebird patch ios --flavor prod --build-number 123
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
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// iOS-specific options:
/// - `--export-method`: iOS export method (should match original release)
/// - `--export-options-plist`: Path to export options plist file
///
/// ## Platform Requirements
///
/// This command requires macOS and properly configured iOS development
/// environment including:
/// - Xcode
/// - iOS development certificates (if needed)
/// - Provisioning profiles (if needed)
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
/// morpheme shorebird patch ios --flavor dev
/// ```
///
/// Create a patch targeting a specific production release:
/// ```bash
/// morpheme shorebird patch ios --flavor prod --build-number 42 --build-name 1.2.0
/// ```
///
/// Create a patch with specific export method:
/// ```bash
/// morpheme shorebird patch ios --flavor staging --export-method ad-hoc
/// ```
///
/// Create a patch with custom export options:
/// ```bash
/// morpheme shorebird patch ios --flavor prod --export-options-plist ios/ExportOptions.plist
/// ```
///
/// ## Important Notes
///
/// - The patch must be compatible with the target release
/// - Export method and options should match the original release
/// - Dart defines and environment must match the target release
/// - Some code changes may not be patchable and require a full release
/// - Code signing is typically not required for patches
class PatchIosCommand extends ShorebirdPatchBaseCommand {
  @override
  String get name => ShorebirdCommandNames.ios;

  @override
  String get description => ShorebirdDescriptions.patchIos;

  @override
  String get platformType => 'ios';
}
