import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

import 'is.dart';
import 'truepath.dart';

String touch(String path, {bool create = false}) {
  final absolutePath = truepath(path);

  if (!exists(p.dirname(absolutePath))) {
    StatusHelper.failed(
        'The directory tree above $absolutePath does not exist.');
  }
  if (create == false && !exists(absolutePath)) {
    StatusHelper.failed('The file $absolutePath does not exist.');
  }

  try {
    final file = File(absolutePath);

    if (file.existsSync()) {
      final now = DateTime.now();
      file
        ..setLastAccessedSync(now)
        ..setLastModifiedSync(now);
    } else {
      if (create) {
        file.createSync();
      }
    }
  } on FileSystemException catch (e) {
    StatusHelper.failed('Unable to touch file $absolutePath: ${e.message}');
  }
  return path;
}
