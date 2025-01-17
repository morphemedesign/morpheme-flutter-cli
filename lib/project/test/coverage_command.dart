import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class CoverageCommand extends Command {
  CoverageCommand() {
    argParser.addOptionMorphemeYaml();
  }

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Run Flutter test coverage for the current project & all modules.';

  @override
  String get category => Constants.project;

  final pathCoverageHelper = 'test/coverage_helper_test.dart';

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    if (!morphemeYaml.containsKey('coverage')) {
      StatusHelper.failed('morpheme.yaml not contain coverage config!');
    }

    final list = find('pubspec.yaml').toList();

    for (var pathPubspec in list) {
      final path = pathPubspec.replaceAll('/pubspec.yaml', '');
      final packageName = getYaml(pathPubspec)['name'];
      await createCoverageHelperTest(path, packageName);
    }

    try {
      await ModularHelper.coverage(concurrent: morphemeYaml.concurrent);

      final pathCoverageLcov = 'coverage/lcov.info';
      if (!exists(pathCoverageLcov)) {
        touch(pathCoverageLcov, create: true);
      }

      for (var pathPubspec in list) {
        final path = pathPubspec.replaceAll('/pubspec.yaml', '');
        try {
          delete('$path/$pathCoverageHelper');
        } catch (e) {
          StatusHelper.warning('$path/$pathCoverageHelper not exists!');
        }

        final pathReplace = path.replaceAll('$current/', '');
        if (path != current) {
          replace('$path/$pathCoverageLcov', 'SF:lib/', 'SF:$pathReplace/lib/');
        }

        read('$path/$pathCoverageLcov').forEach((line) {
          pathCoverageLcov.append(line);
        });
      }

      if (Platform.isWindows) {
        printMessage(
            'you must install perl and lcov then lcov remove file will be ignore to coverage manually & generate report to html manually.');
      }

      if (which('lcov').notfound) {
        StatusHelper.failed(
            'lcov not found, failed to remove ignore file to test.');
      }

      final lcovDir = morphemeYaml['coverage']['lcov_dir']
          ?.toString()
          .replaceAll('/', separator);
      final outputHtmlDir = morphemeYaml['coverage']['output_html_dir']
          ?.toString()
          .replaceAll('/', separator);
      final removeFile = (morphemeYaml['coverage']['remove'] as List).join(' ');

      printMessage(
          "lcov --remove $lcovDir $removeFile -o $lcovDir --ignore-errors unused");

      await "lcov --remove $lcovDir $removeFile -o $lcovDir --ignore-errors unused"
          .run;

      if (which('genhtml').notfound) {
        StatusHelper.failed('failed cannot generate report lcov html.');
      }
      await 'genhtml $lcovDir -o $outputHtmlDir'.run;

      StatusHelper.success();
    } catch (e) {
      for (var pathPubspec in list) {
        final path = pathPubspec.replaceAll('/pubspec.yaml', '');
        try {
          delete('$path/$pathCoverageHelper');
        } catch (e) {
          StatusHelper.warning('$path/$pathCoverageHelper not exists!');
        }
        try {
          deleteDir('$path/coverage');
        } catch (e) {
          StatusHelper.warning('$path/coverage not exists!');
        }
      }
    }
  }

  Map<dynamic, dynamic> getYaml(String path) {
    final File file = File(path);
    final String yamlString = file.readAsStringSync();
    return loadYaml(yamlString);
  }

  Future<void> createCoverageHelperTest(String path, String packageName) async {
    final cwd = Directory(path).uri;
    final libDir = Directory.fromUri(cwd.resolve('lib'));
    final testDir = Directory.fromUri(cwd.resolve('test'));
    final buffer = StringBuffer();

    DirectoryHelper.createDir(testDir.path);

    var files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.dart') &&
            !file.path.contains('.freezed.') &&
            !file.path.contains('.g.') &&
            !file.path.endsWith('generated_plugin_registrant.dart') &&
            !file.readAsLinesSync().any((line) => line.startsWith('part of')))
        .toList();

    buffer.writeln('// GENERATED MORPHEME COVERAGE HELPER TEST');
    buffer.writeln();
    buffer.writeln('// ignore_for_file: unused_import');
    buffer.writeln(
        "import 'package:dev_dependency_manager/dev_dependency_manager.dart';");

    for (var file in files) {
      final fileLibPath =
          file.uri.toFilePath().substring(libDir.uri.toFilePath().length);
      buffer.writeln('import \'package:$packageName/$fileLibPath\';');
    }

    buffer.writeln();
    buffer.writeln('''void main() {
  test('generated helper test', () {
    expect(1, 1);
  });
    }''');
    buffer.writeln();

    final output = File(cwd.resolve(pathCoverageHelper).toFilePath());
    await output.writeAsString(buffer.toString());
  }
}
