import 'package:args/args.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Manages loading and validating page generation configuration.
///
/// This class handles parsing command-line arguments, validating inputs,
/// and creating a validated [PageConfig] object.
class PageConfigManager {
  /// Validates input parameters and project prerequisites.
  ///
  /// Returns true if validation passes, false otherwise.
  /// Displays specific error messages with resolution guidance.
  bool validateInputs(ArgResults? argResults) {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Page name is empty, add a new page with "morpheme page <page-name> -f <feature-name>"');
      return false;
    }
    return true;
  }

  /// Loads and prepares configuration for page generation.
  ///
  /// Parses command-line arguments and constructs a [PageConfig] object
  /// with all necessary parameters for page generation.
  PageConfig loadConfig(ArgResults argResults) {
    return PageConfig.fromArguments(argResults);
  }
}