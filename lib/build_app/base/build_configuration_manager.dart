/// Centralized configuration management for build operations.
///
/// Handles morpheme.yaml parsing, flavor resolution, and
/// environment-specific configuration loading with comprehensive
/// validation and error handling.
///
/// ## Usage
/// ```dart
/// final config = await BuildConfigurationManager.loadConfiguration(
///   yamlPath: 'morpheme.yaml',
///   flavor: 'prod',
///   overrides: {'ENV': 'production'},
/// );
/// ```
library;

import 'dart:io';

import 'package:morpheme_cli/build_app/base/build_command_mixin.dart';
import 'package:morpheme_cli/build_app/base/build_configuration.dart';
import 'package:morpheme_cli/build_app/base/build_error_handler.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Centralized configuration management for build operations.
///
/// Provides unified configuration loading, validation, and resolution
/// with support for platform-specific configurations and overrides.
abstract class BuildConfigurationManager {
  /// Loads and validates build configuration from morpheme.yaml.
  ///
  /// Performs comprehensive configuration loading including flavor resolution,
  /// dart-define parameter extraction, and platform-specific configuration.
  ///
  /// Parameters:
  /// - [yamlPath]: Path to morpheme.yaml configuration file
  /// - [flavor]: Build flavor to load configuration for
  /// - [overrides]: Optional configuration overrides
  ///
  /// Returns: Complete BuildConfiguration object
  /// Throws: BuildCommandException if configuration is invalid
  static Future<BuildConfiguration> loadConfiguration({
    required String yamlPath,
    required String flavor,
    Map<String, String>? overrides,
  }) async {
    try {
      // Validate and load morpheme.yaml
      final yaml = await _loadAndValidateYaml(yamlPath);

      // Resolve flavor configuration
      final flavorConfig =
          await _resolveFlavorConfiguration(yaml, flavor, yamlPath);

      // Extract dart-define parameters
      final dartDefines = _resolveDartDefines(flavorConfig, overrides);

      // Load platform-specific configurations
      final androidConfig = await _loadAndroidConfiguration(yaml, flavor);
      final iosConfig = await _loadIosConfiguration(yaml, flavor);
      final webConfig = await _loadWebConfiguration(yaml, flavor);

      return BuildConfiguration(
        target: 'lib/main.dart', // Default target, can be overridden
        flavor: flavor,
        mode: BuildMode.release, // Default mode, can be overridden
        morphemeYamlPath: yamlPath,
        dartDefines: dartDefines,
        androidConfig: androidConfig,
        iosConfig: iosConfig,
        webConfig: webConfig,
      );
    } catch (e) {
      if (e is BuildCommandException) rethrow;

      throw BuildCommandException(
        BuildCommandError.buildConfigurationInvalid,
        'Failed to load build configuration',
        suggestion: 'Check morpheme.yaml syntax and flavor configuration',
        examples: [
          'morpheme config',
          'cat $yamlPath',
          'morpheme doctor',
        ],
      );
    }
  }

  /// Resolves dart-define parameters from flavor configuration.
  ///
  /// Extracts and formats dart-define parameters from the flavor
  /// configuration with support for environment variable expansion.
  ///
  /// Parameters:
  /// - [flavorConfig]: Flavor configuration map
  /// - [overrides]: Optional parameter overrides
  ///
  /// Returns: Map of dart-define parameters
  static Map<String, String> _resolveDartDefines(
    Map<String, dynamic> flavorConfig,
    Map<String, String>? overrides,
  ) {
    final dartDefines = <String, String>{};

    // Add flavor configuration as dart-defines
    flavorConfig.forEach((key, value) {
      if (value != null) {
        dartDefines[key] = value.toString();
      }
    });

    // Apply overrides
    if (overrides != null) {
      dartDefines.addAll(overrides);
    }

    // Expand environment variables
    final expandedDefines = <String, String>{};
    for (final entry in dartDefines.entries) {
      final expandedValue = _expandEnvironmentVariables(entry.value);
      expandedDefines[entry.key] = expandedValue;
    }

    return expandedDefines;
  }

