import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

extension ArgResultsExtension on ArgResults? {
  String getOptionTarget() => this?['target'] ?? 'lib/main.dart';
  String getOptionMorphemeYaml() {
    final path = join(current, 'pubspec.yaml');
    if (exists(path)) {
      final pathMorphemeCli = YamlHelper.loadFileYaml(path)['morpheme_cli'];
      if (pathMorphemeCli != null) {
        return pathMorphemeCli;
      }
    }
    return this?['morpheme-yaml'] ?? join(current, 'morpheme.yaml');
  }

  String getOptionFlavor({required String defaultTo}) =>
      this?['flavor'] ?? defaultTo;
  String getOptionExportMethod() => this?['export-method'] != null
      ? '--export-method "${this!['export-method']}"'
      : '';
  String? getOptionExportOptionsPlist() => this?['export-options-plist'] != null
      ? '--export-options-plist "${this!['export-options-plist']}"'
      : '';
  String getOptionBuildNumber() => this?['build-number'] != null
      ? '--build-number=${this!['build-number']}'
      : '';
  String getOptionBuildName() =>
      this?['build-name'] != null ? '--build-name=${this!['build-name']}' : '';

  bool getFlagDebug() => this?['debug'];
  bool getFlagProfile() => this?['profile'];
  bool getFlagRelease() => this?['release'];
  String getFlagCodesign() =>
      this?['codesign'] ? '--codesign' : '--no-codesign';

  String getMode() {
    String mode = '--release';
    if (getFlagDebug()) {
      mode = '--debug';
    } else if (getFlagProfile()) {
      mode = '--profile';
    }
    return mode;
  }

  String getFlagObfuscate() => this?['obfuscate'] ? '--obfuscate' : '';
  String getOptionSplitDebugInfo() =>
      this?['split-debug-info'] != null && this?['obfuscate']
          ? '--split-debug-info=${this!['split-debug-info']}'
          : '';
  bool getFlagGenerateL10n() => this?['l10n'];
}
