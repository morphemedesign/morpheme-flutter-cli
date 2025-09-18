import 'package:morpheme_cli/build_app/base/base_prebuild_command.dart';
import 'package:morpheme_cli/build_app/base/build_error_handler.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Android prebuild setup command implementation.
///
/// Prepares Android project for build operations by configuring
/// Fastlane deployment settings, signing configurations, and
/// build environment setup.
///
/// ## Platform Requirements
/// - Android SDK and build tools
/// - Fastlane for deployment automation (optional)
/// - Valid Android project structure
///
/// ## Configuration Setup
/// - Fastlane Appfile generation with package name
/// - Play Store service account configuration
/// - Signing key and certificate setup
/// - Build variant configuration
///
/// ## Fastlane Integration
/// Generates Appfile for Fastlane automation:
/// ```ruby
/// json_key_file("fastlane/play-store.json")
/// package_name("com.example.app")
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Setup Android prebuild for production
/// morpheme prebuild android --flavor prod
///
/// # Setup with development flavor
/// morpheme prebuild android --flavor dev
/// ```
class PreBuildAndroidCommand extends BasePrebuildCommand {
  @override
  String get name => 'android';

  @override
  String get description => 'Prepare Android project for build operations.';

  @override
  String get platformName => 'Android';

  @override
  ValidationResult<bool> validatePrebuildEnvironment() {
    // Check for Android project structure
    final androidDir = join(current, 'android');
    if (!exists(androidDir)) {
      return ValidationResult.error(
        'Android project directory not found',
        suggestion:
            'Ensure this is run from a Flutter project with Android support',
        examples: [
          'flutter create --platforms android .',
          'ls android/',
        ],
      );
    }

    // Check for Android manifest
    final manifestPath =
        join(androidDir, 'app', 'src', 'main', 'AndroidManifest.xml');
    if (!exists(manifestPath)) {
      return ValidationResult.error(
        'Android manifest not found',
        suggestion: 'Ensure Android project is properly configured',
        examples: [
          'ls android/app/src/main/',
          'flutter doctor',
        ],
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePreBuildSetup(PrebuildConfiguration config) async {
    try {
      // Extract Android application ID from flavor config
      final packageName = config.flavorConfig['ANDROID_APPLICATION_ID'];

      validateRequiredConfig(
        packageName,
        'ANDROID_APPLICATION_ID',
        'Android prebuild setup',
      );

      // Setup Fastlane configuration
      await _setupFastlane(packageName.toString());

      // Setup additional Android configurations if needed
      await _setupAndroidSigningConfig(config);
      await _setupGradleProperties(config);
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.environmentSetupFailure,
        'Failed to setup Android prebuild environment',
        platform: platformName,
        suggestion: 'Check Android project configuration and permissions',
        examples: [
          'ls android/',
          'cat android/app/build.gradle',
          'flutter doctor',
        ],
        recoverySteps: [
          'Ensure Android project structure is valid',
          'Check ANDROID_APPLICATION_ID in morpheme.yaml',
          'Verify file write permissions in android directory',
        ],
      );
    }
  }

  /// Sets up Fastlane configuration for Android deployment.
  ///
  /// Creates the Appfile with package name and Play Store
  /// service account configuration for automated deployment.
  ///
  /// Parameters:
  /// - [packageName]: Android application package identifier
  Future<void> _setupFastlane(String packageName) async {
    final fastlaneDir = join(current, 'android', 'fastlane');
    final appFilePath = join(fastlaneDir, 'Appfile');

    final content = '''json_key_file("fastlane/play-store.json")
package_name("$packageName")''';

    generateConfigFile(
      appFilePath,
      content,
      'Fastlane Appfile for Android deployment',
    );

    // Provide guidance on Play Store service account setup
    printMessage('\n📋 Next steps for Fastlane setup:');
    printMessage('   1. Create service account in Google Cloud Console');
    printMessage('   2. Download service account key as play-store.json');
    printMessage('   3. Place key file in android/fastlane/ directory');
    printMessage('   4. Configure Play Store access for the service account');
  }

  /// Sets up Android signing configuration if available.
  ///
  /// Configures release signing settings and keystore
  /// information for production builds.
  ///
  /// Parameters:
  /// - [config]: Prebuild configuration with signing details
  Future<void> _setupAndroidSigningConfig(PrebuildConfiguration config) async {
    // Check if signing configuration is available in morpheme.yaml
    final androidConfig = config.morphemeYaml['android']?[config.flavor];
    if (androidConfig == null) {
      printMessage(
          '\n⚠️  No Android-specific configuration found in morpheme.yaml');
      return;
    }

    final signingConfig = androidConfig['signing'];
    if (signingConfig == null) {
      printMessage(
          '\n💡 Consider adding signing configuration to morpheme.yaml:');
      printMessage('   android:');
      printMessage('     ${config.flavor}:');
      printMessage('       signing:');
      printMessage('         keystorePath: "path/to/keystore.jks"');
      printMessage('         keyAlias: "your-key-alias"');
      return;
    }

    // Validate signing configuration
    final keystorePath = signingConfig['keystorePath'];
    if (keystorePath != null && !exists(keystorePath)) {
      throw BuildCommandException(
        BuildCommandError.signingConfigurationInvalid,
        'Keystore file not found: $keystorePath',
        suggestion: 'Create keystore or update path in morpheme.yaml',
        examples: [
          'keytool -genkey -v -keystore release.keystore',
          'ls ${dirname(keystorePath)}',
        ],
      );
    }

    printMessage('\n🔐 Android signing configuration validated');
  }

  /// Sets up Gradle properties for build configuration.
  ///
  /// Configures gradle.properties with build-specific settings
  /// and optimization parameters.
  ///
  /// Parameters:
  /// - [config]: Prebuild configuration with Gradle settings
  Future<void> _setupGradleProperties(PrebuildConfiguration config) async {
    final gradlePropertiesPath = join(current, 'android', 'gradle.properties');

    if (!exists(gradlePropertiesPath)) {
      // Create basic gradle.properties if it doesn't exist
      final content = '''# Android Gradle Properties
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true''';

      generateConfigFile(
        gradlePropertiesPath,
        content,
        'Gradle properties for Android build',
      );
    } else {
      printMessage('\n✅ Gradle properties file already exists');
    }

    // Check for additional optimizations
    final gradleContent = readFile(gradlePropertiesPath);
    final optimizations = <String>[
      'org.gradle.parallel=true',
      'org.gradle.caching=true',
      'android.enableR8.fullMode=true',
    ];

    final missingOptimizations = optimizations
        .where((opt) => !gradleContent.contains(opt.split('=')[0]))
        .toList();

    if (missingOptimizations.isNotEmpty) {
      printMessage('\n💡 Consider adding these Gradle optimizations:');
      for (final opt in missingOptimizations) {
        printMessage('   $opt');
      }
    }
  }
}
