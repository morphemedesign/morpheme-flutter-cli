import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';

abstract class ShorebirdHelper {
  static (String? version, Map<dynamic, dynamic>? map) byFlavor(
    String flavor,
    String pathMorphemeYaml,
  ) {
    final yaml = YamlHelper.loadFileYaml(pathMorphemeYaml);
    final Map<dynamic, dynamic> mapShorebird = yaml['shorebird'] ?? {};
    final flutterVersion = mapShorebird['flutter_version'];
    final Map<dynamic, dynamic>? mapFlavor =
        mapShorebird['flavor'][flavor] ?? {};
    return (flutterVersion, mapFlavor);
  }

  static void writeShorebirdYaml(Map<dynamic, dynamic>? map) {
    if (map == null) return;
    final appId = map['app_id'];
    final autoUpdate = map['auto_update'] ?? true;
    join(current, 'shorebird.yaml').write(
        '''# This file is used to configure the Shorebird updater used by your app.
# Learn more at https://docs.shorebird.dev
# This file does not contain any sensitive information and should be checked into version control.

# Your app_id is the unique identifier assigned to your app.
# It is used to identify your app when requesting patches from Shorebird's servers.
# It is not a secret and can be shared publicly.
app_id: $appId

# auto_update controls if Shorebird should automatically update in the background on launch.
# If auto_update: false, you will need to use package:shorebird_code_push to trigger updates.
# https://pub.dev/packages/shorebird_code_push
# Uncomment the following line to disable automatic updates.
auto_update: $autoUpdate
''');
  }
}
