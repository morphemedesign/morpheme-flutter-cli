import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

/// Service for updating locator files with feature imports and setup calls.
///
/// This service handles adding the feature's locator import to the main locator file
/// and registering the feature's setup function.
class LocatorService {
  /// Adds the feature to the main locator file.
  ///
  /// This method updates the locator.dart file to import the feature's locator
  /// and call its setup function.
  void addFeatureToLocator(String pathFeature, String featureName, String appsName) {
    String pathLocator = join(current, 'lib', 'locator.dart');
    if (appsName.isNotEmpty) {
      pathLocator = join(current, 'apps', appsName, 'lib', 'locator.dart');
    }

    if (!exists(pathLocator)) {
      return;
    }

    String locator = File(pathLocator).readAsStringSync();

    // Add import statement
    if (RegExp(r'(^(\s+)?void setup)', multiLine: true).hasMatch(locator)) {
      locator = locator.replaceAll(
        RegExp(r'(^(\s+)?void setup)', multiLine: true),
        '''import 'package:$featureName/locator.dart';

void setup''',
      );
    } else if (RegExp(r'(^(\s+)?Future<void> setup)', multiLine: true)
        .hasMatch(locator)) {
      locator = locator.replaceAll(
        RegExp(r'(^(\s+)?Future<void> setup)', multiLine: true),
        '''import 'package:$featureName/locator.dart';

Future<void> setup''',
      );
    }

    // Add setup call
    locator = locator.replaceAll(
      '}',
      '''  setupLocatorFeature${featureName.pascalCase}();
}''',
    );
    
    pathLocator.write(locator);
    StatusHelper.generated(pathLocator);
  }
}