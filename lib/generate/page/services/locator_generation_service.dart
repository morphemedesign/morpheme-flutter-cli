import 'dart:io';

import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Service for generating locator files for pages.
///
/// This service handles the creation of page-specific locator files
/// and updates to feature locator files.
class LocatorGenerationService {
  /// Creates the page-specific locator file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void createLocatorFile(PageConfig config) {
    final path = config.pathPage;
    createDir(path);

    join(path, 'locator.dart').write('''import 'package:core/core.dart';

import 'presentation/cubit/${config.pageName}_cubit.dart';

void setupLocator${config.className}() {
  // *Cubit
  locator.registerFactory(() => ${config.className}Cubit());
}''');

    StatusHelper.generated(join(path, 'locator.dart'));
  }

  /// Updates the feature locator to include the page locator.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void updateFeatureLocator(PageConfig config) {
    final path = join(config.pathFeature, 'lib');
    final locatorPath = join(path, 'locator.dart');

    if (!exists(locatorPath)) {
      StatusHelper.warning('Feature locator file not found at $locatorPath');
      return;
    }

    String data = File(locatorPath).readAsStringSync();

    data = data.replaceAll(RegExp(r'\n?void\s\w+\(\)\s{', multiLine: true),
        '''import '${config.pageName}/locator.dart';

void setupLocatorFeature${config.featureName.pascalCase}() {''');

    data = data.replaceAll(RegExp(r'}\n$', multiLine: true),
        '''  setupLocator${config.className}();
}''');

    join(path, 'locator.dart').write(data);

    StatusHelper.generated(join(path, 'locator.dart'));
  }
}
