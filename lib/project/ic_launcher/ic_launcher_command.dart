import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class IcLauncherCommand extends Command {
  IcLauncherCommand() {
    argParser.addOptionFlavor(defaultsTo: Constants.dev);
  }

  @override
  String get name => 'ic-launcher';

  @override
  String get description => 'Copy your ic launcher to spesific platform';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argFlavor = argResults.getOptionFlavor(defaultTo: Constants.dev);

    copyIcLauncherAndroid(argFlavor);
    copyIcLauncherIos(argFlavor);

    StatusHelper.success('ic-launcher');
  }

  void copyIcLauncherAndroid(String flavor) {
    final from = join(current, 'ic_launcher', 'android', flavor);
    final to = join(current, 'android', 'app', 'src', 'main', 'res');

    copyTree(from, to, overwrite: true);
  }

  void copyIcLauncherIos(String flavor) {
    final from = join(current, 'ic_launcher', 'ios', flavor);
    final to = join(current, 'ios', 'Runner');

    copyTree(from, to, overwrite: true);
  }
}
