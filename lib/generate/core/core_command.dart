import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

import 'orchestrators/core_package_orchestrator.dart';

/// Core command with new modular architecture
///
/// This command uses a clean, modular architecture with separation of concerns:
/// - Command: Handles CLI interface and argument processing
/// - CorePackageOrchestrator: Coordinates overall package creation workflow
/// - Service classes: Handle specialized functionality for each step
class CoreCommand extends Command {
  @override
  String get name => 'core';

  @override
  String get description => 'Create a new core packages module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    try {
      // Validate arguments
      final packageName = _validateArguments();

      // Delegate to orchestrator
      final orchestrator = CorePackageOrchestrator();
      await orchestrator.createPackage(packageName);

      // Report success
      StatusHelper.success('generate package $packageName in core');
    } catch (e) {
      StatusHelper.failed('Failed to create core package: $e');
    }
  }

  /// Validates command arguments and returns the package name
  ///
  /// Throws [Exception] if validation fails
  String _validateArguments() {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Core package name is empty, add a new core package with "morpheme core <package-name>"');
    }

    return argResults?.rest.first ?? '';
  }
}
