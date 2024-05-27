import 'package:collection/collection.dart';
import 'package:morpheme_cli/constants.dart';
import 'package:morpheme_cli/dependency_manager.dart';
import 'package:morpheme_cli/extensions/extensions.dart';
import 'package:morpheme_cli/helper/helper.dart';

class Color2DartCommand extends Command {
  Color2DartCommand() {
    argParser.addFlag(
      'clear-files',
      abbr: 'c',
      help: 'Clear files before generated new files.',
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

  String pathColors = join('core', 'lib', 'src', 'themes', 'morpheme_colors');
  String pathThemes = join('core', 'lib', 'src', 'themes', 'morpheme_themes');

  @override
  void run() async {
    final clearOldFiles = argResults?['clear-files'] as bool;

    if (argResults?.rest.firstOrNull == 'init') {
      init();
      return;
    }
    final argFlavor = argResults.getOptionFlavor(defaultTo: '');
    String pathColorYaml = join(current, 'color2dart', 'color2dart.yaml');
    if (argFlavor.isNotEmpty) {
      pathColorYaml = join(current, 'color2dart', argFlavor, 'color2dart.yaml');
    }
    if (!exists(pathColorYaml)) {
      StatusHelper.failed(
        'File $pathColorYaml is not found, you can create color2dart with `morpheme color2dart init`',
      );
    }

    final colorYaml = YamlHelper.loadFileYaml(pathColorYaml);
    if (clearOldFiles) deleteFiles();
    generateBase(colorYaml.entries.firstOrNull);

    colorYaml.forEach((theme, value) {
      generateTheme(theme, value);
      generateColors(theme, value);
    });

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
      final pathBaseColor = join(pathColors, 'src', 'morpheme_color.dart');
      final colors = mapEntry.value['colors'] is Map
          ? mapEntry.value['colors'] as Map
          : {};
      pathBaseColor
          .write('''import 'package:core/src/shared/global/global_cubit.dart';
import 'package:flutter/material.dart';
import 'package:morpheme_library/morpheme_library.dart';

extension MorphemeColorExtension on BuildContext {
  MorphemeColor get color => read<GlobalCubit>().state.theme.color;
}

abstract base class MorphemeColor {
  ${colors.entries.map((e) {
        final key = e.key.toString().camelCase;
        if (e.value is Map) {
          return '''  MaterialColor get ${key.camelCase};''';
        } else {
          return '''  Color get ${key.camelCase};''';
        }
      }).join('\n')}
}
''');

      final pathBaseTheme = join(pathThemes, 'src', 'morpheme_theme.dart');
      if (!exists(pathBaseTheme)) {
        pathBaseTheme
            .write('''import 'package:core/src/component/component.dart';
import 'package:core/src/constants/constants.dart';
import 'package:core/src/themes/morpheme_colors/morpheme_colors.dart';
import 'package:dependency_manager/dependency_manager.dart';
import 'package:flutter/material.dart';

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

  void generateTheme(String theme, dynamic value) {
    final pathItemTheme = join(
        pathThemes, 'src', 'morpheme_theme_${theme.toString().snakeCase}.dart');
    if (!exists(pathItemTheme)) {
      final brightness = value['brightness'] == 'dark' ? 'dark' : 'light';
      pathItemTheme.write(
          '''import 'package:core/src/themes/morpheme_colors/morpheme_colors.dart';
import 'package:flutter/material.dart';

import 'morpheme_theme.dart';

final class MorphemeTheme${theme.toString().pascalCase} extends MorphemeTheme {
  MorphemeTheme${theme.toString().pascalCase}() : super('${theme.toString().snakeCase}');

  @override
  MorphemeColor get color => MorphemeColor${theme.toString().pascalCase}();

  @override
  ThemeData get rawThemeData => ThemeData.$brightness();

  @override
  ColorScheme get colorScheme => ColorScheme.$brightness(
        primary: color.primary,
        error: color.error,
      );
}
''');
    }
  }

  void generateColors(String theme, dynamic value) {
    final pathItemColor = join(
        pathColors, 'src', 'morpheme_color_${theme.toString().snakeCase}.dart');
    final colors = value['colors'] is Map ? value['colors'] as Map : {};
    pathItemColor.write('''import 'package:flutter/material.dart';

import 'morpheme_color.dart';

final class MorphemeColor${theme.pascalCase} extends MorphemeColor {
  static final MorphemeColor${theme.pascalCase} _instance = MorphemeColor${theme.pascalCase}._();

  factory MorphemeColor${theme.pascalCase}() {
    return _instance;
  }

  MorphemeColor${theme.pascalCase}._();

  ${colors.entries.map((e) {
      return generateColorOrMatrialColor(e);
    }).join('\n')}
}
''');
  }

  String generateColorOrMatrialColor(MapEntry entry) {
    final key = entry.key.toString().camelCase;
    dynamic value = entry.value;
    if (value is Map) {
      final primary = validateAndConvertColor(value['primary'].toString());
      final swatch = value['swatch'] as Map;
      return '''  @override
  MaterialColor $key = const MaterialColor(
    $primary,
    <int, Color>{
      ${swatch.entries.map((e) => '${e.key}: Color(${validateAndConvertColor(e.value.toString())}),').join('\n      ')} 
    },
  );''';
    } else {
      value = validateAndConvertColor(value.toString());
      return '''  @override
  Color get $key => const Color($value);''';
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
    pathLibraryColor.write('''library morpheme_colors;

export 'src/morpheme_color.dart';
${colorYaml.entries.map((e) {
      final theme = e.key.toString().snakeCase;
      return '''export 'src/morpheme_color_$theme.dart';''';
    }).join('\n')}
''');

    final pathLibraryTheme = join(pathThemes, 'morpheme_themes.dart');
    pathLibraryTheme.write('''library morpheme_themes;

export 'src/morpheme_theme.dart';
${colorYaml.entries.map((e) {
      final theme = e.key.toString().snakeCase;
      return '''export 'src/morpheme_theme_$theme.dart';''';
    }).join('\n')}
''');
  }

  void init() {
    final path = join(current, 'color2dart');
    DirectoryHelper.createDir(path, recursive: true);

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
