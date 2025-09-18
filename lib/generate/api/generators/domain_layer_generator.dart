import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/status_helper.dart';
import 'package:path/path.dart';

import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';
import '../templates/api_code_templates.dart';

/// Generates domain layer components following clean architecture.
///
/// Creates entities, repository interfaces, and use cases that encapsulate
/// business logic and define the contract for data layer implementations.
class DomainLayerGenerator {
  DomainLayerGenerator({
    required this.typeResolver,
    required this.codeTemplates,
  });

  final ApiTypeResolver typeResolver;
  final ApiCodeTemplates codeTemplates;

  /// Generates complete domain layer for the API.
  ///
  /// Components generated:
  /// - Domain entities (if return data is model type)
  /// - Repository interface defining the contract
  /// - Use case implementation for the API operation
  void generateDomainLayer(ApiGenerationConfig config) {
    if (!config.json2dart && config.isReturnDataModel) {
      generateEntity(config);
    }

    generateRepository(config);
    generateUseCase(config);
  }

  /// Generates domain entity.
  ///
  /// Creates entity classes that represent domain models with business logic
  /// and are independent of external frameworks.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateEntity(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'domain', 'entities');
    createDir(path);

    final filePath = join(path, '${config.apiName}_entity.dart');
    final content = codeTemplates.generateDomainEntityTemplate(config);

    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Generates repository interface.
  ///
  /// Creates the abstract repository that defines the contract for data access
  /// without specifying implementation details.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateRepository(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'domain', 'repositories');
    createDir(path);

    final filePath = join(path, '${config.pageName}_repository.dart');

    if (!exists(filePath)) {
      // Create new repository interface file
      _createNewRepositoryFile(config, filePath);
    } else {
      // Update existing repository interface file
      _updateExistingRepositoryFile(config, filePath);
    }

    StatusHelper.generated(filePath);
  }

  /// Generates use case.
  ///
  /// Creates use case classes that encapsulate business logic and coordinate
  /// between the presentation and data layers.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  void generateUseCase(ApiGenerationConfig config) {
    final path = join(config.pathPage, 'domain', 'usecases');
    createDir(path);

    final filePath = join(path, '${config.apiName}_use_case.dart');
    final content = codeTemplates.generateUseCaseTemplate(config);

    filePath.write(content);
    StatusHelper.generated(filePath);
  }

  /// Creates a new repository interface file
  void _createNewRepositoryFile(ApiGenerationConfig config, String filePath) {
    final content = codeTemplates.generateDomainRepositoryTemplate(config);
    filePath.write(content);
  }

  /// Updates an existing repository interface file by adding new method
  void _updateExistingRepositoryFile(
      ApiGenerationConfig config, String filePath) {
    String data = read(filePath).join('\n');

    // Check if we need to add typed_data import
    final isNeedImportTypeData = config.returnData == 'body_bytes' &&
        !RegExp(r'''import 'dart:typed_data';''').hasMatch(data);

    if (isNeedImportTypeData) {
      data = '''import 'dart:typed_data';
        
        $data''';
    }

    // Update imports section
    data = data.replaceAll(
        RegExp(r"import\s*'package:core/core\.dart';\s*", multiLine: true),
        '''import 'package:core/core.dart';

import '../../data/models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../entities/${config.apiName}_entity.dart';''' : ''}''');

    // Add new method to abstract class
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);

    final methodSignature =
        '''  ${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}});''';

    data = data.replaceAll(RegExp(r'}$', multiLine: true), '''$methodSignature
}''');

    filePath.write(data);
  }
}
