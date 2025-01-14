import 'dart:io';

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
  void run() async {
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
      final output = firebase['output'];
      final androidPackageName =
          firebase['android_package_name'] ?? flavor['ANDROID_APPLICATION_ID'];
      final iosBundleId =
          firebase['ios_bundle_id'] ?? flavor['IOS_APPLICATION_ID'];
      final webAppId = firebase['web_app_id'];
      final serviceAccount = firebase['service_account']?.toString();
      final enableCiUseServiceAccount =
          firebase['enable_ci_use_service_account'] is bool
              ? firebase['enable_ci_use_service_account'] as bool
              : false;

      final argToken =
          token is String && token.isNotEmpty ? ' -t "$token"' : '';
      final argPlatform = platform is String && platform.isNotEmpty
          ? ' --platforms="$platform"'
          : '';
      final argWebAppId =
          webAppId is String && webAppId.isNotEmpty ? ' -w "$webAppId"' : '';
      final argOutput =
          output is String && output.isNotEmpty ? ' -o "$output"' : '';

      bool regenerate = true;

      final pathFirebaseOptions = output != null
          ? join(current, output)
          : join(current, 'lib', 'firebase_options.dart');
      if (exists(pathFirebaseOptions)) {
        final firebaseOptions = readFile(pathFirebaseOptions);
        if (RegExp('''projectId:(\\s+)?('|")$project('|")''')
            .hasMatch(firebaseOptions)) {
          regenerate = false;
          StatusHelper.generated('you already have lib/firebase_options.dart');
        }
      }

      final isCiCdEnvironment = Platform.environment.containsKey('CI') &&
          Platform.environment['CI'] == 'true';

      if ((isCiCdEnvironment && enableCiUseServiceAccount) ||
          !isCiCdEnvironment) {
        if (serviceAccount?.isNotEmpty ?? false) {
          'export GOOGLE_APPLICATION_CREDENTIALS="$serviceAccount"'.run;
        }
      }

      if (regenerate || argOverwrite) {
        await 'flutterfire configure $argToken$argPlatform$argWebAppId$argOutput -p "$project"  -a "$androidPackageName" -i "$iosBundleId" -m "$iosBundleId" -w "$androidPackageName" -x "$androidPackageName" -y'
            .run;
      }
    } else {
      StatusHelper.failed(
          'flutterfire not installed, You can install with \'dart pub global activate flutterfire_cli\'');
    }
  }
}
