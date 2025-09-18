import 'dart:io';

import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/dependency_manager.dart';

/// Represents an individual asset file with metadata.
///
/// Contains information about the asset's location, type, and naming
/// conventions for code generation.
class Asset {
  /// The file name without extension (e.g., 'icon' from 'icon.png').
  final String name;

  /// The complete file path relative to the project root.
  final String path;

  /// The file extension (e.g., 'png', 'svg', 'jpg').
  final String extension;

  /// The directory name containing this asset.
  final String directory;

  /// The full filename including extension.
  final String fileName;

  /// Creates a new Asset instance.
  const Asset({
    required this.name,
    required this.path,
    required this.extension,
    required this.directory,
    required this.fileName,
  });

  /// Creates an Asset from a file path.
  ///
  /// Extracts the necessary metadata from the file path:
  /// - name: filename without extension
  /// - extension: file extension
  /// - directory: containing directory name
  /// - fileName: complete filename with extension
  factory Asset.fromPath(String filePath) {
    final fileName = basename(filePath);
    final name = basenameWithoutExtension(filePath);
    final extension = fileName.contains('.') ? fileName.split('.').last : '';
    final directory = basename(dirname(filePath));

    return Asset(
      name: name,
      path: filePath,
      extension: extension,
      directory: directory,
      fileName: fileName,
    );
  }

  /// Converts the asset name to a valid Dart constant name.
  ///
  /// Transforms the asset name using camelCase convention
  /// and ensures it's a valid Dart identifier.
  ///
  /// Example: 'my-icon.png' becomes 'myIcon'
  String toConstantName() {
    return name.camelCase;
  }

  /// Converts the directory name to a valid Dart class name.
  ///
  /// Transforms the directory name using PascalCase convention.
  ///
  /// Example: 'app-icons' becomes 'AppIcons'
  String toClassName() {
    return directory.pascalCase;
  }

  /// Gets the relative path from the assets directory.
  ///
  /// Used for generating the correct asset paths in generated code.
  String getRelativePath(String assetsRoot) {
    // Normalize the assets root by removing trailing slashes
    final normalizedRoot = assetsRoot.replaceAll(RegExp(r'[/\\]+$'), '');

    if (path.startsWith(normalizedRoot)) {
      final relativePath = path.substring(normalizedRoot.length);
      // Remove leading slash if present
      return relativePath.replaceAll(RegExp(r'^[/\\]+'), '');
    }
    return path;
  }

  /// Checks if this asset is an image file.
  ///
  /// Supports common image formats: png, jpg, jpeg, gif, svg, webp
  bool get isImage {
    const imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp'};
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Checks if this asset is a font file.
  ///
  /// Supports common font formats: ttf, otf, woff, woff2
  bool get isFont {
    const fontExtensions = {'ttf', 'otf', 'woff', 'woff2'};
    return fontExtensions.contains(extension.toLowerCase());
  }

  /// Checks if this asset should be included in generation.
  ///
  /// Excludes certain files and directories that shouldn't be processed:
  /// - Hidden files (starting with '.')
  /// - Generated files (ending with '_gen.dart')
  /// - System files (like .DS_Store)
  bool get shouldInclude {
    if (name.startsWith('.')) return false;
    if (name.endsWith('_gen')) return false;
    if (fileName == '.DS_Store') return false;
    return true;
  }

  @override
  String toString() {
    return 'Asset{'
        'name: $name, '
        'path: $path, '
        'extension: $extension, '
        'directory: $directory, '
        'fileName: $fileName'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          extension == other.extension &&
          directory == other.directory &&
          fileName == other.fileName;

  @override
  int get hashCode =>
      name.hashCode ^
      path.hashCode ^
      extension.hashCode ^
      directory.hashCode ^
      fileName.hashCode;
}

/// Represents a directory containing assets with metadata.
///
/// Groups related assets and provides convenient access methods
/// for processing and code generation.
class AssetDirectory {
  /// The directory name.
  final String name;

  /// The absolute directory path.
  final String path;

  /// List of assets contained in this directory.
  final List<Asset> assets;

  /// Creates a new AssetDirectory instance.
  const AssetDirectory({
    required this.name,
    required this.path,
    required this.assets,
  });

  /// Creates an AssetDirectory by scanning a directory path.
  ///
  /// Recursively scans the directory and creates Asset instances
  /// for all valid files found.
  factory AssetDirectory.fromPath(String directoryPath) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }

    final assets = <Asset>[];
    final entities = directory.listSync(recursive: false);

    for (final entity in entities) {
      if (entity is File) {
        final asset = Asset.fromPath(entity.path);
        if (asset.shouldInclude) {
          assets.add(asset);
        }
      }
    }

    return AssetDirectory(
      name: basename(directoryPath),
      path: directoryPath,
      assets: assets,
    );
  }

  /// Checks if the directory is empty (contains no valid assets).
  bool get isEmpty => assets.isEmpty;

  /// Gets the total number of assets in this directory.
  int get assetCount => assets.length;

  /// Filters assets by file extension.
  ///
  /// Example: `filterByExtension('png')` returns only PNG files.
  List<Asset> filterByExtension(String extension) {
    return assets
        .where(
            (asset) => asset.extension.toLowerCase() == extension.toLowerCase())
        .toList();
  }

  /// Gets all image assets in this directory.
  List<Asset> get imageAssets {
    return assets.where((asset) => asset.isImage).toList();
  }

  /// Gets all font assets in this directory.
  List<Asset> get fontAssets {
    return assets.where((asset) => asset.isFont).toList();
  }

  /// Converts the directory name to a valid Dart class name.
  ///
  /// Uses PascalCase convention for class naming.
  String toClassName() {
    return name.pascalCase;
  }

  @override
  String toString() {
    return 'AssetDirectory{'
        'name: $name, '
        'path: $path, '
        'assets: ${assets.length} items'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetDirectory &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          assets == other.assets;

  @override
  int get hashCode => name.hashCode ^ path.hashCode ^ assets.hashCode;
}
