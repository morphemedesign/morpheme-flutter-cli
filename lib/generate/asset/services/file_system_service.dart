import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';

import '../models/models.dart';

/// Provides centralized file system operations for asset generation.
///
/// Encapsulates all file system interactions with error handling,
/// validation, and atomic operations to ensure data integrity.
class FileSystemService {
  /// Creates a new FileSystemService instance.
  const FileSystemService();

  /// Creates the necessary directory structure for asset generation.
  ///
  /// Ensures all required directories exist before generation begins,
  /// creating them recursively if needed.
  ///
  /// Parameters:
  /// - [config]: Asset configuration containing directory paths
  ///
  /// Returns a [ValidationResult] indicating success or failure.
  ValidationResult createDirectoryStructure(AssetConfig config) {
    final errors = <ValidationError>[];
    final suggestions = <String>[];

    try {
      // Create output directory
      final outputPath = config.getOutputPath();
      _createDirectorySafely(outputPath);

      // Create source output directory
      final sourceOutputPath = config.getSourceOutputPath();
      _createDirectorySafely(sourceOutputPath);

      return ValidationResult.success();
    } catch (e) {
      errors.add(ValidationError(
        message: 'Failed to create directory structure: $e',
        type: ValidationErrorType.fileSystem,
      ));
      suggestions.add('Check write permissions for the output directory');
      suggestions.add('Ensure sufficient disk space is available');

      return ValidationResult.failure(
        errors: errors,
        suggestions: suggestions,
      );
    }
  }

  /// Writes multiple files to the file system atomically.
  ///
  /// Attempts to write all files and provides rollback capability
  /// if any operation fails to maintain consistency.
  ///
  /// Parameters:
  /// - [files]: List of [GeneratedFile] instances to write
  /// - [config]: Asset configuration for path resolution
  ///
  /// Returns a [ValidationResult] indicating success or failure.
  ValidationResult writeFiles(List<GeneratedFile> files, AssetConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];
    final writtenFiles = <String>[];

