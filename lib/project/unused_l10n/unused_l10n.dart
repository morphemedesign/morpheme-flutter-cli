import 'dart:convert';
import 'dart:io';

import 'package:morpheme_cli/helper/helper.dart';

import '../../constants.dart';
import '../../dependency_manager.dart';

const lineNumber = 'line-number';

class UnusedL10nCommand extends Command {
  @override
  String get name => 'unused-l10n';

  @override
  String get description => 'Unused l10n all files .dart.';

  @override
  String get category => Constants.project;

  @override
  void run() async {
    print('Checking unused l10n');

    Set<String> notUsed = getTranslationTerms();

    await ModularHelper.runSequence((path) {
      final dartFiles = find('lib/**.dart', workingDirectory: path).toList();
      notUsed = findNotUsedArbTerms(notUsed, dartFiles);
      stdout.writeln('.');
    });

    print('Total unused: ${notUsed.length}');
    if (notUsed.isNotEmpty) print('---------------------------');
    for (final t in notUsed) {
      print(t);
    }

    StatusHelper.success('unused-l10n');
  }

  Set<String> getTranslationTerms() {
    final arbFiles = find('*.arb').toList();

    final arbTerms = <String>{};

    for (final path in arbFiles) {
      final content = File(path).readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in map.entries) {
        if (!entry.key.startsWith('@')) {
          arbTerms.add(entry.key);
        }
      }
    }
    return arbTerms;
  }

  Set<String> findNotUsedArbTerms(
    Set<String> arbTerms,
    List<String> pathFiles,
  ) {
    final unused = arbTerms.toSet();
    final length = pathFiles.length;
    for (final path in pathFiles) {
      stdout.write(
          '\r${((pathFiles.indexOf(path) + 1) / length * 100).toStringAsFixed(0)}%');
      final content = File(path).readAsStringSync();
      for (final arb in arbTerms) {
        if (content.contains(RegExp(
            'S(\\s+)?.(\\s+)?of(context)(\\s+)?.(\\s+)?$arb|context(\\s+)?.(\\s+)?s(\\s+)?.(\\s+)?$arb'))) {
          unused.remove(arb);
        }
      }
    }
    return unused;
  }
}
