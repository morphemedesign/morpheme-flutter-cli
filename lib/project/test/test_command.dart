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
    argParser.addOption(
      'reporter',
      abbr: 'r',
      help:
          '''Set how to print test results. If unset, value will default to either compact or expanded.

          [compact]                                          A single line, updated continuously (the default).
          [expanded]                                         A separate line for each update. May be preferred when logging to a file or in continuous integration.
          [failures-only]                                    A separate line for failing tests, with no output for passing tests.
          [github]                                           A custom reporter for GitHub Actions (the default reporter when running on GitHub Actions).
          [json]                                             A machine-readable format. See: https://dart.dev/go/test-docs/json_reporter.md
          [silent]                                           A reporter with no output. May be useful when only the exit code is meaningful.''',
      allowed: [
        'compact',
        'expanded',
        'failures-only',
        'github',
        'json',
        'silent',
      ],
    );
    argParser.addOption(
      'file-reporter',
      help: '''Enable an additional reporter writing test results to a file.
                                                             Should be in the form <reporter>:<filepath>, Example: "json:reports/tests.json".''',
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

    final String? reporter = argResults?['reporter'];
    final argReporter = reporter != null ? '--reporter $reporter' : '';

    final String? fileReporter = argResults?['file-reporter'];
    final argFileReporter =
        fileReporter != null ? '--file-reporter $fileReporter' : '';

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
        'test test/${page}_test/bundle_test.dart --no-pub $argCoverage $argReporter $argFileReporter',
        workingDirectory: workingDirCoverage,
      );
    } else if (feature != null) {
      workingDirCoverage = join(current, 'features', feature);
      await FlutterHelper.start(
        'test test/bundle_test.dart --no-pub $argCoverage $argReporter $argFileReporter',
        workingDirectory: join(current, 'features', feature),
      );
    } else {
      await ModularHelper.test(
        concurrent: yaml.concurrent,
        isCoverage: isCoverage ?? false,
        reporter: reporter,
        fileReporter: fileReporter,
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
    final pathMergeLcovRoot = join(current, 'coverage', 'merge_lcov.info');
    if (!exists(pathMergeLcovRoot)) {
      touch(pathMergeLcovRoot, create: true);
    } else if (isDeleteRootCoverageFirst) {
      delete(pathMergeLcovRoot);
      touch(pathMergeLcovRoot, create: true);
    }

    final pathLcov = find(
      'lcov.info',
      recursive: true,
      types: [Find.file],
      workingDirectory: workingDirectory,
    ).toList();

    for (var path in pathLcov) {
      final splitPathLcov = path.split(separator);
      final newFileName = 'merge_${splitPathLcov.removeLast()}';
      final newPathFileLcov = '${splitPathLcov.join(separator)}/$newFileName';
      copy(path, newPathFileLcov, overwrite: true);
      final pathReplace = newPathFileLcov
          .replaceAll('$current/', '')
          .replaceAll(RegExp(r'(\/)?coverage\/merge_lcov.info(\/)?'), '')
          .replaceAll(RegExp(r'(\/)?coverage\/lcov.info(\/)?'), '');

      replace(newPathFileLcov, RegExp(r'SF:lib\/'), 'SF:$pathReplace/lib/');

      pathMergeLcovRoot.append(readFile(newPathFileLcov));
    }
  }
}
