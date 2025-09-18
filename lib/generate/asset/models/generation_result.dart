/// Represents a generated file with its content and metadata.
///
/// Used to track files created during the asset generation process,
/// including their type, location, and content.
class GeneratedFile {
  /// The absolute path where the file will be written.
  final String path;

  /// The complete content of the generated file.
  final String content;

  /// The type of file being generated.
  final FileType type;

  /// Optional description of what this file contains.
  final String? description;

  /// Creates a new GeneratedFile instance.
  const GeneratedFile({
    required this.path,
    required this.content,
    required this.type,
    this.description,
  });

  /// Gets the filename from the path.
  String get fileName {
    return path.split('/').last;
  }

  /// Gets the directory path from the full path.
  String get directory {
    final parts = path.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }

  /// Gets the file size in bytes.
  int get sizeInBytes {
    return content.length;
  }

  /// Checks if this file is a Dart source file.
  bool get isDartFile {
    return fileName.endsWith('.dart');
  }

  @override
  String toString() {
    return 'GeneratedFile{'
        'path: $path, '
        'type: $type, '
        'size: $sizeInBytes bytes'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          content == other.content &&
          type == other.type &&
          description == other.description;

  @override
  int get hashCode =>
      path.hashCode ^ content.hashCode ^ type.hashCode ^ description.hashCode;
}

/// Enumeration of different file types that can be generated.
enum FileType {
  /// Dart class file containing asset constants.
  assetClass,

  /// Library export file that exports all generated classes.
  exportFile,

  /// Configuration or metadata file.
  configFile,

  /// Documentation file.
  documentation,
}

/// Contains the complete result of an asset generation operation.
///
/// Includes all generated files, warnings encountered during generation,
/// and performance metrics for the operation.
class GenerationResult {
  /// List of all files generated during the operation.
  final List<GeneratedFile> generatedFiles;

  /// List of warning messages encountered during generation.
  final List<String> warnings;

  /// Performance metrics for the generation operation.
  final GenerationMetrics metrics;

  /// Whether the generation operation completed successfully.
  final bool isSuccess;

  /// Optional error message if the operation failed.
  final String? errorMessage;

  /// Creates a new GenerationResult instance.
  const GenerationResult({
    required this.generatedFiles,
    required this.warnings,
    required this.metrics,
    required this.isSuccess,
    this.errorMessage,
  });

  /// Creates a successful GenerationResult.
  factory GenerationResult.success({
    required List<GeneratedFile> generatedFiles,
    List<String> warnings = const [],
    required GenerationMetrics metrics,
  }) {
    return GenerationResult(
      generatedFiles: generatedFiles,
      warnings: warnings,
      metrics: metrics,
      isSuccess: true,
    );
  }

  /// Creates a failed GenerationResult.
  factory GenerationResult.failure({
    required String errorMessage,
    List<GeneratedFile> generatedFiles = const [],
    List<String> warnings = const [],
    GenerationMetrics? metrics,
  }) {
    return GenerationResult(
      generatedFiles: generatedFiles,
      warnings: warnings,
      metrics: metrics ?? GenerationMetrics.empty(),
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// Gets the total number of files generated.
  int get fileCount => generatedFiles.length;

  /// Checks if any warnings were encountered.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Gets all asset class files.
  List<GeneratedFile> get assetClassFiles {
    return generatedFiles
        .where((file) => file.type == FileType.assetClass)
        .toList();
  }

  /// Gets all export files.
  List<GeneratedFile> get exportFiles {
    return generatedFiles
        .where((file) => file.type == FileType.exportFile)
        .toList();
  }

  /// Gets a summary of the generation operation.
  String getSummary() {
    if (!isSuccess) {
      return 'Generation failed: ${errorMessage ?? "Unknown error"}';
    }

    final buffer = StringBuffer();
    buffer.writeln('Asset generation completed successfully');
    buffer.writeln('Files generated: $fileCount');
    buffer.writeln('Assets processed: ${metrics.assetsProcessed}');
    buffer.writeln('Classes created: ${metrics.classesCreated}');
    buffer.writeln('Duration: ${metrics.duration.inMilliseconds}ms');

    if (hasWarnings) {
      buffer.writeln('Warnings: ${warnings.length}');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'GenerationResult{'
        'success: $isSuccess, '
        'files: $fileCount, '
        'warnings: ${warnings.length}, '
        'duration: ${metrics.duration.inMilliseconds}ms'
        '}';
  }
}

/// Performance metrics for asset generation operations.
///
/// Tracks timing, counts, and other performance-related data
/// to help with optimization and reporting.
class GenerationMetrics {
  /// Number of files generated.
  final int filesGenerated;

  /// Number of Dart classes created.
  final int classesCreated;

  /// Number of individual assets processed.
  final int assetsProcessed;

  /// Total duration of the generation operation.
  final Duration duration;

  /// Number of directories scanned.
  final int directoriesScanned;

  /// Number of files skipped during processing.
  final int filesSkipped;

  /// Creates a new GenerationMetrics instance.
  const GenerationMetrics({
    required this.filesGenerated,
    required this.classesCreated,
    required this.assetsProcessed,
    required this.duration,
    this.directoriesScanned = 0,
    this.filesSkipped = 0,
  });

  /// Creates an empty metrics instance.
  factory GenerationMetrics.empty() {
    return const GenerationMetrics(
      filesGenerated: 0,
      classesCreated: 0,
      assetsProcessed: 0,
      duration: Duration.zero,
    );
  }

  /// Converts metrics to a map for serialization or reporting.
  Map<String, dynamic> toMap() {
    return {
      'filesGenerated': filesGenerated,
      'classesCreated': classesCreated,
      'assetsProcessed': assetsProcessed,
      'durationMs': duration.inMilliseconds,
      'directoriesScanned': directoriesScanned,
      'filesSkipped': filesSkipped,
    };
  }

  /// Creates metrics from a map.
  factory GenerationMetrics.fromMap(Map<String, dynamic> map) {
    return GenerationMetrics(
      filesGenerated: map['filesGenerated'] ?? 0,
      classesCreated: map['classesCreated'] ?? 0,
      assetsProcessed: map['assetsProcessed'] ?? 0,
      duration: Duration(milliseconds: map['durationMs'] ?? 0),
      directoriesScanned: map['directoriesScanned'] ?? 0,
      filesSkipped: map['filesSkipped'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'GenerationMetrics{'
        'files: $filesGenerated, '
        'classes: $classesCreated, '
        'assets: $assetsProcessed, '
        'duration: ${duration.inMilliseconds}ms, '
        'directories: $directoriesScanned, '
        'skipped: $filesSkipped'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationMetrics &&
          runtimeType == other.runtimeType &&
          filesGenerated == other.filesGenerated &&
          classesCreated == other.classesCreated &&
          assetsProcessed == other.assetsProcessed &&
          duration == other.duration &&
          directoriesScanned == other.directoriesScanned &&
          filesSkipped == other.filesSkipped;

  @override
  int get hashCode =>
      filesGenerated.hashCode ^
      classesCreated.hashCode ^
      assetsProcessed.hashCode ^
      duration.hashCode ^
      directoriesScanned.hashCode ^
      filesSkipped.hashCode;
}
