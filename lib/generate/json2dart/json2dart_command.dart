import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

enum TypeMapper { toEntity, toResponse }

class Json2DartCommand extends Command {
  Json2DartCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'api',
      help: 'Generate models with implement api.',
    );
    argParser.addFlag(
      'endpoint',
      help: 'Generate endpoint from path json2dart.yaml.',
    );
    argParser.addFlag(
      'unit-test',
      help: 'Generate unit test for api implementation.',
    );
    argParser.addFlag(
      'only-unit-test',
      help: 'Generate only unit test for api implementation.',
    );
    argParser.addOption(
      'feature-name',
      abbr: 'f',
      help: 'Generate spesific feature (Optional)',
    );
    argParser.addOption(
      'page-name',
      abbr: 'p',
      help: 'Generate spesific page, must include --feature-name (Optional)',
    );
    argParser.addFlag(
      'replace',
      help:
          'Replace value generated. if set to false will be delete all directory generated json2dart before.',
    );
    argParser.addOption(
      'apps-name',
      abbr: 'a',
      help: 'Generate spesific apps (Optional)',
    );
    argParser.addFlag(
      'format',
      help: 'Format file dart generated.',
    );
  }

  @override
  String get name => 'json2dart';

  @override
  String get description => 'Generate dart data class from json.';

  @override
  String get category => Constants.generate;

  String projectName = '';

  bool isApi = true;
  bool isEndpoint = true;
  bool isUnitTest = false;
  bool isOnlyUnitTest = false;
  bool isReplace = false;
  bool isFormat = true;
  String? appsName;
  String? featureName;
  String? pageName;
  String defaultBodyDateFormat = '.toIso8601String()';
  String defaultResponseDateFormat = '.toIso8601String()';
  String bodyDateFormat = '.toIso8601String()';
  String responseDateFormat = '.toIso8601String()';

  List<ModelClassName> listClassNameBody = [];
  List<ModelClassName> listClassNameResponse = [];
  List<ModelClassName> listClassNameEntity = [];
  List<ModelClassName> listClassNameMapper = [];

  List<ModelClassName> listClassNameUnitTest = [];

  List<String> fix = [];
  List<String> format = [];

  bool isReturnDataModel(String returnData) => returnData == 'model';

  final regexDateTime =
      RegExp(r'"\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?"');

  T whenMethodHttp<T>(
    String method, {
    required T Function() onStream,
    required T Function() onFuture,
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
    if (argResults?.rest.firstOrNull == 'init') {
      init();
      return;
    }

    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    projectName = YamlHelper.loadFileYaml(argMorphemeYaml).projectName;

    appsName = argResults?['apps-name'];

    final searchFileJson2Dart = appsName?.isNotEmpty ?? false
        ? '${appsName}_json2dart.yaml'
        : '*json2dart.yaml';

    final workingDirectory = find(
      searchFileJson2Dart,
      workingDirectory: join(current, 'json2dart'),
    ).toList();

    final listCommands = <String>[];

    for (var pathJson2Dart in workingDirectory) {
      if (!exists(pathJson2Dart)) {
        StatusHelper.warning(
            'you don\'t have "json2dart.yaml" in $pathJson2Dart');
      }

      final yml = YamlHelper.loadFileYaml(pathJson2Dart);
      Map json2DartMap = Map.from(yml);

      if (json2DartMap['json2dart'] != null) {
        final config = json2DartMap.remove('json2dart');

        if (config['body_format_date_time'] != null) {
          defaultBodyDateFormat =
              ".toFormatDateTimeBody('${config['body_format_date_time']}')";
        }
        if (config['response_format_date_time'] != null) {
          defaultResponseDateFormat =
              ".toFormatDateTimeResponse('${config['response_format_date_time']}')";
        }
        if (config['endpoint'] != null && config['endpoint'] is bool) {
          isEndpoint = config['endpoint'];
        }
        if (config['api'] != null && config['api'] is bool) {
          isApi = config['api'];
        }
        if (config['unit-test'] != null && config['unit-test'] is bool) {
          isUnitTest = config['unit-test'];
        }
        if (config['replace'] != null && config['replace'] is bool) {
          isReplace = config['replace'];
        }
        if (config['format'] != null && config['format'] is bool) {
          isFormat = config['format'];
        }
      }

      isEndpoint = (argResults?.arguments.firstWhereOrNull(
                      (element) => element.contains('endpoint')) !=
                  null
              ? argResults!['endpoint']
              : null) ??
          isEndpoint ??
          true;

      isApi = (argResults?.arguments
                      .firstWhereOrNull((element) => element.contains('api')) !=
                  null
              ? argResults!['api']
              : null) ??
          isApi ??
          true;
      isUnitTest = (argResults?.arguments.firstWhereOrNull(
                      (element) => element.contains('unit-test')) !=
                  null
              ? argResults!['unit-test']
              : null) ??
          isUnitTest ??
          false;
      isOnlyUnitTest = (argResults?.arguments.firstWhereOrNull(
                      (element) => element.contains('only-unit-test')) !=
                  null
              ? argResults!['only-unit-test']
              : null) ??
          isOnlyUnitTest ??
          false;
      isReplace = (argResults?.arguments.firstWhereOrNull(
                      (element) => element.contains('replace')) !=
                  null
              ? argResults!['replace']
              : null) ??
          isReplace ??
          false;
      isFormat = (argResults?.arguments.firstWhereOrNull(
                      (element) => element.contains('format')) !=
                  null
              ? argResults!['format']
              : null) ??
          isFormat ??
          true;
      featureName = argResults?['feature-name'];
      pageName = argResults?['page-name'];

      if (!isOnlyUnitTest && isEndpoint) {
        await 'morpheme endpoint --json2dart'.run;
      }

      if (featureName != null) {
        if (json2DartMap.keys
                .firstWhereOrNull((element) => element == featureName) ==
            null) {
          StatusHelper.warning('$featureName not found in json2dart.yaml');
        } else {
          final lastPathJson2Dart = pathJson2Dart.split(separator).last;

          String featurePath = join(current, 'features', featureName);
          String? appsName = this.appsName;
          if (lastPathJson2Dart.contains('_')) {
            appsName = lastPathJson2Dart.split('_').first;
            featurePath =
                join(current, 'apps', appsName, 'features', featureName);
          }
          await handleFeature(
              featurePath, featureName!, json2DartMap[featureName], appsName);

          if (isFormat && format.isNotEmpty) {
            printMessage('Execute morpheme format................');
            await ModularHelper.format(format);
          }
          if (isFormat && fix.isNotEmpty) {
            printMessage('Execute morpheme fix................');
            await ModularHelper.fix(fix);
          }
          if (isFormat && format.isNotEmpty) {
            printMessage('Execute morpheme format................');
            await ModularHelper.format(format);
          }
        }
      } else {
        for (var element in json2DartMap.entries) {
          final featureName = element.key;

          final lastPathJson2Dart = pathJson2Dart.split(separator).last;

          String? appsName = this.appsName;
          if (lastPathJson2Dart.contains('_')) {
            appsName = lastPathJson2Dart.split('_').first;
          }
          listCommands.add(
            'morpheme json2dart --feature-name $featureName '
            '--morpheme-yaml $argMorphemeYaml '
            '${appsName?.isNotEmpty ?? false ? '--apps-name $appsName' : ''} '
            '${isApi ? '--api' : '--no-api'} '
            '${isUnitTest ? '--unit-test' : '--no-unit-test'} '
            '${isOnlyUnitTest ? '--only-unit-test' : '--no-only-unit-test'} '
            '${isReplace ? '--replace' : '--no-replace'} '
            '--no-endpoint '
            '--no-format ',
          );
        }
      }
    }

    if (listCommands.isNotEmpty) {
      await ModularHelper.executeCommand(listCommands);
      printMessage('Execute morpheme format................');
      await ModularHelper.format([join(current, 'features')]);
      printMessage('Execute morpheme fix................');
      await ModularHelper.fix([join(current, 'features')]);
      printMessage('Execute morpheme format................');
      await ModularHelper.format([join(current, 'features')]);
    }

    StatusHelper.success('morpheme json2dart');
  }

  void init() {
    final path = join(current, 'json2dart');
    DirectoryHelper.createDir(path);

    if (!exists(join(path, 'json2dart.yaml'))) {
      join(path, 'json2dart.yaml')
          .write('''# json2dart for configuration generate
#
# node 1 is feature name
# node 2 is page name
# node 3 is api name can be multiple api in 1 page
#
# method allow: get, post, put, patch, delete, multipart (postMultipart / patchMultipart).
# cache_strategy allow: async_or_cache, cache_or_async, just_async, just_cache. by default set to just_async.
# base_url: base_url for remote api take from String.environment('\$base_url').
#
# example
# json2dart:
#   body_format_date_time: yyyy-MM-dd
#   response_format_date_time: yyyy-MM-dd HH:mm
#   api: true
#   endpoint: true
#   unit-test: false
#   replace: false

#   environment_url:
#     - &base_url BASE_URL

#   remote:
#     .login: &login
#       base_url: *base_url
#       path: /login
#       method: post
#       # header: json2dart/json/header/login_header.json
#       body: json2dart/json/body/login_body.json
#       response: json2dart/json/response/login_response.json
#       cache_strategy: async_or_cache
#     .register: &register
#       base_url: *base_url
#       path: /register
#       method: post
#       # header: json2dart/json/header/register_header.json
#       body: json2dart/json/body/register_body.json
#       response: json2dart/json/response/register_response.json
#       cache_strategy:
#         strategy: cache_or_async
#         ttl: 60
#     .forgot_password: &forgot_password
#       base_url: *base_url
#       path: /forgot_password
#       method: get
#       # header: json2dart/json/header/forgot_password_header.json
#       body: json2dart/json/body/forgot_password_body.json
#       response: json2dart/json/response/forgot_password_response.json
#       cache_strategy:
#         strategy: just_cache
#         ttl: 120
#         keep_expired_cache: true
#
# auth:
#   login:
#     login: *login
#   register:
#     register: *register
#   forgot_password:
#     forgot_password: *forgot_password

json2dart:
  body_format_date_time: yyyy-MM-dd
  response_format_date_time: yyyy-MM-dd HH:mm
  api: true
  endpoint: true
  unit-test: false
  replace: false

  environment_url:
    - &base_url BASE_URL

  remote:
    .login: &login
      base_url: *base_url
      path: /login
      method: post
      # header: json2dart/json/header/login_header.json
      body: json2dart/json/body/login_body.json
      response: json2dart/json/response/login_response.json
      cache_strategy: async_or_cache
    .register: &register
      base_url: *base_url
      path: /register
      method: post
      # header: json2dart/json/header/register_header.json
      body: json2dart/json/body/register_body.json
      response: json2dart/json/response/register_response.json
      cache_strategy:
        strategy: cache_or_async
        ttl: 60
    .forgot_password: &forgot_password
      base_url: *base_url
      path: /forgot_password
      method: get
      # header: json2dart/json/header/forgot_password_header.json
      body: json2dart/json/body/forgot_password_body.json
      response: json2dart/json/response/forgot_password_response.json
      cache_strategy:
        strategy: just_cache
        ttl: 120
        keep_expired_cache: true

auth:
  login:
    login: *login
  register:
    register: *register
  forgot_password:
    forgot_password: *forgot_password
''');
    }

    final pathBody = join(path, 'json', 'body');
    final pathResponse = join(path, 'json', 'response');

    DirectoryHelper.createDir(pathBody);
    DirectoryHelper.createDir(pathResponse);

    StatusHelper.success('morpheme json2dart init');
  }

  Future<void> handleFeature(
    String featurePath,
    String featureName,
    dynamic featureValue,
    String? appsName,
  ) async {
    if (!exists(featurePath)) {
      StatusHelper.warning(
          'Feature with name $featureName not found in $featurePath!');
      return;
    }
    if (featureValue is! Map) {
      StatusHelper.warning(
          'Value feature is not valid, please check format json2dart.yaml');
      return;
    }

    fix.add(featurePath);

    if (this.featureName != null && pageName != null) {
      if (featureValue.keys
              .firstWhereOrNull((element) => element == pageName) ==
          null) {
        StatusHelper.warning(
            '$pageName in $featureName not found in json2dart.yaml');
      } else {
        await handlePage(
          featureName: featureName,
          featurePath: featurePath,
          pageName: pageName!,
          pageValue: featureValue[pageName],
          appsName: appsName,
        );
      }
    } else {
      for (var element in featureValue.entries) {
        final pageName = element.key;
        final pageValue = element.value;

        await handlePage(
          featureName: featureName,
          featurePath: featurePath,
          pageName: pageName,
          pageValue: pageValue,
          appsName: appsName,
        );
      }
    }
  }

  Future<void> handlePage({
    required String featureName,
    required String featurePath,
    required String pageName,
    required dynamic pageValue,
    required String? appsName,
  }) async {
    final pathPage = join(featurePath, 'lib', pageName);
    final pathTestPage = join(featurePath, 'test', '${pageName}_test');
    if (!exists(pathPage)) {
      StatusHelper.warning(
          'Page with name $pageName not found in feature $pathPage!');
      return;
    }
    if (pageValue is! Map) {
      StatusHelper.warning(
          'Value page is not valid, please check format json2dart.yaml');
      return;
    }

    if (!isOnlyUnitTest && isApi) {
      removeAllRelatedApiPage(pathPage, pageName, pageValue, isReplace);
    }
    if ((isOnlyUnitTest || isUnitTest)) {
      removeAllRelatedApiPageUnitTest(featureName, pageName);
    }

    if (!isOnlyUnitTest) createMapper(pathPage, pageValue);

    List<Map<String, String>> resultModelUnitTest = [];

    for (var element in pageValue.entries) {
      final apiName = element.key;
      final apiValue = element.value;

      if (apiValue is! Map) {
        StatusHelper.warning(
            'Value api is not valid, please check format json2dart.yaml');
        return;
      }

      final pathUrl = apiValue['path'];
      final paramPath = <String>[];
      parse(pathUrl ?? '', parameters: paramPath);

      final pathBody = apiValue['body'];
      bool isBodyList = false;
      dynamic body = getMapFromJson(
        pathBody,
        callbackJsonIsList: () => isBodyList = true,
        warningMessage: 'Format json body $apiName not valid!',
      );

      bool isResponseList = false;
      final pathResponse = apiValue['response'];
      dynamic response = getMapFromJson(
        pathResponse,
        callbackJsonIsList: () => isResponseList = true,
        warningMessage: 'Format json response $apiName not valid!',
      );

      bodyDateFormat =
          apiValue['body_format_date_time'] ?? defaultBodyDateFormat;
      responseDateFormat =
          apiValue['response_format_date_time'] ?? defaultResponseDateFormat;

      dynamic cacheStrategy = apiValue['cache_strategy'];
      String? strategy;
      int? ttl;
      bool? keepExpiredCache;
      if (cacheStrategy is String) {
        strategy = cacheStrategy;
      } else if (cacheStrategy is Map) {
        strategy = cacheStrategy['strategy'];
        ttl = cacheStrategy['ttl'];
        keepExpiredCache = cacheStrategy['keep_expired_cache'];
      }

      final returnData = apiValue['return_data'] ?? 'model';

      if (!isOnlyUnitTest) {
        await handleApi(
          featureName: featureName,
          featurePath: featurePath,
          pageName: pageName,
          pathPage: pathPage,
          apiName: apiName,
          body: body,
          response: response,
          method: apiValue['method'],
          pathUrl: pathUrl ?? '',
          paramPath: paramPath,
          header: apiValue['header'],
          isBodyList: isBodyList,
          isResponseList: isResponseList,
          cacheStrategy: strategy,
          ttl: ttl,
          keepExpiredCache: keepExpiredCache,
          appsName: appsName,
          returnData: returnData,
        );
      }

      dynamic bodyUnitTest;
      dynamic responseUnitTest;
      try {
        final jsonBody = apiValue['body'] != null
            ? File(apiValue['body']).readAsStringSync()
            : '{}';
        bodyUnitTest = jsonDecode(jsonBody);
        final jsonResponse = apiValue['response'] != null
            ? File(apiValue['response']).readAsStringSync()
            : '{}';

        Map<String, dynamic> jsonObject = json.decode(jsonResponse);
        responseUnitTest = processJson(jsonObject);
      } catch (e) {
        bodyUnitTest = {};
        responseUnitTest = {};
      }

      if ((isOnlyUnitTest || isUnitTest) && body != null && response != null) {
        final result = createModelUnitTest(
          pathTestPage: pathTestPage,
          appsName: appsName ?? '',
          featureName: featureName,
          pageName: pageName,
          pathPage: pathPage,
          apiName: apiName,
          jsonBody: pathBody != null
              ? File(pathBody).readAsStringSync().replaceAll(
                  RegExp(r'''('|")\w+('|")(\s+)?:(\s+)?null(\s+)?,'''), '')
              : '{}',
          jsonResponse: pathResponse != null
              ? File(pathResponse).readAsStringSync()
              : '{}',
          body: bodyUnitTest,
          response: responseUnitTest,
          method: apiValue['method'],
          paramPath: paramPath,
          pathHeader: apiValue['header'],
          cacheStrategy: strategy,
          ttl: ttl,
          keepExpiredCache: keepExpiredCache,
          returnData: returnData,
        );
        resultModelUnitTest.add(result);
      }
    }

    format.add(pathPage);

    if (isOnlyUnitTest || isUnitTest) {
      format.add(pathTestPage);
      handleUnitTest(
        pathTestPage: pathTestPage,
        featureName: featureName,
        pageName: pageName,
        pageValue: pageValue,
        resultModelUnitTest: resultModelUnitTest,
      );
    }
  }

  Future<void> handleApi({
    required String featureName,
    required String featurePath,
    required String pageName,
    required String pathPage,
    required String apiName,
    required dynamic body,
    required dynamic response,
    required String? method,
    required String pathUrl,
    required List<String> paramPath,
    required String? header,
    required bool isBodyList,
    required bool isResponseList,
    required String? cacheStrategy,
    required int? ttl,
    required bool? keepExpiredCache,
    required String? appsName,
    required String returnData,
  }) async {
    if (body != null) {
      createDataModelBody(
        pathPage,
        pageName,
        apiName,
        body,
        (method ?? '').toLowerCase().contains('multipart'),
        paramPath,
      );
    }

    if (response != null && isReturnDataModel(returnData)) {
      createDataModelResponse(pathPage, pageName, apiName, response);
      createDomainEntity(pathPage, pageName, apiName, response);
      appendMapper(pathPage, apiName, response);
    }

    final argBody = isBodyList ? '--body-list' : '--no-body-list';
    final argResponse =
        isResponseList ? '--response-list' : '--no-response-list';

    final argCacheStrategy = cacheStrategy == null
        ? ''
        : '--cache-strategy=$cacheStrategy${ttl == null ? '' : ' --ttl=$ttl'}${keepExpiredCache == null ? '' : ' --keep-expired-cache=$keepExpiredCache'}';

    final argAppsName = appsName != null ? '-a "$appsName"' : '';

    if (isApi) {
      printMessage(
          'morpheme api $apiName -f $featureName -p $pageName -r $returnData --json2dart --method=$method --path=$pathUrl ${header != null ? '--header=$header' : ''} $argBody $argResponse $argCacheStrategy $argAppsName');
      await 'morpheme api $apiName -f $featureName -p $pageName -r $returnData --json2dart --method=$method --path=$pathUrl ${header != null ? '--header=$header' : ''} $argBody $argResponse $argCacheStrategy $argAppsName'
          .run;
    }
  }

  dynamic getMapFromJson(
    String? path, {
    required void Function() callbackJsonIsList,
    String warningMessage = 'Format json not valid!',
  }) {
    final json = path != null ? File(path).readAsStringSync() : '{}';
    dynamic response;
    try {
      response = jsonDecode(json);
      if (response is List) {
        callbackJsonIsList();
        response = response.first;
      }
    } catch (e) {
      StatusHelper.warning(warningMessage);
      return null;
    }

    if (response is! Map) {
      StatusHelper.warning(warningMessage);
      return null;
    }
    return response;
  }

  void createDataModelBody(
    String pathPage,
    String pageName,
    String apiName,
    dynamic body, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final apiClassName = apiName.pascalCase;

    String classBody =
        '''${isMultipart ? "import 'dart:io';\n" : ''}import 'package:core/core.dart';

''';
    classBody += getBodyClass(
      apiClassName,
      'Body',
      '',
      body,
      true,
      isMultipart,
      paramPath,
    );

    final path = join(pathPage, 'data', 'models', 'body');
    DirectoryHelper.createDir(path);
    join(path, '${apiName.snakeCase}_body.dart').write(classBody);

    StatusHelper.generated(join(path, '${apiName.snakeCase}_body.dart'));
  }

  void createDataModelResponse(
    String pathPage,
    String pageName,
    String apiName,
    dynamic response,
  ) {
    final apiClassName = apiName.pascalCase;
    String classResponse = '''import 'dart:convert';

import 'package:core/core.dart';

''';
    classResponse +=
        getResponseClass(apiClassName, 'Response', '', response, true);

    final path = join(pathPage, 'data', 'models', 'response');
    DirectoryHelper.createDir(path);
    join(path, '${apiName.snakeCase}_response.dart').write(classResponse);

    StatusHelper.generated(join(path, '${apiName.snakeCase}_response.dart'));
  }

  String setConstractor(
    String apiClassName,
    Map map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final variable = map.keys;
    if (variable.isEmpty && paramPath.isEmpty) {
      return 'const $apiClassName(${isMultipart ? '{ this.files }' : ''});';
    }
    return '''const $apiClassName({
    ${isMultipart ? 'this.files,' : ''}
    ${paramPath.map((e) => 'this.${e.camelCase},').join('    \n')}
    ${variable.map((e) => 'this.${e.toString().camelCase},').join('    \n')}
  });''';
  }

  String setConstractorBody(
    String apiClassName,
    Map map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    final variable = map.keys;
    if (variable.isEmpty && paramPath.isEmpty) {
      return 'const $apiClassName(${isMultipart ? '{ this.rawBody,  this.files }' : '{ this.rawBody }'});';
    }
    return '''const $apiClassName({
    this.rawBody,
    ${isMultipart ? 'this.files,' : ''}
    ${paramPath.map((e) => 'required this.${e.camelCase},').join('    \n')}
    ${variable.map((e) => 'this.${e.toString().camelCase},').join('    \n')}
  });''';
  }

  void createDomainEntity(
    String pathPage,
    String pageName,
    String apiName,
    dynamic response,
  ) {
    final apiClassName = apiName.pascalCase;
    String classResponse = '''import 'package:core/core.dart';

''';
    classResponse += getEntityClass(apiClassName, 'Entity', '', response, true);

    final path = join(pathPage, 'domain', 'entities');
    DirectoryHelper.createDir(path);
    join(path, '${apiName.snakeCase}_entity.dart').write(classResponse);

    StatusHelper.generated(join(path, '${apiName.snakeCase}_entity.dart'));
  }

  void createMapper(String pathPage, Map map) {
    final keys = map.keys;
    DirectoryHelper.createDir(pathPage);
    join(pathPage, 'mapper.dart').write(
      keys.map(
        (e) {
          if (isReturnDataModel(map[e]['return_data'] ?? 'model')) {
            return """import 'data/models/response/${e.toString().snakeCase}_response.dart' as ${e.toString().snakeCase}_response;
import 'domain/entities/${e.toString().snakeCase}_entity.dart' as ${e.toString().snakeCase}_entity;""";
          }
          return '';
        },
      ).join('\n'),
    );

    StatusHelper.generated(join(pathPage, 'mapper.dart'));
  }

  String getTypeVariable(String key, dynamic value, String suffix,
      List<ModelClassName> listClassName, String parent) {
    if (value is int) {
      return 'int';
    }
    if (value is double) {
      return 'double';
    }
    if (value is bool) {
      return 'bool';
    }
    if (value is Map) {
      return ModelClassNameHelper.getClassName(
          listClassName, suffix, key.pascalCase, false, false, parent);
    }
    if (value is List) {
      if (value.isNotEmpty) {
        return 'List<${getTypeVariable(key, value.first, suffix, listClassName, parent)}>';
      }
      return 'List<dynamic>';
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
          .hasMatch(value)) {
        return 'DateTime';
      }
      return 'String';
    }
    return 'dynamic';
  }

  String setTypeData(
    Map map,
    String suffix,
    List<ModelClassName> listClassName,
    String parent, [
    bool isMultipart = false,
    List<String> paramPath = const [],
    String rawVariable = '',
  ]) {
    final variable = map.keys;
    return '''${isMultipart ? 'final Map<String, List<File>>? files;' : ''}
    ${rawVariable.isNotEmpty ? rawVariable : ''}
    ${paramPath.map((e) => 'final String ${e.camelCase};').join('\n')}
    ${variable.map((e) => 'final ${getTypeVariable(e, map[e], suffix, listClassName, parent)}${getTypeVariable(e, map[e], suffix, listClassName, parent) != 'dynamic' ? '?' : ''} ${e.toString().camelCase}').join(';  \n')}${variable.isNotEmpty ? ';' : ''}''';
  }

  String setPropsEquatable(
    Map map, [
    bool isMultipart = false,
    List<String> paramPath = const [],
    String rawVariable = '',
  ]) {
    final variable = map.keys;

    if (variable.isEmpty && paramPath.isEmpty && !isMultipart) {
      return '''@override
  List<Object?> get props => [${rawVariable.isNotEmpty ? rawVariable : ''}];''';
    }
    return '''@override
  List<Object?> get props => [${rawVariable.isNotEmpty ? rawVariable : ''} ${isMultipart ? 'files,' : ''} ${paramPath.isEmpty ? '' : paramPath.map((e) => '${e.camelCase},').join()} ${variable.map((e) => '${e.toString().camelCase},').join()}];''';
  }

  String getVariableToMap(String key, dynamic value) {
    final variable = key.camelCase;
    if (value is Map) {
      return '$variable?.toMap()';
    }
    if (value is List) {
      if (value.isNotEmpty) {
        if (value.first is Map) {
          return '$variable?.map((e) => e.toMap(),).toList()';
        }
      }
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
          .hasMatch(value)) {
        return '$variable?$responseDateFormat';
      }
    }
    return variable;
  }

  String getVariableToMapBody(String key, dynamic value) {
    final variable = key.camelCase;
    if (value is Map) {
      return '$variable?.toMap()';
    }
    if (value is List) {
      if (value.isNotEmpty) {
        if (value.first is Map) {
          return '$variable?.map((e) => e.toMap(),).toList()';
        }
      }
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
          .hasMatch(value)) {
        return '$variable?$bodyDateFormat';
      }
    }
    return variable;
  }

  String toMap(Map map) {
    final variable = map.keys;
    return '''Map<String, dynamic> toMap() {
    return {
      ${variable.map((e) => "'${e.toString()}': ${getVariableToMap(e, map[e])}").join(',      \n')}${variable.isNotEmpty ? ',' : ''}
    };
  }''';
  }

  String toMapBody(Map map) {
    final variable = map.keys;
    return '''Map<String, dynamic> toMap() {
    return {
      if (rawBody?.isNotEmpty ?? false) ...rawBody ?? {},
      ${variable.map((e) => "if (${e.toString().camelCase} != null)  '${e.toString()}': ${getVariableToMapBody(e, map[e])}").join(',      \n')}${variable.isNotEmpty ? ',' : ''}
    };
  }''';
  }

  String fromMap(String apiClassName, Map map, String suffix,
      List<ModelClassName> listClassName, String parent) {
    final variable = map.keys;
    return '''factory $apiClassName.fromMap(Map<String, dynamic> map,) {
    return ${variable.isEmpty ? 'const' : ''} $apiClassName(
      ${variable.map((e) => "${e.toString().camelCase}: ${getVariableFromMap(e, map[e], suffix, listClassName, parent)}").join(',      \n')}${variable.isNotEmpty ? ',' : ''}
    );
  }''';
  }

  String getVariableFromMap(String key, dynamic value, String suffix,
      List<ModelClassName> listClassName, String parent) {
    final variable = "map['$key']";
    if (value is int) {
      return "int.tryParse($variable?.toString() ?? '')";
    }
    if (value is double) {
      return "double.tryParse($variable?.toString() ?? '')";
    }
    if (value is bool) {
      return variable;
    }
    if (value is Map) {
      final data =
          '${ModelClassNameHelper.getClassName(listClassName, suffix, key.pascalCase, false, false, parent)}.fromMap($variable,)';
      return '$variable == null ? null : $data';
    }
    if (value is List) {
      if (value.isNotEmpty) {
        if (value.first is Map) {
          final data =
              'List.from(($variable as List).where((element) => element != null).map((e) => ${ModelClassNameHelper.getClassName(listClassName, suffix, key.pascalCase, false, false, parent)}.fromMap(e)),)';
          return '$variable is List ? $data : null';
        } else if (value.first is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
                .hasMatch(value.first)) {
          final data =
              'List.from(($variable as List).where((element) => element != null).map((e) => DateTime.parse($variable)}.fromMap(e)),)';
          return '$variable is List ? $data : null';
        } else {
          // final data = 'List.from($variable)';
          final variableList = value.firstOrNull;
          final data = 'List.from($variable)';
          if (variableList is int) {
            return '$variable is List ? List.from(($variable as List).where((element) => element != null).map((e) => int.tryParse(e.toString()) ?? 0),) : null';
          }
          if (variableList is double) {
            return '$variable is List ? List.from(($variable as List).where((element) => element != null).map((e) => double.tryParse(e.toString()) ?? 0),) : null';
          }
          return '$variable is List ? $data : null';
        }
      }
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
          .hasMatch(value)) {
        return "DateTime.tryParse($variable ?? '')";
      } else {
        return variable;
      }
    }
    return variable;
  }

  String getBodyClass(
    String suffix,
    String name,
    String parent,
    Map? map, [
    bool root = false,
    bool isMultipart = false,
    List<String> paramPath = const [],
  ]) {
    if (map == null) return '';
    final apiClassName = ModelClassNameHelper.getClassName(
        listClassNameBody, suffix, name, root, true, parent);
    final classString = '''class $apiClassName extends Equatable {
  ${setConstractorBody(apiClassName, map, isMultipart, paramPath)}

  ${setTypeData(map, suffix, listClassNameBody, apiClassName, isMultipart, paramPath, '  final Map<String, dynamic>? rawBody;')}

  ${toMapBody(map)}

  ${setPropsEquatable(map, isMultipart, paramPath, 'rawBody,')}
}
${map.keys.map((e) => map[e] is Map ? getBodyClass(suffix, e.toString().pascalCase, apiClassName, map[e], false) : '').join()}
${map.keys.map((e) => map[e] is List ? map[e] == null ? '' : (map[e] as List).isEmpty ? '' : (map[e] as List).first is! Map ? '' : getBodyClass(suffix, e.toString().pascalCase, apiClassName, (map[e] as List).first, false) : '').join()}
''';

    return classString;
  }

  String getResponseClass(String suffix, String name, String parent, Map? map,
      [bool root = false]) {
    if (map == null) return '';
    final apiClassName = ModelClassNameHelper.getClassName(
        listClassNameResponse, suffix, name, root, true, parent);
    final classString = '''class $apiClassName extends Equatable {
  ${setConstractor(apiClassName, map)}

  ${fromMap(apiClassName, map, suffix, listClassNameResponse, apiClassName)}

  factory $apiClassName.fromJson(String source) =>
      $apiClassName.fromMap(json.decode(source));

  ${setTypeData(map, suffix, listClassNameResponse, apiClassName)}

  ${toMap(map)}

  String toJson() => json.encode(toMap());

  ${setPropsEquatable(map)}
}

${map.keys.map((e) => map[e] is Map ? getResponseClass(suffix, e.toString().pascalCase, apiClassName, map[e]) : '').join()}
${map.keys.map((e) => map[e] is List ? map[e] == null ? '' : (map[e] as List).isEmpty ? '' : (map[e] as List).first is! Map ? '' : getResponseClass(suffix, e.toString().pascalCase, apiClassName, (map[e] as List).first) : '').join()}
''';

    return classString;
  }

  String getEntityClass(String suffix, String name, String parent, Map? map,
      [bool root = false]) {
    if (map == null) return '';
    final apiClassName = ModelClassNameHelper.getClassName(
        listClassNameEntity, suffix, name, root, true, parent);
    final classString = '''class $apiClassName extends Equatable {
  ${setConstractor(apiClassName, map)}

  ${setTypeData(map, suffix, listClassNameEntity, apiClassName)}

  $apiClassName copyWith({
    ${map.keys.map((e) => '${getTypeVariable(e, map[e], suffix, listClassNameEntity, apiClassName)}? ${e.toString().camelCase},').join('\n    ')}
  }) {
    return $apiClassName(
      ${map.keys.map((e) => '${e.toString().camelCase}: ${e.toString().camelCase} ?? this.${e.toString().camelCase},').join('\n      ')}
    );
  }

  ${setPropsEquatable(map)}
}

${map.keys.map((e) => map[e] is Map ? getEntityClass(suffix, e.toString().pascalCase, apiClassName, map[e]) : '').join()}
${map.keys.map((e) => map[e] is List ? map[e] == null ? '' : (map[e] as List).isEmpty ? '' : (map[e] as List).first is! Map ? '' : getEntityClass(suffix, e.toString().pascalCase, apiClassName, (map[e] as List).first) : '').join()}
''';

    return classString;
  }

  void appendMapper(
    String pathPage,
    String apiName,
    dynamic response,
  ) {
    String extensionMapper = getExtensionMapper(
      apiName.pascalCase,
      '',
      '',
      response,
      null,
      false,
      true,
    );

    final path = pathPage;
    DirectoryHelper.createDir(path);
    join(path, 'mapper.dart').append(extensionMapper);
  }

  String getExtensionMapper(
    String suffix,
    String name,
    String parent,
    Map? map,
    String? parentList,
    bool fromList, [
    bool root = false,
  ]) {
    if (map == null) return '';
    final variable = map.keys;
    final asClassNameResponse = '${suffix.snakeCase}_response';
    final asClassNameEntity = '${suffix.snakeCase}_entity';
    final apiClassName = ModelClassNameHelper.getClassName(
      listClassNameMapper,
      suffix,
      name,
      root,
      true,
      parent,
      parentList != null && fromList ? parentList + parent : parent,
    );
    final apiClassNameResponse = '$apiClassName${root ? 'Response' : ''}';
    final apiClassNameEntity = '$apiClassName${root ? 'Entity' : ''}';

    final parentOfChild = parentList != null && fromList
        ? parentList + apiClassName
        : apiClassName;

    for (var e in variable) {
      if (map[e] is Map) {
        ModelClassNameHelper.getClassName(
          listClassNameMapper,
          suffix,
          e.toString().pascalCase,
          root,
          false,
          apiClassName,
          parentOfChild,
        );
      }
    }

    for (var e in variable) {
      final list = map[e];
      if (list is List && list.isNotEmpty && list.first is Map) {
        ModelClassNameHelper.getClassName(
          listClassNameMapper,
          suffix,
          e.toString().pascalCase,
          root,
          false,
          apiClassName,
          parentOfChild,
        );
      }
    }

    final classString =
        '''extension $apiClassNameResponse${root ? '' : 'Response'}Mapper on $asClassNameResponse.$apiClassNameResponse {
  $asClassNameEntity.$apiClassNameEntity toEntity() => ${variable.isEmpty ? 'const' : ''} $asClassNameEntity.$apiClassNameEntity(${setVariableEntity(map, TypeMapper.toEntity)});
}

extension $apiClassNameEntity${root ? '' : 'Entity'}Mapper on $asClassNameEntity.$apiClassNameEntity {
  $asClassNameResponse.$apiClassNameResponse toResponse() => ${variable.isEmpty ? 'const' : ''} $asClassNameResponse.$apiClassNameResponse(${setVariableEntity(map, TypeMapper.toResponse)});
}

${map.keys.map((e) => map[e] is Map ? getExtensionMapper(suffix, e.toString().pascalCase, apiClassName, map[e], parentOfChild, false) : '').join()}
${map.keys.map((e) => map[e] is List ? map[e] == null ? '' : (map[e] as List).isEmpty ? '' : (map[e] as List).first is! Map ? '' : getExtensionMapper(suffix, e.toString().pascalCase, apiClassName, (map[e] as List).first, parentOfChild, true) : '').join()}''';

    return classString;
  }

  String setVariableEntity(Map map, TypeMapper typeMapper) {
    final variable = map.keys;
    return '${variable.map((e) => '${e.toString().camelCase}: ${setValueVariableMapper(e, map[e], typeMapper)}').join(',\n')}${variable.isNotEmpty ? ',' : ''}';
  }

  String setValueVariableMapper(
      String key, dynamic value, TypeMapper typeMapper) {
    if (value is List && value.firstOrNull is Map) {
      return '${key.camelCase}?.map((e) => e.${typeMapper == TypeMapper.toEntity ? 'toEntity' : 'toResponse'}()).toList()';
    } else if (value is Map) {
      return '${key.camelCase}?.${typeMapper == TypeMapper.toEntity ? 'toEntity' : 'toResponse'}()';
    } else {
      return key.camelCase;
    }
  }

  void removeFile(String path) {
    if (exists(path)) {
      delete(path);
    }
  }

  void removeDir(String path) {
    if (exists(path)) {
      deleteDir(path);
    }
  }

  void removeAllRelatedApiPage(
    String pathPage,
    String pageName,
    Map pageValue,
    bool isReplace,
  ) {
    removeFile(join(pathPage, 'locator.dart'));
    removeFile(join(pathPage, 'mapper.dart'));

    if (isReplace) {
      final api = pageValue.keys;
      final pathDataDatasources = join(pathPage, 'data', 'datasources',
          '${pageName.snakeCase}_remote_data_source.dart');
      if (exists(pathDataDatasources)) {
        String classDataDatasources = readFile(pathDataDatasources);
        for (var element in api) {
          classDataDatasources = classDataDatasources.replaceAll(
            RegExp(
                '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${element.toString().snakeCase}_(\\w+)\\.dart(\\\'|\\");)|(([a-zA-Z\\<\\>\\s]+)${element.toString().camelCase}([a-zA-Z\\s\\(\\)]+);)|((\\@override)(\\s+)([a-zA-Z\\<\\>\\s]+)${element.toString().camelCase}([a-zA-Z\\d\\<\\>\\s\\(\\)\\{=\\.\\,\\:\\;]+)})'),
            '',
          );
        }
        if (!RegExp(r'}(\s+)?}').hasMatch(classDataDatasources)) {
          classDataDatasources += '}';
        }
        pathDataDatasources.write(classDataDatasources);
      }

      final pathDataRepositories = join(pathPage, 'data', 'repositories',
          '${pageName.snakeCase}_repository_impl.dart');
      if (exists(pathDataDatasources)) {
        String dataDataRepositories = readFile(pathDataRepositories);
        for (var element in api) {
          dataDataRepositories = dataDataRepositories.replaceAll(
            RegExp(
                '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${element.toString().snakeCase}_(\\w+)\\.dart(\\\'|\\");)|((\\@override)(\\s+)([a-zA-Z\\<\\>\\s\\,]+)${element.toString().camelCase}([a-zA-Z\\<\\>\\s\\(\\)\\{\\}=\\.\\,\\:\\;]+);(\\s+)?}(\\s+)?})'),
            '',
          );
        }
        if (!RegExp(r'}(\s+)?}(\s+)?}').hasMatch(dataDataRepositories)) {
          dataDataRepositories += '}}';
        }
        pathDataRepositories.write(dataDataRepositories);
      }

      final pathDomainRepositories = join(pathPage, 'domain', 'repositories',
          '${pageName.snakeCase}_repository.dart');
      if (exists(pathDataDatasources)) {
        String classDomainRepositories = readFile(pathDomainRepositories);
        for (var element in api) {
          classDomainRepositories = classDomainRepositories.replaceAll(
            RegExp(
                '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${element.toString().snakeCase}_(\\w+)\\.dart(\\\'|\\");)|(([a-zA-Z\\<\\>\\s\\,]+)${element.toString().camelCase}([a-zA-Z\\s\\(\\)]+);)'),
            '',
          );
        }
        pathDomainRepositories.write(classDomainRepositories);
      }

      final pathDataModels = join(pathPage, 'data', 'models');
      final pathDomainEntities = join(pathPage, 'domain', 'entities');
      final pathDomainUsecases = join(pathPage, 'domain', 'usecases');
      final pathPresentationBloc = join(pathPage, 'presentation', 'bloc');
      for (var element in api) {
        final body = join(pathDataModels, 'body',
            '${element.toString().snakeCase}_body.dart');
        final response = join(pathDataModels, 'response',
            '${element.toString().snakeCase}_response.dart');
        final entity = join(
            pathDomainEntities, '${element.toString().snakeCase}_entity.dart');
        final useCase = join(pathDomainUsecases,
            '${element.toString().snakeCase}_use_case.dart');
        final bloc = join(pathPresentationBloc, element.toString().snakeCase);
        removeFile(body);
        removeFile(response);
        removeFile(entity);
        removeFile(useCase);
        removeDir(bloc);
      }
    } else {
      removeDir(join(pathPage, 'data'));
      removeDir(join(pathPage, 'domain'));
      removeDir(join(pathPage, 'presentation', 'bloc'));
    }
  }

  void removeAllRelatedApiPageUnitTest(String featureName, String pageName) {
    final pathTestPage =
        join(current, 'features', featureName, 'test', '${pageName}_test');
    removeFile(join(pathTestPage, 'mapper.dart'));
    removeDir(join(pathTestPage, 'json'));
    removeDir(join(pathTestPage, 'data'));
    removeDir(join(pathTestPage, 'domain'));
    removeDir(join(pathTestPage, 'presentation', 'bloc'));
  }

  String getValueUnitTest(
    String key,
    dynamic value,
    String suffix,
    String parent,
    String asImport, [
    String? parentList,
  ]) {
    final variable = key.camelCase;
    if (value is Map) {
      final apiClassName = ModelClassNameHelper.getClassName(
        listClassNameUnitTest,
        suffix,
        key.pascalCase,
        false,
        true,
        parent,
        parentList,
      );

      List<String> children = [];

      value.forEach((key, child) {
        if (child is Map) {
          children.add(getValueUnitTest(key.toString(), child, suffix,
              apiClassName, asImport, parentList));
        }
      });
      value.forEach((key, child) {
        if (child is List) {
          children.add(getValueUnitTest(key.toString(), child, suffix,
              apiClassName, asImport, parentList));
        }
      });
      value.forEach((key, child) {
        if (child is! List && child is! Map) {
          children.add(getValueUnitTest(key.toString(), child, suffix,
              apiClassName, asImport, parentList));
        }
      });
      return '$variable: $asImport.$apiClassName(${children.join(',')})';
    }
    if (value is List) {
      if (value.isNotEmpty) {
        if (value.first is Map) {
          String list = '[';
          final apiClassName = ModelClassNameHelper.getClassName(
            listClassNameUnitTest,
            suffix,
            key.pascalCase,
            false,
            true,
            parent,
            parentList != null ? parentList + parent : parent,
          );

          final parentOfChild =
              parentList != null ? parentList + apiClassName : apiClassName;

          for (var element in value) {
            List<String> children = [];

            final value = element as Map;

            value.forEach((key, child) {
              if (child is Map) {
                children.add(getValueUnitTest(key.toString(), child, suffix,
                    apiClassName, asImport, parentOfChild));
              }
            });
            value.forEach((key, child) {
              if (child is List) {
                children.add(getValueUnitTest(key.toString(), child, suffix,
                    apiClassName, asImport, parentOfChild));
              }
            });
            value.forEach((key, child) {
              if (child is! List && child is! Map) {
                children.add(getValueUnitTest(key.toString(), child, suffix,
                    apiClassName, asImport, parentOfChild));
              }
            });

            list += '$asImport.$apiClassName(${children.join(',')}),';
          }
          list += ']';
          return '$variable: $list';
        } else if (value.first is String) {
          return '$variable: [${value.map((e) => "'$e'").join(',')}]';
        } else {
          return '$variable: [${value.join(',')}]';
        }
      } else {
        return '$variable: []';
      }
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?$')
          .hasMatch(value)) {
        return '$variable: ${"DateTime.tryParse('$value')"}';
      }
      return "$variable: '$value'";
    }
    return '$variable: ${value.toString()}';
  }

  String getBodyVariableUnitTest(
      String apiName, dynamic body, String parent, List<String> paramPath) {
    final List<Map> data = [];
    if (body is List) {
      for (var element in body) {
        data.add(element);
      }
    } else if (body is Map) {
      data.add(body);
    }

    List<String> result = [];
    listClassNameUnitTest.clear();

    for (var element in data) {
      final keys = element.keys;
      final variables = keys
          .map((e) => getValueUnitTest(e.toString(), element[e],
              apiName.pascalCase, parent, 'body_${apiName.snakeCase}'))
          .join(',');
      result.add(
          'body_${apiName.snakeCase}.${apiName.pascalCase}Body(${paramPath.map((e) => "${e.camelCase}: '$e',").join()} $variables${variables.isNotEmpty ? ',' : ''})');
    }

    if (result.length > 1) {
      return '[${result.join(',')}];';
    } else {
      return '${result.join(',')};';
    }
  }

  String getResponseVariableUnitTest(
    String apiName,
    dynamic body,
    String parent, {
    String suffix = 'Response',
    String variable = 'response',
  }) {
    final List<Map> data = [];
    if (body is List) {
      for (var element in body) {
        data.add(element);
      }
    } else if (body is Map) {
      data.add(body);
    }

    List<String> result = [];
    listClassNameUnitTest.clear();

    for (var element in data) {
      final keys = element.keys;
      listClassNameUnitTest.clear();
      final variables = keys
          .map((e) => getValueUnitTest(e.toString(), element[e],
              apiName.pascalCase, '', '${variable}_${apiName.snakeCase}'))
          .join(',');
      result.add(
          '${variable}_${apiName.snakeCase}.${apiName.pascalCase}$suffix($variables${variables.isNotEmpty ? ',' : ''})');
    }

    if (result.length > 1) {
      return '[${result.join(',')}];';
    } else {
      return '${result.join(',')};';
    }
  }

  String getConstOrFinalValue(String value) {
    if (RegExp(r'\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?')
        .hasMatch(value)) {
      return 'final';
    } else {
      return 'const';
    }
  }

  Map<String, String> createModelUnitTest({
    required String pathTestPage,
    required String appsName,
    required String featureName,
    required String pageName,
    required String pathPage,
    required String apiName,
    required dynamic jsonBody,
    required dynamic jsonResponse,
    required dynamic body,
    required dynamic response,
    required String method,
    required List<String> paramPath,
    required String? pathHeader,
    required String? cacheStrategy,
    required int? ttl,
    required bool? keepExpiredCache,
    required String returnData,
  }) {
    Map<String, String> result = {};

    final endpoint =
        'final url${apiName.pascalCase} = ${projectName.pascalCase}Endpoints.${apiName.camelCase}${appsName.pascalCase}${paramPath.isEmpty ? '' : '(${paramPath.map((e) => "'$e',").join()})'};';

    final bodyVariable = getBodyVariableUnitTest(apiName, body, '', paramPath);
    createDataModelBodyTest(
      pathTestPage,
      featureName,
      pageName,
      apiName,
      jsonBody,
      bodyVariable,
      body is List,
    );

    final responseVariable = isReturnDataModel(returnData)
        ? getResponseVariableUnitTest(
            apiName,
            response,
            '',
            suffix: 'Response',
            variable: 'response',
          )
        : '';
    final entityVariable = isReturnDataModel(returnData)
        ? getResponseVariableUnitTest(
            apiName,
            response,
            '',
            suffix: 'Entity',
            variable: 'entity',
          )
        : '';

    final formattedJsonString = isReturnDataModel(returnData)
        ? createJsonResponseTest(
            pathTestPage,
            featureName,
            pageName,
            apiName,
            jsonResponse,
          )
        : '';

    if (isReturnDataModel(returnData)) {
      createDataModelResponseTest(
        pathTestPage,
        featureName,
        pageName,
        apiName,
        formattedJsonString,
        responseVariable,
        response is List,
      );
    }

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
          'headers: $headers.map((key, value) => MapEntry(key, value.toString()))';
    }

    result['apiName'] = apiName;
    result['body'] = bodyVariable;
    result['response'] = responseVariable;
    result['entity'] = entityVariable;
    result['jsonBody'] = jsonBody;
    result['jsonResponse'] = jsonResponse;
    result['method'] = method;
    result['endpoint'] = endpoint;
    result['header'] = headers ?? '';
    result['isBodyList'] = body is List ? 'true' : 'false';
    result['isResponseList'] = response is List ? 'true' : 'false';
    result['cacheStrategy'] = cacheStrategy ?? '';
    result['ttl'] = ttl?.toString() ?? '';
    result['keepExpiredCache'] = keepExpiredCache?.toString() ?? '';
    result['returnData'] = returnData;

    return result;
  }

  void handleUnitTest({
    required String pathTestPage,
    required String featureName,
    required String pageName,
    required Map pageValue,
    required List<Map<String, String>> resultModelUnitTest,
  }) {
    createDataDataSourceTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createDataRepositoryTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);

    createDomainEntityTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createDomainRepositoryTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createDomainUseCaseTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);

    createPresentationBlocTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createPresentationCubitTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createPresentationPageTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);
    createPresentationWidgetTest(
        pathTestPage, featureName, pageName, resultModelUnitTest);

    createMapperTest(pathTestPage, featureName, pageName, resultModelUnitTest);
  }

  String getChangeDateTimeFromMapJson(String json) {
    return json.replaceAllMapped(
      regexDateTime,
      (match) => 'DateTime.tryParse(${match.group(0)})?$responseDateFormat',
    );
  }

  String getChangeDateTimeFromMapJsonBody(String json) {
    return json.replaceAllMapped(
      regexDateTime,
      (match) => 'DateTime.tryParse(${match.group(0)})?$bodyDateFormat',
    );
  }

  void createDataModelBodyTest(
    String pathTestPage,
    String featureName,
    String pageName,
    String apiName,
    dynamic jsonBody,
    String bodyVariable,
    bool isBodyList,
  ) {
    final path = join(pathTestPage, 'data', 'models', 'body');
    DirectoryHelper.createDir(path);
    join(path, '${apiName.snakeCase}_body_test.dart').write(
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable
        
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';
import 'package:$featureName/$pageName/data/models/body/${apiName.snakeCase}_body.dart' as body_${apiName.snakeCase};

Future<void> main() async {
  initializeDateFormatting();

  test('Test body convert to map', () {
    ${getConstOrFinalValue(bodyVariable)} body${apiName.pascalCase} = $bodyVariable

    final map = ${isBodyList ? 'body${apiName.pascalCase}.map((e) => e.toMap()).toList()' : 'body${apiName.pascalCase}.toMap()'};

    expect(map, ${getChangeDateTimeFromMapJsonBody(jsonBody)});
  });
}''');

    StatusHelper.generated(join(path, '${pageName}_body_test.dart'));
  }

  void createDataModelResponseTest(
    String pathTestPage,
    String featureName,
    String pageName,
    String apiName,
    dynamic jsonResponse,
    dynamic responseVariable,
    bool isResponseList,
  ) {
    final path = join(pathTestPage, 'data', 'models', 'response');
    DirectoryHelper.createDir(path);

    join(path, '${apiName.snakeCase}_response_test.dart').write(
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable

${isResponseList ? "import 'dart:convert';" : ''}
        
import 'package:core/core.dart';
import 'package:$featureName/$pageName/mapper.dart';
import 'package:$featureName/$pageName/data/models/response/${apiName.snakeCase}_response.dart' as response_${apiName.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${apiName.snakeCase}_entity.dart' as entity_${apiName.snakeCase};
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

Future<void> main() async {
  initializeDateFormatting();

  ${getConstOrFinalValue(responseVariable)} response${apiName.pascalCase} = $responseVariable
  final ${isResponseList ? 'List<Map<String, dynamic>>' : 'Map<String, dynamic>'} map = ${getChangeDateTimeFromMapJson(jsonResponse)};

  ${isResponseList ? '''test('mapper response model to ${apiName.pascalCase}Entity entity', () async {
    expect(response${apiName.pascalCase}.map((e) => e.toEntity()).toList(), isA<List<entity_${apiName.snakeCase}.${apiName.pascalCase}Entity>>());
  });''' : '''test('mapper response model to ${apiName.pascalCase}Entity entity', () async {
    expect(response${apiName.pascalCase}.toEntity(), isA<entity_${apiName.snakeCase}.${apiName.pascalCase}Entity>());
  });'''}
  

  group('fromJson', () {
    test(
      'should return a valid model when the JSON is real data',
      () async {
        // arrange
        final json = readJsonFile('test/${pageName}_test/json/${apiName}_success.json');
        // act
        ${isResponseList ? '''final mapResponse = jsonDecode(json);
        final result = mapResponse is List
            ? List.from(
                mapResponse.map((e) => response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(e)))
            : [response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(mapResponse)];''' : 'final result = response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromJson(json);'}
        // assert
        expect(result, response${apiName.pascalCase});
      },
    );
  });

  group('fromMap', () {
    test(
      'should return a valid model when the Map is an map of response model',
      () async {
        // act
        ${isResponseList ? '''final result = map
            .map((e) =>
                response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(e))
            .toList();''' : 'final result = response_${apiName.snakeCase}.${apiName.pascalCase}Response.fromMap(map);'}
        // assert
        expect(result, response${apiName.pascalCase});
      },
    );
  });

  group('toMap', () {
    test(
      'should return a map containing the proper model',
      () async {
        // act
        ${isResponseList ? 'final result = response${apiName.pascalCase}.map((e) => e.toMap()).toList();' : 'final result = response${apiName.pascalCase}.toMap();'}
        // assert
        expect(result, map);
      },
    );
  });

  group('toJson', () {
    test(
      'should return a JSON String containing the proper model',
      () async {
        // act
        ${isResponseList ? 'final result = jsonEncode(response${apiName.pascalCase});' : 'final result = response${apiName.pascalCase}.toJson();'}
        // assert
        expect(result, isA<String>());
      },
    );
  });
}''');

    StatusHelper.generated(join(path, '${pageName}_response_test.dart'));
  }

  String createJsonResponseTest(
    String pathTestPage,
    String featureName,
    String pageName,
    String apiName,
    String jsonResponse,
  ) {
    final path = join(pathTestPage, 'json');

    DirectoryHelper.createDir(path);
    String formattedJsonString = jsonResponse.toString();

    try {
      Map<String, dynamic> jsonObject = json.decode(jsonResponse);
      jsonObject = processJson(jsonObject);
      formattedJsonString = json.encode(jsonObject);
    } catch (_) {}

    join(path, '${apiName.snakeCase}_success.json').write(formattedJsonString);

    StatusHelper.generated(join(path, '${apiName.snakeCase}_success.json'));

    return formattedJsonString;
  }

  void createDataDataSourceTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'data', 'datasources');
    DirectoryHelper.createDir(path);
    join(path, '${pageName}_remote_data_source_test.dart').write(
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, unused_local_variable

import 'dart:convert';
${resultModelUnitTest.any((element) => element['returnData'] == 'body_bytes') ? '''import 'dart:typed_data';''' : ''}
        
import 'package:${featureName.snakeCase}/$pageName/data/datasources/${pageName}_remote_data_source.dart';
${resultModelUnitTest.map((e) => '''import 'package:${featureName.snakeCase}/$pageName/data/models/body/${e['apiName']?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${isReturnDataModel(e['returnData']!) ? '''import 'package:${featureName.snakeCase}/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};''' : ''}''').join('\n')}
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockMorphemeHttp extends Mock implements MorphemeHttp {}

Future<void> main() async {
  initializeDateFormatting();

  late MockMorphemeHttp http;
  late ${pageName.pascalCase}RemoteDataSource remoteDataSource;

  ${resultModelUnitTest.map((e) => '''${e['endpoint']}
  ${getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}''').join('\n')}

  setUp(() {
    http = MockMorphemeHttp();
    remoteDataSource = ${pageName.pascalCase}RemoteDataSourceImpl(http: http);
  });

  ${resultModelUnitTest.map((e) {
      final className = e['apiName']?.pascalCase;
      final methodName = e['apiName']?.camelCase;
      final returnData = e['returnData'] ?? 'model';

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];
      final header = e['header']?.isEmpty ?? true ? '' : '${e['header']},';
      final body = (e['isBodyList'] == 'true' && !isMultipart)
          ? 'jsonEncode(body$className.map((e) => e.toMap()).toList()),'
          : 'body$className.toMap()${isMultipart ? '.map((key, value) => MapEntry(key, value.toString()))' : ''},';
      final cacheStrategy = e['cacheStrategy']?.isEmpty ?? true
          ? null
          : CacheStrategy.fromString(e['cacheStrategy']!);
      final ttl =
          e['ttl']?.isEmpty ?? true ? null : int.tryParse(e['ttl'] ?? '');
      final keepExpiredCache = e['keepExpiredCache']?.isEmpty ?? true
          ? null
          : e['keepExpiredCache'] == 'true';

      final paramCacheStrategy = cacheStrategy == null || isMultipart
          ? ''
          : '${cacheStrategy.toParamCacheStrategy(ttl: ttl, keepExpiredCache: keepExpiredCache)},';

      final expectSuccess = switch (returnData) {
        'header' => '''expect(result, isA<Map<String, String>>());''',
        'body_bytes' => '''expect(result, isA<Uint8List>());''',
        'body_string' => '''expect(result, isA<String>());''',
        'status_code' => '''expect(result, isA<int>());''',
        'raw' => '''expect(result, isA<Response>());''',
        'model' =>
          '''expect(result, isA<${'response_${className?.snakeCase}'}.${className}Response>());''',
        _ => "''",
      };

      final isCreateTest = whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        return '';
      }

      return '''group('$className Api Remote Data Source', () {
    test(
      'should peform fetch & return response',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenAnswer((_) async => Response('{}', 200));
        // act
        final result = await remoteDataSource.$methodName(body$className);
        // assert
        verify(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy));
        $expectSuccess
      },
    );

    test(
      'should throw a RedirectionException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(RedirectionException(statusCode: 300, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<RedirectionException>()));
      },
    );

    test(
      'should throw a ClientException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(ClientException(statusCode: 400, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<ClientException>()));
      },
    );

    test(
      'should throw a ServerException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(ServerException(statusCode: 500, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<ServerException>()));
      },
    );

    test(
      'should throw a TimeoutException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(TimeoutException());
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<TimeoutException>()));
      },
    );

    test(
      'should throw a UnauthorizedException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(UnauthorizedException(statusCode: 401, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<UnauthorizedException>()));
      },
    );

    test(
      'should throw a RefreshTokenException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(RefreshTokenException(statusCode: 401, jsonBody: '{}'));
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<RefreshTokenException>()));
      },
    );

    test(
      'should throw a NoInternetException when the server error',
      () async {
        // arrange
        when(() => http.$httpMethod(url$className, body: $body$header$paramCacheStrategy)).thenThrow(NoInternetException());
        // act
        final call = remoteDataSource.$methodName;
        // assert
        expect(() => call(body$className), throwsA(isA<NoInternetException>()));
      },
    );
  });
