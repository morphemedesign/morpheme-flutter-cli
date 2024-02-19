import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class FirebaseCommand extends Command {
  FirebaseCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'overwrite',
      abbr: 'o',
      help: 'Force overwrite firebase configuration',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'firebase';

  @override
  String get description => 'Generate google service both android & ios.';

  @override
  String get category => Constants.generate;

  @override
  void run() {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argOverwrite = argResults?['overwrite'] as bool? ?? false;

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final flavor = FlavorHelper.byFlavor(argFlavor, argMorphemeYaml);
    final firebase = FirebaseHelper.byFlavor(argFlavor, argMorphemeYaml);
    if (firebase.isEmpty) {
      StatusHelper.warning(
          'Cannot setup flavor firebase, You don\'t have config "firebase" with flavor "$argFlavor" in morpheme.yaml');
    } else if (which('flutterfire').found) {
      final project = firebase['project_id'];
      final token = firebase['token'];
      final platform = firebase['platform'];
      final androidPackageName =
          firebase['android_package_name'] ?? flavor['ANDROID_APPLICATION_ID'];
      final iosBundleId =
          firebase['ios_bundle_id'] ?? flavor['IOS_APPLICATION_ID'];
      final webAppId = firebase['web_app_id'];

      final argToken =
          token is String && token.isNotEmpty ? ' -t "$token"' : '';
      final argPlatform = platform is String && platform.isNotEmpty
          ? ' --platforms="$platform"'
          : '';
      final argWebAppId =
          webAppId is String && webAppId.isNotEmpty ? ' -w "$webAppId"`' : '';

      bool regenerate = true;

      final pathFirebaseOptions = join(current, 'lib', 'firebase_options.dart');
      if (exists(pathFirebaseOptions)) {
        final firebaseOptions = readFile(pathFirebaseOptions);
        if (RegExp('''projectId:(\\s+)?('|")$project('|")''')
            .hasMatch(firebaseOptions)) {
          regenerate = false;
          StatusHelper.generated('you already have lib/firebase_options.dart');
        }
      }

      if (regenerate || argOverwrite) {
        'flutterfire configure $argToken$argPlatform$argWebAppId -p "$project"  -a "$androidPackageName" -i "$iosBundleId" -y'
            .run;
      }
    } else {
      StatusHelper.failed(
          'flutterfire not installed, You can install with \'dart pub global activate flutterfire_cli\'');
    }
  }
}
