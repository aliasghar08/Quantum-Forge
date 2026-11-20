// ============================================================================
// Multi-Organ Digital Patient, NephroLab 3D & Safety Guardrails Test Suite
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';
import 'package:quantum_forge/features/clinical_core/presentation/widgets/clinical_safety_proctor_banner.dart';
import 'package:quantum_forge/core/security/chemical_safety_guard.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/domain_of_applicability_advisory_widget.dart';
import 'package:quantum_forge/features/cardiac/data/cardiac_master_vitals_state.dart';
import 'package:quantum_forge/features/cardiac/data/coronary_hemodynamics_engine.dart';

void main() {
  group('MultiOrganPatientState & Cardiorenal Coupling Tests', () {
    late MultiOrganPatientState patientState;

    setUp(() {
      patientState = MultiOrganPatientState.instance;
      patientState.resetAllVitals();
      patientState.setCoupling(true);
    });

    test('Initial baseline values are normal across organs', () {
      expect(patientState.isCoupled, isTrue);
      expect(patientState.cardiacVitals.heartRateBpm, closeTo(72.0, 1.0));
      expect(patientState.cardiacVitals.lvefPct, closeTo(60.0, 1.0));
      expect(patientState.neuroVitals.icpMmHg, closeTo(11.0, 1.0));
      expect(patientState.nephroVitals.egfrMlMin, closeTo(95.0, 1.0));
      expect(patientState.nephroVitals.clearanceRatio, closeTo(1.0, 0.05));
    });

    test('Cardiorenal Cascade: Cardiogenic shock drops RPP, eGFR, and scales clearance ratio', () {
      patientState.cardiacVitals.triggerSituation(CardiacClinicalSituation.cardiogenicShock);

      // LVEF drops to 22%, MAP drops
      expect(patientState.cardiacVitals.lvefPct, lessThan(30.0));
      // Nephro eGFR should drop significantly
      expect(patientState.nephroVitals.egfrMlMin, lessThan(35.0));
      // Clearance multiplier drops < 0.40
      expect(patientState.nephroVitals.clearanceRatio, lessThan(0.40));
      // Oliguria triggered (< 0.5 mL/kg/h)
      expect(patientState.nephroVitals.urineOutputMlKgH, lessThan(0.5));
    });

    test('Cardio-Embolic Neuro Cascade: Atrial Fibrillation triggers embolic risk and CHA2DS2-VASc score', () {
      expect(patientState.hasEmbolicRisk, isFalse);

      patientState.cardiacVitals.applyRhythmOverride(OscilloscopeRhythmType.afib);

      expect(patientState.hasEmbolicRisk, isTrue);
      expect(patientState.cha2ds2VascScore, greaterThanOrEqualTo(2));
    });

    test('Cushing Reflex: Intracranial hypertension (ICP > 28 mmHg) triggers severe hypertension and reflex bradycardia', () {
      patientState.neuroVitals.setManualIcp(32.0);

      expect(patientState.isCushingReflexActive, isTrue);
      expect(patientState.cardiacVitals.systolicBp, greaterThanOrEqualTo(195.0));
      expect(patientState.cardiacVitals.heartRateBpm, lessThanOrEqualTo(50.0));
    });

    test('Uncoupling disables cascading between systems', () {
      patientState.setCoupling(false);
      expect(patientState.isCoupled, isFalse);

      final baselineEgfr = patientState.nephroVitals.egfrMlMin;
      patientState.cardiacVitals.triggerSituation(CardiacClinicalSituation.cardiogenicShock);

      // When uncoupled, cardiac shock should NOT alter nephro eGFR
      expect(patientState.nephroVitals.egfrMlMin, equals(baselineEgfr));
    });
  });

  group('NephroMasterVitalsState & Acid-Base Math Tests', () {
    test('Calculates Anion Gap and Albumin-Corrected Anion Gap accurately', () {
      final vitals = NephroMasterVitalsState();
      vitals.setManualValues(
        sodium: 140.0,
        chloride: 100.0,
        hco3: 20.0,
        albumin: 4.0,
      );

      // AG = 140 - (100 + 20) = 20
      expect(vitals.rawAnionGap, closeTo(20.0, 0.1));
      expect(vitals.correctedAnionGap, closeTo(20.0, 0.1));

      // With hypoalbuminemia (albumin 2.0 g/dL): corrAG = 20 + 2.5 * (4.0 - 2.0) = 25.0
      vitals.setManualValues(albumin: 2.0);
      expect(vitals.correctedAnionGap, closeTo(25.0, 0.1));
    });

    test('Calculates Winter formula expected PaCO2 and Delta-Delta ratio correctly', () {
      final vitals = NephroMasterVitalsState();
      vitals.applySituation(NephroClinicalSituation.dka);

      // DKA: HCO3 = 6.0
      // Winter formula expected PaCO2 = 1.5 * 6.0 + 8 = 17.0 (+/- 2)
      expect(vitals.winterExpectedPaCO2, closeTo(17.0, 0.1));
      expect(vitals.deltaDeltaRatio, greaterThan(0.0));
    });
  });

  group('CBRN & Controlled Substance Input Safety Gate Tests', () {
    test('Permits benign organic molecules and therapeutic drugs', () {
      expect(ChemicalSafetyGuard.screen('Aspirin acetylsalicylic acid').isAllowed, isTrue);
      expect(ChemicalSafetyGuard.screen('Dapagliflozin SGLT2 inhibitor').isAllowed, isTrue);
      expect(ChemicalSafetyGuard.screen('CC(=O)Oc1ccccc1C(=O)O').isAllowed, isTrue);
      expect(ChemicalSafetyGuard.screen('Ethanol C2H5OH').isAllowed, isTrue);
    });

    test('Blocks Chemical Weapons Convention (CWC) nerve and vesicant agents', () {
      final sarin = ChemicalSafetyGuard.screen('Sarin GB chemical agent');
      expect(sarin.isAllowed, isFalse);
      expect(sarin.violationCategory, contains('CWC'));

      final vx = ChemicalSafetyGuard.screen('VX nerve agent');
      expect(vx.isAllowed, isFalse);

      final mustard = ChemicalSafetyGuard.screen('Sulfur mustard bis(2-chloroethyl) sulfide');
      expect(mustard.isAllowed, isFalse);

      final tabun = ChemicalSafetyGuard.screen('Tabun GA nerve agent');
      expect(tabun.isAllowed, isFalse);
    });

    test('Blocks High Explosives (RDX, TNT, PETN, TATP)', () {
      final rdx = ChemicalSafetyGuard.screen('RDX cyclotrimethylenetrinitramine');
      expect(rdx.isAllowed, isFalse);
      expect(rdx.violationCategory, contains('Explosive'));

      final tnt = ChemicalSafetyGuard.screen('Trinitrotoluene TNT explosive');
      expect(tnt.isAllowed, isFalse);

      final tatp = ChemicalSafetyGuard.screen('TATP triacetone triperoxide');
      expect(tatp.isAllowed, isFalse);
    });

    test('Blocks DEA Schedule I/II illicit narcotics and controlled precursors', () {
      final heroin = ChemicalSafetyGuard.screen('Diacetylmorphine Heroin synthesis');
      expect(heroin.isAllowed, isFalse);
      expect(heroin.violationCategory, contains('Controlled'));

      final meth = ChemicalSafetyGuard.screen('Methamphetamine synthesis route');
      expect(meth.isAllowed, isFalse);
    });
  });

  group('Domain of Applicability (DoA) & Transition Metal Advisory Tests', () {
    test('Flags transition metals correctly', () {
      const widgetPd = DomainOfApplicabilityAdvisoryWidget(
        chemicalName: 'Palladium catalyzed Suzuki-Miyaura coupling',
      );
      expect(widgetPd.hasTransitionMetal, isTrue);
      expect(widgetPd.shouldDisplay, isTrue);

      const widgetFe = DomainOfApplicabilityAdvisoryWidget(
        chemicalName: 'Ferrocene iron complex',
        molecularFormula: 'Fe(C5H5)2',
      );
      expect(widgetFe.hasTransitionMetal, isTrue);
      expect(widgetFe.shouldDisplay, isTrue);
    });

    test('Flags open-shell spin multiplicity (> 1) as outside DoA', () {
      const widgetTriplet = DomainOfApplicabilityAdvisoryWidget(
        chemicalName: 'Oxygen radical',
        spinMultiplicity: 3,
      );
      expect(widgetTriplet.isOpenShellSpin, isTrue);
      expect(widgetTriplet.shouldDisplay, isTrue);
    });

    test('Permits standard organic closed-shell molecules inside DoA', () {
      const widgetOrganic = DomainOfApplicabilityAdvisoryWidget(
        chemicalName: 'Aspirin',
        molecularFormula: 'C9H8O4',
        spinMultiplicity: 1,
      );
      expect(widgetOrganic.hasTransitionMetal, isFalse);
      expect(widgetOrganic.isOpenShellSpin, isFalse);
      expect(widgetOrganic.shouldDisplay, isFalse);
    });
  });

  group('Clinical Safety Proctor Interceptor Widget Tests', () {
    testWidgets('Detects and displays Nitroglycerin contraindication in Inferior/RV STEMI', (tester) async {
      final patientState = MultiOrganPatientState.instance;
      patientState.resetAllVitals();
      patientState.cardiacVitals.triggerSituation(CardiacClinicalSituation.inferiorRvMi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSafetyProctorBanner(patientState: patientState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOCRATIC ATTENDING INTERCEPTOR'), findsOneWidget);
      expect(find.text('PRELOAD COLLAPSE'), findsOneWidget);
      expect(find.textContaining('Nitroglycerin in Inferior / RV STEMI'), findsOneWidget);
      expect(find.text('Socratic Review'), findsOneWidget);
    });

    testWidgets('Tapping Socratic Review opens dialog with pathophysiological pearl and board question', (tester) async {
      final patientState = MultiOrganPatientState.instance;
      patientState.resetAllVitals();
      patientState.cardiacVitals.triggerSituation(CardiacClinicalSituation.inferiorRvMi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSafetyProctorBanner(patientState: patientState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Socratic Review'));
      await tester.pumpAndSettle();

      expect(find.text('ACADEMIC ROUNDS: CLINICAL ERROR INTERCEPT'), findsOneWidget);
      expect(find.textContaining('Pathophysiological Mechanism'), findsOneWidget);
      expect(find.textContaining('Attending Board Question'), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);
    });
  });
}
