import 'dart:convert';

/// Splits a `String` into a list of command-line argument parts.
/// e.g. "command -p param" -> ["command", "-p", "param"]
///
class CommandlineConverter extends Converter<String, List<String>> {
  @override
  List<String> convert(String? input) {
    if (input == null || input.isEmpty) {
      return [];
    }

    final List<String> result = [];

    var current = "";

    String? inQuote;
    bool lastTokenHasBeenQuoted = false;

    for (int index = 0; index < input.length; index++) {
      final token = input[index];

      if (inQuote != null) {
        if (token == inQuote) {
          lastTokenHasBeenQuoted = true;
          inQuote = null;
        } else {
          current += token;
        }
      } else {
        switch (token) {
          case "'": // '
          case '"': // ""
            inQuote = token;
            continue;
          case " ": // space
            if (lastTokenHasBeenQuoted || current.isNotEmpty) {
              result.add(current);
              current = "";
            }
            break;
          default:
            current += token;
            lastTokenHasBeenQuoted = false;
        }
      }
    }

    if (lastTokenHasBeenQuoted || current.isNotEmpty) {
      result.add(current);
    }

    if (inQuote != null) {
      throw Exception("Unbalanced quote $inQuote in input:\n$input");
    }

    return result;
  }
}
