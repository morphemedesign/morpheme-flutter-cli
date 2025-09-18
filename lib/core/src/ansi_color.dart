import 'ansi.dart';

/// ANSI color utility functions for terminal text formatting.
///
/// This module provides convenient functions for applying colors to text
/// in terminal output. Each function wraps text with appropriate ANSI
/// escape sequences while respecting terminal capabilities.
///
/// Example usage:
/// ```dart
/// print(red('Error message'));
/// print(green('Success message', bold: false));
/// print(blue('Info', background: AnsiColor.yellow));
/// ```

/// Apply red color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(red('Error: File not found'));
/// print(red('Warning', bold: false, background: AnsiColor.white));
/// ```
String red(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeRed, bold: bold),
      text,
      background: background,
    );

/// Apply black color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to white for visibility)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(black('Dark text'));
/// ```
String black(
  String text, {
  AnsiColor background = AnsiColor.white,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeBlack, bold: bold),
      text,
      background: background,
    );

/// Apply green color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(green('Operation successful'));
/// ```
String green(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeGreen, bold: bold),
      text,
      background: background,
    );

/// Apply blue color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(blue('Information message'));
/// ```
String blue(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeBlue, bold: bold),
      text,
      background: background,
    );

/// Apply yellow color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(yellow('Warning message'));
/// ```
String yellow(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeYellow, bold: bold),
      text,
      background: background,
    );

/// Apply magenta color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(magenta('Highlighted text'));
/// ```
String magenta(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeMagenta, bold: bold),
      text,
      background: background,
    );

/// Apply cyan color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(cyan('Debug information'));
/// ```
String cyan(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeCyan, bold: bold),
      text,
      background: background,
    );

/// Apply white color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(white('Bright text'));
/// ```
String white(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeWhite, bold: bold),
      text,
      background: background,
    );

