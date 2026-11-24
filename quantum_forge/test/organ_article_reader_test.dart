// ============================================================================
// Organ Article Reader & Multi-Source Literature Service Test Suite
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/organ_literature_service.dart';
import 'package:quantum_forge/features/organ_articles/presentation/organ_structure_article_screen.dart';

void main() {
  group('OrganLiteratureService Unit Tests', () {
    test('Curated monographs resolve correctly for major cardiac landmarks', () {
      final lmca = OrganLiteratureService.getCuratedMonograph(
        structureId: 'lmca',
        structureName: 'Left Main Coronary Artery',
        organSystem: 'Cardiovascular',
      );
      expect(lmca.structureId, 'lmca');
      expect(lmca.latinName, contains('Arteria coronaria'));
      expect(lmca.curatedReferences, isNotEmpty);
      expect(lmca.grossMicroAnatomy, contains('LMCA'));
      expect(lmca.biophysicsHemodynamics, contains('diastolic'));
      expect(lmca.pathophysiologyClinical, contains('EXCEL'));
      expect(lmca.pharmacologicalInterventions, contains('Percutaneous Coronary Intervention'));

      final lad = OrganLiteratureService.getCuratedMonograph(
        structureId: 'lad',
        structureName: 'Left Anterior Descending Artery',
        organSystem: 'Cardiovascular',
      );
      expect(lad.structureId, 'lad');
      expect(lad.curatedReferences.any((r) => r.pmid == '19144937'), isTrue);

      final avNode = OrganLiteratureService.getCuratedMonograph(
        structureId: 'av_node',
        structureName: 'AV Node',
        organSystem: 'Cardiovascular',
      );
      expect(avNode.structureId, 'av_node');
      expect(avNode.grossMicroAnatomy, contains('Koch triangle'));
    });

    test('Curated monographs resolve correctly for neuro and nephro structures', () {
      final cow = OrganLiteratureService.getCuratedMonograph(
        structureId: 'circle_of_willis',
        structureName: 'Circle of Willis',
        organSystem: 'Cerebrovascular / Neuro',
      );
      expect(cow.structureId, 'circle_of_willis');
      expect(cow.pathophysiologyClinical, contains('aneurysms'));

      final mca = OrganLiteratureService.getCuratedMonograph(
        structureId: 'mca',
        structureName: 'Middle Cerebral Artery',
        organSystem: 'Cerebrovascular / Neuro',
      );
      expect(mca.structureId, 'mca');
      expect(mca.pharmacologicalInterventions, contains('Thrombectomy'));

      final glomerulus = OrganLiteratureService.getCuratedMonograph(
        structureId: 'glomerulus',
        structureName: 'Glomerulus',
        organSystem: 'Renal / Nephrology',
      );
      expect(glomerulus.structureId, 'glomerulus');
      expect(glomerulus.biophysicsHemodynamics, contains('ultrafiltration'));

      final podocyte = OrganLiteratureService.getCuratedMonograph(
        structureId: 'podocyte',
        structureName: 'Podocyte',
        organSystem: 'Renal / Nephrology',
      );
      expect(podocyte.structureId, 'podocyte');
      expect(podocyte.grossMicroAnatomy, contains('pedicels'));
      expect(podocyte.biophysicsHemodynamics, contains('nephrin'));
    });

    test('Dynamic fallback monograph generated for unknown landmark ID', () {
      final custom = OrganLiteratureService.getCuratedMonograph(
        structureId: 'unknown_artery_99',
        structureName: 'Novel Anastomotic Branch',
        organSystem: 'Microvascular',
        bloodSupply: 'Arcuate arcade',
        contextPearl: 'Susceptible to micro-embolism',
      );
      expect(custom.structureId, 'unknown_artery_99');
      expect(custom.structureName, 'Novel Anastomotic Branch');
      expect(custom.grossMicroAnatomy, contains('compartment'));
      expect(custom.biophysicsHemodynamics, contains('Susceptible to micro-embolism'));
      expect(custom.curatedReferences, isNotEmpty);
    });

    test('VerifiedResearchReference targetUrl and citation logic', () {
      const doiRef = VerifiedResearchReference(
        title: 'Coronary Physiology and FFR Guidance',
        authors: ['De Bruyne B', 'Pijls NH'],
        journal: 'N Engl J Med',
        year: 2012,
        source: LiteratureSource.crossref,
        doi: '10.1056/NEJMoa1205361',
      );
      expect(doiRef.targetUrl, 'https://doi.org/10.1056/NEJMoa1205361');
      expect(doiRef.citation, 'De Bruyne B & Pijls NH (2012), N Engl J Med.');

      const pmidRef = VerifiedResearchReference(
        title: 'Long-term Outcomes of TAVR',
        authors: ['Leon MB', 'Smith CR', 'Mack MJ'],
        journal: 'The Lancet',
        year: 2016,
        source: LiteratureSource.pubmed,
        pmid: '27040439',
      );
      expect(pmidRef.targetUrl, 'https://pubmed.ncbi.nlm.nih.gov/27040439/');
      expect(pmidRef.citation, 'Leon MB et al. (2016), The Lancet.');

      const webRef = VerifiedResearchReference(
        title: 'Open Access Research',
        source: LiteratureSource.curated,
        webUrl: 'https://example.com/article',
      );
      expect(webRef.targetUrl, 'https://example.com/article');
    });

    test('OrganArticleResult deduplicates references accurately', () {
      final monograph = OrganLiteratureService.getCuratedMonograph(
        structureId: 'lmca',
        structureName: 'LMCA',
        organSystem: 'Cardiovascular',
      );

      final liveDuplicate = VerifiedResearchReference(
        title: 'Duplicate Title',
        source: LiteratureSource.crossref,
        doi: '10.1056/nejmoa1610227', // Same as EXCEL in curated
      );

      final liveUnique = const VerifiedResearchReference(
        title: 'Unique 2026 Trial on Bioresorbable Stents',
        source: LiteratureSource.openalex,
        doi: '10.1016/j.jacc.2026.01.001',
      );

      final result = OrganArticleResult(
        monograph: monograph,
        liveReferences: [liveDuplicate, liveUnique],
      );

      final all = result.allReferences;
      expect(all.length, monograph.curatedReferences.length + 1);
      expect(all.any((r) => r.doi == '10.1016/j.jacc.2026.01.001'), isTrue);
    });
  });

  group('OrganStructureArticleScreen Widget Tests', () {
    testWidgets('Renders all monograph cards, SaMD shield, and research references', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrganStructureArticleScreen(
            structureId: 'lmca',
            structureName: 'Left Main Coronary Artery (LMCA)',
            organSystem: 'Cardiovascular',
            latinName: 'Arteria coronaria sinistra (truncus)',
            bloodSupply: 'Left posterior aortic sinus',
            innervation: 'Cardiac autonomic plexus',
            contextPearl: 'Highest ischemic hazard ratio in interventional cardiology',
          ),
        ),
      );

      await tester.pump();

      // Verify Title & Latin Name
      expect(find.text('Left Main Coronary Artery (LMCA)'), findsWidgets);
      expect(find.text('Arteria coronaria sinistra (truncus)'), findsOneWidget);
      expect(find.text('CARDIOVASCULAR'), findsWidgets);

      // Verify Vascular supply pill
      expect(find.textContaining('left posterior aortic sinus'), findsOneWidget);

      // Verify Provenance Badges
      expect(find.text('PubMed (NCBI)'), findsWidgets);
      expect(find.text('CrossRef'), findsWidgets);
      expect(find.text('OpenAlex'), findsWidgets);
      expect(find.text('Europe PMC'), findsWidgets);

      // Verify All 4 Monograph Cards
      expect(find.text('1. Gross & Micro-Anatomical Architecture'), findsOneWidget);
      expect(find.text('2. Physiology, Biophysics & Hemodynamics'), findsOneWidget);
      expect(find.text('3. Pathophysiology & Clinical Correlations'), findsOneWidget);
      expect(find.text('4. Pharmacological & Interventional Targets'), findsOneWidget);

      // Verify Permanent SaMD 7-Pillar Legal Shield Banner
      expect(find.textContaining('Educational & Research Simulation Only'), findsWidgets);
      expect(find.textContaining('SaMD'), findsWidgets);

      // Verify Peer-Reviewed Literature Section & Article CTA
      expect(find.text('Peer-Reviewed Literature & Landmark Studies'), findsOneWidget);
      expect(find.byKey(const Key('organ_article_back_button')), findsOneWidget);
    });
  });
}
