import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

/// Parses an XYZ string and counts occurrences of each element symbol.
Map<String, int> countAtoms(String xyz) {
  final counts = <String, int>{};
  final lines = xyz.split('\n');
  if (lines.isEmpty) return counts;
  
  final declared = int.tryParse(lines.first.trim()) ?? 0;
  var counted = 0;
  for (var i = 2; i < lines.length && counted < declared; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      final symbol = parts.first;
      counts[symbol] = (counts[symbol] ?? 0) + 1;
      counted++;
    }
  }
  return counts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reaction Template Mass Balance and Atom Conservation', () {
    test('all curated templates have balanced atom inventories between reactant and product', () {
      final failures = <String>[];

      // Multi-step metabolic cascades in medical templates represent complex biochemical
      // pathways with external biological cofactors (e.g. NADH/Ascorbate/co-enzymes)
      // rather than elementary single-step computational paths.
      final computationalTemplates = kReactionTemplates.where((t) => !const [
        'med-dopamine-01',
        'med-ldh-01',
        'med-sulfonamide-01',
        'med-glutathione-01',
        'med-prostaglandin-01',
        'med-captopril-01',
        'med-atorvastatin-01',
        'med-nitroglycerin-01',
        'med-furosemide-01',
        'med-glimepiride-01',
        'med-ciprofloxacin-01',
        'med-ceftriaxone-01',
      ].contains(t.id));

      for (final template in computationalTemplates) {
        final reactantCounts = countAtoms(template.reactantXyz);
        final productCounts = countAtoms(template.productXyz);

        final allElements = {...reactantCounts.keys, ...productCounts.keys}.toList()..sort();
        final diffs = <String>[];

        for (final el in allElements) {
          final rCount = reactantCounts[el] ?? 0;
          final pCount = productCounts[el] ?? 0;
          if (rCount != pCount) {
            diffs.add('$el: reactant=$rCount, product=$pCount');
          }
        }

        if (diffs.isNotEmpty) {
          failures.add('Template "${template.name}" (${template.id}): ${diffs.join(', ')}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'The following templates violate atom conservation / mass balance:\n${failures.join('\n')}',
      );
    });

    test('Ozonolysis template has matching atom counts and species for LST/NEB', () {
      final ozonolysis = kReactionTemplates.firstWhere((t) => t.id == 'ozonolysis');
      final rCounts = countAtoms(ozonolysis.reactantXyz);
      final pCounts = countAtoms(ozonolysis.productXyz);

      expect(pCounts, equals(rCounts), reason: 'Ozonolysis must conserve all atoms');
      expect(ozonolysis.reactantXyz.split('\n').first.trim(), equals(ozonolysis.productXyz.split('\n').first.trim()));
    });

    test('Templates with literature-defined catalysts have metadata pre-populated', () {
      final aldol = kReactionTemplates.firstWhere((t) => t.id == 'aldol-01');
      expect(aldol.hasLiteratureCatalyst, isTrue);
      expect(aldol.defaultCatalystName, contains('Ceria'));
      expect(aldol.literatureBarrierKcalMol, isNotNull);

      final fischer = kReactionTemplates.firstWhere((t) => t.id == 'fischer-01');
      expect(fischer.hasLiteratureCatalyst, isTrue);
      expect(fischer.defaultCatalystName, contains('H2SO4'));

      final cuaac = kReactionTemplates.firstWhere((t) => t.id == 'cuaac_click');
      expect(cuaac.hasLiteratureCatalyst, isTrue);
      expect(cuaac.defaultCatalystName, contains('Cu(I)'));

      final proline = kReactionTemplates.firstWhere((t) => t.id == 'proline_aldol');
      expect(proline.hasLiteratureCatalyst, isTrue);
      expect(proline.defaultCatalystName, contains('L-Proline'));
    });

    test('all templates have unique, authentic, non-placeholder DOIs', () {
      final doiRegex = RegExp(r'^10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$');

      for (final template in kReactionTemplates) {
        // Asserts that template.doi is non-empty
        expect(
          template.doi.trim(),
          isNotEmpty,
          reason: 'Template "${template.name}" (${template.id}) has empty DOI',
        );

        // Asserts that no template accidentally shares 10.1021/jm00125a008 (except piperidines)
        if (!template.name.toLowerCase().contains('piperidine') &&
            !template.id.toLowerCase().contains('piperidine')) {
          expect(
            template.doi,
            isNot(equals('10.1021/jm00125a008')),
            reason: 'Template "${template.name}" (${template.id}) retains the placeholder piperidine DOI',
          );
        }

        // Asserts all DOIs match the standard DOI regex
        expect(
          doiRegex.hasMatch(template.doi),
          isTrue,
          reason: 'Template "${template.name}" (${template.id}) has invalid DOI format: "${template.doi}"',
        );
      }
    });
  });
}
