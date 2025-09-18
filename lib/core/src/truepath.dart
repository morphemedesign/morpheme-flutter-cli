import 'package:path/path.dart';

/// Path normalization and resolution utilities.
///
/// This module provides functions for creating absolute, normalized paths
/// from relative or partial path components.

/// Create an absolute, normalized path from path components.
///
/// This function combines multiple path components into a single,
/// absolute path that is normalized (removes '..' and '.' components).
/// It's similar to the Unix 'realpath' command.
///
/// Parameters:
/// - [part1]: First path component (required)
/// - [part2] through [part7]: Additional optional path components
///
/// Returns an absolute, normalized path string.
///
/// Example:
/// ```dart
/// // Simple absolute path
/// final path1 = truepath('/home/user/documents');
/// // Result: '/home/user/documents' (Unix) or 'C:\\home\\user\\documents' (Windows)
///
/// // Combine multiple components
/// final path2 = truepath('/home', 'user', 'documents', 'file.txt');
/// // Result: '/home/user/documents/file.txt'
///
/// // Resolve relative paths
/// final path3 = truepath('../documents', 'subfolder');
/// // Result: absolute path relative to current directory
///
/// // Handle complex relative paths
/// final path4 = truepath('/home/user', '../other', './documents');
/// // Result: '/home/other/documents'
/// ```

String truepath(
  String part1, [
  String? part2,
  String? part3,
  String? part4,
  String? part5,
  String? part6,
  String? part7,
]) {
  if (part1.isEmpty) {
    throw ArgumentError('First path component cannot be empty');
  }

  return normalize(
      absolute(join(part1, part2, part3, part4, part5, part6, part7)));
}
