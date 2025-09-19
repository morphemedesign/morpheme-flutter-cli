import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

/// iOS application build command implementation.
///
/// Builds iOS application bundles for deployment to devices and simulators
/// with support for code signing, provisioning profiles, and build configuration.
///
/// ## Platform Requirements
/// - macOS host system (iOS builds require Xcode)
/// - Xcode and Xcode Command Line Tools
/// - Valid iOS development or distribution certificates
/// - Appropriate provisioning profiles for target devices
///
/// ## Code Signing
/// For device deployment, proper code signing is essential:
/// - Development builds: Development certificate + development provisioning profile
/// - Distribution builds: Distribution certificate + distribution provisioning profile
/// - Ad-hoc builds: Distribution certificate + ad-hoc provisioning profile
///
/// ## Usage Examples
/// ```bash
/// # Build for iOS simulator (no code signing required)
/// morpheme build ios --flavor dev --debug
///
/// # Build for device with code signing
/// morpheme build ios --flavor prod --release --codesign
///
/// # Build without code signing (simulator only)
/// morpheme build ios --flavor dev --no-codesign
/// ```
class IosCommand extends BuildCommandBase {
  IosCommand() : super() {
    argParser.addFlagCodesign();
  }

  @override
  String get name => 'ios';

  @override
  String get description =>
      'Build an iOS application bundle (Mac OS X host only).';

  @override
  String get buildTarget => 'ios';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argCodesign = argResults.getFlagCodesign();
    return '$baseCommand $argCodesign';
  }
}
