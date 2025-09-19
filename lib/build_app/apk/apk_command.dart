import 'package:morpheme_cli/build_app/base/build_command_base.dart';

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
class ApkCommand extends BuildCommandBase {
  ApkCommand() : super() {
    // APK-specific arguments if any
  }

  @override
  String get name => 'apk';

  @override
  String get description => 'Build android apk with flavor.';

  @override
  String get buildTarget => 'apk';
}
