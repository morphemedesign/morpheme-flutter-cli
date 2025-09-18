import 'dart:io';

import 'package:morpheme_cli/build_app/base/base.dart';
import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Android APK build command implementation.
///
/// Builds Android APK files with support for multiple flavors,
/// build modes, and advanced configuration options including
/// obfuscation and debug information splitting.
///
/// ## Platform Requirements
/// - Android SDK and tools
/// - Flutter SDK with Android support
/// - Valid Android project configuration
///
/// ## Configuration
/// Uses morpheme.yaml for flavor and build configuration:
/// ```yaml
/// flavors:
///   dev:
///     ENV: "development"
///     API_URL: "https://dev-api.example.com"
///   prod:
///     ENV: "production"
///     API_URL: "https://api.example.com"
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Build debug APK with dev flavor
/// morpheme build apk --flavor dev --debug
///
/// # Build release APK with obfuscation
/// morpheme build apk --flavor prod --release --obfuscate
///
/// # Build with custom build number
/// morpheme build apk --build-number 42 --build-name "1.2.0"
/// ```
class ApkCommand extends BaseBuildCommand {
  @override
  String get name => 'apk';

  @override
  String get description => 'Build Android APK with flavor support.';

  @override
  String get platformName => 'Android APK';

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

    // Check for required Android tools
    if (which('adb').notfound) {
      return ValidationResult.error(
        'Android Debug Bridge (adb) not found',
        suggestion: 'Ensure Android SDK platform-tools are in PATH',
        examples: [
          'export PATH=\$ANDROID_HOME/platform-tools:\$PATH',
          'flutter doctor',
        ],
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
      });

      // Build Flutter arguments for APK
      final arguments = buildFlutterArguments(config, 'apk');

      // Add Android-specific configurations
      if (config.androidConfig != null) {
        // final androidConfig = config.androidConfig!;

        // Note: APK builds don't use app bundle format
        // Additional Android-specific arguments can be added here
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.compilation,
        0.1,
        estimatedRemaining: Duration(minutes: 3),
      );

      // Execute Flutter build command
      await FlutterHelper.run(
        arguments.join(' '),
        showLog: true,
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.packaging,
        0.9,
        estimatedRemaining: Duration(seconds: 30),
      );

      // Report build artifacts
      final apkPath = _findGeneratedApk();
      if (apkPath != null) {
        final apkFile = File(apkPath);
        final artifacts = [
          BuildArtifact(
            type: 'APK',
            path: apkPath,
            sizeBytes: apkFile.existsSync() ? apkFile.lengthSync() : null,
          ),
        ];

        BuildProgressReporter.reportBuildArtifacts(artifacts);
      }
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildProcessFailure,
        'Android APK build failed',
        platform: platformName,
        suggestion: 'Check build logs and Android configuration',
        examples: [
          'flutter clean',
          'flutter pub get',
          'morpheme doctor',
        ],
        diagnosticCommands: [
          'flutter doctor',
          'adb devices',
          'gradle --version',
        ],
        recoverySteps: [
          'Clean the project with "flutter clean"',
          'Get dependencies with "flutter pub get"',
          'Check Android SDK configuration',
          'Verify Android project settings in android/app/build.gradle',
        ],
      );
    }
  }

  /// Finds the generated APK file path.
  ///
  /// Searches common APK output locations and returns the path
  /// to the most recently generated APK file.
  ///
  /// Returns: Path to APK file or null if not found
  String? _findGeneratedApk() {
    final commonPaths = [
      'build/app/outputs/apk/release/app-release.apk',
      'build/app/outputs/apk/debug/app-debug.apk',
      'build/app/outputs/apk/profile/app-profile.apk',
    ];

    for (final path in commonPaths) {
      if (exists(path)) {
        return path;
      }
    }

    // Search for any APK files in the output directory
    final apkDir = 'build/app/outputs/apk';
    if (exists(apkDir)) {
      try {
        final directory = Directory(apkDir);
        final apkFiles = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.apk'))
            .toList();

        if (apkFiles.isNotEmpty) {
          // Return the most recently modified APK
          apkFiles.sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          return apkFiles.first.path;
        }
      } catch (e) {
        // Ignore errors when searching for APK files
      }
    }

    return null;
  }
}
