/// Build command container for all platform-specific build commands.
///
/// This command serves as the main entry point for build operations,
/// organizing all platform-specific build commands under a unified
/// interface with enhanced documentation and command discovery.
///
/// ## Available Build Commands
/// - **apk**: Build Android APK files
/// - **appbundle**: Build Android App Bundle (AAB) files
/// - **ios**: Build iOS application bundles
/// - **ipa**: Build iOS IPA archives for distribution
/// - **web**: Build web applications with modern optimizations
///
/// ## Enhanced Features
/// - Unified build workflow with consistent error handling
/// - Comprehensive progress reporting and user feedback
/// - Platform-specific validation and environment checks
/// - Advanced configuration management through morpheme.yaml
/// - Build artifact analysis and deployment guidance
///
/// ## Usage Examples
/// ```bash
/// # Build Android APK for production
/// morpheme build apk --flavor prod --release
///
/// # Build iOS IPA for App Store submission
/// morpheme build ipa --flavor prod --export-method app-store
///
/// # Build web application with PWA support
/// morpheme build web --flavor prod --pwa-strategy offline-first
/// ```
///
/// ## Global Options
/// All build commands support common options including:
/// - Flavor selection (--flavor)
/// - Build modes (--debug, --profile, --release)
/// - Target specification (--target)
/// - Configuration override (--morpheme-yaml)
/// - Localization generation (--l10n)
/// - Build versioning (--build-number, --build-name)
/// - Code obfuscation (--obfuscate, --split-debug-info)
library;

import 'package:morpheme_cli/build_app/apk/apk_command.dart';
import 'package:morpheme_cli/build_app/appbundle/appbundle_command.dart';
import 'package:morpheme_cli/build_app/ios/ios_command.dart';
import 'package:morpheme_cli/build_app/ipa/ipa_command.dart';
import 'package:morpheme_cli/build_app/web/web_command.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

/// Container command for all build operations.
///
/// Organizes platform-specific build commands and provides
/// unified access to build functionality across different
/// target platforms and deployment scenarios.
class BuildCommand extends Command {
  /// Creates a new BuildCommand with all platform subcommands.
  ///
  /// Initializes and registers all available build commands
  /// including Android, iOS, and web build targets.
  BuildCommand() {
    addSubcommand(ApkCommand());
    addSubcommand(AppbundleCommand());
    addSubcommand(IpaCommand());
    addSubcommand(IosCommand());
    addSubcommand(WebCommand());
  }

  @override
  String get name => 'build';

  @override
  String get description =>
      'Build applications for Android, iOS, and web platforms.';

  @override
  String get category => Constants.build;

  /// Extended help text with platform-specific guidance.
  ///
  /// Provides comprehensive information about available build
  /// commands, their purposes, and usage recommendations.
  @override
  String get invocation {
    final buffer = StringBuffer();
    buffer.writeln('Usage: morpheme build <platform> [options]');
    buffer.writeln();
    buffer.writeln('Available platforms:');
    buffer.writeln('  apk        Build Android APK for device installation');
    buffer.writeln('  appbundle  Build Android App Bundle for Play Store');
    buffer.writeln('  ios        Build iOS app bundle for development/testing');
    buffer.writeln('  ipa        Build iOS IPA archive for distribution');
    buffer.writeln('  web        Build web application for browser deployment');
    buffer.writeln();
    buffer.writeln('Global options:');
    buffer.writeln(
        '  -f, --flavor      Select build flavor (dev, staging, prod)');
    buffer.writeln('  --debug           Build in debug mode');
    buffer.writeln('  --profile         Build in profile mode');
    buffer.writeln('  --release         Build in release mode (default)');
    buffer.writeln('  --build-number    Override build number');
    buffer.writeln('  --build-name      Override build name/version');
    buffer
        .writeln('  --obfuscate       Enable code obfuscation (release only)');
    buffer.writeln('  --l10n            Generate localization files');
    buffer.writeln();
    buffer.writeln('Examples:');
    buffer.writeln('  morpheme build apk --flavor prod');
    buffer.writeln('  morpheme build ipa --export-method app-store');
    buffer.writeln('  morpheme build web --web-renderer canvaskit');
    buffer.writeln();
    buffer.writeln('For platform-specific options, use:');
    buffer.writeln('  morpheme build <platform> --help');

    return buffer.toString();
  }
}
