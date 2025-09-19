import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

import '../models/json2dart_config.dart';
import '../services/file_operation_service.dart';
import 'page_processor.dart';

/// Processes features within the Json2Dart generation workflow
///
/// This processor handles individual feature processing, including
/// page generation, cleanup, and file management for each feature.
class FeatureProcessor {
  final PageProcessor _pageProcessor;
  final FileOperationService _fileService;
  final bool _verbose;

  FeatureProcessor({
    required PageProcessor pageProcessor,
    required FileOperationService fileService,
    bool verbose = false,
  })  : _pageProcessor = pageProcessor,
        _fileService = fileService,
        _verbose = verbose;

  /// Processes a single feature
  ///
  /// [featurePath] - Path to the feature directory
  /// [featureName] - Name of the feature
  /// [featureConfig] - Configuration for the feature
  /// [globalConfig] - Global configuration settings
  /// [projectName] - Name of the project
  /// Returns true if successful, false otherwise
  Future<bool> processFeature({
    required String featurePath,
    required String featureName,
    required dynamic featureConfig,
    required Json2DartConfig globalConfig,
    required String projectName,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success(
            'Processing feature: $featureName at $featurePath');
      }

      // Validate feature directory exists
      if (!exists(featurePath)) {
        StatusHelper.warning('Feature directory not found: $featurePath');
        return false;
      }

      // Validate feature configuration
      if (featureConfig is! Map) {
        StatusHelper.warning('Invalid feature configuration for: $featureName');
        return false;
      }

      final featureMap = Map<String, dynamic>.from(featureConfig);

      // Process specific page if requested
      if (globalConfig.pageName != null) {
        return await _processSpecificPage(
          featurePath,
          featureName,
          featureMap,
          globalConfig,
          projectName,
        );
      }

      // Process all pages in the feature
      bool allSuccessful = true;
      final pageProcessInfo = <String, List<String>>{}; // pageName -> apiNames
      for (final entry in featureMap.entries) {
        final pageName = entry.key;
        final pageConfig = entry.value;

        // Extract API names for this page (these become blocs)
        final apiNames = <String>[];
        if (pageConfig is Map) {
          apiNames.addAll(pageConfig.keys.cast<String>());
        }
        pageProcessInfo[pageName] = apiNames;

        final success = await _pageProcessor.processPage(
          featurePath: featurePath,
          featureName: featureName,
          pageName: pageName,
          pageConfig: pageConfig,
          globalConfig: globalConfig,
          projectName: projectName,
        );

        if (!success) {
          allSuccessful = false;
          StatusHelper.failed(
              'Failed to process page: $pageName in feature: $featureName');
          // Continue processing other pages
        }
      }

      // Update cubit for each page if needed
      if (globalConfig.isCubit) {
        for (final entry in pageProcessInfo.entries) {
          final pageName = entry.key;
          final apiNames = entry.value;
          _updatePresentationCubit(
            featureName,
            featurePath,
            pageName,
            apiNames,
          );
        }
      }

      if (_verbose && allSuccessful) {
        StatusHelper.success('Successfully processed feature: $featureName');
      }

      return allSuccessful;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error processing feature $featureName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Processes a specific page within a feature
  Future<bool> _processSpecificPage(
    String featurePath,
    String featureName,
    Map<String, dynamic> featureMap,
    Json2DartConfig globalConfig,
    String projectName,
  ) async {
    final pageName = globalConfig.pageName!;

    if (!featureMap.containsKey(pageName)) {
      StatusHelper.warning('Page $pageName not found in feature $featureName');
      return false;
    }

    final pageConfig = featureMap[pageName];

    // Extract API names for this page (these become blocs)
    final apiNames = <String>[];
    if (pageConfig is Map) {
      apiNames.addAll(pageConfig.keys.cast<String>());
    }

    final success = await _pageProcessor.processPage(
      featurePath: featurePath,
      featureName: featureName,
      pageName: pageName,
      pageConfig: pageConfig,
      globalConfig: globalConfig,
      projectName: projectName,
    );

    // Update cubit only for this specific page if needed
    if (success && globalConfig.isCubit) {
      _updatePresentationCubit(
        featureName,
        featurePath,
        pageName,
        apiNames,
      );
    }

    return success;
  }

  /// Updates presentation cubit with bloc providers and listeners
  void _updatePresentationCubit(
    String featureName,
    String featurePath,
    String pageName,
    List<String> blocsName, // API names that become blocs
  ) {
    try {
      if (_verbose) {
        StatusHelper.success(
            'Updating presentation cubit for page: $pageName in feature: $featureName');
      }

      final pagePath = join(featurePath, 'lib', pageName);
      final cubitPath = join(
        pagePath,
        'presentation',
        'cubit',
        '${pageName.snakeCase}_cubit.dart',
      );

      if (_fileService.fileExists(cubitPath)) {
        _updateCubitFile(featureName, pageName, cubitPath, blocsName);
      }
    } catch (e) {
      StatusHelper.warning('Failed to update presentation cubit: $e');
    }
  }

  /// Updates a specific cubit file with bloc providers and listeners
  void _updateCubitFile(
    String featureName,
    String pageName,
    String cubitPath,
    List<String> blocsName,
  ) {
    try {
      String cubit = _fileService.readFileContent(cubitPath);
      if (cubit.isEmpty) return;

      // Add imports
      for (final blocName in blocsName) {
        final importStatement =
            'import \'package:${featureName.snakeCase}/${pageName.snakeCase}/presentation/bloc/${blocName.snakeCase}/${blocName.snakeCase}_bloc.dart\';';

        if (!cubit.contains(RegExp(
            'import\\s*\'package:${featureName.snakeCase}/${pageName.snakeCase}/presentation/bloc/${blocName.snakeCase}/${blocName.snakeCase}_bloc.dart\';'))) {
          cubit = '$importStatement\n$cubit';
        }
      }

      // Update constructor
      cubit = _updateCubitConstructor(cubit, pageName, blocsName);

      // Update variables
      cubit = _updateCubitVariables(cubit, pageName, blocsName);

      // Update bloc providers
      cubit = _updateBlocProviders(cubit, blocsName);

      // Update bloc listeners
      cubit = _updateBlocListeners(cubit, blocsName);

      // Update dispose method
      cubit = _updateDisposeMethod(cubit, blocsName);

      _fileService.writeFileContent(cubitPath, cubit);

      if (_verbose) {
        StatusHelper.success('Updated cubit file: $cubitPath');
      }
    } catch (e) {
      StatusHelper.warning('Failed to update cubit file $cubitPath: $e');
    }
  }

  /// Updates cubit constructor with bloc dependencies
  String _updateCubitConstructor(
      String cubit, String pageName, List<String> blocsName) {
    final constructorPattern =
        '${pageName.pascalCase}Cubit\\({[\\s\\w\\.\\,\\d]+}\\)';
    final newConstructor = '''${pageName.pascalCase}Cubit({
${blocsName.isEmpty ? '' : blocsName.map((e) => '    required this.${e.camelCase}Bloc,').join('\n')}
  })''';

    return cubit.replaceAll(RegExp(constructorPattern), newConstructor);
  }

  /// Updates cubit variables with bloc instances
  String _updateCubitVariables(
      String cubit, String pageName, List<String> blocsName) {
    final constructorRegex = RegExp(
      '(${pageName.pascalCase}Cubit\\s*\\([\\s\\S]*?\\)\\s*:\\s*super\\([\\s\\S]*?\\);)',
      multiLine: true,
    );

    final newVariables = blocsName
        .map((e) {
          if (cubit.contains(
            RegExp('final\\s*${e.pascalCase}Bloc\\s*${e.camelCase}Bloc\\s*;'),
          )) {
            return '';
          }
          return '  final ${e.pascalCase}Bloc ${e.camelCase}Bloc;';
        })
        .where((v) => v.isNotEmpty)
        .join('\n');

    if (newVariables.isNotEmpty) {
      cubit = cubit.replaceFirstMapped(constructorRegex, (match) {
        final matchedConstructor = match.group(1)!;
        return '$matchedConstructor\n\n$newVariables';
      });
    }

    return cubit;
  }

  /// Updates bloc providers in the cubit
  String _updateBlocProviders(String cubit, List<String> blocsName) {
    final blocProvidersRegex = RegExp(
      r'List<\w+>\s*blocProviders\s*\([\s\S]*?\)\s*(?:=>|{\s*return)\s*\[([\s\S]*?)\];\s*\}?',
      multiLine: true,
    );

    if (cubit.contains(blocProvidersRegex)) {
      cubit = cubit.replaceFirstMapped(blocProvidersRegex, (match) {
        String arrayContent = match.group(1)!.trim();

        for (final blocName in blocsName.reversed) {
          if (!arrayContent.contains(RegExp('${blocName.camelCase}Bloc'))) {
            arrayContent =
                '$arrayContent\n        BlocProvider<${blocName.pascalCase}Bloc>.value(value: ${blocName.camelCase}Bloc,),';
          }
        }

        return '''List<BlocProvider> blocProviders(BuildContext context) => [
  $arrayContent
        ];''';
      });
    } else {
      // Add bloc providers if not exists
      final providers = blocsName
          .map((e) =>
              '        BlocProvider<${e.pascalCase}Bloc>.value(value: ${e.camelCase}Bloc,)')
          .join('\n');

      cubit = cubit.replaceAll(
        RegExp(r'\}(?![\s\S]*\})', multiLine: true),
        '''  @override
  List<BlocProvider> blocProviders(BuildContext context) => [
$providers
      ];
  }''',
      );
    }

    return cubit;
  }

  /// Updates bloc listeners in the cubit
  String _updateBlocListeners(String cubit, List<String> blocsName) {
    final blocListenerRegex = RegExp(
      r'List<\w+>\s*blocListeners\s*\([\s\S]*?\)\s*(?:=>|{\s*return)\s*\[([\s\S]*?)\];\s*\}?',
      multiLine: true,
    );

    if (cubit.contains(blocListenerRegex)) {
      cubit = cubit.replaceFirstMapped(blocListenerRegex, (match) {
        String arrayContent = match.group(1)!.trim();

        for (final blocName in blocsName.reversed) {
          if (!arrayContent.contains(RegExp('${blocName.pascalCase}Bloc'))) {
            arrayContent =
                '$arrayContent\n        BlocListener<${blocName.pascalCase}Bloc, ${blocName.pascalCase}State>(listener: listener${blocName.pascalCase}Bloc,),';
          }
        }

        return '''List<BlocListener> blocListeners(BuildContext context) => [
  $arrayContent
        ];''';
      });

      for (final blocName in blocsName.reversed) {
        if (!cubit
            .contains(RegExp('void\\s*listener${blocName.pascalCase}Bloc'))) {
          cubit = cubit.replaceAll(
            RegExp(r'\}(?![\s\S]*\})', multiLine: true),
            '''  void listener${blocName.pascalCase}Bloc(BuildContext context, ${blocName.pascalCase}State state) {
    state.when(
      onFailed: (state) {
        // handle failed state
      },
      onSuccess: (state) {
        // handle success state
      },
    );
  }
}''',
          );
        }
      }
    } else {
      // Add bloc listeners if not exists
      final listeners = blocsName
          .map((e) =>
              '        BlocListener<${e.pascalCase}Bloc, ${e.pascalCase}State>(listener: listener${e.pascalCase}Bloc,)')
          .join('\n');

      cubit = cubit.replaceAll(
        RegExp(r'\}(?![\s\S]*\})', multiLine: true),
        '''  @override
  List<BlocListener> blocListeners(BuildContext context) => [
$listeners
      ];
  
  ${blocsName.map(
              (e) =>
                  '''  void listener${e.pascalCase}Bloc(BuildContext context, ${e.pascalCase}State state) {
    state.when(
      onFailed: (state) {
        // handle failed state
      },
      onSuccess: (state) {
        // handle success state
      },
    );
  }''',
            ).join('\n')}
}''',
      );
    }

    return cubit;
  }

  /// Updates dispose method in the cubit
  String _updateDisposeMethod(String cubit, List<String> blocsName) {
    final disposeRegex = RegExp(
      r'(Future<)?void(>)?\s*dispose\s*\(\s*\)\s*(async\s*)?\{([\s\S]*?)\}',
      multiLine: true,
    );

    if (cubit.contains(disposeRegex)) {
      cubit = cubit.replaceFirstMapped(disposeRegex, (match) {
        String arrayContent = match.group(4)!.trim();

        for (final blocName in blocsName.reversed) {
          if (!arrayContent.contains(RegExp('${blocName.camelCase}Bloc'))) {
            arrayContent =
                '    ${blocName.camelCase}Bloc.close();\n$arrayContent';
          }
        }

        return '''void dispose() {
  $arrayContent
  }''';
      });
    } else {
      // Add dispose method if not exists
      final disposeCalls =
          blocsName.map((e) => '    ${e.camelCase}Bloc.close();').join('\n');

      cubit = cubit.replaceAll(
        RegExp(r'\}(?![\s\S]*\})', multiLine: true),
        '''  @override
  void dispose() {
$disposeCalls
    super.dispose();
  }
}''',
      );
    }

    return cubit;
  }
}
