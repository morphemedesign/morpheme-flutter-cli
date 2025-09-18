import 'dart:io';

import 'package:path/path.dart';

import 'is.dart';

/// Path search utilities for finding executable applications.
///
/// This module provides functionality similar to the Unix 'which' command,
/// allowing you to locate executable files in the system PATH.
///
/// Example usage:
/// ```dart
/// // Find the location of the 'dart' executable
/// final dartLocation = which('dart');
/// if (dartLocation.found) {
///   print('Dart found at: ${dartLocation.path}');
/// }
///
/// // Find all occurrences of 'python'
/// final pythonLocations = which('python', first: false);
/// for (final path in pythonLocations.paths) {
///   print('Python found at: $path');
/// }
/// ```

/// Search the PATH for an executable application.
///
/// This function searches for the specified application in all directories
/// listed in the PATH environment variable, from left to right.
///
/// Parameters:
/// - [appname]: Name of the application to find
/// - [first]: If true, stops after finding the first match (default: true)
/// - [verbose]: If true, provides detailed search progress (default: false)
/// - [extensionSearch]: If true, searches for Windows extensions (default: true)
/// - [progress]: Optional callback for processing search progress
///
/// Returns a [Which] object containing search results and status.
///
/// The [extensionSearch] parameter is useful for cross-platform development.
/// When true on Windows, it will search for 'dart.exe', 'dart.bat', etc.
/// when you search for 'dart'.
///
/// Example:
/// ```dart
/// // Find the first occurrence of 'ls'
/// final result = which('ls');
/// if (result.found) {
///   print('Found at: ${result.path}');
/// }
///
/// // Find all occurrences with verbose output
/// which('python', first: false, verbose: true);
///
/// // Cross-platform executable search
/// which('dart'); // Finds 'dart' on Unix, 'dart.exe' on Windows
/// ```
Which which(
  String appname, {
  bool first = true,
  bool verbose = false,
  bool extensionSearch = true,
  void Function(WhichSearch)? progress,
}) =>
    _Which().which(
      appname,
      first: first,
      verbose: verbose,
      extensionSearch: extensionSearch,
      progress: progress,
    );

/// Search results container for executable location queries.
///
/// This class holds the results of a PATH search operation, including
/// all found locations and status information.
///
/// Example:
/// ```dart
/// final result = which('python');
///
/// if (result.found) {
///   print('Primary location: ${result.path}');
///   print('All locations: ${result.paths}');
/// } else {
///   print('Python not found in PATH');
/// }
/// ```
class Which {
  String? _path;
  final _paths = <String>[];
  bool _found = false;

  /// The progress used to accumualte the results
  /// If verbose was passed this will contain all
  /// of the verbose output. If you passed a [progress]
  /// into the which call then this will be the same progress
  /// otherwse a Progress.devNull will be allocated and returned.
  Stream<String>? progress;

  /// The primary path where the application was found.
  ///
  /// This is the first location found in the PATH search,
  /// which is the one the OS would use when executing the command.
  ///
  /// Returns null if the application was not found.
  ///
  /// See [paths] for all found locations.
  String? get path => _path;

  /// All paths where the application was found.
  ///
  /// Contains a list of all directories in PATH that contain the
  /// requested application, in the order they appear in PATH.
  ///
  /// If [first] was true during the search, this will contain
  /// at most one path. Otherwise, it contains all found locations.
  ///
  /// Returns an empty list if no paths were found.
  List<String> get paths => _paths;

  /// Whether the application was found in at least one PATH location.
  ///
  /// Returns true if [paths] is not empty.
  bool get found => _found;

  /// Whether the application was not found in any PATH location.
  ///
  /// Returns true if [paths] is empty. This is the inverse of [found].
  bool get notfound => !_found;
}

/// Individual search result for a single PATH directory.
///
/// This class represents the result of searching a single directory
/// in the PATH for the requested application.
class WhichSearch {
  /// Create a successful search result.
  ///
  /// Use this constructor when the application was found in the [path] directory.
  /// [exePath] should be the full path to the executable.
  WhichSearch.found(this.path, this.exePath) : found = true;

  /// Create a failed search result.
  ///
  /// Use this constructor when the application was not found in the [path] directory.
  WhichSearch.notfound(this.path) : found = false;

  /// The PATH directory that was searched.
  String path;

  /// Whether the application was found in this directory.
  bool found;

  /// The full path to the executable if found.
  ///
  /// This is null if [found] is false.
  String? exePath;
}

class _Which {
  ///
  /// Searches the path for the given appname.
  Which which(
    String appname, {
    required bool extensionSearch,
    bool first = true,
    bool verbose = false,
    void Function(WhichSearch)? progress,
  }) {
    final results = Which();
    final paths =
        Platform.environment['PATH']?.split(Platform.isWindows ? ';' : ':') ??
            [];

    for (final path in paths) {
      final fullpath =
          _appExists(path, appname, extensionSearch: extensionSearch);
      if (fullpath == null) {
        progress?.call(WhichSearch.notfound(path));
      } else {
        progress?.call(WhichSearch.found(path, fullpath));

        if (!results._found) {
          results._path = fullpath;
        }
        results.paths.add(fullpath);
        results._found = true;
        if (first) {
          break;
        }
      }
    }

    return results;
  }

  /// Checks if [appname] exists in [pathTo].
  ///
  /// On Windows if [extensionSearch] is true and [appname] doesn't
  /// have an extension then we check each appname.extension variant
  /// to see if it exists. We first check if just an file of [appname] with
  /// no extension exits.
  String? _appExists(
    String pathTo,
    String appname, {
    required bool extensionSearch,
  }) {
    final pathToAppname = join(pathTo, appname);
    if (exists(pathToAppname)) {
      return pathToAppname;
    }
    if (Platform.isWindows && extensionSearch && extension(appname).isEmpty) {
      final pathExt = Platform.environment['PATHEXT'];

      if (pathExt != null) {
        final extensions = pathExt.split(';');
        for (final extension in extensions) {
          final fullname = '$pathToAppname$extension';
          if (exists(fullname)) {
            return fullname;
          }
        }
      }
    }
    return null;
  }
}
