/// Immutable configuration object for build operations.
///
/// Encapsulates all build-related parameters including flavors,
/// build modes, target paths, and platform-specific options.
///
/// ## Usage
/// ```dart
/// final config = BuildConfiguration(
///   target: 'lib/main.dart',
///   flavor: 'prod',
///   mode: BuildMode.release,
///   dartDefines: {'ENV': 'production'},
/// );
/// ```
library;

import 'package:morpheme_cli/build_app/base/build_command_mixin.dart';

/// Immutable build configuration containing all build parameters.
///
/// This class encapsulates all the configuration needed to perform
/// a build operation, extracted from command arguments and morpheme.yaml.
class BuildConfiguration {
  /// Target entry point file for the application
  final String target;

  /// Build flavor (e.g., dev, staging, prod)
  final String flavor;

  /// Build mode (debug, profile, release)
  final BuildMode mode;

  /// Path to morpheme.yaml configuration file
  final String morphemeYamlPath;

  /// Build number for version identification
  final String? buildNumber;

  /// Build name for version display
  final String? buildName;

  /// Whether to obfuscate the build output
  final bool obfuscate;

  /// Directory path for split debug information
  final String? splitDebugInfo;

  /// Whether to generate localization files before build
  final bool generateL10n;

  /// Dart define parameters from flavor configuration
  final Map<String, String> dartDefines;

  /// Android-specific build configuration
  final AndroidBuildConfig? androidConfig;

  /// iOS-specific build configuration
  final IosBuildConfig? iosConfig;

  /// Web-specific build configuration
  final WebBuildConfig? webConfig;

  /// Creates a new BuildConfiguration.
  ///
  /// All required parameters must be provided. Optional parameters
  /// can be null or have sensible defaults.
  const BuildConfiguration({
    required this.target,
    required this.flavor,
    required this.mode,
    required this.morphemeYamlPath,
    this.buildNumber,
    this.buildName,
    this.obfuscate = false,
    this.splitDebugInfo,
    this.generateL10n = false,
    this.dartDefines = const {},
    this.androidConfig,
    this.iosConfig,
    this.webConfig,
  });

  /// Creates a copy of this configuration with updated values.
  ///
  /// Only the specified parameters are changed; all others
  /// retain their current values.
  BuildConfiguration copyWith({
    String? target,
    String? flavor,
    BuildMode? mode,
    String? morphemeYamlPath,
    String? buildNumber,
    String? buildName,
    bool? obfuscate,
    String? splitDebugInfo,
    bool? generateL10n,
    Map<String, String>? dartDefines,
    AndroidBuildConfig? androidConfig,
    IosBuildConfig? iosConfig,
    WebBuildConfig? webConfig,
  }) {
    return BuildConfiguration(
      target: target ?? this.target,
      flavor: flavor ?? this.flavor,
      mode: mode ?? this.mode,
      morphemeYamlPath: morphemeYamlPath ?? this.morphemeYamlPath,
      buildNumber: buildNumber ?? this.buildNumber,
      buildName: buildName ?? this.buildName,
      obfuscate: obfuscate ?? this.obfuscate,
      splitDebugInfo: splitDebugInfo ?? this.splitDebugInfo,
      generateL10n: generateL10n ?? this.generateL10n,
      dartDefines: dartDefines ?? this.dartDefines,
      androidConfig: androidConfig ?? this.androidConfig,
      iosConfig: iosConfig ?? this.iosConfig,
      webConfig: webConfig ?? this.webConfig,
    );
  }

  @override
  String toString() {
    return 'BuildConfiguration('
        'target: $target, '
        'flavor: $flavor, '
        'mode: ${mode.displayName}, '
        'buildNumber: $buildNumber, '
        'buildName: $buildName, '
        'obfuscate: $obfuscate, '
        'generateL10n: $generateL10n'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuildConfiguration &&
        other.target == target &&
        other.flavor == flavor &&
        other.mode == mode &&
        other.morphemeYamlPath == morphemeYamlPath &&
        other.buildNumber == buildNumber &&
        other.buildName == buildName &&
        other.obfuscate == obfuscate &&
        other.splitDebugInfo == splitDebugInfo &&
        other.generateL10n == generateL10n;
  }

  @override
  int get hashCode {
    return Object.hash(
      target,
      flavor,
      mode,
      morphemeYamlPath,
      buildNumber,
      buildName,
      obfuscate,
      splitDebugInfo,
      generateL10n,
    );
  }
}

/// Android-specific build configuration.
///
/// Contains Android platform-specific build parameters
/// such as signing configuration and build types.
class AndroidBuildConfig {
  /// Whether to build an App Bundle instead of APK
  final bool buildAppBundle;

  /// Android signing configuration
  final AndroidSigningConfig? signingConfig;

  /// Target Android SDK version
  final int? targetSdkVersion;

  /// Minimum Android SDK version
  final int? minSdkVersion;

  /// Creates a new AndroidBuildConfig.
  const AndroidBuildConfig({
    this.buildAppBundle = false,
    this.signingConfig,
    this.targetSdkVersion,
    this.minSdkVersion,
  });

  @override
  String toString() {
    return 'AndroidBuildConfig('
        'buildAppBundle: $buildAppBundle, '
        'targetSdk: $targetSdkVersion, '
        'minSdk: $minSdkVersion'
        ')';
  }
}

/// Android code signing configuration.
///
/// Contains parameters for Android application signing
/// including keystore and certificate information.
class AndroidSigningConfig {
  /// Path to the keystore file
  final String keystorePath;

  /// Keystore password
  final String keystorePassword;

  /// Key alias within the keystore
  final String keyAlias;

  /// Key password
  final String keyPassword;

