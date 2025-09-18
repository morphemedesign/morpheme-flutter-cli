import 'package:morpheme_cli/helper/recase.dart';

import '../models/models.dart';

/// Manages code templates and generation logic for asset classes and exports.
///
/// Provides template generation for:
/// - Asset constant classes
/// - Library export files
/// - Individual asset constants
///
/// Uses consistent naming conventions and formatting standards.
class TemplateGenerator {
  /// Creates a new TemplateGenerator instance.
  const TemplateGenerator();

  /// Generates a complete Dart class template for asset constants.
  ///
  /// Creates a class with static const fields for each asset in the directory,
  /// following Dart naming conventions and including proper documentation.
  ///
  /// Parameters:
  /// - [projectName]: The project name for class naming
  /// - [directoryName]: The asset directory name for class naming
  /// - [assets]: List of assets to include in the class
  /// - [assetsBasePath]: Base path for asset references
  ///
  /// Returns the complete Dart class as a string.
  String generateAssetClassTemplate({
    required String projectName,
    required String directoryName,
    required List<Asset> assets,
    required String assetsBasePath,
  }) {
    final className = '${projectName.pascalCase}${directoryName.pascalCase}';
    final packagePath = _buildPackagePath(assetsBasePath);

    final template = ClassTemplate(
      className: className,
      packagePath: packagePath,
      assets: assets,
      directoryName: directoryName,
    );

    return template.render();
  }

  /// Generates a library export file template.
  ///
  /// Creates a barrel file that exports all generated asset classes,
  /// providing a single import point for consuming code.
  ///
  /// Parameters:
  /// - [exportFiles]: List of file names to export (without .dart extension)
  ///
  /// Returns the complete export file content as a string.
  String generateExportTemplate(List<String> exportFiles) {
    final template = ExportTemplate(exports: exportFiles);
    return template.render();
  }

  /// Generates a single asset constant definition.
  ///
  /// Creates a properly formatted static const field for an individual asset.
  ///
  /// Parameters:
  /// - [asset]: The asset to generate a constant for
  /// - [packagePath]: The package path prefix for the asset
  ///
  /// Returns the constant definition as a string.
  String generateAssetConstant(Asset asset, String packagePath) {
    final constantName = asset.toConstantName();
    final assetPath = '$packagePath/${asset.fileName}';

    return "  static const String $constantName = '$assetPath';";
  }

  /// Builds the package path for asset references.
  ///
  /// Converts file system paths to package-relative paths suitable
  /// for use in Flutter asset references.
  String _buildPackagePath(String assetsBasePath) {
    // Remove leading path separators and normalize
    final normalizedPath =
        assetsBasePath.replaceAll(RegExp(r'^[/\\]+'), '').replaceAll('\\', '/');

    return 'packages/$normalizedPath';
  }
}

/// Template for generating asset constant classes.
///
/// Encapsulates the structure and formatting of generated asset classes,
/// providing consistent output across all generated files.
class ClassTemplate {
  /// The name of the generated class.
  final String className;

  /// The package path prefix for asset references.
  final String packagePath;

  /// List of assets to include in the class.
  final List<Asset> assets;

  /// The source directory name for documentation.
  final String directoryName;

  /// Creates a new ClassTemplate instance.
  const ClassTemplate({
    required this.className,
    required this.packagePath,
    required this.assets,
    required this.directoryName,
  });

  /// Renders the complete class template.
  ///
  /// Generates a properly formatted Dart class with documentation,
  /// package path constant, and individual asset constants.
  String render() {
    final buffer = StringBuffer();

    // Class declaration
    buffer.writeln('abstract class $className {');

    // Package path constant (commented for reference)
    buffer.writeln('  // ignore: unused_field');
    buffer.writeln("  static const String _assets = '$packagePath';");
    buffer.writeln("");

    // Asset constants
    for (final asset in assets) {
      buffer.writeln(_generateAssetConstant(asset));
    }

    // Close class
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a constant definition for an asset.
  String _generateAssetConstant(Asset asset) {
    final constantName = asset.toConstantName();
    final fullPath = '\$_assets/${asset.fileName}';

    return "  static const String $constantName = '$fullPath';";
  }
}

/// Template for generating library export files.
///
/// Creates barrel files that export all generated asset classes,
/// providing a convenient single import point for consuming code.
class ExportTemplate {
  /// List of file names to export (without .dart extension).
  final List<String> exports;

