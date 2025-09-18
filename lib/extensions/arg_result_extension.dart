import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Extension methods for [ArgResults] to retrieve parsed CLI argument values.
///
/// This extension provides a set of methods that make it easy to retrieve
/// parsed command-line argument values from [ArgResults] in the Morpheme CLI.
///
/// Example usage:
/// ```dart
/// final results = parser.parse(args);
/// final isDebug = results.getFlagDebug();
/// final flavor = results.getOptionFlavor(defaultTo: 'development');
/// ```
extension ArgResultsExtension on ArgResults? {
  /// Gets the target file path.
  ///
  /// Returns the main entry-point file of the application.
  ///
  /// Defaults to `lib/main.dart`.
  ///
  /// Example:
  /// ```dart
  /// final target = argResults.getOptionTarget();
  /// ```
  String getOptionTarget() => this?['target'] ?? 'lib/main.dart';

  /// Gets the custom path to morpheme.yaml.
  ///
  /// Returns the custom path to the morpheme.yaml configuration file.
  /// If not specified, looks for a default path in pubspec.yaml or falls back
  /// to `morpheme.yaml` in the current directory.
  ///
  /// Example:
  /// ```dart
  /// final morphemeYamlPath = argResults.getOptionMorphemeYaml();
  /// ```
  String getOptionMorphemeYaml() {
    final path = join(current, 'pubspec.yaml');
    if (exists(path)) {
      final pathMorphemeCli = YamlHelper.loadFileYaml(path)['morpheme_cli'];
      if (pathMorphemeCli != null) {
        return pathMorphemeCli;
      }
    }
    return this?['morpheme-yaml'] ?? join(current, 'morpheme.yaml');
  }

  /// Gets the flavor option value.
  ///
  /// Returns the selected application flavor.
  ///
  /// Example:
  /// ```dart
  /// final flavor = argResults.getOptionFlavor(defaultTo: 'development');
  /// ```
  String getOptionFlavor({required String defaultTo}) =>
      this?['flavor'] ?? defaultTo;

  /// Gets the export method option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--export-method "value"'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final exportMethodFlag = argResults.getOptionExportMethod();
  /// // Returns '--export-method "app-store"' or ''
  /// ```
  String getOptionExportMethod() => this?['export-method'] != null
      ? '--export-method "${this!['export-method']}"'
      : '';

  /// Gets the export options plist option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--export-options-plist "value"'` if the option is provided
  /// - `null` if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final exportOptionsPlistFlag = argResults.getOptionExportOptionsPlist();
  /// // Returns '--export-options-plist "path/to/plist"' or null
  /// ```
  String? getOptionExportOptionsPlist() => this?['export-options-plist'] != null
      ? '--export-options-plist "${this!['export-options-plist']}"'
      : '';

  /// Gets the build number option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--build-number=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final buildNumberFlag = argResults.getOptionBuildNumber();
  /// // Returns '--build-number=123' or ''
  /// ```
  String getOptionBuildNumber() => this?['build-number'] != null
      ? '--build-number=${this!['build-number']}'
      : '';

  /// Gets the build name option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--build-name=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final buildNameFlag = argResults.getOptionBuildName();
  /// // Returns '--build-name=1.0.0' or ''
  /// ```
  String getOptionBuildName() =>
      this?['build-name'] != null ? '--build-name=${this!['build-name']}' : '';

  /// Gets the debug flag value.
  ///
  /// Returns `true` if the debug flag is set, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isDebug = argResults.getFlagDebug();
  /// ```
  bool getFlagDebug() => this?['debug'] ?? false;

  /// Gets the profile flag value.
  ///
  /// Returns `true` if the profile flag is set, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isProfile = argResults.getFlagProfile();
  /// ```
  bool getFlagProfile() => this?['profile'] ?? false;

  /// Gets the release flag value.
  ///
  /// Returns `true` if the release flag is set, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isRelease = argResults.getFlagRelease();
  /// ```
  bool getFlagRelease() => this?['release'] ?? false;

  /// Gets the codesign flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--codesign'` if the flag is set to true
  /// - `'--no-codesign'` if the flag is set to false or not provided
  ///
  /// Example:
  /// ```dart
  /// final codesignFlag = argResults.getFlagCodesign();
  /// // Returns '--codesign' or '--no-codesign'
  /// ```
  String getFlagCodesign() =>
      this?['codesign'] ?? true ? '--codesign' : '--no-codesign';

  /// Gets the build mode as a command-line flag.
  ///
  /// Returns:
  /// - `'--debug'` if debug flag is set
  /// - `'--profile'` if profile flag is set
  /// - `'--release'` as default if neither debug nor profile is set
  ///
  /// Example:
  /// ```dart
  /// final modeFlag = argResults.getMode();
  /// // Returns '--debug', '--profile', or '--release'
  /// ```
  String getMode() {
    String mode = '--release';
    if (getFlagDebug()) {
      mode = '--debug';
    } else if (getFlagProfile()) {
      mode = '--profile';
    }
    return mode;
  }

  /// Gets the obfuscate flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--obfuscate'` if the flag is set to true
  /// - Empty string if the flag is set to false or not provided
  ///
  /// Example:
  /// ```dart
  /// final obfuscateFlag = argResults.getFlagObfuscate();
  /// // Returns '--obfuscate' or ''
  /// ```
  String getFlagObfuscate() => this?['obfuscate'] ?? false ? '--obfuscate' : '';

