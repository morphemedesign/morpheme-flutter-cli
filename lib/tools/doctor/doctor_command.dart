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
      printMessage('${green('[✓]')} Flutter installed');
      await FlutterHelper.run('doctor');
    } else {
      printerrMessage('${red('[x]')} Flutter not installed');
      printerrMessage(
        'You can install flutter in https://docs.flutter.dev/get-started/install',
      );
    }

    if (which('flutterfire').found) {
      printMessage('${green('[✓]')} flutterfire installed');
    } else {
      printerrMessage('${red('[x]')} flutterfire not installed');
      printerrMessage(
        'You can install with \'dart pub global activate flutterfire_cli\'',
      );
    }
    printMessage('flutterfire use for \'morpheme firebase\' command');

    if (which('gherkin').found) {
      printMessage('${green('[✓]')} Gherkin installed');
    } else {
      printerrMessage('${red('[x]')} Gherkin not installed');
      printerrMessage(
        'You can install in https://github.com/morphemedesign/morpheme-flutter-cli/releases/tag/cucumber',
      );
    }
    printMessage('gherkin use for \'morpheme cucumber\' command');

    if (which('npm').found) {
      printMessage('${green('[✓]')} npm installed');
    } else {
      printerrMessage('${red('[x]')} npm not installed');
      printerrMessage(
        'You can follow installation in https://nodejs.org/en',
      );
    }
    printMessage(
        'npm use for create report integration test after \'morpheme cucumber\' command');

    if (which('lcov').found) {
      printMessage('${green('[✓]')} lcov installed');
    } else {
      printerrMessage('${red('[x]')} lcov not installed');
      printerrMessage(
        'You can follow installation in https://github.com/linux-test-project/lcov',
      );
    }
    printMessage('lcov use for \'morpheme coverage\' command');
  }
}