''';
    }).join('\n')}
}''');

    StatusHelper.generated(
        join(path, '${pageName}_remote_data_source_test.dart'));
  }

  void createDataRepositoryTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'data', 'repositories');
    DirectoryHelper.createDir(path);
    join(path, '${pageName}_repository_impl_test.dart').write(
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable

${resultModelUnitTest.any((element) => element['returnData'] == 'body_bytes') ? '''import 'dart:typed_data';''' : ''}
        
import 'package:$featureName/$pageName/data/datasources/${pageName}_remote_data_source.dart';
import 'package:$featureName/$pageName/data/repositories/${pageName}_repository_impl.dart';
${resultModelUnitTest.map((e) => '''import 'package:$featureName/$pageName/data/models/body/${e['apiName']?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${isReturnDataModel(e['returnData']!) ? '''import 'package:$featureName/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${e['apiName']?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : ''}''').join('\n')}
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockRemoteDataSource extends Mock implements ${pageName.pascalCase}RemoteDataSource {}

Future<void> main() async {
  late MockRemoteDataSource mockRemoteDatasource;
  late ${pageName.pascalCase}RepositoryImpl repository;

  setUp(() {
    mockRemoteDatasource = MockRemoteDataSource();
    repository = ${pageName.pascalCase}RepositoryImpl(
      remoteDataSource: mockRemoteDatasource,
    );
  });

  ${resultModelUnitTest.map((e) {
      final className = e['apiName']?.pascalCase;
      final methodName = e['apiName']?.camelCase;
      final returnData = e['returnData'] ?? 'model';

      final responseMock = switch (returnData) {
        'header' => '{}',
        'body_bytes' => 'Uint8List(0)',
        'body_string' => "''",
        'status_code' => '200',
        'raw' => 'Response(\'\' , 200)',
        _ => "response_${className?.snakeCase}.${className}Response()",
      };

      final expectSuccess = switch (returnData) {
        'header' =>
          '''expect(result, isA<Right<MorphemeFailure, Map<String, String>>>(),);''',
        'body_bytes' =>
          '''expect(result, isA<Right<MorphemeFailure, Uint8List>>(),);''',
        'body_string' =>
          '''expect(result, isA<Right<MorphemeFailure, String>>(),);''',
        'status_code' =>
          '''expect(result, isA<Right<MorphemeFailure, int>>(),);''',
        'raw' =>
          '''expect(result, isA<Right<MorphemeFailure, Response>>(),);''',
        'model' =>
          '''expect(result, isA<Right<MorphemeFailure, entity_${className?.snakeCase}.${className}Entity>>(),);''',
        _ => "''",
      };

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];

      final isCreateTest = whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        return '';
      }

      return '''group('$className Api Repository', () {
    ${getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}

    test(
        'should return response data when the call to remote data source is successful',
        () async {
      // arrange
      when(() => mockRemoteDatasource.$methodName(body$className)).thenAnswer((_) async => $responseMock);
      // act
      final result = await repository.$methodName(body$className);
      // assert
      verify(() => mockRemoteDatasource.$methodName(body$className));
      $expectSuccess
    });

    test(
      'should return redirection exception when the call to remote data source is unsuccessful',
      () async {
        final exception = RedirectionException(statusCode: 300, jsonBody: '{}');
        final failure = RedirectionFailure(
          exception.toString(),
          statusCode: 300,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return client failure when the call to remote data source is unsuccessful',
      () async {
        final exception = ClientException(statusCode: 400, jsonBody: '{}');
        final failure = ClientFailure(
          exception.toString(),
          statusCode: 400,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return server failure when the call to remote data source is unsuccessful',
      () async {
        final exception = ServerException(statusCode: 500, jsonBody: '{}');
        final failure = ServerFailure(
          exception.toString(),
          statusCode: 500,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return unauthorized failure when the call to remote data source is unsuccessful',
      () async {
        final exception =
            UnauthorizedException(statusCode: 401, jsonBody: '{}');
        final failure = UnauthorizedFailure(
          exception.toString(),
          statusCode: 401,
          jsonBody: '{}',
        );
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return timeout failure when the call to remote data source is unsuccessful',
      () async {
        final exception = TimeoutException();
        final failure = TimeoutFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return internal failure when the call to remote data source is unsuccessful',
      () async {
        final exception = InternalException();
        final failure = InternalFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return no internet failure when the call to remote data source is unsuccessful',
      () async {
        final exception = NoInternetException();
        final failure = NoInternetFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );

    test(
      'should return internal failure when the call to remote data source is unknown exception',
      () async {
        final exception = Exception('unknown');
        final failure = InternalFailure(exception.toString());
        // arrange
        when(() => mockRemoteDatasource.$methodName(body$className)).thenThrow(exception);
        // act
        final result = await repository.$methodName(body$className);
        // assert
        verify(() => mockRemoteDatasource.$methodName(body$className));
        expect(result, equals(Left(failure)));
      },
    );
  });
''';
    }).join('\n')}
}''');

    StatusHelper.generated(join(path, '${pageName}_repository_impl_test.dart'));
  }

  void createDomainEntityTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'domain', 'entities');
    DirectoryHelper.createDir(path);
    touch(join(path, '.gitkeep'), create: true);

    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createDomainRepositoryTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'domain', 'repositories');
    DirectoryHelper.createDir(path);
    touch(join(path, '.gitkeep'), create: true);

    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createDomainUseCaseTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'domain', 'usecases');
    DirectoryHelper.createDir(path);

    for (var e in resultModelUnitTest) {
      final apiName = e['apiName'];
      final className = apiName?.pascalCase;
      final methodName = apiName?.camelCase;
      final returnData = e['returnData'] ?? 'model';

      final responseMock = switch (returnData) {
        'header' => '{}',
        'body_bytes' => 'Uint8List(0)',
        'body_string' => "''",
        'status_code' => '200',
        'raw' => 'Response(\'\' , 200)',
        _ => "entity_${className?.snakeCase}.${className}Entity()",
      };

      final expectSuccess = switch (returnData) {
        'header' =>
          '''expect(result, isA<Right<MorphemeFailure, Map<String, String>>>(),);''',
        'body_bytes' =>
          '''expect(result, isA<Right<MorphemeFailure, Uint8List>>(),);''',
        'body_string' =>
          '''expect(result, isA<Right<MorphemeFailure, String>>(),);''',
        'status_code' =>
          '''expect(result, isA<Right<MorphemeFailure, int>>(),);''',
        'raw' =>
          '''expect(result, isA<Right<MorphemeFailure, Response>>(),);''',
        'model' =>
          '''expect(result, isA<Right<MorphemeFailure, entity_${className?.snakeCase}.${className}Entity>>(),);''',
        _ => "''",
      };

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];

      final isCreateTest = whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        continue;
      }

      join(path, '${apiName?.snakeCase}_use_case_test.dart').write(
          '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable

${returnData == 'body_bytes' ? '''import 'dart:typed_data';''' : ''}
          
import 'package:$featureName/$pageName/domain/repositories/${pageName}_repository.dart';
import 'package:$featureName/$pageName/data/models/body/${apiName?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${isReturnDataModel(returnData) ? '''import 'package:$featureName/$pageName/domain/entities/${apiName?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : ''}
import 'package:$featureName/$pageName/domain/usecases/${apiName?.snakeCase}_use_case.dart';
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockRepository extends Mock implements ${pageName.pascalCase}Repository {}

