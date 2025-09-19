import 'package:morpheme_cli/build_app/base/build_command_base.dart';

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
class AppbundleCommand extends BuildCommandBase {
  AppbundleCommand() : super() {
    // App Bundle-specific arguments if any
  }

  @override
  String get name => 'appbundle';

  @override
  String get description => 'Build android aab with flavor.';

  @override
  String get buildTarget => 'appbundle';
}
