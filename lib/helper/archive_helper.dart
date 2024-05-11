import 'dart:io';

import 'package:archive/archive.dart';

class ArchiveHelper {
  static Future<void> extractFile(File file, String destinationPath) async {
    var bytes = await file.readAsBytes();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var filename = file.name;
      if (file.isFile) {
        var data = file.content as List<int>;
        File('$destinationPath/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('$destinationPath/$filename').create(recursive: true);
      }
    }
  }
}
