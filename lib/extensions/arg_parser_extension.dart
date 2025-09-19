import 'package:morpheme_cli/dependency_manager.dart';

/// Extension methods for [ArgParser] to add common CLI options and flags.
///
/// This extension provides a set of methods that make it easy to add common
/// command-line options and flags to commands in the Morpheme CLI.
///
/// Example usage:
/// ```dart
/// final parser = ArgParser();
/// parser.addFlagDebug();
/// parser.addOptionFlavor(defaultsTo: 'development');
/// ```
extension ArgParserExtension on ArgParser {
  /// Adds a target file option for specifying the main entry-point file.
  ///
  /// The main entry-point file of the application, as run on the device.
  /// If the "--target" option is omitted, but a file name is provided on the
  /// command line, then that is used instead.
  ///
  /// Defaults to `lib/main.dart`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionTarget();
  /// ```
  void addOptionTarget() {
    addOption(
      'target',
      abbr: 't',
      help:
          '''The main entry-point file of the application, as run on the device.
If the "--target" option is omitted, but a file name is provided on the command line, then that is
used instead.''',
      defaultsTo: 'lib/main.dart',
    );
  }

  /// Adds an option for specifying a custom path to morpheme.yaml.
  ///
  /// Allows users to specify a custom path to their morpheme.yaml configuration file.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionMorphemeYaml();
  /// ```
  void addOptionMorphemeYaml() {
    addOption(
      'morpheme-yaml',
      help: '''Custom path morpheme.yaml.''',
    );
  }

