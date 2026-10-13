import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/polymer_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

void main() {
  group('Polymer Reaction Templates Library', () {
    test('contains all canonical polymer chemistry reaction templates', () {
      expect(kPolymerReactionTemplates.length, equals(18));
      expect(
        kReactionTemplates.where((t) => t.category == ReactionCategory.polymer).length,
        equals(18),
      );
    });

    test('each polymer reaction template has complete metadata and valid XYZ geometry', () {
      for (final t in kPolymerReactionTemplates) {
        expect(t.category, equals(ReactionCategory.polymer), reason: '${t.id} category');
        expect(t.name.isNotEmpty, isTrue, reason: '${t.id} name');
        expect(t.iupacName.isNotEmpty, isTrue, reason: '${t.id} iupacName');
        expect(t.description.isNotEmpty, isTrue, reason: '${t.id} description');
        expect(t.referenceEa, greaterThan(0.0), reason: '${t.id} referenceEa');
        expect(t.doi.isNotEmpty, isTrue, reason: '${t.id} doi');
        expect(t.journalRef.isNotEmpty, isTrue, reason: '${t.id} journalRef');
        expect(t.tags.isNotEmpty, isTrue, reason: '${t.id} tags');

        // Check Reactant XYZ
        final rLines = t.reactantXyz.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
        expect(rLines.length, greaterThanOrEqualTo(3), reason: '${t.id} reactant line count');
        final rCount = int.parse(rLines.first.trim());
        expect(rLines.length - 2, equals(rCount), reason: '${t.id} reactant declared vs actual atom lines');

        // Check Product XYZ
        final pLines = t.productXyz.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
        expect(pLines.length, greaterThanOrEqualTo(3), reason: '${t.id} product line count');
        final pCount = int.parse(pLines.first.trim());
        expect(pLines.length - 2, equals(pCount), reason: '${t.id} product declared vs actual atom lines');

        // Reactant and product must have equal atom counts
        expect(rCount, equals(pCount), reason: '${t.id} reactant count == product count');
      }
    });

    test('key milestone discoveries are present in polymer templates', () {
      final ids = kPolymerReactionTemplates.map((t) => t.id).toSet();
      expect(ids.contains('poly-ziegler-natta-01'), isTrue);
      expect(ids.contains('poly-romp-grubbs-02'), isTrue);
      expect(ids.contains('poly-atrp-matyjaszewski-03'), isTrue);
      expect(ids.contains('poly-raft-csiro-04'), isTrue);
      expect(ids.contains('poly-nmp-tempo-05'), isTrue);
      expect(ids.contains('poly-pvc-free-radical-06'), isTrue);
      expect(ids.contains('poly-rop-caprolactone-07'), isTrue);
      expect(ids.contains('poly-nylon-carothers-08'), isTrue);
      expect(ids.contains('poly-polyurethane-bayer-09'), isTrue);
      expect(ids.contains('poly-pet-whinfield-10'), isTrue);
      expect(ids.contains('poly-anionic-szwarc-11'), isTrue);
      expect(ids.contains('poly-cationic-isobutylene-12'), isTrue);
      expect(ids.contains('poly-bakelite-baekeland-13'), isTrue);
      expect(ids.contains('poly-polypyrrole-conductive-14'), isTrue);
      expect(ids.contains('poly-epoxy-amine-crosslink-15'), isTrue);
      expect(ids.contains('poly-pla-lactide-rop-16'), isTrue);
      expect(ids.contains('poly-gtp-webster-17'), isTrue);
      expect(ids.contains('poly-admet-wagener-18'), isTrue);
    });

    test('ReactionCardWidget handles ReactionCategory.polymer', () {
      expect(
        ReactionCardWidget.categoryColor(ReactionCategory.polymer),
        equals(const Color(0xFFEC4899)),
      );
      expect(
        ReactionCardWidget.categoryLabel(ReactionCategory.polymer),
        equals('Polymer Chemistry'),
      );
    });
  });
}
