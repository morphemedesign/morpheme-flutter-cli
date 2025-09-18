import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

import '../managers/json2dart_config_manager.dart';
import '../models/json2dart_config.dart';
import '../orchestrators/generation_orchestrator.dart';
import '../services/file_operation_service.dart';

/// Processes Json2Dart commands and coordinates the generation workflow
///
/// This processor handles command line argument parsing, configuration loading,
/// and delegates to the GenerationOrchestrator for actual processing.
class CommandProcessor {
  final GenerationOrchestrator _orchestrator;
  final Json2DartConfigManager _configManager;
  final bool _verbose;
  final Set<String> _extraDirectories =
      <String>{}; // Track extra directories for formatting

  CommandProcessor({
    required GenerationOrchestrator orchestrator,
    required Json2DartConfigManager configManager,
    required FileOperationService fileService,
    bool verbose = false,
  })  : _orchestrator = orchestrator,
        _configManager = configManager,
        _verbose = verbose;

  /// Executes the Json2Dart command with the given arguments
  ///
  /// [argResults] - Parsed command line arguments
  /// [projectName] - Name of the project
  /// Returns true if successful, false otherwise
  Future<bool> execute({
    required ArgResults? argResults,
    required String projectName,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Starting Json2Dart command execution');
      }

      // Clear extra directories from previous runs
      _extraDirectories.clear();

      // Find configuration files
      final configFiles = _findConfigFiles(argResults);
      if (configFiles.isEmpty) {
        StatusHelper.warning('No json2dart configuration files found');
        return false;
      }

      bool allSuccessful = true;

      // Process each configuration file
      for (final configFile in configFiles) {
        final success = await _processConfigFile(
          configFile: configFile,
          argResults: argResults,
          projectName: projectName,
        );

        if (!success) {
          allSuccessful = false;
          StatusHelper.failed(
              'Failed to process configuration file: $configFile');
          // Continue processing other files
        }
      }

      if (_verbose && allSuccessful) {
        StatusHelper.success(
            'Json2Dart command execution completed successfully');
      }

      return allSuccessful;
    } catch (e, stackTrace) {
      StatusHelper.failed('Error executing Json2Dart command: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Finds Json2Dart configuration files based on command line arguments
  List<String> _findConfigFiles(ArgResults? argResults) {
    try {
      final appsName = argResults?['apps-name'] as String?;
      final searchFileJson2Dart = appsName?.isNotEmpty ?? false
          ? '${appsName}_json2dart.yaml'
          : '*json2dart.yaml';

      final workingDirectory = find(
        searchFileJson2Dart,
        workingDirectory: join(current, 'json2dart'),
      ).toList();

      if (_verbose) {
        StatusHelper.success(
            'Found ${workingDirectory.length} configuration files');
      }

      return workingDirectory;
    } catch (e) {
      StatusHelper.warning('Error finding configuration files: $e');
      return [];
    }
  }

  /// Processes a single configuration file
  Future<bool> _processConfigFile({
    required String configFile,
    required ArgResults? argResults,
    required String projectName,
  }) async {
    try {
      if (_verbose) {
        StatusHelper.success('Processing configuration file: $configFile');
      }

      // Load and parse YAML configuration using YamlHelper
      final yamlContent = YamlHelper.loadFileYaml(configFile);
      final Map<String, dynamic> yamlMap = _convertYamlMapToMap(yamlContent);

      // Load configuration using the config manager
      final config = _configManager.loadConfig(yamlMap, argResults);

      // Generate endpoint if needed
      if (config.isEndpoint) {
        await _generateEndpoints(configFile, argResults);
      }

      // Extract features from the YAML (everything except the 'json2dart' section)
      final features = Map<String, dynamic>.from(yamlMap);
      features.remove('json2dart');

      // Filter features if specific feature name is provided
      Map<String, dynamic> filteredFeatures = features;
      if (config.featureName != null) {
        if (features.containsKey(config.featureName)) {
          filteredFeatures = {
            config.featureName!: features[config.featureName]
          };
        } else {
          StatusHelper.warning(
              'Feature ${config.featureName} not found in configuration');
          return false;
        }
      }

      // Process features using orchestrator
      final success = await _orchestrator.generateFeatures(
        features: filteredFeatures,
        globalConfig: config,
        projectName: projectName,
        configFile: configFile,
      );

      // Format generated files if requested
      if (success && config.isFormat) {
        await _formatGeneratedFiles(config, configFile);
      }

      if (_verbose && success) {
        StatusHelper.success(
            'Successfully processed configuration file: $configFile');
      }

      return success;
    } catch (e, stackTrace) {
      StatusHelper.failed('Failed to process configuration file: $e');
      if (_verbose) {
        StatusHelper.failed('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Formats generated files using dart format
  Future<void> _formatGeneratedFiles(
      Json2DartConfig config, String configFile) async {
    try {
      if (_verbose) {
        StatusHelper.success('Formatting generated files');
      }

      // Determine paths to format based on configuration
      final pathsToFormat = <String>[];

      if (config.featureName != null) {
        // Format specific feature
        final lastPathSegment = configFile.split(separator).last;
        String featurePath;

        if (lastPathSegment.contains('_')) {
          // App-specific feature
          final appsName = lastPathSegment.split('_').first;
          featurePath =
              join(current, 'apps', appsName, 'features', config.featureName!);
        } else {
          // Project-level feature
          featurePath = join(current, 'features', config.featureName!);
        }

        // If page name is also specified, format only that page and its tests
        if (config.pageName != null) {
          pathsToFormat.add(join(featurePath, 'lib', config.pageName!));
          if (config.isUnitTest || config.isOnlyUnitTest) {
            pathsToFormat.add(
              join(featurePath, 'test', '${config.pageName!}_test'),
            );
          }
        } else {
          // Format the entire feature
          pathsToFormat.add(featurePath);
        }
      } else {
        // Format all features
        final lastPathSegment = configFile.split(separator).last;
        if (lastPathSegment.contains('_')) {
          // App-specific features
          final appsName = lastPathSegment.split('_').first;
          pathsToFormat.add(join(current, 'apps', appsName, 'features'));
        } else {
          // Project-level features
          pathsToFormat.add(join(current, 'features'));
        }
      }

      if (pathsToFormat.isNotEmpty) {
        // Format the determined paths
        await ModularHelper.format(pathsToFormat);
      }

      if (_verbose) {
        StatusHelper.success('Successfully formatted generated files');
      }
    } catch (e) {
      StatusHelper.warning('Failed to format generated files: $e');
    }
  }

  /// Generates endpoints if needed
  Future<void> _generateEndpoints(
      String configFile, ArgResults? argResults) async {
    try {
      if (_verbose) {
        StatusHelper.success('Generating endpoints');
      }

      final argMorphemeYaml = argResults.getOptionMorphemeYaml();
      final lastPathJson2Dart = configFile.split(separator).last;
      final appsName = lastPathJson2Dart.contains('_')
          ? lastPathJson2Dart.split('_').first
          : null;

      var command = 'morpheme endpoint';
      if (appsName != null) {
        command += ' -a $appsName';
      }
      command += ' --morpheme-yaml $argMorphemeYaml';

      if (_verbose) {
        StatusHelper.success('Executing: $command');
      }

      await command.run;
    } catch (e) {
      StatusHelper.warning('Failed to generate endpoints: $e');
    }
  }

  /// Converts YamlMap to regular Map recursively
  Map<String, dynamic> _convertYamlMapToMap(dynamic yamlContent) {
    if (yamlContent is Map) {
      final result = <String, dynamic>{};
      yamlContent.forEach((key, value) {
        result[key.toString()] = _convertYamlValue(value);
      });
      return result;
    }
    return {};
  }

  /// Converts YAML values recursively, handling nested structures
  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _convertYamlMapToMap(value);
    } else if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    } else {
      return value;
    }
  }
}
