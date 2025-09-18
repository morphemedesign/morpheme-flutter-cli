/// Template for the main export file.
///
/// This class provides static methods for generating the
/// main library export file.
class ExportTemplate {
  /// Generates the main export file.
  ///
  /// Parameters:
  /// - [exportStatements]: The export statements to include.
  ///
  /// Returns: The generated export file code.
  static String generate(List<String> exportStatements) {
    return '''
library local2dart;

${exportStatements.join('\n')}
''';
  }
}