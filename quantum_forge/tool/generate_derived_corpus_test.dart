// Bulk generator for derived reaction variants.
//
// Not a unit test: it is a `flutter test` entry point because the derivation
// engine imports `package:flutter/foundation.dart`, which plain `dart run`
// cannot load. It is skipped unless QF_DERIVED_OUT is set, so it never runs as
// part of the normal suite.
//
//   QF_DERIVED_OUT=/path/derived.jsonl QF_DERIVED_COUNT=80000 \
//     flutter test tool/generate_derived_corpus_test.dart
//
// Output is JSON Lines: one `ReactionTemplate.toJson()` map per line plus `id`.
// Ids are deterministic (parent id + substituents + site numbers), so
// re-uploading the same output is idempotent.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_template_generator.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

void main() {
  final outPath = Platform.environment['QF_DERIVED_OUT'];
  final target =
      int.tryParse(Platform.environment['QF_DERIVED_COUNT'] ?? '') ?? 80000;

  test('generate derived corpus', () async {
    // Grow the per-parent budget until enough distinct variants exist. Parents
    // with few spectator sites run dry early, so an even split undershoots.
    var perParent = (target / 8).ceil();
    var unique = <String, ReactionTemplate>{};
    for (var round = 0; round < 8; round++) {
      final batch = deriveTemplateVariants(
        kReactionTemplates,
        maxTotal: target * 4,
        perParentOverride: perParent,
      );
      unique = {for (final t in batch) t.id: t};
      stdout.writeln(
          'round $round: perParent=$perParent -> ${unique.length} unique variants');
      if (unique.length >= target) break;
      final grown = (perParent * 1.5).ceil();
      if (grown > kMaxVariantsPerParent) break;
      perParent = grown;
    }

    final chosen = unique.values.take(target).toList();
    final byParent = <String, int>{};
    for (final t in chosen) {
      byParent.update(t.derivedFrom ?? '?', (n) => n + 1, ifAbsent: () => 1);
    }
    stdout.writeln('writing ${chosen.length} variants');
    byParent.forEach((k, v) => stdout.writeln('  $v  $k'));

    final sink = File(outPath!).openWrite();
    for (final t in chosen) {
      sink.writeln(jsonEncode({'id': t.id, ...t.toJson()}));
    }
    await sink.flush();
    await sink.close();
    expect(chosen, isNotEmpty);
  }, skip: outPath == null ? 'set QF_DERIVED_OUT to run' : false, timeout: const Timeout(Duration(minutes: 30)));
}
