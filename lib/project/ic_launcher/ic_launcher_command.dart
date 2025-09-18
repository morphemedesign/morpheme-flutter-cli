import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to copy application launcher icons to platform-specific directories.
///
/// This command manages the distribution of launcher icons from the project's
/// `ic_launcher` directory to the appropriate Android and iOS locations based
/// on the selected flavor configuration.
///
/// **Purpose:**
/// - Automates launcher icon deployment across platforms
/// - Supports multiple flavor configurations (dev, staging, prod, etc.)
/// - Maintains consistent icon assets across Android and iOS
///
/// **Directory Structure:**
/// ```
/// ic_launcher/
/// ├── dev/
/// │   ├── android/
/// │   └── ios/
/// ├── staging/
/// └── production/
/// ```
///
/// **Usage:**
/// ```bash
/// # Use default flavor (dev)
/// morpheme ic-launcher
///
/// # Specify flavor
/// morpheme ic-launcher --flavor production
/// ```
///
/// **Parameters:**
/// - `--flavor`: Target flavor for icon deployment (default: dev)
///
/// **Exceptions:**
/// - Throws [DirectoryException] if source icon directories don't exist
/// - Throws [FileSystemException] if icon copy operations fail
///
/// **Example:**
/// ```dart
/// // Copies icons from ic_launcher/dev/ to platform directories
/// morpheme ic-launcher --flavor dev
/// ```
class IcLauncherCommand extends Command {
  IcLauncherCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
  }

  @override
  String get name => 'ic-launcher';

  @override
  String get description =>
      'Deploy launcher icons to platform-specific directories for the specified flavor.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);

      printMessage('🎨 Deploying launcher icons for flavor: $argFlavor');

      // Validate source directories exist before proceeding
      _validateSourceDirectories(argFlavor);

      // Deploy icons to both platforms
      _deployAndroidIcons(argFlavor);
      _deployIosIcons(argFlavor);

      printMessage('🎉 Successfully deployed launcher icons to all platforms');
      StatusHelper.success('ic-launcher deployment completed');
    } catch (e) {
      StatusHelper.failed('Failed to deploy launcher icons: $e');
    }
  }

  /// Validates that the required source directories exist for the specified flavor.
  ///
  /// **Parameters:**
  /// - [flavor]: The flavor to validate directories for
  ///
  /// **Throws:**
  /// - [DirectoryException] if required directories are missing
  void _validateSourceDirectories(String flavor) {
    final androidSourceDir = join(current, 'ic_launcher', flavor, 'android');
    final iosSourceDir = join(current, 'ic_launcher', flavor, 'ios');

    if (!exists(androidSourceDir)) {
      throw Exception(
          'Android icon source directory not found: $androidSourceDir');
    }

    if (!exists(iosSourceDir)) {
      throw Exception('iOS icon source directory not found: $iosSourceDir');
    }

    printMessage('✓ Source directories validated for flavor: $flavor');
  }

  /// Deploys Android launcher icons to the appropriate resource directory.
  ///
  /// Copies all icon resources from the flavor's Android directory to the
  /// main Android app resources directory.
  ///
  /// **Parameters:**
  /// - [flavor]: The flavor to deploy icons for
  ///
  /// **Target:** `android/app/src/main/res/`
  void _deployAndroidIcons(String flavor) {
    final sourceDir = join(current, 'ic_launcher', flavor, 'android');
    final targetDir = join(current, 'android', 'app', 'src', 'main', 'res');

    try {
      printMessage('🤖 Deploying Android icons...');
      copyTree(sourceDir, targetDir, overwrite: true);
      printMessage('✓ Android icons deployed successfully');
    } catch (e) {
      throw Exception('Failed to deploy Android icons: $e');
    }
  }

  /// Deploys iOS launcher icons to the appropriate assets directory.
  ///
  /// Copies all icon assets from the flavor's iOS directory to the
  /// main iOS app assets directory.
  ///
  /// **Parameters:**
  /// - [flavor]: The flavor to deploy icons for
  ///
  /// **Target:** `ios/Runner/Assets.xcassets/`
  void _deployIosIcons(String flavor) {
    final sourceDir = join(current, 'ic_launcher', flavor, 'ios');
    final targetDir = join(current, 'ios', 'Runner', 'Assets.xcassets');

    try {
      printMessage('🍎 Deploying iOS icons...');
      copyTree(sourceDir, targetDir, overwrite: true);
      printMessage('✓ iOS icons deployed successfully');
    } catch (e) {
      throw Exception('Failed to deploy iOS icons: $e');
    }
  }
}
