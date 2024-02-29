import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

class RenameCommand extends Command {
  RenameCommand() {
    argParser.addOption(
      'prefix',
      abbr: 'p',
      help: 'Add prefix filename',
    );
    argParser.addOption(
      'suffix',
      abbr: 's',
      help: 'Add prefix filename',
    );
    argParser.addOption(
      'glob-pattern',
      abbr: 'g',
      help: 'Glob pattern filename',
    );
  }

  @override
  String get name => 'rename';

  @override
  String get description =>
      'Rename filename to snakecase with prefix or suffix';

  @override
  String get category => Constants.tools;

  @override
  void run() {
    final prefix = argResults?['prefix'] ?? '';
    final suffix = argResults?['suffix'] ?? '';
    final globPattern = argResults?['glob-pattern'] ?? '*';
    final workingDirectory =
        argResults?.rest.isNotEmpty ?? false ? argResults!.rest.first : '.';

    final items =
        find(globPattern, workingDirectory: workingDirectory).toList();

    for (var item in items) {
      final path = item.split(separator);
      final filenameWithExtension = path.removeLast().split('.');

      String filename = filenameWithExtension.first;
      String extesion =
          filenameWithExtension.length > 1 ? filenameWithExtension.last : '';

      if (!filename.startsWith(prefix)) {
        filename = '${prefix}_$filename';
      }

      if (!filename.endsWith(suffix)) {
        filename = '${filename}_$suffix';
      }

      filename = filename.snakeCase;

      path.add('$filename.$extesion');

      final finalPath = path.join(separator);
      move(item, finalPath);

      StatusHelper.generated('rename from $item to $finalPath');
    }

    StatusHelper.success('morpheme rename');
  }
}
