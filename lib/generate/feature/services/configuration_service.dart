import 'package:morpheme_cli/dependency_manager.dart';

/// Service for setting up feature configuration files.
///
/// This service handles creating .gitignore and analysis_options.yaml files
/// for the new feature module.
class ConfigurationService {
  /// Creates or updates the .gitignore file for the feature.
  ///
  /// This method sets up the .gitignore file with standard Flutter ignore patterns
  /// and adds coverage-related entries.
  void setupGitIgnore(String pathFeature, String featureName, String appsName) {
    final pathIgnore = join(pathFeature, '.gitignore');
    if (exists(pathIgnore)) {
      String gitignore = readFile(pathIgnore);
      gitignore = '''$gitignore
coverage/
test/coverage_helper_test.dart''';

      pathIgnore.write(gitignore);
    } else {
      pathIgnore.write('''# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
# Libraries should not include pubspec.lock, per https://dart.dev/guides/libraries/private-files#pubspeclock.
/pubspec.lock
**/doc/api/
.dart_tool/
.packages
build/

coverage/
test/coverage_helper_test.dart
''');
    }
  }

  /// Creates the analysis_options.yaml file for the feature.
  ///
  /// This method sets up the analysis_options.yaml file to include the standard
  /// dev_dependency_manager configuration.
  void setupAnalysisOptions(
      String pathFeature, String featureName, String appsName) {
    final path = join(pathFeature, 'analysis_options.yaml');
    path.write('''include: package:dev_dependency_manager/flutter.yaml
    
# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''');
  }
}
