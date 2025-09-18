import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Generator for creating template test files from code templates.
///
/// This class handles the generation of test files using template-based
/// code generation, particularly for cubit test files.
class TemplateTestFileGenerator {
  /// Creates the presentation cubit test file.
  ///
  /// Parameters:
  /// - [dir]: Directory where the test file will be created
  /// - [featureName]: Name of the feature
  /// - [pageName]: Name of the page
  /// - [json2DartMap]: JSON to Dart configuration map
  void createPresentationCubitTest(
    String dir,
    String featureName,
    String pageName,
    Map json2DartMap,
  ) {
    final path = join(dir, '${pageName}_cubit_test.dart');

    final template = '''import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';
import 'package:${featureName.snakeCase}/${pageName.snakeCase}/presentation/pages/${pageName.snakeCase}_page.dart';
import 'package:${featureName.snakeCase}/${pageName.snakeCase}/presentation/cubit/${pageName.snakeCase}_cubit.dart';
${json2DartMap.keys.map(
      (e) {
        final feature = featureName.snakeCase;
        final page = pageName.snakeCase;
        final api = e.toString().snakeCase;
        return '''import 'package:$feature/$page/data/models/body/${api}_body.dart';
import 'package:$feature/$page/presentation/bloc/$api/${api}_bloc.dart';''';
      },
    ).join('\n')}

${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''class Mock${api}Bloc extends Mock implements ${api}Bloc {}''';
      },
    ).join('\n\n')}

class Mock${pageName.pascalCase}Page extends Mock implements ${pageName.pascalCase}Page {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

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

  setUp(() async {
    // this method is called before each test for register all dependencies
    // you can delete this if you don't need it
    registerSetUp();

    ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''    mock${api}Bloc = Mock${api}Bloc();''';
      },
    ).join('\n')}

    ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''    when(() => mock${api}Bloc.close()).thenAnswer((_) async {});''';
      },
    ).join('\n')}

     cubit = ${pageName.pascalCase}Cubit(${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''${api.camelCase}Bloc: mock${api}Bloc,''';
      },
    ).join('\n')});

     ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        final path = json2DartMap[e]['path']?.toString();
        final regExp = RegExp(r':\w+');

        final parameters = <String>[];

        if (path?.isNotEmpty ?? false) {
          final matchAll = regExp.allMatches(path!);

          for (final match in matchAll) {
            parameters.add(match.group(0)?.replaceAll(':', '') ?? '');
          }
        }

        return '''    registerFallbackValue(Fetch$api(${api}Body(${parameters.isEmpty ? '' : parameters.map((e) => "${e.camelCase}: '${e.paramCase}',").join('\n')}),),);''';
      },
    ).join('\n')}


  });

  tearDown(() async {
    cubit.dispose();

    // this method is called before each test for register all dependencies
    // you can delete this if you don't need it
    registerTearDown();
  });

  tearDownAll(() {
    // this method is called after each test for unregister all dependencies
    // you can delete this if you don't need it
    registerTearDownAll();
  });

  test('initial state should be ${pageName.pascalCase}StateCubit', () {
    expect(cubit.state, isA<${pageName.pascalCase}StateCubit>());
  });

  group('blocProviders', (){
    test('should provide the correct number of BlocProviders', () {
      final blocProviders = cubit.blocProviders(mockContext);

      ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''expect(
        blocProviders.whereType<BlocProvider<${api}Bloc>>().length,
        1,
        reason: 'There should be exactly one BlocProvider for ${api}Bloc',
      );''';
      },
    ).join('\n')}

    ${json2DartMap.isEmpty ? 'expect(blocProviders, isEmpty);' : ''}
    });
  });

  group('blocListeners', (){
    test('should provide the correct number of BlocListener', () {
      final blocListeners = cubit.blocListeners(mockContext);

      ${json2DartMap.keys.map(
      (e) {
        final api = e.toString().pascalCase;
        return '''expect(
        blocListeners
            .whereType<BlocListener<${api}Bloc, ${api}State>>()
            .length,
        isIn([0, 1]),
        reason: 'There should be exactly one BlocListener for ${api}Bloc',
      );''';
      },
    ).join('\n')}
      
      ${json2DartMap.isEmpty ? 'expect(blocListeners, isEmpty);' : ''}
    });
  });

  ${json2DartMap.isEmpty ? '' : '''group('dispose', (){
    test('should close all Blocs when cubit is closed', () async {
      await cubit.close();

      ${json2DartMap.keys.map(
                (e) {
                  final api = e.toString().pascalCase;
                  return '''    verify(() => mock${api}Bloc.close()).called(1);''';
                },
              ).join('\n')}
    });
  });'''}

   // your test here
}
''';

    path.write(template);

    StatusHelper.generated(path);
  }
}