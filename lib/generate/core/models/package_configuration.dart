import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';

/// Configuration model for core package creation
///
/// This model encapsulates all the configuration data needed for creating
/// a new core Flutter package, including paths and naming conventions.
class PackageConfiguration {
  /// The original package name as provided by the user
  final String name;

  /// The package name converted to snake_case for file system compatibility
  final String snakeCaseName;

  /// The full path where the package will be created
  final String path;

  /// Creates a new package configuration
  ///
  /// [name] - The name of the package to create
  PackageConfiguration({
    required this.name,
  })  : snakeCaseName = name.snakeCase,
        path = join(current, 'core', 'packages', name.snakeCase);

  /// Path to the package's pubspec.yaml file
  String get pubspecPath => join(path, 'pubspec.yaml');

  /// Path to the package's .gitignore file
  String get gitIgnorePath => join(path, '.gitignore');

  /// Path to the package's analysis_options.yaml file
  String get analysisOptionsPath => join(path, 'analysis_options.yaml');
}
