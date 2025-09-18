/// Text case conversion library.
///
/// This library provides utilities for converting text between different
/// naming conventions such as camelCase, snake_case, PascalCase, etc.
///
/// Based on the recase package implementation.
library;

/// An instance of text to be re-cased.
///
/// This class takes a string and provides getters for various naming
/// conventions, making it easy to convert between different text cases.
class ReCase {
  final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');

  final symbolSet = {' ', '.', '/', '_', '\\', '-'};

  /// The original text provided to the ReCase instance
  late String originalText;
  
  /// The words extracted from the original text
  late List<String> _words;

  /// Creates a new ReCase instance with the provided text.
  ///
  /// Parameters:
  /// - [text]: The text to be converted to different cases
  ReCase(String text) {
    originalText = text;
    _words = _groupIntoWords(text);
  }

  /// Groups the input text into individual words.
  ///
  /// This method analyzes the input text and splits it into words
  /// based on various delimiters and camelCase boundaries.
  ///
  /// Parameters:
  /// - [text]: The text to be split into words
  ///
  /// Returns: A list of individual words extracted from the text
  List<String> _groupIntoWords(String text) {
    StringBuffer sb = StringBuffer();
    List<String> words = [];
    bool isAllCaps = text.toUpperCase() == text;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String? nextChar = i + 1 == text.length ? null : text[i + 1];

      if (symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      bool isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  /// Gets the text in camelCase format.
  ///
  /// Example: "hello world" becomes "helloWorld"
  String get camelCase => _getCamelCase();

  /// Gets the text in CONSTANT_CASE format.
  ///
  /// Example: "hello world" becomes "HELLO_WORLD"
  String get constantCase => _getConstantCase();

  /// Gets the text in Sentence case format.
  ///
  /// Example: "hello world" becomes "Hello world"
  String get sentenceCase => _getSentenceCase();

  /// Gets the text in snake_case format.
  ///
  /// Example: "hello world" becomes "hello_world"
  String get snakeCase => _getSnakeCase();

  /// Gets the text in dot.case format.
  ///
  /// Example: "hello world" becomes "hello.world"
  String get dotCase => _getSnakeCase(separator: '.');

  /// Gets the text in param-case format.
  ///
  /// Example: "hello world" becomes "hello-world"
  String get paramCase => _getSnakeCase(separator: '-');

  /// Gets the text in path/case format.
  ///
  /// Example: "hello world" becomes "hello/world"
  String get pathCase => _getSnakeCase(separator: '/');

  /// Gets the text in PascalCase format.
  ///
  /// Example: "hello world" becomes "HelloWorld"
  String get pascalCase => _getPascalCase();

  /// Gets the text in Header-Case format.
  ///
  /// Example: "hello world" becomes "Hello-World"
  String get headerCase => _getPascalCase(separator: '-');

  /// Gets the text in Title Case format.
  ///
  /// Example: "hello world" becomes "Hello World"
  String get titleCase => _getPascalCase(separator: ' ');

  /// Converts words to camelCase format.
  ///
  /// Parameters:
  /// - [separator]: The separator to use between words (default: '')
  String _getCamelCase({String separator = ''}) {
    List<String> words = _words.map(_upperCaseFirstLetter).toList();
    if (_words.isNotEmpty) {
      words[0] = words[0].toLowerCase();
    }

    return words.join(separator);
  }

  /// Converts words to CONSTANT_CASE format.
  ///
  /// Parameters:
  /// - [separator]: The separator to use between words (default: '_')
  String _getConstantCase({String separator = '_'}) {
    List<String> words = _words.map((word) => word.toUpperCase()).toList();

    return words.join(separator);
  }

  /// Converts words to PascalCase format.
  ///
  /// Parameters:
  /// - [separator]: The separator to use between words (default: '')
  String _getPascalCase({String separator = ''}) {
    List<String> words = _words.map(_upperCaseFirstLetter).toList();

    return words.join(separator);
  }

  /// Converts words to Sentence case format.
  ///
  /// Parameters:
  /// - [separator]: The separator to use between words (default: ' ')
  String _getSentenceCase({String separator = ' '}) {
    List<String> words = _words.map((word) => word.toLowerCase()).toList();
    if (_words.isNotEmpty) {
      words[0] = _upperCaseFirstLetter(words[0]);
    }

    return words.join(separator);
  }

  /// Converts words to snake_case format.
  ///
  /// Parameters:
  /// - [separator]: The separator to use between words (default: '_')
  String _getSnakeCase({String separator = '_'}) {
    List<String> words = _words.map((word) => word.toLowerCase()).toList();

    return words.join(separator);
  }

  /// Converts the first letter of a word to uppercase.
  ///
  /// Parameters:
  /// - [word]: The word to convert
  ///
  /// Returns: The word with its first letter capitalized
  String _upperCaseFirstLetter(String word) {
    return '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}

/// Extension methods for String to provide easy access to ReCase functionality.
///
/// This extension adds getters to the String class for convenient
/// case conversion without having to create a ReCase instance directly.
extension StringReCase on String {
  /// Gets the text in camelCase format.
  ///
  /// Example: "hello world".camelCase returns "helloWorld"
  String get camelCase => ReCase(this).camelCase;

  /// Gets the text in CONSTANT_CASE format.
  ///
  /// Example: "hello world".constantCase returns "HELLO_WORLD"
  String get constantCase => ReCase(this).constantCase;

  /// Gets the text in Sentence case format.
  ///
  /// Example: "hello world".sentenceCase returns "Hello world"
  String get sentenceCase => ReCase(this).sentenceCase;

  /// Gets the text in snake_case format.
  ///
  /// Example: "hello world".snakeCase returns "hello_world"
  String get snakeCase => ReCase(this).snakeCase;

  /// Gets the text in dot.case format.
  ///
  /// Example: "hello world".dotCase returns "hello.world"
  String get dotCase => ReCase(this).dotCase;

  /// Gets the text in param-case format.
  ///
  /// Example: "hello world".paramCase returns "hello-world"
  String get paramCase => ReCase(this).paramCase;

  /// Gets the text in path/case format.
  ///
  /// Example: "hello world".pathCase returns "hello/world"
  String get pathCase => ReCase(this).pathCase;

  /// Gets the text in PascalCase format.
  ///
  /// Example: "hello world".pascalCase returns "HelloWorld"
  String get pascalCase => ReCase(this).pascalCase;

  /// Gets the text in Header-Case format.
  ///
  /// Example: "hello world".headerCase returns "Hello-World"
  String get headerCase => ReCase(this).headerCase;

  /// Gets the text in Title Case format.
  ///
  /// Example: "hello world".titleCase returns "Hello World"
  String get titleCase => ReCase(this).titleCase;
}