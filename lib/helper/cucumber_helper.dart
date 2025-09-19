import 'package:morpheme_cli/dependency_manager.dart';

/// Helper class for Cucumber testing operations.
///
/// This class provides utilities for managing Cucumber test artifacts
/// and related files during the testing lifecycle.
abstract class CucumberHelper {
  /// Removes the ndjson_gherkin.json file used by Cucumber tests.
  ///
  /// This method removes the ndjson_gherkin.json file that is generated
  /// during Cucumber test execution. This file contains test results
  /// in NDJSON format and is typically located in the integration_test/ndjson
  /// directory.
  ///
  /// The method safely checks for the file's existence before attempting
  /// to delete it, preventing errors if the file doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// // Clean up Cucumber test artifacts after test execution
  /// CucumberHelper.removeNdjsonGherkin();
  /// ```
  ///
  /// Note: This method only removes the specific ndjson_gherkin.json file
  /// and does not affect other test artifacts or files.
  static void removeNdjsonGherkin() {
    final path =
        join(current, 'integration_test', 'ndjson', 'ndjson_gherkin.json');
    if (exists(path)) {
      delete(path);
    }
  }
}
