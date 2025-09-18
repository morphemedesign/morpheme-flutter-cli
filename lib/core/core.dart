/// Core utilities for CLI application development.
///
/// This library provides a comprehensive set of utilities for building
/// command-line applications, including file operations, process execution,
/// console output, and system utilities.
///
/// ## Modules
///
/// ### Console and Display
/// - **ANSI**: Color and formatting utilities for terminal output
/// - **Loading**: Animated loading indicators for long-running operations
/// - **Print**: Error output utilities for stderr
///
/// ### File System Operations
/// - **File Operations**: Copy, move, create, delete files and directories
/// - **Path Utilities**: Path normalization and resolution
/// - **File Search**: Find files and directories with glob patterns
/// - **File I/O**: Read and write text files
///
/// ### Process and Command Execution
/// - **String Extensions**: Execute commands with enhanced process control
/// - **Command Parsing**: Parse command-line strings into arguments
///
/// ### System Utilities
/// - **Environment Detection**: Check for CI/CD environments
/// - **Path Search**: Find executables in system PATH
/// - **File Type Detection**: Check file system entity types
///
/// ### Text Processing
/// - **Content Replacement**: Find and replace text in files
/// - **Logging**: Simple file-based logging utilities
///
/// ## Example Usage
///
/// ```dart
/// import 'package:morpheme_cli/core/core.dart';
///
/// // File operations
/// copy('/path/to/source.txt', '/path/to/dest.txt');
/// createDir('/path/to/new/directory', recursive: true);
///
/// // Console output with colors
/// print(red('Error: Something went wrong'));
/// print(green('Success: Operation completed'));
///
/// // Process execution
/// await 'flutter build apk'.run;
///
/// // File search
/// find('*.dart').forEach(print);
///
/// // Loading animation
/// final loading = Loading();
/// loading.start();
/// // ... long operation ...
/// loading.stop();
/// ```
library;

// ANSI and Console Output
export 'src/ansi.dart';
export 'src/ansi_color.dart';

// File System Operations
export 'src/copy.dart';
export 'src/copy_tree.dart';
export 'src/create.dart';
export 'src/delete.dart';
export 'src/move.dart';
export 'src/touch.dart';

// File System Queries and Search
export 'src/find.dart';
export 'src/is.dart';
export 'src/which.dart';

// I/O and Text Processing
export 'src/read.dart';
export 'src/replace.dart';

// Process and Command Execution
export 'src/commandline_converter.dart';
export 'src/string_extension.dart';

// System Utilities
export 'src/truepath.dart';

// Console and UI
export 'src/loading.dart';
export 'src/print.dart';
