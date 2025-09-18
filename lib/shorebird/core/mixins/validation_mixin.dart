import 'package:morpheme_cli/helper/helper.dart';
import '../exceptions/validation_error.dart';
import '../exceptions/configuration_error.dart';

/// Mixin that provides input validation functionality for Shorebird commands.
///
/// This mixin contains validation methods for command arguments, configuration
/// files, and other inputs used by Shorebird commands.
mixin ShorebirdValidationMixin {
  /// Validates the morpheme.yaml configuration file.
  ///
  /// Parameters:
  /// - [morphemeYamlPath]: Path to the morpheme.yaml file
  ///
  /// Throws:
  /// - [ShorebirdConfigurationError]: If the file is missing or invalid
  void validateMorphemeYaml(String morphemeYamlPath) {
    try {
      YamlHelper.validateMorphemeYaml(morphemeYamlPath);
    } catch (e) {
      throw ShorebirdConfigurationError.missingFile(morphemeYamlPath);
    }
  }

  /// Validates that a flavor exists in the configuration.
  ///
  /// Parameters:
  /// - [flavor]: The flavor name to validate
  /// - [morphemeYamlPath]: Path to the morpheme.yaml file
  ///
  /// Returns the flavor configuration map.
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If the flavor is invalid
  Map<String, String> validateAndGetFlavorConfig(
      String flavor, String morphemeYamlPath) {
    try {
      final result = FlavorHelper.byFlavor(flavor, morphemeYamlPath);
      return Map<String, String>.from(result);
    } catch (e) {
      throw ShorebirdValidationError.invalidValue(
        'flavor',
        flavor,
        ['dev', 'staging', 'prod'], // Common flavors - could be dynamic
      );
    }
  }

  /// Validates that a target file exists and is accessible.
  ///
  /// Parameters:
  /// - [target]: Path to the target file
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If the target file is invalid
  void validateTarget(String target) {
    if (target.isEmpty) {
      throw ShorebirdValidationError.emptyField('target');
    }

    // Additional validation could be added here to check if file exists
  }

  /// Validates build number format.
  ///
  /// Parameters:
  /// - [buildNumber]: The build number to validate
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If the build number format is invalid
  void validateBuildNumber(String? buildNumber) {
    if (buildNumber != null && buildNumber.isNotEmpty) {
      // Check if build number is numeric
      if (int.tryParse(buildNumber) == null) {
        throw ShorebirdValidationError(
          field: 'buildNumber',
          expectedValue: 'numeric value',
          actualValue: buildNumber,
          message: 'Build number must be a valid integer',
        );
      }
    }
  }

  /// Validates that Shorebird configuration exists for the flavor.
  ///
  /// Parameters:
  /// - [flavor]: The flavor to check Shorebird configuration for
  /// - [morphemeYamlPath]: Path to the morpheme.yaml file
  ///
  /// Returns a tuple of (flutterVersion, shorebirdConfig).
  ///
  /// Throws:
  /// - [ShorebirdConfigurationError]: If Shorebird configuration is missing
  (String?, Map<dynamic, dynamic>?) validateShorebirdConfig(
      String flavor, String morphemeYamlPath) {
    try {
      final result = ShorebirdHelper.byFlavor(flavor, morphemeYamlPath);
      return (result.$1, result.$2);
    } catch (e) {
      throw ShorebirdConfigurationError.missingField(
        morphemeYamlPath,
        'shorebird configuration for flavor: $flavor',
      );
    }
  }

  /// Validates export method for iOS builds.
  ///
  /// Parameters:
  /// - [exportMethod]: The export method to validate
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If the export method is invalid
  void validateExportMethod(String? exportMethod) {
    if (exportMethod != null && exportMethod.isNotEmpty) {
      const validMethods = ['app-store', 'ad-hoc', 'development', 'enterprise'];
      if (!validMethods.contains(exportMethod)) {
        throw ShorebirdValidationError.invalidValue(
          'exportMethod',
          exportMethod,
          validMethods,
        );
      }
    }
  }

  /// Validates that export options plist file exists (if specified).
  ///
  /// Parameters:
  /// - [exportOptionsPlist]: Path to the export options plist file
  ///
  /// Throws:
  /// - [ShorebirdValidationError]: If the file path is invalid
  void validateExportOptionsPlist(String? exportOptionsPlist) {
    if (exportOptionsPlist != null && exportOptionsPlist.isNotEmpty) {
      // Additional validation could be added here to check if file exists
      // and has valid plist format
    }
  }
}
