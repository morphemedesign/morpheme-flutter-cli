import 'package:collection/collection.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/helper/helper.dart';

abstract class RefactorHelper {
  static void renameFileAndClassName({
    required String pathDir,
    required String oldName,
    required String newName,
    List<String> exceptChanges = const [],
    List<String> exceptFiles = const [],
    List<String> exceptDirs = const [],
  }) {
    final findAll = find(
      '*.dart',
      workingDirectory: pathDir,
    ).toList();

    findAll.removeWhere((element) =>
        exceptDirs.firstWhereOrNull((except) => element
            .replaceAll(current, '')
            .replaceAll(RegExp(r'^/'), '')
            .contains(except
                .replaceAll(current, '')
                .replaceAll(RegExp(r'^/'), ''))) !=
        null);
    findAll.removeWhere((element) =>
        exceptFiles.firstWhereOrNull((except) => element
            .replaceAll(current, '')
            .replaceAll(RegExp(r'^/'), '')
            .contains(except
                .replaceAll(current, '')
                .replaceAll(RegExp(r'^/'), ''))) !=
        null);

    for (var oldPath in findAll) {
      replace(
        oldPath,
        RegExp(exceptChanges.map((e) => '(?!$e)').join() + oldName.pascalCase),
        newName.pascalCase,
        all: true,
      );
      replace(
        oldPath,
        RegExp(exceptChanges.map((e) => '(?!$e)').join() + oldName.camelCase),
        newName.camelCase,
        all: true,
      );
      replace(
        oldPath,
        RegExp(exceptChanges.map((e) => '(?!$e)').join() + oldName.snakeCase),
        newName.snakeCase,
        all: true,
      );

      String newPath = oldPath.replaceAll(current + separator, '');
      newPath = newPath.replaceAll(oldName.camelCase, newName.camelCase);
      newPath = join(current, newPath);
      if (oldPath != newPath) {
        final dir = newPath.split(separator);
        dir.removeLast();
        if (!exists(dir.join(separator))) {
          DirectoryHelper.createDir(dir.join(separator));
        }
        move(oldPath, newPath, overwrite: true);
        StatusHelper.refactor('$oldPath to $newPath');
      }
    }

    final findAllDir = find(
      '*',
      workingDirectory: pathDir,
      types: [Find.directory],
    ).toList();

    findAllDir.removeWhere((element) =>
        exceptDirs.firstWhereOrNull((except) => element
            .replaceAll(current, '')
            .replaceAll(RegExp(r'^/'), '')
            .contains(except
                .replaceAll(current, '')
                .replaceAll(RegExp(r'^/'), ''))) !=
        null);

    for (var dir in findAllDir) {
      final partDir = <String>[];
      final splitDir = dir.replaceAll(current + separator, '').split(separator);
      for (var element in splitDir) {
        partDir.add(element);
        if (element.contains(oldName.snakeCase)) {
          final pathDir = partDir.join(separator);
          if (exists(pathDir) && isDirectory(pathDir)) {
            deleteDir(join(current, pathDir), recursive: true);
          }
          break;
        }
      }
    }
  }
}
