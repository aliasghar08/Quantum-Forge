import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/library_search_tokenizer.dart';
import 'package:quantum_forge/features/reaction_library/data/dp_search_memo_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firestore Dual-Collection Federation Tests', () {
    test('Collection constants are strictly partitioned between /library and /medications', () {
      expect(FirestoreLibraryRepository.kLibraryCollection, equals('library'));
      expect(FirestoreLibraryRepository.kMedicationsCollection, equals('medications'));
    });

    test('ReactionTemplate distinguishes prescribed clinical medicines from standard reactions', () {
      final reaction = ReactionTemplate(
        id: 'rx_diels_alder',
        name: 'Diels-Alder Cycloaddition',
        iupacName: 'Cyclohexene synthesis',
        description: 'Pericyclic [4+2] reaction',
        category: ReactionCategory.pericyclic,
        reactantXyz: '1\nAtoms\nC 0 0 0',
        productXyz: '1\nAtoms\nC 1 0 0',
        referenceEa: 24.5,
        doi: '10.1002/anie.196800011',
        journalRef: 'Angew. Chem. Int. Ed.',
        tags: const ['Organic', 'Pericyclic'],
      );

      final medication = ReactionTemplate(
        id: 'rx_med_metoprolol',
        name: 'Metoprolol (ADRB1)',
        iupacName: '(2RS)-1-(isopropylamino)-3-[4-(2-methoxyethyl)phenoxy]propan-2-ol',
        description: 'Cardioselective beta-1 adrenergic receptor antagonist',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\nAtoms\nC 0 0 0',
        productXyz: '1\nAtoms\nC 1 0 0',
        referenceEa: 16.1,
        doi: '10.1016/j.cell.2021.03.008',
        journalRef: 'Cell',
        tags: const ['Pharm-D', 'MBBS', 'Cardiology', 'Beta-Blocker'],
        isDerived: false,
      );

      expect(reaction.id.startsWith('rx_med_'), isFalse);
      expect(medication.id.startsWith('rx_med_'), isTrue);
      expect(reaction.category, equals(ReactionCategory.pericyclic));
      expect(medication.category, equals(ReactionCategory.pharmaceutical));
    });

    test('buildFirestorePayload indexes clinical synonyms and curriculum facets for /medications', () {
      final medication = ReactionTemplate(
        id: 'rx_med_semaglutide',
        name: 'Semaglutide (GLP-1 Receptor)',
        iupacName: 'GLP-1 receptor agonist',
        description: 'Increases insulin secretion, slows gastric emptying',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\nAtoms\nC 0 0 0',
        productXyz: '1\nAtoms\nC 1 0 0',
        referenceEa: 14.2,
        doi: '10.1016/j.celrep.2021.109374',
        journalRef: 'Cell Reports',
        tags: const ['Pharm-D', 'MBBS', 'Ozempic', 'Wegovy', 'Rybelsus', 'GLP-1'],
        isDerived: false,
      );

      final payload = buildFirestorePayload(medication);
      expect(payload['search_tokens'], isA<List>());
      final tokens = (payload['search_tokens'] as List).cast<String>();

      // Assert bidirectional synonym and brand expansion
      expect(tokens.any((t) => t.contains('semaglutide') || t.contains('ozempic')), isTrue);
      expect(payload['is_pharm_d'], isTrue);
      expect(payload['is_mbbs'], isTrue);
      expect(payload['is_derived'], isFalse);
    });

    test('MedicinePharmacologyProfile correctly preserves 7-tab Clinical Dossier', () {
      final profile = MedicinePharmacologyProfile(
        id: 'rx_med_quetiapine',
        genericName: 'Quetiapine',
        iupacName: '2-[2-(4-dibenzo[b,f][1,4]thiazepin-11-ylpiperazin-1-yl)ethoxy]ethanol',
        brandNames: const ['Seroquel', 'Ketipinor'],
        targetDisciplines: const [TargetDiscipline.mbbs, TargetDiscipline.pharmD],
        specialty: PharmacologicalSpecialty.neurology,
        chemicalClass: 'Atypical Antipsychotic',
        engagementType: TargetEngagementType.covalentMetabolicReaction,
        therapeuticIndications: 'Bipolar disorder, Schizophrenia, Major Depressive Disorder',
        clinicalStaging: 'First-line atypical antipsychotic with low EPS risk',
        sourceAndOrigin: 'Discovered by AstraZeneca (ICI pharmaceuticals)',
        discoveryHistory: 'Synthesized to improve D2/5-HT2A balance',
        syntheticRoute: 'Condensation of dibenzothiazepinone with piperazine',
        molecularTarget: 'Dopamine D2 & 5-HT2A Receptors',
        pdbAccession: '6CM4',
        modeOfAction: 'Rapid dissociation from D2 receptors ("hit-and-run" kinetics)',
        downstreamSignaling: 'Blocks Gi/o-mediated adenylyl cyclase inhibition',
        absorptionAndDistribution: 'Rapid oral absorption, Tmax 1.5 hours',
        metabolismAndElimination: 'Hepatic CYP3A4 to norquetiapine',
        eliminationHalfLifeHours: 6.0,
        comparativeSpeciesPharmacology: 'Extrapolated across canine/feline veterinary applications',
        transitionStateDescription: 'CYP3A4 sulfoxidation and 7-hydroxylation',
        activationBarrierKcalMol: 17.4,
        catalyticResidues: 'CYP3A4 Cys-442, Fe-protoporphyrin IX',
        associatedReactionId: 'rx_med_quetiapine',
        contraindications: 'Severe CNS depression, bone marrow suppression',
        adverseEffectsAndToxicity: 'Sedation, weight gain, orthostatic hypotension, QTc prolongation',
        blackBoxWarning: 'Increased mortality in elderly patients with dementia-related psychosis',
        antidoteAndRescue: 'Supportive care, IV fluids, activated charcoal',
        clinicalGuidelines: const ['APA Practice Guideline for the Treatment of Patients with Schizophrenia'],
        primaryDoi: '10.1016/j.cell.2018.02.049',
        pubmedId: '29551270',
        highYieldExamPearls: const [
          'High 5-HT2A/D2 affinity ratio imparts minimal extrapyramidal symptoms',
          'Norquetiapine active metabolite drives norepinephrine transporter inhibition'
        ],
        verifiedSources: [
          DossierSourceProvenance(
            id: 'src_pdb_6cm4',
            title: 'Cryo-EM structure of human D2 dopamine receptor',
            journalOrSource: 'Cell',
            pdbId: '6CM4',
            url: 'https://www.rcsb.org/structure/6CM4',
            repositoryType: VerifiedRepositoryType.rcsbPdb,
            authorityTier: AuthorityTier.tier1RegulatoryPeerReviewed,
            publicationYear: 2018,
            isPeerReviewed: true,
            retrievedAt: DateTime(2026, 1, 1),
            semanticMatchHash: 'tok_6cm4',
          ),
        ],
      );

      final json = profile.toJson();
      expect(json['id'], equals('rx_med_quetiapine'));
      expect(json['genericName'], equals('Quetiapine'));
      expect(json['brandNames'], contains('Seroquel'));
      expect(json['pdbAccession'], equals('6CM4'));
      expect(json['verifiedSources'], isA<List>());
      expect((json['verifiedSources'] as List).length, equals(1));
    });

    test('Local persistence fallback preserves both custom reactions and custom medications', () {
      final customMed = ReactionTemplate(
        id: 'rx_med_custom_test_drug',
        name: 'Custom Test Drug',
        iupacName: 'Test IUPAC Name',
        description: 'Custom doctor-prescribed medication',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\nAtoms\nC 0 0 0',
        productXyz: '1\nAtoms\nC 1 0 0',
        referenceEa: 15.0,
        doi: '10.1000/182',
        journalRef: 'Clinical Research',
        tags: const ['Pharm-D', 'Test'],
      );

      FirestoreLibraryRepository.saveToLocalStorage(customMed);
      final loaded = FirestoreLibraryRepository.loadLocalCustomReactions();
      expect(loaded.any((r) => r.id == 'rx_med_custom_test_drug'), isTrue);
    });

    test('synthesizeStoichiometricXyz generates valid non-clashing mass-conserving 3D coordinates', () {
      final rXyz = synthesizeStoichiometricXyz(moleculeName: 'Semaglutide', state: 'reactant');
      final pXyz = synthesizeStoichiometricXyz(moleculeName: 'Semaglutide', state: 'product');

      final rAtoms = parseXyz(rXyz);
      final pAtoms = parseXyz(pXyz);

      expect(rAtoms.length, equals(6));
      expect(pAtoms.length, equals(6));

      // Should not throw
      validateMassConservation(rAtoms, pAtoms);
      validateStericClashes(rAtoms, 'Reactant');
      validateStericClashes(pAtoms, 'Product');
    });

    test('prepareMedicationPayloadIsolate validates coordinates and builds facets', () {
      final rXyz = synthesizeStoichiometricXyz(moleculeName: 'Metoprolol', state: 'reactant');
      final pXyz = synthesizeStoichiometricXyz(moleculeName: 'Metoprolol', state: 'product');

      final med = ReactionTemplate(
        id: 'rx_med_metoprolol_iso_test',
        name: 'Metoprolol Tartrate',
        iupacName: '1-(isopropylamino)-3-[4-(2-methoxyethyl)phenoxy]propan-2-ol',
        description: 'Cardioselective beta-1 blocker',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: rXyz,
        productXyz: pXyz,
        referenceEa: 14.5,
        doi: '10.1016/j.cell.2021.03.008',
        journalRef: 'Cell',
        tags: const ['Cardiology', 'Beta-Blocker'],
      );

      final payload = prepareMedicationPayloadIsolate(med.toJson()..['id'] = med.id);
      expect(payload['search_tokens'], isA<List>());
      expect(payload['is_pharm_d'], isTrue);
      expect(payload['reactantXyz'], equals(rXyz));
      expect(payload['productXyz'], equals(pXyz));
    });

    test('DPSearchMemoEngine injectAndInvalidate hydrates hot catalog and purges empty caches', () async {
      final engine = DPSearchMemoEngine();
      final med = ReactionTemplate(
        id: 'rx_med_instant_test',
        name: 'InstantTestDrug (GLP-1)',
        iupacName: 'Instant Drug',
        description: 'Test drug for sub-millisecond cache hydration',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: synthesizeStoichiometricXyz(moleculeName: 'InstantDrug', state: 'reactant'),
        productXyz: synthesizeStoichiometricXyz(moleculeName: 'InstantDrug', state: 'product'),
        referenceEa: 12.0,
        doi: '10.1000/182',
        journalRef: 'Lancet',
        tags: const ['Pharm-D'],
      );

      // Pre-seed an empty node for stale query
      final staleKey = SearchStateKey(query: 'stale_query_term', category: ReactionCategory.pharmaceutical);
      engine.l1Table.put(staleKey, MemoizedSearchNode(items: const [], isExhaustive: true, cachedAt: DateTime.now()));

      // Inject
      engine.injectAndInvalidate(med);

      // Stale empty node was purged
      expect(engine.l1Table.get(staleKey), isNull);

      // L1 exact hit node is primed for immediate O(1) retrieval
      final exactKey = SearchStateKey(query: med.name, category: med.category);
      final hit = engine.l1Table.get(exactKey);
      expect(hit, isNotNull);
      expect(hit!.items.length, equals(1));
      expect(hit.items.first.id, equals('rx_med_instant_test'));

      // Sub-millisecond search returns the injected medication
      final searchResult = await engine.search(query: 'InstantTestDrug', category: ReactionCategory.pharmaceutical);
      expect(searchResult.items.any((t) => t.id == 'rx_med_instant_test'), isTrue);
    });
  });
}
