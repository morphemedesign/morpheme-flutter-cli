import 'package:morpheme_cli/enum/cache_strategy.dart';
import 'package:morpheme_cli/helper/recase.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../models/api_generation_config.dart';
import '../resolvers/api_type_resolver.dart';

/// Provides code templates for API generation.
///
/// Contains all template strings and generation logic for creating
/// consistent, well-structured code across all generated components.
class ApiCodeTemplates {
  ApiCodeTemplates({required this.typeResolver});

  final ApiTypeResolver typeResolver;

  /// Generates data source implementation template.
  ///
  /// Creates the remote data source interface and implementation
  /// with proper HTTP method handling and response processing.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  /// - [headers]: Optional headers content from file
  String generateDataSourceTemplate(
    ApiGenerationConfig config, {
    String? headers,
  }) {
    final convert = config.bodyList || config.responseList
        ? "import 'dart:convert';\n\n"
        : '';

    final methodOfDataSource = generateDataSourceMethod(
      config,
      headers: headers,
    );

    return _buildDataSourceFile(config, convert, methodOfDataSource);
  }

  String generateDataSourceMethod(
    ApiGenerationConfig config, {
    String? headers,
  }) {
    final paramPath = <String>[];
    parse(config.pathUrl ?? '', parameters: paramPath);

    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final bodyImpl = config.bodyList
        ? 'body: jsonEncode(body.map((e) => e.toMap()).toList()),'
        : 'body: body.toMap()${typeResolver.isMultipart(config.method) ? '.map((key, value) => MapEntry(key, value.toString()))' : ''},${typeResolver.isMultipart(config.method) ? ' files: body.files,' : ''}';

    final responseClass = typeResolver.whenMethod(
      config.method,
      onStream: () => typeResolver.resolveStreamResponseClass(config),
      onFuture: () => typeResolver.resolveResponseClass(config),
    );

    final responseImpl = typeResolver.whenMethod(
      config.method,
      onStream: () => typeResolver.generateStreamResponseReturn(config),
      onFuture: () => typeResolver.generateResponseReturn(config),
    );

    final apiMethod = typeResolver.isMultipart(config.method)
        ? config.method == 'multipart'
            ? 'postMultipart'
            : config.method
        : config.method;

    final apiEndpoint = paramPath.isEmpty
        ? '${config.projectName.pascalCase}Endpoints.${config.apiMethodName}${config.appsName?.pascalCase ?? ''}'
        : '${config.projectName.pascalCase}Endpoints.${config.apiMethodName}${config.appsName?.pascalCase ?? ''}(${paramPath.map((e) => 'body.${e.camelCase}').join(',')})';

    final apiCacheStrategy = typeResolver.isApplyCacheStrategy(config.method)
        ? config.cacheStrategy.toParamCacheStrategy(
            ttl: config.ttl, keepExpiredCache: config.keepExpiredCache)
        : '';

    final headersConfig = headers != null
        ? 'headers: $headers.map((key, value) => MapEntry(key, value.toString()))..addAll(headers ?? {}),'
            .replaceAll('\n', ' ')
        : null;

    return '''@override
  ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<$responseClass> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers,}) async* {
    final responses = http.$apiMethod($apiEndpoint, $bodyImpl${headersConfig ?? 'headers: headers,'});
    $responseImpl
  }''';
      },
      onFuture: () {
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<$responseClass> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}}) async {
    final response = await http.$apiMethod($apiEndpoint, $bodyImpl${headersConfig ?? 'headers: headers,'}$apiCacheStrategy);
    $responseImpl
  }''';
      },
    )}''';
  }

  String _buildDataSourceFile(
      ApiGenerationConfig config, String convert, String methodOfDataSource) {
    return '''${config.returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}

${convert}import 'package:core/core.dart';

import '../models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../models/response/${config.apiName}_response.dart';''' : ''}

abstract class ${config.pageClassName}RemoteDataSource {
  ${typeResolver.resolveFlutterClassOfMethod(config.method)}<${typeResolver.whenMethod(
      config.method,
      onStream: () => typeResolver.resolveStreamResponseClass(config),
      onFuture: () => typeResolver.resolveResponseClass(config),
    )}> ${config.apiMethodName}(${typeResolver.resolveBodyClass(config.apiClassName, config.bodyList)} body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}});
}

