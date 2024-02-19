import 'package:morpheme/constants.dart';
import 'package:morpheme/dependency_manager.dart';
import 'package:morpheme/helper/modular_helper.dart';
import 'package:morpheme/helper/status_helper.dart';

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
