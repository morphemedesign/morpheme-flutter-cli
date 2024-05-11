import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class DownloadCommand extends Command {
  DownloadCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'download';

  @override
  String get description => 'Download all needed where set in morpheme.yaml.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    final Map? download = yaml['download'];
    if (download == null) {
      StatusHelper.failed('morpheme.yaml not contain download');
      return;
    }

    download.forEach((key, value) async {
      if (value is! Map) {
        print(
            'Configuration error for $key: expected a map with "url" and "path".');
        StatusHelper.failed(
            'Configuration error for $key: expected a map with "url" and "path".');
        return;
      }

      final String? url = value['url'];
      final String? path = value['dir'];
      final bool isCompressed = value['compressed'] ?? false;

      if (url == null || path == null) {
        print('Invalid configuration for $key. URL and path must be provided.');
        StatusHelper.failed(
            'Invalid configuration for $key. URL and path must be provided.');
        return;
      }

      try {
        print('Downloading from $url to $path...');
        final bytes = await HttpClientHelper.downloadFile(
          url,
          onProgress: (downloadedLength, contentLength, progress) {
            stdout.write(
              "\rDownload progress: $downloadedLength / $contentLength .................. ${progress.toStringAsFixed(2)}%",
            );
          },
        );
        Directory directory = Directory(path);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        File file = File(join(path, basename(url)));
        await file.writeAsBytes(bytes);
        print('Download completed.');

        if (isCompressed) {
          print('Extracting the compressed file...');
          await ArchiveHelper.extractFile(file, path);
          print('Extraction completed.');
          print('Removing compressed file');
          if (await file.exists()) {
            await file.delete();
          }
          final macosxDir = Directory(join(path, '__MACOSX'));
          if (await macosxDir.exists()) {
            await macosxDir.delete(recursive: true);
          }
          print('Removal completed.');
        }
      } catch (e) {
        print('Failed to download or extract file: $e');
        StatusHelper.failed('Failed to download or extract file: $e');
      }
    });
  }
}
