import 'dart:io';

import 'ansi_color.dart';

/// Helper class for ANSI escape sequence detection and management.
///
/// This class provides utilities for detecting ANSI support in terminals
/// and managing ANSI escape sequences for text formatting.
///
/// Example usage:
/// ```dart
/// if (Ansi.isSupported) {
///   print('\x1b[31mRed text\x1b[0m');
/// } else {
///   print('Plain text');
/// }
/// ```
///
/// See also:
/// * [AnsiColor] for color application utilities
/// * [red], [green], [blue] and other color functions
class Ansi {
  /// Factory ctor
  factory Ansi() => _self;

  const Ansi._internal();

  static const _self = Ansi._internal();
  static bool? _emitAnsi;

  /// Returns true if stdout supports ANSI escape characters.
  ///
  /// This detection is more reliable on non-Windows platforms.
  /// On Windows, it relies on [stdout.supportsAnsiEscapes].
  /// On other platforms, it defaults to true unless explicitly overridden.
  static bool get isSupported {
    if (_emitAnsi == null) {
      // We don't trust [stdout.supportsAnsiEscapes] except on Windows.
      // [stdout] relies on the TERM environment variable
      // which generates false negatives.
      if (!Platform.isWindows) {
        _emitAnsi = true;
      } else {
        _emitAnsi = stdout.supportsAnsiEscapes;
      }
    }
    return _emitAnsi!;
  }

  /// Override the detected ANSI settings.
  ///
  /// Dart's ANSI detection isn't always accurate, so this provides
  /// a way to manually control ANSI output.
  ///
  /// - If set to `true`: ANSI escape characters are emitted
  /// - If set to `false`: ANSI escape characters are not emitted
  ///
  /// Use [resetEmitAnsi] to return to automatic detection.
  static set isSupported(bool emit) => _emitAnsi = emit;

  /// Reset ANSI emission to automatic detection.
  ///
  /// If you have manually set [isSupported], calling this will
  /// reset the setting back to automatic platform detection.
  static void resetEmitAnsi() => _emitAnsi = null;

  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const esc = '\x1b[';
  // static const esc = '\u001b[';

  /// Strip all ANSI escape sequences from [line].
  ///
  /// This method is useful for:
  /// - Logging messages without formatting
  /// - Calculating the number of printable characters
  /// - Storing plain text versions of formatted output
  ///
  /// Example:
  /// ```dart
  /// final colored = red('Hello World');
  /// final plain = Ansi.strip(colored); // 'Hello World'
  /// ```
  static String strip(String line) =>
      line.replaceAll(RegExp('\x1b\\[[0-9;]+m'), '');
}
