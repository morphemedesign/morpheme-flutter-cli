import 'dart:io';

import 'package:morpheme_cli/build_app/base/base.dart';
import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

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
/// ## Configuration
/// Uses morpheme.yaml and appstore_deployment.json for configuration:
/// ```yaml
/// ios:
///   prod:
///     exportMethod: "app-store"
///     provisioning:
///       teamId: "XXXXXXXXXX"
///       provisioningProfile: "App Store Profile"
/// ```
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
class IpaCommand extends BaseBuildCommand {
  @override
  String get name => 'ipa';

  @override
  String get description =>
      'Build iOS IPA archive for distribution (macOS host required).';

  @override
  String get platformName => 'iOS IPA';

  @override
  bool get requiresMacOS => true;

  @override
  void configurePlatformArguments() {
    super.configurePlatformArguments();
    argParser.addOptionExportMethod();
    argParser.addOptionExportOptionsPlist();
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

    // Check for code signing certificates
    try {
      final result = Process.runSync(
          'security', ['find-identity', '-v', '-p', 'codesigning']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (!output.contains('valid identities found')) {
          return ValidationResult.error(
            'No valid code signing identities found',
            suggestion: 'Install iOS development or distribution certificates',
            examples: [
              'security find-identity -v -p codesigning',
              'Open Keychain Access and install certificates',
              'Download certificates from Apple Developer Portal',
            ],
          );
        }
      }
    } catch (e) {
      BuildProgressReporter.reportWarning(
        'Could not verify code signing certificates: $e',
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePlatformBuild(BuildConfiguration config) async {
    try {
      final exportMethod = argResults?.getOptionExportMethod();
      final exportOptionsPlist = argResults?.getOptionExportOptionsPlist();

      BuildProgressReporter.reportBuildEnvironment(platformName, {
        'flavor': config.flavor,
        'mode': config.mode.displayName,
        'target': config.target,
        'exportMethod': exportMethod ?? 'auto',
        'obfuscate': config.obfuscate,
      });

      // Validate IPA configuration
      if (config.iosConfig != null) {
        _validateIpaConfiguration(config.iosConfig!, exportMethod);
      }

      // Validate export options plist if provided
      if (exportOptionsPlist != null && !exists(exportOptionsPlist)) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'Export options plist not found: $exportOptionsPlist',
          suggestion: 'Create export options plist or check file path',
          examples: [
            'ls $exportOptionsPlist',
            'xcodebuild -h | grep exportOptionsPlist',
          ],
        );
      }

      // Build Flutter arguments for IPA
      final arguments = buildFlutterArguments(config, 'ipa');

      // Add IPA-specific arguments
      if (exportMethod != null && exportMethod.isNotEmpty) {
        arguments.addAll(['--export-method', exportMethod]);
      }

      if (exportOptionsPlist != null && exportOptionsPlist.isNotEmpty) {
        arguments.addAll(['--export-options-plist', exportOptionsPlist]);
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.compilation,
        0.1,
        estimatedRemaining: Duration(minutes: 6),
      );

      // Execute Flutter build command
      await FlutterHelper.run(
        arguments.join(' '),
        showLog: true,
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.signing,
        0.7,
        estimatedRemaining: Duration(minutes: 2),
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.packaging,
        0.9,
        estimatedRemaining: Duration(seconds: 45),
      );

      // Report build artifacts
      final ipaPath = _findGeneratedIpa();
      if (ipaPath != null) {
        final ipaFile = File(ipaPath);
        final artifacts = [
          BuildArtifact(
            type: 'IPA',
            path: ipaPath,
            sizeBytes: ipaFile.existsSync() ? ipaFile.lengthSync() : null,
            metadata: {
              'format': 'iOS Application Archive',
              'exportMethod': exportMethod ?? 'auto',
              'distribution': true,
            },
          ),
        ];

        BuildProgressReporter.reportBuildArtifacts(artifacts);

        // Provide distribution guidance
        _reportDistributionInfo(ipaPath, exportMethod);
      }
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildProcessFailure,
        'iOS IPA build failed',
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
          'ls ~/Library/MobileDevice/Provisioning\\ Profiles/',
        ],
        recoverySteps: [
          'Clean the project with "flutter clean"',
          'Get dependencies with "flutter pub get"',
          'Check Xcode and iOS SDK installation',
          'Verify distribution certificates and provisioning profiles',
          'Check export method and provisioning profile compatibility',
        ],
      );
    }
  }

  /// Validates IPA-specific configuration.
  ///
  /// Checks export method, provisioning profiles, and certificates
  /// required for IPA distribution.
  void _validateIpaConfiguration(
      IosBuildConfig iosConfig, String? exportMethod) {
    if (exportMethod != null) {
      final validMethods = ['app-store', 'ad-hoc', 'development', 'enterprise'];
      if (!validMethods.contains(exportMethod)) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'Invalid export method: $exportMethod',
          suggestion: 'Use one of the supported export methods',
          examples: validMethods,
        );
      }
    }

    // Validate provisioning configuration for distribution
    if (iosConfig.provisioningConfig != null) {
      final provisioning = iosConfig.provisioningConfig!;

      if (provisioning.teamId.isEmpty) {
        throw BuildCommandException(
          BuildCommandError.signingConfigurationInvalid,
          'Team ID is required for IPA distribution',
          suggestion: 'Configure team ID in morpheme.yaml ios section',
          examples: ['teamId: "XXXXXXXXXX"'],
        );
      }

      if (provisioning.provisioningProfile.isEmpty) {
        BuildProgressReporter.reportWarning(
          'Provisioning profile not specified - using automatic signing',
        );
      }
    }

    // Check for distribution certificates if building for distribution
    if (exportMethod == 'app-store' || exportMethod == 'ad-hoc') {
      try {
        final result = Process.runSync(
            'security', ['find-identity', '-v', '-p', 'codesigning']);

        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          if (!output.contains('Distribution')) {
            BuildProgressReporter.reportWarning(
              'No distribution certificates found - may cause signing issues',
            );
          }
        }
      } catch (e) {
        BuildProgressReporter.reportWarning(
          'Could not verify distribution certificates: $e',
        );
      }
    }
  }

  /// Finds the generated IPA file.
  ///
  /// Searches for the built .ipa file in common output locations.
  ///
  /// Returns: Path to .ipa file or null if not found
  String? _findGeneratedIpa() {
    final commonPaths = [
      'build/ios/ipa/Runner.ipa',
      'build/ios/archive/Runner.ipa',
      'ios/build/Runner.ipa',
    ];

    for (final path in commonPaths) {
      if (exists(path)) {
        return path;
      }
    }

    // Search for any .ipa files in the build directory
    final buildDirs = ['build/ios', 'ios/build'];

    for (final buildDir in buildDirs) {
      if (exists(buildDir)) {
        try {
          final directory = Directory(buildDir);
          final ipaFiles = directory
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.ipa'))
              .toList();

          if (ipaFiles.isNotEmpty) {
            // Return the most recently modified IPA
            ipaFiles.sort(
                (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
            return ipaFiles.first.path;
          }
        } catch (e) {
          // Ignore errors when searching for IPA files
        }
      }
    }

    return null;
  }

  /// Reports IPA distribution information and recommendations.
  ///
  /// Provides guidance on how to distribute the built IPA file
  /// based on the export method used.
  void _reportDistributionInfo(String ipaPath, String? exportMethod) {
    printMessage('\n📦 iOS IPA Information:');
    printMessage('   Generated: $ipaPath');
    printMessage('   Export method: ${exportMethod ?? "auto"}');

    switch (exportMethod) {
      case 'app-store':
        printMessage('   Distribution: App Store');
        printMessage('\n🏦 App Store submission:');
        printMessage('   1. Open Xcode and use "Distribute App" feature');
        printMessage('   2. Or use Application Loader / Transporter');
        printMessage('   3. Upload to App Store Connect for review');
        break;

      case 'ad-hoc':
        printMessage('   Distribution: Ad-Hoc (up to 100 devices)');
        printMessage('\n📧 Ad-Hoc distribution:');
        printMessage('   1. Share IPA file with registered device owners');
        printMessage('   2. Install via iTunes, Apple Configurator, or OTA');
        printMessage(
            '   3. Ensure devices are registered in provisioning profile');
        break;

      case 'development':
        printMessage('   Distribution: Development team');
        printMessage('\n👥 Development distribution:');
        printMessage('   1. Share with development team members');
        printMessage('   2. Install on development devices');
        printMessage('   3. Use for testing and debugging');
        break;

      case 'enterprise':
        printMessage('   Distribution: Enterprise (in-house)');
        printMessage('\n🏢 Enterprise distribution:');
        printMessage('   1. Distribute within your organization');
        printMessage('   2. Install via MDM or enterprise app catalog');
        printMessage('   3. No device registration limit');
        break;

      default:
        printMessage('\n🚀 Distribution options:');
        printMessage('   - Use with compatible provisioning profile');
        printMessage('   - Check export method for distribution type');
    }

    // Provide additional tools information
    printMessage('\n🧠 Additional tools:');
    printMessage('   # Verify IPA contents');
    printMessage('   unzip -l "$ipaPath"');
    printMessage('   # Check app info');
    printMessage('   plutil -p "Payload/Runner.app/Info.plist"');
  }
}
