// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Lista claves de app_en.arb que no aparecen en ningún .dart de lib/ (excepto gen_l10n).
void main() {
  final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final keys = arb.keys
      .where((k) => !k.startsWith('@') && k != '@@locale')
      .toList()
    ..sort();

  final buffer = StringBuffer();
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.contains('gen_l10n')) continue;
    buffer.writeln(entity.readAsStringSync());
  }
  final allCode = buffer.toString();

  final unused = <String>[];
  for (final k in keys) {
    if (!allCode.contains(k)) unused.add(k);
  }

  print('Total keys: ${keys.length}');
  print('Unused: ${unused.length}');
  for (final k in unused) {
    print(k);
  }
}
