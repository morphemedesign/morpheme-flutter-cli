import 'package:morpheme_cli/core/src/loading.dart';

/// Progress reporting utilities for long-running operations.
///
/// Provides consistent progress feedback mechanisms that
/// can be used across different commands.
abstract class ProgressReporter {
  /// Reports progress with a simple percentage indicator.
  ///
  /// Parameters:
  /// - [operation]: Description of the current operation
  /// - [current]: Current progress value
  /// - [total]: Total expected value
  static void reportProgress(String operation, int current, int total) {
    final percentage = (current / total * 100).toStringAsFixed(1);
    final progressBar = _generateProgressBar(current, total, width: 20);

    print('\r$operation: $progressBar $percentage% ($current/$total)');
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

  /// Generates a text-based progress bar.
  ///
  /// Parameters:
  /// - [current]: Current progress value
  /// - [total]: Total expected value
  /// - [width]: Width of the progress bar in characters
  ///
  /// Returns: String representation of the progress bar
  static String _generateProgressBar(int current, int total, {int width = 20}) {
    final progress = (current / total * width).round();
    final filled = '█' * progress;
    final empty = '░' * (width - progress);
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
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}
