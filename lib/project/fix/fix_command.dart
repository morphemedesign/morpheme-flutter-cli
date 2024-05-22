import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

class FixCommand extends Command {
  @override
  String get name => 'fix';

  @override
  String get description => 'Fix all files .dart.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    await ModularHelper.fix();
    StatusHelper.success('morpheme format');
  }
}
