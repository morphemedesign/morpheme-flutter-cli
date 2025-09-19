import 'package:collection/collection.dart';

/// Represents a model class name with its associated metadata.
///
/// This class is used to track model class names during code generation,
/// including their parent relationships and creation status to ensure
/// unique naming when conflicts occur.
class ModelClassName {
  /// Creates a new ModelClassName instance.
  ///
  /// Parameters:
  /// - [className]: The name of the class
  /// - [parent]: The parent context or container of this class
  /// - [created]: Whether this class has been created/generated
  /// - [parentList]: Optional parent list context
  ModelClassName({
    required this.className,
    required this.parent,
    required this.created,
    this.parentList,
  });

  /// The name of the class
  final String className;

  /// The parent context or container of this class
  final String parent;

  /// Whether this class has been created/generated
  final bool created;

  /// Optional parent list context
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

/// Helper class for generating unique model class names.
///
/// This class provides utilities for generating unique class names
/// during code generation, resolving naming conflicts by appending
/// Greek letters to duplicate names.
abstract class ModelClassNameHelper {
  /// Greek letters used as prefixes for resolving naming conflicts.
  ///
  /// When class name conflicts occur, these Greek letters are prepended
  /// to the class name to make it unique. The list is ordered from
  /// Alpha (first choice) to Omega (last choice).
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

  /// Generates a unique class name based on the provided parameters.
  ///
  /// This method implements the class name generation algorithm that ensures
  /// unique names by checking against existing names and appending Greek
  /// letters when conflicts are detected.
  ///
  /// Algorithm:
  /// 1. Generate base class name based on suffix and name parameters
  /// 2. If root is true, clear the existing list of class names
  /// 3. Check if the generated name already exists with the same parent and created status
  /// 4. If a conflict exists, try to resolve by:
  ///    a. Using the base name if no conflict with created classes
  ///    b. Prepending Greek letters in order until a unique name is found
  /// 5. Add the new class name to the tracking list
  /// 6. Return the unique class name
  ///
  /// Parameters:
  /// - [listClassName]: List of existing ModelClassName objects for conflict checking
  /// - [suffix]: Suffix to append to the class name (e.g., 'Model', 'Entity')
  /// - [name]: Base name for the class
  /// - [root]: Whether this is a root-level class (clears existing list if true)
  /// - [created]: Whether this class is being created/generated
  /// - [parent]: Parent context or container of this class
  /// - [parentList]: Optional parent list context
  ///
  /// Returns: A unique class name string
  ///
  /// Example:
  /// ```dart
  /// final listClassName = <ModelClassName>[];
  ///
  /// // Generate a unique class name for a User model
  /// final className1 = ModelClassNameHelper.getClassName(
  ///   listClassName,
  ///   'Model',
  ///   'user',
  ///   true, // root
  ///   true, // created
  ///   'models'
  /// );
  /// print(className1); // UserModel
  ///
  /// // Generate another class name that might conflict
  /// final className2 = ModelClassNameHelper.getClassName(
  ///   listClassName,
  ///   'Model',
  ///   'user',
  ///   false, // not root
  ///   true, // created
  ///   'models'
  /// );
  /// print(className2); // AlphaUserModel
  /// ```
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
