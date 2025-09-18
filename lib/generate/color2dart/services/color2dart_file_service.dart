import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/helper/helper.dart';
import 'package:morpheme_cli/generate/color2dart/models/color2dart_config.dart';

/// Service for handling file operations in the Color2Dart command.
///
/// This service encapsulates all file-related operations including:
/// - Clearing existing files
/// - Writing files with proper directory creation
/// - Generating base color and theme files
/// - Generating flavor-specific files
/// - Creating library export files
class Color2DartFileService {
  /// Clears existing generated files if the clear flag is set.
  ///
  /// This method deletes existing morpheme_color_*.dart and morpheme_theme_*.dart
  /// files from the colors and themes directories respectively.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths and clear flag
  void clearExistingFiles(Color2DartConfig config) {
    if (!config.clearFiles) return;

    // Delete existing color files
    final fileColors = find(
      'morpheme_color_*.dart',
      workingDirectory: config.pathColors,
    ).toList();

    for (final file in fileColors) {
      if (exists(file)) delete(file);
    }

    // Delete existing theme files
    final fileThemes = find(
      'morpheme_theme_*.dart',
      workingDirectory: config.pathThemes,
    ).toList();

    for (final theme in fileThemes) {
      if (exists(theme)) delete(theme);
    }
  }

  /// Writes content to a file, creating directories as needed.
  ///
  /// This method ensures the directory path exists before writing the file.
  ///
  /// Parameters:
  /// - [path]: The file path to write to
  /// - [content]: The content to write
  void writeToFile(String path, String content) {
    // Ensure directory exists
    final dir = dirname(path);
    createDir(dir);

    // Write content to file
    path.write(content);
  }

