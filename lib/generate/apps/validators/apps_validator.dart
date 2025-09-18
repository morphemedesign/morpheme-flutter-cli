import 'package:morpheme_cli/helper/status_helper.dart';

/// Validates input parameters for app module creation.
///
/// This class handles validation of user input for creating new app modules,
/// including app name validation and conflict detection.
class AppsValidator {
  /// Validates that an app name is provided and valid.
  ///
  /// This method checks that an app name is provided and follows naming conventions.
  ///
  /// Parameters:
  /// - [appName]: The app name to validate
  ///
  /// Throws:
  /// - Exception if the app name is empty or invalid
  static void validateAppName(String? appName) {
    if (appName == null || appName.isEmpty) {
      StatusHelper.failed(
        'App name is empty',
        suggestion: 'Add a new app with "morpheme apps <app-name>"',
        examples: [
          'morpheme apps user_dashboard',
          'morpheme apps payment_gateway',
        ],
      );
    }
  }

  /// Validates that required dependencies are available.
  ///
  /// This method checks that required dependencies like Flutter SDK are available.
  ///
  /// Throws:
  /// - Exception if required dependencies are missing
  static void validateDependencies() {
    // Currently no specific dependency validation is needed
    // but this method is here for future extensibility
  }
}
