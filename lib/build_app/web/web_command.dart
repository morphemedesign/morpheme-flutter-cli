import 'dart:io';

import 'package:morpheme_cli/build_app/base/base.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Web application build command implementation.
///
/// Builds Flutter web applications with support for modern web deployment
/// patterns including PWA generation, CDN optimization, and various
/// web renderers (HTML, CanvasKit, Skwasm).
///
/// ## Platform Requirements
/// - Flutter SDK with web support enabled
/// - Modern web browser for testing
/// - Web server for deployment (nginx, Apache, etc.)
///
/// ## Build Optimizations
/// - Tree shaking and code splitting for optimal bundle sizes
/// - Asset optimization for web delivery
/// - Progressive Web App (PWA) support
/// - Content Security Policy (CSP) compliance
/// - Source map generation for debugging
///
/// ## Web Renderers
/// - **auto**: HTML on mobile, CanvasKit on desktop (default)
/// - **canvaskit**: WebGL/WebAssembly renderer for better performance
/// - **html**: DOM-based renderer for better compatibility
/// - **skwasm**: Experimental WebAssembly renderer
///
/// ## Deployment Considerations
/// - Base href configuration for subdirectory deployment
/// - CDN resource optimization
/// - Browser compatibility and fallbacks
/// - CORS configuration for API access
///
/// ## Configuration
/// Uses morpheme.yaml for web-specific configuration:
/// ```yaml
/// web:
///   prod:
///     baseHref: "/app/"
///     webRenderer: "canvaskit"
///     pwaStrategy: "offline-first"
///     csp: true
/// ```
///
/// ## Usage Examples
/// ```bash
/// # Build for production with CanvasKit renderer
/// morpheme build web --flavor prod --web-renderer canvaskit
///
/// # Build PWA with offline support
/// morpheme build web --pwa-strategy offline-first
///
/// # Build with custom base href for subdirectory
/// morpheme build web --base-href /myapp/
///
/// # Build with CSP compliance
/// morpheme build web --csp --no-source-maps
/// ```
class WebCommand extends BaseBuildCommand {
  @override
  String get name => 'web';

  @override
  String get description =>
      'Build web application with flavor support and modern optimizations.';

  @override
  String get platformName => 'Web';

  @override
  void configurePlatformArguments() {
    super.configurePlatformArguments();

    // Web-specific build options
    argParser.addOptionBaseHref();
    argParser.addOptionPwaStrategy();
    argParser.addOptionWebRenderer();
    argParser.addFlagWebResourcesCdn();
    argParser.addFlagCsp();
    argParser.addFlagSourceMaps();
    argParser.addOptionDart2JsOptimization();
    argParser.addFlagDumpInfo();
    argParser.addFlagFrequencyBasedMinification();
  }

  @override
  ValidationResult<bool> validatePlatformEnvironment() {
    // Check Flutter web support
    try {
      final result = Process.runSync('flutter', ['config']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.contains('enable-web: false')) {
          return ValidationResult.error(
            'Flutter web support is disabled',
            suggestion: 'Enable Flutter web support',
            examples: [
              'flutter config --enable-web',
              'flutter doctor',
            ],
          );
        }
      }
    } catch (e) {
      BuildProgressReporter.reportWarning(
        'Could not verify Flutter web support: $e',
      );
    }

    // Check for Chrome (for testing)
    final chromeCommands = [
      'google-chrome',
      'chromium-browser',
      'chrome',
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    ];

    bool chromeFound = false;
    for (final command in chromeCommands) {
      if (which(command).found || exists(command)) {
        chromeFound = true;
        break;
      }
    }

    if (!chromeFound) {
      BuildProgressReporter.reportWarning(
        'Chrome browser not found - recommended for web development and testing',
        severity: 'INFO',
      );
    }

