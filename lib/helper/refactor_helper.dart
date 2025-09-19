import 'package:collection/collection.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Helper class for refactoring operations.
///
/// This class provides utilities for renaming files and classes during
/// code generation and refactoring operations. It handles the complex
/// process of updating file names, class names, and references throughout
/// a Flutter project.
abstract class RefactorHelper {
  /// Renames files and updates class names throughout a directory.
  ///
  /// This method performs a comprehensive refactoring operation that:
  /// 1. Finds all Dart files in the specified directory
  /// 2. Updates class names and references in those files
  /// 3. Renames files to match the new naming convention
  /// 4. Cleans up old directory structures
  ///
  /// The refactoring process handles multiple naming conventions:
  /// - PascalCase for class names
  /// - camelCase for variable and function names
  /// - snake_case for file and directory names
  ///
  /// Parameters:
  /// - [pathDir]: The directory path to refactor
  /// - [oldName]: The original name to be replaced
  /// - [newName]: The new name to replace with
  /// - [exceptChanges]: List of patterns to exclude from changes
  /// - [exceptFiles]: List of files to exclude from processing
  /// - [exceptDirs]: List of directories to exclude from processing
  ///
  /// Example:
  /// ```dart
  /// // Rename a feature from 'user_profile' to 'user_account'
  /// RefactorHelper.renameFileAndClassName(
  ///   pathDir: './lib/features',
  ///   oldName: 'user_profile',
  ///   newName: 'user_account',
  ///   exceptChanges: ['UserProfile'], // Don't change this specific class
  ///   exceptFiles: ['./lib/features/user_profile/widgets/user_profile_widget.dart'],
  ///   exceptDirs: ['./lib/features/user_profile/models'],
  /// );
  /// ```
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
          createDir(dir.join(separator));
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
