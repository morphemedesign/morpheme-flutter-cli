import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';

import '../models/models.dart';
import '../managers/configuration_manager.dart';
import '../validators/asset_validator.dart';
import '../generators/asset_generator.dart';
import '../services/file_system_service.dart';

/// Orchestrates the complete asset generation workflow.
///
/// Coordinates all components of the asset generation system to execute
/// the complete workflow from configuration loading to file generation
/// and formatting. Provides centralized error handling and progress reporting.
class AssetOrchestrator {
  /// Configuration manager for loading and validating configurations.
  final ConfigurationManager _configManager;

  /// Validator for validating configurations and assets.
  final AssetValidator _validator;

  /// Generator for creating asset classes and export files.
  final AssetGenerator _generator;

  /// File system service for file operations.
  final FileSystemService _fileSystem;

  /// Creates a new AssetOrchestrator instance.
  ///
  /// Parameters:
  /// - [configManager]: Optional custom configuration manager
  /// - [validator]: Optional custom asset validator
  /// - [generator]: Optional custom asset generator
  /// - [fileSystem]: Optional custom file system service
  AssetOrchestrator({
    ConfigurationManager? configManager,
    AssetValidator? validator,
    AssetGenerator? generator,
    FileSystemService? fileSystem,
  })  : _configManager = configManager ?? const ConfigurationManager(),
        _validator = validator ?? const AssetValidator(),
        _generator = generator ?? const AssetGenerator(),
        _fileSystem = fileSystem ?? const FileSystemService();

  /// Executes the complete asset generation workflow.
  ///
  /// Performs the following steps:
  /// 1. Load and validate configuration
  /// 2. Merge flavor assets if specified
  /// 3. Load pubspec assets configuration
  /// 4. Validate assets and directories
  /// 5. Generate asset classes
  /// 6. Generate export file (if enabled)
  /// 7. Write files to disk
  /// 8. Format generated code
  ///
  /// Parameters:
  /// - [morphemeYamlPath]: Optional path to morpheme.yaml file
  /// - [flavor]: Optional flavor name for environment-specific generation
  ///
  /// Returns a [GenerationResult] with the outcome of the operation.
  Future<GenerationResult> execute({
    String? morphemeYamlPath,
    String? flavor,
  }) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // Step 1: Load configuration
      StatusHelper.generated('Loading configuration...');
      final config = await _loadConfiguration(morphemeYamlPath, flavor);

      // Step 2: Validate configuration
      StatusHelper.generated('Validating configuration...');
      final configValidation = await _validateConfiguration(config);
      if (!configValidation.isValid) {
        return _createFailureResult(
          'Configuration validation failed',
          configValidation.getFormattedErrors(),
          stopwatch.elapsed,
        );
      }
      warnings.addAll(configValidation.warningMessages);

      // Step 3: Merge flavor assets
      if (config.flavor != null) {
        StatusHelper.generated('Merging flavor assets...');
        final flavorResult = await _mergeFlavorAssets(config);
        if (!flavorResult.isValid) {
          warnings.addAll(flavorResult.warningMessages);
        }
      }

      // Step 4: Load pubspec assets
      StatusHelper.generated('Loading pubspec assets...');
      final assetPaths = await _loadPubspecAssets(config);

      // Step 5: Validate asset directories
      StatusHelper.generated('Validating asset directories...');
      final assetValidation =
          await _validateAssetDirectories(assetPaths, config);
      if (!assetValidation.isValid) {
        return _createFailureResult(
          'Asset validation failed',
          assetValidation.getFormattedErrors(),
          stopwatch.elapsed,
        );
      }
      warnings.addAll(assetValidation.warningMessages);

      // Step 6: Discover and validate assets
      StatusHelper.generated('Discovering assets...');
      final assets = await _discoverAssets(config, assetPaths);
      final assetNamingValidation = await _validateAssetNaming(assets);
      if (!assetNamingValidation.isValid) {
        return _createFailureResult(
          'Asset naming validation failed',
          assetNamingValidation.getFormattedErrors(),
          stopwatch.elapsed,
        );
      }
      warnings.addAll(assetNamingValidation.warningMessages);

      // Step 7: Generate asset classes
      StatusHelper.generated('Generating asset classes...');
      final generatedFiles = await _generateAssetClasses(config, assetPaths);

