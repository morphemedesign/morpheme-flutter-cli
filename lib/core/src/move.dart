import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart' as p;

import 'copy.dart';
import 'copy_tree.dart';
import 'delete.dart';
import 'is.dart';
import 'truepath.dart';

void move(String from, String to, {bool overwrite = false}) {
  var dest = to;

  if (isDirectory(to)) {
    dest = p.join(to, p.basename(from));
  }

  if (!overwrite && exists(dest)) {
    StatusHelper.failed('The [to] path ${truepath(dest)} already exists.');
  }
  try {
    File(from).renameSync(dest);
  } on FileSystemException catch (_) {
    /// Invalid cross-device link
    /// We can't move files across a partition so
    /// do a copy/delete.
    copy(from, to, overwrite: overwrite);
    delete(from);
  }

  /// ignore: avoid_catches_without_on_clauses
  catch (e) {
    StatusHelper.failed('error: $e');
  }
}

Future<void> moveDir(String from, String to) async {
  if (!exists(from)) {
    StatusHelper.failed('The [from] path ${truepath(from)} does not exists.');
  }
  if (!isDirectory(from)) {
    StatusHelper.failed(
        'The [from] path ${truepath(from)} must be a directory.');
  }
  if (exists(to)) {
    StatusHelper.failed('The [to] path ${truepath(to)} must NOT exist.');
  }

  try {
    Directory(from).renameSync(to);
  } on FileSystemException catch (_) {
    copyTree(from, to, includeHidden: true);
    delete(from);
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    StatusHelper.failed(
        'The Move of ${truepath(from)} to ${truepath(to)} failed. Error $e');
  }
}
