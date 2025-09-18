import 'dart:convert';
import 'dart:io';

import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Validates JSON files and data structures
///
/// This validator ensures JSON files are properly formatted,
/// accessible, and contain valid data for code generation.
class JsonValidator {
  final bool _verbose;

  JsonValidator({bool verbose = false}) : _verbose = verbose;

  /// Validates a JSON file and returns parsed data
  ///
  /// [filePath] - Path to the JSON file
  /// [allowList] - Whether to allow JSON arrays
  /// Returns the parsed JSON data or null if invalid
  ValidationResult<dynamic> validateJsonFile(
    String? filePath, {
    bool allowList = true,
  }) {
    try {
      // Check if file path is provided
      if (filePath == null || filePath.isEmpty) {
        return ValidationResult.success(null);
      }

      // Check if file exists
      if (!File(filePath).existsSync()) {
        return ValidationResult.error('JSON file not found: $filePath');
      }

      // Read file content
      String jsonContent;
      try {
        jsonContent = read(filePath).join('\n');
      } catch (e) {
        return ValidationResult.error(
            'Failed to read JSON file: $filePath - $e');
      }

      // Parse JSON
      dynamic parsedData;
      try {
        parsedData = jsonDecode(jsonContent);
      } catch (e) {
        return ValidationResult.error(
            'Invalid JSON format in file: $filePath - $e');
      }

      // Validate structure
      final structureResult = _validateJsonStructure(parsedData, allowList);
      if (!structureResult.isValid) {
        return ValidationResult.error(
          'Invalid JSON structure in file: $filePath - ${structureResult.error}',
        );
      }

      // If it's a list, take the first element
      if (parsedData is List && parsedData.isNotEmpty) {
        if (_verbose) {
          StatusHelper.success(
              'JSON file contains array, using first element: $filePath');
        }
        parsedData = parsedData.first;
      }

      if (_verbose) {
        StatusHelper.success('Successfully validated JSON file: $filePath');
      }

      return ValidationResult.success(parsedData);
    } catch (e, stackTrace) {
      final error = 'Unexpected error validating JSON file: $filePath - $e';
      if (_verbose) {
        StatusHelper.failed('$error\nStack trace: $stackTrace');
      }
      return ValidationResult.error(error);
    }
  }

  /// Validates a JSON string and returns parsed data
  ///
  /// [jsonString] - JSON string to validate
  /// [allowList] - Whether to allow JSON arrays
  /// Returns the parsed JSON data or null if invalid
  ValidationResult<dynamic> validateJsonString(
    String jsonString, {
    bool allowList = true,
  }) {
    try {
      if (jsonString.isEmpty) {
        return ValidationResult.success({});
      }

      // Parse JSON
      dynamic parsedData;
      try {
        parsedData = jsonDecode(jsonString);
      } catch (e) {
        return ValidationResult.error('Invalid JSON format: $e');
      }

      // Validate structure
      final structureResult = _validateJsonStructure(parsedData, allowList);
      if (!structureResult.isValid) {
        return ValidationResult.error(structureResult.error!);
      }

      // If it's a list, take the first element
      if (parsedData is List && parsedData.isNotEmpty) {
        parsedData = parsedData.first;
      }

      return ValidationResult.success(parsedData);
    } catch (e) {
      return ValidationResult.error(
          'Unexpected error validating JSON string: $e');
    }
  }

  /// Validates JSON structure for code generation compatibility
  ValidationResult<void> _validateJsonStructure(dynamic data, bool allowList) {
    if (data == null) {
      return ValidationResult.success(null);
    }

    if (data is Map) {
      return _validateMapStructure(data);
    }

    if (data is List) {
      if (!allowList) {
        return ValidationResult.error(
            'JSON arrays are not allowed in this context');
      }
      return _validateListStructure(data);
    }

    // Primitive types are generally not useful for code generation
    if (data is String || data is num || data is bool) {
      return ValidationResult.error(
        'JSON root must be an object or array, not a primitive value',
      );
    }

    return ValidationResult.error('Unsupported JSON structure');
  }

