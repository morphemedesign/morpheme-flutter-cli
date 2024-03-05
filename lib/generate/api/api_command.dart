import 'dart:io';

import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/directory_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

class ApiCommand extends Command {
  ApiCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Name of the feature to be added api',
      mandatory: true,
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Name of the page to be added api',
      mandatory: true,
    );
    argParser.addFlag(
      'json2dart',
      help: 'Generate models handle by json2dart',
      defaultsTo: false,
    );
    argParser.addOption(
      'method',
      abbr: 'm',
      allowed: ['get', 'post', 'put', 'patch', 'delete', 'multipart'],
      defaultsTo: 'post',
    );
    argParser.addOption('path');
    argParser.addOption(
      'header',
      help: 'path file json additional header fetch api',
    );
    argParser.addFlag(
      'body-list',
      help: 'body for api is list',
      defaultsTo: false,
    );
    argParser.addFlag(
      'response-list',
      help: 'response for api is list',
      defaultsTo: false,
    );
    argParser.addOption(
      'cache-strategy',
      help: 'Strategy for caching response api',
      allowed: ['async_or_cache', 'cache_or_async', 'just_async', 'just_cache'],
    );
    argParser.addOption(
      'ttl',
      help: 'Duration of expired cache in cache strategy in minutes',
    );
    argParser.addOption(
      'keep-expired-cache',
      help: 'Keep cache without expired.',
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate spesific apps (Optional)',
    );
  }

  @override
  String get name => 'api';

  @override
  String get description => 'Create a new api in page.';

  @override
  String get category => Constants.generate;

  String projectName = '';

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      StatusHelper.failed(
          'Api name is empty, add a new api with "morpheme api <api-name> -f <feature-name> -p <page-name>"');
    }

    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    projectName = YamlHelper.loadFileYaml(argMorphemeYaml).projectName;

    final appsName = argResults?['apps-name'] as String?;
    final featureName =
        (argResults?['feature-name'] as String? ?? '').snakeCase;
    final pageName = (argResults?['page-name'] as String? ?? '').snakeCase;
    final bool json2dart = argResults?['json2dart'] ?? false;
    final String method = argResults?['method'] as String? ?? 'post';
    final String? pathUrl = argResults?['path'];
    final String? header = argResults?['header'];
    final bool bodyList =
        (argResults?['body-list'] ?? false) && method != 'multipart';
    final bool responseList = argResults?['response-list'] ?? false;

    final CacheStrategy? cacheStrategy = argResults?['cache-strategy'] == null
        ? null
        : CacheStrategy.fromString(argResults?['cache-strategy']);
    final int? ttl = int.tryParse(argResults?['ttl'] ?? '');
    final bool? keepExpiredCache = argResults?['keep-expired-cache'] == null
        ? null
        : argResults?['keep-expired-cache'] == 'true';

    String pathFeature = join(current, 'features', featureName);
    if (appsName != null) {
      pathFeature = join(current, 'apps', appsName, 'features', featureName);
    }

    if (!exists(pathFeature)) {
      StatusHelper.failed(
          'Feature with "$featureName" does not exists, create a new feature with "morpheme feature <feature-name>"');
    }

    String pathPage = join(pathFeature, 'lib', pageName);

    if (!exists(pathPage)) {
      StatusHelper.failed(
          'Page with "$pageName" does not exists, create a new page with "morpheme page <page-name> -f <feature-name>"');
    }

    final apiName = (argResults?.rest.first ?? '').snakeCase;

    createLocator(pathPage, pageName, apiName);

    createDataDataSource(
      pathPage,
      appsName ?? '',
      pageName,
      apiName,
      method,
      pathUrl,
      header,
      bodyList,
      responseList,
      cacheStrategy,
      ttl,
      keepExpiredCache,
    );
    if (!json2dart) createDataModelBody(pathPage, pageName, apiName, bodyList);
    if (!json2dart) createDataModelResponse(pathPage, pageName, apiName);
    createDataRepository(pathPage, pageName, apiName, bodyList, responseList);
    if (!json2dart) createDomainEntity(pathPage, pageName, apiName);
    createDomainRepository(pathPage, pageName, apiName, bodyList, responseList);
    createDomainUseCase(pathPage, pageName, apiName, bodyList, responseList);
    createPresentationBloc(pathPage, pageName, apiName, bodyList, responseList);
    if (!json2dart) createMapper(pathPage, pageName, apiName);

    createPostLocator(pathPage, pageName, apiName);

    if (!json2dart) await ModularHelper.format();

    if (!json2dart) {
      StatusHelper.success('generate $apiName in $featureName/$pageName');
    }
  }

  String getBodyClass(String apiClassName, bool bodyList) {
    if (bodyList) {
      return 'List<${apiClassName}Body>';
    } else {
      return '${apiClassName}Body';
    }
  }

  String getResponseClass(String apiClassName, bool responseList) {
    if (responseList) {
      return 'List<${apiClassName}Response>';
    } else {
      return '${apiClassName}Response';
    }
  }

  String getEntityClass(String apiClassName, bool responseList) {
    if (responseList) {
      return 'List<${apiClassName}Entity>';
    } else {
      return '${apiClassName}Entity';
    }
  }

  void createDataDataSource(
    String pathPage,
    String appsName,
    String pageName,
    String apiName,
    String method,
    String? pathUrl,
    String? pathHeader,
    bool bodyList,
    bool responseList,
    CacheStrategy? cacheStrategy,
    int? ttl,
    bool? keepExpiredCache,
  ) {
    final paramPath = <String>[];
    parse(pathUrl ?? '', parameters: paramPath);

    final pageClassName = pageName.pascalCase;
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'data', 'datasources');
    DirectoryHelper.createDir(path, recursive: true);

    String? headers;
    if (pathHeader != null && exists(pathHeader)) {
      try {
        headers = File(pathHeader).readAsStringSync();
      } catch (e) {
        StatusHelper.warning(e.toString());
      }
    }

    if (headers != null) {
      headers =
          'headers: $headers.map((key, value) => MapEntry(key, value.toString()))..addAll(headers ?? {}),';
    }

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final bodyImpl = bodyList
        ? 'body: jsonEncode(body.map((e) => e.toMap()).toList()),'
        : 'body: body.toMap()${method == 'multipart' ? '.map((key, value) => MapEntry(key, value.toString()))' : ''},${method == 'multipart' ? ' files: body.files,' : ''}';

    final responseClass = getResponseClass(apiClassName, responseList);
    final responseImpl = responseList
        ? '''final mapResponse = jsonDecode(response.body);
    return mapResponse is List
        ? List.from(mapResponse.map((e) => ${apiClassName}Response.fromMap(e)))
        : [${apiClassName}Response.fromMap(mapResponse)];'''
        : 'return ${apiClassName}Response.fromJson(response.body);';

    final convert =
        bodyList || responseList ? "import 'dart:convert';\n\n" : '';

    final apiMethod = method == 'multipart' ? 'postMultipart' : method;
    final apiEndpoint = paramPath.isEmpty
        ? '${projectName.pascalCase}Endpoints.$apiMethodName${appsName.pascalCase}'
        : '${projectName.pascalCase}Endpoints.$apiMethodName${appsName.pascalCase}(${paramPath.map((e) => 'body.${e.camelCase}').join(',')})';
    final apiCacheStrategy = cacheStrategy == null
        ? ''
        : '${cacheStrategy.toParamCacheStrategy(ttl: ttl, keepExpiredCache: keepExpiredCache)},';

    if (!exists(join(path, '${pageName}_remote_data_source.dart'))) {
      join(path, '${pageName}_remote_data_source.dart')
          .write('''${convert}import 'package:core/core.dart';

import '../models/body/${apiName}_body.dart';
import '../models/response/${apiName}_response.dart';

abstract class ${pageName.pascalCase}RemoteDataSource {
  Future<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}

class ${pageName.pascalCase}RemoteDataSourceImpl implements ${pageName.pascalCase}RemoteDataSource {
  ${pageName.pascalCase}RemoteDataSourceImpl({required this.http});

  final MorphemeHttp http;

  @override
  Future<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    final response = await http.$apiMethod($apiEndpoint, $bodyImpl${headers ?? 'headers: headers,'}$apiCacheStrategy);
    $responseImpl
  }
}''');
    } else {
      String data = File(join(path, '${pageName}_remote_data_source.dart'))
          .readAsStringSync();

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';
    
import '../models/body/${apiName}_body.dart';
import '../models/response/${apiName}_response.dart';''');

      data = data.replaceAll(
          RegExp('abstract\\s?class\\s?${pageClassName}RemoteDataSource\\s?{',
              multiLine: true),
          '''abstract class ${pageClassName}RemoteDataSource {
  Future<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,});''');

      final isEmpty =
          RegExp(r'final MorphemeHttp http;(\s+)?}(\s+)?}').hasMatch(data);

      data = data.replaceAll(RegExp(r'}(\s+)?}'), '''${isEmpty ? '' : '}'}

  @override
  Future<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    final response = await http.$apiMethod($apiEndpoint, $bodyImpl${headers ?? 'headers: headers,'}$apiCacheStrategy);
    $responseImpl
  }
}''');

      join(path, '${pageName}_remote_data_source.dart').write(data);
    }
    StatusHelper.generated(join(path, '${pageName}_remote_data_source.dart'));
  }

  void createDataModelBody(
    String pathPage,
    String pageName,
    String apiName,
    bool bodyList,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = join(pathPage, 'data', 'models', 'body');
    DirectoryHelper.createDir(path, recursive: true);

    join(path, '${apiName}_body.dart').write('''import 'package:core/core.dart';

