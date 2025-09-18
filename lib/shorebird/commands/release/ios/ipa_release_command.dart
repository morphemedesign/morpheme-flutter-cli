import '../../../constants/command_names.dart';
import '../../../constants/descriptions.dart';
import '../../../core/base_release_command.dart';

/// Command for releasing iOS IPA files through Shorebird.
///
/// This command creates a Shorebird release for iOS IPA (iOS App Store Package)
/// artifacts, allowing for over-the-air updates to be deployed to IPA-based
/// iOS applications. This is typically used for App Store distribution.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird release ipa --flavor dev
/// morpheme shorebird release ipa --flavor prod --build-number 123
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
/// - `--split-debug-info`: Path for split debug information
/// - `--generate-l10n`: Generate localization files
///
/// iOS-specific options:
/// - `--export-method`: iOS export method (app-store, ad-hoc, development, enterprise)
/// - `--export-options-plist`: Path to export options plist file
/// - `--codesign`: Enable code signing
///
/// ## Platform Requirements
///
/// This command requires macOS and properly configured iOS development
/// environment including:
/// - Xcode
/// - iOS development/distribution certificates
/// - Provisioning profiles
/// - Valid App Store Connect credentials (for app-store export)
///
/// ## Examples
///
/// Basic IPA release for development:
/// ```bash
/// morpheme shorebird release ipa --export-method development
/// ```
///
/// Production IPA release for App Store:
/// ```bash
/// morpheme shorebird release ipa --flavor prod --export-method app-store --build-number 42 --build-name 1.2.0
/// ```
///
/// Ad-hoc IPA release for testing:
/// ```bash
/// morpheme shorebird release ipa --flavor staging --export-method ad-hoc --export-options-plist ios/ExportOptions.plist
/// ```
class ReleaseIpaCommand extends ShorebirdReleaseBaseCommand {
  @override
  String get name => ShorebirdCommandNames.ipa;

  @override
  String get description => ShorebirdDescriptions.releaseIpa;

  @override
  String get artifactType => 'ipa';
}
