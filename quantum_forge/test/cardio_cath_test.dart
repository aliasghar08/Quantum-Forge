import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/cardio_cath_screen.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_3d_anatomical_heart_viewport.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_fluoroscopy_viewport.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_c_arm_gantry_twin.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_hemodynamic_ecg_strip.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_drug_mechanism_dialog.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardio_nephro_gnn_dialog.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_clinical_info_system.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_diagnostic_workstation_panel.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_research_workstation_panel.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_fellowship_suite_panel.dart';

void main() {
  group('CardioCath 3D: Coronary Angiography & Hemodynamic Lab Tests', () {
    Widget buildTestScreen({String? initialScenarioId, Size size = const Size(1280, 900)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: CardioCathScreen(initialScenarioId: initialScenarioId),
        ),
      );
    }

    testWidgets('renders CardioCathScreen with SaMD banner and 4 viewports on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify SaMD legal banner
      expect(
        find.textContaining('Educational Simulation Only — Not for Clinical Diagnosis'),
        findsOneWidget,
      );

      // Verify Screen Header
      expect(find.text('CardioCath 3D: Coronary Angiography & Hemodynamic Lab'), findsOneWidget);

      // Verify all 4 viewports exist
      expect(find.byType(Cardiac3DAnatomicalHeartViewport), findsOneWidget);
      expect(find.byType(CardiacFluoroscopyViewport), findsOneWidget);
      expect(find.byType(CardiacCArmGantryTwin), findsOneWidget);
      expect(find.byType(CardiacHemodynamicEcgStrip), findsOneWidget);

      // Verify Telemetry strip readouts
      expect(find.text('CATH LAB TELEMETRY'), findsOneWidget);
      expect(find.text('Inject Contrast Dye'), findsOneWidget);
    });

    testWidgets('switches scenario and updates ECG / hemodynamic parameters',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Initial scenario: Normal Coronary
      expect(find.text('Normal Coronary Circulation (Right-Dominant)'), findsOneWidget);

      // Tap on Acute Anterior STEMI chip
      final stemiChip = find.text('Acute Anterior STEMI');
      expect(stemiChip, findsOneWidget);
      await tester.tap(stemiChip);
      await tester.pump();

      // Verify title updated
      expect(find.text('Acute Anterior STEMI (95% Proximal LAD Occlusion)'), findsOneWidget);

      // Verify ST elevation deviation displayed (+4.5 mm)
      expect(find.text('+4.5 mm'), findsOneWidget);
    });

    testWidgets('tapping Inject Contrast triggers dye opacification', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final injectBtn = find.text('Inject Contrast Dye');
      expect(injectBtn, findsOneWidget);
      await tester.ensureVisible(injectBtn);
      await tester.pump();

      await tester.tap(injectBtn);
      await tester.pump();

      expect(find.text('Dye Flowing...'), findsOneWidget);
      expect(find.text('DYE: OPACIFIED (PULSATILE)'), findsOneWidget);
    });

    testWidgets('preset C-arm angle buttons update gantry angles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap on RAO Caudal (Spider View)
      final spiderChip = find.textContaining('Spider View');
      expect(spiderChip, findsOneWidget);

      await tester.ensureVisible(spiderChip);
      await tester.pump();
      await tester.tap(spiderChip);
      await tester.pump();

      // Verify fluoroscopy readout shows RAO 20° / CAUD 30°
      expect(find.textContaining('RAO 20°'), findsWidgets);
      expect(find.textContaining('CAUD 30°'), findsWidgets);
    });

    testWidgets('Inspect Drug MoA button opens CardiacDrugMechanismDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final moaBtn = find.text('Inspect Drug MoA');
      expect(moaBtn, findsOneWidget);

      await tester.tap(moaBtn);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CardiacDrugMechanismDialog), findsOneWidget);
      expect(find.text('Cath Lab Molecular Pharmacology Bridge'), findsOneWidget);
      expect(find.text('Aspirin (Acetylsalicylic Acid)'), findsOneWidget);
      expect(find.text('Nitroglycerin (Glyceryl Trinitrate)'), findsOneWidget);

      // Close dialog
      final closeBtn = find.text('Close');
      await tester.tap(closeBtn);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CardiacDrugMechanismDialog), findsNothing);
    });

    testWidgets('Coronary Dominance Switcher toggles dynamic PDA anatomy', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Default: Right-Dominant (85%)
      expect(find.text('Right-Dominant (85%)'), findsOneWidget);
      expect(find.text('PDA from RCA (85% population)'), findsOneWidget);

      // Switch to Left-Dominant (8%)
      final leftDomChip = find.text('Left-Dominant (8%)');
      await tester.tap(leftDomChip);
      await tester.pump();

      expect(find.text('PDA from LCx (8% population)'), findsOneWidget);

      // Switch to Co-Dominant (7%)
      final coDomChip = find.text('Co-Dominant (7%)');
      await tester.tap(coDomChip);
      await tester.pump();

      expect(find.text('Dual PDA from RCA + LCx (7%)'), findsOneWidget);
    });

    testWidgets('Simulate PCI Stent deploys metallic stent and resolves ST elevation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Select Acute Anterior STEMI
      final stemiChip = find.text('Acute Anterior STEMI');
      await tester.tap(stemiChip);
      await tester.pump();

      // Verify Simulate PCI Stent button appears
      final pciBtn = find.text('Simulate PCI Stent');
      expect(pciBtn, findsOneWidget);
      await tester.ensureVisible(pciBtn);
      await tester.pump();

      // Deploy PCI Stent
      await tester.tap(pciBtn);
      await tester.pump();

      // Verify button changes to TIMI 3 (Stented)
      expect(find.text('TIMI 3 (Stented)'), findsOneWidget);
      // Verify contrast is flowing
      expect(find.text('Dye Flowing...'), findsOneWidget);
      // ST elevation resolved to ~+1.1 mm (75% resolution of 4.5 mm)
      expect(find.text('+1.1 mm'), findsOneWidget);
    });

    testWidgets('12-Lead Territory Switcher updates localized ST deviations and reciprocal depression',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Select Acute Anterior STEMI
      final stemiChip = find.text('Acute Anterior STEMI');
      await tester.tap(stemiChip);
      await tester.pump();

      // Switch territory to Inferior leads (II, III, aVF) to observe reciprocal depression
      final inferiorLeadChip = find.text('II, III, aVF (Inferior)');
      expect(inferiorLeadChip, findsOneWidget);
      await tester.ensureVisible(inferiorLeadChip);
      await tester.pump();
      await tester.tap(inferiorLeadChip);
      await tester.pump();

      // Reciprocal ST depression should be -2.0 mm
      expect(find.text('-2.0 mm'), findsOneWidget);
      expect(find.textContaining('II, III, aVF'), findsWidgets);
    });

    testWidgets('OSCE Exam Mode presents clinical challenge and evaluates student response',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap OSCE Exam Mode toggle button
      final osceToggleBtn = find.text('OSCE Exam Mode');
      expect(osceToggleBtn, findsOneWidget);
      await tester.tap(osceToggleBtn);
      await tester.pump();

      // Verify OSCE header and clinical vignette
      expect(find.text('MBBS INTERVENTIONAL OSCE CHALLENGE'), findsOneWidget);
      expect(find.textContaining('58-year-old male arrives in emergency'), findsOneWidget);

      // Select Culprit Artery
      final ladChoice = find.text('LAD (Left Anterior Descending)');
      expect(ladChoice, findsOneWidget);
      await tester.tap(ladChoice);
      await tester.pump();

      // Select Treatment
      final treatmentChoice = find.text('Deploy PCI Stent + Dual Antiplatelet (Aspirin + P2Y12)');
      expect(treatmentChoice, findsOneWidget);
      await tester.tap(treatmentChoice);
      await tester.pump();

      // Submit OSCE Assessment
      final submitBtn = find.text('Submit OSCE Assessment');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pump();

      // Evaluation results
      expect(find.textContaining('SCORE:'), findsOneWidget);
      expect(find.text('FACULTY CLINICAL RATIONALE & FEEDBACK:'), findsOneWidget);
    });

    testWidgets('3D Anatomical Heart Viewport switches layers between Anatomy, Blood Flow, Conduction, and Coronaries',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify Initial 3D Anatomy Mode & legend
      expect(find.text('Anatomy'), findsOneWidget);
      expect(find.text('LV Myocardium'), findsOneWidget);
      expect(find.text('Pulmonary / Vena Cava'), findsOneWidget);

      // Switch to Blood Flow Mode
      final flowTab = find.text('Blood Flow');
      expect(flowTab, findsOneWidget);
      await tester.ensureVisible(flowTab);
      await tester.pump();
      await tester.tap(flowTab);
      await tester.pump();

      expect(find.text('Oxygenated (LA/LV/Aorta)'), findsOneWidget);
      expect(find.text('Deoxygenated (RA/RV/PA)'), findsOneWidget);

      // Switch to Conduction System Mode
      final condTab = find.text('Conduction');
      expect(condTab, findsOneWidget);
      await tester.ensureVisible(condTab);
      await tester.pump();
      await tester.tap(condTab);
      await tester.pump();

      expect(find.text('SA Node (Pacemaker)'), findsOneWidget);
      expect(find.text('His-Purkinje Network'), findsOneWidget);

      // Switch to Vessels Mode
      final coronariesTab = find.text('Vessels');
      expect(coronariesTab, findsOneWidget);
      await tester.ensureVisible(coronariesTab);
      await tester.pump();
      await tester.tap(coronariesTab);
      await tester.pump();

      expect(find.text('LAD'), findsWidgets);
      expect(find.text('Catheter / Stent'), findsOneWidget);

      // Switch to Ischemia Map Mode
      final ischemiaTab = find.text('Ischemia Map');
      expect(ischemiaTab, findsOneWidget);
      await tester.ensureVisible(ischemiaTab);
      await tester.pump();
      await tester.tap(ischemiaTab);
      await tester.pump();

      expect(find.text('Perfused (FFR ≥ 0.85, WSS Normal)'), findsOneWidget);
      expect(find.text('Ischemic Culprit (FFR < 0.75, Hypoxic)'), findsOneWidget);

      // Switch to Color Doppler Mode
      final dopplerTab = find.text('Color Doppler');
      expect(dopplerTab, findsOneWidget);
      await tester.ensureVisible(dopplerTab);
      await tester.pump();
      await tester.tap(dopplerTab);
      await tester.pump();

      expect(find.text('Mitral Inflow (Toward Apex — BART Red)'), findsOneWidget);
      expect(find.text('Aortic Ejection (Away from Apex — BART Blue)'), findsOneWidget);
    });

    testWidgets('Interventional Suite: toggles Virtual IVUS/OCT, PressureWire X FFR, and Rotablator',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify ALARA Safety Bar readouts
      expect(find.textContaining('ALARA SAFETY & CONTRAST STEWARDSHIP'), findsOneWidget);
      expect(find.textContaining('Air Kerma:'), findsOneWidget);
      expect(find.textContaining('Contrast:'), findsOneWidget);

      // Verify Guide Catheter selections
      expect(find.text('JL4'), findsWidgets);
      expect(find.text('JR4'), findsOneWidget);

      // Tap PressureWire X (FFR) chip
      final pressureWireChip = find.text('PressureWire X (FFR)');
      expect(pressureWireChip, findsOneWidget);
      await tester.tap(pressureWireChip);
      await tester.pump();

      // Verify live FFR / iFR readout is active
      expect(find.textContaining('FFR (Pd/Pa)'), findsOneWidget);

      // Tap Rotablator Burr
      final rotablatorBtn = find.text('Rotablator Burr');
      expect(rotablatorBtn, findsOneWidget);
      await tester.tap(rotablatorBtn);
      await tester.pump();

      expect(find.text('Rotablated (160k RPM)'), findsOneWidget);

      // Toggle Virtual IVUS / OCT Viewport
      final ivusToggleBtn = find.text('Virtual IVUS / OCT');
      expect(ivusToggleBtn, findsOneWidget);
      await tester.ensureVisible(ivusToggleBtn);
      await tester.pump();
      await tester.tap(ivusToggleBtn);
      await tester.pump();

      expect(find.text('VIRTUAL OCT'), findsOneWidget);
      expect(find.text('PULLBACK: 15.0 mm'), findsOneWidget);

      // Open AI Proctor debrief dialog
      final aiProctorBtn = find.text('AI Proctor');
      expect(aiProctorBtn, findsOneWidget);
      await tester.tap(aiProctorBtn);
      await tester.pump();

      expect(find.text('AI Interventional Attending Proctor'), findsOneWidget);
      expect(find.text('Close Proctor Review'), findsOneWidget);
    });

    test('ECG and Hemodynamic Telemetry: R-wave spike, electro-mechanical phase lock, and dicrotic notch', () {
      // 1. P-wave, QRS spike, and S-wave morphology verification
      final pPeak = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.125, 0.0);
      final qNadir = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.245, 0.0);
      final rPeak = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.270, 0.0);
      final sNadir = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.295, 0.0);
      final tPeak = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.460, 0.0);

      expect(pPeak, closeTo(0.15, 0.02), reason: 'P-wave upright dome must be ~+0.15 mV');
      expect(qNadir, closeTo(-0.15, 0.02), reason: 'Q-wave negative dip must be ~-0.15 mV');
      expect(rPeak, closeTo(1.25, 0.01), reason: 'R-wave razor-sharp spike must peak at +1.25 mV');
      expect(sNadir, closeTo(-0.28, 0.02), reason: 'S-wave nadir must dip to ~-0.28 mV');
      expect(tPeak, closeTo(0.32, 0.03), reason: 'T-wave upright dome must peak at ~+0.32 mV');

      // Requirement: R-wave amplitude > 4x P-wave amplitude
      expect(rPeak, greaterThan(4.0 * pPeak), reason: 'R-wave amplitude must be > 4x P-wave amplitude');
      expect(rPeak / pPeak, greaterThan(7.0), reason: 'True QRS:P ratio exceeds 7:1');

      // 2. Strict Electro-Mechanical Coupling (Pa vs R-Wave)
      // At R-wave peak (0.270), left ventricle is initiating isovolumetric contraction;
      // aortic valve is closed, so Pa must still be at diastolic nadir (80 mmHg).
      final paAtR = CardiacHemodynamicEcgStrip.computeAorticPressure(0.270, false, false);
      expect(paAtR, closeTo(80.0, 1.5), reason: 'Pa at R-wave peak must remain at diastolic baseline (80 mmHg)');

      // Search for Pa peak across full cardiac cycle
      double maxPa = 0.0;
      double phiAtMaxPa = 0.0;
      for (int i = 0; i < 1000; i++) {
        final phi = i / 1000.0;
        final pa = CardiacHemodynamicEcgStrip.computeAorticPressure(phi, false, false);
        if (pa > maxPa) {
          maxPa = pa;
          phiAtMaxPa = phi;
        }
      }

      // Requirement: Systolic Pa peak strictly after R-wave peak
      expect(phiAtMaxPa, greaterThan(0.270), reason: 'Systolic Pa peak must occur strictly after R-wave peak');
      expect(phiAtMaxPa, closeTo(0.440, 0.02), reason: 'Systolic Pa peak occurs at ejection peak ~0.44');
      expect(maxPa, closeTo(120.0, 1.0), reason: 'Peak systolic Pa must reach 120 mmHg');

      // 3. Requirement: Dicrotic notch strictly after T-wave
      // T-wave ends at phi = 0.560
      const tWaveEndPhi = 0.560;
      final paAtIncisura = CardiacHemodynamicEcgStrip.computeAorticPressure(0.570, false, false);
      final paAtRebound = CardiacHemodynamicEcgStrip.computeAorticPressure(0.590, false, false);

      expect(0.570, greaterThan(tWaveEndPhi), reason: 'Dicrotic notch must occur strictly after T-wave end (0.560)');
      // Verify incisura dip followed by rebound
      expect(paAtRebound, greaterThan(paAtIncisura), reason: 'Dicrotic notch rebound must exceed incisura nadir');
      expect(paAtIncisura, closeTo(89.5, 2.0));
      expect(paAtRebound, closeTo(94.0, 2.0));

      // 4. STEMI ST-Elevation Verification
      final ecgNormal = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.350, 0.0);
      final ecgStemi = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(0.350, 4.5);
      expect(ecgStemi - ecgNormal, closeTo(0.40, 0.06), reason: '4.5 mm ST elevation translates to ~+0.40 mV ST takeoff');
    });

    testWidgets('CardioNephroGNN Screener Dialog renders benchmark presets and hERG risk',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardioNephroGnnDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SaMD banner verification
      expect(
        find.textContaining('EDUCATIONAL SIMULATION ONLY — In-silico GNN estimate'),
        findsOneWidget,
      );

      // Dialog title & GNN badge
      expect(find.text('PyTorch MPS GNN'), findsOneWidget);
      expect(find.textContaining('CardioNephroGNN'), findsWidgets);

      // Verify preset chips are present
      expect(find.text('Enalaprilat'), findsWidgets);
      expect(find.text('Bisoprolol'), findsOneWidget);
      expect(find.text('Empagliflozin'), findsOneWidget);
      expect(find.text('Losartan'), findsOneWidget);
      expect(find.text('Amiodarone'), findsOneWidget);
      expect(find.text('Terfenadine'), findsOneWidget);

      // Initial drug is Enalaprilat (safe)
      expect(find.textContaining('LOW RISK (SAFE)'), findsOneWidget);
      expect(find.text('ACE'), findsWidgets);

      // Tap on Terfenadine (High-Risk Cardiotoxic Control)
      final terfenadineChip = find.text('Terfenadine');
      await tester.tap(terfenadineChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Terfenadine should trigger High Risk hERG and QT prolongation alert
      expect(find.textContaining('HIGH RISK — Strong hERG Block'), findsOneWidget);
      expect(find.textContaining('CLINICAL ALERT: High affinity for the hERG'), findsOneWidget);
    });

    testWidgets('CardioCathScreen opens CardioNephroGNN dialog from AppBar action',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(size: const Size(1400, 900)));
      await tester.pump();

      final gnnButton = find.text('CardioNephroGNN');
      expect(gnnButton, findsOneWidget);
      await tester.tap(gnnButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog should now be open
      expect(find.byType(CardioNephroGnnDialog), findsOneWidget);
      expect(find.text('PyTorch MPS GNN'), findsOneWidget);
    });

    testWidgets('CardiacInfoButton (ⓘ), Interactive Guide, and 7-Pillar Legal Shield dialogs render and function',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(size: const Size(1440, 1000)));
      await tester.pump();

      // 1. Verify multiple interactive CardiacInfoButton (ⓘ) widgets are rendered across panels
      expect(find.byType(CardiacInfoButton), findsWidgets);
      expect(find.text('Venous In (SVC/IVC/CS)'), findsOneWidget);
      expect(find.text('Pulm Veins In (LA)'), findsOneWidget);
      expect(find.text('Aorta/PA Out'), findsOneWidget);
      expect(find.text('Coronary Tree'), findsOneWidget);

      // 2. Tap on "Legal Info" (CardiacInfoButton) in the top SaMD banner to open detailed modal
      final legalInfoBtn = find.text('Legal Info');
      expect(legalInfoBtn, findsOneWidget);
      await tester.tap(legalInfoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('Regulatory, SaMD, Malpractice & IP Legal Protection Shield'),
        findsOneWidget,
      );
      expect(find.text('PLAIN-ENGLISH SUMMARY (EASY TO UNDERSTAND)'), findsOneWidget);
      expect(find.text('ADVANCED PHYSIOLOGY, BIOPHYSICS & MECHANISM'), findsOneWidget);

      // Close topic modal
      await tester.tap(find.text('Got It'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // 3. Open the 7-Pillar Legal & Regulatory Protection Shield from banner
      final legalShieldBtn = find.text('7-Pillar Legal Shield');
      expect(legalShieldBtn, findsOneWidget);
      await tester.tap(legalShieldBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('7-PILLAR LEGAL, REGULATORY & LIABILITY PROTECTION SHIELD'),
        findsOneWidget,
      );
      expect(
        find.textContaining('21 U.S.C. § 360j(o)'),
        findsWidgets,
      );

      // Acknowledge & close Legal Shield
      await tester.tap(find.text('I Understand & Acknowledge (Educational Use Only)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // 4. Open the Interactive Cath Lab & Dual-Circulation Master Guide from banner
      final cathGuideBtn = find.text('Cath Guide');
      expect(cathGuideBtn, findsOneWidget);
      await tester.tap(cathGuideBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('CardioCath 3D Interactive Clinical & Biophysical Guide'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close Guide'));
      await tester.pump();
    });

    testWidgets('6-Module Cardiovascular Sciences & Diagnostic Workstation renders and switches across all 6 clinical modules',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(size: const Size(1440, 1200)));
      await tester.pump();

      expect(find.byType(CardiacDiagnosticWorkstationPanel), findsOneWidget);
      expect(
        find.text('CARDIOVASCULAR SCIENCES & CLINICAL DIAGNOSTIC WORKSTATION (6 MODULES)'),
        findsOneWidget,
      );

      // Module 1 (Default): Echo & Doppler Lab
      expect(find.text('1. Echo & Doppler Lab'), findsOneWidget);
      expect(find.text('PLAX (Parasternal Long)'), findsOneWidget);
      expect(find.text('Bernoulli ΔP = 4v²'), findsOneWidget);

      // Switch to Module 2: Auscultation & PCG
      final mod2Tab = find.text('2. Auscultation & PCG');
      await tester.ensureVisible(mod2Tab);
      await tester.pump();
      await tester.tap(mod2Tab);
      await tester.pump();
      expect(find.text('A2–P2 Split Interval'), findsOneWidget);
      expect(find.text('Valsalva Strain (Phase II)'), findsOneWidget);

      // Switch to Module 3: EP, Arrhythmia & Pacer
      final mod3Tab = find.text('3. EP, Arrhythmia & Pacer');
      await tester.tap(mod3Tab);
      await tester.pump();
      expect(find.text('AH Interval (AV Node)'), findsOneWidget);
      expect(find.text('HV Interval (His-Purkinje)'), findsOneWidget);

      // Switch to Module 4: LV P–V Loop & Heart Failure
      final mod4Tab = find.text('4. LV P–V Loop & Heart Failure');
      await tester.tap(mod4Tab);
      await tester.pump();
      expect(find.text('Dobutamine (β1 Inotrope)'), findsOneWidget);
      expect(find.text('Stroke Work / PVA (MVO₂)'), findsOneWidget);

      // Switch to Module 5: Congenital Shunt & Oximetry
      final mod5Tab = find.text('5. Congenital Shunt & Oximetry');
      await tester.tap(mod5Tab);
      await tester.pump();
      expect(find.text('Qp / Qs Shunt Ratio'), findsOneWidget);
      expect(find.text('Indomethacin (COX Inhibitor → Closes PDA)'), findsOneWidget);

      // Switch to Module 6: Neuro-Cardiology Tilt & EEG
      final mod6Tab = find.text('6. Neuro-Cardiology Tilt & EEG');
      await tester.tap(mod6Tab);
      await tester.pump();
      expect(find.text('Frontal EEG Rhythm'), findsOneWidget);
      expect(find.text('Leg-Cross Counter-Pressure Maneuver'), findsOneWidget);
    });

    testWidgets('Computational Research Workstation Panel renders and switches across all 4 PyTorch MPS research tabs',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(size: const Size(1440, 1400)));
      await tester.pump();

      expect(find.byType(CardiacResearchWorkstationPanel), findsOneWidget);
      expect(
        find.text('CARDIOVASCULAR COMPUTATIONAL RESEARCH WORKSTATION (IN-HOUSE M1 PRO PYTORCH SUITE)'),
        findsOneWidget,
      );

      // Tab 1 (Default): CardioElectrophys-Net (CiPA AP & hERG)
      expect(find.text('1. CardioElectrophys-Net (CiPA AP & hERG)'), findsOneWidget);
      expect(find.text('IKr (hERG / CHEMBL240)'), findsOneWidget);
      expect(find.textContaining('CiPA qNet:'), findsOneWidget);

      // Switch to Tab 2: CardioPINN TAWSS / OSI & Reynolds Profiler
      final tab2 = find.text('2. CardioPINN TAWSS / OSI & Reynolds Profiler');
      await tester.ensureVisible(tab2);
      await tester.pump();
      await tester.tap(tab2);
      await tester.pump();
      expect(find.text('Project 3D Coronary WSS Heatmap'), findsOneWidget);
      expect(find.textContaining('Peak Throat TAWSS'), findsOneWidget);

      // Switch to Tab 3: Virtual Cohort (N=50–500) & Sobol Tornado
      final tab3 = find.text('3. Virtual Cohort (N=50–500) & Sobol Tornado');
      await tester.tap(tab3);
      await tester.pump();
      expect(find.text('N = 500'), findsOneWidget);
      expect(
        find.text('FIRST-ORDER SOBOL SENSITIVITY TORNADO (VARIANCE CONTRIBUTION S1 TO FFR)'),
        findsOneWidget,
      );

      // Switch to Tab 4: Reproducible Export & Provenance Ledger
      final tab4 = find.text('4. Reproducible Export & Provenance Ledger');
      await tester.tap(tab4);
      await tester.pump();
      expect(find.textContaining('SHA-256 REPRODUCIBILITY DIGEST:'), findsOneWidget);
      expect(find.text('Copy 1,000 Hz Waveform CSV'), findsOneWidget);
      expect(find.text('Copy SHA-256 JSON Manifest'), findsOneWidget);
    });

    testWidgets('Fellowship Suite Panel renders Bifurcation/CTO/Structural Heart, Inverse Digital Twin, and Multiplayer Grand Rounds Room',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(size: const Size(1440, 1600)));
      await tester.pump();

      expect(find.byType(CardiacFellowshipSuitePanel), findsOneWidget);
      expect(
        find.text('INTERVENTIONAL FELLOWSHIP, DIGITAL TWIN & MULTIPLAYER GRAND ROUNDS SUITE'),
        findsOneWidget,
      );

      // Tab 1 (Default): Complex PCI (DK-Crush / CTO) & Structural (TAVR / MitraClip)
      expect(find.text('DK-Crush (2-Stent + Final POT)'), findsOneWidget);
      expect(find.text('0.94 (Patent)'), findsOneWidget);

      // Switch to Structural Heart (TAVR & MitraClip TEER)
      final structPill = find.text('Structural Heart (TAVR & MitraClip TEER)');
      await tester.ensureVisible(structPill);
      await tester.pump();
      await tester.tap(structPill);
      await tester.pump();
      expect(find.text('TAVR Balloon-Expandable (SAPIEN 3 Ultra)'), findsOneWidget);
      expect(find.textContaining('Bernoulli ΔP = 7.6 mmHg'), findsOneWidget);

      // Switch to Tab 2: Real ECG/Waveform Inverse Digital Twin (CardioPINN)
      final tab2 = find.text('2. Real ECG/Waveform Inverse Digital Twin (CardioPINN)');
      await tester.ensureVisible(tab2);
      await tester.pump();
      await tester.tap(tab2);
      await tester.pump();
      expect(find.text('PhysioNet MIMIC-III Radial/Aortic Line'), findsOneWidget);
      expect(find.text('Invert Digital Twin Parameters (CardioPINN)'), findsOneWidget);
      expect(find.text('Sync Fitted Twin to 3D Beating Heart'), findsOneWidget);

      // Switch to Tab 3: Multiplayer Cath Lab & Grand Rounds ("Pass Catheter" OSCE)
      final tab3 = find.text('3. Multiplayer Cath Lab & Grand Rounds ("Pass Catheter" OSCE)');
      await tester.ensureVisible(tab3);
      await tester.pump();
      await tester.tap(tab3);
      await tester.pump();
      expect(find.text('https://quantumforgeapp.com/#/cardiac?room=CATH-ROUNDS-101'), findsOneWidget);
      expect(find.text('Pass Catheter to Fellow'), findsOneWidget);

      // Trigger Coronary Perforation / Tamponade and rescue with Covered Stent + Pericardiocentesis
      final perfBtn = find.text('Trigger Coronary Perforation / Tamponade');
      await tester.tap(perfBtn);
      await tester.pump();
      expect(find.text('0 / 100 (CRISIS ACTIVE)'), findsOneWidget);

      final rescueBtn = find.text('PK Papyrus Covered Stent + Pericardiocentesis');
      await tester.tap(rescueBtn);
      await tester.pump();
      expect(find.text('100 / 100 (RESCUED / STABLE)'), findsOneWidget);
    });
  });
}
