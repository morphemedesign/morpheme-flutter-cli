import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/template_test/models/template_test_config.dart';

/// Manages loading and validating template test generation configuration.
///
/// This class handles parsing command-line arguments, validating inputs,
/// and creating a validated [TemplateTestConfig] object.
class TemplateTestConfigManager {
  /// Validates input parameters and project prerequisites.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool validateInputs(ArgResults? argResults) {
    if (argResults == null) {
      StatusHelper.failed(
        'Invalid arguments provided',
        suggestion: 'Check your command syntax and try again',
        examples: [
          'morpheme template-test --help',
        ],
      );
      return false;
    }

    final featureName = argResults['feature-name'] != null
        ? argResults['feature-name'].toString().snakeCase
        : '';
    final pageName = argResults['page-name'] != null
        ? argResults['page-name'].toString().snakeCase
        : '';

    if (featureName.isEmpty) {
      StatusHelper.failed(
        'Feature name is required',
        suggestion: 'Provide a feature name using --feature-name or -f',
        examples: [
          'morpheme template-test --feature-name user --page-name profile',
        ],
      );
      return false;
    }

    if (pageName.isEmpty) {
      StatusHelper.failed(
        'Page name is required',
        suggestion: 'Provide a page name using --page-name or -p',
        examples: [
          'morpheme template-test --feature-name user --page-name profile',
        ],
      );
      return false;
    }

    // Check if feature and page exist
    final pathFeaturePage = join(
      current,
      'features',
      featureName,
      'lib',
      pageName,
    );

    if (!exists(pathFeaturePage)) {
      StatusHelper.failed(
        'Feature or page not found, please check your feature or page name',
        suggestion: 'Verify that the feature and page exist in your project',
        examples: [
          'morpheme feature $featureName',
          'morpheme page $pageName -f $featureName',
        ],
      );
      return false;
    }

    return true;
  }

  /// Loads and validates configuration from command arguments.
  ///
  /// Parameters:
  /// - [argResults]: Parsed command-line arguments
  ///
  /// Returns: A validated TemplateTestConfig object
  TemplateTestConfig loadConfig(ArgResults argResults) {
    return TemplateTestConfig.fromArgs(argResults, current);
  }
}