/// Apply orange color to text.
///
/// [text] - The text to colorize
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(orange('Alert message'));
/// ```
String orange(
  String text, {
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor(AnsiColor.codeOrange, bold: bold),
      text,
      background: background,
    );

/// Apply grey color to text with adjustable brightness level.
///
/// [text] - The text to colorize
/// [level] - Brightness level from 0.0 (dark) to 1.0 (light), defaults to 0.5
/// [background] - Background color (defaults to none)
/// [bold] - Whether to make text bold (defaults to true)
///
/// Example:
/// ```dart
/// print(grey('Subtle text'));
/// print(grey('Dark grey', level: 0.2));
/// print(grey('Light grey', level: 0.8));
/// ```
String grey(
  String text, {
  double level = 0.5,
  AnsiColor background = AnsiColor.none,
  bool bold = true,
}) =>
    AnsiColor._apply(
      AnsiColor._grey(level: level, bold: bold),
      text,
      background: background,
    );

/// ANSI color management class for terminal text formatting.
///
/// This class provides low-level ANSI color functionality. For most use cases,
/// prefer the convenience functions like [red], [green], [blue], etc.
///
/// Example usage:
/// ```dart
/// final redColor = AnsiColor(AnsiColor.codeRed);
/// print(redColor.apply('Error message'));
/// ```
///
/// See also:
/// * [red], [green], [blue] and other color convenience functions
/// * [Ansi] for ANSI detection and management
class AnsiColor {
  /// Create an ANSI color with the specified color code.
  ///
  /// [code] - The ANSI color code (see class constants)
  /// [bold] - Whether to apply bold formatting (defaults to true)
  const AnsiColor(
    int code, {
    bool bold = true,
  })  : _code = code,
        _bold = bold;

  /// Create a grey color with adjustable brightness level.
  ///
  /// [level] - Brightness level from 0.0 (darkest) to 1.0 (lightest)
  /// [bold] - Whether to apply bold formatting (defaults to true)
  AnsiColor._grey({
    double level = 0.5,
    bool bold = true,
  })  : _code = codeGrey + (level.clamp(0.0, 1.0) * 23).round(),
        _bold = bold;

  /// Reset all color formatting to terminal defaults.
  ///
  /// This clears both foreground and background colors.
  static String reset() => _emit(_resetCode);

  /// Reset only the foreground color to terminal default.
  ///
  /// Background color remains unchanged.
  static String fgReset() => _emit(_fgResetCode);

  /// Reset only the background color to terminal default.
  ///
  /// Foreground color remains unchanged.
  static String bgReset() => _emit(_bgResetCode);

  final int _code;

  final bool _bold;

  //
  static String _emit(String ansicode) => '${Ansi.esc}${ansicode}m';

  /// The ANSI color code for this color instance.
  int get code => _code;

  /// Whether this color uses bold formatting.
  bool get bold => _bold;

  /// Apply this color to the given text.
  ///
  /// [text] - The text to colorize
  /// [background] - Optional background color (defaults to none)
  ///
  /// Returns the text wrapped with appropriate ANSI escape sequences.
  String apply(String text, {AnsiColor background = none}) =>
      _apply(this, text, background: background);

  static String _apply(
    AnsiColor color,
    String text, {
    AnsiColor background = none,
  }) {
    String? output;

    if (Ansi.isSupported) {
      output = '${_fg(color.code, bold: color.bold)}'
          '${_bg(background.code)}$text$_reset';
    } else {
      output = text;
    }
    return output;
  }

  static String get _reset => '${Ansi.esc}${_resetCode}m';

  static String _fg(
    int code, {
    bool bold = true,
  }) {
    String output;

    if (code == none.code) {
      output = '';
    } else if (code > 39) {
      output = '${Ansi.esc}$_fgColorCode$code${bold ? ';1' : ''}m';
    } else {
      output = '${Ansi.esc}$code${bold ? ';1' : ''}m';
    }
    return output;
  }

  // background colors are fg color + 10
  static String _bg(int code) {
    String output;

    if (code == none.code) {
      output = '';
    } else if (code > 49) {
      output = '${Ansi.esc}$_backgroundCode${code + 10}m';
    } else {
      output = '${Ansi.esc}${code + 10}m';
    }
    return output;
  }

  // ANSI reset codes

  /// Reset fg and bg colors
  static const String _resetCode = '0';

  /// Defaults the terminal's fg color without altering the bg.
  static const String _fgResetCode = '39';

  /// Defaults the terminal's bg color without altering the fg.
  static const String _bgResetCode = '49';

  // ANSI color application codes

  // emit this code followed by a color code to set the fg color
  static const String _fgColorCode = '38;5;';

  // emit this code followed by a color code to set the bg color
  static const String _backgroundCode = '48;5;';

  // Standard ANSI color codes

  /// code for black
  static const int codeBlack = 30;

  /// code for  red
  static const int codeRed = 31;

  /// code for green
  static const int codeGreen = 32;

  /// code for yellow
  static const int codeYellow = 33;

  /// code for  blue
  static const int codeBlue = 34;

  /// code for magenta
  static const int codeMagenta = 35;

  /// code for cyan
  static const int codeCyan = 36;

  /// code for white
  static const int codeWhite = 37;

  // Extended color codes

  /// code for orange
  static const int codeOrange = 208;

  /// code for grey
  static const int codeGrey = 232;

  // Predefined color instances
  /// black
  static const AnsiColor black = AnsiColor(codeBlack);

  /// red
  static const AnsiColor red = AnsiColor(codeRed);

  /// green
  static const AnsiColor green = AnsiColor(codeGreen);

  /// yellow
  static const AnsiColor yellow = AnsiColor(codeYellow);

  /// blue
  static const AnsiColor blue = AnsiColor(codeBlue);

  /// magenta
  static const AnsiColor magenta = AnsiColor(codeMagenta);

  /// cyan
  static const AnsiColor cyan = AnsiColor(codeCyan);

  /// white
  static const AnsiColor white = AnsiColor(codeWhite);

  /// orange
  static const AnsiColor orange = AnsiColor(codeOrange);

  /// Represents no color/transparent - suppresses background color codes.
  ///
  /// Use this when you want the default terminal background color.
  static const AnsiColor none = AnsiColor(-1, bold: false);
}
