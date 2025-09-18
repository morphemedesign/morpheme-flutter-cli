import 'package:morpheme_cli/dependency_manager.dart';

import '../../constants/command_names.dart';
import '../../constants/descriptions.dart';
import 'android/apk_release_command.dart';
import 'android/appbundle_release_command.dart';
import 'ios/ios_release_command.dart';
import 'ios/ipa_release_command.dart';

/// Main coordinator command for all Shorebird release operations.
///
/// This command serves as the parent command for all platform-specific
/// release commands. It provides a unified entry point for creating
/// Shorebird releases across different platforms and artifact types.
///
/// ## Subcommands
///
/// ### Android Release Commands
/// - `apk`: Release Android APK files
/// - `appbundle`: Release Android App Bundle (AAB) files
///
/// ### iOS Release Commands
/// - `ios`: Release iOS application bundles
/// - `ipa`: Release iOS IPA files
///
/// ## Usage
///
/// ```bash
/// # Release Android APK
/// morpheme shorebird release apk --flavor prod
///
/// # Release Android App Bundle
/// morpheme shorebird release appbundle --flavor prod --obfuscate
///
/// # Release iOS application
/// morpheme shorebird release ios --flavor prod --codesign
///
/// # Release iOS IPA for App Store
/// morpheme shorebird release ipa --flavor prod --export-method app-store
/// ```
///
/// ## Common Options
///
/// All release subcommands support these common options:
/// - `--flavor`: Build flavor (dev, staging, prod)
/// - `--target`: Main entry point file
/// - `--morpheme-yaml`: Path to morpheme.yaml configuration
/// - `--build-number`: Build number for versioning
/// - `--build-name`: Build name for versioning
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// Platform-specific options are available for each subcommand.
///
/// ## Workflow
///
/// Each release command follows this workflow:
/// 1. Validate command arguments and configuration
/// 2. Setup environment (localization, Firebase, Shorebird)
/// 3. Build and execute the Shorebird release command
/// 4. Report success or handle errors
///
/// ## Examples
///
/// Create a development APK release:
/// ```bash
/// morpheme shorebird release apk --flavor dev
/// ```
///
/// Create a production App Bundle with obfuscation:
/// ```bash
/// morpheme shorebird release appbundle --flavor prod --build-number 123 --build-name 1.2.3 --obfuscate
/// ```
///
/// Create an iOS release for App Store distribution:
/// ```bash
/// morpheme shorebird release ipa --flavor prod --export-method app-store --build-number 123
/// ```
class ShorebirdReleaseCommand extends Command {
  /// Creates a new release command with all platform-specific subcommands.
  ShorebirdReleaseCommand() {
    // Add Android release commands
    addSubcommand(ReleaseApkCommand());
    addSubcommand(ReleaseAppbundleCommand());

    // Add iOS release commands
    addSubcommand(ReleaseIosCommand());
    addSubcommand(ReleaseIpaCommand());
  }

  @override
  String get name => ShorebirdCommandNames.release;

  @override
  String get description => ShorebirdDescriptions.release;
}
