import 'dart:io';

import 'package:morpheme_cli/build_app/build_command.dart';
import 'package:morpheme_cli/build_app/prebuild_command.dart';
import 'package:morpheme_cli/core/src/log.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/generate/generate.dart';
import 'package:morpheme_cli/generate/remove/remove_test_command.dart';
import 'package:morpheme_cli/generate/test/template_test_command.dart';
import 'package:morpheme_cli/project/project.dart';
import 'package:morpheme_cli/shorebird/shorebird_command.dart';
import 'package:morpheme_cli/tools/tools.dart';

void main(List<String> arguments) async {
  clearLog();

  final runner = CommandRunner('morpheme',
      'Morpheme CLI Boost productivity with modular project creation, API generation & folder structuring tools. Simplify Flutter dev! #Flutter #CLI')
    //* Generate
    ..addCommand(LocalizationCommand())
    ..addCommand(FeatureCommand())
    ..addCommand(PageCommand())
    ..addCommand(ApiCommand())
    ..addCommand(CoreCommand())
    ..addCommand(ConfigCommand())
    ..addCommand(FirebaseCommand())
    ..addCommand(Json2DartCommand())
    ..addCommand(Color2DartCommand())
    ..addCommand(EndpointCommand())
    ..addCommand(AssetCommand())
    ..addCommand(Local2DartCommand())
    ..addCommand(RemovePageCommand())
    ..addCommand(RemoveFeatureCommand())
    ..addCommand(PreBuildCommand())
    ..addCommand(AppsCommand())
    ..addCommand(RemoveAppsCommand())
    ..addCommand(TemplateTestCommand())
    ..addCommand(RemoveTestCommand())
    //* Project
    ..addCommand(CreateCommand())
    ..addCommand(GetCommand())
    ..addCommand(RunCommand())
    ..addCommand(CleanCommand())
    ..addCommand(FormatCommand())
    ..addCommand(TestCommand())
    ..addCommand(UpgradeDependencyCommand())
    ..addCommand(CoverageCommand())
    ..addCommand(AnalyzeCommand())
    ..addCommand(RefactorCommand())
    ..addCommand(CucumberCommand())
    ..addCommand(UnusedL10nCommand())
    ..addCommand(DownloadCommand())
    ..addCommand(IcLauncherCommand())
    ..addCommand(FixCommand())
    //* Build
    ..addCommand(BuildCommand())
    ..addCommand(ShorebirdCommand())
    //* Tools
    ..addCommand(RenameCommand())
    ..addCommand(ChangelogCommand())
    ..addCommand(DoctorCommand())
    ..addCommand(InitCommand())
    ..addCommand(UpgradeCommand());

  runner.argParser.addFlag(
    'version',
    abbr: 'v',
    help: 'Reports the version of this tool.',
    negatable: false,
  );

  try {
    final results = runner.argParser.parse(arguments);
    if (results.wasParsed('version')) {
      printMessage('Morpheme CLI 3.3.4');
      exit(0);
    }
  } catch (e) {
    printerrMessage(red(e.toString()));
  }

  Loading().start();

  await runner.run(arguments).onError((error, stackTrace) {
    Loading().stop();

    printerrMessage(red(error.toString()));
    exit(1);
  });

  Loading().stop();
}
