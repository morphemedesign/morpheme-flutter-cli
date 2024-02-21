import 'dart:io';

import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import 'is.dart';
import 'truepath.dart';

String resolveSymLink(String pathToLink) {
  final normalised = canonicalize(pathToLink);

  String resolved;
  if (isDirectory(normalised)) {
    resolved = Directory(normalised).resolveSymbolicLinksSync();
  } else {
    resolved = canonicalize(File(normalised).resolveSymbolicLinksSync());
  }

  return resolved;
}

void copy(String from, String to, {bool overwrite = false}) {
  var finalto = to;
  if (isDirectory(finalto)) {
    finalto = join(finalto, basename(from));
  }

  if (overwrite == false && exists(finalto, followLinks: false)) {
    StatusHelper.failed('The target file ${truepath(finalto)} already exists.');
  }

  try {
    /// if we are copying a symlink then we copy the file rather than
    /// the symlink as this mimicks gnu 'cp'.
    if (isLink(from)) {
      final resolvedFrom = resolveSymLink(from);
      File(resolvedFrom).copySync(finalto);
    } else {
      File(from).copySync(finalto);
    }
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    /// lets try and improve the message.
    /// We do these checks only on failure
    /// so in the most common case (everything is correct)
    /// we don't waste cycles on unnecessary work.
    if (isDirectory(from)) {
      StatusHelper.failed(
          "The 'from' argument ${truepath(from)} is a directory.");
    }
    if (!exists(from)) {
      StatusHelper.failed("The 'from' file ${truepath(from)} does not exists.");
    }
    if (!exists(dirname(to))) {
      StatusHelper.failed(
        "The 'to' directory ${truepath(dirname(to))} does not exists.",
      );
    }

    StatusHelper.failed(
        'An error occured copying ${truepath(from)} to ${truepath(finalto)}.');
  }
}
