import 'dart:convert';

import 'package:collection/collection.dart';

/// Merges two ARB (Application Resource Bundle) files.
///
/// This function includes the novel keys of [arb2Contents] in the [arb1Contents]
/// and returns the result of the merge. In case of discrepancies of
/// the values for the same key, the [arb2Contents] will prevail.
///
/// In a nutshell [arb1Contents] <-merge-- [arb2Contents]
///
/// Parameters:
/// - [arb1Contents]: The base ARB file contents as a JSON string
/// - [arb2Contents]: The ARB file contents to merge into the base as a JSON string
///
/// Returns: Merged ARB file contents as a JSON string
///
/// Example:
/// ```dart
/// final baseArb = '{"appName": "My App", "welcomeMessage": "Welcome!"}';
/// final newArb = '{"appName": "New App Name", "newFeature": "New Feature"}';
/// final merged = mergeARBs(baseArb, newArb);
/// // Result: '{"appName": "New App Name", "welcomeMessage": "Welcome!", "newFeature": "New Feature"}'
/// ```
String mergeARBs(String arb1Contents, String arb2Contents) {
  Map<String, dynamic> ret = json.decode(arb1Contents);
  Map<String, dynamic> json2 = json.decode(arb2Contents);
  for (var key in json2.keys) {
    ret[key] = json2[key];
  }
  return json.encode(ret);
}

/// Sorts the .arb formatted String in alphabetical order of the keys.
///
/// Sorts the .arb formatted String [arbContents] in alphabetical order
/// of the keys, with the @key portion added below it's respective key.
///
/// Optionally you can provide a [compareFunction] for customizing the sorting.
/// For simplicity sake there are common sorting features you can use when not
/// defining the former parameter.
///
/// Parameters:
/// - [arbContents]: The ARB file contents as a JSON string to sort
/// - [compareFunction]: Optional custom comparison function for sorting keys
/// - [caseInsensitive]: Whether to perform case-insensitive sorting (default: false)
/// - [naturalOrdering]: Whether to use natural ordering (e.g., "2" before "10") (default: false)
/// - [descendingOrdering]: Whether to sort in descending order (default: false)
///
/// Returns: Sorted ARB file contents as a JSON string
///
/// Example:
/// ```dart
/// final arbContent = '{"zebra": "Zebra", "apple": "Apple", "banana": "Banana"}';
/// final sorted = sortARB(arbContent);
/// // Result: '{"apple": "Apple", "banana": "Banana", "zebra": "Zebra"}'
///
/// // Case insensitive sorting
/// final sortedCaseInsensitive = sortARB(arbContent, caseInsensitive: true);
///
/// // Natural ordering (useful for numbered keys)
/// final sortedNatural = sortARB('{"item2": "Item 2", "item10": "Item 10", "item1": "Item 1"}', naturalOrdering: true);
/// // Result: '{"item1": "Item 1", "item2": "Item 2", "item10": "Item 10"}'
/// ```
String sortARB(String arbContents,
    {int Function(String, String)? compareFunction,
    bool caseInsensitive = false,
    bool naturalOrdering = false,
    bool descendingOrdering = false}) {
  compareFunction ??= (a, b) =>
      _commonSorts(a, b, caseInsensitive, naturalOrdering, descendingOrdering);

  final sorted = <String, dynamic>{};
  final Map<String, dynamic> contents = json.decode(arbContents);

  final keys = contents.keys.where((key) => !key.startsWith('@')).toList()
    ..sort(compareFunction);

  // Add at the beginning the [Global Attributes] of the .arb original file, if any
  // [link]: https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification#global-attributes
  contents.keys.where((key) => key.startsWith('@@')).toList()
    ..sort(compareFunction)
    ..forEach((key) {
      sorted[key] = contents[key];
    });
  for (final key in keys) {
    sorted[key] = contents[key];
    if (contents.containsKey('@$key')) {
      sorted['@$key'] = contents['@$key'];
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(sorted);
}

/// Common sorting function for ARB keys.
///
/// Internal helper function that implements common sorting algorithms
/// for ARB file keys based on the provided parameters.
///
/// Parameters:
/// - [a]: First key to compare
/// - [b]: Second key to compare
/// - [isCaseInsensitive]: Whether to perform case-insensitive comparison
/// - [isNaturalOrdering]: Whether to use natural ordering
/// - [isDescending]: Whether to reverse the sorting order
///
/// Returns: Comparison result (-1, 0, or 1)
int _commonSorts(String a, String b, bool isCaseInsensitive,
    bool isNaturalOrdering, bool isDescending) {
  var ascending = 1;
  if (isDescending) {
    ascending = -1;
  }
  if (isCaseInsensitive) {
    a = a.toLowerCase();
    b = b.toLowerCase();
  }

  if (isNaturalOrdering) {
    return ascending * compareNatural(a, b);
  } else {
    return ascending * a.compareTo(b);
  }
}