/// Configuration model for endpoint generation.
///
/// This class encapsulates all the parameters needed for generating endpoint files.
class EndpointConfig {
  /// The project name used for generating endpoint class name.
  final String projectName;

  /// The path where the endpoint file will be generated.
  final String outputPath;

  /// List of paths to json2dart.yaml files.
  final List<String> json2DartPaths;

  /// Creates a new EndpointConfig instance.
  ///
  /// All parameters are required to ensure complete configuration.
  EndpointConfig({
    required this.projectName,
    required this.outputPath,
    required this.json2DartPaths,
  });

  @override
  String toString() {
    return 'EndpointConfig(projectName: $projectName, outputPath: $outputPath, '
        'json2DartPaths: $json2DartPaths)';
  }
}
