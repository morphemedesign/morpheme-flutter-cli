import 'package:morpheme_cli/helper/helper.dart';

/// Extension methods for [Map] to access YAML configuration values.
///
/// This extension provides easy access to common YAML configuration values
/// with appropriate defaults for the Morpheme CLI.
///
/// Example usage:
/// ```dart
/// final config = loadYaml('morpheme.yaml');
/// final projectName = config.projectName;
/// final concurrent = config.concurrent;
/// ```
extension MapYamlExtension on Map {
  /// Gets the project name from YAML configuration.
  ///
  /// If not specified in the configuration, defaults to 'morpheme'.
  ///
  /// Example:
  /// ```yaml
  /// project_name: my_app
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// final projectName = config.projectName;
  /// ```
  String get projectName => this['project_name'] ?? 'morpheme';

  /// Gets the concurrent value from YAML configuration.
  ///
  /// If not specified in the configuration, defaults to [ModularHelper.defaultConcurrent].
  ///
  /// Example:
  /// ```yaml
  /// concurrent: 8
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// final concurrent = config.concurrent;
  /// ```
  int get concurrent => this['concurrent'] ?? ModularHelper.defaultConcurrent;
}
