import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Manages locator.dart file modifications for app modules.
///
/// This class handles updating the main locator.dart file to register
/// the new app module's locator setup function.
class LocatorManager {
  /// Adds a new app module to the main locator.dart file.
  ///
  /// This method updates the locator.dart file to import the new app module
  /// and call its setup function.
  ///
  /// Parameters:
  /// - [pathApps]: The path to the new app module
  /// - [appsName]: The name of the new app module
  ///
  /// Throws:
  /// - Exception if the locator.dart file doesn't exist
  /// - Exception if there are file I/O errors
  static void addNewAppsInLocator(String pathApps, String appsName) {
    final locatorPath = join(current, 'lib', 'locator.dart');
    if (!exists(locatorPath)) {
      StatusHelper.warning(
          'lib/locator.dart not found. Skipping locator update.');
      return;
    }

    try {
      String locator = File(locatorPath).readAsStringSync();

      // Add import statement
      locator = locator.replaceAll(
        RegExp(r'(^(\s+)?void setup)', multiLine: true),
        '''import 'package:$appsName/locator.dart';

void setup''',
      );

      // Add setup function call
      locator = locator.replaceAll(
        '}',
        '''  setupLocatorApps${appsName.pascalCase}();
}''',
      );

      locatorPath.write(locator);
      StatusHelper.generated(locatorPath);
    } catch (e) {
      StatusHelper.failed('Failed to update locator.dart: $e');
    }
  }
}
