import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/helper/helper.dart';

class InitCommand extends Command {
  InitCommand() {
    argParser.addOption(
      'app-name',
      help: 'Init with App name',
      defaultsTo: 'morpheme',
    );
    argParser.addOption(
      'application-id',
      help: 'Init with application id',
      defaultsTo: 'design.morpheme',
    );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Init a new project from starter kit';

  @override
  String get category => Constants.tools;

  @override
  void run() {
    final String appName = argResults?['app-name'] ?? 'morpheme';
    final String applicationId =
        argResults?['application-id'] ?? 'design.morpheme';

    final androidApplicationId =
        applicationId.split('.').map((e) => e.snakeCase).join('.');
    final iosApplicationId =
        applicationId.split('.').map((e) => e.camelCase).join('.');

    if (!exists(join(current, 'pubspec.yaml'))) {
      StatusHelper.failed(
          'You don\'t have "pubspec.yaml" in root apps, make sure to select project flutter');
    }

    if (exists(join(current, 'morpheme.yaml'))) {
      StatusHelper.warning(
          'you already have morpheme.yaml in your project root');
    } else {
      join(current, 'morpheme.yaml').write('''flavor:
  dev:
    FLAVOR: dev
    APP_NAME: ${appName.titleCase} Dev
    ANDROID_APPLICATION_ID: $androidApplicationId.dev
    IOS_APPLICATION_ID: $iosApplicationId.dev
    BASE_URL: https://reqres.in/api
  stag:
    FLAVOR: stag
    APP_NAME: ${appName.titleCase} Stag
    ANDROID_APPLICATION_ID: $androidApplicationId.stag
    IOS_APPLICATION_ID: $iosApplicationId.stag
    BASE_URL: https://reqres.in/api
  prod:
    FLAVOR: prod
    APP_NAME: ${appName.titleCase}
    ANDROID_APPLICATION_ID: $androidApplicationId
    IOS_APPLICATION_ID: $iosApplicationId
    BASE_URL: https://reqres.in/api

firebase:
  dev:
    project_id: "morpheme-dev"
    token: "YOUR FIREBASE TOKEN: firebase login:ci"
  stag:
    project_id: "morpheme-stag"
    token: "YOUR FIREBASE TOKEN: firebase login:ci"
  prod:
    project_id: "morpheme"
    token: "YOUR FIREBASE TOKEN: firebase login:ci"

localization:
  arb_dir: assets/assets/l10n
  template_arb_file: id.arb
  output_localization_file: s.dart
  output_class: S
  output_dir: core/lib/src/l10n
  replace: false

assets:
  pubspec_dir: assets
  assets_dir: assets/assets
  output_dir: assets/lib
  create_library_file: true
  
coverage:
  lcov_dir: coverage/lcov.info
  output_html_dir: coverage/html
  remove:
    - "*/mock/*"
    - "*.freezed.*"
    - "*.g.*"
    - "*/l10n/*"
    - "*_state.dart"
    - "*_event.dart"
    - "**/locator.dart"
    - "**/environtment.dart"
    - "core/lib/src/test/*"
    - "core/lib/src/constants/*"
    - "core/lib/src/themes/*"
    - "lib/routes/routes.dart"
    - "lib/generated_plugin_registrant.dart"
''');

      StatusHelper.generated(join(current, 'morpheme.yaml'));
    }
  }
}
