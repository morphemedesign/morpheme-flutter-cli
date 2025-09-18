import 'package:morpheme_cli/dependency_manager.dart';

import '../../constants/command_names.dart';
import '../../constants/descriptions.dart';
import 'android_patch_command.dart';
import 'ios_patch_command.dart';

/// Main coordinator command for all Shorebird patch operations.
///
/// This command serves as the parent command for all platform-specific
/// patch commands. It provides a unified entry point for creating
/// Shorebird patches across different platforms.
///
/// ## Subcommands
///
/// ### Platform Patch Commands
/// - `android`: Create patches for Android applications
/// - `ios`: Create patches for iOS applications
///
/// ## Usage
///
/// ```bash
/// # Create Android patch
/// morpheme shorebird patch android --flavor prod
///
/// # Create iOS patch
/// morpheme shorebird patch ios --flavor prod
/// ```
///
/// ## Common Options
///
/// All patch subcommands support these common options:
/// - `--flavor`: Build flavor (dev, staging, prod)
/// - `--target`: Main entry point file
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--build-number`: Build number for targeting specific release
/// - `--build-name`: Build name for targeting specific release
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// Platform-specific options are available for each subcommand.
///
/// ## Patch Workflow
///
/// Each patch command follows this workflow:
/// 1. Validate command arguments and configuration
/// 2. Setup environment (localization, Firebase, Shorebird)
/// 3. Build and execute the Shorebird patch command
/// 4. Report success or handle errors
///
/// ## Patch Targeting
///
/// Patches are applied to specific releases identified by:
/// - Build number and build name combination
/// - Release version string
/// - Shorebird release ID
///
/// ## Examples
///
/// Create a development Android patch:
/// ```bash
/// morpheme shorebird patch android --flavor dev
/// ```
///
/// Create a production Android patch targeting specific release:
/// ```bash
/// morpheme shorebird patch android --flavor prod --build-number 123 --build-name 1.2.3
/// ```
///
/// Create an iOS patch for staging environment:
/// ```bash
/// morpheme shorebird patch ios --flavor staging --export-method ad-hoc
/// ```
///
/// ## Best Practices
///
/// - Always test patches in development/staging before production
/// - Ensure patch configuration matches the target release
/// - Verify that the code changes are compatible with patching
/// - Monitor patch deployment and rollback if necessary
///
/// ## Limitations
///
/// - Not all code changes can be patched (native code, assets)
/// - Patches must be compatible with the target release
/// - Some Flutter framework changes may require full releases
class ShorebirdPatchCommand extends Command {
  /// Creates a new patch command with all platform-specific subcommands.
  ShorebirdPatchCommand() {
    // Add platform patch commands
    addSubcommand(PatchAndroidCommand());
    addSubcommand(PatchIosCommand());
  }

  @override
  String get name => ShorebirdCommandNames.patch;

  @override
  String get description => ShorebirdDescriptions.patch;
}