    return ValidationResult.success(true);
  }

  @override
  Future<void> executePlatformBuild(BuildConfiguration config) async {
    try {
      // Extract web-specific arguments
      final baseHref = argResults?.getOptionBaseHref();
      final pwaStrategy = argResults?.getOptionPwaStrategy();
      final webRenderer = argResults?.getOptionWebRenderer();
      final webResourcesCdn =
          (argResults?.getFlagWebResourcesCdn() ?? true) as bool;
      final csp = (argResults?.getFlagCsp() ?? false) as bool;
      final sourceMaps = (argResults?.getFlagSourceMaps() ?? false) as bool;
      final dart2JsOptimization = argResults?.getOptionDart2JsOptimization();
      final dumpInfo = (argResults?.getFlagDumpInfo() ?? false) as bool;
      final frequencyBasedMinification =
          (argResults?.getFlagFrequencyBasedMinification() ?? true) as bool;

      BuildProgressReporter.reportBuildEnvironment(platformName, {
        'flavor': config.flavor,
        'mode': config.mode.displayName,
        'target': config.target,
        'webRenderer': webRenderer ?? 'auto',
        'pwaStrategy': pwaStrategy ?? 'offline-first',
        'csp': csp,
        'cdn': webResourcesCdn,
      });

      // Validate web configuration
      if (config.webConfig != null) {
        _validateWebConfiguration(config.webConfig!, baseHref);
      }

      // Build Flutter arguments for web
      final arguments = buildFlutterArguments(config, 'web');

      // Add web-specific arguments
      if (baseHref != null && baseHref.isNotEmpty) {
        arguments.addAll(['--base-href', baseHref]);
      }

      if (pwaStrategy != null && pwaStrategy.isNotEmpty) {
        arguments.addAll(['--pwa-strategy', pwaStrategy]);
      }

      if (webRenderer != null && webRenderer.isNotEmpty) {
        arguments.addAll(['--web-renderer', webRenderer]);
      }

      if (webResourcesCdn) {
        arguments.add('--web-resources-cdn');
      } else {
        arguments.add('--no-web-resources-cdn');
      }

      if (csp) {
        arguments.add('--csp');
      }

      if (sourceMaps) {
        arguments.add('--source-maps');
      }

      if (dart2JsOptimization != null && dart2JsOptimization.isNotEmpty) {
        arguments.addAll(['--dart2js-optimization', dart2JsOptimization]);
      }

      if (dumpInfo) {
        arguments.add('--dump-info');
      }

      if (frequencyBasedMinification) {
        arguments.add('--frequency-based-minification');
      } else {
        arguments.add('--no-frequency-based-minification');
      }

      BuildProgressReporter.reportBuildStage(
        BuildStage.dependencies,
        0.1,
        estimatedRemaining: Duration(minutes: 1),
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.compilation,
        0.3,
        estimatedRemaining: Duration(minutes: 4),
      );

      // Execute Flutter build command
      await FlutterHelper.run(
        arguments.join(' '),
        showLog: true,
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.assets,
        0.8,
        estimatedRemaining: Duration(seconds: 30),
      );

      BuildProgressReporter.reportBuildStage(
        BuildStage.packaging,
        0.95,
        estimatedRemaining: Duration(seconds: 15),
      );

      // Report build artifacts and analysis
      final webPath = _findWebBuildOutput();
      if (webPath != null) {
        final artifacts = _analyzeBuildOutput(webPath);
        BuildProgressReporter.reportBuildArtifacts(artifacts);

        // Provide deployment guidance
        _reportDeploymentInfo(webPath, baseHref, pwaStrategy);

        // Analyze build performance
        _analyzeWebBuildPerformance(webPath, dumpInfo);
      }
    } catch (e) {
      throw BuildCommandException(
        BuildCommandError.buildProcessFailure,
        'Web build failed',
        platform: platformName,
        suggestion: 'Check build logs and web configuration',
        examples: [
          'flutter clean',
          'flutter pub get',
          'flutter config --enable-web',
        ],
        diagnosticCommands: [
          'flutter doctor',
          'flutter config',
          'dart --version',
        ],
        recoverySteps: [
          'Clean the project with "flutter clean"',
          'Get dependencies with "flutter pub get"',
          'Enable web support with "flutter config --enable-web"',
          'Check for web-specific dependencies in pubspec.yaml',
        ],
      );
    }
  }

  /// Validates web-specific configuration.
  ///
  /// Checks base href format, PWA settings, and other
  /// web-specific build requirements.
  void _validateWebConfiguration(WebBuildConfig webConfig, String? baseHref) {
    // Validate base href format
    final effectiveBaseHref = baseHref ?? webConfig.baseHref;
    if (effectiveBaseHref != null) {
      if (!effectiveBaseHref.startsWith('/') ||
          !effectiveBaseHref.endsWith('/')) {
        throw BuildCommandException(
          BuildCommandError.buildConfigurationInvalid,
          'Base href must start and end with "/": $effectiveBaseHref',
          suggestion:
              'Format base href as "/path/" with leading and trailing slashes',
          examples: ['/', '/app/', '/subdirectory/'],
        );
      }
    }

    // Validate PWA strategy
    if (webConfig.pwaStrategy != null) {
      BuildProgressReporter.reportPreparationStep(
        'PWA strategy: ${webConfig.pwaStrategy!.toArgumentString()}',
        true,
      );
    }

    // Validate web renderer
    if (webConfig.webRenderer != null) {
      BuildProgressReporter.reportPreparationStep(
        'Web renderer: ${webConfig.webRenderer!.toArgumentString()}',
        true,
      );
    }
  }

  /// Finds the web build output directory.
  ///
  /// Returns: Path to web build output or null if not found
  String? _findWebBuildOutput() {
    final commonPaths = [
      'build/web',
      'web/build',
    ];

    for (final path in commonPaths) {
      if (exists(path)) {
        return path;
      }
    }

    return null;
  }

  /// Analyzes web build output and creates artifact list.
  ///
  /// Returns: List of build artifacts with size information
  List<BuildArtifact> _analyzeBuildOutput(String webPath) {
    final artifacts = <BuildArtifact>[];

    try {
      final webDir = Directory(webPath);
      if (!webDir.existsSync()) return artifacts;

      // Main artifacts
      final mainFiles = [
        'index.html',
        'main.dart.js',
        'flutter.js',
        'flutter_service_worker.js',
      ];

      for (final fileName in mainFiles) {
        final filePath = join(webPath, fileName);
        final file = File(filePath);
        if (file.existsSync()) {
          artifacts.add(BuildArtifact(
            type: _getFileType(fileName),
            path: filePath,
            sizeBytes: file.lengthSync(),
          ));
        }
      }

      // Calculate total size
      int totalSize = 0;
      webDir.listSync(recursive: true).whereType<File>().forEach((file) {
        totalSize += file.lengthSync();
      });

      artifacts.add(BuildArtifact(
        type: 'Web Bundle',
        path: webPath,
        sizeBytes: totalSize,
        metadata: {
          'format': 'Web Application',
          'compressed': false,
          'files': webDir.listSync(recursive: true).length,
        },
      ));
    } catch (e) {
      // Ignore analysis errors
    }

    return artifacts;
  }

  /// Gets display type for file artifacts.
  String _getFileType(String fileName) {
    if (fileName.endsWith('.html')) return 'HTML';
    if (fileName.endsWith('.js')) return 'JavaScript';
    if (fileName.endsWith('.css')) return 'CSS';
    if (fileName.endsWith('.json')) return 'JSON';
    return 'File';
  }

  /// Reports web deployment information and recommendations.
  ///
  /// Provides guidance on deploying the web application to
  /// various hosting platforms and CDNs.
  void _reportDeploymentInfo(
      String webPath, String? baseHref, String? pwaStrategy) {
    printMessage('\n🌐 Web Application Information:');
    printMessage('   Generated: $webPath');
    printMessage('   Base href: ${baseHref ?? "/"}');
    printMessage('   PWA: ${pwaStrategy ?? "offline-first"}');

    printMessage('\n🚀 Deployment options:');
    printMessage('   # Local testing');
    printMessage('   cd $webPath && python -m http.server 8000');
    printMessage('   # Or use Flutter\'s built-in server');
    printMessage('   flutter run -d chrome --web-port 8080');

    printMessage('\n🌍 Production deployment:');
    printMessage('   - Static hosting: GitHub Pages, Netlify, Vercel');
    printMessage('   - CDN: CloudFlare, AWS CloudFront, Google Cloud CDN');
    printMessage('   - Web server: nginx, Apache, IIS');

    if (baseHref != null && baseHref != '/') {
      printMessage('\n⚠️  Subdirectory deployment:');
      printMessage('   Configure web server to serve from: $baseHref');
      printMessage('   Ensure all routes redirect to index.html');
    }

    if (pwaStrategy == 'offline-first') {
      printMessage('\n📦 PWA Features:');
      printMessage('   - Offline support enabled');
      printMessage('   - Service worker for caching');
      printMessage('   - Add manifest.json for app-like experience');
    }
  }

  /// Analyzes web build performance and provides optimization suggestions.
  void _analyzeWebBuildPerformance(String webPath, bool dumpInfo) {
    try {
      final webDir = Directory(webPath);
      if (!webDir.existsSync()) return;

      // Analyze main.dart.js size
      final mainJsPath = join(webPath, 'main.dart.js');
      final mainJsFile = File(mainJsPath);

      if (mainJsFile.existsSync()) {
        final sizeKB = (mainJsFile.lengthSync() / 1024).round();

        printMessage('\n📊 Performance Analysis:');
        printMessage('   Main bundle size: ${sizeKB}KB');

        if (sizeKB > 2000) {
          BuildProgressReporter.reportWarning(
            'Large bundle size detected (${sizeKB}KB) - consider code splitting',
          );
          printMessage('   Optimization suggestions:');
          printMessage(
              '   - Enable tree shaking with --dart2js-optimization O4');
          printMessage('   - Remove unused dependencies');
          printMessage('   - Use deferred loading for large features');
        } else if (sizeKB > 1000) {
          printMessage(
              '   Bundle size is moderate - consider optimization for mobile users');
        } else {
          printMessage('   Good bundle size for web deployment');
        }
      }

      if (dumpInfo) {
        final infoPath = join(webPath, 'main.dart.js.info.json');
        if (exists(infoPath)) {
          printMessage('\n🔍 Build analysis:');
          printMessage('   Detailed analysis: $infoPath');
          printMessage('   Use dart2js_info tool for deep analysis');
        }
      }
    } catch (e) {
      // Ignore performance analysis errors
    }
  }
}