  /// Validates platform-specific configuration requirements.
  ///
  /// Performs comprehensive validation of platform configuration
  /// including required tools, certificates, and environment setup.
  ///
  /// Parameters:
  /// - [platform]: Target platform name
  /// - [config]: Build configuration to validate
  ///
  /// Returns: ValidationResult indicating configuration validity
  static ValidationResult<bool> validatePlatformConfig(
    String platform,
    BuildConfiguration config,
  ) {
    switch (platform.toLowerCase()) {
      case 'android':
      case 'apk':
      case 'appbundle':
        return _validateAndroidConfig(config);

      case 'ios':
      case 'ipa':
        return _validateIosConfig(config);

      case 'web':
        return _validateWebConfig(config);

      default:
        return ValidationResult.error(
          'Unknown platform: $platform',
          suggestion: 'Use supported platforms: android, ios, web',
          examples: ['apk', 'ipa', 'web'],
        );
    }
  }

  /// Loads and validates morpheme.yaml file.
  ///
  /// Performs comprehensive YAML validation including syntax checking
  /// and required field verification.
  static Future<Map<String, dynamic>> _loadAndValidateYaml(
      String yamlPath) async {
    // Check if file exists
    if (!exists(yamlPath)) {
      throw BuildCommandException(
        BuildCommandError.buildConfigurationInvalid,
        'morpheme.yaml not found at: $yamlPath',
        suggestion: 'Create morpheme.yaml configuration file',
        examples: [
          'morpheme init',
          'morpheme config',
        ],
      );
    }

    try {
      final yaml = YamlHelper.loadFileYaml(yamlPath);

      // Validate required sections
      if (yaml.isEmpty) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'morpheme.yaml is empty or invalid',
          suggestion: 'Add valid configuration to morpheme.yaml',
          examples: ['morpheme config', 'morpheme init'],
        );
      }

