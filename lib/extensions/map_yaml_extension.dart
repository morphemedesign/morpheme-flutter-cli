import 'package:morpheme_cli/helper/helper.dart';

extension MapYamlExtension on Map {
  String get projectName => this['project_name'] ?? 'morpheme';
  int get concurrent => this['concurrent'] ?? ModularHelper.defaultConcurrent;
}
