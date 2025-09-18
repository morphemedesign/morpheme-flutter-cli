import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

/// Helper class for localization configuration.
///
/// This class provides access to localization configuration settings
/// from the morpheme.yaml file, making it easy to retrieve localization
/// parameters for code generation and management.
class LocalizationHelper {
  /// Creates a LocalizationHelper instance from a morpheme.yaml file.
  ///
  /// This constructor reads localization configuration from the specified
  /// morpheme.yaml file and initializes the helper with those settings.
  ///
  /// Parameters:
  /// - [pathMorphemeyaml]: The path to the morpheme.yaml configuration file
  ///
  /// Example:
  /// ```dart
  /// final localizationHelper = LocalizationHelper('./morpheme.yaml');
  /// final arbDir = localizationHelper.arbDir;
  /// final outputDir = localizationHelper.outputDir;
  /// ```
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

  /// The directory containing ARB files
  late String _abrDir;
  
  /// The template ARB file name
  late String _templateArbFile;
  
  /// The output localization file name
  late String _outputLocalizationFile;
  
  /// The output class name for generated localization code
  late String _outputClass;
  
  /// The output directory for generated localization files
  late String _outputDir;
  
  /// Whether to replace existing files during generation
  late bool _replace;

  /// Gets the directory containing ARB files
  String get arbDir => _abrDir;
  
  /// Gets the template ARB file name
  String get templateArbFile => _templateArbFile;
  
  /// Gets the output localization file name
  String get outputLocalizationFile => _outputLocalizationFile;
  
  /// Gets the output class name for generated localization code
  String get outputClass => _outputClass;
  
  /// Gets the output directory for generated localization files
  String get outputDir => _outputDir;
  
  /// Gets whether to replace existing files during generation
  bool get replace => _replace;
}