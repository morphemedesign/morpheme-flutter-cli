import 'package:morpheme_cli/core/src/move.dart';
import 'package:morpheme_cli/core/src/string_extension.dart';

import 'delete.dart';
import 'is.dart';
import 'read.dart';
import 'touch.dart';

int replace(
  String path,
  Pattern existing,
  String replacement, {
  bool all = false,
}) {
  var changes = 0;
  final tmp = '$path.tmp';
  if (exists(tmp)) {
    delete(tmp);
  }
  touch(tmp, create: true);
  read(path).forEach((line) {
    String newline;
    if (all) {
      newline = line.replaceAll(existing, replacement);
    } else {
      newline = line.replaceFirst(existing, replacement);
    }
    if (newline != line) {
      changes++;
    }

    tmp.append(newline);
  });
  if (changes != 0) {
    move(path, '$path.bak');
    move(tmp, path);
    delete('$path.bak');
  } else {
    delete(tmp);
  }
  return changes;
}
