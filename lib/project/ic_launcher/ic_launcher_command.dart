import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class IcLauncherCommand extends Command {
  @override
  String get name => 'ic-launcher';

  @override
  String get description => 'Copy your ic launcher to spesific platform';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    copyIcLauncherAndroid();
    copyIcLauncherIos();

    StatusHelper.success('ic-launcher');
  }

  void copyIcLauncherAndroid() {
    final from = join(current, 'ic_launcher', 'android');
    final to = join(current, 'android', 'app', 'src', 'main', 'res');

    copy(from, to, overwrite: true);
  }

  void copyIcLauncherIos() {
    final from = join(current, 'ic_launcher', 'ios');
    final to = join(current, 'ios', 'Runner');

    copy(from, to, overwrite: true);
  }
}
