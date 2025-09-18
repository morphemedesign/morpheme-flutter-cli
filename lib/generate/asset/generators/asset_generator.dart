import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';

import '../models/models.dart';
import '../templates/template_generator.dart';

/// Main code generation engine for asset classes and export files.
///
/// Coordinates the generation of Dart code from asset directories,
/// handling file discovery, template rendering, and output generation.
class AssetGenerator {
  /// Template generator for creating code templates.
  final TemplateGenerator _templateGenerator;

  /// Creates a new AssetGenerator instance.
  ///
  /// Parameters:
  /// - [templateGenerator]: Optional custom template generator (defaults to TemplateGenerator())
  const AssetGenerator({
    TemplateGenerator? templateGenerator,
  }) : _templateGenerator = templateGenerator ?? const TemplateGenerator();

  /// Generates asset classes for all directories defined in the configuration.
  ///
  /// Scans asset directories, discovers assets, and generates corresponding
  /// Dart classes with static constants for each asset.
  ///
  /// Parameters:
  /// - [config]: Asset generation configuration
  /// - [assetPaths]: List of asset directory paths from pubspec.yaml
  ///
  /// Returns a list of [GeneratedFile] instances representing the created classes.
  List<GeneratedFile> generateAssetClasses(
    AssetConfig config,
    List<String> assetPaths,
  ) {
    final generatedFiles = <GeneratedFile>[];

    for (final assetPath in assetPaths) {
      try {
        final generatedFile =
            _generateAssetClassForDirectory(config, assetPath);
        if (generatedFile != null) {
          generatedFiles.add(generatedFile);
        }
      } catch (e) {
        // Log error but continue with other directories
        print('Warning: Failed to generate class for $assetPath: $e');
      }
    }

    return generatedFiles;
  }

  /// Generates a library export file that exports all asset classes.
  ///
  /// Creates a barrel file providing a single import point for all
  /// generated asset classes.
  ///
  /// Parameters:
  /// - [config]: Asset generation configuration
  /// - [generatedClassFiles]: List of generated class files to export
  ///
  /// Returns a [GeneratedFile] for the export file, or null if not needed.
  GeneratedFile? generateExportFile(
    AssetConfig config,
    List<GeneratedFile> generatedClassFiles,
  ) {
    if (!config.createLibraryFile || generatedClassFiles.isEmpty) {
      return null;
    }

    // Extract file names without extensions for export statements
    final exportNames = generatedClassFiles
        .where((file) => file.type == FileType.assetClass)
        .map((file) => _getFileNameWithoutExtension(file.fileName))
        .toList();

    if (exportNames.isEmpty) {
      return null;
    }

    final content = _templateGenerator.generateExportTemplate(exportNames);
    final exportPath = join(config.getOutputPath(), 'assets.dart');

    return GeneratedFile(
      path: exportPath,
      content: content,
      type: FileType.exportFile,
      description: 'Library export file for asset classes',
    );
  }

  /// Processes an asset directory and returns asset information.
  ///
  /// Scans the specified directory for valid asset files and creates
  /// Asset instances with proper metadata.
  ///
  /// Parameters:
  /// - [directoryPath]: Absolute path to the asset directory
  ///
  /// Returns an [AssetDirectory] containing discovered assets.
  AssetDirectory processAssetDirectory(String directoryPath) {
    if (!exists(directoryPath) || !Directory(directoryPath).existsSync()) {
      throw ArgumentError('Invalid directory path: $directoryPath');
    }

    final assets = <Asset>[];

    try {
      final entities = Directory(directoryPath).listSync(recursive: false);

      for (final entity in entities) {
        if (entity is File) {
          final asset = Asset.fromPath(entity.path);
          if (asset.shouldInclude) {
            assets.add(asset);
          }
        }
      }
    } catch (e) {
      throw AssetGenerationException(
        'Failed to scan directory $directoryPath: $e',
      );
    }

    return AssetDirectory(
      name: basename(directoryPath),
      path: directoryPath,
      assets: assets,
    );
  }

  /// Discovers all assets in the specified paths.
  ///
  /// Scans multiple asset directories and returns a comprehensive
  /// list of all discovered assets with their metadata.
  ///
  /// Parameters:
  /// - [config]: Asset generation configuration
  /// - [assetPaths]: List of asset directory paths from pubspec.yaml
  ///
  /// Returns a list of all discovered [Asset] instances.
  List<Asset> discoverAssets(AssetConfig config, List<String> assetPaths) {
    final allAssets = <Asset>[];

    for (final assetPath in assetPaths) {
      final fullPath = join(current, config.pubspecDir, assetPath);

      if (!exists(fullPath) || !Directory(fullPath).existsSync()) {
        continue; // Skip invalid paths
      }

      try {
        final assetDirectory = processAssetDirectory(fullPath);
        allAssets.addAll(assetDirectory.assets);
      } catch (e) {
        // Log warning but continue
        print('Warning: Failed to process directory $assetPath: $e');
      }
    }

    return allAssets;
  }

