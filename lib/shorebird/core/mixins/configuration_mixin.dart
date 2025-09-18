import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/dependency_manager.dart';

/// Mixin that provides standard command configuration functionality.
///
/// This mixin adds common command line options and argument parsing
/// methods that are used across all Shorebird commands.
mixin ShorebirdCommandConfiguration {
  /// Adds standard options that are common to all Shorebird commands.
  ///
  /// This includes flavor, target, morpheme-yaml path, build versioning,
  /// obfuscation, split debug info, and localization generation options.
  void addStandardOptions(ArgParser argParser) {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionTarget();
    argParser.addOptionMorphemeYaml();
    argParser.addOptionBuildNumber();
    argParser.addOptionBuildName();
    argParser.addFlagObfuscate();
    argParser.addOptionSplitDebugInfo();
    argParser.addFlagGenerateL10n();
  }

  /// Adds platform-specific options.
  ///
  /// This is a hook for subclasses to add platform-specific command
  /// line options. The default implementation does nothing.
  void addPlatformSpecificOptions(ArgParser argParser) {
    // Default implementation - subclasses can override
  }

  /// Validates and extracts the flavor value from command arguments.
  ///
  /// Parameters:
  /// - [argResults]: The parsed command line arguments
  /// - [defaultTo]: Default flavor value to use if none specified
  ///
  /// Returns the validated flavor string.
  String validateAndGetFlavor(ArgResults? argResults,
      {String defaultTo = Constants.dev}) {
    return argResults.getOptionFlavor(defaultTo: defaultTo);
  }

  /// Builds environment variables map for command execution.
  ///
  /// Parameters:
  /// - [config]: The command configuration containing environment settings
  ///
  /// Returns a map of environment variables for the command.
  Map<String, String> buildEnvironmentVariables(
      Map<String, String> flavorConfig) {
    final environment = <String, String>{};

    // Add flavor-specific environment variables
    flavorConfig.forEach((key, value) {
      environment[key] = value;
    });

    return environment;
  }

  /// Validates that all required arguments are present and valid.
  ///
  /// Parameters:
  /// - [argResults]: The parsed command line arguments
  ///
  /// Returns true if all validations pass.
  ///
  /// Throws:
  /// - [ArgumentError]: If any required arguments are missing or invalid
  bool validateRequiredArguments(ArgResults? argResults) {
    final target = argResults.getOptionTarget();
    if (target.isEmpty) {
      throw ArgumentError('Target cannot be empty');
    }

    final morphemeYaml = argResults.getOptionMorphemeYaml();
    if (morphemeYaml.isEmpty) {
      throw ArgumentError('Morpheme YAML path cannot be empty');
    }

    return true;
  }
}
