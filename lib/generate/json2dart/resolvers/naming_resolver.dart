import 'package:morpheme_cli/helper/helper.dart';

/// Resolves naming conflicts and manages class naming conventions
///
/// This resolver ensures consistent and conflict-free naming
/// across the generated code structure.
class NamingResolver {
  final Map<String, int> _nameCounters = {};
  final Set<String> _reservedNames = {
    'Object',
    'String',
    'int',
    'double',
    'bool',
    'List',
    'Map',
    'Set',
    'dynamic',
    'var',
    'void',
    'null',
    'true',
    'false',
    'class',
    'enum',
    'mixin',
    'typedef',
    'import',
    'export',
    'library',
    'part',
    'abstract',
    'static',
    'final',
    'const',
    'factory',
    'operator',
    'get',
    'set',
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'break',
    'continue',
    'return',
    'throw',
    'try',
    'catch',
    'finally',
    'new',
    'this',
    'super',
    'is',
    'as',
    'in',
    'async',
    'await',
    'sync',
    'yield',
  };

  /// Resolves a class name ensuring uniqueness and convention compliance
  ///
  /// [baseName] - Base name for the class
  /// [suffix] - Suffix to append to the class name
  /// [isRoot] - Whether this is a root class
  /// Returns a unique, valid class name
  String resolveClassName(
    String baseName,
    String suffix, [
    bool isRoot = false,
  ]) {
    // Clean and format base name
    String cleanName = _cleanBaseName(baseName);

    // Apply suffix
    String fullName = '$cleanName$suffix';

    // Ensure it starts with uppercase
    fullName = fullName.pascalCase;

    // Check for reserved names
    if (_reservedNames.contains(fullName.toLowerCase())) {
      fullName = '${fullName}Model';
    }

    // Ensure uniqueness
    fullName = _ensureUniqueness(fullName);

    return fullName;
  }

  /// Resolves a variable name ensuring convention compliance
  ///
  /// [baseName] - Base name for the variable
  /// Returns a valid variable name
  String resolveVariableName(String baseName) {
    // Clean and format variable name
    String cleanName = _cleanBaseName(baseName);

    // Apply camelCase
    cleanName = cleanName.camelCase;

    // Check for reserved names
    if (_reservedNames.contains(cleanName.toLowerCase())) {
      cleanName = '${cleanName}Value';
    }

    // Ensure it doesn't start with a number
    if (RegExp(r'^\d').hasMatch(cleanName)) {
      cleanName = 'value$cleanName';
    }

    return cleanName;
  }

  /// Resolves a method name ensuring convention compliance
  ///
  /// [baseName] - Base name for the method
  /// [prefix] - Optional prefix (e.g., 'get', 'set', 'to')
  /// Returns a valid method name
  String resolveMethodName(String baseName, [String? prefix]) {
    // Clean and format base name
    String cleanName = _cleanBaseName(baseName);

    // Apply prefix if provided
    if (prefix != null) {
      cleanName = '$prefix${cleanName.pascalCase}';
    }

    // Apply camelCase
    cleanName = cleanName.camelCase;

    // Check for reserved names
    if (_reservedNames.contains(cleanName.toLowerCase())) {
      cleanName = '${cleanName}Method';
    }

    return cleanName;
  }

  /// Resolves a file name ensuring convention compliance
  ///
  /// [baseName] - Base name for the file
  /// [suffix] - File suffix (e.g., 'model', 'service')
  /// Returns a valid file name
  String resolveFileName(String baseName, String suffix) {
    // Clean and format base name
    String cleanName = _cleanBaseName(baseName);

    // Apply snake_case
    cleanName = cleanName.snakeCase;

    // Add suffix
    String fileName = '${cleanName}_$suffix.dart';

    return fileName;
  }

  /// Cleans a base name removing invalid characters
  String _cleanBaseName(String baseName) {
    // Remove invalid characters and normalize
    String cleaned = baseName
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    // Ensure it's not empty
    if (cleaned.isEmpty) {
      cleaned = 'Generated';
    }

    // Ensure it doesn't start with a number
    if (RegExp(r'^\d').hasMatch(cleaned)) {
      cleaned = 'Item$cleaned';
    }

    return cleaned;
  }

  /// Ensures name uniqueness by appending a counter if needed
  String _ensureUniqueness(String name) {
    final baseName = name;
    int counter = _nameCounters[baseName] ?? 0;

    String uniqueName = name;
    if (counter > 0) {
      uniqueName = '$baseName$counter';
    }

    // Update counter for next use
    _nameCounters[baseName] = counter + 1;

    return uniqueName;
  }

  /// Registers a name as used to prevent conflicts
  void registerUsedName(String name) {
    final baseName = name.replaceAll(RegExp(r'\d+$'), '');
    final currentCounter = _nameCounters[baseName] ?? 0;
    _nameCounters[baseName] = currentCounter + 1;
  }

  /// Clears all registered names and counters
  void clearRegistry() {
    _nameCounters.clear();
  }

  /// Gets suggestion for fixing invalid names
  String suggestValidName(String invalidName) {
    if (invalidName.isEmpty) {
      return 'GeneratedName';
    }

    // Try to fix common issues
    String suggestion = invalidName
        .replaceAll(RegExp(r'[^\w]'), '')
        .replaceAll(RegExp(r'^\d+'), '');

    if (suggestion.isEmpty) {
      return 'GeneratedName';
    }

    // Ensure proper casing
    suggestion = suggestion.pascalCase;

    // Check if it's a reserved word
    if (_reservedNames.contains(suggestion.toLowerCase())) {
      suggestion = '${suggestion}Model';
    }

    return suggestion;
  }

  /// Validates if a name follows Dart conventions
  bool isValidDartName(String name) {
    // Check basic format
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      return false;
    }

    // Check for reserved words
    if (_reservedNames.contains(name.toLowerCase())) {
      return false;
    }

    return true;
  }
}
