import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class TestCommand extends Command {
  TestCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'apps',
      abbr: 'a',
      help: 'Test with spesific apps (Optional)',
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Test with spesific feature (optional)',
    );
    argParser.addOption(
      'page',
      abbr: 'p',
      help: 'Test with spesific page (optional)',
    );
    argParser.addFlag(
      'coverage',
      abbr: 'c',
      help: 'Run test with coverage',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'test';

  @override
  String get description =>
      'Run Flutter unit tests for the current project & all modules.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final String? apps = argResults?['apps']?.toString().snakeCase;
    final String? feature = argResults?['feature']?.toString().snakeCase;
    final String? page = argResults?['page']?.toString().snakeCase;

    final pathApps = join(current, 'apps', '${apps}_test');
    final pathFeature = apps?.isEmpty ?? true
        ? join(current, 'features', '$feature', 'test')
        : join(pathApps, 'features', '$feature', 'test');
    final pathPage = join(pathFeature, '${page}_test');

    final bool? isCoverage = argResults?['coverage'] as bool?;
    final argCoverage = isCoverage ?? false ? '--coverage' : '';

    if (apps == null && feature == null && page == null) {
      await ModularHelper.runSequence(
        (path) {
          final pathFeature = join(path, 'test');

          DirectoryHelper.createDir(pathFeature);

          final pages = find(
            '*_test',
            workingDirectory: pathFeature,
            recursive: false,
            types: [Find.directory],
          ).toList();

          for (var i = 0; i < pages.length; i++) {
            final pathPage = join(pathFeature, pages[i]);
            deleteAllBundleTest(pathPage);
            createBundleTest(pathPage);
          }

          creatFeatureBundleTest(pathFeature);
        },
        ignorePubWorkspaces: true,
      );
    } else if (page != null) {
      if (feature == null) {
        StatusHelper.failed('Feature is required');
      } else if (!exists(pathFeature)) {
        StatusHelper.failed('Feature not found');
      } else if (!exists(pathPage)) {
        StatusHelper.failed('Page not found');
      }

      DirectoryHelper.createDir(pathFeature);

      deleteAllBundleTest(pathPage);
      createBundleTest(pathPage);

      creatFeatureBundleTest(pathFeature);
    } else if (feature != null) {
      if (!exists(pathFeature)) {
        StatusHelper.failed('Feature not found');
      }

      DirectoryHelper.createDir(pathFeature);

      final pages = find(
        '*_test',
        workingDirectory: pathFeature,
        recursive: false,
        types: [Find.directory],
      ).toList();

      for (var i = 0; i < pages.length; i++) {
        final pathPage = join(pathFeature, pages[i]);
        deleteAllBundleTest(pathPage);
        createBundleTest(pathPage);
      }

      creatFeatureBundleTest(pathFeature);
    } else if (apps != null) {
      StatusHelper.failed('This feature is not yet available');
    }

    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    String workingDirCoverage = current;

    if (page != null) {
      workingDirCoverage = join(current, 'features', feature);
      await FlutterHelper.start(
        'test test/${page}_test/bundle_test.dart --no-pub $argCoverage',
        workingDirectory: workingDirCoverage,
      );
    } else if (feature != null) {
      workingDirCoverage = join(current, 'features', feature);
      await FlutterHelper.start(
        'test test/bundle_test.dart --no-pub $argCoverage',
        workingDirectory: join(current, 'features', feature),
      );
    } else {
      await ModularHelper.test(
        concurrent: yaml.concurrent,
        isCoverage: isCoverage ?? false,
      );
    }

    if (isCoverage ?? false) {
      combineLcovToRoot(
        workingDirectory: workingDirCoverage,
        isDeleteRootCoverageFirst: feature != null,
      );
    }

    StatusHelper.success('morpheme test');
  }

  void deleteAllBundleTest(String? dir) {
    final files = find(
      'bundle_test.dart',
      workingDirectory: dir ?? current,
      recursive: true,
      types: [Find.file],
    ).toList();

    for (var i = 0; i < files.length; i++) {
      delete(files[i]);
    }
  }

  void createBundleTest(String dir) {
    final files = find(
      '*_test.dart',
      workingDirectory: dir,
      recursive: true,
      types: [Find.file],
    ).toList().map((e) => e.replaceAll('$dir/', '')).toList();

    final imports = <String>[];
    final mains = <String>[];

    for (var i = 0; i < files.length; i++) {
      imports.add("import '${files[i]}' as test$i;");
      mains.add("test$i.main();");
    }

    join(dir, 'bundle_test.dart').write(
        '''import 'package:dev_dependency_manager/dev_dependency_manager.dart';
${imports.join('\n')}

Future<void> main() async {
  test('generated helper test', () {
    expect(1, 1);
  });
  ${mains.join('\n  ')}
}
''');
  }

  void creatFeatureBundleTest(String dir) {
    final files = find(
      'bundle_test.dart',
      workingDirectory: dir,
      recursive: true,
      types: [Find.file],
    )
        .toList()
        .map((e) => e
            .replaceAll('$dir/', '')
            .replaceAll('$current/${dir.replaceAll('./', '')}/', ''))
        .toList();

    files.remove('bundle_test.dart');

    final imports = <String>[];
    final mains = <String>[];

    for (var i = 0; i < files.length; i++) {
      imports.add("import '${files[i]}' as test$i;");
      mains.add("test$i.main();");
    }

    join(dir, 'bundle_test.dart').write(
        '''import 'package:dev_dependency_manager/dev_dependency_manager.dart';
${imports.join('\n')}

Future<void> main() async {
  test('generated helper test', () {
    expect(1, 1);
  });
  ${mains.join('\n  ')}
}
''');
  }

  void combineLcovToRoot({
    required String workingDirectory,
    bool isDeleteRootCoverageFirst = false,
  }) {
    final pathLcovRoot = join(current, 'coverage', 'lcov.info');
    if (!exists(pathLcovRoot)) {
      touch(pathLcovRoot, create: true);
    } else if (isDeleteRootCoverageFirst) {
      delete(pathLcovRoot);
      touch(pathLcovRoot, create: true);
    }

    final pathLcov = find(
      'lcov.info',
      recursive: true,
      types: [Find.file],
      workingDirectory: workingDirectory,
    ).toList();

    pathLcov.remove(pathLcovRoot);

    for (var path in pathLcov) {
      final pathReplace = path
          .replaceAll('$current/', '')
          .replaceAll(RegExp(r'(\/)?coverage\/lcov.info(\/)?'), '');

      replace(path, RegExp(r'SF:lib\/'), 'SF:$pathReplace/lib/');

      pathLcovRoot.append(readFile(path));
    }
  }
}
