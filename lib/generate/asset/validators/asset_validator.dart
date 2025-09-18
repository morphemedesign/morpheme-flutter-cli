import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

import '../models/models.dart';

/// Provides comprehensive validation for asset generation operations.
///
/// Validates configurations, file system state, permissions, and asset
/// directory structures to ensure successful generation.
class AssetValidator {
  /// Creates a new AssetValidator instance.
  const AssetValidator();

  /// Validates the complete asset configuration.
  ///
  /// Performs comprehensive validation including:
  /// - Configuration parameter validation
  /// - Directory existence and permissions
  /// - Asset path validation
  /// - Project name format validation
  ///
  /// Parameters:
  /// - [config]: The asset configuration to validate
  ///
  /// Returns a [ValidationResult] with all validation findings.
  ValidationResult validateConfiguration(AssetConfig config) {
    final results = <ValidationResult>[];

    // Validate basic configuration
    results.add(_validateBasicConfig(config));

    // Validate project name
    results.add(_validateProjectName(config.projectName));

    // Validate directory paths
    results.add(_validateDirectoryPaths(config));

    // Validate file permissions
    results.add(_validateFilePermissions(config));

    // Combine all validation results
    return _combineResults(results);
  }

  /// Validates asset directories and their contents.
  ///
  /// Checks that asset directories exist, are accessible, and contain
  /// valid asset files for processing.
  ///
  /// Parameters:
  /// - [assetPaths]: List of asset directory paths from pubspec.yaml
  /// - [config]: The asset configuration
  ///
  /// Returns a [ValidationResult] with asset directory validation findings.
  ValidationResult validateAssetDirectories(
    List<String> assetPaths,
    AssetConfig config,
  ) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    if (assetPaths.isEmpty) {
      return ValidationResult.failure(
        errors: [
          ValidationError(
            message: 'No asset paths provided for validation',
            type: ValidationErrorType.missing,
          ),
        ],
        suggestions: [
          'Add asset directory paths to pubspec.yaml',
          'Ensure assets are defined under flutter > assets',
        ],
      );
    }