  /// Adds a debug flag to build a debug version of the app.
  ///
  /// When set, builds a debug version of your app.
  ///
  /// Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagDebug(defaultsTo: true);
  /// ```
  void addFlagDebug({bool defaultsTo = false}) {
    addFlag(
      'debug',
      help: 'Build a debug version of your app.',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  /// Adds a profile flag for performance profiling builds.
  ///
  /// Builds a version of your app specialized for performance profiling.
  ///
  /// Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagProfile(defaultsTo: true);
  /// ```
  void addFlagProfile({bool defaultsTo = false}) {
    addFlag(
      'profile',
      help:
          'Build a version of your app specialized for performance profiling.',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  /// Adds a release flag to build a release version of the app.
  ///
  /// Builds a release version of your app (default mode).
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagRelease(defaultsTo: false);
  /// ```
  void addFlagRelease({bool defaultsTo = true}) {
    addFlag(
      'release',
      help: 'Build a release version of your app  (default mode).',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  /// Adds a flavor option for selecting application flavors.
  ///
  /// Allows users to select different flavors of the application.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionFlavor(defaultsTo: 'development');
  /// ```
  void addOptionFlavor({required String defaultsTo}) {
    addOption(
      'flavor',
      abbr: 'f',
      help: 'Select flavor apps.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds an export method option for IPA distribution.
  ///
  /// Specify how the IPA will be distributed.
  ///
  /// Allowed values:
  /// - `ad-hoc`
  /// - `app-store`
  /// - `development`
  /// - `enterprise`
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionExportMethod();
  /// ```
  void addOptionExportMethod() {
    addOption(
      'export-method',
      help: 'Specify how the IPA will be distributed.',
      allowed: ['ad-hoc', 'app-store', 'development', 'enterprise'],
    );
  }

  /// Adds an export options plist option.
  ///
  /// Export an IPA with these options. See "xcodebuild -h" for available
  /// exportOptionsPlist keys.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionExportOptionsPlist();
  /// ```
  void addOptionExportOptionsPlist() {
    addOption(
      'export-options-plist',
      help:
          'Export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys.',
    );
  }

  /// Adds a build number option for versioning.
  ///
  /// An identifier used as an internal version number.
  /// Each build must have a unique identifier to differentiate it from previous builds.
  /// It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
  /// On Android it is used as "versionCode".
  /// On Xcode builds it is used as "CFBundleVersion".
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionBuildNumber();
  /// ```
  void addOptionBuildNumber() {
    addOption(
      'build-number',
      help: '''An identifier used as an internal version number.
Each build must have a unique identifier to differentiate it from previous builds.
It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
On Android it is used as "versionCode".
On Xcode builds it is used as "CFBundleVersion".''',
    );
  }

  /// Adds a build name option for versioning.
  ///
  /// A "x.y.z" string used as the version number shown to users.
  /// For each new version of your app, you will provide a version number to differentiate it from previous versions.
  /// On Android it is used as "versionName".
  /// On Xcode builds it is used as "CFBundleShortVersionString".
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionBuildName();
  /// ```
  void addOptionBuildName() {
    addOption(
      'build-name',
      help: '''A "x.y.z" string used as the version number shown to users.
For each new version of your app, you will provide a version number to differentiate it from previous versions.
On Android it is used as "versionName".
On Xcode builds it is used as "CFBundleShortVersionString".''',
    );
  }

  /// Adds a codesign flag for application bundle signing.
  ///
  /// Codesign the application bundle (only available on device builds).
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagCodesign(defaultsTo: false);
  /// ```
  void addFlagCodesign({bool defaultsTo = true}) {
    addFlag(
      'codesign',
      help:
          'Codesign the application bundle (only available on device builds).',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds an obfuscate flag for source code obfuscation.
  ///
  /// In a release build, this flag removes identifiers and replaces them with randomized values for the purposes of source code obfuscation.
  /// This flag must always be combined with "--split-debug-info" option, the mapping between the values and the original identifiers is stored in the symbol map created in the specified directory.
  /// For an app built with this flag, the "flutter symbolize" command with the right program symbol file is required to obtain a human readable stack trace.
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagObfuscate();
  /// ```
  void addFlagObfuscate() {
    addFlag(
      'obfuscate',
      help:
          '''In a release build, this flag removes identifiers and replaces them with randomized values for the purposes of source code obfuscation. This flag must always be combined with
"--split-debug-info" option, the mapping between the values and the original identifiers is stored in the symbol map created in the specified directory. For an app built with
this flag, the "flutter symbolize" command with the right program symbol file is required to obtain a human readable stack trace.''',
      defaultsTo: true,
    );
  }

  /// Adds a split debug info option for reducing application size.
  ///
  /// In a release build, this flag reduces application size by storing Dart program symbols in a separate file on the host rather than in the application.
  /// The value of the flag should be a directory where program symbol files can be stored for later use.
  /// These symbol files contain the information needed to symbolize Dart stack traces.
  /// For an app built with this flag, the "flutter symbolize" command with the right program symbol file is required to obtain a human readable stack trace.
  /// This flag cannot be combined with "--analyze-size".
  ///
  /// Defaults to `./.symbols/`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionSplitDebugInfo();
  /// ```
  void addOptionSplitDebugInfo() {
    addOption(
      'split-debug-info',
      help:
          '''In a release build, this flag reduces application size by storing Dart program symbols in a separate file on the host rather than in the application. The value of the flag
should be a directory where program symbol files can be stored for later use. These symbol files contain the information needed to symbolize Dart stack traces. For an app built
with this flag, the "flutter symbolize" command with the right program symbol file is required to obtain a human readable stack trace.
This flag cannot be combined with "--analyze-size".''',
      defaultsTo: './.symbols/',
    );
  }

  /// Adds a use app option for specifying pre-built application binaries.
  ///
  /// Specify a pre-built application binary to use when running.
  /// For Android applications, this must be the path to an APK.
  /// For iOS applications, the path to an IPA.
  /// Other device types do not yet support prebuilt application binaries.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionUseApp();
  /// ```
  void addOptionUseApp() {
    addOption(
      'use-app',
      abbr: 'a',
      help:
          '''Specify a pre-built application binary to use when running. For Android applications, this must be the
path to an APK. For iOS applications, the path to an IPA. Other device types do not yet support
prebuilt application binaries.''',
    );
  }

  /// Adds a generate l10n flag for localization generation.
  ///
  /// Generate l10n first before running other command.
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagGenerateL10n(defaultsTo: false);
  /// ```
  void addFlagGenerateL10n({bool defaultsTo = true}) {
    addFlag(
      'l10n',
      help: 'Generate l10n first before running other command.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a base href option for web applications.
  ///
  /// Overrides the href attribute of the &lt;base&gt; tag in web/index.html.
  /// No change is done to web/index.html file if this flag is not provided.
  /// The value has to start and end with a slash "/".
  /// For more information: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionBaseHref();
  /// ```
  void addOptionBaseHref() {
    addOption(
      'base-href',
      help:
          '''Overrides the href attribute of the <base> tag in web/index.html. No change is done to web/index.html file if this flag is not
provided. The value has to start and end with a slash "/". For more information:
https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base''',
    );
  }

  /// Adds a PWA strategy option for web applications.
  ///
  /// The caching strategy to be used by the PWA service worker.
  ///
  /// Allowed values:
  /// - `none`: Generate a service worker with no body. This is useful for local testing or in cases where the service worker caching functionality is not desirable
  /// - `offline-first` (default): Attempt to cache the application shell eagerly and then lazily cache all subsequent assets as they are loaded. When making a network request for an asset, the offline cache will be preferred.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionPwaStrategy();
  /// ```
  void addOptionPwaStrategy() {
    addOption(
      'pwa-strategy',
      help: '''The caching strategy to be used by the PWA service worker.
none: Generate a service worker with no body. This is useful for local testing or in cases where the service worker caching functionality is not desirable
offline-first(default): Attempt to cache the application shell eagerly and then lazily cache all subsequent assets as they are loaded. When making a network request for an asset, the offline cache will be preferred.''',
      allowed: ['none', 'offline-first'],
    );
  }

  /// Adds a web renderer option for web applications.
  ///
  /// The renderer implementation to use when building for the web.
  ///
  /// Allowed values:
  /// - `auto` (default): Use the HTML renderer on mobile devices, and CanvasKit on desktop devices.
  /// - `canvaskit`: Always use the CanvasKit renderer. This renderer uses WebGL and WebAssembly to render graphics.
  /// - `html`: Always use the HTML renderer. This renderer uses a combination of HTML, CSS, SVG, 2D Canvas, and WebGL.
  /// - `skwasm`: Always use the experimental skwasm renderer.
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionWebRenderer();
  /// ```
  void addOptionWebRenderer() {
    addOption(
      'web-renderer',
      help: '''The renderer implementation to use when building for the web.
[auto] (default): Use the HTML renderer on mobile devices, and CanvasKit on desktop devices.
[canvaskit]: Always use the CanvasKit renderer. This renderer uses WebGL and WebAssembly to render graphics.
[html]: Always use the HTML renderer. This renderer uses a combination of HTML, CSS, SVG, 2D Canvas, and WebGL.
[skwasm]: Always use the experimental skwasm renderer.''',
      allowed: ['auto', 'canvaskit', 'html', 'skwasm'],
    );
  }

  /// Adds a web resources CDN flag.
  ///
  /// Use Web static resources hosted on a CDN.
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagWebResourcesCdn(defaultsTo: false);
  /// ```
  void addFlagWebResourcesCdn({bool defaultsTo = true}) {
    addFlag(
      'web-resources-cdn',
      help: 'Use Web static resources hosted on a CDN.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a CSP flag for content security policy.
  ///
  /// Disable dynamic generation of code in the generated output.
  /// This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).
  ///
  /// Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagCsp(defaultsTo: true);
  /// ```
  void addFlagCsp({bool defaultsTo = false}) {
    addFlag(
      'csp',
      help:
          'Disable dynamic generation of code in the generated output. This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a source maps flag for debugging.
  ///
  /// Generate a sourcemap file.
  /// These can be used by browsers to view and debug the original source code of a compiled and minified Dart application.
  ///
  /// Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagSourceMaps(defaultsTo: true);
  /// ```
  void addFlagSourceMaps({bool defaultsTo = false}) {
    addFlag(
      'source-maps',
      help:
          'Generate a sourcemap file. These can be used by browsers to view and debug the original source code of a compiled and minified Dart application.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a dart2js optimization option.
  ///
  /// Sets the optimization level used for Dart compilation to JavaScript.
  /// Valid values range from O1 to O4.
  ///
  /// Allowed values:
  /// - `O1`
  /// - `O2`
  /// - `O3`
  /// - `O4` (default)
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionDart2JsOptimization();
  /// ```
  void addOptionDart2JsOptimization() {
    addOption(
      'dart2js-optimization',
      help:
          '''Sets the optimization level used for Dart compilation to JavaScript. Valid values range from O1 to O4. [O1, O2, O3, O4 (default)]''',
      allowed: ['O1', 'O2', 'O3', 'O4'],
    );
  }

  /// Adds a dump info flag for JavaScript compiler information.
  ///
  /// Passes "--dump-info" to the Javascript compiler which generates information about the generated code is a .js.info.json file.
  ///
  /// Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagDumpInfo(defaultsTo: true);
  /// ```
  void addFlagDumpInfo({bool defaultsTo = false}) {
    addFlag(
      'dump-info',
      help:
          'Passes "--dump-info" to the Javascript compiler which generates information about the generated code is a .js.info.json file.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a frequency based minification flag.
  ///
  /// Disables the frequency based minifier.
  /// Useful for comparing the output between builds.
  ///
  /// Defaults to `true`.
  ///
  /// Example:
  /// ```dart
  /// argParser.addFlagFrequencyBasedMinification(defaultsTo: false);
  /// ```
  void addFlagFrequencyBasedMinification({bool defaultsTo = true}) {
    addFlag(
      'frequency-based-minification',
      help:
          'Disables the frequency based minifier. Useful for comparing the output between builds.',
      defaultsTo: defaultsTo,
    );
  }

  /// Adds a device ID option for targeting specific devices.
  ///
  /// Target device id or name (prefixes allowed).
  ///
  /// Example:
  /// ```dart
  /// argParser.addOptionDeviceId();
  /// ```
  void addOptionDeviceId() {
    addOption(
      'device-id',
      abbr: 'd',
      help: '''Target device id or name (prefixes allowed).''',
    );
  }
}
