import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../models/package_configuration.dart';

/// Service for managing .gitignore file setup
///
/// This service handles creating and configuring the .gitignore file
/// for the new core package to ensure proper files are ignored.
class GitIgnoreService {
  /// Sets up the .gitignore file for the new package
  ///
  /// [config] - Configuration for the package
  void setup(PackageConfiguration config) {
    try {
      if (exists(config.gitIgnorePath)) {
        _updateExistingGitIgnore(config);
      } else {
        _createNewGitIgnore(config);
      }
    } catch (e) {
      StatusHelper.failed(
        'Failed to setup .gitignore file',
        suggestion: 'Check file permissions and available disk space',
      );
      rethrow;
    }
  }

  /// Updates an existing .gitignore file
  ///
  /// [config] - Configuration for the package
  void _updateExistingGitIgnore(PackageConfiguration config) {
    String gitignore = readFile(config.gitIgnorePath);
    gitignore = gitignore.replaceAll('/pubspec.lock', '');
    gitignore = '''$gitignore
coverage/
test/coverage_helper_test.dart''';

    config.gitIgnorePath.write(gitignore);
  }

  /// Creates a new .gitignore file with standard Flutter exclusions
  ///
  /// [config] - Configuration for the package
  void _createNewGitIgnore(PackageConfiguration config) {
    config.gitIgnorePath.write('''# Miscellaneous
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
**/doc/api/
.dart_tool/
.packages
build/

coverage/
test/coverage_helper_test.dart
''');
  }
}