class ${config.pageClassName}RemoteDataSourceImpl implements ${config.pageClassName}RemoteDataSource {
  ${config.pageClassName}RemoteDataSourceImpl({required this.http});

  final MorphemeHttp http;

  $methodOfDataSource
}''';
  }

  /// Generates data model body template.
  ///
  /// Creates a basic model with sample fields for the request body.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateDataModelBodyTemplate(ApiGenerationConfig config) {
    return '''import 'package:core/core.dart';

class ${config.apiClassName}Body extends Equatable {
  const ${config.apiClassName}Body({
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
}''';
  }

  /// Generates data model response template.
  ///
  /// Creates a basic model with sample fields for the API response.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateDataModelResponseTemplate(ApiGenerationConfig config) {
    return '''import 'dart:convert';

import 'package:core/core.dart';

class ${config.apiClassName}Response extends Equatable {
  const ${config.apiClassName}Response({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toMap() {
    return {
      'token': token,
    };
  }

  factory ${config.apiClassName}Response.fromMap(Map<String, dynamic> map) {
    return ${config.apiClassName}Response(
      token: map['token'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ${config.apiClassName}Response.fromJson(String source) =>
      ${config.apiClassName}Response.fromMap(json.decode(source));

  @override
  List<Object?> get props => [token];
}''';
  }

  /// Generates repository implementation template.
  ///
  /// Creates the repository implementation with proper error handling
  /// and data transformation.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateRepositoryImplTemplate(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);
    final entityImpl = typeResolver.generateEntityReturn(config);

    final methodOfDataRepository = '''@override
  ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers,}) async* {
    try {
      final response = remoteDataSource.${config.apiMethodName}(
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
        return '''${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}}) async {
    try {
      final data = await remoteDataSource.${config.apiMethodName}(body, headers: headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'cacheStrategy: cacheStrategy,' : ''});
      return Right($entityImpl);
    } on MorphemeException catch (e) {
      return Left(e.toMorphemeFailure());
    } catch (e) {
      return Left(InternalFailure(e.toString()));
    }
  }''';
      },
    )}''';

    return '''${config.returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
          
import 'package:core/core.dart';

${config.isReturnDataModel ? '''import '../../domain/entities/${config.apiName}_entity.dart';''' : ''}
${config.isReturnDataModel ? '''import '../../mapper.dart';''' : ''}
import '../../domain/repositories/${config.pageName}_repository.dart';
import '../datasources/${config.pageName}_remote_data_source.dart';
import '../models/body/${config.apiName}_body.dart';

class ${config.pageClassName}RepositoryImpl implements ${config.pageClassName}Repository {
  ${config.pageClassName}RepositoryImpl({
    required this.remoteDataSource,
  });

  final ${config.pageClassName}RemoteDataSource remoteDataSource;

  $methodOfDataRepository
}''';
  }

  /// Generates domain entity template.
  ///
  /// Creates a basic domain entity with sample fields.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateDomainEntityTemplate(ApiGenerationConfig config) {
    return '''import 'package:core/core.dart';

class ${config.apiClassName}Entity extends Equatable {
  const ${config.apiClassName}Entity({
    required this.token,
  });
  final String token;

  @override
  List<Object?> get props => [token];
}''';
  }

  /// Generates domain repository interface template.
  ///
  /// Creates the repository contract with the API method signature.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateDomainRepositoryTemplate(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);

    return '''${config.returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
          
import 'package:core/core.dart';

import '../../data/models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../entities/${config.apiName}_entity.dart';''' : ''}

abstract class ${config.pageClassName}Repository {
  ${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> ${config.apiMethodName}($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}});
}''';
  }

  /// Generates use case template.
  ///
  /// Creates the use case implementation that calls the repository.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateUseCaseTemplate(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);

    return '''${config.returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
        
import 'package:core/core.dart';

import '../../data/models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../entities/${config.apiName}_entity.dart';''' : ''}
import '../repositories/${config.pageName}_repository.dart';

class ${config.apiClassName}UseCase implements ${typeResolver.whenMethod(
      config.method,
      onStream: () => 'StreamUseCase',
      onFuture: () => 'UseCase',
    )}<$entityClass, $bodyClass> {
  ${config.apiClassName}UseCase({
    required this.repository,
  });

  final ${config.pageClassName}Repository repository;

  @override
  ${typeResolver.resolveFlutterClassOfMethod(config.method)}<Either<MorphemeFailure, $entityClass>> call($bodyClass body,{Map<String, String>? headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'CacheStrategy? cacheStrategy,' : ''}}) {
    return repository.${config.apiMethodName}(body, headers: headers, ${typeResolver.isApplyCacheStrategy(config.method) ? 'cacheStrategy: cacheStrategy,' : ''});
  }
}''';
  }

  /// Generates BLoC state template.
  ///
  /// Creates state classes for different API call states with proper
  /// stream/future handling based on method type.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateBlocStateTemplate(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);
    final entityClass = typeResolver.resolveEntityClass(config);

    return '''part of '${config.apiName}_bloc.dart';

@immutable
abstract class ${config.apiClassName}State extends Equatable {
  bool get isInitial => this is ${config.apiClassName}Initial;
  bool get isLoading => this is ${config.apiClassName}Loading;
  bool get isFailed => this is ${config.apiClassName}Failed;
  bool get isSuccess => this is ${config.apiClassName}Success;
  bool get isCanceled => this is ${config.apiClassName}Canceled;
  ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''bool get isStream => this is ${config.apiClassName}Stream;
  bool get isPaused => this is ${config.apiClassName}Paused;
  bool get isResumed => this is ${config.apiClassName}Resumed;''';
      },
      onFuture: () => '',
    )}

  bool get isNotInitial => this is! ${config.apiClassName}Initial;
  bool get isNotLoading => this is! ${config.apiClassName}Loading;
  bool get isNotFailed => this is! ${config.apiClassName}Failed;
  bool get isNotSuccess => this is! ${config.apiClassName}Success;
  bool get isNotCanceled => this is! ${config.apiClassName}Canceled;
  ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''bool get isNotStream => this is! ${config.apiClassName}Stream;
  bool get isNotPaused => this is! ${config.apiClassName}Paused;
  bool get isNotResumed => this is! ${config.apiClassName}Resumed;''';
      },
      onFuture: () => '',
    )}

  void when({
    void Function(${config.apiClassName}Initial state)? onInitial,
    void Function(${config.apiClassName}Loading state)? onLoading,
    void Function(${config.apiClassName}Failed state)? onFailed,
    void Function(${config.apiClassName}Success state)? onSuccess,
    void Function(${config.apiClassName}Canceled state)? onCanceled,
    ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''void Function(${config.apiClassName}Stream state)? onStream,
  void Function(${config.apiClassName}Paused state)? onPaused,
  void Function(${config.apiClassName}Resumed state)? onResumed,''';
      },
      onFuture: () => '',
    )}
  }) {
    final state = this;
    if (state is ${config.apiClassName}Initial) {
      onInitial?.call(state);
    } else if (state is ${config.apiClassName}Loading) {
      onLoading?.call(state);
    } else if (state is ${config.apiClassName}Failed) {
      onFailed?.call(state);
    } else if (state is ${config.apiClassName}Success) {
      onSuccess?.call(state);
    } else if (state is ${config.apiClassName}Canceled) {
      onCanceled?.call(state);
    } ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''else if (state is ${config.apiClassName}Stream) {
      onStream?.call(state);
    } else if (state is ${config.apiClassName}Paused) {
      onPaused?.call(state);
    } else if (state is ${config.apiClassName}Resumed) {
      onResumed?.call(state);
    }''';
      },
      onFuture: () => '',
    )}
  }

  Widget builder({
    Widget Function(${config.apiClassName}Initial state)? onInitial,
    Widget Function(${config.apiClassName}Loading state)? onLoading,
    Widget Function(${config.apiClassName}Failed state)? onFailed,
    Widget Function(${config.apiClassName}Success state)? onSuccess,
    Widget Function(${config.apiClassName}Canceled state)? onCanceled,
    ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''Widget Function(${config.apiClassName}Stream state)? onStream,
   Widget Function(${config.apiClassName}Paused state)? onPaused,
   Widget Function(${config.apiClassName}Resumed state)? onResumed,''';
      },
      onFuture: () => '',
    )}
    Widget Function(${config.apiClassName}State state)? onStateBuilder,
  }) {
    final state = this;
    final defaultWidget = onStateBuilder?.call(this) ?? const SizedBox.shrink();

    if (state is ${config.apiClassName}Initial) {
      return onInitial?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Loading) {
      return onLoading?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Failed) {
      return onFailed?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Success) {
      return onSuccess?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Canceled) {
      return onCanceled?.call(state) ?? defaultWidget;
    } ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''else if (state is ${config.apiClassName}Stream) {
      return onStream?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Paused) {
      return onPaused?.call(state) ?? defaultWidget;
    } else if (state is ${config.apiClassName}Resumed) {
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

class ${config.apiClassName}Initial extends ${config.apiClassName}State {
  @override
  List<Object?> get props => [];
}

class ${config.apiClassName}Loading extends ${config.apiClassName}State {
   ${config.apiClassName}Loading(this.body, this.headers, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, extra,];
}

class ${config.apiClassName}Failed extends ${config.apiClassName}State {
  ${config.apiClassName}Failed(this.body, this.headers, this.failure, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final MorphemeFailure failure;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, failure, extra,];
}

class ${config.apiClassName}Canceled extends ${config.apiClassName}State {
  ${config.apiClassName}Canceled(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''class ${config.apiClassName}Stream extends ${config.apiClassName}State {
  ${config.apiClassName}Stream(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final $entityClass data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}

class ${config.apiClassName}Paused extends ${config.apiClassName}State {
  ${config.apiClassName}Paused(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class ${config.apiClassName}Resumed extends ${config.apiClassName}State {
  ${config.apiClassName}Resumed(this.extra);

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class ${config.apiClassName}Success extends ${config.apiClassName}State {
  ${config.apiClassName}Success(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final List<$entityClass> data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}''';
      },
      onFuture: () =>
          '''class ${config.apiClassName}Success extends ${config.apiClassName}State {
  ${config.apiClassName}Success(this.body, this.headers, this.data, this.extra,);

  final $bodyClass body;
  final Map<String, String>? headers;
  final $entityClass data;
  final dynamic extra;

  @override
  List<Object?> get props => [body, headers, data, extra,];
}''',
    )}