      return Map<String, dynamic>.from(yaml);
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildConfigurationInvalid,
        'Invalid morpheme.yaml syntax: ${e.toString()}',
        suggestion: 'Check YAML syntax and formatting',
        examples: [
          'cat $yamlPath',
          'yamllint $yamlPath',
        ],
      );
    }
  }

  /// Resolves flavor configuration from morpheme.yaml.
  ///
  /// Extracts and validates flavor-specific configuration with
  /// support for inheritance and default values.
  static Future<Map<String, dynamic>> _resolveFlavorConfiguration(
    Map<String, dynamic> yaml,
    String flavor,
    String yamlPath,
  ) async {
    try {
      final flavorConfig = FlavorHelper.byFlavor(flavor, yamlPath);

      if (flavorConfig.isEmpty) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'Flavor "$flavor" not found in morpheme.yaml',
          suggestion: 'Add flavor configuration or use existing flavor',
          examples: [
            'morpheme config',
            'cat $yamlPath | grep -A 10 "flavors:"',
          ],
        );
      }

      return Map<String, dynamic>.from(flavorConfig);
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildConfigurationInvalid,
        'Failed to resolve flavor configuration: ${e.toString()}',
        suggestion: 'Check flavor definition in morpheme.yaml',
        examples: ['morpheme config', 'cat $yamlPath'],
      );
    }
  }

  /// Loads Android-specific build configuration.
  ///
  /// Extracts Android platform configuration including signing
  /// settings and build parameters.
  static Future<AndroidBuildConfig?> _loadAndroidConfiguration(
    Map<String, dynamic> yaml,
    String flavor,
  ) async {
    final androidSection = yaml['android'] as Map<String, dynamic>?;
    if (androidSection == null) return null;

    final flavorSection = androidSection[flavor] as Map<String, dynamic>?;
    if (flavorSection == null) return null;

    // Load signing configuration if available
    AndroidSigningConfig? signingConfig;
    final signingSection = flavorSection['signing'] as Map<String, dynamic>?;
    if (signingSection != null) {
      signingConfig = AndroidSigningConfig(
        keystorePath: signingSection['keystorePath'] as String? ?? '',
        keystorePassword: signingSection['keystorePassword'] as String? ?? '',
        keyAlias: signingSection['keyAlias'] as String? ?? '',
        keyPassword: signingSection['keyPassword'] as String? ?? '',
      );
    }

    return AndroidBuildConfig(
      buildAppBundle: flavorSection['buildAppBundle'] as bool? ?? false,
      signingConfig: signingConfig,
      targetSdkVersion: flavorSection['targetSdkVersion'] as int?,
      minSdkVersion: flavorSection['minSdkVersion'] as int?,
    );
  }

  /// Loads iOS-specific build configuration.
  ///
  /// Extracts iOS platform configuration including code signing
  /// and provisioning profile settings.
  static Future<IosBuildConfig?> _loadIosConfiguration(
    Map<String, dynamic> yaml,
    String flavor,
  ) async {
    final iosSection = yaml['ios'] as Map<String, dynamic>?;
    if (iosSection == null) return null;

    final flavorSection = iosSection[flavor] as Map<String, dynamic>?;
    if (flavorSection == null) return null;

    // Parse export method
    IosExportMethod? exportMethod;
    final exportMethodStr = flavorSection['exportMethod'] as String?;
    if (exportMethodStr != null) {
      switch (exportMethodStr.toLowerCase()) {
        case 'ad-hoc':
          exportMethod = IosExportMethod.adHoc;
          break;
        case 'app-store':
          exportMethod = IosExportMethod.appStore;
          break;
        case 'development':
          exportMethod = IosExportMethod.development;
          break;
        case 'enterprise':
          exportMethod = IosExportMethod.enterprise;
          break;
      }
    }

    // Load provisioning configuration if available
    IosProvisioningConfig? provisioningConfig;
    final provisioningSection =
        flavorSection['provisioning'] as Map<String, dynamic>?;
    if (provisioningSection != null) {
      provisioningConfig = IosProvisioningConfig(
        teamId: provisioningSection['teamId'] as String? ?? '',
        provisioningProfile:
            provisioningSection['provisioningProfile'] as String? ?? '',
        codeSignIdentity: provisioningSection['codeSignIdentity'] as String?,
      );
    }

    return IosBuildConfig(
      codesign: flavorSection['codesign'] as bool? ?? true,
      exportMethod: exportMethod,
      exportOptionsPlist: flavorSection['exportOptionsPlist'] as String?,
      provisioningConfig: provisioningConfig,
    );
  }

  /// Loads Web-specific build configuration.
  ///
  /// Extracts web platform configuration including PWA settings
  /// and optimization parameters.
  static Future<WebBuildConfig?> _loadWebConfiguration(
    Map<String, dynamic> yaml,
    String flavor,
  ) async {
    final webSection = yaml['web'] as Map<String, dynamic>?;
    if (webSection == null) return null;

    final flavorSection = webSection[flavor] as Map<String, dynamic>?;
    if (flavorSection == null) return null;

    // Parse PWA strategy
    WebPwaStrategy? pwaStrategy;
    final pwaStrategyStr = flavorSection['pwaStrategy'] as String?;
    if (pwaStrategyStr != null) {
      switch (pwaStrategyStr.toLowerCase()) {
        case 'none':
          pwaStrategy = WebPwaStrategy.none;
          break;
        case 'offline-first':
          pwaStrategy = WebPwaStrategy.offlineFirst;
          break;
      }
    }

    // Parse web renderer
    WebRenderer? webRenderer;
    final webRendererStr = flavorSection['webRenderer'] as String?;
    if (webRendererStr != null) {
      switch (webRendererStr.toLowerCase()) {
        case 'auto':
          webRenderer = WebRenderer.auto;
          break;
        case 'canvaskit':
          webRenderer = WebRenderer.canvaskit;
          break;
        case 'html':
          webRenderer = WebRenderer.html;
          break;
        case 'skwasm':
          webRenderer = WebRenderer.skwasm;
          break;
      }
    }

    // Parse optimization level
    WebOptimizationLevel? optimizationLevel;
    final optimizationStr = flavorSection['optimizationLevel'] as String?;
    if (optimizationStr != null) {
      switch (optimizationStr.toUpperCase()) {
        case 'O1':
          optimizationLevel = WebOptimizationLevel.o1;
          break;
        case 'O2':
          optimizationLevel = WebOptimizationLevel.o2;
          break;
        case 'O3':
          optimizationLevel = WebOptimizationLevel.o3;
          break;
        case 'O4':
          optimizationLevel = WebOptimizationLevel.o4;
          break;
      }
    }

    return WebBuildConfig(
      baseHref: flavorSection['baseHref'] as String?,
      pwaStrategy: pwaStrategy,
      webRenderer: webRenderer,
      webResourcesCdn: flavorSection['webResourcesCdn'] as bool? ?? true,
      csp: flavorSection['csp'] as bool? ?? false,
      sourceMaps: flavorSection['sourceMaps'] as bool? ?? false,
      optimizationLevel: optimizationLevel,
      dumpInfo: flavorSection['dumpInfo'] as bool? ?? false,
      frequencyBasedMinification:
          flavorSection['frequencyBasedMinification'] as bool? ?? true,
    );
  }

  /// Validates Android platform configuration.
  static ValidationResult<bool> _validateAndroidConfig(
      BuildConfiguration config) {
    final androidConfig = config.androidConfig;
    if (androidConfig == null) {
      return ValidationResult.success(true);
    }

    // Validate signing configuration for release builds
    if (config.mode == BuildMode.release &&
        androidConfig.signingConfig != null) {
      final signing = androidConfig.signingConfig!;

      if (signing.keystorePath.isNotEmpty && !exists(signing.keystorePath)) {
        return ValidationResult.error(
          'Android keystore not found: ${signing.keystorePath}',
          suggestion: 'Create keystore or update path in morpheme.yaml',
          examples: [
            'keytool -genkey -v -keystore release.keystore',
            'ls ${dirname(signing.keystorePath)}',
          ],
        );
      }
    }

    return ValidationResult.success(true);
  }

  /// Validates iOS platform configuration.
  static ValidationResult<bool> _validateIosConfig(BuildConfiguration config) {
    final iosConfig = config.iosConfig;
    if (iosConfig == null) {
      return ValidationResult.success(true);
    }

    // Validate macOS requirement
    if (!Platform.isMacOS) {
      return ValidationResult.error(
        'iOS builds require macOS host system',
        suggestion: 'Use a macOS system to build iOS applications',
        examples: ['sw_vers', 'uname -a'],
      );
    }

    // Validate Xcode installation
    if (which('xcodebuild').notfound) {
      return ValidationResult.error(
        'Xcode command line tools not found',
        suggestion: 'Install Xcode and command line tools',
        examples: [
          'xcode-select --install',
          'sudo xcode-select --switch /Applications/Xcode.app',
        ],
      );
    }

    // Validate export options plist if specified
    if (iosConfig.exportOptionsPlist != null &&
        !exists(iosConfig.exportOptionsPlist!)) {
      return ValidationResult.error(
        'Export options plist not found: ${iosConfig.exportOptionsPlist}',
        suggestion: 'Create export options plist or update path',
        examples: [
          'ls ${dirname(iosConfig.exportOptionsPlist!)}',
          'xcodebuild -h | grep exportOptionsPlist',
        ],
      );
    }

    return ValidationResult.success(true);
  }

  /// Validates Web platform configuration.
  static ValidationResult<bool> _validateWebConfig(BuildConfiguration config) {
    final webConfig = config.webConfig;
    if (webConfig == null) {
      return ValidationResult.success(true);
    }

    // Validate base href format
    if (webConfig.baseHref != null) {
      final baseHref = webConfig.baseHref!;
      if (!baseHref.startsWith('/') || !baseHref.endsWith('/')) {
        return ValidationResult.error(
          'Base href must start and end with "/"',
          suggestion: 'Format base href as "/path/" (with slashes)',
          examples: ['/', '/app/', '/subdirectory/'],
        );
      }
    }

    return ValidationResult.success(true);
  }

  /// Expands environment variables in configuration values.
  ///
  /// Supports ${VAR} and $VAR syntax for environment variable expansion.
  static String _expandEnvironmentVariables(String value) {
    return value.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)'),
      (match) {
        final varName = match.group(1) ?? match.group(2)!;
        return Platform.environment[varName] ?? match.group(0)!;
      },
    );
  }
}
