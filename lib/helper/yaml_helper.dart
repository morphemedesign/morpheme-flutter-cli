import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Helper class for YAML file operations.
///
/// This class provides utilities for loading, validating, and saving
/// YAML files, particularly for morpheme.yaml configuration files.
abstract class YamlHelper {
  /// Validates the existence of a morpheme.yaml file.
  ///
  /// This method checks if a morpheme.yaml file exists in the current
  /// directory or at a specified custom path. If the file is not found,
  /// it reports an error and exits the application.
  ///
  /// Parameters:
  /// - [morphemeYaml]: Optional custom path to the morpheme.yaml file
  ///
  /// Example:
  /// ```dart
  /// // Validate default morpheme.yaml in current directory
  /// YamlHelper.validateMorphemeYaml();
  ///
  /// // Validate custom path
  /// YamlHelper.validateMorphemeYaml('./config/morpheme.yaml');
  /// ```
  ///
  /// Note: If the morpheme.yaml file is not found, this method will
  /// terminate the application with an error message.
  static void validateMorphemeYaml([String? morphemeYaml]) {
    if (!exists(join(current, 'morpheme.yaml')) && morphemeYaml == null) {
      StatusHelper.failed(
          'You don\'t have "morpheme.yaml" in root apps, make sure to "morpheme init" first');
    } else if (morphemeYaml != null && !exists(morphemeYaml)) {
      StatusHelper.failed(
          'Not found custom path morpheme.yaml in "$morphemeYaml"');
    }
  }

  /// Loads and parses a YAML file.
  ///
  /// This method reads a YAML file and parses its contents into a Map.
  /// If an error occurs during reading or parsing, it prints an error
  /// message and returns an empty map.
  ///
  /// Parameters:
  /// - [path]: The path to the YAML file to load
  ///
  /// Returns: A Map containing the parsed YAML contents, or an empty
  ///          map if an error occurs
  ///
  /// Example:
  /// ```dart
  /// final config = YamlHelper.loadFileYaml('./morpheme.yaml');
  /// final appName = config['app_name'];
  /// print('App name: $appName');
  /// ```
  static Map<dynamic, dynamic> loadFileYaml(String path) {
    try {
      final File file = File(path);
      final String yamlString = file.readAsStringSync();
      return loadYaml(yamlString);
    } catch (e) {
      printerrMessage(e.toString());
      return {};
    }
  }

  /// Saves data to a YAML file.
  ///
  /// This method converts a Map to YAML format and writes it to a file.
  ///
  /// Parameters:
  /// - [path]: The path where the YAML file should be saved
  /// - [map]: The Map containing the data to be saved as YAML
  ///
  /// Example:
  /// ```dart
  /// final config = {
  ///   'app_name': 'My App',
  ///   'version': '1.0.0',
  /// };
  /// YamlHelper.saveFileYaml('./morpheme.yaml', config);
  /// ```
  static void saveFileYaml(String path, Map map) {
    final yaml = YamlWriter().write(map);
    path.write(yaml);
  }
}