      // Step 8: Generate export file
      final exportFile = await _generateExportFile(config, generatedFiles);
      if (exportFile != null) {
        generatedFiles.add(exportFile);
      }

      // Step 9: Write files to disk
      StatusHelper.generated('Writing generated files...');
      final writeResult = await _writeFiles(generatedFiles, config);
      if (!writeResult.isValid) {
        return _createFailureResult(
          'File writing failed',
          writeResult.getFormattedErrors(),
          stopwatch.elapsed,
        );
      }
      warnings.addAll(writeResult.warningMessages);

      // Step 10: Format generated code
      StatusHelper.generated('Formatting generated code...');
      await _formatGeneratedCode(config);

      // Create success result
      stopwatch.stop();
      final metrics = GenerationMetrics(
        filesGenerated: generatedFiles.length,
        classesCreated:
            generatedFiles.where((f) => f.type == FileType.assetClass).length,
        assetsProcessed: assets.length,
        duration: stopwatch.elapsed,
        directoriesScanned: assetPaths.length,
      );

      return GenerationResult.success(
        generatedFiles: generatedFiles,
        warnings: warnings,
        metrics: metrics,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      print('Error during asset generation: $e');
      print('Stack trace: $stackTrace');

      return _createFailureResult(
        'Unexpected error during asset generation',
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Loads the asset configuration from morpheme.yaml.
  Future<AssetConfig> _loadConfiguration(
      String? morphemeYamlPath, String? flavor) async {
    try {
      return _configManager.loadAssetConfiguration(
        morphemeYamlPath: morphemeYamlPath,
        flavor: flavor,
      );
    } catch (e) {
      throw AssetOrchestrationException('Failed to load configuration: $e');
    }
  }

  /// Validates the asset configuration.
  Future<ValidationResult> _validateConfiguration(AssetConfig config) async {
    try {
      final configValidation = _validator.validateConfiguration(config);
      final pathValidation = _configManager.validateConfigurationPaths(config);

      return configValidation.combine(pathValidation);
    } catch (e) {
      return ValidationResult.singleError(
        message: 'Configuration validation error: $e',
      );
    }
  }

  /// Merges flavor-specific assets with the main assets.
  Future<ValidationResult> _mergeFlavorAssets(AssetConfig config) async {
    try {
      return _configManager.mergeFlavorAssets(config);
    } catch (e) {
      return ValidationResult.singleError(
        message: 'Flavor merge error: $e',
      );
    }
  }

  /// Loads asset paths from pubspec.yaml.
  Future<List<String>> _loadPubspecAssets(AssetConfig config) async {
    try {
      return _configManager.loadPubspecAssets(config);
    } catch (e) {
      throw AssetOrchestrationException('Failed to load pubspec assets: $e');
    }
  }

  /// Validates asset directories.
  Future<ValidationResult> _validateAssetDirectories(
    List<String> assetPaths,
    AssetConfig config,
  ) async {
    try {
      return _validator.validateAssetDirectories(assetPaths, config);
    } catch (e) {
      return ValidationResult.singleError(
        message: 'Asset directory validation error: $e',
      );
    }
  }

  /// Discovers all assets in the specified paths.
  Future<List<Asset>> _discoverAssets(
    AssetConfig config,
    List<String> assetPaths,
  ) async {
    try {
      return _generator.discoverAssets(config, assetPaths);
    } catch (e) {
      throw AssetOrchestrationException('Failed to discover assets: $e');
    }
  }

  /// Validates asset naming conventions.
  Future<ValidationResult> _validateAssetNaming(List<Asset> assets) async {
    try {
      return _validator.validateAssetNaming(assets);
    } catch (e) {
      return ValidationResult.singleError(
        message: 'Asset naming validation error: $e',
      );
    }
  }

  /// Generates asset classes for all directories.
  Future<List<GeneratedFile>> _generateAssetClasses(
    AssetConfig config,
    List<String> assetPaths,
  ) async {
    try {
      return _generator.generateAssetClasses(config, assetPaths);
    } catch (e) {
      throw AssetOrchestrationException('Failed to generate asset classes: $e');
    }
  }

  /// Generates the export file if enabled.
  Future<GeneratedFile?> _generateExportFile(
    AssetConfig config,
    List<GeneratedFile> generatedFiles,
  ) async {
    try {
      return _generator.generateExportFile(config, generatedFiles);
    } catch (e) {
      throw AssetOrchestrationException('Failed to generate export file: $e');
    }
  }

  /// Writes all generated files to disk.
  Future<ValidationResult> _writeFiles(
    List<GeneratedFile> files,
    AssetConfig config,
  ) async {
    try {
      return _fileSystem.writeFiles(files, config);
    } catch (e) {
      return ValidationResult.singleError(
        message: 'File writing error: $e',
      );
    }
  }

  /// Formats the generated code using dart format.
  Future<void> _formatGeneratedCode(AssetConfig config) async {
    try {
      await ModularHelper.format([config.outputDir]);
    } catch (e) {
      // Log warning but don't fail the operation
      print('Warning: Failed to format generated code: $e');
    }
  }

  /// Creates a failure result with consistent structure.
  GenerationResult _createFailureResult(
    String message,
    String details,
    Duration duration,
  ) {
    return GenerationResult.failure(
      errorMessage: '$message: $details',
      metrics: GenerationMetrics(
        filesGenerated: 0,
        classesCreated: 0,
        assetsProcessed: 0,
        duration: duration,
      ),
    );
  }
}

/// Utility class for orchestrating workflow steps with error handling.
///
/// Provides helper methods for executing workflow steps with consistent
/// error handling and progress reporting.
class WorkflowExecutor {
  /// Executes a workflow step with error handling and progress reporting.
  ///
  /// Parameters:
  /// - [stepName]: Name of the step for progress reporting
  /// - [operation]: The operation to execute
  /// - [onError]: Optional error handler
  ///
  /// Returns the result of the operation.
  static Future<T> executeStep<T>(
    String stepName,
    Future<T> Function() operation, {
    String Function(Object error)? onError,
  }) async {
    try {
      StatusHelper.generated('Executing $stepName...');
      return await operation();
    } catch (e) {
      final errorMessage =
          onError?.call(e) ?? 'Failed to execute $stepName: $e';
      throw WorkflowException(errorMessage, stepName);
    }
  }

  /// Executes multiple workflow steps in sequence.
  ///
  /// Parameters:
  /// - [steps]: Map of step names to operations
  ///
  /// Returns a map of step names to results.
  static Future<Map<String, dynamic>> executeSteps(
    Map<String, Future<dynamic> Function()> steps,
  ) async {
    final results = <String, dynamic>{};

    for (final entry in steps.entries) {
      final stepName = entry.key;
      final operation = entry.value;

      try {
        results[stepName] = await executeStep(stepName, operation);
      } catch (e) {
        throw WorkflowException(
          'Workflow failed at step "$stepName": $e',
          stepName,
        );
      }
    }

    return results;
  }

  /// Validates workflow prerequisites.
  ///
  /// Parameters:
  /// - [validators]: List of validation functions
  ///
  /// Returns a combined validation result.
  static Future<ValidationResult> validatePrerequisites(
    List<Future<ValidationResult> Function()> validators,
  ) async {
    final results = <ValidationResult>[];

    for (final validator in validators) {
      try {
        results.add(await validator());
      } catch (e) {
        results.add(ValidationResult.singleError(
          message: 'Validation error: $e',
        ));
      }
    }

    ValidationResult combined = ValidationResult.success();
    for (final result in results) {
      combined = combined.combine(result);
    }

    return combined;
  }
}

/// Exception thrown when workflow orchestration fails.
class AssetOrchestrationException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// The workflow step where the error occurred.
  final String? step;

  /// Optional underlying cause of the exception.
  final Object? cause;

  /// Creates a new AssetOrchestrationException.
  const AssetOrchestrationException(
    this.message, [
    this.step,
    this.cause,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('AssetOrchestrationException: $message');

    if (step != null) {
      buffer.write(' (step: $step)');
    }

    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }

    return buffer.toString();
  }
}

/// Exception thrown when workflow execution fails.
class WorkflowException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// The workflow step where the error occurred.
  final String step;

  /// Creates a new WorkflowException.
  const WorkflowException(this.message, this.step);

  @override
  String toString() {
    return 'WorkflowException: $message (step: $step)';
  }
}
