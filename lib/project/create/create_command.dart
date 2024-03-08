import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class CreateCommand extends Command {
  CreateCommand() {
    argParser.addOption(
      'tag',
      abbr: 't',
      help:
          'Clone with Tag version morpheme flutter starter kit, default clone master',
    );
    argParser.addFlag(
      'refactor',
      help: 'Auto refactor rename morpheme name to app name',
      defaultsTo: false,
    );
    argParser.addFlag(
      'include-library',
      defaultsTo: false,
    );
    argParser.addOption(
      'application-id',
      help: 'Init with application id',
      defaultsTo: 'design.morpheme',
    );
  }

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create flutter application with Morpheme Flutter Starter Kit';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      StatusHelper.failed(
          'App name is empty, you can create flutter apps with "morpheme create <app-name>"');
    }

    final appName = rest.first;
    final workingDirectory = join(current, appName);

    if (exists(workingDirectory)) {
      StatusHelper.failed('Directory with $appName is already exists');
    }

    final bool refactor = argResults?['refactor'] ?? false;
    final tag =
        argResults?['tag'] != null ? '-b ${argResults?['tag']} --depth 1' : '';
    final applicationId = argResults?['application-id'] != null
        ? '--application-id "${argResults?['application-id']}"'
        : '';

    await 'git clone https://github.com/morphemedesign/morpheme-flutter.git $appName $tag'
        .run;

    deleteDir(join(workingDirectory, '.git'));
    await 'morpheme init --app-name "$appName" $applicationId'
        .start(workingDirectory: workingDirectory);
    if (refactor) {
      final includeLibrary =
          (argResults?['include-library'] ?? false) ? '--include-library' : '';
      await 'morpheme refactor --old-name="morpheme" --new-name="$appName" $includeLibrary'
          .start(workingDirectory: workingDirectory);
    } else {
      await 'morpheme get'.start(workingDirectory: workingDirectory);
    }
    await 'morpheme config'.start(workingDirectory: workingDirectory);

    StatusHelper.generated(workingDirectory);
  }
}
