import 'dart:convert';

import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

/// Service for handling file operations in Json2Dart generation
///
/// This service provides centralized file management including reading JSON files,
/// writing generated code, and managing file cleanup operations.
class FileOperationService {
  /// Reads and parses JSON from a file path
  ///
  /// [path] - File path to read from
  /// [onJsonIsList] - Callback when JSON is an array
  /// [warningMessage] - Warning message for invalid JSON
  /// Returns parsed JSON data or null if invalid
  dynamic readJsonFile(
    String? path, {
    required void Function() onJsonIsList,
    String warningMessage = 'Format json not valid!',
  }) {
    if (path == null) {
      return <String, dynamic>{};
    }

    // Check if file exists, if not return empty map as default
    if (!exists(path)) {
      StatusHelper.warning(
          'JSON file not found: $path, using default value {}');
      return <String, dynamic>{};
    }

    final jsonString = read(path).join('\n');
    dynamic response;

    try {
      response = jsonDecode(jsonString);
      if (response is List) {
        onJsonIsList();
        response = response.first;
      }
    } catch (e) {
      StatusHelper.warning(warningMessage);
      return {};
    }

    if (response is! Map) {
      StatusHelper.warning(warningMessage);
      return {};
    }

    return response;
  }

  /// Writes generated code to a file
  ///
  /// [path] - Directory path
  /// [fileName] - File name
  /// [content] - File content
  void writeGeneratedFile(String path, String fileName, String content) {
    createDir(path);
    final filePath = join(path, fileName);
    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Appends content to an existing file
  ///
  /// [filePath] - Full file path
  /// [content] - Content to append
  void appendToFile(String filePath, String content) {
    createDir(dirname(filePath));
    filePath.append(content);
  }

  /// Creates directory structure if it doesn't exist
  ///
  /// [path] - Directory path to create
  void ensureDirectoryExists(String path) {
    createDir(path);
  }

  /// Removes a file if it exists
  ///
  /// [path] - File path to remove
  void removeFile(String path) {
    if (exists(path)) {
      delete(path);
    }
  }

  /// Removes a directory if it exists
  ///
  /// [path] - Directory path to remove
  void removeDirectory(String path) {
    if (exists(path)) {
      deleteDir(path);
    }
  }

  /// Removes all related API files for a page
  ///
  /// [pathPage] - Page path
  /// [pageName] - Page name
  /// [pageValue] - Page configuration
  /// [isReplace] - Whether to replace files
  void removeAllRelatedApiFiles(
    String pathPage,
    String pageName,
    Map<String, dynamic> pageValue,
    bool isReplace,
  ) {
    removeFile(join(pathPage, 'locator.dart'));
    removeFile(join(pathPage, 'mapper.dart'));

    if (isReplace) {
      _removeSpecificApiFiles(pathPage, pageName, pageValue);
    } else {
      _removeAllApiFiles(pathPage);
    }
  }

  /// Removes all related unit test files for a page
  ///
  /// [featureName] - Feature name
  /// [pageName] - Page name
  void removeAllRelatedUnitTestFiles(String featureName, String pageName) {
    final testPath =
        join(current, 'features', featureName, 'test', '${pageName}_test');
    removeFile(join(testPath, 'mapper.dart'));
    removeDirectory(join(testPath, 'json'));
    removeDirectory(join(testPath, 'data'));
    removeDirectory(join(testPath, 'domain'));
    removeDirectory(join(testPath, 'presentation', 'bloc'));
  }

  /// Creates the initial project structure for Json2Dart
  void createInitialStructure() {
    final path = join(current, 'json2dart');
    createDir(path);

    if (!exists(join(path, 'json2dart.yaml'))) {
      _createInitialConfigFile(path);
    }

    final pathBody = join(path, 'json', 'body');
    final pathResponse = join(path, 'json', 'response');

    createDir(pathBody);
    createDir(pathResponse);

    StatusHelper.success('morpheme json2dart init');
  }

  /// Reads file content safely
  ///
  /// [filePath] - Path to the file
  /// Returns file content or empty string if file doesn't exist
  String readFileContent(String filePath) {
    if (!exists(filePath)) {
      return '';
    }

    try {
      return read(filePath).join('\n');
    } catch (e) {
      StatusHelper.warning('Failed to read file $filePath: $e');
      return '';
    }
  }

  /// Writes content to a file with error handling
  ///
  /// [filePath] - Path to write to
  /// [content] - Content to write
  /// Returns true if successful
  bool writeFileContent(String filePath, String content) {
    try {
      createDir(dirname(filePath));
      filePath.write(content);
      return true;
    } catch (e) {
      StatusHelper.warning('Failed to write file $filePath: $e');
      return false;
    }
  }

  /// Gets file paths for a specific search pattern
  ///
  /// [searchPattern] - Glob pattern to search for
  /// [searchDirectory] - Directory to search in
  /// Returns list of matching file paths
  List<String> findFiles(String searchPattern, String searchDirectory) {
    return find(
      searchPattern,
      workingDirectory: searchDirectory,
    ).toList();
  }

  /// Checks if a file exists
  ///
  /// [path] - File path to check
  /// Returns true if file exists
  bool fileExists(String path) {
    return exists(path);
  }

  /// Private helper methods

  void _removeSpecificApiFiles(
      String pathPage, String pageName, Map<String, dynamic> pageValue) {
    final apis = pageValue.keys;

    // Clean up data sources
    _cleanDataSources(pathPage, pageName, apis);

    // Clean up repositories
    _cleanRepositories(pathPage, pageName, apis);

    // Clean up domain repositories
    _cleanDomainRepositories(pathPage, pageName, apis);

    // Remove specific API files
    for (final api in apis) {
      _removeApiSpecificFiles(pathPage, api.toString());
    }
  }

  void _removeAllApiFiles(String pathPage) {
    removeDirectory(join(pathPage, 'data'));
    removeDirectory(join(pathPage, 'domain'));
    removeDirectory(join(pathPage, 'presentation', 'bloc'));
  }

  void _cleanDataSources(
      String pathPage, String pageName, Iterable<String> apis) {
    final dataSourcePath = join(pathPage, 'data', 'datasources',
        '${pageName.snakeCase}_remote_data_source.dart');
    if (exists(dataSourcePath)) {
      String content = readFileContent(dataSourcePath);
      for (final api in apis) {
        content = _removeApiFromClass(content, api.toString());
      }
      if (!RegExp(r'}(\s+)?}').hasMatch(content)) {
        content += '}';
      }
      writeFileContent(dataSourcePath, content);
    }
  }

  void _cleanRepositories(
      String pathPage, String pageName, Iterable<String> apis) {
    final repositoryPath = join(pathPage, 'data', 'repositories',
        '${pageName.snakeCase}_repository_impl.dart');
    if (exists(repositoryPath)) {
      String content = readFileContent(repositoryPath);
      for (final api in apis) {
        content = _removeApiFromRepository(content, api.toString());
      }
      if (!RegExp(r'}(\s+)?}(\s+)?}').hasMatch(content)) {
        content += '}}';
      }
      writeFileContent(repositoryPath, content);
    }
  }

  void _cleanDomainRepositories(
      String pathPage, String pageName, Iterable<String> apis) {
    final domainRepositoryPath = join(pathPage, 'domain', 'repositories',
        '${pageName.snakeCase}_repository.dart');
    if (exists(domainRepositoryPath)) {
      String content = readFileContent(domainRepositoryPath);
      for (final api in apis) {
        content = _removeApiFromDomainRepository(content, api.toString());
      }
      writeFileContent(domainRepositoryPath, content);
    }
  }

  void _removeApiSpecificFiles(String pathPage, String apiName) {
    final pathDataModels = join(pathPage, 'data', 'models');
    final pathDomainEntities = join(pathPage, 'domain', 'entities');
    final pathDomainUsecases = join(pathPage, 'domain', 'usecases');
    final pathPresentationBloc = join(pathPage, 'presentation', 'bloc');

    removeFile(join(pathDataModels, 'body', '${apiName.snakeCase}_body.dart'));
    removeFile(
        join(pathDataModels, 'response', '${apiName.snakeCase}_response.dart'));
    removeFile(join(pathDomainEntities, '${apiName.snakeCase}_entity.dart'));
    removeFile(join(pathDomainUsecases, '${apiName.snakeCase}_use_case.dart'));
    removeDirectory(join(pathPresentationBloc, apiName.snakeCase));
  }

  String _removeApiFromClass(String content, String apiName) {
    return content.replaceAll(
      RegExp(
        '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${apiName.snakeCase}_(\\w+)\\.dart(\\\'|\\");)|(([a-zA-Z\\<\\>\\s]+)${apiName.camelCase}([a-zA-Z\\s\\(\\)]+);)|((\\@override)(\\s+)([a-zA-Z\\<\\>\\s]+)${apiName.camelCase}([a-zA-Z\\d\\<\\>\\s\\(\\)\\{=\\.\\,\\:\\;]+)})',
      ),
      '',
    );
  }

  String _removeApiFromRepository(String content, String apiName) {
    return content.replaceAll(
      RegExp(
        '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${apiName.snakeCase}_(\\w+)\\.dart(\\\'|\\");)|((\\@override)(\\s+)([a-zA-Z\\<\\>\\s\\,]+)${apiName.camelCase}([a-zA-Z\\<\\>\\s\\(\\)\\{\\}=\\.\\,\\:\\;]+);(\\s+)?}(\\s+)?})',
      ),
      '',
    );
  }

  String _removeApiFromDomainRepository(String content, String apiName) {
    return content.replaceAll(
      RegExp(
        '(import([\\s\\\'\\"\\.a-zA-Z\\/_]+)${apiName.snakeCase}_(\\w+)\\.dart(\\\'|\\");)|(([a-zA-Z\\<\\>\\s\\,]+)${apiName.camelCase}([a-zA-Z\\s\\(\\)]+);)',
      ),
      '',
    );
  }

  void _createInitialConfigFile(String path) {
    final configContent = '''# json2dart for configuration generate
#
# node 1 is feature name
# node 2 is page name
# node 3 is api name can be multiple api in 1 page
#
# method allow: get, post, put, patch, delete, multipart (postMultipart / patchMultipart).
# cache_strategy allow: async_or_cache, cache_or_async, just_async, just_cache. by default set to just_async.
# base_url: base_url for remote api take from String.environment('\$base_url').

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
      body: json2dart/json/body/login_body.json
      response: json2dart/json/response/login_response.json
      cache_strategy: async_or_cache
    .register: &register
      base_url: *base_url
      path: /register
      method: post
      body: json2dart/json/body/register_body.json
      response: json2dart/json/response/register_response.json
      cache_strategy:
        strategy: cache_or_async
        ttl: 60
    .forgot_password: &forgot_password
      base_url: *base_url
      path: /forgot_password
      method: get
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
''';

    join(path, 'json2dart.yaml').write(configContent);
  }
}