  /// Creates a new ExportTemplate instance.
  const ExportTemplate({
    required this.exports,
  });

  /// Renders the complete export file template.
  ///
  /// Generates a properly formatted export file with documentation
  /// and export statements for all specified files.
  String render() {
    final buffer = StringBuffer();

    // Export statements
    for (final exportFile in exports) {
      buffer.writeln("export 'src/$exportFile.dart';");
    }

    return buffer.toString();
  }
}

/// Utility class for asset naming conventions and transformations.
///
/// Provides consistent naming strategies across all generated code,
/// ensuring proper Dart identifier formatting and convention adherence.
class NamingConventions {
  /// Converts an asset name to a valid Dart constant name.
  ///
  /// Applies camelCase convention and ensures the result is a valid
  /// Dart identifier by removing or replacing invalid characters.
  ///
  /// Parameters:
  /// - [assetName]: The original asset name (usually filename without extension)
  ///
  /// Returns a valid Dart constant name.
  static String toConstantName(String assetName) {
    // Remove file extension if present
    final nameWithoutExtension = assetName.contains('.')
        ? assetName.substring(0, assetName.lastIndexOf('.'))
        : assetName;

    // Apply camelCase transformation
    final camelCased = nameWithoutExtension.camelCase;

    // Ensure it starts with a letter or underscore
    if (RegExp(r'^[0-9]').hasMatch(camelCased)) {
      return '_$camelCased';
    }

    return camelCased;
  }

  /// Converts a directory name to a valid Dart class name.
  ///
  /// Applies PascalCase convention and ensures the result is a valid
  /// Dart class identifier.
  ///
  /// Parameters:
  /// - [directoryName]: The directory name
  ///
  /// Returns a valid Dart class name.
  static String toClassName(String directoryName) {
    final pascalCased = directoryName.pascalCase;

    // Ensure it starts with a letter
    if (RegExp(r'^[0-9]').hasMatch(pascalCased)) {
      return 'Asset$pascalCased';
    }

    return pascalCased;
  }

  /// Converts a project name to a valid Dart class prefix.
  ///
  /// Ensures the project name can be safely used as part of class names.
  ///
  /// Parameters:
  /// - [projectName]: The project name
  ///
  /// Returns a valid class name prefix.
  static String toClassPrefix(String projectName) {
    return toClassName(projectName);
  }

  /// Validates if a string is a valid Dart identifier.
  ///
  /// Checks if the string follows Dart identifier rules:
  /// - Starts with letter or underscore
  /// - Contains only letters, digits, and underscores
  /// - Is not a reserved word
  ///
  /// Parameters:
  /// - [identifier]: The string to validate
  ///
  /// Returns true if the identifier is valid.
  static bool isValidDartIdentifier(String identifier) {
    if (identifier.isEmpty) return false;

    // Check format
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(identifier)) {
      return false;
    }

    // Check for reserved words (basic check)
    const reservedWords = {
      'abstract',
      'as',
      'assert',
      'async',
      'await',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'default',
      'do',
      'else',
      'enum',
      'export',
      'extends',
      'false',
      'final',
      'finally',
      'for',
      'if',
      'import',
      'in',
      'is',
      'library',
      'new',
      'null',
      'operator',
      'part',
      'return',
      'static',
      'super',
      'switch',
      'this',
      'throw',
      'true',
      'try',
      'var',
      'void',
      'while',
      'with',
    };

    return !reservedWords.contains(identifier.toLowerCase());
  }
}
