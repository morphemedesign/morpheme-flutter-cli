import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/generate/page/models/page_config.dart';

/// Service for generating presentation layer components for pages.
///
/// This service handles the creation of all presentation layer components
/// for a new page, including BLoC, Cubit, pages, and widgets.
class PresentationLayerGenerationService {
  /// Creates all presentation layer components for the page.
  ///
  /// Generates directories and implementation files for:
  /// - BLoC components
  /// - Cubit components
  /// - Page widgets
  /// - Custom widgets
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void createPresentationLayer(PageConfig config) {
    _createPresentationBloc(config);
    _createPresentationCubit(config);
    _createPresentationPage(config);
    _createPresentationWidget(config);
  }

  /// Generates a .gitkeep file in the specified directory.
  ///
  /// Creates the directory if it doesn't exist and adds a .gitkeep
  /// file to ensure the directory is tracked by Git.
  ///
  /// Parameters:
  /// - [path]: Path to the directory where .gitkeep should be created
  void _generateGitKeep(String path) {
    createDir(path);
    touch(join(path, '.gitkeep'), create: true);
    StatusHelper.generated(join(path, '.gitkeep'));
  }

  /// Creates the BLoC directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createPresentationBloc(PageConfig config) {
    final path = join(config.pathPage, 'presentation', 'bloc');
    _generateGitKeep(path);
  }

  /// Creates the Cubit implementation files.
  ///
  /// Generates both the main Cubit file and the state file with
  /// complete implementation following Morpheme patterns.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createPresentationCubit(PageConfig config) {
    final path = join(config.pathPage, 'presentation', 'cubit');
    createDir(path);

    // Generate state file
    join(path, '${config.pageName}_state.dart')
        .write('''part of '${config.pageName}_cubit.dart';

class ${config.className}StateCubit extends Equatable {
  @override
  List<Object?> get props => [];
}''');

    // Generate main cubit file
    join(path, '${config.pageName}_cubit.dart')
        .write('''import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../pages/${config.pageName}_page.dart';

part '${config.pageName}_state.dart';

class ${config.className}Cubit extends MorphemeCubit<${config.className}StateCubit> {
  ${config.className}Cubit() : super(${config.className}StateCubit());

  @override
  void initState(BuildContext context) {
    super.initState(context);
  }

  @override
  void initAfterFirstLayout(BuildContext context) {
    super.initAfterFirstLayout(context);
  }

  @override
  void initArgument<T>(BuildContext context, T widget) {
    super.initArgument(context, widget);
    if(widget is! ${config.className}Page) return;
  }

  @override
  void didChangeDependencies(BuildContext context) {
    super.didChangeDependencies(context);
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

    StatusHelper.generated(join(path, '${config.pageName}_cubit.dart'));
  }

  /// Creates the page widget implementation file.
  ///
  /// Generates a complete page widget with state management
  /// following Morpheme patterns.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createPresentationPage(PageConfig config) {
    final path = join(config.pathPage, 'presentation', 'pages');
    createDir(path);

    join(path, '${config.pageName}_page.dart')
        .write('''import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../cubit/${config.pageName}_cubit.dart';

class ${config.className}Page extends StatefulWidget {
  const ${config.className}Page({super.key});

  @override
  State<${config.className}Page> createState() => _${config.className}PageState();
}

class _${config.className}PageState extends State<${config.className}Page>
    with MorphemeStatePage<${config.className}Page, ${config.className}Cubit> {
  @override
  ${config.className}Cubit setCubit() => locator<${config.className}Cubit>();

  @override
  Widget buildWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${config.className}')),
      body: Container(),
    );
  }
}''');

    StatusHelper.generated(join(path, '${config.pageName}_page.dart'));
  }

  /// Creates the widgets directory with a .gitkeep file.
  ///
  /// Parameters:
  /// - [config]: Configuration containing generation parameters
  void _createPresentationWidget(PageConfig config) {
    final path = join(config.pathPage, 'presentation', 'widgets');
    _generateGitKeep(path);
  }
}
