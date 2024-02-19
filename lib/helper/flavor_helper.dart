import 'package:morpheme/helper/status_helper.dart';
import 'package:morpheme/helper/yaml_helper.dart';

abstract class FlavorHelper {
  static Map<dynamic, dynamic> byFlavor(
      String flavor, String pathMorphemeYaml) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapFlavor = yaml['flavor'] ?? {};
    final map = mapFlavor[flavor] ?? {};
    if (map.isEmpty) {
      StatusHelper.failed('Flavor $flavor not found in morpheme.yaml');
    }
    return map;
  }
}
