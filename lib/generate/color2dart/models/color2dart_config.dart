/// Configuration model for Color2Dart command.
///
/// This class encapsulates all configuration parameters needed for
/// the color generation process, including paths, flags, and flavor settings.
class Color2DartConfig {
  /// Path to the morpheme.yaml file.
  final String morphemeYamlPath;

  /// Flag indicating whether to clear existing files before generation.
  final bool clearFiles;

  /// Flag indicating whether to generate files for all flavors.
  final bool allFlavor;

  /// Specific flavor to generate files for.
  final String flavor;

  /// Base output directory for generated files.
  final String outputDir;

  /// Directory containing color2dart configuration files.
  final String color2dartDir;

  /// Path to the colors directory.
  final String pathColors;

  /// Path to the themes directory.
  final String pathThemes;

  /// List of flavor paths to process.
  final List<String> flavorPaths;

  /// Creates a new Color2DartConfig instance.
  ///
  /// All parameters are required to ensure complete configuration.
  Color2DartConfig({
    required this.morphemeYamlPath,
    required this.clearFiles,
    required this.allFlavor,
    required this.flavor,
    required this.outputDir,
    required this.color2dartDir,
    required this.pathColors,
    required this.pathThemes,
    required this.flavorPaths,
  });

  /// Creates a copy of this configuration with modified values.
  ///
  /// This method is useful for creating slightly modified configurations
  /// for different processing steps while maintaining most settings.
  Color2DartConfig copyWith({
    String? morphemeYamlPath,
    bool? clearFiles,
    bool? allFlavor,
    String? flavor,
    String? outputDir,
    String? color2dartDir,
    String? pathColors,
    String? pathThemes,
    List<String>? flavorPaths,
  }) {
    return Color2DartConfig(
      morphemeYamlPath: morphemeYamlPath ?? this.morphemeYamlPath,
      clearFiles: clearFiles ?? this.clearFiles,
      allFlavor: allFlavor ?? this.allFlavor,
      flavor: flavor ?? this.flavor,
      outputDir: outputDir ?? this.outputDir,
      color2dartDir: color2dartDir ?? this.color2dartDir,
      pathColors: pathColors ?? this.pathColors,
      pathThemes: pathThemes ?? this.pathThemes,
      flavorPaths: flavorPaths ?? this.flavorPaths,
    );
  }
}