class ${apiClassName}Body extends Equatable {
  const ${apiClassName}Body({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [email, password];
}''');

    StatusHelper.generated(join(path, '${apiName}_body.dart'));
  }

  void createDataModelResponse(
    String pathPage,
    String pageName,
    String apiName,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = join(pathPage, 'data', 'models', 'response');
    DirectoryHelper.createDir(path, recursive: true);
    join(path, '${apiName}_response.dart').write('''import 'dart:convert';

import 'package:core/core.dart';

class ${apiClassName}Response extends Equatable {
  const ${apiClassName}Response({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toMap() {
    return {
      'token': token,
    };
  }

  factory ${apiClassName}Response.fromMap(Map<String, dynamic> map) {
    return ${apiClassName}Response(
      token: map['token'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ${apiClassName}Response.fromJson(String source) =>
      ${apiClassName}Response.fromMap(json.decode(source));

  @override
  List<Object?> get props => [token];
}''');

    StatusHelper.generated(join(path, '${apiName}_response.dart'));
  }

  void createDataRepository(
    String pathPage,
    String pageName,
    String apiName,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'data', 'repositories');
    DirectoryHelper.createDir(path, recursive: true);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    final entityImpl = responseList
        ? 'data.map((e) => e.toEntity()).toList()'
        : 'data.toEntity()';

    if (!exists(join(path, '${pageName}_repository_impl.dart'))) {
      join(path, '${pageName}_repository_impl.dart')
          .write('''import 'package:core/core.dart';

import '../../domain/entities/${apiName}_entity.dart';
import '../../domain/repositories/${pageName}_repository.dart';
import '../datasources/${pageName}_remote_data_source.dart';
import '../models/body/${apiName}_body.dart';
import '../../mapper.dart';

class ${pageName.pascalCase}RepositoryImpl implements ${pageName.pascalCase}Repository {
  ${pageName.pascalCase}RepositoryImpl({
    required this.remoteDataSource,
  });

  final ${pageName.pascalCase}RemoteDataSource remoteDataSource;

  @override
  Future<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    try {
      final data = await remoteDataSource.$apiMethodName(body, headers: headers);
      return Right($entityImpl);
    } on MorphemeException catch (e) {
      return Left(e.toMorphemeFailure());
    } catch (e) {
      return Left(InternalFailure(e.toString()));
    }
  }
}''');
    } else {
      String data = File(join(path, '${pageName}_repository_impl.dart'))
          .readAsStringSync();

      final isDataDatasourceAlready =
          RegExp(r'remote_data_source\.dart').hasMatch(data);
      final isDomainRepositoryAlready =
          RegExp(r'repository\.dart').hasMatch(data);

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';
          
${isDataDatasourceAlready ? '' : "import '../datasources/${pageName}_remote_data_source.dart';"}
${isDomainRepositoryAlready ? '' : "import '../../domain/repositories/${pageName}_repository.dart';"}
import '../../domain/entities/${apiName}_entity.dart';
import '../models/body/${apiName}_body.dart';''');

      final isEmpty = RegExp(r'remoteDataSource;(\s+)?}(\s+)?}').hasMatch(data);

      data =
          data.replaceAll(RegExp(r'}(\s+)?}(\s+)?}'), '''${isEmpty ? '' : '}}'}

  @override
  Future<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    try {
        final data = await remoteDataSource.$apiMethodName(body, headers: headers);
        return Right($entityImpl);
    } on MorphemeException catch (e) {
        return Left(e.toMorphemeFailure());
    } catch (e) {
        return Left(InternalFailure(e.toString()));
    }
  }
}''');

      join(path, '${pageName}_repository_impl.dart').write(data);
    }

    StatusHelper.generated(join(path, '${pageName}_repository_impl.dart'));
  }

  void createDomainEntity(
    String pathPage,
    String pageName,
    String apiName,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = join(pathPage, 'domain', 'entities');
    DirectoryHelper.createDir(path, recursive: true);
    join(path, '${apiName}_entity.dart')
        .write('''import 'package:core/core.dart';

class ${apiClassName}Entity extends Equatable {
  const ${apiClassName}Entity({
    required this.token,
  });
  final String token;

  @override
  List<Object?> get props => [token];
}''');

    StatusHelper.generated(join(path, '${apiName}_entity.dart'));
  }

  void createDomainRepository(
    String pathPage,
    String pageName,
    String apiName,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'domain', 'repositories');
    DirectoryHelper.createDir(path, recursive: true);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    if (!exists(join(path, '${pageName}_repository.dart'))) {
      join(path, '${pageName}_repository.dart')
          .write('''import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
import '../entities/${apiName}_entity.dart';

abstract class ${pageName.pascalCase}Repository {
  Future<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}''');
    } else {
      String data =
          File(join(path, '${pageName}_repository.dart')).readAsStringSync();

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
import '../entities/${apiName}_entity.dart';''');

      data = data.replaceAll(RegExp(r'}$', multiLine: true),
          '''  Future<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}''');

      join(path, '${pageName}_repository.dart').write(data);
    }

    StatusHelper.generated(join(path, '${pageName}_repository.dart'));
  }

  void createDomainUseCase(
    String pathPage,
    String pageName,
    String apiName,
    bool bodyList,
    bool responseList,
  ) {
    final pageClassName = pageName.pascalCase;
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'domain', 'usecases');
    DirectoryHelper.createDir(path, recursive: true);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    join(path, '${apiName}_use_case.dart')
        .write('''import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
import '../entities/${apiName}_entity.dart';
import '../repositories/${pageName}_repository.dart';

class ${apiClassName}UseCase implements UseCase<$entityClass, $bodyClass> {
  ${apiClassName}UseCase({
    required this.repository,
  });

  final ${pageClassName}Repository repository;

  @override
  Future<Either<MorphemeFailure, $entityClass>> call($bodyClass body,{Map<String, String>? headers,}) {
    return repository.$apiMethodName(body, headers: headers);
  }
}''');

    StatusHelper.generated(join(path, '${apiName}_use_case.dart'));
  }

  void createPresentationBloc(
    String pathPage,
    String pageName,
    String apiName,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = join(pathPage, 'presentation', 'bloc', apiName);
    DirectoryHelper.createDir(path, recursive: true);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    join(path, '${apiName}_state.dart').write('''part of '${apiName}_bloc.dart';

@immutable
abstract class ${apiClassName}State extends Equatable {
  void when({
    void Function(${apiClassName}Initial state)? onInitial,
    void Function(${apiClassName}Loading state)? onLoading,
    void Function(${apiClassName}Failed state)? onFailed,
    void Function(${apiClassName}Success state)? onSuccess,
  }) {
    final state = this;
    if (state is ${apiClassName}Initial) {
      onInitial?.call(state);
    } else if (state is ${apiClassName}Loading) {
      onLoading?.call(state);
    } else if (state is ${apiClassName}Failed) {
      onFailed?.call(state);
    } else if (state is ${apiClassName}Success) {
      onSuccess?.call(state);
    }
  }

  Widget builder({
    Widget Function(${apiClassName}Initial state)? onInitial,
    Widget Function(${apiClassName}Loading state)? onLoading,
    Widget Function(${apiClassName}Failed state)? onFailed,
    Widget Function(${apiClassName}Success state)? onSuccess,
    Widget Function(${apiClassName}State state)? onStateBuilder,
  }) {
    final state = this;
    final defaultWidget = onStateBuilder?.call(this) ?? const SizedBox.shrink();

    if (state is ${apiClassName}Initial) {
      return onInitial?.call(state) ?? defaultWidget;
    } else if (state is ${apiClassName}Loading) {
      return onLoading?.call(state) ?? defaultWidget;
    } else if (state is ${apiClassName}Failed) {
      return onFailed?.call(state) ?? defaultWidget;
    } else if (state is ${apiClassName}Success) {
      return onSuccess?.call(state) ?? defaultWidget;
    } else {
      return defaultWidget;
    }
  }
}

class ${apiClassName}Initial extends ${apiClassName}State {
  @override
  List<Object?> get props => [];
}

class ${apiClassName}Loading extends ${apiClassName}State {
   ${apiClassName}Loading(this.body, this.headers, this.extra);

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, extra];
}

class ${apiClassName}Success extends ${apiClassName}State {
  ${apiClassName}Success(this.body, this.headers, this.data, this.extra);

  final $bodyClass body;
  final Map<String, String>? headers;
  final $entityClass data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra];
}

class ${apiClassName}Failed extends ${apiClassName}State {
  ${apiClassName}Failed(this.body, this.headers, this.failure, this.extra);

