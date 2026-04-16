// Comprueba paridad de claves entre app_en.arb y app_es.arb, ejecuta `flutter gen-l10n`
// y avisa si hay mensajes sin traducir (untranslated_report.json).
//
// Uso (desde la raíz del paquete): dart run tool/verify_l10n.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const _enArb = 'lib/l10n/app_en.arb';
const _esArb = 'lib/l10n/app_es.arb';
const _untranslatedReport = 'lib/l10n/untranslated_report.json';

Set<String> _messageKeys(Map<String, dynamic> arb) {
  final keys = <String>{};
  for (final e in arb.entries) {
    final k = e.key;
    if (k == '@@locale') continue;
    if (k.startsWith('@')) continue;
    keys.add(k);
  }
  return keys;
}

Future<void> main() async {
  final root = Directory.current.path;
  stdout.writeln('[verify_l10n] Paquete: $root');

  final enFile = File(_enArb);
  final esFile = File(_esArb);
  if (!enFile.existsSync() || !esFile.existsSync()) {
    stderr.writeln('[verify_l10n] ERROR: No se encontró $_enArb o $_esArb (ejecutar desde texi_passenger_app/).');
    exitCode = 1;
    return;
  }

  Map<String, dynamic> decodeArb(File f) {
    final raw = f.readAsStringSync();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('ARB inválido: ${f.path}');
    }
    return decoded;
  }

  final enKeys = _messageKeys(decodeArb(enFile));
  final esKeys = _messageKeys(decodeArb(esFile));

  final onlyEn = enKeys.difference(esKeys).toList()..sort();
  final onlyEs = esKeys.difference(enKeys).toList()..sort();

  if (onlyEn.isNotEmpty || onlyEs.isNotEmpty) {
    stderr.writeln('[verify_l10n] ERROR: Claves ARB desalineadas entre template (en) y es.');
    if (onlyEn.isNotEmpty) {
      stderr.writeln('  Solo en app_en.arb (${onlyEn.length}): ${onlyEn.join(', ')}');
    }
    if (onlyEs.isNotEmpty) {
      stderr.writeln('  Solo en app_es.arb (${onlyEs.length}): ${onlyEs.join(', ')}');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('[verify_l10n] OK: ${enKeys.length} claves coincidentes en app_en.arb / app_es.arb.');

  final r = await Process.run(
    'flutter',
    const ['gen-l10n'],
    workingDirectory: root,
    runInShell: true,
  );
  stdout.write(r.stdout);
  stderr.write(r.stderr);

  if (r.exitCode != 0) {
    stderr.writeln('[verify_l10n] ERROR: flutter gen-l10n salió con código ${r.exitCode}.');
    exitCode = r.exitCode;
    return;
  }

  final untranslated = File(_untranslatedReport);
  if (untranslated.existsSync()) {
    final text = untranslated.readAsStringSync().trim();
    if (text.isEmpty) {
      stdout.writeln('[verify_l10n] Sin archivo de no traducidos o vacío.');
      return;
    }
    try {
      final map = jsonDecode(text);
      if (map is Map && map.isEmpty) {
        stdout.writeln('[verify_l10n] OK: sin entradas en untranslated_report.json.');
        return;
      }
      stderr.writeln('[verify_l10n] AVISO: Hay mensajes sin traducir (ver $_untranslatedReport):');
      const encoder = JsonEncoder.withIndent('  ');
      stderr.writeln(encoder.convert(map));
      exitCode = 2;
    } catch (_) {
      stderr.writeln('[verify_l10n] AVISO: $_untranslatedReport no es JSON vacío/legible:');
      stderr.writeln(text);
      exitCode = 2;
    }
  } else {
    stdout.writeln('[verify_l10n] OK: no se generó $_untranslatedReport (todo traducido o sin otros locales).');
  }
}
