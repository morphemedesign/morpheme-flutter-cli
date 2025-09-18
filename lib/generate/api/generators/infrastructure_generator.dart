import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';
import '../templates/api_code_templates.dart';

/// Generates infrastructure components for dependency injection and data mapping.
///
/// Creates locator configuration for dependency injection and mapper extensions
/// for converting between data and domain layer objects.
class InfrastructureGenerator {
  InfrastructureGenerator({
    required this.typeResolver,
    required this.codeTemplates,
  });

  final ApiTypeResolver typeResolver;
  final ApiCodeTemplates codeTemplates;

  /// Generates complete infrastructure for the API.
  ///
  /// Components generated:
  /// - Dependency injection setup in locator
  /// - Data mapper extensions (if using model return data)
  void generateInfrastructure(ApiGenerationConfig config) {
    generateLocator(config);
    generatePostLocator(config);

    if (!config.json2dart && config.isReturnDataModel) {
      generateMapper(config);
    }
  }

  /// Generates or updates the locator configuration.
  ///
  /// Sets up dependency injection for all the generated components including
  /// data sources, repositories, use cases, and BLoCs.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateLocator(ApiGenerationConfig config) {
    final path = config.pathPage;
    createDir(path);

    final filePath = join(path, 'locator.dart');

    if (!exists(filePath)) {
      // Create new locator file
      _createNewLocatorFile(config, filePath);

      _updateExistingLocatorFile(config, filePath);
    } else {
      // Update existing locator file
      _updateExistingLocatorFile(config, filePath);
    }
  }

  /// Updates the locator with BLoC dependencies after all components are generated.
  ///
  /// This is called after all other components are generated to ensure the
  /// cubit constructor includes all necessary BLoC dependencies.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generatePostLocator(ApiGenerationConfig config) {
    final filePath = join(config.pathPage, 'locator.dart');
    String data = read(filePath).join('\n');

    // Find all BLoC directories and generate locator entries
    final blocDirs = <String>[];
    final blocPath = join(config.pathPage, 'presentation', 'bloc');

    if (exists(blocPath)) {
      final directories = find(
        '*',
        recursive: false,
        includeHidden: false,
        workingDirectory: blocPath,
        types: [Find.directory],
      ).toList();

      for (final dir in directories) {
        final blocName = dir.replaceAll('$blocPath$separator', '').camelCase;
        blocDirs.add('${blocName}Bloc: locator()');
      }
    }

    final blocEntries = blocDirs.join(',');

    // Update cubit constructor with BLoC dependencies
    data = data.replaceAll(
      RegExp(r'\w*Cubit\(([\w,:\s]*(\(\))?)*\)'),
      '${config.pageClassName}Cubit($blocEntries,)',
    );

    // Ensure proper closing brace
    data = data.replaceAll(RegExp(r';?\s*}', multiLine: true), ''';}''');

    // Use proper file handle management to avoid 'too many open files' error
    filePath.write(data);
    StatusHelper.generated(filePath);
  }

  /// Generates mapper extensions.
  ///
  /// Creates extension methods for converting between data models and
  /// domain entities, enabling clean separation between layers.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateMapper(ApiGenerationConfig config) {
    final path = config.pathPage;
    createDir(path);

    final filePath = join(path, 'mapper.dart');

    if (!exists(filePath)) {
      // Create new mapper file
      _createNewMapperFile(config, filePath);
    } else {
      // Update existing mapper file
      _updateExistingMapperFile(config, filePath);
    }

    StatusHelper.generated(filePath);
  }

  /// Creates a new locator file with basic structure
  void _createNewLocatorFile(ApiGenerationConfig config, String filePath) {
    filePath.write('''import 'package:core/core.dart';

import 'presentation/cubit/${config.pageName.snakeCase}_cubit.dart';

void setupLocator${config.pageClassName}() {
  // *Cubit
  locator..registerFactory(() => ${config.pageClassName}Cubit(),);
}''');
  }

  /// Updates an existing locator file with new dependencies
  void _updateExistingLocatorFile(ApiGenerationConfig config, String filePath) {
    String data = read(filePath).join('\n');

    final isDataDatasourceAlready =
        RegExp(r'remote_data_source\.dart').hasMatch(data);
    final isDataRepositoryAlready =
        RegExp(r'repository_impl\.dart').hasMatch(data);
    final isDomainRepositoryAlready =
        RegExp(r'repository\.dart').hasMatch(data);

    // Update imports
    data = data.replaceAll(RegExp(r"import\s*'package:core/core\.dart';\s*"),
        '''import 'package:core/core.dart';

${!isDataDatasourceAlready ? '''import 'data/datasources/${config.pageName}_remote_data_source.dart';''' : ''}
${!isDataRepositoryAlready ? '''import 'data/repositories/${config.pageName}_repository_impl.dart';''' : ''}
${!isDomainRepositoryAlready ? '''import 'domain/repositories/${config.pageName}_repository.dart';''' : ''}
import 'domain/usecases/${config.apiName}_use_case.dart';
import 'presentation/bloc/${config.apiName}/${config.apiName}_bloc.dart';''');

    // Add new registrations
    data = data.replaceAll(RegExp(r';\s*}', multiLine: true), '''

  // *Bloc
  ..registerFactory(() => ${config.apiClassName}Bloc(useCase: locator()),)

  // *Usecase
  ..registerLazySingleton(() => ${config.apiClassName}UseCase(repository: locator()),)
  ${!isDataDatasourceAlready ? '''
  // *Repository
  ..registerLazySingleton<${config.pageClassName}Repository>(
    () => ${config.pageClassName}RepositoryImpl(remoteDataSource: locator(),),
  )''' : ''}
 ${!isDataRepositoryAlready && !isDomainRepositoryAlready ? '''
  // *Datasource
  ..registerLazySingleton<${config.pageClassName}RemoteDataSource>(
    () => ${config.pageClassName}RemoteDataSourceImpl(http: locator(),),
  )''' : ''}
}''');

    filePath.write(data);
  }

  /// Creates a new mapper file
  void _createNewMapperFile(ApiGenerationConfig config, String filePath) {
    final content = codeTemplates.generateMapperTemplate(config);
    filePath.write(content);
  }

  /// Updates an existing mapper file with new extensions
  void _updateExistingMapperFile(ApiGenerationConfig config, String filePath) {
    String data = read(filePath).join('\n');

    // Add imports at the top
    data = '''import 'data/models/response/${config.apiName}_response.dart';
import 'domain/entities/${config.apiName}_entity.dart';
$data''';

    // Add new mapper extensions
    data = '''$data

extension ${config.apiClassName}ResponseMapper on ${config.apiClassName}Response {
  ${config.apiClassName}Entity toEntity() => ${config.apiClassName}Entity(token: token);
}

extension ${config.apiClassName}EntityMapper on ${config.apiClassName}Entity {
  ${config.apiClassName}Response toResponse() => ${config.apiClassName}Response(token: token);
}''';

    filePath.write(data);
  }
}
