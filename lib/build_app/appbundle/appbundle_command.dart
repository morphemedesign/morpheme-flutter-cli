import 'dart:io';

import 'package:morpheme_cli/build_app/base/base.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Android App Bundle build command implementation.
///
/// Builds Android App Bundle (AAB) files optimized for Google Play Store
/// distribution with dynamic delivery support and size optimizations.
///
/// ## Platform Requirements
/// - Android SDK and tools
/// - Flutter SDK with Android support
/// - Valid Android project configuration
/// - Android Gradle Plugin 3.2+ for App Bundle support
///
/// ## App Bundle Benefits
/// - Smaller download sizes through dynamic delivery
/// - Automatic APK generation by Google Play
/// - Enhanced security and optimization
/// - Support for feature modules and asset packs
///
/// ## Configuration
/// Uses morpheme.yaml for flavor and build configuration:
/// ```yaml
/// android:
///   prod:
///     buildAppBundle: true
///     signing:
///       keystorePath: "release.keystore"
///       keyAlias: "release"
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Build release App Bundle for production
/// morpheme build appbundle --flavor prod --release
///
/// # Build with custom signing configuration
/// morpheme build appbundle --flavor staging --build-number 42
/// ```
class AppbundleCommand extends BaseBuildCommand {
  @override
  String get name => 'appbundle';

  @override
  String get description =>
      'Build Android App Bundle (AAB) with flavor support.';

  @override
  String get platformName => 'Android App Bundle';

  @override
  ValidationResult<bool> validatePlatformEnvironment() {
    // Check for Android SDK
    final androidHome = Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];

    if (androidHome == null || androidHome.isEmpty) {
      return ValidationResult.error(
        'Android SDK not found',
        suggestion:
            'Install Android SDK and set ANDROID_HOME environment variable',
        examples: [
          'export ANDROID_HOME=/path/to/android/sdk',
          'flutter doctor',
          'morpheme doctor',
        ],
      );
    }

    // Check for Gradle (required for App Bundle builds)
    if (which('gradle').notfound) {
      // Check if gradlew exists in project
      if (!exists('./gradlew') && !exists('./android/gradlew')) {
        return ValidationResult.error(
          'Gradle not found',
          suggestion:
              'Install Gradle or ensure gradlew is available in project',
          examples: [
            'brew install gradle',
            'cd android && ./gradlew --version',
            'flutter doctor',
          ],
        );
      }
    }

