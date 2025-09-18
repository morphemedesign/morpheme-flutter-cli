import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to upgrade Morpheme CLI to the latest version.
///
/// This command uses Dart's pub global activate to upgrade the CLI tool
/// to the latest available version from pub.dev. It provides feedback
/// during the upgrade process and handles potential errors gracefully.
class UpgradeCommand extends Command {
  UpgradeCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force upgrade even if already on latest version',
      negatable: false,
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output during upgrade process',
      negatable: false,
    );
  }

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade Morpheme CLI to the latest version';

  @override
  String get category => Constants.tools;

  /// Package name for the Morpheme CLI
  static const String _packageName = 'morpheme_cli';

  @override
  void run() async {
    final isForce = argResults?['force'] as bool? ?? false;
    final isVerbose = argResults?['verbose'] as bool? ?? false;

    try {
      await _performUpgrade(isForce: isForce, isVerbose: isVerbose);
    } catch (e) {
      StatusHelper.failed('Upgrade failed: $e');
      _printTroubleshootingHelp();
      rethrow;
    }
  }

  /// Performs the actual upgrade operation.
  Future<void> _performUpgrade({
    required bool isForce,
    required bool isVerbose,
  }) async {
    _printUpgradeHeader();

    if (!isForce) {
      await _checkCurrentVersion(isVerbose);
    }

    printMessage(blue('Upgrading $_packageName...'));

    final upgradeCommand = _buildUpgradeCommand(isVerbose);

    if (isVerbose) {
      printMessage('${grey('Executing:')} $upgradeCommand');
    }

    try {
      await upgradeCommand.run;
      _printUpgradeSuccess();
    } catch (e) {
      StatusHelper.failed('Failed to execute upgrade command: $e');
      rethrow;
    }
  }

  /// Prints the upgrade process header.
  void _printUpgradeHeader() {
    printMessage('\n${blue('Morpheme CLI Upgrade')}');
    printMessage(
        '${grey('Checking for updates and upgrading to latest version...')}\n');
  }

  /// Checks and displays current version information.
  Future<void> _checkCurrentVersion(bool isVerbose) async {
    try {
      if (isVerbose) {
        printMessage(blue('Checking current version...'));

        // Try to get current version info
        // Note: This could be enhanced to actually check version numbers
        final listResult =
            await '${FlutterHelper.getCommandDart()} pub global list'.run;

        if (isVerbose) {
          printMessage(grey('Current global packages:'));
          printMessage('$listResult');
        }
      }
    } catch (e) {
      // Non-critical error, continue with upgrade
      if (isVerbose) {
        StatusHelper.warning('Could not check current version: $e');
      }
    }
  }

  /// Builds the upgrade command with appropriate options.
  String _buildUpgradeCommand(bool isVerbose) {
    final dartCommand = FlutterHelper.getCommandDart();
    return '$dartCommand pub global activate $_packageName';
  }

  /// Prints success message after upgrade completion.
  void _printUpgradeSuccess() {
    StatusHelper.success('Morpheme CLI upgraded successfully!');

    printMessage('\n${blue('What\'s next?')}');
    printMessage('• Run ${cyan('morpheme doctor')} to verify your setup');
    printMessage('• Check ${cyan('morpheme --help')} for available commands');
    printMessage(
        '• Visit ${cyan('https://github.com/morphemedesign/morpheme-flutter-cli')} for documentation');

    _printVersionCheckSuggestion();
  }

  /// Suggests how to check the new version.
  void _printVersionCheckSuggestion() {
    printMessage('\n${grey('To verify the upgrade:')}');
    printMessage(
        'Run ${cyan('morpheme --version')} to see the current version');
  }

  /// Prints troubleshooting help when upgrade fails.
  void _printTroubleshootingHelp() {
    printMessage('\n${yellow('Troubleshooting:')}');
    printMessage('• Ensure you have an active internet connection');
    printMessage('• Check if Dart SDK is properly installed');
    printMessage('• Try running ${cyan('dart pub cache repair')} and retry');
    printMessage(
        '• Use ${cyan('morpheme upgrade --verbose')} for detailed output');
    printMessage('\n${grey('If the problem persists, please report it at:')}');
    printMessage(
        cyan('https://github.com/morphemedesign/morpheme-flutter-cli/issues'));
  }
}
