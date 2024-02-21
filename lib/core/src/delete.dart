import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';

import 'is.dart';
import 'truepath.dart';

void delete(String path) {
  if (!exists(path)) {
    StatusHelper.failed('The path ${truepath(path)} does not exists.');
  }

  if (isDirectory(path)) {
    StatusHelper.failed('The path ${truepath(path)} is a directory.');
  }

  try {
    File(path).deleteSync();
  } catch (e) {
    StatusHelper.failed(
        'An error occured deleting ${truepath(path)}. Error: $e');
  }
}

void deleteDir(String path, {bool recursive = true}) {
  if (!exists(path)) {
    StatusHelper.failed('The path ${truepath(path)} does not exists.');
  }

  if (!isDirectory(path)) {
    StatusHelper.failed('The path ${truepath(path)} is not a directory.');
  }

  try {
    Directory(path).deleteSync(recursive: recursive);
  } catch (e) {
    StatusHelper.failed(
        'Unable to delete the directory ${truepath(path)}. Error: $e');
  }
}
