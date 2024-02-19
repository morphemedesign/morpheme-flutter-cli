import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/directory_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';

class PageCommand extends Command {
  PageCommand() {
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature to be added page',
      mandatory: true,
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Name of the apps to be added page.',
    );
  }

  @override
  String get name => 'page';

  @override
  String get description => 'Create a new page in feature module.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Page name is empty, add a new page with "morpheme page <page-name> -f <feature-name>"');
    }

    final appsName = (argResults?['apps-name'] as String? ?? '').snakeCase;
    final pathApps = join(current, 'apps', appsName);
    String featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    final pageName = (argResults?.rest.first ?? '').snakeCase;
    if (appsName.isNotEmpty && !RegExp('^${appsName}_').hasMatch(featureName)) {
      featureName = '${appsName}_$featureName';
    }

    if (appsName.isNotEmpty && !exists(pathApps)) {
      StatusHelper.failed(
          'Apps with "$appsName" does not exists, create a new apps with "morpheme apps <apps-name>"');
    }

    String pathFeature = join(current, 'features', featureName);
    if (appsName.isNotEmpty) {
      pathFeature = join(pathApps, 'features', featureName);
    }

    if (!exists(pathFeature)) {
      StatusHelper.failed(
          'Feature with "$featureName" does not exists, create a new feature with "morpheme feature <feature-name>"');
    }

    String pathPage = join(pathFeature, 'lib', pageName);
    if (exists(pathPage)) {
      StatusHelper.failed('Page already exists.');
    }

    final className = pageName.pascalCase;
    final methodName = pageName.camelCase;

    createDataDataSource(pathPage, pageName, className, methodName);
    createDataModelBody(pathPage, pageName, className, methodName);
    createDataModelResponse(pathPage, pageName, className, methodName);
    createDataRepository(pathPage, pageName, className, methodName);

    createDomainEntity(pathPage, pageName, className, methodName);
    createDomainRepository(pathPage, pageName, className, methodName);
    createDomainUseCase(pathPage, pageName, className, methodName);

    createPresentationBloc(pathPage, pageName, className, methodName);
    createPresentationCubit(pathPage, pageName, className, methodName);
    createPresentationPage(pathPage, pageName, className, methodName);
    createPresentationWidget(pathPage, pageName, className, methodName);

    createLocator(pathPage, pageName, className, methodName);
    appendLocatorFeature(
        pathFeature, featureName, pageName, className, methodName);

    await ModularHelper.format([pathFeature]);

    StatusHelper.success('generate page $pageName in feature $featureName');
  }

  void generateGitKeep(String path) {
    DirectoryHelper.createDir(path, recursive: true);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createDataDataSource(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'data', 'datasources');
    generateGitKeep(path);
  }

  void createDataModelBody(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'data', 'models', 'body');
    generateGitKeep(path);
  }

  void createDataModelResponse(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'data', 'models', 'response');
    generateGitKeep(path);
  }

  void createDataRepository(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'data', 'repositories');
    generateGitKeep(path);
  }

  void createDomainEntity(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'domain', 'entities');
    generateGitKeep(path);
  }

  void createDomainRepository(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'domain', 'repositories');
    generateGitKeep(path);
  }

  void createDomainUseCase(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'domain', 'usecases');
    generateGitKeep(path);
  }

  void createPresentationBloc(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'presentation', 'bloc');
    generateGitKeep(path);
  }

  void createPresentationCubit(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'presentation', 'cubit');
    DirectoryHelper.createDir(path, recursive: true);
    join(path, '${pageName}_state.dart')
        .write('''part of '${pageName}_cubit.dart';

class ${className}StateCubit extends Equatable {
  @override
  List<Object?> get props => [];
}''');

    join(path, '${pageName}_cubit.dart')
        .write('''import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../pages/${pageName}_page.dart';

part '${pageName}_state.dart';

class ${className}Cubit extends MorphemeCubit<${className}StateCubit> {
  ${className}Cubit() : super(${className}StateCubit());

  @override
  void initState(BuildContext context) {
    super.initState(context);
  }

  @override
  void initAfterFirstLayout(BuildContext context) {
    super.initAfterFirstLayout(context);
  }

  @override
  void initArgument<Page>(BuildContext context, Page widget) {
    super.initArgument(context, widget);
    if(widget is! ${className}Page) return;
  }

  @override
  void didChangeDependencies(BuildContext context) {
    super.didChangeDependencies(context);
  }

  @override
  void didUpdateWidget<Page>(
      BuildContext context, Page oldWidget, Page widget) {
    if (oldWidget is! ${className}Page || widget is! ${className}Page) return;
  }

  @override
  List<BlocProvider> blocProviders(BuildContext context) => [];

  @override
  List<BlocListener> blocListeners(BuildContext context) => [];

  @override
  void dispose() {
    super.dispose();
  }
}''');

    StatusHelper.generated(join(path, '${pageName}_cubit.dart'));
  }

  void createPresentationPage(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'presentation', 'pages');
    DirectoryHelper.createDir(path, recursive: true);
    join(path, '${pageName}_page.dart')
        .write('''import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../cubit/${pageName}_cubit.dart';

class ${className}Page extends StatefulWidget {
  const ${className}Page({Key? key}) : super(key: key);

  @override
  State<${className}Page> createState() => _${className}PageState();
}

class _${className}PageState extends State<${className}Page>
    with MorphemeStatePage<${className}Page, ${className}Cubit> {
  @override
  ${className}Cubit setCubit() => locator<${className}Cubit>();

  @override
  Widget buildWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: Container(),
    );
  }
}''');

    StatusHelper.generated(join(path, '${pageName}_page.dart'));
  }

  void createPresentationWidget(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathPage, 'presentation', 'widgets');
    generateGitKeep(path);
  }

  void createLocator(
    String pathPage,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = pathPage;
    DirectoryHelper.createDir(path, recursive: true);
    join(path, 'locator.dart').write('''import 'package:core/core.dart';

import 'presentation/cubit/${pageName}_cubit.dart';

void setupLocator$className() {
  // *Cubit
  locator.registerFactory(() => ${className}Cubit());
}''');

    StatusHelper.generated(join(path, 'locator.dart'));
  }

  void appendLocatorFeature(
    String pathFeature,
    String featureName,
    String pageName,
    String className,
    String methodName,
  ) {
    final path = join(pathFeature, 'lib');
    String data = File(join(path, 'locator.dart')).readAsStringSync();

    data = data.replaceAll(RegExp(r'\n?void\s\w+\(\)\s{', multiLine: true),
        '''import '$pageName/locator.dart';

void setupLocatorFeature${featureName.pascalCase}() {''');

    data = data.replaceAll(
        RegExp(r'}\n$', multiLine: true), '''  setupLocator$className();
}''');

    join(path, 'locator.dart').write(data);

    StatusHelper.generated(join(path, 'locator.dart'));
  }
}
