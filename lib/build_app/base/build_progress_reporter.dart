/// Enhanced progress reporting for build operations.
///
/// Provides real-time feedback during long-running build processes
/// with stage-specific progress indicators and time estimates.
///
/// ## Usage
/// ```dart
/// BuildProgressReporter.reportPhase('Building Android APK');
/// BuildProgressReporter.reportBuildStage(
///   BuildStage.compilation,
///   0.5,
///   estimatedRemaining: Duration(minutes: 2),
/// );
/// BuildProgressReporter.reportCompletion('Android APK build', duration);
/// ```
library;

import 'package:morpheme_cli/core/core.dart';

/// Build stage enumeration.
///
/// Represents the different stages of a build process
/// with associated display names and progress tracking.
enum BuildStage {
  /// Initial validation and setup
  initialization,

  /// Configuration preparation
  configuration,

  /// Dependency resolution
  dependencies,

  /// Code compilation
  compilation,

  /// Asset processing
  assets,

  /// Linking and optimization
  linking,

  /// Code signing (iOS/macOS)
  signing,

  /// Final packaging
  packaging;

  /// Gets display name for this build stage.
  String get displayName {
    switch (this) {
      case BuildStage.initialization:
        return 'Initialization';
      case BuildStage.configuration:
        return 'Configuration';
      case BuildStage.dependencies:
        return 'Dependencies';
      case BuildStage.compilation:
        return 'Compilation';
      case BuildStage.assets:
        return 'Assets';
      case BuildStage.linking:
        return 'Linking';
      case BuildStage.signing:
        return 'Code Signing';
      case BuildStage.packaging:
        return 'Packaging';
    }
  }

  /// Gets emoji icon for this build stage.
  String get icon {
    switch (this) {
      case BuildStage.initialization:
        return '🚀';
      case BuildStage.configuration:
        return '⚙️';
      case BuildStage.dependencies:
        return '📦';
      case BuildStage.compilation:
        return '🔨';
      case BuildStage.assets:
        return '🎨';
      case BuildStage.linking:
        return '🔗';
      case BuildStage.signing:
        return '🔒';
      case BuildStage.packaging:
        return '📱';
    }
  }
}

/// Build artifact information.
///
/// Contains details about generated build artifacts
/// including file paths, sizes, and metadata.
class BuildArtifact {
  /// The type of artifact (APK, IPA, etc.)
  final String type;

  /// Full path to the artifact file
  final String path;

  /// File size in bytes
  final int? sizeBytes;

  /// Additional metadata about the artifact
  final Map<String, dynamic> metadata;

  /// Creates a new BuildArtifact.
  const BuildArtifact({
    required this.type,
    required this.path,
    this.sizeBytes,
    this.metadata = const {},
  });

