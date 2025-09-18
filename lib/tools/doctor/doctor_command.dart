import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';

/// Command to check the health and availability of required development tools.
///
/// This command performs comprehensive checks for all tools required by the
/// Morpheme CLI, including Flutter SDK, Firebase CLI, testing tools, and
/// additional utilities. It provides detailed feedback about each tool's
/// installation status and usage context.
class DoctorCommand extends Command {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Show information about the installed tooling.';

  @override
  String get category => Constants.tools;

  /// List of tools to check with their configurations
  static const List<ToolCheck> _toolChecks = [
    ToolCheck(
      name: 'flutter',
      displayName: 'Flutter',
      installUrl: 'https://docs.flutter.dev/get-started/install',
      usage: 'Required for Flutter development',
      isRequired: true,
    ),
    ToolCheck(
      name: 'flutterfire',
      displayName: 'FlutterFire CLI',
      installCommand: 'dart pub global activate flutterfire_cli',
      usage: 'Used for \'morpheme firebase\' command',
      isRequired: false,
    ),
    ToolCheck(
      name: 'gherkin',
      displayName: 'Gherkin',
      installUrl:
          'https://github.com/morphemedesign/morpheme-flutter-cli/releases/tag/cucumber',
      usage: 'Used for \'morpheme cucumber\' command',
      isRequired: false,
    ),
    ToolCheck(
      name: 'npm',
      displayName: 'npm',
      installUrl: 'https://nodejs.org/en',
      usage:
          'Used for creating integration test reports after \'morpheme cucumber\' command',
      isRequired: false,
    ),
    ToolCheck(
      name: 'lcov',
      displayName: 'lcov',
      installUrl: 'https://github.com/linux-test-project/lcov',
      usage: 'Used for \'morpheme coverage\' command',
      isRequired: false,
    ),
    ToolCheck(
      name: 'shorebird',
      displayName: 'Shorebird',
      installUrl: 'https://docs.shorebird.dev/',
      usage: 'Used for Flutter code push \'morpheme shorebird\' command',
      isRequired: false,
    ),
  ];

  @override
  void run() async {
    printMessage('\n${blue('Morpheme CLI Doctor')}');
    printMessage('${grey('Checking installed tools and dependencies...')}\n');

    int installedCount = 0;
    int requiredMissing = 0;

    for (final toolCheck in _toolChecks) {
      final isInstalled = await _checkTool(toolCheck);
      if (isInstalled) {
        installedCount++;
      } else if (toolCheck.isRequired) {
        requiredMissing++;
      }
    }

    _printSummary(installedCount, _toolChecks.length, requiredMissing);
  }

  /// Checks if a specific tool is installed and provides feedback.
  ///
  /// Returns true if the tool is installed, false otherwise.
  /// For Flutter, it also runs `flutter doctor` to provide additional insights.
  Future<bool> _checkTool(ToolCheck toolCheck) async {
    final isInstalled = which(toolCheck.name).found;

    if (isInstalled) {
      _printToolStatus(toolCheck, true);

      // Special handling for Flutter to run doctor command
      if (toolCheck.name == 'flutter') {
        printMessage(grey('Running Flutter doctor...'));
        try {
          await FlutterHelper.run('doctor');
        } catch (e) {
          printerrMessage(
              '${yellow('[!]')} Warning: Flutter doctor failed: $e');
        }
      }
    } else {
      _printToolStatus(toolCheck, false);
      _printInstallationInstructions(toolCheck);
    }

    _printToolUsage(toolCheck);
    printMessage(''); // Add spacing between tools

    return isInstalled;
  }

  /// Prints the installation status of a tool.
  void _printToolStatus(ToolCheck toolCheck, bool isInstalled) {
    final status = isInstalled ? green('[✓]') : red('[✗]');
    final statusText = isInstalled ? 'installed' : 'not installed';
    final requiredText = toolCheck.isRequired ? ' ${red('(required)')}' : '';

    printMessage('$status ${toolCheck.displayName} $statusText$requiredText');
  }

  /// Prints installation instructions for a missing tool.
  void _printInstallationInstructions(ToolCheck toolCheck) {
    if (toolCheck.installCommand != null) {
      printMessage(
          '  ${grey('Install with:')} ${cyan(toolCheck.installCommand!)}');
    }

    if (toolCheck.installUrl != null) {
      printMessage(
          '  ${grey('Installation guide:')} ${cyan(toolCheck.installUrl!)}');
    }
  }

  /// Prints the usage description for a tool.
  void _printToolUsage(ToolCheck toolCheck) {
    printMessage('  ${grey('Usage:')} ${toolCheck.usage}');
  }

  /// Prints a summary of the tool check results.
  void _printSummary(int installed, int total, int requiredMissing) {
    printMessage(blue('Summary:'));
    printMessage('• Tools installed: $installed/$total');

    if (requiredMissing > 0) {
      printerrMessage('• ${red('Required tools missing: $requiredMissing')}');
      printerrMessage(
          '  ${yellow('Please install missing required tools to use Morpheme CLI properly.')}');
    } else {
      printMessage('• ${green('All required tools are installed!')}');
    }

    if (installed == total) {
      printMessage('\n${green('🎉 Perfect! All tools are ready to use.')}');
    } else {
      printMessage(
          '\n${yellow('💡 Install optional tools to unlock additional features.')}');
    }
  }
}

/// Configuration for a tool check.
class ToolCheck {
  const ToolCheck({
    required this.name,
    required this.displayName,
    required this.usage,
    required this.isRequired,
    this.installCommand,
    this.installUrl,
  });

  /// The command name used to check if the tool is installed
  final String name;

  /// The human-readable name of the tool
  final String displayName;

  /// Description of what the tool is used for
  final String usage;

  /// Whether this tool is required for basic Morpheme CLI functionality
  final bool isRequired;

  /// Command to install the tool (if available)
  final String? installCommand;

  /// URL with installation instructions
  final String? installUrl;
}
