import 'package:morpheme_cli/build_app/base/build_command_base.dart';
import 'package:morpheme_cli/extensions/extensions.dart';

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
class WebCommand extends BuildCommandBase {
  WebCommand() : super() {
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
  String get name => 'web';

  @override
  String get description => 'Build a web application bundle with flavor.';

  @override
  String get buildTarget => 'web';

  @override
  String constructBuildCommand(List<String> dartDefines) {
    final baseCommand = super.constructBuildCommand(dartDefines);
    final argBaseHref = argResults.getOptionBaseHref();
    final argPwaStrategy = argResults.getOptionPwaStrategy();
    final argWebRenderer = argResults.getOptionWebRenderer();
    final argWebResourcesCdn = argResults.getFlagWebResourcesCdn();
    final argCsp = argResults.getFlagCsp();
    final argSourcesMap = argResults.getFlagSourceMaps();
    final argDart2JsOptimization = argResults.getOptionDart2JsOptimization();
    final argDumpInfo = argResults.getFlagDumpInfo();
    final argFrequencyBasedMinification =
        argResults.getFlagFrequencyBasedMinification();

    return '$baseCommand $argBaseHref $argPwaStrategy $argWebRenderer '
        '$argWebResourcesCdn $argCsp $argSourcesMap $argDart2JsOptimization '
        '$argDumpInfo $argFrequencyBasedMinification';
  }
}
