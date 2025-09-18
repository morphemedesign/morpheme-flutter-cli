import '../../../constants/command_names.dart';
import '../../../constants/descriptions.dart';
import '../../../core/base_release_command.dart';

/// Command for releasing iOS applications through Shorebird.
///
/// This command creates a Shorebird release for iOS applications,
/// allowing for over-the-air updates to be deployed to iOS apps.
/// This command creates an iOS application bundle on macOS hosts only.
///
/// ## Usage
///
/// ```bash
/// morpheme shorebird release ios --flavor dev
/// morpheme shorebird release ios --flavor prod --build-number 123
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
/// - `--codesign`: Enable code signing
///
/// ## Platform Requirements
///
/// This command requires macOS and properly configured iOS development
/// environment including:
/// - Xcode
/// - iOS development certificates
/// - Provisioning profiles
///
/// ## Examples
///
/// Basic iOS release:
/// ```bash
/// morpheme shorebird release ios
/// ```
///
/// Production iOS release with code signing:
/// ```bash
/// morpheme shorebird release ios --flavor prod --build-number 42 --build-name 1.2.0 --codesign
/// ```
///
/// iOS release with custom target:
/// ```bash
/// morpheme shorebird release ios --target lib/main_dev.dart --flavor dev
/// ```
class ReleaseIosCommand extends ShorebirdReleaseBaseCommand {
  @override
  String get name => ShorebirdCommandNames.ios;

  @override
  String get description => ShorebirdDescriptions.releaseIos;

  @override
  String get artifactType => 'ios';
}