Future<void> main() async {
  late ${className}UseCase usecase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    usecase = ${className}UseCase(repository: mockRepository);
  });

  ${getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}

  test(
    'Should fetch entity for the body from the repository',
    () async {
      // arrange
      when(() => mockRepository.$methodName(body$className))
          .thenAnswer((_) async => Right($responseMock));
      // act
      final result = await usecase(body$className);
      // assert
      $expectSuccess
      verify(() => mockRepository.$methodName(body$className));
      verifyNoMoreInteractions(mockRepository);
    },
  );
}''');

      StatusHelper.generated(
          join(path, '${apiName?.snakeCase}_use_case_test.dart'));
    }
  }

  void createPresentationBlocTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'presentation', 'bloc');
    DirectoryHelper.createDir(path);

    for (var e in resultModelUnitTest) {
      final apiName = e['apiName'];
      final className = apiName?.pascalCase;
      final returnData = e['returnData'] ?? 'model';

      final responseMock = switch (returnData) {
        'header' => '{}',
        'body_bytes' => 'Uint8List(0)',
        'body_string' => "''",
        'status_code' => '200',
        'raw' => 'Response(\'\' , 200)',
        _ => "entity_${className?.snakeCase}.${className}Entity()",
      };

      final isMultipart =
          e['method']?.toLowerCase().contains('multipart') ?? false;
      final httpMethod = isMultipart
          ? e['method'] == 'multipart'
              ? 'postMultipart'
              : e['method']
          : e['method'];

      final isCreateTest = whenMethodHttp<bool>(
        httpMethod ?? '',
        onStream: () => false,
        onFuture: () => true,
      );

      if (!isCreateTest) {
        continue;
      }

      join(path, '${apiName?.snakeCase}_bloc_test.dart').write(
          '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable

${resultModelUnitTest.any((element) => element['returnData'] == 'body_bytes') ? '''import 'dart:typed_data';''' : ''}
          
import 'package:$featureName/$pageName/data/models/body/${apiName?.snakeCase}_body.dart' as body_${e['apiName']?.snakeCase};
${isReturnDataModel(returnData) ? '''import 'package:$featureName/$pageName/domain/entities/${apiName?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : ''}
import 'package:$featureName/$pageName/domain/usecases/${apiName?.snakeCase}_use_case.dart';
import 'package:$featureName/$pageName/presentation/bloc/${apiName?.snakeCase}/${apiName?.snakeCase}_bloc.dart';
import 'package:core/core.dart';
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