  /// Validates map structure recursively
  ValidationResult<void> _validateMapStructure(Map<dynamic, dynamic> map) {
    if (map.isEmpty) {
      return ValidationResult.success(null);
    }

    // Check for valid keys
    for (final key in map.keys) {
      if (key is! String) {
        return ValidationResult.error('All JSON object keys must be strings');
      }

      if (key.isEmpty) {
        return ValidationResult.error('JSON object keys cannot be empty');
      }

      // Validate nested structures
      final value = map[key];
      if (value is Map) {
        final nestedResult = _validateMapStructure(value);
        if (!nestedResult.isValid) {
          return nestedResult;
        }
      } else if (value is List) {
        final nestedResult = _validateListStructure(value);
        if (!nestedResult.isValid) {
          return nestedResult;
        }
      }
    }

    return ValidationResult.success(null);
  }

  /// Validates list structure recursively
  ValidationResult<void> _validateListStructure(List<dynamic> list) {
    if (list.isEmpty) {
      return ValidationResult.success(null);
    }

    // For code generation, we typically want consistent types in arrays
    final firstElementType = _getElementType(list.first);

    for (int i = 1; i < list.length; i++) {
      final currentType = _getElementType(list[i]);
      if (currentType != firstElementType) {
        if (_verbose) {
          StatusHelper.warning(
            'Inconsistent types in array: expected $firstElementType, got $currentType at index $i',
          );
        }
        // Don't fail for type inconsistency, just warn
      }
    }

    // Validate nested structures using first element
    final firstElement = list.first;
    if (firstElement is Map) {
      return _validateMapStructure(firstElement);
    } else if (firstElement is List) {
      return _validateListStructure(firstElement);
    }

    return ValidationResult.success(null);
  }

  /// Gets the type of an element for consistency checking
  String _getElementType(dynamic element) {
    if (element == null) return 'null';
    if (element is String) return 'string';
    if (element is int) return 'int';
    if (element is double) return 'double';
    if (element is bool) return 'bool';
    if (element is Map) return 'map';
    if (element is List) return 'list';
    return 'unknown';
  }

  /// Validates that a JSON structure is suitable for model generation
  ValidationResult<void> validateForModelGeneration(dynamic data) {
    if (data == null) {
      return ValidationResult.error('Cannot generate model from null data');
    }

    if (data is! Map) {
      return ValidationResult.error(
          'Model generation requires JSON object structure');
    }

    final map = data;
    if (map.isEmpty) {
      return ValidationResult.error('Cannot generate model from empty object');
    }

    // Check for potential naming conflicts
    final keys = map.keys.cast<String>().toList();
    final duplicateKeys = _findDuplicateKeys(keys);
    if (duplicateKeys.isNotEmpty) {
      return ValidationResult.error(
        'Duplicate keys found (case-insensitive): ${duplicateKeys.join(', ')}',
      );
    }

    return ValidationResult.success(null);
  }

  /// Finds duplicate keys (case-insensitive)
  List<String> _findDuplicateKeys(List<String> keys) {
    final seen = <String, String>{};
    final duplicates = <String>[];

    for (final key in keys) {
      final lowerKey = key.toLowerCase();
      if (seen.containsKey(lowerKey)) {
        if (!duplicates.contains(seen[lowerKey])) {
          duplicates.add(seen[lowerKey]!);
        }
        if (!duplicates.contains(key)) {
          duplicates.add(key);
        }
      } else {
        seen[lowerKey] = key;
      }
    }

    return duplicates;
  }
}

/// Represents the result of a validation operation
class ValidationResult<T> {
  final T? data;
  final String? error;
  final bool isValid;

  const ValidationResult._(this.data, this.error, this.isValid);

  factory ValidationResult.success(T? data) {
    return ValidationResult._(data, null, true);
  }

  factory ValidationResult.error(String error) {
    return ValidationResult._(null, error, false);
  }
}
