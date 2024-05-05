import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:yaml_writer/yaml_writer.dart';

abstract class YamlHelper {
  static void validateMorphemeYaml([String? morphemeYaml]) {
    if (!exists(join(current, 'morpheme.yaml')) && morphemeYaml == null) {
      StatusHelper.failed(
          'You don\'t have "morpheme.yaml" in root apps, make sure to "morpheme init" first');
    } else if (morphemeYaml != null && !exists(morphemeYaml)) {
      StatusHelper.failed(
          'Not found custom path morpheme.yaml in "$morphemeYaml"');
    }
  }

  static Map<dynamic, dynamic> loadFileYaml(String path) {
    try {
      final File file = File(path);
      final String yamlString = file.readAsStringSync();
      return loadYaml(yamlString);
    } catch (e) {
      printerr(e.toString());
      return {};
    }
  }

  static void saveFileYaml(String path, Map map) {
    final yaml = YamlWriter().write(map);
    path.write(yaml);
  }
}
