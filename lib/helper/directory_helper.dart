import 'package:morpheme_cli/dependency_manager.dart' as dependency_manager;

abstract class DirectoryHelper {
  static void createDir(String path) {
    if (!dependency_manager.exists(path)) {
      dependency_manager.createDir(path, recursive: true);
    }
  }
}