  /// Generates base color and theme files.
  ///
  /// This method creates the base MorphemeColor and MorphemeTheme classes.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths
  /// - [baseEntry]: The base color entry from the YAML file
  void generateBaseFiles(Color2DartConfig config, MapEntry? baseEntry) {
    if (baseEntry != null) {
      final dirColor = join(config.pathColors, 'src');
      createDir(dirColor);

      final pathBaseColor = join(dirColor, 'morpheme_color.dart');
      final colors = baseEntry.value['colors'] is Map
          ? baseEntry.value['colors'] as Map
          : {};

      final colorContent = '''import 'package:flutter/material.dart';

extension MorphemeColorExtension on BuildContext {
  MorphemeColor get color => Theme.of(this).extension<MorphemeColor>()!;
}

class MorphemeColor extends ThemeExtension<MorphemeColor> {
  MorphemeColor({
    ${colors.entries.map((e) => '    required this.${e.key.toString().camelCase},').join('\n')}
  });
  
  ${colors.entries.map((e) {
        final key = e.key.toString().camelCase;
        if (e.value is Map) {
          return '''  final MaterialColor ${key.camelCase};''';
        } else {
          return '''  final Color ${key.camelCase};''';
        }
      }).join('\n')}

  @override
  MorphemeColor copyWith({
    ${colors.entries.map((e) {
        final key = e.key.toString().camelCase;
        if (e.value is Map) {
          return '''    MaterialColor? ${key.camelCase},''';
        } else {
          return '''    Color? ${key.camelCase},''';
        }
      }).join('\n')}
  }) {
    return MorphemeColor(
      ${colors.entries.map((e) => '      ${e.key.toString().camelCase}: ${e.key.toString().camelCase} ?? this.${e.key.toString().camelCase},').join('\n')}
    );
  }

  @override
  MorphemeColor lerp(covariant MorphemeColor? other, double t) {
    if (other is! MorphemeColor) {
      return this;
    }

    return MorphemeColor(
      ${colors.entries.map((e) {
        final key = e.key.toString().camelCase;
        if (e.value is Map) {
          return '''    ${key.camelCase}: other.${key.camelCase},''';
        } else {
          return '''    ${key.camelCase}: Color.lerp(${key.camelCase}, other.${key.camelCase}, t) ?? ${key.camelCase},''';
        }
      }).join('\n')}
    );
  }
}
''';

      writeToFile(pathBaseColor, colorContent);

      final dirTheme = join(config.pathThemes, 'src');
      createDir(dirTheme);

      final pathBaseTheme = join(dirTheme, 'morpheme_theme.dart');
      if (!exists(pathBaseTheme)) {
        final themeContent = '''import 'package:flutter/material.dart';

import '../../morpheme_colors/morpheme_colors.dart';

abstract base class MorphemeTheme {
  MorphemeTheme(this.id);

  final String id;

  MorphemeColor get color;
  ThemeData get rawThemeData;
  ColorScheme get colorScheme;

  TextTheme get _getTextTheme => GoogleFonts.robotoTextTheme()
      .apply(bodyColor: color.black, displayColor: color.black)
      .merge(MorphemeTextTheme.textTheme);

  ThemeData get themeData => rawThemeData.copyWith(
        scaffoldBackgroundColor: color.white,
        extensions: [color],
        appBarTheme: AppBarTheme(
          elevation: 0,
          color: color.white,
          foregroundColor: color.black,
          titleTextStyle: _getTextTheme.titleLarge,
        ),
        colorScheme: colorScheme,
        textTheme: _getTextTheme,
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: _getTextTheme.bodyMedium?.apply(color: color.grey1),
          fillColor: color.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MorphemeSizes.s16,
            vertical: MorphemeSizes.s8,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.grey1, width: 1),
            borderRadius: BorderRadius.circular(MorphemeSizes.s8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.grey1, width: 1),
            borderRadius: BorderRadius.circular(MorphemeSizes.s8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.grey1, width: 1),
            borderRadius: BorderRadius.circular(MorphemeSizes.s8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.error, width: 1),
            borderRadius: BorderRadius.circular(MorphemeSizes.s8),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.grey1, width: 1),
            borderRadius: BorderRadius.circular(MorphemeSizes.s8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: _getTextTheme.labelLarge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(MorphemeSizes.s8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: MorphemeSizes.s16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: _getTextTheme.labelLarge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(MorphemeSizes.s8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: MorphemeSizes.s16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: _getTextTheme.labelLarge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(MorphemeSizes.s8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: MorphemeSizes.s16),
          ),
        ),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MorphemeTheme && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
''';

        writeToFile(pathBaseTheme, themeContent);
      }
    }
  }

  /// Generates theme-specific files.
  ///
  /// This method creates theme classes that extend MorphemeTheme.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths and flags
  /// - [theme]: The theme name
  /// - [value]: The theme configuration values
  /// - [flavor]: The flavor name
  void generateThemeFiles(
      Color2DartConfig config, String theme, dynamic value, String flavor) {
    final className = config.allFlavor ? '$flavor $theme' : theme;

    final dir = join(config.pathThemes, 'src');
    createDir(dir);

    final pathItemTheme =
        join(dir, 'morpheme_theme_${className.snakeCase}.dart');

    if (!exists(pathItemTheme)) {
      final brightness = value['brightness'] == 'dark' ? 'dark' : 'light';
      final themeContent = '''import 'package:flutter/material.dart';

import '../../morpheme_colors/morpheme_colors.dart';
import 'morpheme_theme.dart';

final class MorphemeTheme${className.pascalCase} extends MorphemeTheme {
  MorphemeTheme${className.pascalCase}() : super('${className.snakeCase}');

  @override
  MorphemeColor get color => MorphemeColor${className.pascalCase}();

  @override
  ThemeData get rawThemeData => ThemeData.$brightness().copyWith(
        extensions: [color],
      );

  @override
  ColorScheme get colorScheme => ColorScheme.$brightness(
        primary: color.primary,
      );
}
''';

      writeToFile(pathItemTheme, themeContent);
    }
  }

