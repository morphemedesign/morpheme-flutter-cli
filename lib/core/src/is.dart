import 'dart:io';

/// File system existence and type checking utilities.
///
/// This module provides utility functions for checking file system entity
/// existence, types, and environment conditions.

/// Check if a file system path exists.
///
/// Parameters:
/// - [path]: The path to check (cannot be empty)
/// - [followLinks]: If true, follows symbolic links (defaults to true)
///
/// Returns true if the path exists, false otherwise.
///
/// Throws [ArgumentError] if [path] is empty.
///
/// Example:
/// ```dart
/// if (exists('/path/to/file.txt')) {
///   print('File exists');
/// }
///
/// // Check without following symbolic links
/// if (exists('/path/to/symlink', followLinks: false)) {
///   print('Symlink exists');
/// }
/// ```
bool exists(String path, {bool followLinks = true}) {
  if (path.isEmpty) {
    throw ArgumentError('path must not be empty.');
  }

  final exists = FileSystemEntity.typeSync(path, followLinks: followLinks) !=
      FileSystemEntityType.notFound;

  return exists;
}

/// Check if a path points to a directory.
///
/// Parameters:
/// - [path]: The path to check
///
/// Returns true if the path exists and is a directory, false otherwise.
///
/// Example:
/// ```dart
/// if (isDirectory('/path/to/directory')) {
///   print('It\'s a directory');
/// }
/// ```
bool isDirectory(String path) {
  final fromType = FileSystemEntity.typeSync(path);
  return fromType == FileSystemEntityType.directory;
}

/// Check if a path points to a symbolic link.
///
/// This function checks the path without following links to determine
/// if it's a symbolic link itself.
///
/// Parameters:
/// - [path]: The path to check
///
/// Returns true if the path is a symbolic link, false otherwise.
///
/// Example:
/// ```dart
/// if (isLink('/path/to/symlink')) {
///   print('It\'s a symbolic link');
/// }
/// ```
bool isLink(String path) {
  final fromType = FileSystemEntity.typeSync(path, followLinks: false);
  return fromType == FileSystemEntityType.link;
}

/// Check if the current environment is a CI/CD environment.
///
/// This function checks for the standard CI environment variable
/// that most CI/CD systems set.
///
/// Returns true if running in a CI/CD environment, false otherwise.
///
/// Example:
/// ```dart
/// if (isCiCdEnvironment) {
///   print('Running in CI/CD');
///   // Disable interactive features
/// }
/// ```
bool get isCiCdEnvironment =>
    Platform.environment.containsKey('CI') &&
    Platform.environment['CI'] == 'true';
