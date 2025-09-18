import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:morpheme_cli/helper/yaml_helper.dart';
import 'package:morpheme_cli/helper/modular_helper.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:morpheme_cli/generate/endpoint/models/endpoint_config.dart';

/// Service for handling endpoint generation logic.
///
/// This service implements the core business logic for generating endpoint files,
/// including deleting old endpoints, generating URI creation methods, and writing
/// the output to files. It automatically processes all json2dart.yaml files found
/// in the json2dart directory.
class EndpointService {
  /// Deletes old endpoint files from the specified directory.
  ///
  /// Parameters:
  /// - [pathDir]: The directory to search for old endpoint files
  void deleteOldEndpoints(String pathDir) {
    final findOld = find(
      '*_endpoints.dart',
      workingDirectory: pathDir,
    ).toList();

    for (var item in findOld) {
      delete(item);
    }
  }

  /// Generates endpoint methods and writes them to the output file.
  ///
  /// Parameters:
  /// - [config]: The endpoint configuration
  Future<void> generateEndpoints(EndpointConfig config) async {
    final StringBuffer file = StringBuffer();

    file.write('abstract class ${config.projectName.pascalCase}Endpoints {\n');

    // Generate URI creation methods
    await _generateUriCreationMethods(file, config.json2DartPaths);

    file.writeln();

    // Generate endpoint methods
    await _generateEndpointMethods(file, config.json2DartPaths);

    file.write('}');

    // Write to output file
    config.outputPath.write(file.toString());
    StatusHelper.generated(config.outputPath);

    // Format the generated code
    final pathDir = join(
      current,
      'core',
      'lib',
      'src',
      'data',
      'remote',
    );
    await ModularHelper.format([pathDir]);
  }

  /// Generates URI creation methods for each base URL.
  ///
  /// Parameters:
  /// - [file]: The StringBuffer to write to
  /// - [json2DartPaths]: List of paths to json2dart.yaml files
  Future<void> _generateUriCreationMethods(
      StringBuffer file, List<String> json2DartPaths) async {
    final Set<String> generatedBaseUrls = <String>{};

    for (var pathJson2Dart in json2DartPaths) {
      if (!exists(pathJson2Dart)) continue;

      final yml = YamlHelper.loadFileYaml(pathJson2Dart);
      Map json2DartMap = Map.from(yml);

      List environmentUrl =
          json2DartMap['json2dart']?['environment_url'] ?? ['BASE_URL'];

      for (var baseUrl in environmentUrl) {
        if (!generatedBaseUrls.contains(baseUrl.toString())) {
          file.writeln(
            '  static Uri _createUri${baseUrl.toString().pascalCase}(String path) => Uri.parse(const String.fromEnvironment(\'$baseUrl\') + path,);',
          );
          generatedBaseUrls.add(baseUrl.toString());
        }
      }
    }
  }

  /// Generates endpoint methods for each API endpoint.
  ///
  /// Parameters:
  /// - [file]: The StringBuffer to write to
  /// - [json2DartPaths]: List of paths to json2dart.yaml files
  Future<void> _generateEndpointMethods(
      StringBuffer file, List<String> json2DartPaths) async {
    final Set<String> generatedMethods = <String>{};

    for (var pathJson2Dart in json2DartPaths) {
      if (!exists(pathJson2Dart)) continue;

      final yml = YamlHelper.loadFileYaml(pathJson2Dart);
      Map json2DartMap = Map.from(yml);

      json2DartMap.forEach((featureName, featureValue) {
        final lastPathJson2Dart = pathJson2Dart.split(separator).last;

        String appsName = '';
        if (lastPathJson2Dart.contains('_')) {
          appsName = lastPathJson2Dart.split('_').first;
        }
        if (featureValue is Map) {
          featureValue.forEach((pageKey, pageValue) {
            if (pageValue is Map) {
              pageValue.forEach((apiKey, apiValue) {
                final baseUrl = apiValue['base_url'] ?? 'BASE_URL';
                final pathUrl = apiValue['path'];
                if (pathUrl != null) {
                  final parameters = <String>[];
                  parse(pathUrl, parameters: parameters);

                  final isHttp =
                      RegExp(r'^(http|https):\/\/').hasMatch(pathUrl);

                  String data = '';

                  if (parameters.isEmpty) {
                    data =
                        "  static Uri ${apiKey.toString().camelCase}${appsName.pascalCase} = ${isHttp ? 'Uri.parse' : '_createUri${baseUrl.toString().pascalCase}'}('$pathUrl',);";
                  } else {
                    final parameterString =
                        parameters.map((e) => 'String ${e.camelCase},').join();
                    final replacePath = parameters
                        .map((e) => ".replaceAll(':$e', ${e.camelCase})")
                        .join();

                    data =
                        "  static Uri ${apiKey.toString().camelCase}${appsName.pascalCase}($parameterString) => ${isHttp ? 'Uri.parse' : '_createUri${baseUrl.toString().pascalCase}'}('$pathUrl'$replacePath,);";
                  }

                  if (!generatedMethods.contains(data)) {
                    file.writeln(data);
                    generatedMethods.add(data);
                  }
                }
              });
            }
          });
        }
      });
    }
  }
}