    // Check for bundletool (optional but recommended for testing)
    if (which('bundletool').notfound) {
      BuildProgressReporter.reportWarning(
        'bundletool not found - install for local AAB testing',
        severity: 'INFO',
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePlatformBuild(BuildConfiguration config) async {
    try {
      BuildProgressReporter.reportBuildEnvironment(platformName, {
        'flavor': config.flavor,
        'mode': config.mode.displayName,
        'target': config.target,
        'obfuscate': config.obfuscate,
        'appBundle': true,
      });

      // Build Flutter arguments for App Bundle
      final arguments = buildFlutterArguments(config, 'appbundle');

      // Add Android-specific configurations
      if (config.androidConfig != null) {
        final androidConfig = config.androidConfig!;

        // Validate signing configuration for release builds
        if (config.mode == BuildMode.release &&
            androidConfig.signingConfig != null) {
          _validateSigningConfiguration(androidConfig.signingConfig!);
        }

        // Report App Bundle optimization info
        if (androidConfig.buildAppBundle) {
          BuildProgressReporter.reportPreparationStep(
            'App Bundle optimization enabled',
            true,
          );
        }
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.compilation,
        0.1,
        estimatedRemaining: Duration(minutes: 4),
      );

      // Execute Flutter build command
      await FlutterHelper.run(
        arguments.join(' '),
        showLog: true,
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.packaging,
        0.9,
        estimatedRemaining: Duration(seconds: 45),
      );

      // Report build artifacts
      final aabPath = _findGeneratedAppBundle();
      if (aabPath != null) {
        final aabFile = File(aabPath);
        final artifacts = [
          BuildArtifact(
            type: 'AAB',
            path: aabPath,
            sizeBytes: aabFile.existsSync() ? aabFile.lengthSync() : null,
            metadata: {
              'format': 'Android App Bundle',
              'optimized': true,
              'dynamicDelivery': true,
            },
          ),
        ];

        BuildProgressReporter.reportBuildArtifacts(artifacts);

        // Provide additional App Bundle information
        _reportAppBundleInfo(aabPath);
      }
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildProcessFailure,
        'Android App Bundle build failed',
        platform: platformName,
        suggestion: 'Check build logs and Android configuration',
        examples: [
          'flutter clean',
          'flutter pub get',
          'morpheme doctor',
        ],
        diagnosticCommands: [
          'flutter doctor',
          'gradle --version',
          'cd android && ./gradlew --version',
        ],
        recoverySteps: [
          'Clean the project with "flutter clean"',
          'Get dependencies with "flutter pub get"',
          'Check Android Gradle Plugin version (requires 3.2+)',
          'Verify signing configuration for release builds',
        ],
      );
    }
  }

  /// Validates Android signing configuration.
  ///
  /// Ensures all required signing parameters are present and
  /// the keystore file exists for release builds.
  void _validateSigningConfiguration(AndroidSigningConfig signingConfig) {
    if (signingConfig.keystorePath.isNotEmpty &&
        !exists(signingConfig.keystorePath)) {
      throw BuildCommandException(
        BuildCommandError.signingConfigurationInvalid,
        'Keystore file not found: ${signingConfig.keystorePath}',
        suggestion: 'Create keystore or update path in morpheme.yaml',
        examples: [
          'keytool -genkey -v -keystore release.keystore',
          'ls ${dirname(signingConfig.keystorePath)}',
        ],
      );
    }

    if (signingConfig.keyAlias.isEmpty) {
      throw BuildCommandException(
        BuildCommandError.signingConfigurationInvalid,
        'Key alias is required for signed builds',
        suggestion:
            'Configure key alias in morpheme.yaml android signing section',
      );
    }
  }

  /// Finds the generated App Bundle file path.
  ///
  /// Searches common AAB output locations and returns the path
  /// to the most recently generated App Bundle file.
  ///
  /// Returns: Path to AAB file or null if not found
  String? _findGeneratedAppBundle() {
    final commonPaths = [
      'build/app/outputs/bundle/release/app-release.aab',
      'build/app/outputs/bundle/debug/app-debug.aab',
      'build/app/outputs/bundle/profile/app-profile.aab',
    ];

    for (final path in commonPaths) {
      if (exists(path)) {
        return path;
      }
    }

    // Search for any AAB files in the output directory
    final bundleDir = 'build/app/outputs/bundle';
    if (exists(bundleDir)) {
      try {
        final directory = Directory(bundleDir);
        final aabFiles = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.aab'))
            .toList();

        if (aabFiles.isNotEmpty) {
          // Return the most recently modified AAB
          aabFiles.sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          return aabFiles.first.path;
        }
      } catch (e) {
        // Ignore errors when searching for AAB files
      }
    }

    return null;
  }

  /// Reports additional App Bundle information and recommendations.
  ///
  /// Provides guidance on App Bundle testing, upload, and optimization.
  void _reportAppBundleInfo(String aabPath) {
    printMessage('\n📱 App Bundle Information:');
    printMessage('   Generated: $aabPath');
    printMessage('   Ready for Google Play Store upload');

    if (which('bundletool').found) {
      printMessage('\n🧪 Testing suggestions:');
      printMessage('   # Generate APKs for local testing');
      printMessage(
          '   bundletool build-apks --bundle=$aabPath --output=app.apks');
      printMessage('   # Install on connected device');
      printMessage('   bundletool install-apks --apks=app.apks');
    } else {
      BuildProgressReporter.reportWarning(
        'Install bundletool for local AAB testing: https://github.com/google/bundletool',
      );
    }
  }
}
