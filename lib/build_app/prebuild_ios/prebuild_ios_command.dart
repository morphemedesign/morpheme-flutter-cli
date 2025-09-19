import 'dart:convert';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// iOS prebuild setup command implementation.
///
/// Prepares iOS project for build operations by configuring
/// Fastlane deployment settings, Xcode project settings,
/// provisioning profiles, and export options.
///
/// ## Platform Requirements
/// - macOS host system (iOS builds require Xcode)
/// - Xcode and Xcode Command Line Tools
/// - Valid iOS project structure
/// - App Store deployment configuration file
///
/// ## Configuration Files
/// - **Fastlane Appfile**: App Store Connect and team configuration
/// - **project.pbxproj**: Xcode project signing and bundle settings
/// - **ExportOptions.plist**: IPA export configuration
///
/// ## Deployment Configuration
/// Requires `ios/deployment/appstore_deployment.json`:
/// ```json
/// {
///   "prod": {
///     "email_identity": "developer@example.com",
///     "itc_team_id": "12345678",
///     "team_id": "ABCDEFGHIJ",
///     "provisioning_profiles": "App Store Profile"
///   }
/// }
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Setup iOS prebuild for production
/// morpheme prebuild ios --flavor prod
///
/// # Setup with development flavor
/// morpheme prebuild ios --flavor dev
/// ```
class PreBuildIosCommand extends Command {
  PreBuildIosCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'ios';

  @override
  String get description => 'Prepare setup ios before build';

  @override
  void run() async {
    _validateInputs();
    _prepareConfiguration();
    _setupIOS();
    _reportSuccess();
  }

  void _validateInputs() {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final pathAppstoreDeployment =
        join(current, 'ios', 'deployment', 'appstore_deployment.json');
    if (!exists(pathAppstoreDeployment)) {
      StatusHelper.failed('$pathAppstoreDeployment is not found!');
    }
  }

  void _prepareConfiguration() {
    // Any preparation logic specific to iOS prebuild
  }

  void _setupIOS() {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    final pathAppstoreDeployment =
        join(current, 'ios', 'deployment', 'appstore_deployment.json');
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    final Map appstoreDeployment =
        jsonDecode(readFile(pathAppstoreDeployment))[argFlavor];
    final bundleId = morphemeYaml['flavor'][argFlavor]['IOS_APPLICATION_ID'];

    _setupFastlane(bundleId, appstoreDeployment);
    _setupProjectIos(bundleId, appstoreDeployment);
    _setupExportOptions(bundleId, appstoreDeployment);
  }

  void _setupFastlane(String bundleId, Map appstoreDeployment) {
    final path = join(current, 'ios', 'fastlane', 'Appfile');
    path.write(
        '''app_identifier("$bundleId") # The bundle identifier of your app
apple_id("${appstoreDeployment['email_identity']}") # Your Apple email address

itc_team_id("${appstoreDeployment['itc_team_id']}") # App Store Connect Team ID
team_id("${appstoreDeployment['team_id']}") # Developer Portal Team ID

# For more information about the Appfile, see:
#     https://docs.fastlane.tools/advanced/#appfile''');

    StatusHelper.generated(path);
  }

  void _setupProjectIos(String bundleId, Map appstoreDeployment) {
    final path = join(current, 'ios', 'Runner.xcodeproj', 'project.pbxproj');

    String file = readFile(path);
    file = file.replaceAll(
        RegExp(r'"?CODE_SIGN_IDENTITY"?(\s+)?=(\s+)?"?.+"?;'),
        'CODE_SIGN_IDENTITY = "iPhone Distribution";');
    file = file.replaceAll(
        RegExp(r'"?CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;'),
        '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Distribution";');
    file = file.replaceAll(RegExp(r'"?DEVELOPMENT_TEAM"?(\s+)?=(\s+)?"?.+"?;'),
        'DEVELOPMENT_TEAM = ${appstoreDeployment['team_id']};');
    file = file.replaceAll(
        RegExp(r'"?DEVELOPMENT_TEAM\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;'),
        '"DEVELOPMENT_TEAM[sdk=iphoneos*]" = ${appstoreDeployment['team_id']};');
    file = file.replaceAll(
        RegExp(r'"?PRODUCT_BUNDLE_IDENTIFIER"?(\s+)?=(\s+)?"?.+"?;'),
        'PRODUCT_BUNDLE_IDENTIFIER = "\${IOS_APPLICATION_ID}";');
    file = file.replaceAll(
        RegExp(
            r'"?PRODUCT_BUNDLE_IDENTIFIER\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;'),
        '"PRODUCT_BUNDLE_IDENTIFIER[sdk=iphoneos*]" = "\${IOS_APPLICATION_ID}";');
    file = file.replaceAll(
        RegExp(r'"?PROVISIONING_PROFILE_SPECIFIER"?(\s+)?=(\s+)?"?.+"?;'),
        'PROVISIONING_PROFILE_SPECIFIER = "${appstoreDeployment['provisioning_profiles']}";');
    file = file.replaceAll(
        RegExp(
            r'"?PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;'),
        '"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]" = "${appstoreDeployment['provisioning_profiles']}";');

    path.write(file);
    StatusHelper.generated(path);
  }

  void _setupExportOptions(String bundleId, Map appstoreDeployment) {
    final path = join(current, 'ios', 'ExportOptions.plist');

    path.write('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${appstoreDeployment['team_id']}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$bundleId</key>
        <string>${appstoreDeployment['provisioning_profiles']}</string>
    </dict>
 </dict>
 </plist>''');

    StatusHelper.generated(path);
  }

  void _reportSuccess() {
    StatusHelper.success('prebuild ios');
  }
}