  /// Generates color-specific files.
  ///
  /// This method creates color classes that extend MorphemeColor.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths and flags
  /// - [theme]: The theme name
  /// - [value]: The theme configuration values
  /// - [flavor]: The flavor name
  void generateColorFiles(
      Color2DartConfig config, String theme, dynamic value, String flavor) {
    final className = config.allFlavor ? '$flavor $theme' : theme;

    final dir = join(config.pathColors, 'src');
    createDir(dir);

    final pathItemColor =
        join(dir, 'morpheme_color_${className.snakeCase}.dart');
    final colors = value['colors'] is Map ? value['colors'] as Map : {};

    final colorContent = '''import 'package:flutter/material.dart';

import 'morpheme_color.dart';

class MorphemeColor${className.pascalCase} extends MorphemeColor {
  MorphemeColor${className.pascalCase}() : super(
    ${colors.entries.map((e) {
      return generateColorOrMaterialColor(e);
    }).join('\n')}
  );
}
''';

    writeToFile(pathItemColor, colorContent);
  }

  /// Generates a color or MaterialColor property declaration.
  ///
  /// This method creates the appropriate Dart code for a color property,
  /// handling both regular Color and MaterialColor types.
  ///
  /// Parameters:
  /// - [entry]: The color entry from the configuration
  ///
  /// Returns: A string containing the Dart code for the color property
  String generateColorOrMaterialColor(MapEntry entry) {
    final key = entry.key.toString().camelCase;
    dynamic value = entry.value;

    if (value is Map) {
      final primary = validateAndConvertColor(value['primary'].toString());
      final swatch = value['swatch'] as Map;

      return '''    $key: const MaterialColor(
    $primary,
    <int, Color>{
      ${swatch.entries.map((e) => '${e.key}: Color(${validateAndConvertColor(e.value.toString())}),').join('\n      ')} 
    },
  ),''';
    } else {
      value = validateAndConvertColor(value.toString());
      return '    $key: const Color($value),';
    }
  }

  /// Validates and converts a color string to the proper format.
  ///
  /// This method validates hex color formats and converts them to the
  /// 0x format required by Flutter.
  ///
  /// Parameters:
  /// - [color]: The color string to validate and convert
  ///
  /// Returns: A validated and converted color string
  String validateAndConvertColor(String color) {
    RegExp hexColorRegex =
        RegExp(r'^(#|0x|0X)?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

    if (hexColorRegex.hasMatch(color)) {
      String formattedColor =
          color.replaceAll("#", "").replaceAll(RegExp(r'0x|0X'), '');

      if (formattedColor.length == 6) {
        formattedColor = "FF$formattedColor";
      }

      return "0x$formattedColor";
    } else {
      StatusHelper.failed('Format warna tidak valid: $color');
      return "Format warna tidak valid: $color";
    }
  }

  /// Generates library export files.
  ///
  /// This method creates the library files that export all generated
  /// color and theme files.
  ///
  /// Parameters:
  /// - [config]: The configuration containing paths
  void generateLibraryExports(Color2DartConfig config) {
    // Generate color library exports
    final pathLibraryColor = join(config.pathColors, 'morpheme_colors.dart');
    final fileLibraryColors = find(
      '*.dart',
      recursive: false,
      includeHidden: false,
      workingDirectory: join(config.pathColors, 'src'),
      types: [Find.file],
    ).toList();

    final colorExports = fileLibraryColors
        .map((e) => "export 'src/${e.split(separator).last}';")
        .join('\n');

    writeToFile(pathLibraryColor, colorExports);

    // Generate theme library exports
    final pathLibraryTheme = join(config.pathThemes, 'morpheme_themes.dart');
    final fileLibraryThemes = find(
      '*.dart',
      recursive: false,
      includeHidden: false,
      workingDirectory: join(config.pathThemes, 'src'),
      types: [Find.file],
    ).toList();

    final themeExports = fileLibraryThemes
        .map((e) => "export 'src/${e.split(separator).last}';")
        .join('\n');

    writeToFile(pathLibraryTheme, themeExports);
  }
}