  final $bodyClass body;
  final Map<String, String>? headers;
  final MorphemeFailure failure;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, failure, extra];
}''');

    join(path, '${apiName}_event.dart').write('''part of '${apiName}_bloc.dart';

@immutable
abstract class ${apiClassName}Event extends Equatable {}

class Fetch$apiClassName extends ${apiClassName}Event {
  Fetch$apiClassName(this.body, {this.headers, this.extra});

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, extra];
}''');

    join(path, '${apiName}_bloc.dart').write('''import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../data/models/body/${apiName}_body.dart';
import '../../../domain/entities/${apiName}_entity.dart';
import '../../../domain/usecases/${apiName}_use_case.dart';

part '${apiName}_event.dart';
part '${apiName}_state.dart';

class ${apiClassName}Bloc extends Bloc<${apiClassName}Event, ${apiClassName}State> {
  final ${apiClassName}UseCase useCase;

  ${apiClassName}Bloc({
    required this.useCase,
  }) : super(${apiClassName}Initial()) {
    on<Fetch$apiClassName>((event, emit) async {
      emit(${apiClassName}Loading(event.body, event.headers, event.extra));
      final result = await useCase(event.body, headers: event.headers);
      emit(
        result.fold(
          (failure) => ${apiClassName}Failed(event.body, event.headers, failure, event.extra),
          (success) => ${apiClassName}Success(event.body, event.headers, success, event.extra),
        ),
      );
    });
  }
}''');

    StatusHelper.generated(join(path, '${apiName}_state.dart'));
    StatusHelper.generated(join(path, '${apiName}_event.dart'));
    StatusHelper.generated(join(path, '${apiName}_bloc.dart'));
  }

  void createLocator(
    String pathPage,
    String pageName,
    String apiName,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = pathPage;
    DirectoryHelper.createDir(path, recursive: true);

    if (!exists(join(path, 'locator.dart'))) {
      join(path, 'locator.dart').write('''import 'package:core/core.dart';

