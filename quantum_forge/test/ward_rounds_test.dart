// ============================================================================
// WardRounds 3D: Undifferentiated ER/ICU Clinical Reasoning & POCUS Tests
// ----------------------------------------------------------------------------
// Comprehensive Unit & Widget Test Suite verifying:
// 1. WardRoundsEngine lifecycle & multi-organ physiological coupling
// 2. All 8 High-Yield Undifferentiated Bedside Cases
// 3. Bedside POCUS 5-window simulator, B-mode/M-mode, & landmark tags
// 4. Differential Diagnosis (DDx) ranking & clinical evidence tagging
// 5. Emergency order placement & Socratic Attending safety interception
// 6. 100-point encounter scoring & 6-axis Student Mastery Radar
// 7. WardRoundsScreen widget rendering, amber SaMD banner, & responsive layout
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/ward/data/ward_rounds_engine.dart';
import 'package:quantum_forge/screens/ward_rounds_screen.dart';

Widget buildTestHarness({required Widget child}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: child,
  );
}

void main() {
  group('WardRoundsEngine Unit Tests', () {
    late WardRoundsEngine engine;

    setUp(() {
      engine = WardRoundsEngine.instance;
      engine.loadCase(0);
    });

    tearDown(() {
      engine.stopTimer();
    });

    test('initializes with Case 1 (Cardiac Tamponade) and correct baseline parameters', () {
      expect(engine.currentCaseIndex, 0);
      expect(engine.activeCase.caseNumber, 1);
      expect(engine.activeCase.triageId, 'UNDIFF-ER-001');
      expect(engine.activeCase.hiddenDiagnosis, contains('Cardiac Tamponade'));
      expect(engine.activeCase.primaryOrganDomain, 'Cardiovascular');
      expect(engine.isTimerRunning, isTrue);
      expect(engine.isCaseSubmitted, isFalse);
      expect(engine.isPatientStabilized, isFalse);
      expect(engine.placedOrders, isEmpty);
      expect(engine.top3Ddx, [null, null, null]);
    });

    test('all 8 cases are structurally valid with complete diagnostic profiles', () {
      expect(WardRoundsEngine.allCases.length, 8);

      for (int i = 0; i < 8; i++) {
        final c = WardRoundsEngine.allCases[i];
        expect(c.caseNumber, i + 1);
        expect(c.triageId, isNotEmpty);
        expect(c.demographic, isNotEmpty);
        expect(c.chiefComplaint, isNotEmpty);
        expect(c.triageStory, isNotEmpty);
        expect(c.physicalExamSummary, isNotEmpty);
        expect(c.hiddenDiagnosis, isNotEmpty);
        expect(c.primaryOrganDomain, isNotEmpty);
        expect(c.usmlePearl, isNotEmpty);
        expect(c.remediationRoute, startsWith('/'));

        // POCUS findings checks
        expect(c.pocusFindings.subxiphoidDescription, isNotEmpty);
        expect(c.pocusFindings.plaxDescription, isNotEmpty);
        expect(c.pocusFindings.ivcDescription, isNotEmpty);
        expect(c.pocusFindings.lungDescription, isNotEmpty);
        expect(c.pocusFindings.morisonDescription, isNotEmpty);

        // DDx checks
        expect(c.differentialOptions.length, greaterThanOrEqualTo(5));
        expect(c.correctDdxRanking.length, 3);
        expect(c.mandatoryOrderIds, isNotEmpty);
        expect(c.contraindicationMap, isNotEmpty);
      }
    });

    test('case loading updates multi-organ coupled vitals correctly', () {
      // Load Case 3: Inferior STEMI with RV Infarction (Bradycardia, Hypotension)
      engine.loadCase(2);
      expect(engine.activeCase.caseNumber, 3);
      expect(engine.multiOrganState.cardiacVitals.heartRateBpm, 52.0);
      expect(engine.multiOrganState.cardiacVitals.systolicBp, 82.0);

      // Load Case 6: Ruptured ACom Aneurysm with Cushing Triad (ICP 34 triggers reflex bradycardia HR 46, SBP 205)
      engine.loadCase(5);
      expect(engine.activeCase.caseNumber, 6);
      expect(engine.multiOrganState.cardiacVitals.heartRateBpm, 46.0);
      expect(engine.multiOrganState.cardiacVitals.systolicBp, 205.0);
      expect(engine.multiOrganState.neuroVitals.icpMmHg, 34.0);
    });

    test('POCUS window, ultrasound mode, and landmark tags toggle cleanly', () {
      expect(engine.activePocusWindow, WardPocusWindow.subxiphoid4Chamber);
      engine.setPocusWindow(WardPocusWindow.ivcLongitudinal);
      expect(engine.activePocusWindow, WardPocusWindow.ivcLongitudinal);

      expect(engine.ultrasoundMode, PocusUltrasoundMode.bMode2D);
      engine.setUltrasoundMode(PocusUltrasoundMode.mModeMotion);
      expect(engine.ultrasoundMode, PocusUltrasoundMode.mModeMotion);

      expect(engine.showLandmarkTags, isTrue);
      engine.toggleLandmarkTags();
      expect(engine.showLandmarkTags, isFalse);
    });

    test('DDx slot ranking, evidence tags, and clear slot behave predictably', () {
      engine.setDdxRank(0, 'Acute Cardiac Tamponade');
      engine.setDdxRank(1, 'Acute Pulmonary Embolism');
      engine.setDdxRank(2, 'Anterior Wall STEMI with Cardiogenic Shock');

      expect(engine.top3Ddx[0], 'Acute Cardiac Tamponade');
      expect(engine.top3Ddx[1], 'Acute Pulmonary Embolism');
      expect(engine.top3Ddx[2], 'Anterior Wall STEMI with Cardiogenic Shock');

      engine.clearDdxSlot(1);
      expect(engine.top3Ddx[1], isNull);

      engine.toggleEvidenceTag('Hypotension (MAP < 65)');
      expect(engine.selectedEvidenceTags.contains('Hypotension (MAP < 65)'), isTrue);
      engine.toggleEvidenceTag('Hypotension (MAP < 65)');
      expect(engine.selectedEvidenceTags.contains('Hypotension (MAP < 65)'), isFalse);
    });

    test('contraindicated order triggers Socratic Attending Safety Interception', () {
      engine.loadCase(0); // Tamponade

      // Furosemide is contraindicated in Tamponade (preload collapse)
      final furosemide = WardRoundsEngine.catalogOrders.firstWhere((o) => o.id == 'iv_furosemide');
      final result = engine.placeOrder(furosemide);

      expect(result, isFalse);
      expect(engine.hasActiveSafetyAlert, isTrue);
      expect(engine.activeSafetyAlertTitle, contains('ATTENDING SAFETY INTERCEPTION'));
      expect(engine.activeSafetyAlertRationale, contains('Furosemide causes acute volume depletion'));

      engine.dismissSafetyAlert();
      expect(engine.hasActiveSafetyAlert, isFalse);
    });

    test('mandatory therapeutic orders stabilize the patient', () {
      engine.loadCase(0); // Tamponade requires 'iv_crystalloid_bolus' & 'proc_pericardiocentesis'

      final bolus = WardRoundsEngine.catalogOrders.firstWhere((o) => o.id == 'iv_crystalloid_bolus');
      final pericardiocentesis = WardRoundsEngine.catalogOrders.firstWhere((o) => o.id == 'proc_pericardiocentesis');

      engine.placeOrder(bolus);
      expect(engine.isPatientStabilized, isFalse);

      engine.placeOrder(pericardiocentesis);
      expect(engine.isPatientStabilized, isTrue);
    });

    test('encounter submission calculates multi-factor score out of 100', () {
      engine.loadCase(0);
      engine.setDdxRank(0, 'Acute Cardiac Tamponade');
      engine.setDdxRank(1, 'Acute Pulmonary Embolism');
      engine.setDdxRank(2, 'Anterior Wall STEMI with Cardiogenic Shock');

      engine.toggleEvidenceTag('POCUS Pericardial Effusion');
      engine.toggleEvidenceTag('POCUS RV Diastolic Collapse');

      final bolus = WardRoundsEngine.catalogOrders.firstWhere((o) => o.id == 'iv_crystalloid_bolus');
      final pericardiocentesis = WardRoundsEngine.catalogOrders.firstWhere((o) => o.id == 'proc_pericardiocentesis');
      engine.placeOrder(bolus);
      engine.placeOrder(pericardiocentesis);

      engine.submitCase();

      expect(engine.isCaseSubmitted, isTrue);
      expect(engine.isTimerRunning, isFalse);
      expect(engine.finalEncounterScore, greaterThanOrEqualTo(80.0));
      expect(engine.aggregateDomainMastery['Cardiovascular'], isNotNull);
    });
  });

  group('WardRoundsScreen Widget Tests', () {
    testWidgets('renders top bar, amber SaMD banner, vitals HUD, and panels cleanly', (tester) async {
      addTearDown(() => WardRoundsEngine.instance.stopTimer());
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        buildTestHarness(
          child: const WardRoundsScreen(initialCaseIndex: 0),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify SaMD legal banner
      expect(
        find.text('Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care'),
        findsOneWidget,
      );
      expect(find.text('7-Pillar Shield'), findsOneWidget);

      // Verify Top Bar Title & Case selector
      expect(find.text('WardRounds 3D'), findsOneWidget);
      expect(find.text('Undifferentiated ER/ICU Clinical Reasoning & POCUS'), findsOneWidget);

      // Verify Bedside Vitals HUD
      expect(find.text('HR'), findsOneWidget);
      expect(find.text('BP'), findsOneWidget);
      expect(find.text('SHOCK INDEX'), findsOneWidget);

      // Verify POCUS Simulator
      expect(find.text('BEDSIDE POCUS & RUSH PROTOCOL SIMULATOR'), findsOneWidget);
      expect(find.text('Subxiphoid 4-Chamber'), findsOneWidget);
      expect(find.text('Parasternal Long Axis (PLAX)'), findsOneWidget);
      expect(find.text('IVC Longitudinal'), findsOneWidget);

      // Verify DDx & Orders
      expect(find.text('RANK TOP 3 DIFFERENTIAL DIAGNOSES'), findsOneWidget);
      expect(find.text('LINK SUPPORTING CLINICAL EVIDENCE'), findsOneWidget);
      expect(find.text('BEDSIDE INTERVENTION & ORDER SHEET'), findsOneWidget);
      expect(find.text('SUBMIT CASE FOR ATTENDING REVIEW'), findsOneWidget);
    });

    testWidgets('POCUS window switching and freeze toggle work seamlessly', (tester) async {
      addTearDown(() => WardRoundsEngine.instance.stopTimer());
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        buildTestHarness(
          child: const WardRoundsScreen(initialCaseIndex: 0),
        ),
      );
      await tester.pump();

      // Tap IVC Longitudinal
      await tester.ensureVisible(find.text('IVC Longitudinal'));
      await tester.tap(find.text('IVC Longitudinal'));
      await tester.pump();
      expect(WardRoundsEngine.instance.activePocusWindow, WardPocusWindow.ivcLongitudinal);

      // Tap FREEZE button
      await tester.ensureVisible(find.text('FREEZE'));
      await tester.tap(find.text('FREEZE'));
      await tester.pump();
      expect(find.text('RESUME CINE'), findsOneWidget);

      // Tap CALIPER
      await tester.ensureVisible(find.text('CALIPER'));
      await tester.tap(find.text('CALIPER'));
      await tester.pump();
      expect(find.text('CALIPER ON'), findsOneWidget);
    });

    testWidgets('Socratic Attending dialog opens on 7-Pillar Shield tap', (tester) async {
      addTearDown(() => WardRoundsEngine.instance.stopTimer());
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        buildTestHarness(
          child: const WardRoundsScreen(initialCaseIndex: 0),
        ),
      );
      await tester.pump();

      // Tap 7-Pillar Shield
      await tester.tap(find.text('7-Pillar Shield'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SaMD 7-Pillar Regulatory Shield'), findsOneWidget);
      expect(find.textContaining('Pillar 1: Non-Diagnostic'), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('DISMISS'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SaMD 7-Pillar Regulatory Shield'), findsNothing);
    });
  });
}
