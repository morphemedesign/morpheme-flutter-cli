import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class UpgradeCommand extends Command {
  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade morpheme_cli to latest versions..';

  @override
  String get category => Constants.tools;

  @override
  void run() async {
    await '${FlutterHelper.getCommandDart()} pub global activate morpheme_cli'
        .run;

    StatusHelper.success();
  }
}
