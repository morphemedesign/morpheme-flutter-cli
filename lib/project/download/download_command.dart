import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to download external resources as specified in the morpheme.yaml configuration.
///
/// This command processes download configurations from morpheme.yaml and downloads
/// files from external URLs to specified local directories. It supports both
/// regular files and compressed archives with automatic extraction.
///
/// **Purpose:**
/// - Automates downloading of external dependencies and assets
/// - Supports compressed file extraction (ZIP, TAR, etc.)
/// - Provides progress tracking for large downloads
/// - Validates download configurations before execution
///
/// **Configuration Format (morpheme.yaml):**
/// ```yaml
/// download:
///   asset_pack:
///     url: "https://example.com/assets.zip"
///     dir: "assets/downloaded"
///     compressed: true
///   documentation:
///     url: "https://example.com/docs.pdf"
///     dir: "docs"
///     compressed: false
/// ```
///
/// **Usage:**
/// ```bash
/// # Download all configured resources
/// morpheme download
///
/// # Download with custom morpheme.yaml
/// morpheme download --morpheme-yaml custom.yaml
/// ```
///
/// **Parameters:**
/// - `--morpheme-yaml`: Path to custom morpheme.yaml file
///
/// **Exceptions:**
/// - Throws [ConfigurationException] if morpheme.yaml is invalid
/// - Throws [NetworkException] if download fails
/// - Throws [FileSystemException] if file operations fail
///
/// **Example Configuration:**
/// ```yaml
/// download:
///   external_library:
///     url: "https://cdn.example.com/library.zip"
///     dir: "lib/external"
///     compressed: true
/// ```
class DownloadCommand extends Command {
  DownloadCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'download';

  @override
  String get description =>
      'Download external resources and dependencies as configured in morpheme.yaml.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    try {
      final argMorphemeYaml = argResults.getOptionMorphemeYaml();
      YamlHelper.validateMorphemeYaml(argMorphemeYaml);

      final morphemeConfig = YamlHelper.loadFileYaml(argMorphemeYaml);
      final downloadConfig = _validateDownloadConfiguration(morphemeConfig);

      if (downloadConfig.isEmpty) {
        printMessage('📎 No download configurations found in morpheme.yaml');
        StatusHelper.success('No downloads to process');
        return;
      }

      printMessage(
          '📦 Starting download process for ${downloadConfig.length} item(s)...');

      // Process downloads concurrently for better performance
      final downloadTasks = downloadConfig.entries
          .map((entry) => _processDownloadItem(entry.key, entry.value))
          .toList();

      await Future.wait(downloadTasks);

