import 'package:args/command_runner.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/generate/apps/controllers/apps_controller.dart';

/// Command for generating new app modules within the Morpheme CLI ecosystem.
///
/// This command creates a complete app module structure including:
/// - Package configuration
/// - Locator registration
/// - Project integration
/// - Development environment setup
///
/// Usage: morpheme apps &lt;app-name&gt;
///
/// Example:
///   morpheme apps user_dashboard
///   morpheme apps payment_gateway
class AppsCommand extends Command<void> {
  @override
  String get name => 'apps';

  @override
  String get description => 'Create a new apps module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    final appName = argResults?.rest.firstOrNull;
    await AppsController.createApp(appName ?? '');
  }
}
