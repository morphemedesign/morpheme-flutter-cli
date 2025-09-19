import 'package:morpheme_cli/build_app/prebuild_android/prebuild_android_command.dart';
import 'package:morpheme_cli/build_app/prebuild_ios/prebuild_ios_command.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

/// Container command for all prebuild setup operations.
///
/// Organizes platform-specific prebuild commands and provides
/// unified access to build environment preparation across
/// different target platforms.
class PreBuildCommand extends Command {
  PreBuildCommand() {
    addSubcommand(PreBuildAndroidCommand());
    addSubcommand(PreBuildIosCommand());
  }

  @override
  String get name => 'prebuild';

  @override
  String get description => 'Prepare setup before build';

  @override
  String get category => Constants.build;

  /// Extended help text with platform-specific guidance.
  ///
  /// Provides comprehensive information about available prebuild
  /// commands, their purposes, and setup requirements.
  @override
  String get invocation {
    final buffer = StringBuffer();
    buffer.writeln('Usage: morpheme prebuild <platform> [options]');
    buffer.writeln();
    buffer.writeln('Available platforms:');
    buffer.writeln('  android    Prepare Android build environment');
    buffer.writeln('             - Fastlane Appfile generation');
    buffer.writeln('             - Play Store service account setup');
    buffer.writeln('             - Gradle configuration optimization');
    buffer.writeln();
    buffer
        .writeln('  ios        Prepare iOS build environment (macOS required)');
    buffer.writeln('             - Fastlane Appfile with App Store Connect');
    buffer.writeln('             - Xcode project signing configuration');
    buffer.writeln('             - Export options for IPA generation');
    buffer.writeln();
    buffer.writeln('Common options:');
    buffer.writeln(
        '  -f, --flavor         Select flavor for configuration (dev, staging, prod)');
    buffer.writeln(
        '  --morpheme-yaml      Custom path to morpheme.yaml configuration');
    buffer.writeln();
    buffer.writeln('Requirements by platform:');
    buffer.writeln('  Android:');
    buffer.writeln('    - Android SDK and build tools');
    buffer.writeln('    - Valid Android project structure');
    buffer.writeln('    - ANDROID_APPLICATION_ID in morpheme.yaml');
    buffer.writeln();
    buffer.writeln('  iOS:');
    buffer.writeln('    - macOS host system with Xcode');
    buffer.writeln('    - Valid iOS project structure');
    buffer.writeln('    - IOS_APPLICATION_ID in morpheme.yaml');
    buffer.writeln('    - ios/deployment/appstore_deployment.json');
    buffer.writeln();
    buffer.writeln('Examples:');
    buffer.writeln('  morpheme prebuild android --flavor prod');
    buffer.writeln('  morpheme prebuild ios --flavor staging');
    buffer.writeln();
    buffer.writeln('For platform-specific options and detailed setup, use:');
    buffer.writeln('  morpheme prebuild <platform> --help');

    return buffer.toString();
  }
}
