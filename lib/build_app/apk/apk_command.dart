import 'package:morpheme_cli/build_app/base/build_command_base.dart';

class ApkCommand extends BuildCommandBase {
  ApkCommand() : super() {
    // APK-specific arguments if any
  }

  @override
  String get name => 'apk';

  @override
  String get description => 'Build android apk with flavor.';

  @override
  String get buildTarget => 'apk';
}