      printMessage('✨ All downloads completed successfully!');
      StatusHelper.success('download operation completed');
    } catch (e) {
      StatusHelper.failed('Download operation failed: $e');
    }
  }

  /// Validates and extracts the download configuration from morpheme.yaml.
  ///
  /// **Parameters:**
  /// - [morphemeConfig]: The loaded morpheme.yaml configuration
  ///
  /// **Returns:** Map of download configurations
  ///
  /// **Throws:**
  /// - [ConfigurationException] if download section is invalid
  Map<String, dynamic> _validateDownloadConfiguration(
      Map<dynamic, dynamic> morphemeConfig) {
    final downloadSection = morphemeConfig['download'];

    if (downloadSection == null) {
      return <String, dynamic>{};
    }

    if (downloadSection is! Map) {
      throw const FormatException(
          'Invalid download configuration: expected a map with download items');
    }

    return Map<String, dynamic>.from(downloadSection);
  }

  /// Processes a single download item from the configuration.
  ///
  /// **Parameters:**
  /// - [itemName]: Name of the download item
  /// - [config]: Configuration for this download item
  ///
  /// **Throws:**
  /// - [ConfigurationException] if item configuration is invalid
  /// - [NetworkException] if download fails
  /// - [FileSystemException] if file operations fail
  Future<void> _processDownloadItem(String itemName, dynamic config) async {
    if (config is! Map) {
      throw FormatException(
          'Invalid configuration for "$itemName": expected a map with "url" and "dir" properties');
    }

    final downloadUrl = config['url'] as String?;
    final targetDirectory = config['dir'] as String?;
    final isCompressed = config['compressed'] as bool? ?? false;

    if (downloadUrl == null || targetDirectory == null) {
      throw FormatException(
          'Incomplete configuration for "$itemName": both "url" and "dir" are required');
    }

    try {
      printMessage('📥 Downloading "$itemName" from $downloadUrl...');

      final downloadedBytes = await _downloadFileWithProgress(downloadUrl);
      final targetFile = await _saveDownloadedFile(
          downloadedBytes, downloadUrl, targetDirectory);

      if (isCompressed) {
        await _extractCompressedFile(targetFile, targetDirectory);
        await _cleanupCompressedFile(targetFile);
      }

      printMessage('✓ Successfully processed "$itemName"');
    } catch (e) {
      throw Exception('Failed to process download item "$itemName": $e');
    }
  }

  /// Downloads a file from the specified URL with progress tracking.
  ///
  /// **Parameters:**
  /// - [url]: The URL to download from
  ///
  /// **Returns:** The downloaded file bytes
  ///
  /// **Throws:**
  /// - [NetworkException] if download fails
  Future<List<int>> _downloadFileWithProgress(String url) async {
    try {
      return await HttpClientHelper.downloadFile(
        url,
        onProgress: (downloadedLength, contentLength, progress) {
          final progressStr = progress.toStringAsFixed(1);
          final downloadedMB =
              (downloadedLength / 1024 / 1024).toStringAsFixed(1);
          final totalMB = (contentLength / 1024 / 1024).toStringAsFixed(1);

          stdout.write(
              '\r📥 Progress: ${downloadedMB}MB / ${totalMB}MB ($progressStr%)');
        },
      );
    } catch (e) {
      throw Exception('Network download failed: $e');
    }
  }

  /// Saves the downloaded bytes to the target directory.
  ///
  /// **Parameters:**
  /// - [bytes]: The downloaded file bytes
  /// - [downloadUrl]: Original download URL (for filename extraction)
  /// - [targetDirectory]: Directory to save the file
  ///
  /// **Returns:** The created file object
  ///
  /// **Throws:**
  /// - [FileSystemException] if file operations fail
  Future<File> _saveDownloadedFile(
      List<int> bytes, String downloadUrl, String targetDirectory) async {
    try {
      final targetDir = Directory(targetDirectory);
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
        printMessage('\n📁 Created directory: $targetDirectory');
      }

      final fileName = basename(downloadUrl);
      final targetFile = File(join(targetDirectory, fileName));

      await targetFile.writeAsBytes(bytes);
      printMessage('\n💾 Saved file: ${targetFile.path}');

      return targetFile;
    } catch (e) {
      throw Exception('Failed to save downloaded file to $targetDirectory: $e');
    }
  }

  /// Extracts a compressed file to the specified directory.
  ///
  /// **Parameters:**
  /// - [compressedFile]: The compressed file to extract
  /// - [targetDirectory]: Directory to extract files to
  ///
  /// **Throws:**
  /// - [FileSystemException] if extraction fails
  Future<void> _extractCompressedFile(
      File compressedFile, String targetDirectory) async {
    try {
      printMessage('📂 Extracting compressed file...');
      await ArchiveHelper.extractFile(compressedFile, targetDirectory);
      printMessage('✓ Extraction completed successfully');
    } catch (e) {
      throw Exception(
          'Failed to extract compressed file ${compressedFile.path}: $e');
    }
  }

  /// Cleans up temporary files after extraction.
  ///
  /// **Parameters:**
  /// - [compressedFile]: The compressed file to remove
  ///
  /// **Throws:**
  /// - [FileSystemException] if cleanup fails
  Future<void> _cleanupCompressedFile(File compressedFile) async {
    try {
      printMessage('🧹 Cleaning up temporary files...');

      // Remove the compressed file
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }

      // Remove macOS metadata directory if present
      final parentDir = compressedFile.parent.path;
      final macosxDir = Directory(join(parentDir, '__MACOSX'));
      if (await macosxDir.exists()) {
        await macosxDir.delete(recursive: true);
      }

      printMessage('✓ Cleanup completed');
    } catch (e) {
      // Log warning but don't fail the entire operation
      printMessage('⚠️  Warning: Cleanup partially failed: $e');
    }
  }
}
