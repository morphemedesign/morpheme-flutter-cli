import 'package:morpheme_cli/dependency_manager.dart';

/// Configuration class for asset generation operations.
///
/// Encapsulates all necessary configuration parameters for asset processing,
/// including project settings, directory paths, and generation options.
class AssetConfig {
  /// The name of the Flutter project.
  final String projectName;

  /// Directory containing the pubspec.yaml file.
  final String pubspecDir;

  /// Output directory for generated Dart classes.
  final String outputDir;

  /// Directory containing the assets to process.
  final String assetsDir;

  /// Directory containing flavor-specific assets.
  final String flavorDir;

  /// Whether to create a library export file.
  final bool createLibraryFile;

  /// Optional flavor name for environment-specific asset generation.
  final String? flavor;

  /// Creates a new AssetConfig instance.
  ///
  /// All directory paths should be relative to the project root.
  /// The [projectName] is used for generating class names.
  const AssetConfig({
    required this.projectName,
    required this.pubspecDir,
    required this.outputDir,
    required this.assetsDir,
    required this.flavorDir,
    required this.createLibraryFile,
    this.flavor,
  });

  /// Creates an AssetConfig from a morpheme.yaml configuration map.
  ///
  /// Applies default values for missing configuration entries:
  /// - pubspecDir: 'assets'
  /// - outputDir: 'assets/lib'
  /// - assetsDir: 'assets/assets'
  /// - flavorDir: 'assets/flavor'
  /// - createLibraryFile: true
  factory AssetConfig.fromMorphemeConfig({
    required String projectName,
    required Map<dynamic, dynamic> assetsConfig,
    String? flavor,
  }) {
    return AssetConfig(
      projectName: projectName,
      pubspecDir: (assetsConfig['pubspec_dir']?.toString() ?? 'assets')
          .replaceAll('/', separator),
      outputDir: (assetsConfig['output_dir']?.toString() ?? 'assets/lib')
          .replaceAll('/', separator),
      assetsDir: (assetsConfig['assets_dir']?.toString() ?? 'assets/assets')
          .replaceAll('/', separator),
      flavorDir: (assetsConfig['flavor_dir']?.toString() ?? 'assets/flavor')
          .replaceAll('/', separator),
      createLibraryFile: assetsConfig['create_library_file'] ?? true,
      flavor: flavor?.isNotEmpty == true ? flavor : null,
    );
  }

  /// Gets the absolute path to the flavor directory for the current flavor.
  ///
  /// Returns null if no flavor is specified.
  String? getFlavorPath() {
    if (flavor == null) return null;
    return join(current, flavorDir, flavor!);
  }

  /// Gets the absolute path to the assets directory.
  String getAssetsPath() {
    return join(current, assetsDir);
  }

  /// Gets the absolute path to the output directory.
  String getOutputPath() {
    return join(current, outputDir);
  }

  /// Gets the absolute path to the source output directory.
  String getSourceOutputPath() {
    return join(getOutputPath(), 'src');
  }

  /// Gets the absolute path to the pubspec.yaml file.
  String getPubspecPath() {
    return join(current, pubspecDir, 'pubspec.yaml');
  }

  /// Validates the configuration and returns a list of validation errors.
  ///
  /// Checks for:
  /// - Empty or invalid project name
  /// - Missing required directories
  /// - Invalid path formats
  List<String> validate() {
    final errors = <String>[];

    if (projectName.isEmpty) {
      errors.add('Project name cannot be empty');
    }

    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(projectName)) {
      errors.add('Project name must be a valid Dart identifier');
    }

    if (pubspecDir.isEmpty) {
      errors.add('Pubspec directory cannot be empty');
    }

    if (outputDir.isEmpty) {
      errors.add('Output directory cannot be empty');
    }

    if (assetsDir.isEmpty) {
      errors.add('Assets directory cannot be empty');
    }

    return errors;
  }

  /// Returns a copy of this configuration with the specified fields updated.
  AssetConfig copyWith({
    String? projectName,
    String? pubspecDir,
    String? outputDir,
    String? assetsDir,
    String? flavorDir,
    bool? createLibraryFile,
    String? flavor,
  }) {
    return AssetConfig(
      projectName: projectName ?? this.projectName,
      pubspecDir: pubspecDir ?? this.pubspecDir,
      outputDir: outputDir ?? this.outputDir,
      assetsDir: assetsDir ?? this.assetsDir,
      flavorDir: flavorDir ?? this.flavorDir,
      createLibraryFile: createLibraryFile ?? this.createLibraryFile,
      flavor: flavor ?? this.flavor,
    );
  }

  @override
  String toString() {
    return 'AssetConfig{'
        'projectName: $projectName, '
        'pubspecDir: $pubspecDir, '
        'outputDir: $outputDir, '
        'assetsDir: $assetsDir, '
        'flavorDir: $flavorDir, '
        'createLibraryFile: $createLibraryFile, '
        'flavor: $flavor'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetConfig &&
          runtimeType == other.runtimeType &&
          projectName == other.projectName &&
          pubspecDir == other.pubspecDir &&
          outputDir == other.outputDir &&
          assetsDir == other.assetsDir &&
          flavorDir == other.flavorDir &&
          createLibraryFile == other.createLibraryFile &&
          flavor == other.flavor;

  @override
  int get hashCode =>
      projectName.hashCode ^
      pubspecDir.hashCode ^
      outputDir.hashCode ^
      assetsDir.hashCode ^
      flavorDir.hashCode ^
      createLibraryFile.hashCode ^
      flavor.hashCode;
}
