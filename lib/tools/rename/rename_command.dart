import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';

/// Command to rename files to snake_case with optional prefix and suffix.
///
/// This command searches for files matching a glob pattern and renames them
/// to follow snake_case naming convention. It supports adding prefixes and
/// suffixes to filenames while preserving file extensions.
class RenameCommand extends Command {
  RenameCommand() {
    argParser.addOption(
      'prefix',
      abbr: 'p',
      help: 'Add prefix to filename (e.g., "test_" → "test_filename")',
      valueHelp: 'prefix',
    );
    argParser.addOption(
      'suffix',
      abbr: 's',
      help: 'Add suffix to filename (e.g., "_test" → "filename_test")',
      valueHelp: 'suffix',
    );
    argParser.addOption(
      'glob-pattern',
      abbr: 'g',
      help: 'Glob pattern to match files (e.g., "*.dart", "test/**/*.dart")',
      defaultsTo: '*',
      valueHelp: 'pattern',
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Show what would be renamed without actually renaming files',
      negatable: false,
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed information about the renaming process',
      negatable: false,
    );
  }

  @override
  String get name => 'rename';

  @override
  String get description =>
      'Rename files to snake_case with optional prefix/suffix';

  @override
  String get category => Constants.tools;

  @override
  void run() {
    final options = _parseArguments();

    printMessage(blue('Starting file rename operation...'));
    if (options.verbose) {
      _printOptions(options);
    }

    final files = _findMatchingFiles(options);

    if (files.isEmpty) {
      StatusHelper.warning(
          'No files found matching pattern: ${options.globPattern}');
      return;
    }

    final renameOperations = _planRenameOperations(files, options);

    if (renameOperations.isEmpty) {
      printMessage(green('No files need to be renamed.'));
      return;
    }

    _displayRenamePreview(renameOperations, options);

    if (!options.isDryRun) {
      _executeRenames(renameOperations, options);
    }

    _printSummary(renameOperations, options);
  }

  /// Parses and validates command line arguments.
  RenameOptions _parseArguments() {
    final prefix = (argResults?['prefix'] as String?) ?? '';
    final suffix = (argResults?['suffix'] as String?) ?? '';
    final globPattern = (argResults?['glob-pattern'] as String?) ?? '*';
    final workingDirectory =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : '.';
    final isDryRun = argResults?['dry-run'] as bool? ?? false;
    final verbose = argResults?['verbose'] as bool? ?? false;

    // Validate working directory exists
    if (!exists(workingDirectory)) {
      StatusHelper.failed(
          'Working directory does not exist: $workingDirectory');
      throw ArgumentError('Invalid working directory: $workingDirectory');
    }

    return RenameOptions(
      prefix: prefix,
      suffix: suffix,
      globPattern: globPattern,
      workingDirectory: workingDirectory,
      isDryRun: isDryRun,
      verbose: verbose,
    );
  }

  /// Prints the parsed options for verbose mode.
  void _printOptions(RenameOptions options) {
    printMessage(blue('Rename Options:'));
    printMessage('• Working directory: ${options.workingDirectory}');
    printMessage('• Glob pattern: ${options.globPattern}');
    if (options.prefix.isNotEmpty) {
      printMessage('• Prefix: "${options.prefix}"');
    }
    if (options.suffix.isNotEmpty) {
      printMessage('• Suffix: "${options.suffix}"');
    }
    printMessage('• Mode: ${options.isDryRun ? "Dry run" : "Execute"}');
    printMessage('');
  }

  /// Finds all files matching the glob pattern.
  List<String> _findMatchingFiles(RenameOptions options) {
    try {
      final files = find(
        options.globPattern,
        workingDirectory: options.workingDirectory,
      ).toList();

      // Filter out directories - we only want to rename files
      final fileList = files.where((file) => !isDirectory(file)).toList();

      if (options.verbose) {
        printMessage('Found ${fileList.length} files matching pattern.');
      }

      return fileList;
    } catch (e) {
      StatusHelper.failed('Error finding files: $e');
      rethrow;
    }
  }

  /// Plans rename operations for all matching files.
  List<RenameOperation> _planRenameOperations(
    List<String> files,
    RenameOptions options,
  ) {
    final operations = <RenameOperation>[];

    for (final file in files) {
      final newPath = _generateNewFilename(file, options);

      // Only add operation if the filename actually changes
      if (file != newPath) {
        operations.add(RenameOperation(
          originalPath: file,
          newPath: newPath,
        ));
      }
    }

    return operations;
  }

