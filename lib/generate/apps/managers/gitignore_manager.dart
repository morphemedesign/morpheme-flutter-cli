import 'dart:io';

import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

/// Manages .gitignore file creation and updates for app modules.
///
/// This class handles creating or updating the .gitignore file in app modules
/// with standard ignore patterns for Flutter/Dart projects.
class GitIgnoreManager {
  /// Creates or updates the .gitignore file for a new app module.
  ///
  /// This method creates a standard .gitignore file with common patterns
  /// for Flutter/Dart projects, or updates an existing one.
  ///
  /// Parameters:
  /// - [pathApps]: The path to the new app module
  /// - [appsName]: The name of the new app module (unused but kept for consistency)
  static void addNewGitIgnore(String pathApps, String appsName) {
    final gitignorePath = p.join(pathApps, '.gitignore');

    try {
      if (File(gitignorePath).existsSync()) {
        // Append to existing .gitignore
        String gitignore = File(gitignorePath).readAsStringSync();
        gitignore = '''$gitignore
coverage/
test/coverage_helper_test.dart''';

        gitignorePath.write(gitignore);
      } else {
        // Create new .gitignore with standard content
        final content = '''# Miscellaneous
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
''';
        gitignorePath.write(content);
      }

      StatusHelper.generated(gitignorePath);
    } catch (e) {
      StatusHelper.failed('Failed to create/update .gitignore: $e');
    }
  }
}
