import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

abstract class FirebaseHelper {
  static Future<int> run(String flavor, String pathMorphemeYaml) async {
    return 'morpheme firebase -f $flavor --morpheme-yaml "$pathMorphemeYaml"'
        .run;
  }

  static Map<dynamic, dynamic> byFlavor(
      String flavor, String pathMorphemeYaml) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapFlavor = yaml['firebase'] ?? {};
    return mapFlavor[flavor] ?? {};
  }
}
