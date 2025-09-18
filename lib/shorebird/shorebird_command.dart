import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'commands/patch/patch_command.dart';
import 'commands/release/release_command.dart';
import 'constants/command_names.dart';
import 'constants/descriptions.dart';

/// Main entry point for all Shorebird-related commands.
///
/// This command serves as the root command for the Shorebird CLI module,
/// providing access to all Shorebird functionality through organized
/// subcommands for releases and patches.
///
/// ## Subcommands
///
/// ### Release Commands
/// - `release`: Create Shorebird releases for different platforms
///   - `apk`: Release Android APK files
///   - `appbundle`: Release Android App Bundle files
///   - `ios`: Release iOS application bundles
///   - `ipa`: Release iOS IPA files
///
/// ### Patch Commands
/// - `patch`: Create Shorebird patches for existing releases
///   - `android`: Create patches for Android applications
///   - `ios`: Create patches for iOS applications
///
/// ## Usage
///
/// ```bash
/// # Create releases
/// morpheme shorebird release apk --flavor prod
/// morpheme shorebird release ipa --flavor prod --export-method app-store
///
/// # Create patches
/// morpheme shorebird patch android --flavor prod
/// morpheme shorebird patch ios --flavor prod
/// ```
///
/// ## About Shorebird
///
/// Shorebird Code Push enables over-the-air updates for Flutter applications,
/// allowing developers to deploy bug fixes and feature updates instantly
/// without requiring users to download a new version from app stores.
///
/// ## Features
///
/// - **Instant Updates**: Deploy updates immediately to users
/// - **Platform Support**: Works with Android (APK/AAB) and iOS (IPA)
/// - **Targeted Patches**: Apply patches to specific app releases
/// - **Rollback Support**: Revert problematic updates quickly
/// - **Development Integration**: Seamless integration with existing workflows
class ShorebirdCommand extends Command {
  /// Creates a new Shorebird command with all subcommands.
  ShorebirdCommand() {
    addSubcommand(ShorebirdReleaseCommand());
    addSubcommand(ShorebirdPatchCommand());
  }

  @override
  String get name => ShorebirdCommandNames.shorebird;

  @override
  String get description => ShorebirdDescriptions.shorebird;

  @override
  String get category => Constants.shorebird;
}