  /// Generates a new filename following snake_case with prefix/suffix.
  String _generateNewFilename(String filePath, RenameOptions options) {
    final pathParts = filePath.split(separator);
    final filename = pathParts.removeLast();
    final filenameParts = filename.split('.');

    String baseName = filenameParts.first;
    final extensions =
        filenameParts.length > 1 ? filenameParts.skip(1).toList() : <String>[];

    // Apply prefix if specified and not already present
    if (options.prefix.isNotEmpty && !baseName.startsWith(options.prefix)) {
      baseName = '${options.prefix}_$baseName';
    }

    // Apply suffix if specified and not already present
    if (options.suffix.isNotEmpty && !baseName.endsWith(options.suffix)) {
      baseName = '${baseName}_${options.suffix}';
    }

    // Convert to snake_case
    baseName = baseName.snakeCase;

    // Reconstruct filename with extensions
    final newFilename =
        extensions.isEmpty ? baseName : '$baseName.${extensions.join('.')}';

    // Reconstruct full path
    pathParts.add(newFilename);
    return pathParts.join(separator);
  }

  /// Displays a preview of planned rename operations.
  void _displayRenamePreview(
    List<RenameOperation> operations,
    RenameOptions options,
  ) {
    final modeText = options.isDryRun ? 'Would rename' : 'Will rename';
    printMessage('${blue(modeText)} ${operations.length} file(s):');
    printMessage('');

    for (final operation in operations) {
      final originalBasename = basename(operation.originalPath);
      final newBasename = basename(operation.newPath);

      if (options.verbose) {
        printMessage('  ${grey(operation.originalPath)}');
        printMessage('  ${green('→')} ${operation.newPath}');
      } else {
        printMessage('  $originalBasename ${green('→')} $newBasename');
      }
    }
    printMessage('');
  }

  /// Executes the planned rename operations.
  void _executeRenames(
    List<RenameOperation> operations,
    RenameOptions options,
  ) {
    int successCount = 0;
    int failureCount = 0;

    for (final operation in operations) {
      try {
        // Check if target already exists
        if (exists(operation.newPath)) {
          StatusHelper.warning(
              'Target already exists, skipping: ${basename(operation.newPath)}');
          failureCount++;
          continue;
        }

        move(operation.originalPath, operation.newPath);

        if (options.verbose) {
          StatusHelper.generated(
              'Renamed: ${basename(operation.originalPath)} → ${basename(operation.newPath)}');
        }

        successCount++;
      } catch (e) {
        StatusHelper.failed(
            'Failed to rename ${basename(operation.originalPath)}: $e');
        failureCount++;
      }
    }

    if (failureCount == 0) {
      StatusHelper.success('All files renamed successfully!');
    } else {
      StatusHelper.warning('$successCount succeeded, $failureCount failed');
    }
  }

  /// Prints a summary of the rename operation.
  void _printSummary(
    List<RenameOperation> operations,
    RenameOptions options,
  ) {
    if (options.isDryRun) {
      printMessage(
          '${yellow('Dry run completed.')} Run without --dry-run to execute.');
    } else {
      printMessage(green('Rename operation completed.'));
    }

    if (operations.isNotEmpty && options.verbose) {
      printMessage('');
      printMessage(blue('Summary:'));
      printMessage('• Files processed: ${operations.length}');
      printMessage('• Pattern used: ${options.globPattern}');
      printMessage('• Working directory: ${options.workingDirectory}');
    }
  }
}

/// Configuration options for the rename operation.
class RenameOptions {
  const RenameOptions({
    required this.prefix,
    required this.suffix,
    required this.globPattern,
    required this.workingDirectory,
    required this.isDryRun,
    required this.verbose,
  });

  /// Prefix to add to filenames
  final String prefix;

  /// Suffix to add to filenames
  final String suffix;

  /// Glob pattern to match files
  final String globPattern;

  /// Directory to search for files
  final String workingDirectory;

  /// Whether this is a dry run (preview only)
  final bool isDryRun;

  /// Whether to show verbose output
  final bool verbose;
}

/// Represents a planned file rename operation.
class RenameOperation {
  const RenameOperation({
    required this.originalPath,
    required this.newPath,
  });

  /// Original file path
  final String originalPath;

  /// New file path after rename
  final String newPath;
}