import 'presentation/cubit/${pageName.snakeCase}_cubit.dart';

void setupLocator${pageName.pascalCase}() {
  // *Cubit
  locator.registerFactory(() => ${pageName.pascalCase}Cubit());
}''');
    }

    String data = File(join(path, 'locator.dart')).readAsStringSync();

    final isDataDatasourceAlready =
        RegExp(r'remote_data_source\.dart').hasMatch(data);
    final isDataRepositoryAlready =
        RegExp(r'repository_impl\.dart').hasMatch(data);
    final isDomainRepositoryAlready =
        RegExp(r'repository\.dart').hasMatch(data);

    data = data.replaceAll(RegExp(r"import\s?'package:core\/core.dart';\n?\n?"),
        '''import 'package:core/core.dart';

${!isDataDatasourceAlready ? '''import 'data/datasources/${pageName}_remote_data_source.dart';''' : ''}
${!isDataRepositoryAlready ? '''import 'data/repositories/${pageName}_repository_impl.dart';''' : ''}
${!isDomainRepositoryAlready ? '''import 'domain/repositories/${pageName}_repository.dart';''' : ''}
import 'domain/usecases/${apiName}_use_case.dart';
import 'presentation/bloc/$apiName/${apiName}_bloc.dart';''');

    data = data.replaceAll(RegExp(r'}', multiLine: true), '''
  // *Bloc
  locator.registerFactory(() => ${apiClassName}Bloc(useCase: locator()));

  // *Usecase
  locator.registerLazySingleton(() => ${apiClassName}UseCase(repository: locator()));
  ${!isDataDatasourceAlready ? '''
  // *Repository
  locator.registerLazySingleton<${pageName.pascalCase}Repository>(
    () => ${pageName.pascalCase}RepositoryImpl(remoteDataSource: locator()),
  );''' : ''}
 ${!isDataRepositoryAlready && !isDomainRepositoryAlready ? '''
  // *Datasource
  locator.registerLazySingleton<${pageName.pascalCase}RemoteDataSource>(
    () => ${pageName.pascalCase}RemoteDataSourceImpl(http: locator()),
  );''' : ''}
}''');

    join(path, 'locator.dart').write(data);
  }

  void createPostLocator(String pathPage, String pageName, String apiName) {
    String data = File(join(pathPage, 'locator.dart')).readAsStringSync();

    final bloc = find(
      '*',
      recursive: false,
      includeHidden: false,
      workingDirectory: join(pathPage, 'presentation', 'bloc'),
      types: [Find.directory],
    )
        .toList()
        .map((e) =>
            '${e.replaceAll('${join(pathPage, 'presentation', 'bloc')}$separator', '').camelCase}Bloc: locator()')
        .join(',');

    data = data.replaceAll(
      RegExp(r"\w*Cubit\((([\w,:\s]*(\(\))?)+)?\)"),
      '${pageName.pascalCase}Cubit($bloc)',
    );

    join(pathPage, 'locator.dart').write(data);

    StatusHelper.generated(join(pathPage, 'locator.dart'));
  }

  void createMapper(
    String pathPage,
    String pageName,
    String apiName,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = pathPage;
    DirectoryHelper.createDir(path, recursive: true);

    if (!exists(join(path, 'mapper.dart'))) {
      join(path, 'mapper.dart')
          .write('''import 'data/models/response/${apiName}_response.dart';
import 'domain/entities/${apiName}_entity.dart';

extension ${apiClassName}ResponseMapper on ${apiClassName}Response {
  ${apiClassName}Entity toEntity() => ${apiClassName}Entity(token: token);
}

extension ${apiClassName}EntityMapper on ${apiClassName}Entity {
  ${apiClassName}Response toResponse() => ${apiClassName}Response(token: token);
}''');
    } else {
      String data = File(join(path, 'mapper.dart')).readAsStringSync();

      data = '''import 'data/models/response/${apiName}_response.dart';
import 'domain/entities/${apiName}_entity.dart';
$data''';

      data = '''$data

extension ${apiClassName}ResponseMapper on ${apiClassName}Response {
  ${apiClassName}Entity toEntity() => ${apiClassName}Entity(token: token);
}

extension ${apiClassName}EntityMapper on ${apiClassName}Entity {
  ${apiClassName}Response toResponse() => ${apiClassName}Response(token: token);
}''';

      join(path, 'mapper.dart').write(data);
    }

    StatusHelper.generated(join(path, 'mapper.dart'));
  }
}
