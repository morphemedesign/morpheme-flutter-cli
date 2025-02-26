import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';

import '../../helper/helper.dart';

class TemplateTestCommand extends Command {
  @override
  String get name => 'template-test';

  @override
  String get description =>
      'Generate template test code based on json2dart.yaml.';

  @override
  String get category => Constants.generate;

  TemplateTestCommand() {
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate spesific apps (Optional)',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Generate template test in spesific feature',
      mandatory: true,
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Generate spesific page, must include --feature-name',
      mandatory: true,
    );
  }

  @override
  void run() async {
    final appsName = argResults?['apps-name']?.toString().snakeCase;
    final featureName = argResults?['feature-name']?.toString().snakeCase ?? '';
    final pageName = argResults?['page-name']?.toString().snakeCase ?? '';

    final searchFileJson2Dart = appsName?.isNotEmpty ?? false
        ? '${appsName}_json2dart.yaml'
        : 'json2dart.yaml';

    final workingDirectory = find(
      searchFileJson2Dart,
      workingDirectory: join(current, 'json2dart'),
    ).toList();

    for (var pathJson2Dart in workingDirectory) {
      final yml = YamlHelper.loadFileYaml(pathJson2Dart);
      final json2DartMap = Map.from(yml);

      String pathTestPage = join(
        current,
        'features',
        featureName,
        'test',
        '${pageName}_test',
      );

      if (appsName?.toString().isNotEmpty ?? false) {
        pathTestPage = join(
          current,
          'apps',
          appsName,
          'features',
          featureName,
          'test',
          '${pageName}_test',
        );
      }

      Map map = json2DartMap[featureName] ?? {};

      if (map.isEmpty) {
        StatusHelper.failed('Feature not found in json2dart.yaml');
        return;
      }

      map = map[pageName] ?? {};

      if (map.isEmpty) {
        StatusHelper.failed('Page not found in json2dart.yaml');
        return;
      }

      createDataTest(pathTestPage, featureName, pageName);
      createDomainTest(pathTestPage, featureName, pageName);
      createPresentationTest(pathTestPage, featureName, pageName, map);

      await ModularHelper.format([pathTestPage]);
    }

    StatusHelper.success('Generate template test code');
  }

  void createDataTest(
    String pathTestPage,
    String featureName,
    String pageName,
  ) {
    final dirs = [
      'datasources',
      'model/body',
      'model/response',
      'repositories'
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'data', dir);
      DirectoryHelper.createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }
  }

  void createDomainTest(
    String pathTestPage,
    String featureName,
    String pageName,
  ) {
    final dirs = [
      'entities',
      'repositories',
      'usecases',
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'domain', dir);
      DirectoryHelper.createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }
  }

  void createPresentationTest(
    String pathTestPage,
    String featureName,
    String pageName,
    Map json2DartMap,
  ) {
    final dirs = [
      'bloc',
      'cubit',
      'pages',
      'widgets',
    ];

    for (var dir in dirs) {
      final path = join(pathTestPage, 'presentation', dir);
      DirectoryHelper.createDir(path);
      touch(join(path, '.gitkeep'), create: true);
    }

    createPresentationCubitTest(
      join(pathTestPage, 'presentation', 'cubit'),
      featureName,
      pageName,
      json2DartMap,
    );
  }

  void createPresentationCubitTest(
    String dir,
    String featureName,
    String pageName,
    Map json2DartMap,
  ) {
    final path = join(dir, '${pageName}_cubit_test.dart');

    final template =
        '''import 'package:dev_dependency_manager/dev_dependency_manager.dart';
import 'package:${featureName.snakeCase}/${pageName.snakeCase}/presentation/cubit/${pageName.snakeCase}_cubit.dart';
${json2DartMap.keys.map(
      (e) {
        final feature = featureName.snakeCase;
        final page = featureName.snakeCase;
        final api = e.toString().snakeCase;
        return '''import 'package:$feature/$page/presentation/bloc/$api/${api}_bloc.dart';''';
      },
    ).join('\n')}

${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''class Mock${api}Bloc extends Mock implements ${api}Bloc {
  @override
  Future<void> close() async {}
}''';
      },
    ).join('\n\n')}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ${pageName.pascalCase}Cubit cubit;
  ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''  late Mock${api}Bloc mock${api}Bloc;''';
      },
    ).join('\n')}


  setUpAll(() {
    // this method is called before each test for register all dependencies
    // you can delete this if you don't need it
    registerSetUpAll();
  });

  setUp(() {
    ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''    mock${api}Bloc = Mock${api}Bloc();''';
      },
    ).join('\n')}

     cubit = ${pageName.pascalCase}Cubit(${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''${api.camelCase}Bloc: mock${api}Bloc,''';
      },
    ).join('\n')});
  });

  tearDown(() async {
    cubit.dispose();
  });

  tearDownAll(() {
    // this method is called after each test for unregister all dependencies
    // you can delete this if you don't need it
    registerTearDownAll();
  });

  test('initial state should be ${pageName.pascalCase}StateCubit', () {
    expect(cubit.state, isA<${pageName.pascalCase}StateCubit>());
  });

   // your test here
}
''';

    path.write(template);

    StatusHelper.generated(path);
  }
}