  /// Gets formatted file size string.
  String get formattedSize {
    if (sizeBytes == null) return 'Unknown size';

    if (sizeBytes! < 1024) {
      return '${sizeBytes!} B';
    } else if (sizeBytes! < 1024 * 1024) {
      return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes! < 1024 * 1024 * 1024) {
      return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  String toString() {
    return 'BuildArtifact(type: $type, path: $path, size: $formattedSize)';
  }
}

/// Enhanced progress reporting utilities for build operations.
///
/// Provides consistent progress feedback mechanisms with
/// visual indicators, time estimates, and artifact reporting.
abstract class BuildProgressReporter {
  /// Reports build stage progress with time estimates.
  ///
  /// Parameters:
  /// - [stage]: Current build stage
  /// - [progress]: Progress value between 0.0 and 1.0
  /// - [estimatedRemaining]: Optional time estimate for completion
  static void reportBuildStage(
    BuildStage stage,
    double progress, {
    Duration? estimatedRemaining,
  }) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final progressBar = _generateProgressBar(progress, width: 20);
    final timeText = estimatedRemaining != null
        ? ' (${_formatDuration(estimatedRemaining)} remaining)'
        : '';

    final message =
        '${stage.icon} ${stage.displayName}: $progressBar $percentage%$timeText';
    print('\r$message');
  }

  /// Reports platform-specific preparation steps.
  ///
  /// Parameters:
  /// - [step]: Description of the preparation step
  /// - [completed]: Whether the step has been completed
  static void reportPreparationStep(String step, bool completed) {
    final status = completed ? '✅' : '⏳';
    printMessage('$status $step');
  }

  /// Reports the start of an operation phase.
  ///
  /// Parameters:
  /// - [phase]: Description of the operation phase
  static void reportPhase(String phase) {
    printMessage('📋 $phase');
  }

  /// Reports successful completion of an operation.
  ///
  /// Parameters:
  /// - [operation]: Description of the completed operation
  /// - [duration]: Optional duration of the operation
  static void reportCompletion(String operation, [Duration? duration]) {
    final timeText = duration != null ? ' (${_formatDuration(duration)})' : '';
    printMessage('✅ $operation completed$timeText');
  }

  /// Reports build failure with error context.
  ///
  /// Parameters:
  /// - [operation]: Description of the failed operation
  /// - [error]: Error message or exception
  /// - [stage]: Optional build stage where failure occurred
  static void reportFailure(
    String operation,
    dynamic error, {
    BuildStage? stage,
  }) {
    final stageText = stage != null ? ' during ${stage.displayName}' : '';
    printMessage('❌ $operation failed$stageText: $error');
  }

  /// Reports final build artifacts and locations.
  ///
  /// Parameters:
  /// - [artifacts]: List of generated build artifacts
  static void reportBuildArtifacts(List<BuildArtifact> artifacts) {
    if (artifacts.isEmpty) {
      printMessage('📄 No build artifacts generated');
      return;
    }

    printMessage('📄 Build artifacts generated:');
    for (final artifact in artifacts) {
      printMessage(
          '   ${artifact.type}: ${artifact.path} (${artifact.formattedSize})');
    }
  }

  /// Reports build environment information.
  ///
  /// Parameters:
  /// - [platform]: Target platform name
  /// - [config]: Build configuration summary
  static void reportBuildEnvironment(
      String platform, Map<String, dynamic> config) {
    printMessage('🏗️  Building $platform application');

    final flavor = config['flavor'];
    final mode = config['mode'];
    final target = config['target'];

    if (flavor != null) printMessage('   Flavor: $flavor');
    if (mode != null) printMessage('   Mode: $mode');
    if (target != null) printMessage('   Target: $target');
  }

  /// Reports build warnings or important notices.
  ///
  /// Parameters:
  /// - [message]: Warning message
  /// - [severity]: Warning severity level
  static void reportWarning(String message, {String severity = 'WARNING'}) {
    printMessage('⚠️  $severity: $message');
  }

  /// Reports build performance metrics.
  ///
  /// Parameters:
  /// - [metrics]: Map of performance metrics
  static void reportPerformanceMetrics(Map<String, dynamic> metrics) {
    printMessage('📊 Build performance metrics:');

    metrics.forEach((key, value) {
      printMessage('   $key: $value');
    });
  }

  /// Generates a text-based progress bar.
  ///
  /// Parameters:
  /// - [progress]: Progress value between 0.0 and 1.0
  /// - [width]: Width of the progress bar in characters
  ///
  /// Returns: String representation of the progress bar
  static String _generateProgressBar(double progress, {int width = 20}) {
    final completed = (progress * width).round();
    final remaining = width - completed;

    final filled = '█' * completed;
    final empty = '░' * remaining;

    return '[$filled$empty]';
  }

  /// Formats a duration for display.
  ///
  /// Parameters:
  /// - [duration]: Duration to format
  ///
  /// Returns: Human-readable duration string
  static String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Reports real-time build output with filtering.
  ///
  /// Parameters:
  /// - [output]: Build process output line
  /// - [filterWarnings]: Whether to highlight warnings
  /// - [filterErrors]: Whether to highlight errors
  static void reportBuildOutput(
    String output, {
    bool filterWarnings = true,
    bool filterErrors = true,
  }) {
    final line = output.trim();
    if (line.isEmpty) return;

    // Highlight errors
    if (filterErrors && _isErrorLine(line)) {
      printMessage('❌ $line');
      return;
    }

    // Highlight warnings
    if (filterWarnings && _isWarningLine(line)) {
      printMessage('⚠️  $line');
      return;
    }

    // Regular output
    print('   $line');
  }

  /// Checks if an output line indicates an error.
  ///
  /// Parameters:
  /// - [line]: Output line to check
  ///
  /// Returns: true if the line indicates an error
  static bool _isErrorLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('error:') ||
        lowerLine.contains('exception:') ||
        lowerLine.contains('failed:') ||
        lowerLine.contains('error ') ||
        lowerLine.startsWith('error');
  }

  /// Checks if an output line indicates a warning.
  ///
  /// Parameters:
  /// - [line]: Output line to check
  ///
  /// Returns: true if the line indicates a warning
  static bool _isWarningLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('warning:') ||
        lowerLine.contains('warn:') ||
        lowerLine.contains('deprecated') ||
        lowerLine.startsWith('warning');
  }
}
