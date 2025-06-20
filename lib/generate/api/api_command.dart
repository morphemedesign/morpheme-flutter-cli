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
      allowed: [
        'get',
        'post',
        'put',
        'patch',
        'delete',
        'multipart',
        'postMultipart',
        'patchMultipart',
        'head',
        'getSse',
        'postSse',
        'putSse',
        'patchSse',
        'deleteSse',
        'download',
      ],
      defaultsTo: 'post',
    );
    argParser.addOption('path');
    argParser.addOption(
      'header',
      help: 'path file json additional header fetch api',
    );
    argParser.addOption(
      'return-data',
      abbr: 'r',
      help:
          'Specify the type of data to return from the API response. Options include: model, header, body_bytes, body_string, status_code, and raw.',
      allowed: [
        'model',
        'header',
        'body_bytes',
        'body_string',
        'status_code',
        'raw',
      ],
      defaultsTo: 'model',
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
  String returnData = 'model';

  bool get isReturnDataModel => returnData == 'model';

  String flutterClassOfMethod(String method) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return 'Stream';
      default:
        return 'Future';
    }
  }

  String whenMethod(
    String method, {
    required String Function() onStream,
    required String Function() onFuture,
    // required String Function() onDownload,
  }) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return onStream();
      // case 'download':
      //   return onDownload();
      default:
        return onFuture();
    }
  }

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
    final bool bodyList = (argResults?['body-list'] ?? false) &&
        !method.toLowerCase().contains('multipart');
    final bool responseList = argResults?['response-list'] ?? false;

    final CacheStrategy? cacheStrategy = argResults?['cache-strategy'] == null
        ? null
        : CacheStrategy.fromString(argResults?['cache-strategy']);
    final int? ttl = int.tryParse(argResults?['ttl'] ?? '');
    final bool? keepExpiredCache = argResults?['keep-expired-cache'] == null
        ? null
        : argResults?['keep-expired-cache'] == 'true';
    returnData = argResults?['return-data'];

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
    if (!json2dart && isReturnDataModel) {
      createDataModelResponse(pathPage, pageName, apiName);
    }
    createDataRepository(
        pathPage, pageName, apiName, method, bodyList, responseList);
    if (!json2dart && isReturnDataModel) {
      createDomainEntity(pathPage, pageName, apiName);
    }
    createDomainRepository(
        pathPage, pageName, apiName, method, bodyList, responseList);
    createDomainUseCase(
        pathPage, pageName, apiName, method, bodyList, responseList);
    createPresentationBloc(
        pathPage, pageName, apiName, method, bodyList, responseList);
    if (!json2dart && isReturnDataModel) {
      createMapper(pathPage, pageName, apiName);
    }

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
    switch (returnData) {
      case 'header':
        return 'Map<String, String>';
      case 'body_bytes':
        return 'Uint8List';
      case 'body_string':
        return 'String';
      case 'status_code':
        return 'int';
      case 'raw':
        return 'Response';
      default:
        if (responseList) {
          return 'List<${apiClassName}Response>';
        } else {
          return '${apiClassName}Response';
        }
    }
  }

  String getStreamResponseClass(String apiClassName, bool responseList) {
    switch (returnData) {
      case 'header':
        return 'Map<String, String>';
      case 'body_bytes':
        return 'Uint8List';
      case 'body_string':
        return 'String';
      case 'status_code':
        return 'int';
      case 'raw':
        return 'String';
      default:
        if (responseList) {
          return 'List<${apiClassName}Response>';
        } else {
          return '${apiClassName}Response';
        }
    }
  }

  String getResponseReturn(String apiClassName, bool responseList) {
    switch (returnData) {
      case 'header':
        return 'return response.headers;';
      case 'body_bytes':
        return 'return response.bodyBytes;';
      case 'body_string':
        return 'return response.body;';
      case 'status_code':
        return 'return response.statusCode;';
      case 'raw':
        return 'return response;';
      default:
        if (responseList) {
          return '''final mapResponse = jsonDecode(response.body);
    return mapResponse is List
        ? List.from(mapResponse.map((e) => ${apiClassName}Response.fromMap(e)))
        : [${apiClassName}Response.fromMap(mapResponse)];''';
        } else {
          return 'return ${apiClassName}Response.fromJson(response.body);';
        }
    }
  }

  String getStreamResponseReturn(String apiClassName, bool responseList) {
    final data = switch (returnData) {
      // 'header' => 'yield response.headers;',
      // 'body_bytes' => 'yield response.bodyBytes;',
      'body_string' => 'yield response;',
      // 'status_code' => 'yield response.statusCode;',
      'raw' => 'yield response;',
      _ => responseList
          ? '''final mapResponse = jsonDecode(response);
    yiled mapResponse is List
        ? List.from(mapResponse.map((e) => ${apiClassName}Response.fromMap(e)))
        : [${apiClassName}Response.fromMap(mapResponse)];'''
          : 'yield ${apiClassName}Response.fromJson(response);'
    };

    return '''    await for (final response in responses) {
      $data
    }''';
  }

  String getEntityClass(String apiClassName, bool responseList) {
    switch (returnData) {
      case 'header':
        return 'Map<String, String>';
      case 'body_bytes':
        return 'Uint8List';
      case 'body_string':
        return 'String';
      case 'status_code':
        return 'int';
      case 'raw':
        return 'Response';
      default:
        if (responseList) {
          return 'List<${apiClassName}Entity>';
        } else {
          return '${apiClassName}Entity';
        }
    }
  }

  String getEntityReturn(String apiClassName, bool responseList) {
    switch (returnData) {
      case 'model':
        if (responseList) {
          return 'data.map((e) => e.toEntity()).toList()';
        } else {
          return 'data.toEntity()';
        }
      default:
        return 'data';
    }
  }

  bool isMultipart(String method) {
    return method.toLowerCase().contains('multipart');
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
    DirectoryHelper.createDir(path);

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
        : 'body: body.toMap()${isMultipart(method) ? '.map((key, value) => MapEntry(key, value.toString()))' : ''},${isMultipart(method) ? ' files: body.files,' : ''}';

    final responseClass = whenMethod(
      method,
      onStream: () => getStreamResponseClass(apiClassName, responseList),
      onFuture: () => getResponseClass(apiClassName, responseList),
    );
    final responseImpl = whenMethod(
      method,
      onStream: () => getStreamResponseReturn(apiClassName, responseList),
      onFuture: () => getResponseReturn(apiClassName, responseList),
    );

    final convert =
        bodyList || responseList ? "import 'dart:convert';\n\n" : '';

    final apiMethod = isMultipart(method)
        ? method == 'multipart'
            ? 'postMultipart'
            : method
        : method;
    final apiEndpoint = paramPath.isEmpty
        ? '${projectName.pascalCase}Endpoints.$apiMethodName${appsName.pascalCase}'
        : '${projectName.pascalCase}Endpoints.$apiMethodName${appsName.pascalCase}(${paramPath.map((e) => 'body.${e.camelCase}').join(',')})';
    final apiCacheStrategy = cacheStrategy == null || isMultipart(method)
        ? ''
        : '${cacheStrategy.toParamCacheStrategy(ttl: ttl, keepExpiredCache: keepExpiredCache)},';

    final methodOfDataSource = '''@override
  ${whenMethod(
      method,
      onStream: () {
        return '''${flutterClassOfMethod(method)}<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async* {
    final responses = http.$apiMethod($apiEndpoint, $bodyImpl${headers ?? 'headers: headers,'});
    $responseImpl
  }''';
      },
      onFuture: () {
        return '''${flutterClassOfMethod(method)}<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    final response = await http.$apiMethod($apiEndpoint, $bodyImpl${headers ?? 'headers: headers,'}$apiCacheStrategy);
    $responseImpl
  }''';
      },
    )}''';

    if (!exists(join(path, '${pageName}_remote_data_source.dart'))) {
      join(path, '${pageName}_remote_data_source.dart').write(
          '''${returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}

${convert}import 'package:core/core.dart';

import '../models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../models/response/${apiName}_response.dart';''' : ''}

abstract class ${pageName.pascalCase}RemoteDataSource {
  ${flutterClassOfMethod(method)}<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}

class ${pageName.pascalCase}RemoteDataSourceImpl implements ${pageName.pascalCase}RemoteDataSource {
  ${pageName.pascalCase}RemoteDataSourceImpl({required this.http});

  final MorphemeHttp http;

  $methodOfDataSource
}''');
    } else {
      String data = File(join(path, '${pageName}_remote_data_source.dart'))
          .readAsStringSync();

      final isNeedImportTypeData = returnData == 'body_bytes' &&
          !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

      if (isNeedImportTypeData) {
        data = '''import 'dart:typed_data';
        
        $data''';
      }

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';
    
import '../models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../models/response/${apiName}_response.dart';''' : ''}''');

      data = data.replaceAll(
          RegExp('abstract\\s?class\\s?${pageClassName}RemoteDataSource\\s?{',
              multiLine: true),
          '''abstract class ${pageClassName}RemoteDataSource {
  ${flutterClassOfMethod(method)}<$responseClass> $apiMethodName($bodyClass body,{Map<String, String>? headers,});''');

      data = data.replaceAll(RegExp(r'}(\s+)?$', multiLine: false), '');

      data = '''$data
      $methodOfDataSource
}''';

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
    DirectoryHelper.createDir(path);

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
    DirectoryHelper.createDir(path);
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
    String method,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'data', 'repositories');
    DirectoryHelper.createDir(path);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    final entityImpl = getEntityReturn(apiClassName, responseList);

    final methodOfDataRepository = '''@override
  ${whenMethod(
      method,
      onStream: () {
        return '''${flutterClassOfMethod(method)}<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async* {
    try {
      final response = remoteDataSource.$apiMethodName(
        body,
        headers: headers,
      );
      await for (final data in response) {
        yield Right($entityImpl);
      }
    } on MorphemeException catch (e) {
      yield Left(e.toMorphemeFailure());
    } catch (e) {
      yield Left(InternalFailure(e.toString()));
    }
  }''';
      },
      onFuture: () {
        return '''${flutterClassOfMethod(method)}<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,}) async {
    try {
      final data = await remoteDataSource.$apiMethodName(body, headers: headers,);
      return Right($entityImpl);
    } on MorphemeException catch (e) {
      return Left(e.toMorphemeFailure());
    } catch (e) {
      return Left(InternalFailure(e.toString()));
    }
  }''';
      },
    )}''';

    if (!exists(join(path, '${pageName}_repository_impl.dart'))) {
      join(path, '${pageName}_repository_impl.dart').write(
          '''${returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
          
import 'package:core/core.dart';

${isReturnDataModel ? '''import '../../domain/entities/${apiName}_entity.dart';''' : ''}
${isReturnDataModel ? '''import '../../mapper.dart';''' : ''}
import '../../domain/repositories/${pageName}_repository.dart';
import '../datasources/${pageName}_remote_data_source.dart';
import '../models/body/${apiName}_body.dart';

class ${pageName.pascalCase}RepositoryImpl implements ${pageName.pascalCase}Repository {
  ${pageName.pascalCase}RepositoryImpl({
    required this.remoteDataSource,
  });

  final ${pageName.pascalCase}RemoteDataSource remoteDataSource;

  $methodOfDataRepository
}''');
    } else {
      String data = File(join(path, '${pageName}_repository_impl.dart'))
          .readAsStringSync();

      final isDataDatasourceAlready =
          RegExp(r'remote_data_source\.dart').hasMatch(data);
      final isDomainRepositoryAlready =
          RegExp(r'repository\.dart').hasMatch(data);

      final isNeedMapper =
          (RegExp(r'.toEntity()').hasMatch(data) || isReturnDataModel) &&
              !RegExp(r'''import '../../mapper.dart';''').hasMatch(data);

      final isNeedImportTypeData = returnData == 'body_bytes' &&
          !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

      if (isNeedImportTypeData) {
        data = '''import 'dart:typed_data';
        
        $data''';
      }

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';

${isNeedMapper ? '''import '../../mapper.dart';''' : ''}          
${isDataDatasourceAlready ? '' : "import '../datasources/${pageName}_remote_data_source.dart';"}
${isDomainRepositoryAlready ? '' : "import '../../domain/repositories/${pageName}_repository.dart';"}
${isReturnDataModel ? '''import '../../domain/entities/${apiName}_entity.dart';''' : ''}
import '../models/body/${apiName}_body.dart';''');

      final isEmpty = RegExp(r'remoteDataSource;(\s+)?}(\s+)?}').hasMatch(data);

      data =
          data.replaceAll(RegExp(r'}(\s+)?}(\s+)?}'), '''${isEmpty ? '' : '}}'}

  $methodOfDataRepository
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
    DirectoryHelper.createDir(path);
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
    String method,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'domain', 'repositories');
    DirectoryHelper.createDir(path);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    if (!exists(join(path, '${pageName}_repository.dart'))) {
      join(path, '${pageName}_repository.dart').write(
          '''${returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
          
import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../entities/${apiName}_entity.dart';''' : ''}

abstract class ${pageName.pascalCase}Repository {
  ${flutterClassOfMethod(method)}<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}''');
    } else {
      String data =
          File(join(path, '${pageName}_repository.dart')).readAsStringSync();

      final isNeedImportTypeData = returnData == 'body_bytes' &&
          !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

      if (isNeedImportTypeData) {
        data = '''import 'dart:typed_data';
        
        $data''';
      }

      data = data.replaceAll(
          RegExp(r"import\s?'package:core\/core.dart';\n?\n?", multiLine: true),
          '''import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../entities/${apiName}_entity.dart';''' : ''}''');

      data = data.replaceAll(RegExp(r'}$', multiLine: true),
          '''  ${flutterClassOfMethod(method)}<Either<MorphemeFailure, $entityClass>> $apiMethodName($bodyClass body,{Map<String, String>? headers,});
}''');

      join(path, '${pageName}_repository.dart').write(data);
    }

    StatusHelper.generated(join(path, '${pageName}_repository.dart'));
  }

  void createDomainUseCase(
    String pathPage,
    String pageName,
    String apiName,
    String method,
    bool bodyList,
    bool responseList,
  ) {
    final pageClassName = pageName.pascalCase;
    final apiClassName = apiName.pascalCase;
    final apiMethodName = apiName.camelCase;

    final path = join(pathPage, 'domain', 'usecases');
    DirectoryHelper.createDir(path);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    join(path, '${apiName}_use_case.dart').write(
        '''${returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
        
import 'package:core/core.dart';

import '../../data/models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../entities/${apiName}_entity.dart';''' : ''}
import '../repositories/${pageName}_repository.dart';

class ${apiClassName}UseCase implements ${whenMethod(
      method,
      onStream: () => 'StreamUseCase',
      onFuture: () => 'UseCase',
    )}<$entityClass, $bodyClass> {
  ${apiClassName}UseCase({
    required this.repository,
  });

  final ${pageClassName}Repository repository;

  @override
  ${flutterClassOfMethod(method)}<Either<MorphemeFailure, $entityClass>> call($bodyClass body,{Map<String, String>? headers,}) {
    return repository.$apiMethodName(body, headers: headers);
  }
}''');

    StatusHelper.generated(join(path, '${apiName}_use_case.dart'));
  }

  void createPresentationBloc(
    String pathPage,
    String pageName,
    String apiName,
    String method,
    bool bodyList,
    bool responseList,
  ) {
    final apiClassName = apiName.pascalCase;

    final path = join(pathPage, 'presentation', 'bloc', apiName);
    DirectoryHelper.createDir(path);

    final bodyClass = getBodyClass(apiClassName, bodyList);
    final entityClass = getEntityClass(apiClassName, responseList);

    join(path, '${apiName}_state.dart').write('''part of '${apiName}_bloc.dart';

@immutable
abstract class ${apiClassName}State extends Equatable {
  bool get isInitial => this is ${apiClassName}Initial;
  bool get isLoading => this is ${apiClassName}Loading;
  bool get isFailed => this is ${apiClassName}Failed;
  bool get isSuccess => this is ${apiClassName}Success;
  bool get isCanceled => this is ${apiClassName}Canceled;
  ${whenMethod(
      method,
      onStream: () {
        return '''bool get isStream => this is ${apiClassName}Stream;
  bool get isPaused => this is ${apiClassName}Paused;
  bool get isResumed => this is ${apiClassName}Resumed;''';
      },
      onFuture: () => '',
    )}

  bool get isNotInitial => this is! ${apiClassName}Initial;
  bool get isNotLoading => this is! ${apiClassName}Loading;
  bool get isNotFailed => this is! ${apiClassName}Failed;
  bool get isNotSuccess => this is! ${apiClassName}Success;
  bool get isNotCanceled => this is! ${apiClassName}Canceled;
  ${whenMethod(
      method,
      onStream: () {
        return '''bool get isNotStream => this is! ${apiClassName}Stream;
  bool get isNotPaused => this is! ${apiClassName}Paused;
  bool get isNotResumed => this is! ${apiClassName}Resumed;''';
      },
      onFuture: () => '',
    )}

  void when({
    void Function(${apiClassName}Initial state)? onInitial,
    void Function(${apiClassName}Loading state)? onLoading,
    void Function(${apiClassName}Failed state)? onFailed,
    void Function(${apiClassName}Success state)? onSuccess,
    void Function(${apiClassName}Canceled state)? onCanceled,
    ${whenMethod(
      method,
      onStream: () {
        return '''void Function(${apiClassName}Stream state)? onStream,
  void Function(${apiClassName}Paused state)? onPaused,
  void Function(${apiClassName}Resumed state)? onResumed,''';
      },
      onFuture: () => '',
    )}
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
    } else if (state is ${apiClassName}Canceled) {
      onCanceled?.call(state);
    } ${whenMethod(
      method,
      onStream: () {
        return '''else if (state is ${apiClassName}Stream) {
      onStream?.call(state);
    } else if (state is ${apiClassName}Paused) {
      onPaused?.call(state);
    } else if (state is ${apiClassName}Resumed) {
      onResumed?.call(state);
    }''';
      },
      onFuture: () => '',
    )}
  }

  Widget builder({
    Widget Function(${apiClassName}Initial state)? onInitial,
    Widget Function(${apiClassName}Loading state)? onLoading,
    Widget Function(${apiClassName}Failed state)? onFailed,
    Widget Function(${apiClassName}Success state)? onSuccess,
    Widget Function(${apiClassName}Canceled state)? onCanceled,
    ${whenMethod(
      method,
      onStream: () {
        return '''Widget Function(${apiClassName}Stream state)? onStream,
   Widget Function(${apiClassName}Paused state)? onPaused,
   Widget Function(${apiClassName}Resumed state)? onResumed,''';
      },
      onFuture: () => '',
    )}
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
    } else if (state is ${apiClassName}Canceled) {
      return onCanceled?.call(state) ?? defaultWidget;
    } ${whenMethod(
      method,
      onStream: () {
        return '''else if (state is ${apiClassName}Stream) {
      return onStream?.call(state) ?? defaultWidget;
    } else if (state is ${apiClassName}Paused) {
      return onPaused?.call(state) ?? defaultWidget;
    } else if (state is ${apiClassName}Resumed) {
      return onResumed?.call(state) ?? defaultWidget;
    }''';
      },
      onFuture: () => '',
    )}
    else {
      return defaultWidget;
    }
  }
}

class ${apiClassName}Initial extends ${apiClassName}State {
  @override
  List<Object?> get props => [];
}

class ${apiClassName}Loading extends ${apiClassName}State {
   ${apiClassName}Loading(this.body, this.headers, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, extra,];
}

class ${apiClassName}Failed extends ${apiClassName}State {
  ${apiClassName}Failed(this.body, this.headers, this.failure, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final MorphemeFailure failure;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, failure, extra,];
}

class ${apiClassName}Canceled extends ${apiClassName}State {
  ${apiClassName}Canceled(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

${whenMethod(
      method,
      onStream: () {
        return '''class ${apiClassName}Stream extends ${apiClassName}State {
  ${apiClassName}Stream(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final $entityClass data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}

class ${apiClassName}Paused extends ${apiClassName}State {
  ${apiClassName}Paused(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class ${apiClassName}Resumed extends ${apiClassName}State {
  ${apiClassName}Resumed(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class ${apiClassName}Success extends ${apiClassName}State {
  ${apiClassName}Success(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final List<$entityClass> data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}''';
      },
      onFuture: () =>
          '''class ${apiClassName}Success extends ${apiClassName}State {
  ${apiClassName}Success(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final $entityClass data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}''',
    )}
''');

    join(path, '${apiName}_event.dart').write('''part of '${apiName}_bloc.dart';

@immutable
abstract class ${apiClassName}Event extends Equatable {}

class Fetch$apiClassName extends ${apiClassName}Event {
  Fetch$apiClassName(this.body, {this.headers, this.extra,});

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, extra,];
}

class Cancel$apiClassName extends ${apiClassName}Event {
  Cancel$apiClassName({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

${whenMethod(
      method,
      onStream: () {
        return '''class Pause$apiClassName extends ${apiClassName}Event {
  Pause$apiClassName({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class Resume$apiClassName extends ${apiClassName}Event {
  Resume$apiClassName({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}''';
      },
      onFuture: () => '',
    )}''');

    join(path, '${apiName}_bloc.dart').write('''${whenMethod(
      method,
      onStream: () => "import 'dart:async';",
      onFuture: () => '',
    )}
${returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
    
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../data/models/body/${apiName}_body.dart';
${isReturnDataModel ? '''import '../../../domain/entities/${apiName}_entity.dart';''' : ''}
import '../../../domain/usecases/${apiName}_use_case.dart';

part '${apiName}_event.dart';
part '${apiName}_state.dart';

class ${apiClassName}Bloc extends MorphemeBloc<${apiClassName}Event, ${apiClassName}State> {
  ${apiClassName}Bloc({
    required this.useCase,
  }) : super(${apiClassName}Initial()) {
    on<Fetch$apiClassName>((event, emit) async {
      emit(${apiClassName}Loading(event.body, event.headers, event.extra,));
      ${whenMethod(
      method,
      onStream: () {
        return '''final results = useCase(event.body, headers: event.headers,);
      final completer = Completer();
      final List<$entityClass> buffer = [];
      _streamSubscription = results.listen(
        (result) {
          emit(
            result.fold(
              (failure) => ${apiClassName}Failed(
                event.body,
                event.headers,
                failure,
                event.extra,
              ),
              (success) {
                buffer.add(success);
                return ${apiClassName}Stream(
                  event.body,
                  event.headers,
                  success,
                  event.extra,
                );
              },
            ),
          );
        },
        onError: (error) {
          emit(
            ${apiClassName}Failed(
              event.body,
              event.headers,
              InternalFailure('An unexpected error occurred: \$error'),
              event.extra,
            ),
          );
          completer.complete();
        },
        onDone: () {
          emit(
            ${apiClassName}Success(
              event.body,
              event.headers,
              buffer,
              event.extra,
            ),
          );
          completer.complete();
        },
      );
      await completer.future;
    });
    on<Cancel$apiClassName>((event, emit) async {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      emit(${apiClassName}Canceled(event.extra));
    });
    on<Pause$apiClassName>((event, emit) async {
      _streamSubscription?.pause();
      emit(${apiClassName}Paused(event.extra));
    });
    on<Resume$apiClassName>((event, emit) async {
      _streamSubscription?.resume();
      emit(${apiClassName}Resumed(event.extra));
    });''';
      },
      onFuture: () {
        return '''_cancelableOperation = CancelableOperation.fromFuture(
        useCase(
          event.body,
          headers: event.headers,
        ),
      );
      final result = await _cancelableOperation?.valueOrCancellation();

      if (result == null) {
        emit(${apiClassName}Canceled(event.extra));
        return;
      }
      emit(
        result.fold(
          (failure) => ${apiClassName}Failed(event.body, event.headers, failure, event.extra,),
          (success) => ${apiClassName}Success(event.body, event.headers, success, event.extra,),
        ),
      );
    });
    on<Cancel$apiClassName>((event, emit) async {
      _cancelableOperation?.cancel();
      _cancelableOperation = null;
      emit(${apiClassName}Canceled(event.extra));
    });''';
      },
    )}
    
  }

  final ${apiClassName}UseCase useCase;

  ${whenMethod(
      method,
      onStream: () {
        return '''StreamSubscription<Either<MorphemeFailure, $entityClass>>? _streamSubscription;

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    return super.close();
  }''';
      },
      onFuture: () {
        return '''CancelableOperation<Either<MorphemeFailure, $entityClass>>? _cancelableOperation;
  
  @override
  Future<void> close() {
    _cancelableOperation?.cancel();
    _cancelableOperation = null;
    return super.close();
  }''';
      },
    )}
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
    DirectoryHelper.createDir(path);

    if (!exists(join(path, 'locator.dart'))) {
      join(path, 'locator.dart').write('''import 'package:core/core.dart';

import 'presentation/cubit/${pageName.snakeCase}_cubit.dart';

void setupLocator${pageName.pascalCase}() {
  // *Cubit
  locator..registerFactory(() => ${pageName.pascalCase}Cubit(),);
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

    data = data.replaceAll(RegExp(r';?(\s+)?}', multiLine: true), '''

  // *Bloc
  ..registerFactory(() => ${apiClassName}Bloc(useCase: locator()),)

  // *Usecase
  ..registerLazySingleton(() => ${apiClassName}UseCase(repository: locator()),)
  ${!isDataDatasourceAlready ? '''
  // *Repository
  ..registerLazySingleton<${pageName.pascalCase}Repository>(
    () => ${pageName.pascalCase}RepositoryImpl(remoteDataSource: locator(),),
  )''' : ''}
 ${!isDataRepositoryAlready && !isDomainRepositoryAlready ? '''
  // *Datasource
  ..registerLazySingleton<${pageName.pascalCase}RemoteDataSource>(
    () => ${pageName.pascalCase}RemoteDataSourceImpl(http: locator(),),
  )''' : ''}
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
      '${pageName.pascalCase}Cubit($bloc,)',
    );

    data = data.replaceAll(RegExp(r';?(\s+)?}', multiLine: true), ''';}''');

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
    DirectoryHelper.createDir(path);

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
