import 'package:collection/collection.dart';

class ModelClassName {
  ModelClassName({
    required this.className,
    required this.parent,
    required this.created,
    this.parentList,
  });

  final String className;
  final String parent;
  final bool created;
  final String? parentList;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModelClassName &&
        other.className == className &&
        other.parent == parent &&
        other.parentList == parentList;
  }

  @override
  int get hashCode =>
      className.hashCode ^ parent.hashCode ^ parentList.hashCode;
}

abstract class ModelClassNameHelper {
  static const geekLetter = [
    'Alpha',
    'Beta',
    'Gamma',
    'Delta',
    'Epsilon',
    'Zeta',
    'Eta',
    'Theta',
    'Iota',
    'Kappa',
    'Lambda',
    'Mu',
    'Nu',
    'Xi',
    'Omicron',
    'Pi',
    'Rho',
    'Sigma',
    'Tau',
    'Upsilon',
    'Phi',
    'Chi',
    'Psi',
    'Psi',
    'Omega',
  ];

  static String getClassName(List<ModelClassName> listClassName, String suffix,
      String name, bool root, bool created, String parent,
      [String? parentList]) {
    if (root) listClassName.clear();
    String apiClassName = root ? '$suffix$name' : '$name$suffix';

    if (listClassName.firstWhereOrNull((element) =>
            element.className == apiClassName &&
            element.parent == parent &&
            element.parentList == parentList &&
            element.created) !=
        null) {
      apiClassName = apiClassName;
    } else if (listClassName.firstWhereOrNull((element) =>
            element.className == apiClassName && element.created) !=
        null) {
      for (var element in geekLetter) {
        final newClassApiName = element + apiClassName;

        if (listClassName.firstWhereOrNull((element) =>
                element.className == newClassApiName &&
                element.parent == parent &&
                element.parentList == parentList &&
                element.created) !=
            null) {
          apiClassName = newClassApiName;
          break;
        }

        if (listClassName.firstWhereOrNull((element) =>
                element.className == newClassApiName &&
                element.parent == parent &&
                !element.created) !=
            null) {
          apiClassName = newClassApiName;
          break;
        }

        if (listClassName.firstWhereOrNull((element) =>
                element.className == newClassApiName &&
                element.parent != parent) ==
            null) {
          apiClassName = newClassApiName;
          break;
        }
      }
    }

    final modelClassName = ModelClassName(
      className: apiClassName,
      parent: parent,
      created: created,
      parentList: parentList,
    );
    listClassName.remove(modelClassName);
    listClassName.add(modelClassName);

    return apiClassName;
  }
}