    try {
      // Create directory structure first
      final dirResult = createDirectoryStructure(config);
      if (!dirResult.isValid) {
        return dirResult;
      }

      // Write each file
      for (final file in files) {
        try {
          _writeFileSafely(file);
          writtenFiles.add(file.path);
        } catch (e) {
          errors.add(ValidationError(
            message: 'Failed to write file ${file.path}: $e',
            type: ValidationErrorType.fileSystem,
          ));

          // Attempt rollback for already written files
          _rollbackFiles(writtenFiles);

          suggestions.add('Check write permissions for the target directory');
          suggestions.add('Ensure sufficient disk space is available');
          suggestions.add('Verify the file path is valid');

          return ValidationResult.failure(
            errors: errors,
            suggestions: suggestions,
          );
        }
      }

      return ValidationResult.success(
        warnings: warnings,
      );
    } catch (e) {
      errors.add(ValidationError(
        message: 'Unexpected error during file writing: $e',
        type: ValidationErrorType.fileSystem,
      ));

      return ValidationResult.failure(
        errors: errors,
        suggestions: suggestions,
      );
    }
  }

  /// Writes a single file to the file system.
  ///
  /// Creates the file with proper error handling and validation.
  ///
  /// Parameters:
  /// - [file]: The [GeneratedFile] to write
  ///
  /// Returns a [ValidationResult] indicating success or failure.
  ValidationResult writeFile(GeneratedFile file) {
    try {
      _writeFileSafely(file);
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure(
        errors: [
          ValidationError(
            message: 'Failed to write file ${file.path}: $e',
            type: ValidationErrorType.fileSystem,
          ),
        ],
        suggestions: [
          'Check write permissions for the target directory',
          'Ensure the parent directory exists',
          'Verify sufficient disk space is available',
        ],
      );
    }
  }

  /// Backs up existing files before overwriting them.
  ///
  /// Creates backup copies of files that will be overwritten during
  /// generation, allowing for recovery if needed.
  ///
  /// Parameters:
  /// - [filePaths]: List of file paths to backup
  /// - [backupSuffix]: Suffix to append to backup files (default: '.backup')
  ///
  /// Returns a map of original paths to backup paths.
  Map<String, String> backupFiles(
    List<String> filePaths, {
    String backupSuffix = '.backup',
  }) {
    final backupMap = <String, String>{};

    for (final filePath in filePaths) {
      if (exists(filePath)) {
        final backupPath = '$filePath$backupSuffix';
        try {
          copy(filePath, backupPath);
          backupMap[filePath] = backupPath;
        } catch (e) {
          print('Warning: Failed to backup $filePath: $e');
        }
      }
    }

    return backupMap;
  }

  /// Restores files from their backup copies.
  ///
  /// Restores previously backed up files to their original locations.
  ///
  /// Parameters:
  /// - [backupMap]: Map of original paths to backup paths
  ///
  /// Returns a [ValidationResult] indicating success or failure.
  ValidationResult restoreFromBackup(Map<String, String> backupMap) {
    final errors = <ValidationError>[];

    for (final entry in backupMap.entries) {
      final originalPath = entry.key;
      final backupPath = entry.value;

      try {
        if (exists(backupPath)) {
          copy(backupPath, originalPath);
          delete(backupPath); // Clean up backup file
        }
      } catch (e) {
        errors.add(ValidationError(
          message: 'Failed to restore $originalPath from backup: $e',
          type: ValidationErrorType.fileSystem,
        ));
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors);
    }

    return ValidationResult.success();
  }

  /// Cleans up temporary and backup files.
  ///
  /// Removes temporary files created during the generation process
  /// to keep the file system clean.
  ///
  /// Parameters:
  /// - [tempFiles]: List of temporary file paths to remove
  /// - [backupFiles]: List of backup file paths to remove
  ///
  /// Returns the number of files successfully cleaned up.
  int cleanupTempFiles(List<String> tempFiles, List<String> backupFiles) {
    var cleanedCount = 0;

    final allFilesToClean = [...tempFiles, ...backupFiles];

    for (final filePath in allFilesToClean) {
      try {
        if (exists(filePath)) {
          delete(filePath);
          cleanedCount++;
        }
      } catch (e) {
        print('Warning: Failed to cleanup $filePath: $e');
      }
    }

    return cleanedCount;
  }

  /// Validates that all required directories exist and are accessible.
  ///
  /// Checks directory existence and permissions before proceeding
  /// with file operations.
  ///
  /// Parameters:
  /// - [directoryPaths]: List of directory paths to validate
  ///
  /// Returns a [ValidationResult] with validation findings.
  ValidationResult validateDirectories(List<String> directoryPaths) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final suggestions = <String>[];

    for (final dirPath in directoryPaths) {
      if (!exists(dirPath)) {
        warnings.add(ValidationWarning(
          message: 'Directory does not exist: $dirPath',
          type: ValidationWarningType.general,
        ));
        suggestions.add('Create the directory: $dirPath');
        continue;
      }

      if (!Directory(dirPath).existsSync()) {
        errors.add(ValidationError(
          message: 'Path is not a directory: $dirPath',
          type: ValidationErrorType.format,
        ));
        suggestions.add('Ensure the path points to a directory');
        continue;
      }

      // Test read permissions
      try {
        Directory(dirPath).listSync();
      } catch (e) {
        errors.add(ValidationError(
          message: 'Cannot read directory: $dirPath - $e',
          type: ValidationErrorType.permission,
        ));
        suggestions.add('Check read permissions for the directory');
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

  /// Gets file system statistics for the specified paths.
  ///
  /// Collects information about disk usage, file counts, and other
  /// relevant metrics for reporting and validation.
  ///
  /// Parameters:
  /// - [paths]: List of paths to analyze
  ///
  /// Returns a map containing file system statistics.
  Map<String, dynamic> getFileSystemStats(List<String> paths) {
    final stats = <String, dynamic>{};

    var totalFiles = 0;
    var totalDirectories = 0;
    var totalSizeBytes = 0;
    final pathStats = <String, Map<String, dynamic>>{};

    for (final path in paths) {
      final pathStat = <String, dynamic>{};

      if (!exists(path)) {
        pathStat['exists'] = false;
        pathStats[path] = pathStat;
        continue;
      }

      pathStat['exists'] = true;

      if (Directory(path).existsSync()) {
        pathStat['type'] = 'directory';

        try {
          final dir = Directory(path);
          final entities = dir.listSync(recursive: true);

          final files = entities.whereType<File>().toList();
          final directories = entities.whereType<Directory>().toList();

          pathStat['fileCount'] = files.length;
          pathStat['directoryCount'] = directories.length;

          var pathSize = 0;
          for (final file in files) {
            try {
              pathSize += file.lengthSync();
            } catch (e) {
              // Skip files we can't read
            }
          }
          pathStat['sizeBytes'] = pathSize;

          totalFiles += files.length;
          totalDirectories += directories.length;
          totalSizeBytes += pathSize;
        } catch (e) {
          pathStat['error'] = e.toString();
        }
      } else {
        pathStat['type'] = 'file';
        try {
          final fileSize = File(path).lengthSync();
          pathStat['sizeBytes'] = fileSize;
          totalSizeBytes += fileSize;
          totalFiles++;
        } catch (e) {
          pathStat['error'] = e.toString();
        }
      }

      pathStats[path] = pathStat;
    }

    stats['totalFiles'] = totalFiles;
    stats['totalDirectories'] = totalDirectories;
    stats['totalSizeBytes'] = totalSizeBytes;
    stats['totalSizeMB'] = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    stats['pathStats'] = pathStats;

    return stats;
  }

  /// Creates a directory safely with proper error handling.
  void _createDirectorySafely(String path) {
    try {
      createDir(path);
    } catch (e) {
      throw FileSystemException('Failed to create directory $path: $e');
    }
  }

  /// Writes a file safely with validation and error handling.
  void _writeFileSafely(GeneratedFile file) {
    // Validate file content
    if (file.content.isEmpty) {
      throw ArgumentError('File content cannot be empty: ${file.path}');
    }

    // Ensure parent directory exists
    final parentDir = dirname(file.path);
    _createDirectorySafely(parentDir);

    // Write file content
    try {
      file.path.write(file.content);
    } catch (e) {
      throw FileSystemException('Failed to write file ${file.path}: $e');
    }

    // Verify file was written correctly
    if (!exists(file.path)) {
      throw FileSystemException('File was not created: ${file.path}');
    }

    // Verify content matches (basic check)
    try {
      final writtenContent = read(file.path).join('\n');
      if (writtenContent != file.content) {
        throw FileSystemException(
            'File content verification failed: ${file.path}');
      }
    } catch (e) {
      // Log warning but don't fail the operation
      print('Warning: Could not verify file content for ${file.path}: $e');
    }
  }

  /// Attempts to rollback (delete) files that were written during a failed operation.
  void _rollbackFiles(List<String> filePaths) {
    for (final filePath in filePaths) {
      try {
        if (exists(filePath)) {
          delete(filePath);
        }
      } catch (e) {
        print('Warning: Failed to rollback file $filePath: $e');
      }
    }
  }
}

/// Exception thrown when file system operations fail.
class FileSystemException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Optional underlying cause of the exception.
  final Object? cause;

  /// Creates a new FileSystemException.
  const FileSystemException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'FileSystemException: $message\nCaused by: $cause';
    }
    return 'FileSystemException: $message';
  }
}
