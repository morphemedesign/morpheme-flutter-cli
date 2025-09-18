/// Configuration class containing project settings and environment information.
///
/// Encapsulates project-specific settings loaded from morpheme.yaml and
/// environment configuration needed for API generation.
class ProjectConfiguration {
  const ProjectConfiguration({
    required this.projectName,
    required this.morphemeYamlPath,
    this.additionalSettings,
  });

  /// The name of the project from morpheme.yaml
  final String projectName;

  /// Path to the morpheme.yaml configuration file
  final String morphemeYamlPath;

  /// Additional project-specific settings
  final Map<String, dynamic>? additionalSettings;

  /// Creates a copy of this configuration with the given fields replaced
  /// with the new values.
  ProjectConfiguration copyWith({
    String? projectName,
    String? morphemeYamlPath,
    Map<String, dynamic>? additionalSettings,
  }) {
    return ProjectConfiguration(
      projectName: projectName ?? this.projectName,
      morphemeYamlPath: morphemeYamlPath ?? this.morphemeYamlPath,
      additionalSettings: additionalSettings ?? this.additionalSettings,
    );
  }

  @override
  String toString() {
    return 'ProjectConfiguration('
        'projectName: $projectName, '
        'morphemeYamlPath: $morphemeYamlPath'
        ')';
  }
}
