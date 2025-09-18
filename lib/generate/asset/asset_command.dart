import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

import 'orchestrators/asset_orchestrator.dart';
import 'models/models.dart';

/// Command for generating asset constants from Flutter pubspec.yaml definitions.
///
/// This command scans asset directories defined in pubspec.yaml and generates
/// corresponding Dart classes with static constants for each asset file.
///
/// Features:
/// - Generates type-safe asset constants
/// - Supports flavor-specific asset overrides
/// - Creates library export files for easy importing
/// - Validates asset naming and directory structure
/// - Formats generated code automatically
///
/// Usage:
/// ```
/// morpheme generate assets
/// morpheme generate assets --flavor dev
/// morpheme generate assets --morpheme-yaml custom/morpheme.yaml
/// ```
class AssetCommand extends Command {
  /// Asset orchestrator for coordinating the generation workflow.
  final AssetOrchestrator _orchestrator;

  /// Creates a new AssetCommand instance.
  ///
  /// Parameters:
  /// - [orchestrator]: Optional custom orchestrator for testing
  AssetCommand({
    AssetOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator ?? AssetOrchestrator() {
    argParser.addOptionMorphemeYaml();
    argParser.addOptionFlavor(defaultsTo: '');
  }

  @override
  String get name => 'assets';

  @override
  String get description =>
      'Generate asset constants from Flutter pubspec.yaml definitions.';

  @override
  String get category => Constants.generate;

  @override
  void run() async {
    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    final argFlavor = argResults.getOptionFlavor(defaultTo: '');

    try {
      // Execute the complete asset generation workflow
      final result = await _orchestrator.execute(
        morphemeYamlPath: argMorphemeYaml,
        flavor: argFlavor.isNotEmpty ? argFlavor : null,
      );

      if (result.isSuccess) {
        _reportSuccess(result);
      } else {
        _reportFailure(result);
      }
    } catch (e, stackTrace) {
      StatusHelper.failed(
        'Unexpected error during asset generation: $e',
        suggestion:
            'Check the error details and ensure all requirements are met',
        examples: [
          'morpheme generate assets --help',
          'morpheme doctor',
        ],
      );
      print('Stack trace: $stackTrace');
    }
  }

  /// Reports successful generation results.
  void _reportSuccess(GenerationResult result) {
    // Report warnings if any
    if (result.hasWarnings) {
      for (final warning in result.warnings) {
        StatusHelper.warning(warning);
      }
    }

    // Report generated files
    for (final file in result.generatedFiles) {
      StatusHelper.generated(file.path);
    }

    // Report summary
    final summary = _buildSuccessSummary(result);
    print(summary);

    StatusHelper.success('Asset generation completed successfully');
  }

  /// Reports generation failure.
  void _reportFailure(GenerationResult result) {
    final errorMessage = result.errorMessage ?? 'Unknown error';

    StatusHelper.failed(
      errorMessage,
      suggestion: 'Review the error details and fix any configuration issues',
      examples: [
        'Check that morpheme.yaml has an "assets" section',
        'Verify that pubspec.yaml has valid asset paths',
        'Ensure asset directories exist and are readable',
        'Run "morpheme doctor" to check environment setup',
      ],
    );
  }

  /// Builds a summary message for successful generation.
  String _buildSuccessSummary(GenerationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('\n=== Asset Generation Summary ===');
    buffer.writeln('Files generated: ${result.fileCount}');
    buffer.writeln('Classes created: ${result.metrics.classesCreated}');
    buffer.writeln('Assets processed: ${result.metrics.assetsProcessed}');
    buffer.writeln('Duration: ${result.metrics.duration.inMilliseconds}ms');

    if (result.hasWarnings) {
      buffer.writeln('Warnings: ${result.warnings.length}');
    }

    buffer.writeln('================================');

    return buffer.toString();
  }
}