class MockUseCase extends Mock implements ${className}UseCase {}

Future<void> main() async {
  late ${className}Bloc bloc;
  late MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockUseCase();
    bloc = ${className}Bloc(useCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be Initial', () {
    expect(bloc.state, equals(${className}Initial()));
  });

  group('$className Bloc', () {
    ${getConstOrFinalValue(e['body'] ?? '')} body${e['apiName']?.pascalCase} = ${e['body']}

    const timeoutFailed = TimeoutFailure('TimoutFailure');
    const internalFailed = InternalFailure('InternalFailure');

    const redirectionFailed = RedirectionFailure(
      'RedirectionFailure',
      statusCode: 300,
      jsonBody: '{}',
    );

    const clientFailed = ClientFailure(
      'ClientFailure',
      statusCode: 400,
      jsonBody: '{}',
    );

    const serverFailed = ServerFailure(
      'ServerFailure',
      statusCode: 500,
      jsonBody: '{}',
    );

    const unauthorizedFailed = UnauthorizedFailure(
      'UnauthorizedFailure',
      statusCode: 401,
      jsonBody: '{}',
    );

    blocTest<${className}Bloc, ${className}State>(
      'should get data from the subject use case',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer((_) async => Right($responseMock));
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Success] when data is gotten successfully',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer((_) async => Right($responseMock));
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Success(body$className, null, $responseMock, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting timeout failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(timeoutFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, timeoutFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting unauthorized failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(unauthorizedFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, unauthorizedFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting internal failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(internalFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, internalFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting redirection failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(redirectionFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, redirectionFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting client failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(clientFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, clientFailed, null),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [Loading, Failed] when getting server failed',
      setUp: () {
        when(() => mockUseCase(body$className)).thenAnswer(
          (_) async => Left(serverFailed),
        );
      },
      verify: (bloc) {
        mockUseCase(body$className);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(Fetch$className(body$className)),
      expect: () => [
        ${className}Loading(body$className, null, null),
        ${className}Failed(body$className, null, serverFailed, null),
      ],
    );
  });
}''');

      StatusHelper.generated(
          join(path, '${apiName?.snakeCase}_bloc_test.dart'));
    }
  }

  void createPresentationCubitTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'presentation', 'cubit');
    DirectoryHelper.createDir(path);
    touch(join(path, '.gitkeep'), create: true);

    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createPresentationPageTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'presentation', 'pages');
    DirectoryHelper.createDir(path);
    touch(join(path, '.gitkeep'), create: true);

    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createPresentationWidgetTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = join(pathTestPage, 'presentation', 'widgets');
    DirectoryHelper.createDir(path);
    touch(join(path, '.gitkeep'), create: true);

    StatusHelper.generated(join(path, '.gitkeep'));
  }

  void createMapperTest(
    String pathTestPage,
    String featureName,
    String pageName,
    List<Map<String, String>> resultModelUnitTest,
  ) {
    final path = pathTestPage;
    DirectoryHelper.createDir(path);
    join(path, 'mapper_test.dart').write(
        '''// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable
        
import 'package:$featureName/$pageName/mapper.dart';
${resultModelUnitTest.map((e) => isReturnDataModel(e['returnData']!) ? '''import 'package:$featureName/$pageName/data/models/response/${e['apiName']?.snakeCase}_response.dart' as response_${e['apiName']?.snakeCase};
import 'package:$featureName/$pageName/domain/entities/${e['apiName']?.snakeCase}_entity.dart' as entity_${e['apiName']?.snakeCase};''' : '').join('\n')}
import 'package:dev_dependency_manager/dev_dependency_manager.dart';

Future<void> main() async {
  ${resultModelUnitTest.map((e) {
      if (!isReturnDataModel(e['returnData']!)) return '';

      final className = e['apiName']?.pascalCase;
      final isResponseList = e['isResponseList'] == 'true';

      return '''test('mapper response model to entity $className', () {
    ${getConstOrFinalValue(e['response'] ?? '')} response${e['apiName']?.pascalCase} = ${e['response']}
    ${getConstOrFinalValue(e['entity'] ?? '')} entity${e['apiName']?.pascalCase} = ${e['entity']}

    ${isResponseList ? 'expect(response$className.map((e) => e.toEntity()).toList(), entity$className);' : 'expect(response$className.toEntity(), entity$className);'}
  });

  test('mapper entity to response model $className', () {
    ${getConstOrFinalValue(e['response'] ?? '')} response${e['apiName']?.pascalCase} = ${e['response']}
    ${getConstOrFinalValue(e['entity'] ?? '')} entity${e['apiName']?.pascalCase} = ${e['entity']}

    ${isResponseList ? 'expect(entity$className.map((e) => e.toResponse()).toList(), response$className);' : 'expect(entity$className.toResponse(), response$className);'}
  });
''';
    }).join('\n')}
}''');

    StatusHelper.generated(join(path, 'mapper_test.dart'));
  }

  Map<String, dynamic> processJson(Map<String, dynamic> jsonObject) {
    jsonObject.forEach((key, value) {
      if (value is String) {
        // Apply regex transformation only to date-time strings
        jsonObject[key] = formatDateString(value);
      } else if (value is Map<String, dynamic>) {
        // Recursively process nested objects
        jsonObject[key] = processJson(value);
      } else if (value is List) {
        // Process lists of objects
        jsonObject[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return processJson(item);
          } else if (item is String) {
            return formatDateString(item);
          }
          return item;
        }).toList();
      }
    });
    return jsonObject;
  }

  String formatDateString(String input) {
    // Regular expression to match date-time formats
    RegExp dateTimeRegex =
        RegExp(r'\d{4}-\d{2}-\d{2}(\s|T)?(\d{2}:\d{2}(:\d{2})?)?(\.\d+)?Z?');

    if (dateTimeRegex.hasMatch(input)) {
      final date = DateTime.tryParse(input);

      if (date == null) return input;

      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    }

    // Return input as-is if it's not a date-time string
    return input;
  }
}
