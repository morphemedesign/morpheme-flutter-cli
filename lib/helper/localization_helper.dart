import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

class LocalizationHelper {
  LocalizationHelper(String pathMorphemeyaml) {
    final keyLocalization = 'localization';
    final keyArbDir = 'arb_dir';
    final keyTemplateArbFile = 'template_arb_file';
    final keyOutputLocalizationFile = 'output_localization_file';
    final keyOutputClass = 'output_class';
    final keyOutputDir = 'output_dir';
    final keyReplace = 'replace';

    final yaml = YamlHelper.loadFileYaml(pathMorphemeyaml);
    final Map<dynamic, dynamic> localization = yaml[keyLocalization];

    _abrDir =
        localization[keyArbDir]?.toString().replaceAll('/', separator) ?? '';
    _templateArbFile = localization[keyTemplateArbFile] ?? '';
    _outputLocalizationFile = localization[keyOutputLocalizationFile] ?? '';
    _outputClass = localization[keyOutputClass] ?? '';
    _outputDir =
        localization[keyOutputDir]?.toString().replaceAll('/', separator) ?? '';
    _replace = localization[keyReplace] == true;
  }

  late String _abrDir;
  late String _templateArbFile;
  late String _outputLocalizationFile;
  late String _outputClass;
  late String _outputDir;
  late bool _replace;

  String get arbDir => _abrDir;
  String get templateArbFile => _templateArbFile;
  String get outputLocalizationFile => _outputLocalizationFile;
  String get outputClass => _outputClass;
  String get outputDir => _outputDir;
  bool get replace => _replace;
}
