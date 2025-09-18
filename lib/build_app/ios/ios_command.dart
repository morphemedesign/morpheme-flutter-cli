import 'dart:io';

import 'package:morpheme_cli/build_app/base/base.dart';
import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

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
/// ## Configuration
/// Uses morpheme.yaml for iOS-specific configuration:
/// ```yaml
/// ios:
///   prod:
///     codesign: true
///     provisioning:
///       teamId: "XXXXXXXXXX"
///       provisioningProfile: "Profile Name"
/// ```
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
class IosCommand extends BaseBuildCommand {
  @override
  String get name => 'ios';

  @override
  String get description =>
      'Build iOS application bundle (macOS host required).';

  @override
  String get platformName => 'iOS';

  @override
  bool get requiresMacOS => true;

  @override
  void configurePlatformArguments() {
    super.configurePlatformArguments();
    argParser.addFlagCodesign();
  }

  @override
  ValidationResult<bool> validatePlatformEnvironment() {
    // Check for Xcode installation
    if (which('xcodebuild').notfound) {
      return ValidationResult.error(
        'Xcode command line tools not found',
        suggestion: 'Install Xcode and command line tools',
        examples: [
          'xcode-select --install',
          'sudo xcode-select --switch /Applications/Xcode.app',
          'xcodebuild -version',
        ],
      );
    }

    // Check Xcode license agreement
    try {
      final result = Process.runSync('xcodebuild', ['-checkFirstLaunchStatus']);
      if (result.exitCode != 0) {
        return ValidationResult.error(
          'Xcode license agreement not accepted',
          suggestion: 'Accept Xcode license agreement',
          examples: [
            'sudo xcodebuild -license accept',
            'sudo xcodebuild -runFirstLaunch',
          ],
        );
      }
    } catch (e) {
      // License check failed, but continue - this might not be critical
      BuildProgressReporter.reportWarning(
        'Could not verify Xcode license status: $e',
      );
    }

    // Check for iOS SDK
    try {
      final result = Process.runSync('xcodebuild', ['-showsdks']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (!output.contains('iOS')) {
          return ValidationResult.error(
            'iOS SDK not found in Xcode installation',
            suggestion: 'Install iOS SDK through Xcode',
            examples: [
              'xcodebuild -showsdks',
              'Open Xcode and install iOS platform',
            ],
          );
        }
      }
    } catch (e) {
      BuildProgressReporter.reportWarning(
        'Could not verify iOS SDK availability: $e',
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePlatformBuild(BuildConfiguration config) async {
    try {
      final codesign = argResults?.getFlagCodesign() ?? true;
      final codesignBool = codesign as bool;

      BuildProgressReporter.reportBuildEnvironment(platformName, {
        'flavor': config.flavor,
        'mode': config.mode.displayName,
        'target': config.target,
        'codesign': codesignBool,
        'obfuscate': config.obfuscate,
      });

      // Validate iOS configuration
      if (config.iosConfig != null) {
        _validateIosConfiguration(config.iosConfig!, codesignBool);
      }

      // Build Flutter arguments for iOS
      final arguments = buildFlutterArguments(config, 'ios');

      // Add iOS-specific arguments
      if (codesignBool) {
        arguments.add('--codesign');
      } else {
        arguments.add('--no-codesign');
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.compilation,
        0.1,
        estimatedRemaining: Duration(minutes: 5),
      );

      // Execute Flutter build command
      await FlutterHelper.run(
        arguments.join(' '),
        showLog: true,
      );

      if (codesignBool) {
        BuildProgressReporter.reportBuildStage(
          BuildStage.signing,
          0.8,
          estimatedRemaining: Duration(minutes: 1),
        );
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.packaging,
        0.9,
        estimatedRemaining: Duration(seconds: 30),
      );

      // Report build artifacts
      final appPath = _findGeneratedApp();
      if (appPath != null) {
        final artifacts = [
          BuildArtifact(
            type: 'iOS App',
            path: appPath,
            metadata: {
              'format': 'iOS Application Bundle',
              'codesigned': codesignBool,
              'platform': 'iOS',
            },
          ),
        ];

        BuildProgressReporter.reportBuildArtifacts(artifacts);

        // Provide deployment guidance
        _reportDeploymentInfo(appPath, codesignBool);
      }
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildProcessFailure,
        'iOS build failed',
        platform: platformName,
        suggestion: 'Check build logs and iOS configuration',
        examples: [
          'flutter clean',
          'flutter pub get',
          'morpheme doctor',
        ],
        diagnosticCommands: [
          'flutter doctor',
          'xcodebuild -version',
          'security find-identity -v -p codesigning',
        ],
        recoverySteps: [
          'Clean the project with "flutter clean"',
          'Get dependencies with "flutter pub get"',
          'Check Xcode and iOS SDK installation',
          'Verify code signing certificates if using --codesign',
        ],
      );
    }
  }

  /// Validates iOS-specific configuration.
  ///
  /// Checks provisioning profiles, certificates, and other
  /// iOS-specific build requirements.
  void _validateIosConfiguration(IosBuildConfig iosConfig, bool codesign) {
    if (codesign && iosConfig.provisioningConfig != null) {
      final provisioning = iosConfig.provisioningConfig!;

      // Check for valid team ID format
      if (provisioning.teamId.length != 10) {
        BuildProgressReporter.reportWarning(
          'Team ID should be 10 characters long: ${provisioning.teamId}',
        );
      }

      // Check for code signing identity availability
      try {
        final result = Process.runSync(
            'security', ['find-identity', '-v', '-p', 'codesigning']);

        if (result.exitCode == 0) {
          final identities = result.stdout.toString();
          if (!identities.contains('valid identities found')) {
            BuildProgressReporter.reportWarning(
              'No valid code signing identities found',
            );
          }
        }
      } catch (e) {
        BuildProgressReporter.reportWarning(
          'Could not check code signing identities: $e',
        );
      }
    }
  }

  /// Finds the generated iOS application bundle.
  ///
  /// Searches for the built .app bundle in common output locations.
  ///
  /// Returns: Path to .app bundle or null if not found
  String? _findGeneratedApp() {
    final commonPaths = [
      'build/ios/iphoneos/Runner.app',
      'build/ios/iphonesimulator/Runner.app',
      'ios/build/Build/Products/Release-iphoneos/Runner.app',
      'ios/build/Build/Products/Debug-iphoneos/Runner.app',
      'ios/build/Build/Products/Release-iphonesimulator/Runner.app',
      'ios/build/Build/Products/Debug-iphonesimulator/Runner.app',
    ];

    for (final path in commonPaths) {
      if (exists(path)) {
        return path;
      }
    }

    // Search for any .app bundles in the build directory
    final buildDirs = ['build/ios', 'ios/build'];

    for (final buildDir in buildDirs) {
      if (exists(buildDir)) {
        try {
          final directory = Directory(buildDir);
          final appBundles = directory
              .listSync(recursive: true)
              .whereType<Directory>()
              .where((dir) => dir.path.endsWith('.app'))
              .toList();

          if (appBundles.isNotEmpty) {
            // Return the most recently modified app bundle
            appBundles.sort((a, b) =>
                b.statSync().modified.compareTo(a.statSync().modified));
            return appBundles.first.path;
          }
        } catch (e) {
          // Ignore errors when searching for app bundles
        }
      }
    }

    return null;
  }

  /// Reports iOS deployment information and recommendations.
  ///
  /// Provides guidance on how to deploy the built iOS application
  /// to devices or simulators.
  void _reportDeploymentInfo(String appPath, bool codesigned) {
    printMessage('\n📱 iOS Application Information:');
    printMessage('   Generated: $appPath');

    if (codesigned) {
      printMessage('   Code signed: Yes');
      printMessage('   Ready for device deployment');

      printMessage('\n🚀 Deployment options:');
      printMessage('   # Install on connected device');
      printMessage('   flutter install');
      printMessage('   # Or use Xcode for advanced deployment options');
    } else {
      printMessage('   Code signed: No');
      printMessage('   Simulator only - not signed for device deployment');

      printMessage('\n🧪 Simulator deployment:');
      printMessage('   # Run on iOS simulator');
      printMessage('   flutter run -d ios');
      printMessage('   # Or open Simulator.app and drag the .app bundle');
    }

    // Check for connected devices
    try {
      final result = Process.runSync('flutter', ['devices']);
      if (result.exitCode == 0) {
        final devices = result.stdout.toString();
        if (devices.contains('ios')) {
          printMessage('\n📱 Connected iOS devices found');
        }
      }
    } catch (e) {
      // Ignore device check errors
    }
  }
}
