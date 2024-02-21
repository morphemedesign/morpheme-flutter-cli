import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';

import 'is.dart';
import 'truepath.dart';

String createDir(String path, {required bool recursive}) {
  try {
    if (exists(path)) {
      StatusHelper.failed('The path ${truepath(path)} already exists');
    }

    Directory(path).createSync(recursive: recursive);
  } catch (e) {
    StatusHelper.failed(
        'Unable to create the directory ${truepath(path)}. Error: $e');
  }
  return path;
}
