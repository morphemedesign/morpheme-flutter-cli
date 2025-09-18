import '../models/api_generation_config.dart';

/// Resolves type information for API generation.
///
/// Determines appropriate Dart types based on return data configuration,
/// method types (stream vs future), and list/single response patterns.
class ApiTypeResolver {
  /// Resolves the Flutter class type based on the HTTP method.
  ///
  /// Returns 'Stream' for SSE methods, 'Future' for all others.
  ///
  /// Parameters:
  /// - [method]: The HTTP method (get, post, getSse, etc.)
  String resolveFlutterClassOfMethod(String method) {
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

  /// Executes different code paths based on method type.
  ///
  /// Provides a way to conditionally execute logic based on whether
  /// the method is a stream-based SSE method or a future-based method.
  ///
  /// Parameters:
  /// - [method]: The HTTP method
  /// - [onStream]: Function to execute for stream methods
  /// - [onFuture]: Function to execute for future methods
  String whenMethod(
    String method, {
    required String Function() onStream,
    required String Function() onFuture,
  }) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return onStream();
      default:
        return onFuture();
    }
  }

  /// Resolves the request body class type.
  ///
  /// Returns either a list type or single type based on configuration.
  ///
  /// Parameters:
  /// - [apiClassName]: The base API class name
  /// - [bodyList]: Whether the body should be a list
  String resolveBodyClass(String apiClassName, bool bodyList) {
    if (bodyList) {
      return 'List<${apiClassName}Body>';
    } else {
      return '${apiClassName}Body';
    }
  }

  /// Resolves the response class type for future-based methods.
  ///
  /// Returns appropriate type based on return data configuration and
  /// whether response is a list.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String resolveResponseClass(ApiGenerationConfig config) {
    switch (config.returnData) {
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
        if (config.responseList) {
          return 'List<${config.apiClassName}Response>';
        } else {
          return '${config.apiClassName}Response';
        }
    }
  }

  /// Resolves the response class type for stream-based methods.
  ///
  /// Similar to [resolveResponseClass] but for SSE streams.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String resolveStreamResponseClass(ApiGenerationConfig config) {
    switch (config.returnData) {
      case 'header':
        return 'Map<String, String>';
      case 'body_bytes':
        return 'Uint8List';
      case 'body_string':
        return 'String';
      case 'status_code':
        return 'int';
      case 'raw':
        return 'String'; // Note: different from regular response
      default:
        if (config.responseList) {
          return 'List<${config.apiClassName}Response>';
        } else {
          return '${config.apiClassName}Response';
        }
    }
  }

  /// Resolves the domain entity class type.
  ///
  /// Returns appropriate entity type based on return data configuration.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String resolveEntityClass(ApiGenerationConfig config) {
    switch (config.returnData) {
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
        if (config.responseList) {
          return 'List<${config.apiClassName}Entity>';
        } else {
          return '${config.apiClassName}Entity';
        }
    }
  }

  /// Generates the response return statement for future-based methods.
  ///
  /// Creates appropriate return logic based on return data type and
  /// whether the response is a list.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String generateResponseReturn(ApiGenerationConfig config) {
    switch (config.returnData) {
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
        if (config.responseList) {
          return '''final mapResponse = jsonDecode(response.body);
    return mapResponse is List
        ? List.from(mapResponse.map((e) => ${config.apiClassName}Response.fromMap(e)))
        : [${config.apiClassName}Response.fromMap(mapResponse)];''';
        } else {
          return 'return ${config.apiClassName}Response.fromJson(response.body);';
        }
    }
  }

  /// Generates the response return statement for stream-based methods.
  ///
  /// Creates appropriate yield logic for SSE streams.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String generateStreamResponseReturn(ApiGenerationConfig config) {
    final data = switch (config.returnData) {
      'body_string' => 'yield response;',
      'raw' => 'yield response;',
      _ => config.responseList
          ? '''final mapResponse = jsonDecode(response);
    yield mapResponse is List
        ? List.from(mapResponse.map((e) => ${config.apiClassName}Response.fromMap(e)))
        : [${config.apiClassName}Response.fromMap(mapResponse)];'''
          : 'yield ${config.apiClassName}Response.fromJson(response);'
    };

    return '''    await for (final response in responses) {
      $data
    }''';
  }

  /// Generates the entity return statement for repository implementation.
  ///
  /// Creates appropriate mapping from data models to domain entities.
  ///
  /// Parameters:
  /// - [config]: The API generation configuration
  String generateEntityReturn(ApiGenerationConfig config) {
    switch (config.returnData) {
      case 'model':
        if (config.responseList) {
          return 'data.map((e) => e.toEntity()).toList()';
        } else {
          return 'data.toEntity()';
        }
      default:
        return 'data';
    }
  }

  /// Checks if the method is a multipart method.
  ///
  /// Parameters:
  /// - [method]: The HTTP method to check
  bool isMultipart(String method) {
    return method.toLowerCase().contains('multipart');
  }

  /// Checks if the method is a Server-Sent Events method.
  ///
  /// Parameters:
  /// - [method]: The HTTP method to check
  bool isSse(String method) {
    switch (method) {
      case 'getSse':
      case 'postSse':
      case 'putSse':
      case 'patchSse':
      case 'deleteSse':
        return true;
      default:
        return false;
    }
  }

  /// Checks if cache strategy can be applied to the method.
  ///
  /// Cache strategies are not supported for multipart and SSE methods.
  ///
  /// Parameters:
  /// - [method]: The HTTP method to check
  bool isApplyCacheStrategy(String method) {
    return !isMultipart(method) && !isSse(method);
  }
}