  /// Generates asset class for a specific directory.
  ///
  /// Creates a Dart class containing static constants for all assets
  /// found in the specified directory.
  GeneratedFile? _generateAssetClassForDirectory(
    AssetConfig config,
    String assetPath,
  ) {
    final fullPath = join(current, config.pubspecDir, assetPath);

    if (!exists(fullPath) || !Directory(fullPath).existsSync()) {
      return null;
    }

    final assetDirectory = processAssetDirectory(fullPath);

    // Skip empty directories
    if (assetDirectory.isEmpty) {
      return null;
    }

    // Clean up old files with similar naming pattern
    _cleanupOldGeneratedFiles(config, assetDirectory.name);

    // Generate class name and file path
    final directoryName = assetDirectory.name;
    final fileName =
        '${config.projectName.snakeCase}_${directoryName.snakeCase}.dart';
    final filePath = join(config.getSourceOutputPath(), fileName);

    // Build assets base path for package references
    final assetsBasePath = '${config.pubspecDir}/$assetPath'
        .replaceAll(RegExp(r'\/$'), ''); // Remove trailing slash

    // Generate class content
    final content = _templateGenerator.generateAssetClassTemplate(
      projectName: config.projectName,
      directoryName: directoryName,
      assets: assetDirectory.assets,
      assetsBasePath: assetsBasePath,
    );

    return GeneratedFile(
      path: filePath,
      content: content,
      type: FileType.assetClass,
      description:
          'Asset class for $directoryName directory (${assetDirectory.assets.length} assets)',
    );
  }

  /// Cleans up old generated files that match the naming pattern.
  ///
  /// Removes previously generated files to avoid conflicts and ensure
  /// clean generation output.
  void _cleanupOldGeneratedFiles(AssetConfig config, String directoryName) {
    try {
      final sourceDir = config.getSourceOutputPath();
      if (!exists(sourceDir)) return;

      final pattern = '*_${directoryName.snakeCase}.dart';
      final oldFiles = find(
        pattern,
        workingDirectory: sourceDir,
      ).toList();

      for (final oldFile in oldFiles) {
        try {
          delete(oldFile);
        } catch (e) {
          // Log warning but continue
          print('Warning: Failed to delete old file $oldFile: $e');
        }
      }
    } catch (e) {
      // Log warning but continue
      print('Warning: Failed to cleanup old files: $e');
    }
  }

  /// Extracts the filename without extension from a full filename.
  String _getFileNameWithoutExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return fileName;
    return fileName.substring(0, lastDotIndex);
  }
}

/// Utility class for organizing and categorizing discovered assets.
///
/// Provides methods for grouping assets by type, directory, and other
/// criteria to facilitate efficient code generation.
class AssetOrganizer {
  /// Groups assets by their containing directory.
  ///
  /// Creates a map where keys are directory names and values are
  /// lists of assets contained in those directories.
  ///
  /// Parameters:
  /// - [assets]: List of assets to group
  ///
  /// Returns a map of directory names to asset lists.
  static Map<String, List<Asset>> groupByDirectory(List<Asset> assets) {
    final grouped = <String, List<Asset>>{};

    for (final asset in assets) {
      final directory = asset.directory;
      grouped.putIfAbsent(directory, () => <Asset>[]).add(asset);
    }

    return grouped;
  }

  /// Groups assets by their file extension.
  ///
  /// Creates a map where keys are file extensions and values are
  /// lists of assets with those extensions.
  ///
  /// Parameters:
  /// - [assets]: List of assets to group
  ///
  /// Returns a map of extensions to asset lists.
  static Map<String, List<Asset>> groupByExtension(List<Asset> assets) {
    final grouped = <String, List<Asset>>{};

    for (final asset in assets) {
      final extension = asset.extension.toLowerCase();
      grouped.putIfAbsent(extension, () => <Asset>[]).add(asset);
    }

    return grouped;
  }

  /// Filters assets to include only image files.
  ///
  /// Parameters:
  /// - [assets]: List of assets to filter
  ///
  /// Returns a list containing only image assets.
  static List<Asset> filterImages(List<Asset> assets) {
    return assets.where((asset) => asset.isImage).toList();
  }

  /// Filters assets to include only font files.
  ///
  /// Parameters:
  /// - [assets]: List of assets to filter
  ///
  /// Returns a list containing only font assets.
  static List<Asset> filterFonts(List<Asset> assets) {
    return assets.where((asset) => asset.isFont).toList();
  }

  /// Sorts assets by name in alphabetical order.
  ///
  /// Parameters:
  /// - [assets]: List of assets to sort
  ///
  /// Returns a new sorted list of assets.
  static List<Asset> sortByName(List<Asset> assets) {
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Sorts assets by extension, then by name.
  ///
  /// Parameters:
  /// - [assets]: List of assets to sort
  ///
  /// Returns a new sorted list of assets.
  static List<Asset> sortByExtensionThenName(List<Asset> assets) {
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) {
      final extensionComparison = a.extension.compareTo(b.extension);
      if (extensionComparison != 0) return extensionComparison;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  /// Gets statistics about the provided assets.
  ///
  /// Calculates various metrics about the asset collection.
  ///
  /// Parameters:
  /// - [assets]: List of assets to analyze
  ///
  /// Returns a map containing asset statistics.
  static Map<String, dynamic> getStatistics(List<Asset> assets) {
    final stats = <String, dynamic>{};

    stats['totalAssets'] = assets.length;
    stats['totalDirectories'] = groupByDirectory(assets).keys.length;
    stats['totalExtensions'] = groupByExtension(assets).keys.length;
    stats['imageCount'] = filterImages(assets).length;
    stats['fontCount'] = filterFonts(assets).length;

    final extensionCounts = <String, int>{};
    for (final asset in assets) {
      final ext = asset.extension.toLowerCase();
      extensionCounts[ext] = (extensionCounts[ext] ?? 0) + 1;
    }
    stats['extensionBreakdown'] = extensionCounts;

    return stats;
  }
}

/// Exception thrown when asset generation operations fail.
class AssetGenerationException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Optional underlying cause of the exception.
  final Object? cause;

  /// Creates a new AssetGenerationException.
  const AssetGenerationException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'AssetGenerationException: $message\nCaused by: $cause';
    }
    return 'AssetGenerationException: $message';
  }
}
