import 'dart:io';

import 'package:morpheme_cli/build_app/base/base_prebuild_command.dart';
import 'package:morpheme_cli/build_app/base/build_error_handler.dart';
import 'package:morpheme_cli/dependency_manager.dart';
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
class PreBuildIosCommand extends BasePrebuildCommand {
  @override
  String get name => 'ios';

  @override
  String get description =>
      'Prepare iOS project for build operations (macOS required).';

  @override
  String get platformName => 'iOS';

  @override
  bool get requiresMacOS => true;

  @override
  String get deploymentConfigPath =>
      join(current, 'ios', 'deployment', 'appstore_deployment.json');

  @override
  ValidationResult<bool> validatePrebuildEnvironment() {
    // Check for iOS project structure
    final iosDir = join(current, 'ios');
    if (!exists(iosDir)) {
      return ValidationResult.error(
        'iOS project directory not found',
        suggestion:
            'Ensure this is run from a Flutter project with iOS support',
        examples: [
          'flutter create --platforms ios .',
          'ls ios/',
        ],
      );
    }

    // Check for Xcode project
    final xcodeProjectPath = join(iosDir, 'Runner.xcodeproj');
    if (!exists(xcodeProjectPath)) {
      return ValidationResult.error(
        'Xcode project not found',
        suggestion: 'Ensure iOS project is properly configured',
        examples: [
          'ls ios/',
          'flutter doctor',
        ],
      );
    }

    // Check for project.pbxproj
    final pbxprojPath = join(xcodeProjectPath, 'project.pbxproj');
    if (!exists(pbxprojPath)) {
      return ValidationResult.error(
        'Xcode project configuration not found',
        suggestion: 'Xcode project may be corrupted or incomplete',
        examples: [
          'ls ios/Runner.xcodeproj/',
          'xcodebuild -list -project ios/Runner.xcodeproj',
        ],
      );
    }

    // Check for deployment configuration
    if (!exists(deploymentConfigPath)) {
      return ValidationResult.error(
        'App Store deployment configuration not found: $deploymentConfigPath',
        suggestion: 'Create deployment configuration file',
        examples: [
          'mkdir -p ios/deployment',
          'Create appstore_deployment.json with team and provisioning info',
        ],
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePreBuildSetup(PrebuildConfiguration config) async {
    try {
      // Extract iOS bundle ID from flavor config
      final bundleId = config.flavorConfig['IOS_APPLICATION_ID'];

      validateRequiredConfig(
        bundleId,
        'IOS_APPLICATION_ID',
        'iOS prebuild setup',
      );

      // Validate deployment configuration
      if (config.deploymentConfig == null) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'No deployment configuration found for flavor: ${config.flavor}',
          suggestion: 'Add deployment configuration for this flavor',
          examples: [
            'Check ios/deployment/appstore_deployment.json',
            'Ensure flavor "${config.flavor}" is configured',
          ],
        );
      }

      final deploymentConfig = config.deploymentConfig!;

      // Setup iOS prebuild components
      await _setupFastlane(bundleId.toString(), deploymentConfig);
      await _setupProjectIos(bundleId.toString(), deploymentConfig);
      await _setupExportOptions(bundleId.toString(), deploymentConfig);

      // Validate final setup
      await _validateSetupCompletion(deploymentConfig);
    } catch (e) {
      if (e is BuildCommandException) rethrow;

      throw BuildCommandException(
        BuildCommandError.environmentSetupFailure,
        'Failed to setup iOS prebuild environment',
        platform: platformName,
        suggestion: 'Check iOS project configuration and deployment settings',
        examples: [
          'ls ios/',
          'cat ios/deployment/appstore_deployment.json',
          'xcodebuild -version',
        ],
        recoverySteps: [
          'Ensure iOS project structure is valid',
          'Check IOS_APPLICATION_ID in morpheme.yaml',
          'Verify deployment configuration file exists and is valid',
          'Check team ID and provisioning profile settings',
        ],
      );
    }
  }

  /// Sets up Fastlane configuration for iOS deployment.
  ///
  /// Creates the Appfile with App Store Connect credentials,
  /// team IDs, and application identifier.
  ///
  /// Parameters:
  /// - [bundleId]: iOS application bundle identifier
  /// - [deploymentConfig]: App Store deployment configuration
  Future<void> _setupFastlane(
      String bundleId, Map<String, dynamic> deploymentConfig) async {
    // Validate required deployment configuration fields
    final requiredFields = ['email_identity', 'itc_team_id', 'team_id'];
    for (final field in requiredFields) {
      validateRequiredConfig(
        deploymentConfig[field],
        field,
        'Fastlane configuration',
      );
    }

    final fastlaneDir = join(current, 'ios', 'fastlane');
    final appFilePath = join(fastlaneDir, 'Appfile');

    final content =
        '''app_identifier("$bundleId") # The bundle identifier of your app
apple_id("${deploymentConfig['email_identity']}") # Your Apple email address

itc_team_id("${deploymentConfig['itc_team_id']}") # App Store Connect Team ID
team_id("${deploymentConfig['team_id']}") # Developer Portal Team ID

# For more information about the Appfile, see:
#     https://docs.fastlane.tools/advanced/#appfile''';

    generateConfigFile(
      appFilePath,
      content,
      'Fastlane Appfile for iOS deployment',
    );
  }

  /// Sets up Xcode project configuration.
  ///
  /// Updates the project.pbxproj file with proper code signing settings,
  /// bundle identifier, team ID, and provisioning profile configuration.
  ///
  /// Parameters:
  /// - [bundleId]: iOS application bundle identifier
  /// - [deploymentConfig]: App Store deployment configuration
  Future<void> _setupProjectIos(
      String bundleId, Map<String, dynamic> deploymentConfig) async {
    final projectPath =
        join(current, 'ios', 'Runner.xcodeproj', 'project.pbxproj');

    // Define replacement patterns for Xcode project settings
    final replacements = <String, String>{
      // Code signing identity
      r'"?CODE_SIGN_IDENTITY"?(\s+)?=(\s+)?"?.+"?;':
          'CODE_SIGN_IDENTITY = "iPhone Distribution";',
      r'"?CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;':
          '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Distribution";',

      // Development team
      r'"?DEVELOPMENT_TEAM"?(\s+)?=(\s+)?"?.+"?;':
          'DEVELOPMENT_TEAM = ${deploymentConfig['team_id']};',
      r'"?DEVELOPMENT_TEAM\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;':
          '"DEVELOPMENT_TEAM[sdk=iphoneos*]" = ${deploymentConfig['team_id']};',

      // Product bundle identifier
      r'"?PRODUCT_BUNDLE_IDENTIFIER"?(\s+)?=(\s+)?"?.+"?;':
          'PRODUCT_BUNDLE_IDENTIFIER = "\${IOS_APPLICATION_ID}";',
      r'"?PRODUCT_BUNDLE_IDENTIFIER\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;':
          '"PRODUCT_BUNDLE_IDENTIFIER[sdk=iphoneos*]" = "\${IOS_APPLICATION_ID}";',

      // Provisioning profile
      r'"?PROVISIONING_PROFILE_SPECIFIER"?(\s+)?=(\s+)?"?.+"?;':
          'PROVISIONING_PROFILE_SPECIFIER = "${deploymentConfig['provisioning_profiles']}";',
      r'"?PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]"?(\s+)?=(\s+)?"?.+"?;':
          '"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]" = "${deploymentConfig['provisioning_profiles']}";',
    };

    updateConfigFile(
      projectPath,
      replacements,
      'Xcode project settings',
    );
  }

  /// Sets up export options plist for IPA generation.
  ///
  /// Creates ExportOptions.plist with proper export method,
  /// team ID, and provisioning profile configuration.
  ///
  /// Parameters:
  /// - [bundleId]: iOS application bundle identifier
  /// - [deploymentConfig]: App Store deployment configuration
  Future<void> _setupExportOptions(
      String bundleId, Map<String, dynamic> deploymentConfig) async {
    final exportOptionsPath = join(current, 'ios', 'ExportOptions.plist');

    final content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${deploymentConfig['team_id']}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$bundleId</key>
        <string>${deploymentConfig['provisioning_profiles']}</string>
    </dict>
 </dict>
 </plist>''';

    generateConfigFile(
      exportOptionsPath,
      content,
      'Export options plist for IPA generation',
    );
  }

  /// Validates the complete prebuild setup.
  ///
  /// Performs final validation of all generated files and
  /// provides guidance for next steps.
  ///
  /// Parameters:
  /// - [deploymentConfig]: App Store deployment configuration
  Future<void> _validateSetupCompletion(
      Map<String, dynamic> deploymentConfig) async {
    final teamId = deploymentConfig['team_id'];
    final provisioningProfile = deploymentConfig['provisioning_profiles'];

    printMessage('\n🎉 iOS prebuild setup completed successfully!');
    printMessage('\n📝 Configuration summary:');
    printMessage('   Team ID: $teamId');
    printMessage('   Provisioning Profile: $provisioningProfile');

    printMessage('\n🔍 Next steps:');
    printMessage(
        '   1. Ensure provisioning profile is installed on this machine');
    printMessage('   2. Verify code signing certificates are available');
    printMessage(
        '   3. Test build with: morpheme build ipa --flavor ${deploymentConfig.keys.first}');

    // Check for provisioning profiles directory
    final provisioningDir = join(
      Platform.environment['HOME'] ?? '',
      'Library',
      'MobileDevice',
      'Provisioning Profiles',
    );

    if (exists(provisioningDir)) {
      final profiles = Directory(provisioningDir)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.mobileprovision'))
          .length;

      if (profiles > 0) {
        printMessage('\n✅ Found $profiles provisioning profile(s) installed');
      } else {
        printMessage(
            '\n⚠️  No provisioning profiles found in ~/Library/MobileDevice/Provisioning\\ Profiles/');
        printMessage(
            '   Install profiles through Xcode or Apple Developer Portal');
      }
    }

    // Check for code signing identities
    try {
      final result = Process.runSync(
          'security', ['find-identity', '-v', '-p', 'codesigning']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.contains('valid identities found')) {
          final identityCount = output
              .split('\n')
              .where((line) =>
                  line.contains('Distribution') || line.contains('Developer'))
              .length;
          printMessage('\n✅ Found $identityCount code signing identit(ies)');
        } else {
          printMessage('\n⚠️  No code signing identities found');
          printMessage(
              '   Install certificates through Xcode or Keychain Access');
        }
      }
    } catch (e) {
      printMessage('\n⚠️  Could not verify code signing setup: $e');
    }
  }
}
