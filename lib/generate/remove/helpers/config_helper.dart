import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';

import '../../../helper/helper.dart';

/// Helper class for configuration file operations in remove commands.
abstract class ConfigHelper {
  /// Removes app references from the main locator file.
  static void removeAppFromLocator(String appsName) {
    final pathLibLocator = join(current, 'lib', 'locator.dart');
    if (File(pathLibLocator).existsSync()) {
      String data = File(pathLibLocator).readAsStringSync();

      data = data.replaceAll(
          "import 'package:${appsName.snakeCase}/locator.dart';", '');
      data = data.replaceAll("setupLocatorApps${appsName.pascalCase}();", '');

      File(pathLibLocator).writeAsStringSync(data);
    }
  }

  /// Removes feature references from a locator file.
  static void removeFeatureFromLocator(String appsName, String featureName) {
    final workingDir = appsName.isEmpty ? current : join(current, 'apps', appsName);
    final pathLibLocator = join(workingDir, 'lib', 'locator.dart');
    
    if (File(pathLibLocator).existsSync()) {
      String data = File(pathLibLocator).readAsStringSync();

      data = data.replaceAll(
          "import 'package:${featureName.snakeCase}/locator.dart';", '');
      data =
          data.replaceAll("setupLocatorFeature${featureName.pascalCase}();", '');

      File(pathLibLocator).writeAsStringSync(data);
    }
  }

  /// Removes page references from a feature locator file.
  static void removePageFromLocator(String appsName, String featureName, String pageName) {
    final pathFeature = appsName.isEmpty 
        ? join(current, 'features', featureName) 
        : join(current, 'apps', appsName, 'features', featureName);
    final pathFeatureLocator = join(pathFeature, 'lib', 'locator.dart');
    
    if (File(pathFeatureLocator).existsSync()) {
      String data = File(pathFeatureLocator).readAsStringSync();

      data = data.replaceAll("import '${pageName.snakeCase}/locator.dart';", '');
      data = data.replaceAll("setupLocator${pageName.pascalCase}();", '');

      File(pathFeatureLocator).writeAsStringSync(data);
    }
  }

  /// Removes app entries from pubspec.yaml.
  static void removeAppFromPubspec(String appsName) {
    final pathPubspec = join(current, 'pubspec.yaml');
    if (File(pathPubspec).existsSync()) {
      String pubspec = File(pathPubspec).readAsStringSync();

      pubspec = pubspec.replaceAll(
        RegExp("\\s+- apps/${appsName.snakeCase}"),
        '',
      );
      pubspec = pubspec.replaceAll(
        RegExp(
            "\\s+${appsName.snakeCase}:\\s+path: ./apps/${appsName.snakeCase}"),
        '',
      );

      File(pathPubspec).writeAsStringSync(pubspec);
    }
  }

  /// Removes feature entries from pubspec.yaml.
  static void removeFeatureFromPubspec(String appsName, String featureName) {
    final workingDir = appsName.isEmpty ? current : join(current, 'apps', appsName);
    final pathPubspec = join(workingDir, 'pubspec.yaml');
    
    if (File(pathPubspec).existsSync()) {
      String pubspec = File(pathPubspec).readAsStringSync();

      pubspec = pubspec.replaceAll(
        RegExp("\\s+- features/${featureName.snakeCase}"),
        '',
      );
      pubspec = pubspec.replaceAll(
        RegExp(
            "\\s+${featureName.snakeCase}:\\s+path: ./features/${featureName.snakeCase}"),
        '',
      );

      File(pathPubspec).writeAsStringSync(pubspec);
    }
  }
}