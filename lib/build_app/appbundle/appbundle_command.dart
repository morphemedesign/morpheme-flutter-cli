import 'package:morpheme_cli/build_app/base/build_command_base.dart';

class AppbundleCommand extends BuildCommandBase {
  AppbundleCommand() : super() {
    // App Bundle-specific arguments if any
  }

  @override
  String get name => 'appbundle';

  @override
  String get description => 'Build android aab with flavor.';

  @override
  String get buildTarget => 'appbundle';
}