import 'package:morpheme_cli/dependency_manager.dart';

extension ArgParserExtension on ArgParser {
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

  void addOptionMorphemeYaml() {
    addOption(
      'morpheme-yaml',
      help: '''Custom path morpheme.yaml.''',
    );
  }

  void addFlagDebug({bool defaultsTo = false}) {
    addFlag(
      'debug',
      help: 'Build a debug version of your app.',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  void addFlagProfile({bool defaultsTo = false}) {
    addFlag(
      'profile',
      help:
          'Build a version of your app specialized for performance profiling.',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  void addFlagRelease({bool defaultsTo = true}) {
    addFlag(
      'release',
      help: 'Build a release version of your app  (default mode).',
      defaultsTo: defaultsTo,
      negatable: false,
    );
  }

  void addOptionFlavor({required String defaultsTo}) {
    addOption(
      'flavor',
      abbr: 'f',
      help: 'Select flavor apps.',
      defaultsTo: defaultsTo,
    );
  }

  void addOptionExportMethod() {
    addOption(
      'export-method',
      help: 'Specify how the IPA will be distributed.',
      allowed: ['ad-hoc', 'app-store', 'development', 'enterprise'],
    );
  }

  void addOptionExportOptionsPlist() {
    addOption(
      'export-options-plist',
      help:
          'Export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys.',
    );
  }

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

  void addOptionBuildName() {
    addOption(
      'build-name',
      help: '''A "x.y.z" string used as the version number shown to users.
For each new version of your app, you will provide a version number to differentiate it from previous versions.
On Android it is used as "versionName".
On Xcode builds it is used as "CFBundleShortVersionString"".''',
    );
  }

  void addFlagCodesign({bool defaultsTo = true}) {
    addFlag(
      'codesign',
      help:
          'Codesign the application bundle (only available on device builds).',
      defaultsTo: defaultsTo,
    );
  }

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

  void addFlagGenerateL10n({bool defaultsTo = true}) {
    addFlag(
      'l10n',
      help: 'Generate l10n first before running other command.',
      defaultsTo: defaultsTo,
    );
  }

  void addOptionBaseHref() {
    addOption(
      'base-href',
      help:
          '''Overrides the href attribute of the <base> tag in web/index.html. No change is done to web/index.html file if this flag is not
provided. The value has to start and end with a slash "/". For more information:
https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base''',
    );
  }

  void addOptionPwaStrategy() {
    addOption(
      'pwa-strategy',
      help: '''The caching strategy to be used by the PWA service worker.
none: Generate a service worker with no body. This is useful for local testing or in cases where the service worker caching functionality is not desirable
offline-first(default): Attempt to cache the application shell eagerly and then lazily cache all subsequent assets as they are loaded. When making a network request for an asset, the offline cache will be preferred.''',
      allowed: ['none', 'offline-first'],
    );
  }

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

  void addFlagWebResourcesCdn({bool defaultsTo = true}) {
    addFlag(
      'web-resources-cdn',
      help: 'Use Web static resources hosted on a CDN.',
      defaultsTo: defaultsTo,
    );
  }

  void addFlagCsp({bool defaultsTo = false}) {
    addFlag(
      'csp',
      help:
          'Disable dynamic generation of code in the generated output. This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).',
      defaultsTo: defaultsTo,
    );
  }

  void addFlagSourceMaps({bool defaultsTo = false}) {
    addFlag(
      'source-maps',
      help:
          'Generate a sourcemap file. These can be used by browsers to view and debug the original source code of a compiled and minified Dart application.',
      defaultsTo: defaultsTo,
    );
  }

  void addOptionDart2JsOptimization() {
    addOption(
      'dart2js-optimization',
      help:
          '''Sets the optimization level used for Dart compilation to JavaScript. Valid values range from O1 to O4. [O1, O2, O3, O4 (default)]''',
      allowed: ['O1', 'O2', 'O3', 'O4'],
    );
  }

  void addFlagDumpInfo({bool defaultsTo = false}) {
    addFlag(
      'dump-info',
      help:
          'Passes "--dump-info" to the Javascript compiler which generates information about the generated code is a .js.info.json file.',
      defaultsTo: defaultsTo,
    );
  }

  void addFlagFrequencyBasedMinification({bool defaultsTo = true}) {
    addFlag(
      'frequency-based-minification',
      help:
          'Disables the frequency based minifier. Useful for comparing the output between builds.',
      defaultsTo: defaultsTo,
    );
  }
}
