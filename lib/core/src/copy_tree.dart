import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import 'copy.dart';
import 'create.dart';
import 'find.dart';
import 'is.dart';
import 'truepath.dart';

bool _allowAll(String file) => true;

void copyTree(
  String from,
  String to, {
  bool overwrite = false,
  bool Function(String file) filter = _allowAll,
  bool includeHidden = false,
  bool recursive = true,
}) {
  if (!isDirectory(from)) {
    StatusHelper.failed(
        'The [from] path ${truepath(from)} must be a directory.');
  }
  if (!exists(to)) {
    StatusHelper.failed('The [to] path ${truepath(to)} must already exist.');
  }

  if (!isDirectory(to)) {
    StatusHelper.failed('The [to] path ${truepath(to)} must be a directory.');
  }

  try {
    final items = find(
      '*',
      workingDirectory: from,
      includeHidden: includeHidden,
      recursive: recursive,
    );

    items.forEach((item) {
      _process(
        item,
        filter,
        from,
        to,
        overwrite: overwrite,
        recursive: recursive,
      );
    });
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    StatusHelper.failed(
        'An error occured copying directory  ${truepath(from)} to ${truepath(to)}. Error: $e');
  }
}

void _process(
    String file, bool Function(String file) filter, String from, String to,
    {required bool overwrite, required bool recursive}) {
  if (filter(file)) {
    final target = join(to, relative(file, from: from));

    if (recursive && !exists(dirname(target))) {
      createDir(dirname(target), recursive: true);
    }

    if (!overwrite && exists(target)) {
      StatusHelper.failed(
          'The target file ${truepath(target)} already exists.');
    }

    copy(file, target, overwrite: overwrite);
  }
}