  /// Creates a new AndroidSigningConfig.
  const AndroidSigningConfig({
    required this.keystorePath,
    required this.keystorePassword,
    required this.keyAlias,
    required this.keyPassword,
  });

  @override
  String toString() {
    return 'AndroidSigningConfig('
        'keystorePath: $keystorePath, '
        'keyAlias: $keyAlias'
        ')';
  }
}

/// iOS-specific build configuration.
///
/// Contains iOS platform-specific build parameters
/// including code signing and export options.
class IosBuildConfig {
  /// Whether to code sign the application
  final bool codesign;

  /// Export method for IPA generation
  final IosExportMethod? exportMethod;

  /// Path to export options plist file
  final String? exportOptionsPlist;

  /// iOS provisioning profile configuration
  final IosProvisioningConfig? provisioningConfig;

  /// Creates a new IosBuildConfig.
  const IosBuildConfig({
    this.codesign = true,
    this.exportMethod,
    this.exportOptionsPlist,
    this.provisioningConfig,
  });

  @override
  String toString() {
    return 'IosBuildConfig('
        'codesign: $codesign, '
        'exportMethod: $exportMethod'
        ')';
  }
}

/// iOS export method enumeration.
///
/// Represents the different ways an iOS application
/// can be exported and distributed.
enum IosExportMethod {
  /// Ad-hoc distribution for testing
  adHoc,

  /// App Store distribution
  appStore,

  /// Development distribution for debugging
  development,

  /// Enterprise distribution
  enterprise;

  /// Converts to command-line argument string.
  String toArgumentString() {
    switch (this) {
      case IosExportMethod.adHoc:
        return 'ad-hoc';
      case IosExportMethod.appStore:
        return 'app-store';
      case IosExportMethod.development:
        return 'development';
      case IosExportMethod.enterprise:
        return 'enterprise';
    }
  }

  /// Gets display name for this export method.
  String get displayName {
    switch (this) {
      case IosExportMethod.adHoc:
        return 'Ad-Hoc';
      case IosExportMethod.appStore:
        return 'App Store';
      case IosExportMethod.development:
        return 'Development';
      case IosExportMethod.enterprise:
        return 'Enterprise';
    }
  }
}

/// iOS provisioning profile configuration.
///
/// Contains information about iOS provisioning profiles
/// and code signing certificates.
class IosProvisioningConfig {
  /// Team ID for code signing
  final String teamId;

  /// Provisioning profile name or UUID
  final String provisioningProfile;

  /// Code signing identity
  final String? codeSignIdentity;

  /// Creates a new IosProvisioningConfig.
  const IosProvisioningConfig({
    required this.teamId,
    required this.provisioningProfile,
    this.codeSignIdentity,
  });

  @override
  String toString() {
    return 'IosProvisioningConfig('
        'teamId: $teamId, '
        'provisioningProfile: $provisioningProfile'
        ')';
  }
}

/// Web-specific build configuration.
///
/// Contains web platform-specific build parameters
/// including PWA settings and optimization options.
class WebBuildConfig {
  /// Base href for web deployment
  final String? baseHref;

  /// PWA caching strategy
  final WebPwaStrategy? pwaStrategy;

  /// Web renderer implementation
  final WebRenderer? webRenderer;

  /// Whether to use CDN for web resources
  final bool webResourcesCdn;

  /// Whether to enable Content Security Policy
  final bool csp;

  /// Whether to generate source maps
  final bool sourceMaps;

  /// Dart2JS optimization level
  final WebOptimizationLevel? optimizationLevel;

  /// Whether to generate dump info
  final bool dumpInfo;

  /// Whether to use frequency-based minification
  final bool frequencyBasedMinification;

  /// Creates a new WebBuildConfig.
  const WebBuildConfig({
    this.baseHref,
    this.pwaStrategy,
    this.webRenderer,
    this.webResourcesCdn = true,
    this.csp = false,
    this.sourceMaps = false,
    this.optimizationLevel,
    this.dumpInfo = false,
    this.frequencyBasedMinification = true,
  });

  @override
  String toString() {
    return 'WebBuildConfig('
        'baseHref: $baseHref, '
        'pwaStrategy: $pwaStrategy, '
        'webRenderer: $webRenderer'
        ')';
  }
}

/// Web PWA caching strategy enumeration.
enum WebPwaStrategy {
  /// No service worker caching
  none,

  /// Offline-first caching strategy
  offlineFirst;

  /// Converts to command-line argument string.
  String toArgumentString() {
    switch (this) {
      case WebPwaStrategy.none:
        return 'none';
      case WebPwaStrategy.offlineFirst:
        return 'offline-first';
    }
  }
}

/// Web renderer implementation enumeration.
enum WebRenderer {
  /// Automatic renderer selection
  auto,

  /// CanvasKit WebGL renderer
  canvaskit,

  /// HTML DOM renderer
  html,

  /// Experimental Skwasm renderer
  skwasm;

  /// Converts to command-line argument string.
  String toArgumentString() {
    switch (this) {
      case WebRenderer.auto:
        return 'auto';
      case WebRenderer.canvaskit:
        return 'canvaskit';
      case WebRenderer.html:
        return 'html';
      case WebRenderer.skwasm:
        return 'skwasm';
    }
  }
}

/// Web optimization level enumeration.
enum WebOptimizationLevel {
  /// Optimization level O1
  o1,

  /// Optimization level O2
  o2,

  /// Optimization level O3
  o3,

  /// Optimization level O4 (default)
  o4;

  /// Converts to command-line argument string.
  String toArgumentString() {
    switch (this) {
      case WebOptimizationLevel.o1:
        return 'O1';
      case WebOptimizationLevel.o2:
        return 'O2';
      case WebOptimizationLevel.o3:
        return 'O3';
      case WebOptimizationLevel.o4:
        return 'O4';
    }
  }
}
