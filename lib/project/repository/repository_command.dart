import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class RepositoryCommand extends Command {
  RepositoryCommand() {
    argParser.addOptionMorphemeYaml();
  }
  @override
  String get name => 'repository';

  @override
  String get description => 'Clone repository or pull from remote';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();

    YamlHelper.validateMorphemeYaml(argMorphemeYaml);

    final yaml = YamlHelper.loadFileYaml(argMorphemeYaml);
    final Map repository = yaml['repository'] ?? {};

    if (repository.isNotEmpty) {
      repository.forEach(
        (key, value) {
          if (!exists(key)) {
            'git clone $value $key'.run;
          } else {
            'git fetch'.start(
              workingDirectory: key,
            );
            'git pull'.start(
              workingDirectory: key,
            );
          }
        },
      );

      StatusHelper.success('morpheme repository');
    } else {
      StatusHelper.warning(
        'You do not have any repository in $argMorphemeYaml',
      );
    }
  }
}
