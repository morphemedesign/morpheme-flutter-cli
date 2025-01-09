import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

extension AssetsExtension on Map {
  String get pubspecDir =>
      this['pubspec_dir']?.toString().replaceAll('/', separator) ?? 'assets';
  String get outputDir =>
      this['output_dir']?.toString().replaceAll('/', separator) ?? 'assets/lib';
  bool get createLibraryFile => this['create_library_file'] ?? true;
  String get assetsDir =>
      this['assets_dir']?.toString().replaceAll('/', separator) ??
      'assets/assets';
  String get flavorDir =>
      this['flavor_dir']?.toString().replaceAll('/', separator) ??
      'assets/flavor';
}

class AssetCommand extends Command {
  AssetCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOptionFlavor(defaultsTo: '');
  }

  @override
  String get name => 'assets';

  @override
  String get description => 'Generate assets from setup assets pubspec.yaml.';

  @override
  String get category => Constants.generate;

  String projectName = '';

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argFlavor = argResults.getOptionFlavor(defaultTo: '');

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    if (morphemeYaml['assets'] == null) {
      StatusHelper.failed('assets not found in $argMorphemeYaml');
    }

    projectName = morphemeYaml.projectName;
    final morphemeAssets = morphemeYaml['assets'] as Map;

    if (argFlavor.isNotEmpty && exists(morphemeAssets.flavorDir)) {
      final pathFlavorDir = join(current, morphemeAssets.flavorDir, argFlavor);
      final pathAssetsDir = join(current, morphemeAssets.assetsDir);

      copyTree(pathFlavorDir, pathAssetsDir, overwrite: true);
    }

    final pathYaml = join(current, morphemeAssets.pubspecDir, 'pubspec.yaml');

    if (!exists(pathYaml)) {
      StatusHelper.failed('$pathYaml not found!');
    }

    final yaml = YamlHelper.loadFileYaml(pathYaml);
    if (!yaml.containsKey('flutter')) {
      StatusHelper.failed('flutter not found in pubspec.yaml');
    }

    final flutter = (yaml['flutter'] is Map) ? yaml['flutter'] as Map : null;
    if (flutter == null || !flutter.containsKey('assets')) {
      StatusHelper.failed('assets not found in pubspec.yaml');
    }

    final pubspecAssets = (yaml['flutter']['assets'] as List)
        .where((element) =>
            !RegExp(r'(0|[1-9]\d*)\.?(0|[1-9]\d*)?\.?(0|[1-9]\d*)?x')
                .hasMatch(element))
        .toList();

    DirectoryHelper.createDir(join(morphemeAssets.outputDir, 'src'));

    createFileAssets(pubspecAssets, morphemeAssets);
    if (morphemeAssets.createLibraryFile) createFileExport(morphemeAssets);

    await ModularHelper.format([morphemeAssets.outputDir]);

    StatusHelper.success('morpheme assets');
  }

  void createFileAssets(List<dynamic> pubspecAssets, Map morphemeAssets) {
    final outputDir = join(current, morphemeAssets.outputDir);

    for (var element in pubspecAssets) {
      final nameDir = element
          .toString()
          .split('/')
          .lastWhere((element) => element.isNotEmpty);
      if (RegExp(r'^\w+\.\w*').hasMatch(nameDir)) {
        continue;
      }

      final findOld = find(
        '*_${nameDir.snakeCase}.dart',
        workingDirectory: join(outputDir, 'src'),
      ).toList();

      for (var item in findOld) {
        delete(item);
      }

      final pathOutput = join(outputDir, 'src',
          '${projectName.snakeCase}_${nameDir.snakeCase}.dart');

      final assetsDir = '${morphemeAssets.pubspecDir}/$element'
          .replaceAll(RegExp(r'\/$'), '');

      pathOutput.write(
          '''abstract class ${projectName.pascalCase}${nameDir.pascalCase} {
  // ignore: unused_field
  static const String _assets = 'packages/${assetsDir.replaceAll(RegExp(r'\.'), current.split(separator).last)}';
''');

      final items = find(
        '[a-z]*.*',
        workingDirectory: join(current, assetsDir),
        recursive: false,
      ).toList();

      for (var item in items) {
        final nameWithExtension = item.split('/').last;
        pathOutput.append(
            '''  static const String ${nameWithExtension.split('.').first.camelCase} = '\$_assets/$nameWithExtension';''');
      }

      pathOutput.append('}');

      StatusHelper.generated(pathOutput);
    }
  }

  void createFileExport(Map morphemeAssets) {
    final items = find(
      '[a-z]*.*',
      workingDirectory: join(current, morphemeAssets.outputDir, 'src'),
      recursive: false,
    ).toList();

    final pathOutput = join(current, morphemeAssets.outputDir, 'assets.dart');

    for (var item in items) {
      final nameWithExtension = item.split('/').last;
      pathOutput.append("export 'src/$nameWithExtension';");
    }

    StatusHelper.generated(pathOutput);
  }
}