  /// Gets the obfuscate flag value as a boolean.
  ///
  /// Returns `true` if the obfuscate flag is set, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final shouldObfuscate = argResults.getFlagObfuscateBool();
  /// ```
  bool getFlagObfuscateBool() => this?['obfuscate'] ?? false;

  /// Gets the split debug info option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--split-debug-info=value'` if both the option is provided and obfuscate is true
  /// - Empty string otherwise
  ///
  /// Example:
  /// ```dart
  /// final splitDebugInfoFlag = argResults.getOptionSplitDebugInfo();
  /// // Returns '--split-debug-info=./.symbols/' or ''
  /// ```
  String getOptionSplitDebugInfo() =>
      this?['split-debug-info'] != null && (this?['obfuscate'] ?? false)
          ? '--split-debug-info=${this!['split-debug-info']}'
          : '';

  /// Gets the generate l10n flag value.
  ///
  /// Returns `true` if the generate l10n flag is set, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final shouldGenerateL10n = argResults.getFlagGenerateL10n();
  /// ```
  bool getFlagGenerateL10n() => this?['l10n'] ?? false;

  /// Gets the base href option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--base-href=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final baseHrefFlag = argResults.getOptionBaseHref();
  /// // Returns '--base-href=/my-app/' or ''
  /// ```
  String getOptionBaseHref() =>
      this?['base-href'] != null ? '--base-href=${this!['base-href']}' : '';

  /// Gets the PWA strategy option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--pwa-strategy=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final pwaStrategyFlag = argResults.getOptionPwaStrategy();
  /// // Returns '--pwa-strategy=offline-first' or ''
  /// ```
  String getOptionPwaStrategy() => this?['pwa-strategy'] != null
      ? '--pwa-strategy=${this!['pwa-strategy']}'
      : '';

  /// Gets the web renderer option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--web-renderer=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final webRendererFlag = argResults.getOptionWebRenderer();
  /// // Returns '--web-renderer=canvaskit' or ''
  /// ```
  String getOptionWebRenderer() => this?['web-renderer'] != null
      ? '--web-renderer=${this!['web-renderer']}'
      : '';

  /// Gets the web resources CDN flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - Empty string if the flag is set to true or not provided
  /// - `'--no-web-resources-cdn'` if the flag is set to false
  ///
  /// Example:
  /// ```dart
  /// final webResourcesCdnFlag = argResults.getFlagWebResourcesCdn();
  /// // Returns '' or '--no-web-resources-cdn'
  /// ```
  String getFlagWebResourcesCdn() =>
      this?['web-resources-cdn'] ?? true ? '' : '--no-web-resources-cdn';

  /// Gets the CSP flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--csp'` if the flag is set to true
  /// - Empty string if the flag is set to false or not provided
  ///
  /// Example:
  /// ```dart
  /// final cspFlag = argResults.getFlagCsp();
  /// // Returns '--csp' or ''
  /// ```
  String getFlagCsp() => this?['csp'] ?? false ? '--csp' : '';

  /// Gets the source maps flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--source-maps'` if the flag is set to true
  /// - Empty string if the flag is set to false or not provided
  ///
  /// Example:
  /// ```dart
  /// final sourceMapsFlag = argResults.getFlagSourceMaps();
  /// // Returns '--source-maps' or ''
  /// ```
  String getFlagSourceMaps() => this?['source-maps'] ?? false ? '--source-maps' : '';

  /// Gets the dart2js optimization option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--dart2js-optimization=value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final dart2jsOptimizationFlag = argResults.getOptionDart2JsOptimization();
  /// // Returns '--dart2js-optimization=O3' or ''
  /// ```
  String getOptionDart2JsOptimization() => this?['dart2js-optimization'] != null
      ? '--dart2js-optimization=${this!['dart2js-optimization']}'
      : '';

  /// Gets the dump info flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--dump-info'` if the flag is set to true
  /// - Empty string if the flag is set to false or not provided
  ///
  /// Example:
  /// ```dart
  /// final dumpInfoFlag = argResults.getFlagDumpInfo();
  /// // Returns '--dump-info' or ''
  /// ```
  String getFlagDumpInfo() => this?['dump-info'] ?? false ? '--dump-info' : '';

  /// Gets the frequency based minification flag value formatted for command-line usage.
  ///
  /// Returns:
  /// - Empty string if the flag is set to true or not provided
  /// - `'--no-frequency-based-minification'` if the flag is set to false
  ///
  /// Example:
  /// ```dart
  /// final frequencyBasedMinificationFlag = argResults.getFlagFrequencyBasedMinification();
  /// // Returns '' or '--no-frequency-based-minification'
  /// ```
  String getFlagFrequencyBasedMinification() =>
      this?['frequency-based-minification'] ?? true
          ? ''
          : '--no-frequency-based-minification';

  /// Gets the device ID option formatted for command-line usage.
  ///
  /// Returns:
  /// - `'--device-id value'` if the option is provided
  /// - Empty string if the option is not provided
  ///
  /// Example:
  /// ```dart
  /// final deviceIdFlag = argResults.getDeviceId();
  /// // Returns '--device-id emulator-5554' or ''
  /// ```
  String getDeviceId() =>
      this?['device-id'] != null ? '--device-id ${this?['device-id']}' : '';
}