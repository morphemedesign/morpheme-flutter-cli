import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

/// iOS IPA archive build command implementation.
///
/// Creates iOS Application Archive (IPA) files for distribution through
/// App Store, ad-hoc distribution, or enterprise deployment.
///
/// ## Platform Requirements
/// - macOS host system (iOS builds require Xcode)
/// - Xcode and Xcode Command Line Tools
/// - Valid iOS distribution certificates
/// - Appropriate provisioning profiles for distribution
///
/// ## IPA vs iOS Build
/// - iOS build: Creates .app bundle for testing and development
/// - IPA build: Creates .ipa archive for distribution and deployment
///
/// ## Distribution Methods
/// - **app-store**: For App Store submission (requires distribution certificate)
/// - **ad-hoc**: For limited device distribution (up to 100 devices)
/// - **development**: For development team distribution
/// - **enterprise**: For enterprise in-house distribution
///
/// ## Usage Examples
/// ```bash
/// # Build IPA for App Store submission
/// morpheme build ipa --flavor prod --export-method app-store
///
/// # Build ad-hoc IPA for testing
/// morpheme build ipa --flavor staging --export-method ad-hoc
///
/// # Build with custom export options
/// morpheme build ipa --export-options-plist ExportOptions.plist
/// ```
class IpaCommand extends BuildCommandBase {
  IpaCommand() : super() {
    argParser.addOptionExportMethod();
    argParser.addOptionExportOptionsPlist();
  }

  @override
  String get name => 'ipa';

  @override
  String get description => 'Archive ios ipa with flavor.';

  @override
  String get buildTarget => 'ipa';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argExportMethod = argResults.getOptionExportMethod();
    final argExportOptionsPlist = argResults.getOptionExportOptionsPlist();
    return '$baseCommand $argExportMethod $argExportOptionsPlist';
  }
}
