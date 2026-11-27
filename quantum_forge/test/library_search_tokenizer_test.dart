import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/library_search_tokenizer.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

void main() {
  group('Library Search Tokenizer & Soundex Tests', () {
    test('Soundex typo matching for quetiapine', () {
      final typoCode = computeSoundex('qutiapene');
      final exactCode = computeSoundex('quetiapine');
      expect(typoCode, equals('phx_Q315'));
      expect(exactCode, equals('phx_Q315'));
      expect(typoCode, equals(exactCode));
    });

    test('Soundex for paracetamol', () {
      expect(computeSoundex('paracetamol'), equals('phx_P623'));
    });

    test('Query tokenization attaches phonetic keys and synonyms', () {
      final tokens = tokenizeQuery('qutiapene');
      expect(tokens, contains('qutiapene'));
      expect(tokens, contains('phx_Q315'));
    });

    test('Query tokenization expands clinical synonyms', () {
      final tokens = tokenizeQuery('acetaminophen');
      expect(tokens, contains('acetaminophen'));
      expect(tokens, contains('paracetamol'));
      expect(tokens.length, lessThanOrEqualTo(10));
    });

    test('Edge n-grams generation', () {
      final ngrams = generateEdgeNgrams('statin', minLen: 3, maxLen: 6);
      expect(ngrams, equals(['sta', 'stat', 'stati', 'statin']));
    });
  });

  group('BM25 + Provenance Client Re-Ranking Tests', () {
    test('Exact prefix and verified DOI papers rank above synthetic variants', () {
      const verifiedPaper = ReactionTemplate(
        id: 'rx_med_paracetamol_1',
        name: 'Paracetamol Bioactivation to NAPQI',
        iupacName: 'N-(4-hydroxyphenyl)acetamide',
        description: 'Authentic clinical paper on hepatotoxicity',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 14.5,
        doi: '10.1056/NEJMoa12345',
        journalRef: 'New England Journal of Medicine',
        isDerived: false,
      );

      const syntheticVariant = ReactionTemplate(
        id: 'rx_synth_methyl_paracetamol',
        name: 'Methyl Derivative — Paracetamol Bioactivation',
        iupacName: 'Methyl analog',
        description: 'Systematic 3D combinatorial variant',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 14.8,
        doi: '',
        journalRef: '',
        isDerived: true,
      );

      final candidates = [syntheticVariant, verifiedPaper];
      final ranked = rankSearchResults(candidates, 'paracetamol');

      expect(ranked.first.id, equals(verifiedPaper.id));
      expect(ranked.first.isDerived, isFalse);
    });
  });

  group('ReactionTemplate.toFirestore() Integration', () {
    test('builds enriched payload with search_tokens and facets', () {
      const template = ReactionTemplate(
        id: 'rx_med_atorvastatin',
        name: 'Atorvastatin HMG-CoA Reductase Inhibition',
        iupacName: 'Atorvastatin calcium',
        description: 'Lipid-lowering statin mechanism for MBBS and Pharm-D students',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 12.0,
        doi: '10.1016/S0140-6736',
        journalRef: 'Lancet',
        tags: ['MBBS', 'Cardiology', 'Pharm-D', 'Lipidology'],
      );

      final firestorePayload = template.toFirestore();
      expect(firestorePayload['search_tokens'], isA<List>());
      final tokens = List<String>.from(firestorePayload['search_tokens'] as List);
      expect(tokens, contains('atorvastatin'));
      expect(tokens, contains('hmg'));
      expect(tokens, contains('statin')); // synonym
      expect(firestorePayload['name_lower'], equals('atorvastatin hmg-coa reductase inhibition'));
      expect(firestorePayload['is_mbbs'], isTrue);
      expect(firestorePayload['is_pharm_d'], isTrue);
      expect(firestorePayload['is_dvm'], isFalse);
      expect(firestorePayload['is_polymer'], isFalse);
      expect(firestorePayload['specialty'], equals('cardiology'));
    });
  });
}
