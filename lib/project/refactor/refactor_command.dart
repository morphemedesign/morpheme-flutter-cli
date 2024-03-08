import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class RefactorCommand extends Command {
  RefactorCommand() {
    argParser.addOption(
      'old-name',
      abbr: 'o',
      help: 'Old name before refactor',
      defaultsTo: 'morpheme',
    );
    argParser.addOption(
      'new-name',
      abbr: 'n',
      help: 'New name before refactor',
      mandatory: true,
    );
    argParser.addOption(
      'exclude-changes',
      help: 'Code will exclude to refactor separate with , (coma)',
    );
    argParser.addOption(
      'exclude-files',
      help:
          'Spesific path file will exclude to refactor both code and filename separate with , (coma)',
    );
    argParser.addOption(
      'exclude-directories',
      help:
          'Spesific path directory will exclude to refactor including files and codes in it separate with , (coma)',
    );
    argParser.addFlag(
      'include-library',
      defaultsTo: false,
    );
  }
  @override
  String get name => 'refactor';

  @override
  String get description => 'Refactor naming old to new naming';

  @override
  String get category => Constants.project;

  String oldName = '';
  String newName = '';
  bool includeLibrary = false;

  @override
  void run() async {
    oldName = argResults?['old-name'] ?? '';
    newName = argResults?['new-name'] ?? '';

    if (oldName == newName) return;

    includeLibrary = argResults?['include-library'] ?? false;

    addOrUpdateProjectNameMorphemeYaml();
    refactorProjectNamePubspec();
    await refactorProject();

    if (includeLibrary) await refactorLibrary();

    if (exists(join(current, 'morpheme_library_temp'))) {
      deleteDir(join(current, 'morpheme_library_temp'));
    }

    await 'morpheme get'.run;

    StatusHelper.success('morpheme refactor');
  }

  void addOrUpdateProjectNameMorphemeYaml() {
    final pathMorphemeYaml = join(current, 'morpheme.yaml');
    if (exists(pathMorphemeYaml)) {
      final yaml = Map.from(YamlHelper.loadFileYaml(pathMorphemeYaml));
      yaml['project_name'] = newName;
      YamlHelper.saveFileYaml(join(current, 'morpheme.yaml'), yaml);
    }
  }

  void refactorProjectNamePubspec() {
    final pubspec =
        Map.from(YamlHelper.loadFileYaml(join(current, 'pubspec.yaml')));
    final String oldNamePubspec = pubspec['name'];
    pubspec['name'] = newName.snakeCase;
    YamlHelper.saveFileYaml(join(current, 'pubspec.yaml'), pubspec);

    RefactorHelper.renameFileAndClassName(
      pathDir: join(current, 'lib'),
      oldName: oldNamePubspec,
      newName: newName.snakeCase,
    );
  }

  Future<void> refactorProject() async {
    final excludeChanges =
        argResults?['exclude-changes']?.toString().isNotEmpty ?? false
            ? (argResults?['exclude-changes']?.toString() ?? '').split(',')
            : [];
    final excludeFiles =
        argResults?['exclude-files']?.toString().isNotEmpty ?? false
            ? (argResults?['exclude-files']?.toString() ?? '').split(',')
            : [];
    final excludeDirectories =
        argResults?['exclude-directories']?.toString().isNotEmpty ?? false
            ? (argResults?['exclude-directories']?.toString() ?? '').split(',')
            : [];

    final exceptChanges = <String>[
      if (!includeLibrary) ...[
        '${oldName.snakeCase}_library',
        '${oldName.snakeCase}_base',
        '${oldName.snakeCase}_http',
        '${oldName.snakeCase}_inspector',
        '${oldName.snakeCase}_extension',
        '${oldName.pascalCase}Cubit',
        '${oldName.pascalCase}Hydrated',
        '${oldName.pascalCase}StatePage',
        '${oldName.pascalCase}Http',
        '${oldName.pascalCase}Exception',
        '${oldName.pascalCase}Failure',
        '${oldName.pascalCase}HttpOverrides',
        '${oldName.pascalCase}Inspector',
        '${oldName.camelCase}Inspector',
      ],
      ...excludeChanges,
    ];

    final exceptFiles = <String>[
      ...excludeFiles,
    ];
    final exceptDirs = <String>[
      join(current, 'core', 'lib', 'src', 'l10n'),
      join(current, 'core', 'packages', '${oldName.snakeCase}_library'),
      join(current, 'android'),
      join(current, 'ios'),
      join(current, 'macos'),
      join(current, 'web'),
      join(current, 'linux'),
      ...excludeDirectories,
    ];

    RefactorHelper.renameFileAndClassName(
      pathDir: join(current),
      oldName: oldName,
      newName: newName,
      exceptChanges: exceptChanges,
      exceptFiles: exceptFiles,
      exceptDirs: exceptDirs,
    );

    await 'morpheme assets'.run;
  }

  Future<void> refactorLibrary() async {
    final pathTempLibrary = join(current, 'morpheme_library_temp');
    if (exists(pathTempLibrary)) {
      deleteDir(pathTempLibrary);
    }

    await 'git clone https://github.com/morphemedesign/morpheme-flutter-library.git morpheme_library_temp'
        .run;

    final pathOldLibrary =
        join(current, 'core', 'packages', '${oldName.snakeCase}_library');
    final pathNewLibrary =
        join(current, 'core', 'packages', '${newName.snakeCase}_library');

    if (exists(pathOldLibrary)) {
      DirectoryHelper.createDir(join(pathOldLibrary, 'packages'));
    }

    final pubspecLibrary = Map.from(YamlHelper.loadFileYaml(
      join(pathOldLibrary, 'pubspec.yaml'),
    ));

    final packagesLibrary = find(
      '*',
      workingDirectory: join(pathTempLibrary, 'packages'),
      recursive: false,
      types: [Find.directory],
    ).toList();

    final dependencies = pubspecLibrary['dependencies'];
    if (dependencies is! Map) return;
    dependencies.forEach((key, value) {
      final nameLibrary = key
          .toString()
          .replaceAll(RegExp('morpheme|${oldName.snakeCase}'), '');

      final isLibrary = packagesLibrary.firstWhereOrNull((element) {
            return nameLibrary ==
                element.replaceAll(
                    join(pathTempLibrary, 'packages', 'morpheme'), '');
          }) ==
          null;
      final findPackage = find(
        '*$nameLibrary',
        workingDirectory: join(pathOldLibrary, 'packages'),
        recursive: false,
        types: [Find.directory],
      ).toList();

      if (isLibrary || findPackage.isNotEmpty) return;

      if (exists(join(pathTempLibrary, 'packages', 'morpheme$nameLibrary'))) {
        moveDir(
          join(pathTempLibrary, 'packages', 'morpheme$nameLibrary'),
          join(pathOldLibrary, 'packages', 'morpheme$nameLibrary'),
        );
      }

      final pubspec = Map.from(YamlHelper.loadFileYaml(
        join(
            pathOldLibrary, 'packages', 'morpheme$nameLibrary', 'pubspec.yaml'),
      ));

      final dependencies = pubspec['dependencies'];
      if (dependencies is! Map) return;
      dependencies.forEach((key, value) {
        final nameLibrary = key
            .toString()
            .replaceAll(RegExp('morpheme|${oldName.snakeCase}'), '');

        final isLibrary = packagesLibrary.firstWhereOrNull((element) {
              return nameLibrary ==
                  element.replaceAll(
                      join(pathTempLibrary, 'packages', 'morpheme'), '');
            }) ==
            null;
        final findPackage = find(
          '*$nameLibrary',
          workingDirectory: join(pathOldLibrary, 'packages'),
          recursive: false,
          types: [Find.directory],
        ).toList();

        if (isLibrary || findPackage.isNotEmpty) return;

        if (exists(join(pathTempLibrary, 'packages', 'morpheme$nameLibrary'))) {
          moveDir(
            join(pathTempLibrary, 'packages', 'morpheme$nameLibrary'),
            join(pathOldLibrary, 'packages', 'morpheme$nameLibrary'),
          );
        }
      });
    });

    final oldLibrary = find(
      '*',
      workingDirectory: join(pathOldLibrary, 'packages'),
      recursive: false,
      types: [Find.directory],
    ).toList();

    for (var element in oldLibrary) {
      if (exists(join(pathOldLibrary, 'packages', element, 'example'))) {
        deleteDir(join(pathOldLibrary, 'packages', element, 'example'));
      }
      if (exists(join(pathOldLibrary, 'packages', element, 'CHANGELOG.md'))) {
        delete(join(pathOldLibrary, 'packages', element, 'CHANGELOG.md'));
      }
      if (exists(join(pathOldLibrary, 'packages', element, 'README.md'))) {
        delete(join(pathOldLibrary, 'packages', element, 'README.md'));
      }
      if (exists(join(pathOldLibrary, 'packages', element, 'AUTHORS'))) {
        delete(join(pathOldLibrary, 'packages', element, 'AUTHORS'));
      }

      final pubspec = Map.from(YamlHelper.loadFileYaml(
        join(pathOldLibrary, 'packages', element, 'pubspec.yaml'),
      ));

      pubspec['name'] = pubspec['name'].toString().replaceAll(
          RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);
      pubspec['description'] = pubspec['description'].toString().replaceAll(
          RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);
      pubspec['description'] = pubspec['description'].toString().replaceAll(
          RegExp('Morpheme|${oldName.pascalCase}'), newName.pascalCase);
      pubspec['publish_to'] = 'none';
      pubspec.remove('homepage');
      pubspec.remove('repository');

      List<String> keysToRemove = [];
      List<MapEntry> mapEntries = [];
      final dependency = Map.from(pubspec['dependencies']);
      dependency.forEach((key, value) {
        if (key.toString().contains(RegExp('morpheme|${oldName.snakeCase}'))) {
          final libraryName = key.toString().replaceAll(
              RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);
          keysToRemove.add(key);
          mapEntries.add(MapEntry(libraryName, {'path': '../$libraryName'}));
        }
      });
      dependency.removeWhere((key, value) => keysToRemove.contains(key));
      dependency.addEntries(mapEntries);
      pubspec['dependencies'] = dependency;

      YamlHelper.saveFileYaml(
        join(pathOldLibrary, 'packages', element, 'pubspec.yaml'),
        pubspec,
      );
    }

    final pubspec = Map.from(YamlHelper.loadFileYaml(
      join(pathOldLibrary, 'pubspec.yaml'),
    ));

    pubspec['name'] = pubspec['name']
        .toString()
        .replaceAll(RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);

    List<String> keysToRemove = [];
    List<MapEntry> mapEntries = [];
    final dependency = Map.from(pubspec['dependencies']);
    dependency.forEach((key, value) {
      if (key.toString().contains(RegExp('morpheme|${oldName.snakeCase}'))) {
        final libraryName = key.toString().replaceAll(
            RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);
        keysToRemove.add(key);
        mapEntries
            .add(MapEntry(libraryName, {'path': './packages/$libraryName'}));
      }
    });
    dependency.removeWhere((key, value) => keysToRemove.contains(key));
    dependency.addEntries(mapEntries);
    pubspec['dependencies'] = dependency;

    YamlHelper.saveFileYaml(
      join(pathOldLibrary, 'pubspec.yaml'),
      pubspec,
    );

    for (var element in oldLibrary) {
      final lastName = element.split(separator).last.replaceAll(
          RegExp('morpheme|${oldName.snakeCase}'), newName.snakeCase);
      if (exists(element)) {
        moveDir(element, join(pathOldLibrary, 'packages', lastName));
      }
    }

    if (exists(pathOldLibrary)) {
      moveDir(pathOldLibrary, pathNewLibrary);
    }

    RefactorHelper.renameFileAndClassName(
      pathDir: pathNewLibrary,
      oldName: oldName,
      newName: newName,
    );

    replace(
      join(current, 'core', 'pubspec.yaml'),
      RegExp('morpheme|${oldName.snakeCase}'),
      newName.snakeCase,
    );

    if (exists(pathTempLibrary)) {
      deleteDir(pathTempLibrary);
    }
  }
}