    for (final assetPath in assetPaths) {
      final validationResult = _validateSingleAssetDirectory(assetPath, config);

      errors.addAll(validationResult.errors);
      warnings.addAll(validationResult.warnings);
      suggestions.addAll(validationResult.suggestions);
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates the output path and ensures it's writable.
  ///
  /// Parameters:
  /// - [outputPath]: The absolute path to the output directory
  ///
  /// Returns a [ValidationResult] with output path validation findings.
  ValidationResult validateOutputPath(String outputPath) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    try {
      // Test if we can create the directory
      if (!exists(outputPath)) {
        createDir(outputPath, recursive: true);
      }

      // Test write permissions by creating a temporary file
      final testFile = join(outputPath,
          '.morpheme_test_${DateTime.now().millisecondsSinceEpoch}');

      try {
        testFile.write('test');
        if (exists(testFile)) {
          delete(testFile);
        }
      } catch (e) {
        errors.add(ValidationError(
          message: 'Cannot write to output directory: $outputPath',
          type: ValidationErrorType.permission,
          details: e.toString(),
        ));
        suggestions.add('Check write permissions for the output directory');
        suggestions.add('Ensure the directory is not read-only');
      }
    } catch (e) {
      errors.add(ValidationError(
        message: 'Cannot create output directory: $outputPath',
        type: ValidationErrorType.fileSystem,
        details: e.toString(),
      ));
      suggestions.add('Check parent directory permissions');
      suggestions.add('Ensure sufficient disk space is available');
    }

    // Check if output directory conflicts with existing files
    if (exists(outputPath)) {
      final dir = Directory(outputPath);
      try {
        final entities = dir.listSync();
        final conflictingFiles = entities
            .where((entity) => entity is File && entity.path.endsWith('.dart'))
            .cast<File>()
            .toList();

        if (conflictingFiles.isNotEmpty) {
          warnings.add(ValidationWarning(
            message:
                'Output directory contains ${conflictingFiles.length} existing Dart files',
            type: ValidationWarningType.general,
          ));
          suggestions
              .add('Existing files will be overwritten during generation');
          suggestions
              .add('Consider backing up important files before proceeding');
        }
      } catch (e) {
        warnings.add(ValidationWarning(
          message: 'Cannot read output directory contents: $e',
          type: ValidationWarningType.general,
        ));
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates file system permissions for asset generation.
  ///
  /// Checks read permissions for source directories and write permissions
  /// for output directories.
  ///
  /// Parameters:
  /// - [config]: The asset configuration
  ///
  /// Returns a [ValidationResult] with permission validation findings.
  ValidationResult validateFilePermissions(AssetConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    // Check pubspec directory read permissions
    final pubspecDir = join(current, config.pubspecDir);
    if (exists(pubspecDir)) {
      if (!_canReadDirectory(pubspecDir)) {
        errors.add(ValidationError(
          message: 'Cannot read pubspec directory: ${config.pubspecDir}',
          type: ValidationErrorType.permission,
        ));
        suggestions.add('Check read permissions for the pubspec directory');
      }
    }

    // Check assets directory read permissions
    final assetsDir = join(current, config.assetsDir);
    if (exists(assetsDir)) {
      if (!_canReadDirectory(assetsDir)) {
        errors.add(ValidationError(
          message: 'Cannot read assets directory: ${config.assetsDir}',
          type: ValidationErrorType.permission,
        ));
        suggestions.add('Check read permissions for the assets directory');
      }
    }

    // Check output directory write permissions
    final outputValidation = validateOutputPath(config.getOutputPath());
    errors.addAll(outputValidation.errors);
    warnings.addAll(outputValidation.warnings);
    suggestions.addAll(outputValidation.suggestions);

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates asset naming conventions and detectts potential issues.
  ///
  /// Checks for:
  /// - Invalid characters in asset names
  /// - Naming conflicts
  /// - Reserved words usage
  /// - Case sensitivity issues
  ///
  /// Parameters:
  /// - [assets]: List of assets to validate
  ///
  /// Returns a [ValidationResult] with naming validation findings.
  ValidationResult validateAssetNaming(List<Asset> assets) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    final constantNames = <String>{};
    final classNames = <String>{};

    for (final asset in assets) {
      // Validate constant name
      final constantName = asset.toConstantName();
      if (constantName.isEmpty) {
        errors.add(ValidationError(
          message: 'Asset "${asset.name}" produces empty constant name',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Ensure asset names contain valid characters');
      } else if (_isReservedWord(constantName)) {
        errors.add(ValidationError(
          message: 'Asset "${asset.name}" uses reserved word "$constantName"',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Rename the asset to avoid reserved words');
      } else if (constantNames.contains(constantName)) {
        errors.add(ValidationError(
          message:
              'Duplicate constant name "$constantName" for asset "${asset.name}"',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Rename one of the conflicting assets');
      } else {
        constantNames.add(constantName);
      }

      // Validate class name
      final className = asset.toClassName();
      if (className.isEmpty) {
        errors.add(ValidationError(
          message:
              'Asset directory "${asset.directory}" produces empty class name',
          type: ValidationErrorType.format,
        ));
      } else if (_isReservedWord(className)) {
        warnings.add(ValidationWarning(
          message:
              'Directory "${asset.directory}" uses reserved word "$className"',
          type: ValidationWarningType.bestPractice,
        ));
        suggestions
            .add('Consider renaming the directory to avoid reserved words');
      } else {
        classNames.add(className);
      }

      // Check for special characters
      if (asset.name.contains(RegExp(r'[^a-zA-Z0-9_-]'))) {
        warnings.add(ValidationWarning(
          message: 'Asset "${asset.name}" contains special characters',
          type: ValidationWarningType.bestPractice,
        ));
        suggestions.add(
            'Consider using only alphanumeric characters, hyphens, and underscores');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates basic configuration parameters.
  ValidationResult _validateBasicConfig(AssetConfig config) {
    final errors = config.validate();

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors
            .map((error) => ValidationError(
                  message: error,
                  type: ValidationErrorType.configuration,
                ))
            .toList(),
      );
    }

    return ValidationResult.success();
  }

  /// Validates the project name format and conventions.
  ValidationResult _validateProjectName(String projectName) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    if (projectName.isEmpty) {
      errors.add(ValidationError(
        message: 'Project name cannot be empty',
        field: 'projectName',
        type: ValidationErrorType.missing,
      ));
      suggestions.add('Set a valid project name in morpheme.yaml');
    } else {
      // Check Dart identifier format
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(projectName)) {
        errors.add(ValidationError(
          message: 'Project name "$projectName" is not a valid Dart identifier',
          field: 'projectName',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Use only letters, numbers, and underscores');
        suggestions.add('Start with a letter');
      }

      // Check for reserved words
      if (_isReservedWord(projectName)) {
        errors.add(ValidationError(
          message: 'Project name "$projectName" is a reserved word',
          field: 'projectName',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Choose a different project name');
      }

      // Best practice checks
      if (projectName.length < 3) {
        warnings.add(ValidationWarning(
          message: 'Project name "$projectName" is very short',
          field: 'projectName',
          type: ValidationWarningType.bestPractice,
        ));
        suggestions.add('Consider using a more descriptive project name');
      }

      if (projectName.contains('_') && projectName.contains(RegExp(r'[A-Z]'))) {
        warnings.add(ValidationWarning(
          message: 'Project name mixes underscores and capital letters',
          field: 'projectName',
          type: ValidationWarningType.bestPractice,
        ));
        suggestions.add('Use either snake_case or camelCase consistently');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates directory paths in the configuration.
  ValidationResult _validateDirectoryPaths(AssetConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    // Validate path formats
    final pathFields = {
      'pubspec_dir': config.pubspecDir,
      'output_dir': config.outputDir,
      'assets_dir': config.assetsDir,
      'flavor_dir': config.flavorDir,
    };

    for (final entry in pathFields.entries) {
      final fieldName = entry.key;
      final path = entry.value;

      if (path.isEmpty) {
        errors.add(ValidationError(
          message: '$fieldName cannot be empty',
          field: fieldName,
          type: ValidationErrorType.missing,
        ));
        continue;
      }

      // Check for invalid path characters
      if (path.contains('..')) {
        errors.add(ValidationError(
          message: '$fieldName contains invalid path traversal: $path',
          field: fieldName,
          type: ValidationErrorType.format,
        ));
        suggestions.add('Use relative paths without ".." components');
      }

      // Check for absolute paths (usually not desired in config)
      if (isAbsolute(path)) {
        warnings.add(ValidationWarning(
          message: '$fieldName uses absolute path: $path',
          field: fieldName,
          type: ValidationWarningType.bestPractice,
        ));
        suggestions.add('Consider using relative paths for better portability');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validates file permissions for the configuration.
  ValidationResult _validateFilePermissions(AssetConfig config) {
    return validateFilePermissions(config);
  }

  /// Validates a single asset directory.
  ValidationResult _validateSingleAssetDirectory(
      String assetPath, AssetConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    // Resolve full path
    final fullPath = join(current, config.pubspecDir, assetPath);

    if (!exists(fullPath)) {
      errors.add(ValidationError(
        message: 'Asset directory does not exist: $assetPath',
        type: ValidationErrorType.missing,
        details: 'Full path: $fullPath',
      ));
      suggestions.add('Create the asset directory: $assetPath');
      suggestions.add('Check the path in pubspec.yaml');
      return ValidationResult.failure(
        errors: errors,
        suggestions: suggestions,
      );
    }

    // Check if it's actually a directory
    if (!Directory(fullPath).existsSync()) {
      errors.add(ValidationError(
        message: 'Asset path is not a directory: $assetPath',
        type: ValidationErrorType.format,
        details: 'Full path: $fullPath',
      ));
      suggestions.add('Ensure the path points to a directory, not a file');
      return ValidationResult.failure(
        errors: errors,
        suggestions: suggestions,
      );
    }

    // Check read permissions
    if (!_canReadDirectory(fullPath)) {
      errors.add(ValidationError(
        message: 'Cannot read asset directory: $assetPath',
        type: ValidationErrorType.permission,
      ));
      suggestions.add('Check read permissions for the directory');
      return ValidationResult.failure(
        errors: errors,
        suggestions: suggestions,
      );
    }

    // Check if directory is empty
    try {
      final dir = Directory(fullPath);
      final entities = dir.listSync();

      if (entities.isEmpty) {
        warnings.add(ValidationWarning(
          message: 'Asset directory is empty: $assetPath',
          type: ValidationWarningType.general,
        ));
        suggestions.add('Add asset files to the directory');
      } else {
        // Check if directory contains only subdirectories (no files)
        final files = entities.whereType<File>().toList();
        if (files.isEmpty) {
          warnings.add(ValidationWarning(
            message: 'Asset directory contains no files: $assetPath',
            type: ValidationWarningType.general,
          ));
          suggestions
              .add('Add asset files to the directory or its subdirectories');
        }
      }
    } catch (e) {
      warnings.add(ValidationWarning(
        message: 'Cannot read directory contents: $assetPath - $e',
        type: ValidationWarningType.general,
      ));
    }

    return ValidationResult.success(
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Checks if a directory can be read.
  bool _canReadDirectory(String path) {
    try {
      final dir = Directory(path);
      dir.listSync();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a string is a Dart reserved word.
  bool _isReservedWord(String word) {
    const reservedWords = {
      // Dart reserved words
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
      'class', 'const', 'continue', 'default', 'deferred', 'do', 'dynamic',
      'else', 'enum', 'export', 'extends', 'external', 'factory', 'false',
      'final', 'finally', 'for', 'function', 'get', 'hide', 'if',
      'implements', 'import', 'in', 'interface', 'is', 'library', 'mixin',
      'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
      'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
      'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with',
      'yield',
      // Common Flutter/Dart class names
      'Widget', 'State', 'StatelessWidget', 'StatefulWidget', 'BuildContext',
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Object',
    };
    return reservedWords.contains(word);
  }

  /// Combines multiple validation results into a single result.
  ValidationResult _combineResults(List<ValidationResult> results) {
    final allErrors = <ValidationError>[];
    final allWarnings = <ValidationWarning>[];
    final allSuggestions = <String>[];

    for (final result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
      allSuggestions.addAll(result.suggestions);
    }

    // Remove duplicate suggestions
    final uniqueSuggestions = allSuggestions.toSet().toList();

    if (allErrors.isNotEmpty) {
      return ValidationResult.failure(
        errors: allErrors,
        warnings: allWarnings,
        suggestions: uniqueSuggestions,
      );
    }

    return ValidationResult.success(
      warnings: allWarnings,
      suggestions: uniqueSuggestions,
    );
  }
}
