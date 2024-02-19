import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

class FormatCommand extends Command {
  @override
  String get name => 'format';

  @override
  String get description => 'Format all files .dart.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    await ModularHelper.format();
    StatusHelper.success('morpheme format');
  }
}
