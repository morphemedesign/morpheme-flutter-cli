import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/flutter_helper.dart';

class DoctorCommand extends Command {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Show information about the installed tooling.';

  @override
  String get category => Constants.tools;

  @override
  void run() async {
    if (which('flutter').found) {
      print('${green('[✓]')} Flutter installed');
      await FlutterHelper.run('doctor');
    } else {
      printerr('${red('[x]')} Flutter not installed');
      printerr(
        'You can install flutter in https://docs.flutter.dev/get-started/install',
      );
    }

    if (which('flutterfire').found) {
      print('${green('[✓]')} flutterfire installed');
    } else {
      printerr('${red('[x]')} flutterfire not installed');
      printerr(
        'You can install with \'dart pub global activate flutterfire_cli\'',
      );
    }
    print('flutterfire use for \'morpheme firebase\' command');

    if (which('gherkin').found) {
      print('${green('[✓]')} Gherkin installed');
    } else {
      printerr('${red('[x]')} Gherkin not installed');
      printerr(
        'You can install in https://github.com/morphemedesign/morpheme-flutter-cli/releases/tag/cucumber',
      );
    }
    print('gherkin use for \'morpheme cucumber\' command');

    if (which('npm').found) {
      print('${green('[✓]')} npm installed');
    } else {
      printerr('${red('[x]')} npm not installed');
      printerr(
        'You can follow installation in https://nodejs.org/en',
      );
    }
    print(
        'npm use for create report integration test after \'morpheme cucumber\' command');

    if (which('lcov').found) {
      print('${green('[✓]')} lcov installed');
    } else {
      printerr('${red('[x]')} lcov not installed');
      printerr(
        'You can follow installation in https://github.com/linux-test-project/lcov',
      );
    }
    print('lcov use for \'morpheme coverage\' command');
  }
}
