import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class Color2DartCommand extends Command {
  Color2DartCommand() {
    argParser.addOptionMorphemeYaml();
    argParser.addFlag(
      'clear-files',
      abbr: 'c',
      help: 'Clear files before generated new files.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'all-flavor',
      abbr: 'a',
      help: 'Generate all flavor with the same time.',
      defaultsTo: false,
    );
    argParser.addOptionFlavor(defaultsTo: '');
  }

  @override
  String get name => 'color2dart';

  @override
  String get description => 'Generate dart color class from yaml.';

  @override
  String get category => Constants.generate;

  bool isAllFlavor = false;

  String pathColors = join('core', 'lib', 'src', 'themes', 'morpheme_colors');
  String pathThemes = join('core', 'lib', 'src', 'themes', 'morpheme_themes');

  @override
  void run() async {
    final clearOldFiles = argResults?['clear-files'] as bool;
    isAllFlavor = argResults?['all-flavor'] as bool;

    if (argResults?.rest.firstOrNull == 'init') {
      init();
      return;
    }

    final argMorphemeYaml = argResults.getOptionMorphemeYaml();
    YamlHelper.validateMorphemeYaml(argMorphemeYaml);
    final morphemeYaml = YamlHelper.loadFileYaml(argMorphemeYaml);

    if (morphemeYaml['color2dart'] == null) {
      StatusHelper.failed('color2dart not found in $argMorphemeYaml');
    }

    final morphemeColor2dart = morphemeYaml['color2dart'] as Map;
    final color2dartDir = morphemeColor2dart['color2dart_dir']?.toString();
    final outputDir = morphemeColor2dart['output_dir']?.toString();

    if (outputDir != null) {
      pathColors = join(outputDir, 'morpheme_colors');
      pathThemes = join(outputDir, 'morpheme_themes');
    }

    if (clearOldFiles) deleteFiles();

    final argFlavor = argResults.getOptionFlavor(defaultTo: '');

    String pathColorYaml = color2dartDir != null
        ? join(current, color2dartDir, 'color2dart.yaml')
        : join(current, 'color2dart', 'color2dart.yaml');
    if (argFlavor.isNotEmpty) {
      pathColorYaml = color2dartDir != null
          ? join(current, color2dartDir, argFlavor, 'color2dart.yaml')
          : join(current, 'color2dart', argFlavor, 'color2dart.yaml');
    }

    List<String> allFlavorPath = isAllFlavor
        ? find(
            'color2dart.yaml',
            recursive: true,
            types: [Find.file],
            workingDirectory: color2dartDir ?? join(current),
          ).toList()
        : [pathColorYaml];

    final colorYaml = YamlHelper.loadFileYaml(allFlavorPath.first);
    generateBase(colorYaml.entries.firstOrNull);

    for (var path in allFlavorPath) {
      final flavor = path
          .replaceAll('${separator}color2dart.yaml', '')
          .split(separator)
          .last;

      final colorYaml = YamlHelper.loadFileYaml(path);

      colorYaml.forEach((theme, value) {
        generateTheme(theme, value, flavor);
        generateColors(theme, value, flavor);
      });
    }

    generateLibrary(colorYaml);

    await ModularHelper.format([pathColors, pathThemes]);

    StatusHelper.success('morpheme color2dart');
  }

  void deleteFiles() {
    final fileColors = find(
      'morpheme_color_*.dart',
      workingDirectory: pathColors,
    ).toList();
    for (final file in fileColors) {
      if (exists(file)) delete(file);
    }
    final fileThemes = find(
      'morpheme_theme_*.dart',
      workingDirectory: pathThemes,
    ).toList();
    for (final theme in fileThemes) {
      if (exists(theme)) delete(theme);
    }
  }

  void generateBase(MapEntry? mapEntry) {
    if (mapEntry != null) {
      final dirColor = join(pathColors, 'src');
      DirectoryHelper.createDir(dirColor);

      final pathBaseColor = join(dirColor, 'morpheme_color.dart');
      final colors = mapEntry.value['colors'] is Map
          ? mapEntry.value['colors'] as Map
          : {};
      pathBaseColor.write('''import 'package:flutter/material.dart';

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
''');

      final dirTheme = join(pathThemes, 'src');
      DirectoryHelper.createDir(dirTheme);

      final pathBaseTheme = join(dirTheme, 'morpheme_theme.dart');
      if (!exists(pathBaseTheme)) {
        pathBaseTheme.write('''import 'package:flutter/material.dart';

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
''');
      }
    }
  }

  void generateTheme(String theme, dynamic value, String flavor) {
    final className = isAllFlavor ? '$flavor $theme' : theme;

    final dir = join(pathThemes, 'src');
    DirectoryHelper.createDir(dir);

    final pathItemTheme =
        join(dir, 'morpheme_theme_${className.snakeCase}.dart');
    if (!exists(pathItemTheme)) {
      final brightness = value['brightness'] == 'dark' ? 'dark' : 'light';
      pathItemTheme.write('''import 'package:flutter/material.dart';

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
''');
    }
  }

  void generateColors(String theme, dynamic value, String flavor) {
    final className = isAllFlavor ? '$flavor $theme' : theme;

    final dir = join(pathColors, 'src');
    DirectoryHelper.createDir(dir);

    final pathItemColor =
        join(dir, 'morpheme_color_${className.snakeCase}.dart');
    final colors = value['colors'] is Map ? value['colors'] as Map : {};
    pathItemColor.write('''import 'package:flutter/material.dart';

import 'morpheme_color.dart';

 class MorphemeColor${className.pascalCase} extends MorphemeColor {

  MorphemeColor${className.pascalCase}() : super(
    ${colors.entries.map((e) {
      return generateColorOrMatrialColor(e);
    }).join('\n')}
  );
}
''');
  }

  String generateColorOrMatrialColor(MapEntry entry) {
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

  void generateLibrary(Map colorYaml) {
    final pathLibraryColor = join(pathColors, 'morpheme_colors.dart');
    final fileLibraryColors = find(
      '*.dart',
      recursive: false,
      includeHidden: false,
      workingDirectory: join(pathColors, 'src'),
      types: [Find.file],
    ).toList();
    pathLibraryColor.write(fileLibraryColors
        .map((e) => "export 'src/${e.split(separator).last}';")
        .join('\n'));

    final pathLibraryTheme = join(pathThemes, 'morpheme_themes.dart');
    final fileLibraryThemes = find(
      '*.dart',
      recursive: false,
      includeHidden: false,
      workingDirectory: join(pathThemes, 'src'),
      types: [Find.file],
    ).toList();
    pathLibraryTheme.write(fileLibraryThemes
        .map((e) => "export 'src/${e.split(separator).last}';")
        .join('\n'));
  }

  void init() {
    final path = join(current, 'color2dart');
    DirectoryHelper.createDir(path);

    if (!exists(join(path, 'color2dart.yaml'))) {
      join(path, 'color2dart.yaml')
          .write('''# brightness can be 'light' or 'dark'

light:
  brightness: "light"
  colors:
    white: "0xFFFFFFFF"
    black: "0xFF1E1E1E"
    grey: "0xFF979797"
    grey1: "0xFFCFCFCF"
    grey2: "0xFFE5E5E5"
    grey3: "0xFFF5F5F5"
    grey4: "0xFFF9F9F9"
    primary: "0xFF006778"
    secondary: "0xFFFFD124"
    primaryLighter: "0xFF00AFC1"
    warning: "0xFFDAB320"
    info: "0xFF00AFC1"
    success: "0xFF22A82F"
    error: "0xFFD66767"
    bgError: "0xFFFFECEA"
    bgInfo: "0xFFDFFCFF"
    bgSuccess: "0xFFECFFEE"
    bgWarning: "0xFFFFF9E3"
dark:
  brightnes: "dark"
  colors:
    white: "0xFF1E1E1E"
    black: "0xFFFFFFFF"
    grey: "0xFF979797"
    grey1: "0xFFF9F9F9"
    grey2: "0xFFF5F5F5"
    grey3: "0xFFE5E5E5"
    grey4: "0xFFCFCFCF"
    primary: "0xFF006778"
    secondary: "0xFFFFD124"
    primaryLighter: "0xFF00AFC1"
    warning: "0xFFDAB320"
    info: "0xFF00AFC1"
    success: "0xFF22A82F"
    error: "0xFFD66767"
    bgError: "0xFFFFECEA"
    bgInfo: "0xFFDFFCFF"
    bgSuccess: "0xFFECFFEE"
    bgWarning: "0xFFFFF9E3"
''');
    }

    StatusHelper.success('morpheme color2dart init');
  }
}