''';
  }

  /// Generates BLoC event template.
  ///
  /// Creates event classes for triggering API operations with proper
  /// stream control events for SSE methods.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateBlocEventTemplate(ApiGenerationConfig config) {
    final bodyClass =
        typeResolver.resolveBodyClass(config.apiClassName, config.bodyList);

    return '''part of '${config.apiName}_bloc.dart';

@immutable
abstract class ${config.apiClassName}Event extends Equatable {}

class Fetch${config.apiClassName} extends ${config.apiClassName}Event {
  Fetch${config.apiClassName}(this.body, {this.headers, this.extra, ${typeResolver.isApplyCacheStrategy(config.method) ? 'this.cacheStrategy,' : ''}});

  final $bodyClass body;
  final Map<String, String>? headers;
  final dynamic extra;
  ${typeResolver.isApplyCacheStrategy(config.method) ? 'final CacheStrategy? cacheStrategy;' : ''}

  @override
  List<Object?> get props => [body, headers, extra, ${typeResolver.isApplyCacheStrategy(config.method) ? 'cacheStrategy,' : ''}];
}

class Cancel${config.apiClassName} extends ${config.apiClassName}Event {
  Cancel${config.apiClassName}({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''class Pause${config.apiClassName} extends ${config.apiClassName}Event {
  Pause${config.apiClassName}({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}

class Resume${config.apiClassName} extends ${config.apiClassName}Event {
  Resume${config.apiClassName}({this.extra});

  final dynamic extra;

  @override
  List<Object?> get props => [extra];
}''';
      },
      onFuture: () => '',
    )}''';
  }

  /// Generates BLoC template with state management logic.
  ///
  /// Creates the main BLoC class with proper event handling for
  /// both future and stream-based API methods.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateBlocTemplate(ApiGenerationConfig config) {
    final entityClass = typeResolver.resolveEntityClass(config);

    return '''${typeResolver.whenMethod(
      config.method,
      onStream: () => "import 'dart:async';",
      onFuture: () => '',
    )}
${config.returnData == 'body_bytes' ? "import 'dart:typed_data';" : ''}
    
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../data/models/body/${config.apiName}_body.dart';
${config.isReturnDataModel ? '''import '../../../domain/entities/${config.apiName}_entity.dart';''' : ''}
import '../../../domain/usecases/${config.apiName}_use_case.dart';

part '${config.apiName}_event.dart';
part '${config.apiName}_state.dart';

class ${config.apiClassName}Bloc extends MorphemeBloc<${config.apiClassName}Event, ${config.apiClassName}State> {
  ${config.apiClassName}Bloc({
    required this.useCase,
  }) : super(${config.apiClassName}Initial()) {
    on<Fetch${config.apiClassName}>((event, emit) async {
      emit(${config.apiClassName}Loading(event.body, event.headers, event.extra,),);
      ${typeResolver.whenMethod(
      config.method,
      onStream: () {
        return '''final results = useCase(event.body, headers: event.headers,);
      final completer = Completer();
      final List<$entityClass> buffer = [];
      _streamSubscription = results.listen(
        (result) {
          emit(
            result.fold(
              (failure) => ${config.apiClassName}Failed(
                event.body,
                event.headers,
                failure,
                event.extra,
              ),
              (success) {
                buffer.add(success);
                return ${config.apiClassName}Stream(
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
            ${config.apiClassName}Failed(
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
            ${config.apiClassName}Success(
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
    on<Cancel${config.apiClassName}>((event, emit) async {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      emit(${config.apiClassName}Canceled(event.extra));
    });
    on<Pause${config.apiClassName}>((event, emit) async {
      _streamSubscription?.pause();
      emit(${config.apiClassName}Paused(event.extra));
    });
    on<Resume${config.apiClassName}>((event, emit) async {
      _streamSubscription?.resume();
      emit(${config.apiClassName}Resumed(event.extra));
    });''';
      },
      onFuture: () {
        return '''_cancelableOperation = CancelableOperation.fromFuture(
        useCase(
          event.body,
          headers: event.headers,
          ${typeResolver.isApplyCacheStrategy(config.method) ? 'cacheStrategy: event.cacheStrategy,' : ''}
        ),
      );
      final result = await _cancelableOperation?.valueOrCancellation();

      if (result == null) {
        emit(${config.apiClassName}Canceled(event.extra));
        return;
      }
      emit(
        result.fold(
          (failure) => ${config.apiClassName}Failed(event.body, event.headers, failure, event.extra,),
          (success) => ${config.apiClassName}Success(event.body, event.headers, success, event.extra,),
        ),
      );
    });
    on<Cancel${config.apiClassName}>((event, emit) async {
      _cancelableOperation?.cancel();
      _cancelableOperation = null;
      emit(${config.apiClassName}Canceled(event.extra));
    });''';
      },
    )}
    
  }

  final ${config.apiClassName}UseCase useCase;

  ${typeResolver.whenMethod(
      config.method,
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
}''';
  }

  /// Generates mapper template for data model to entity conversion.
  ///
  /// Creates extension methods for converting between data and domain layers.
  ///
  /// Parameters:
  /// - [config]: API generation configuration
  String generateMapperTemplate(ApiGenerationConfig config) {
    return '''import 'data/models/response/${config.apiName}_response.dart';
import 'domain/entities/${config.apiName}_entity.dart';

extension ${config.apiClassName}ResponseMapper on ${config.apiClassName}Response {
  ${config.apiClassName}Entity toEntity() => ${config.apiClassName}Entity(token: token);
}

extension ${config.apiClassName}EntityMapper on ${config.apiClassName}Entity {
  ${config.apiClassName}Response toResponse() => ${config.apiClassName}Response(token: token);
}''';
  }
}
