import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:morpheme_cli/core/core.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:path/path.dart';

import '../models/json2dart_config.dart';
import '../processors/feature_processor.dart';

/// Orchestrates the entire Json2Dart generation process
///
/// This orchestrator coordinates feature processing, file generation,
/// and maintains the overall generation workflow.
class GenerationOrchestrator {
  final FeatureProcessor _featureProcessor;
  final bool _verbose;

  GenerationOrchestrator({
    required FeatureProcessor featureProcessor,
    bool verbose = false,
  })  : _featureProcessor = featureProcessor,
        _verbose = verbose;

  /// Generates code for a specific feature
  ///
  /// [featureName] - Name of the feature to generate
  /// [featureConfig] - Configuration for the feature
  /// [globalConfig] - Global configuration settings
  /// [projectName] - Name of the project
  /// [configFile] - Path to the configuration file
  /// Returns true if successful, false otherwise
  Future<bool> generateFeature({
    required String featureName,
    required dynamic featureConfig,
    required Json2DartConfig globalConfig,
    required String projectName,
    required String configFile,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Generating feature: $featureName');
      }

      // Validate feature configuration
      if (!_validateFeatureConfig(featureConfig)) {
        StatusHelper.failed('Invalid feature configuration for: $featureName');
        return false;
      }

      // Determine feature path
      final featurePath =
          _determineFeaturePath(featureName, globalConfig, configFile);
      if (featurePath == null) {
        StatusHelper.warning('Feature path not found for: $featureName');
        return false;
      }

      if (_verbose) {
        StatusHelper.success('Feature path: $featurePath');
      }

      // Process the feature
      final success = await _featureProcessor.processFeature(
        featurePath: featurePath,
        featureName: featureName,
        featureConfig: featureConfig,
        globalConfig: globalConfig,
        projectName: projectName,
      );

      if (success) {
        if (_verbose) {
          StatusHelper.success('Successfully generated feature: $featureName');
        }
      } else {
        StatusHelper.failed('Failed to generate feature: $featureName');
      }

      return success;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error generating feature $featureName: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Validates feature configuration
  bool _validateFeatureConfig(dynamic featureConfig) {
    if (featureConfig == null) {
      return false;
    }

    if (featureConfig is! Map) {
      StatusHelper.warning('Feature configuration must be a Map');
      return false;
    }

    return true;
  }

  /// Determines the feature path based on configuration
  String? _determineFeaturePath(
    String featureName,
    Json2DartConfig globalConfig,
    String configFile,
  ) {
    try {
      final lastPathSegment = configFile.split(separator).last;

      // Check if this is an app-specific configuration
      if (lastPathSegment.contains('_')) {
        final appsName = lastPathSegment.split('_').first;
        return join(current, 'apps', appsName, 'features', featureName);
      }

      // Default feature path
      final featurePath = join(current, 'features', featureName);

      // Verify the feature directory exists
      if (!exists(featurePath)) {
        StatusHelper.warning('Feature directory not found: $featurePath');
        return null;
      }

      return featurePath;
    } catch (e) {
      StatusHelper.warning('Failed to determine feature path: $e');
      return null;
    }
  }

  /// Generates multiple features in batch using concurrent processing
  ///
  /// [features] - Map of feature names to their configurations
  /// [globalConfig] - Global configuration settings
  /// [projectName] - Name of the project
  /// [configFile] - Path to the configuration file
  /// Returns true if all features were generated successfully
  Future<bool> generateFeatures({
    required Map<String, dynamic> features,
    required Json2DartConfig globalConfig,
    required String projectName,
    required String configFile,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Generating ${features.length} features...');
      }

      // Use concurrent processing for better performance
      final success = await _processFeaturesConcurrently(
        features: features,
        globalConfig: globalConfig,
        projectName: projectName,
        configFile: configFile,
      );

      if (_verbose) {
        if (success) {
          StatusHelper.success('All features generated successfully');
        } else {
          StatusHelper.warning('Some features failed to generate');
        }
      }

      return success;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error generating features: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Processes features concurrently using batch processing
  Future<bool> _processFeaturesConcurrently({
    required Map<String, dynamic> features,
    required Json2DartConfig globalConfig,
    required String projectName,
    required String configFile,
  }) async {
    // Convert features map to list for easier chunking
    final featureEntries = features.entries.toList();

    // Determine optimal batch size based on number of features
    final batchSize = _calculateOptimalBatchSize(featureEntries.length);

    if (_verbose) {
      StatusHelper.success(
          'Processing ${featureEntries.length} features in batches of $batchSize');
    }

    bool allSuccessful = true;
    int processedCount = 0;

    // Process features in batches
    for (int i = 0; i < featureEntries.length; i += batchSize) {
      final end = min(i + batchSize, featureEntries.length);
      final batch = featureEntries.sublist(i, end);

      if (_verbose) {
        StatusHelper.success(
            'Processing batch ${i ~/ batchSize + 1}/${(featureEntries.length / batchSize).ceil()} '
            '(${batch.length} features)');
      }

      // Process batch concurrently
      final batchFutures = <Future<bool>>[];
      for (final entry in batch) {
        final future = generateFeature(
          featureName: entry.key,
          featureConfig: entry.value,
          globalConfig: globalConfig,
          projectName: projectName,
          configFile: configFile,
        );
        batchFutures.add(future);
      }

      // Wait for all features in this batch to complete
      final batchResults = await Future.wait(batchFutures);

      // Check results
      for (int j = 0; j < batchResults.length; j++) {
        processedCount++;
        if (!batchResults[j]) {
          allSuccessful = false;
          if (_verbose) {
            StatusHelper.warning('Failed to process feature: ${batch[j].key}');
          }
        }
      }

      if (_verbose) {
        StatusHelper.success('Completed batch ${i ~/ batchSize + 1}, '
            'processed $processedCount/${featureEntries.length} features so far');
      }
    }

    return allSuccessful;
  }

  /// Calculates optimal batch size based on feature count
  int _calculateOptimalBatchSize(int featureCount) {
    if (featureCount > 100) {
      return max(10, Platform.numberOfProcessors * 2);
    } else if (featureCount > 50) {
      return max(5, Platform.numberOfProcessors);
    } else if (featureCount > 10) {
      return max(3, (Platform.numberOfProcessors * 0.75).ceil());
    } else {
      return max(1, (Platform.numberOfProcessors * 0.5).ceil());
    }
  }
}
