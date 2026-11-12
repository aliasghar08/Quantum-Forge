// ============================================================================
// Cardiovascular Sciences & Diagnostic Workstation Panel
// ----------------------------------------------------------------------------
// Adds 6 High-Yield Cardiology Diagnostic & Clinical Modules to CardioCath 3D:
// 1. Virtual 2D/3D Echocardiography & Color Flow Doppler Lab ("Echo Lab")
// 2. Cardiac Auscultation & Phonocardiography (PCG) Simulator
// 3. Electrophysiology (EP) Study, Arrhythmia & Pacemaker Lab
// 4. Left Ventricular Pressure-Volume (P–V) Loop & Heart Failure Simulator
// 5. Congenital Heart Disease (CHD) & Oximetry Step-Up Shunt Lab
// 6. Neuro-Cardiology Syncope & Autonomic Tilt-Table Lab (ECG + EEG Coupling)
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/cardiac_pathology_models.dart';
import 'cardiac_clinical_info_system.dart';
import 'cardiac_three_engine.dart';

/// Top-level diagnostic module tabs for the Cardiovascular Sciences & Diagnostic Workstation.
enum CardiacDiagnosticModule {
  echoDoppler(
    id: 'echo',
    shortLabel: '1. Echo & Doppler Lab',
    fullTitle: 'Virtual 2D/3D Echocardiography & Color Flow Doppler Lab',
    icon: Icons.radar_rounded,
    accent: Color(0xFF00E5FF),
    topicId: 'diag_echo_lab',
  ),
  auscultationPcg(
    id: 'pcg',
    shortLabel: '2. Auscultation & PCG',
    fullTitle: 'Cardiac Auscultation & Phonocardiography (PCG) Simulator',
    icon: Icons.hearing_rounded,
    accent: Color(0xFF10B981),
    topicId: 'diag_auscultation_pcg',
  ),
  epArrhythmia(
    id: 'ep',
    shortLabel: '3. EP, Arrhythmia & Pacer',
    fullTitle: 'Electrophysiology (EP) Study, Arrhythmia & Pacemaker Lab',
    icon: Icons.electric_bolt_rounded,
    accent: Color(0xFFFFD600),
    topicId: 'diag_ep_arrhythmia',
  ),
  pvLoopHf(
    id: 'pv',
    shortLabel: '4. LV P–V Loop & Heart Failure',
    fullTitle: 'Left Ventricular Pressure-Volume (P–V) Loop & Sagawa Elastance Lab',
    icon: Icons.ssid_chart_rounded,
    accent: Color(0xFFF43F5E),
    topicId: 'diag_pv_loop',
  ),
  congenitalChd(
    id: 'chd',
    shortLabel: '5. Congenital Shunt & Oximetry',
    fullTitle: 'Congenital Heart Disease (CHD) & Oximetry Step-Up Shunt Lab',
    icon: Icons.call_split_rounded,
    accent: Color(0xFFA78BFA),
    topicId: 'diag_chd_shunt',
  ),
  neuroTiltSyncope(
    id: 'tilt',
    shortLabel: '6. Neuro-Cardiology Tilt & EEG',
    fullTitle: 'Head-Up Tilt-Table (HUTT) Syncope & Frontal EEG Coupling Lab',
    icon: Icons.airline_seat_flat_angled_rounded,
    accent: Color(0xFFFB923C),
    topicId: 'diag_neuro_tilt',
  );

  final String id;
  final String shortLabel;
  final String fullTitle;
  final IconData icon;
  final Color accent;
  final String topicId;

  const CardiacDiagnosticModule({
    required this.id,
    required this.shortLabel,
    required this.fullTitle,
    required this.icon,
    required this.accent,
    required this.topicId,
  });
}

// ============================================================================
// MODULE 1 MODELS: ECHOCARDIOGRAPHY & COLOR DOPPLER
// ============================================================================

enum EchoAcousticWindow {
  plax('PLAX (Parasternal Long)', 'TTE L 3rd ICS', 'LA, MV, LV, LVOT, AoV, RV'),
  psax('PSAX (Parasternal Short)', 'TTE L 4th ICS (Papillary)', 'Concentric LV Ring & RV Crescent'),
  a4c('A4C (Apical 4-Chamber)', 'TTE L 5th ICS Apex', 'LA, LV, RA, RV & Septum'),
  subcostal('Subcostal / TEE Mid-Esophageal', 'Subxiphoid / TEE 120°', 'IAS, IVC Collapsibility & 4 Chambers');

  final String label;
  final String probeSite;
  final String structuresViewed;
  const EchoAcousticWindow(this.label, this.probeSite, this.structuresViewed);
}

enum EchoHemodynamicPhenotype {
  normal(
    label: 'Normal LV Function',
    edvMl: 120.0,
    esvMl: 48.0,
    epssMm: 4.2,
    tapseMm: 22.0,
    eWaveMs: 0.85,
    aWaveMs: 0.55,
    peakJetVelMs: 1.3,
    colorJetType: 'Laminar BART (Normal)',
    clinicalPearl: 'Normal LVEF 60%, EPSS < 7 mm, TAPSE >= 17 mm, and E/A ratio 1.54 (healthy diastolic relaxation).',
  ),
  hfref(
    label: 'HFrEF (Dilated Cardiomyopathy)',
    edvMl: 210.0,
    esvMl: 151.0,
    epssMm: 14.5,
    tapseMm: 13.0,
    eWaveMs: 1.15,
    aWaveMs: 0.42,
    peakJetVelMs: 0.9,
    colorJetType: 'Central Functional MR Jet',
    clinicalPearl: 'Severely reduced LVEF (28%) with globular LV dilation, increased Mitral E-Point Septal Separation (EPSS 14.5 mm), and restrictive E/A > 2.0.',
  ),
  hfpef(
    label: 'HFpEF (Diastolic Dysfunction)',
    edvMl: 105.0,
    esvMl: 42.0,
    epssMm: 4.8,
    tapseMm: 19.0,
    eWaveMs: 0.52,
    aWaveMs: 0.88,
    peakJetVelMs: 1.4,
    colorJetType: 'Impaired Relaxation (E < A)',
    clinicalPearl: 'Preserved LVEF (60%) with concentric LV wall hypertrophy, left atrial enlargement, and Grade I E/A reversal (E/A = 0.59, S4 atrial kick reliance).',
  ),
  severeAs(
    label: 'Severe Aortic Stenosis (Calcific)',
    edvMl: 115.0,
    esvMl: 48.0,
    epssMm: 5.1,
    tapseMm: 20.0,
    eWaveMs: 0.62,
    aWaveMs: 0.90,
    peakJetVelMs: 4.5,
    colorJetType: 'Turbulent AoV Aliasing Mosaic',
    clinicalPearl: 'Peak CW Doppler jet velocity v = 4.5 m/s yields Bernoulli peak gradient ΔP = 4v² = 81.0 mmHg (Severe AS criteria: v >= 4.0 m/s, mean ΔP >= 40 mmHg, AVA < 1.0 cm²).',
  ),
  severeMr(
    label: 'Severe Mitral Regurgitation',
    edvMl: 175.0,
    esvMl: 55.0,
    epssMm: 6.0,
    tapseMm: 21.0,
    eWaveMs: 1.45,
    aWaveMs: 0.50,
    peakJetVelMs: 5.2,
    colorJetType: 'Systolic LA Aliasing Regurgitant Jet',
    clinicalPearl: 'Holosystolic high-velocity aliasing jet into the Left Atrium (vena contracta >= 7 mm) with supranormal LVEF (69%) due to unloading into the low-pressure LA.',
  ),
  hocm(
    label: 'HOCM (SAM + LVOT Obstruction)',
    edvMl: 95.0,
    esvMl: 24.0,
    epssMm: 1.5,
    tapseMm: 23.0,
    eWaveMs: 0.58,
    aWaveMs: 0.92,
    peakJetVelMs: 4.2,
    colorJetType: 'LVOT SAM Dagger-Shaped Aliasing',
    clinicalPearl: 'Asymmetric septal hypertrophy (>15 mm) with Systolic Anterior Motion (SAM) of the anterior mitral leaflet causing dynamic LVOT obstruction (ΔP = 4v² = 70.6 mmHg).',
  );

  final String label;
  final double edvMl;
  final double esvMl;
  final double epssMm;
  final double tapseMm;
  final double eWaveMs;
  final double aWaveMs;
  final double peakJetVelMs;
  final String colorJetType;
  final String clinicalPearl;

  const EchoHemodynamicPhenotype({
    required this.label,
    required this.edvMl,
    required this.esvMl,
    required this.epssMm,
    required this.tapseMm,
    required this.eWaveMs,
    required this.aWaveMs,
    required this.peakJetVelMs,
    required this.colorJetType,
    required this.clinicalPearl,
  });

  double get strokeVolumeMl => edvMl - esvMl;
  double get lvefPercent => ((edvMl - esvMl) / edvMl) * 100.0;
  double get eaRatio => eWaveMs / aWaveMs;
  double get bernoulliDeltaPMmHg => 4.0 * peakJetVelMs * peakJetVelMs;
}

// ============================================================================
// MODULE 2 MODELS: CARDIAC AUSCULTATION & PHONOCARDIOGRAPHY (PCG)
// ============================================================================

enum PrecordialListeningPost {
  aortic('Aortic Area', 'R 2nd ICS Sternal Border', 'Aortic Stenosis (radiates to carotids), A2 intensity'),
  pulmonic('Pulmonic Area', 'L 2nd ICS Sternal Border', 'S2 Splitting (A2–P2), Pulmonic Stenosis, PDA machinery murmur'),
  tricuspid('Tricuspid / Erb’s Point', 'L 4th ICS Sternal Border', 'Tricuspid Regurgitation, VSD holosystolic, AR diastolic decrescendo'),
  mitralApex('Mitral Area (Apex)', 'L 5th ICS Mid-Clavicular', 'S1 intensity, Mitral Regurgitation (radiates to axilla), MS rumble, S3/S4');

  final String title;
  final String anatomicalLocation;
  final String primaryFindings;
  const PrecordialListeningPost(this.title, this.anatomicalLocation, this.primaryFindings);
}

enum AuscultationSoundProfile {
  normalS1S2(
    label: 'Normal S1 / S2 (Physiologic Split)',
    baseA2P2SplitMs: 25.0,
    s3Intensity: 0.0,
    s4Intensity: 0.0,
    systolicMurmur: 0.0,
    diastolicMurmur: 0.0,
    murmurShape: 'None',
    description: 'Crisp S1 (M1+T1) at QRS onset and S2 (A2+P2) at dicrotic notch; inspiration widens A2–P2 split to ~45 ms.',
  ),
  asdFixedSplit(
    label: 'Secundum ASD (Wide Fixed Split S2)',
    baseA2P2SplitMs: 55.0,
    s3Intensity: 0.0,
    s4Intensity: 0.0,
    systolicMurmur: 0.45,
    diastolicMurmur: 0.0,
    murmurShape: 'Pulmonic Flow Ejection',
    description: 'Left-to-right atrial shunt continuously overloads RV, keeping A2–P2 split fixed at ~55 ms during both inspiration and expiration.',
  ),
  lbbbParadoxical(
    label: 'LBBB / Severe AS (Paradoxical Split S2)',
    baseA2P2SplitMs: -40.0,
    s3Intensity: 0.0,
    s4Intensity: 0.35,
    systolicMurmur: 0.25,
    diastolicMurmur: 0.0,
    murmurShape: 'Delayed A2 (P2 before A2)',
    description: 'Delayed LV emptying causes A2 to close AFTER P2 (reversed order). Inspiration delays P2, moving it closer to A2 (paradoxical narrowing).',
  ),
  aorticStenosis(
    label: 'Aortic Stenosis (Crescendo-Decrescendo)',
    baseA2P2SplitMs: 15.0,
    s3Intensity: 0.0,
    s4Intensity: 0.55,
    systolicMurmur: 0.90,
    diastolicMurmur: 0.0,
    murmurShape: 'Diamond Systolic Ejection',
    description: 'Harsh mid-systolic crescendo-decrescendo ejection murmur at R 2nd ICS radiating to carotid arteries with soft/absent A2 and S4 gallop.',
  ),
  mitralRegurg(
    label: 'Mitral Regurgitation (Holosystolic + S3)',
    baseA2P2SplitMs: 35.0,
    s3Intensity: 0.65,
    s4Intensity: 0.0,
    systolicMurmur: 0.85,
    diastolicMurmur: 0.0,
    murmurShape: 'Holosystolic Blowing',
    description: 'High-pitched blowing holosystolic murmur at apex radiating to left axilla, accompanied by an early diastolic S3 volume-overload gallop.',
  ),
  mitralStenosis(
    label: 'Mitral Stenosis (Opening Snap + Rumble)',
    baseA2P2SplitMs: 25.0,
    s3Intensity: 0.0,
    s4Intensity: 0.0,
    systolicMurmur: 0.0,
    diastolicMurmur: 0.85,
    murmurShape: 'Opening Snap + Diastolic Rumble',
    description: 'Loud S1 followed by an early diastolic Opening Snap (OS) and low-pitched mid-diastolic rumble with presystolic accentuation.',
  ),
  hocmDynamic(
    label: 'HOCM (Systolic LVOT + S4 Gallop)',
    baseA2P2SplitMs: 20.0,
    s3Intensity: 0.0,
    s4Intensity: 0.70,
    systolicMurmur: 0.75,
    diastolicMurmur: 0.0,
    murmurShape: 'Dynamic LVOT Crescendo-Decrescendo',
    description: 'Harsh systolic murmur along left sternal border that uniquely INTENSIFIES with Valsalva strain (↓ preload narrows LVOT) and SOFTENS with squatting/handgrip.',
  );

  final String label;
  final double baseA2P2SplitMs;
  final double s3Intensity;
  final double s4Intensity;
  final double systolicMurmur;
  final double diastolicMurmur;
  final String murmurShape;
  final String description;

  const AuscultationSoundProfile({
    required this.label,
    required this.baseA2P2SplitMs,
    required this.s3Intensity,
    required this.s4Intensity,
    required this.systolicMurmur,
    required this.diastolicMurmur,
    required this.murmurShape,
    required this.description,
  });
}

enum BedsideManeuver {
  baseline('Resting Baseline', 'Normal venous return & SVR'),
  inspiration('Deep Inspiration', '↑ Venous return to RV → Right-sided murmurs louder (Carvallo sign) & widens physiologic S2 split'),
  valsalva('Valsalva Strain (Phase II)', '↓ Preload (↓ LV volume) → HOCM & MVP LOUDER; AS/MR/MS softer'),
  squatting('Rapid Squatting', '↑ Preload & ↑ Afterload → HOCM & MVP SOFTER; AS/MR/VSD louder'),
  handgrip('Isometric Handgrip', '↑ Afterload (↑ SVR) → MR, AR & VSD LOUDER; AS & HOCM softer');

  final String label;
  final String physiologyEffect;
  const BedsideManeuver(this.label, this.physiologyEffect);
}

// ============================================================================
// MODULE 3 MODELS: ELECTROPHYSIOLOGY (EP), ARRHYTHMIA & PACEMAKER LAB
// ============================================================================

enum EpArrhythmiaState {
  normalSinus(
    label: 'Normal Sinus Rhythm',
    rateBpm: 72,
    paMs: 35,
    ahMs: 85,
    hvMs: 45,
    qtcMs: 410,
    ablatable: false,
    hergLinked: false,
    mechanism: 'SA Node automaticity → AV Node delay (AH 85 ms) → rapid His-Purkinje (HV 45 ms).',
  ),
  wpwSyndrome(
    label: 'WPW Syndrome (Bundle of Kent Delta Wave)',
    rateBpm: 88,
    paMs: 30,
    ahMs: 75,
    hvMs: 15,
    qtcMs: 425,
    ablatable: true,
    hergLinked: false,
    mechanism: 'Atrioventricular Accessory Pathway (Bundle of Kent) bypasses AV node delay, pre-exciting ventricles (short PR < 120 ms, HV 15 ms, slurred Delta wave).',
  ),
  avnrt(
    label: 'AVNRT (Slow-Fast AV Nodal Re-Entry)',
    rateBpm: 175,
    paMs: 30,
    ahMs: 210,
    hvMs: 45,
    qtcMs: 430,
    ablatable: true,
    hergLinked: false,
    mechanism: 'Re-entrant circuit within the AV node (anterograde down Slow pathway, retrograde up Fast pathway) producing narrow-complex SVT with concentric CS activation.',
  ),
  atrialFlutter(
    label: 'Atrial Flutter (CTI Macro-Reentry 2:1)',
    rateBpm: 150,
    paMs: 25,
    ahMs: 95,
    hvMs: 45,
    qtcMs: 420,
    ablatable: true,
    hergLinked: false,
    mechanism: 'Counter-clockwise macro-reentrant circuit around the tricuspid annulus via the Cavotricuspid Isthmus (CTI) at 300 bpm with 2:1 AV conduction (sawtooth F-waves).',
  ),
  mobitzI(
    label: '2nd-Degree Mobitz I (Wenckebach AV Nodal)',
    rateBpm: 58,
    paMs: 35,
    ahMs: 185,
    hvMs: 45,
    qtcMs: 415,
    ablatable: false,
    hergLinked: false,
    mechanism: 'Progressive AV nodal fatigue (prolonging AH interval) until a P-wave fails to conduct; HV interval remains normal (45 ms). Benign & responsive to Atropine.',
  ),
  mobitzII(
    label: '2nd-Degree Mobitz II (Infra-Hisian Block)',
    rateBpm: 48,
    paMs: 35,
    ahMs: 90,
    hvMs: 95,
    qtcMs: 440,
    ablatable: false,
    hergLinked: false,
    mechanism: 'Fixed PR interval with abrupt non-conducted P-waves caused by His-Purkinje system disease (prolonged HV 95 ms). High risk of syncope — requires permanent Pacemaker!',
  ),
  completeHeartBlock(
    label: '3rd-Degree Complete Heart Block (Infra-Hisian)',
    rateBpm: 38,
    paMs: 35,
    ahMs: 90,
    hvMs: 140,
    qtcMs: 460,
    ablatable: false,
    hergLinked: false,
    mechanism: 'Complete atrioventricular dissociation below the Bundle of His; atria fire at 75 bpm while ventricles depend on a slow ventricular escape rhythm (38 bpm). Requires DDD Pacemaker!',
  ),
  ventricularTachycardia(
    label: 'Monomorphic Ventricular Tachycardia (Scar Re-Entry)',
    rateBpm: 185,
    paMs: 35,
    ahMs: 85,
    hvMs: -20,
    qtcMs: 480,
    ablatable: true,
    hergLinked: false,
    mechanism: 'Macro-reentrant circuit around post-MI ventricular scar tissue producing wide-complex tachycardia (185 bpm) with AV dissociation and fusion/capture beats.',
  ),
  torsadesHerg(
    label: 'Torsades de Pointes (CardioNephroGNN hERG Block)',
    rateBpm: 220,
    paMs: 35,
    ahMs: 90,
    hvMs: 50,
    qtcMs: 565,
    ablatable: false,
    hergLinked: true,
    mechanism: 'Potent hERG (KCNH2 / IKr) channel blockade (e.g., Terfenadine / Sotalol) prolongs Phase 3 repolarization (QTc 565 ms), triggering Early Afterdepolarizations (EADs) and twisting polymorphic VT.',
  );

  final String label;
  final int rateBpm;
  final int paMs;
  final int ahMs;
  final int hvMs;
  final int qtcMs;
  final bool ablatable;
  final bool hergLinked;
  final String mechanism;

  const EpArrhythmiaState({
    required this.label,
    required this.rateBpm,
    required this.paMs,
    required this.ahMs,
    required this.hvMs,
    required this.qtcMs,
    required this.ablatable,
    required this.hergLinked,
    required this.mechanism,
  });
}

enum PacemakerMode {
  off('Pacer OFF (Intrinsic)', 'No artificial pacing'),
  vvi('VVI (Single-Chamber RV)', 'Ventricular pacing + sensing; inhibited by intrinsic R-wave'),
  ddd('DDD (Dual-Chamber AV Sync)', 'Atrial + Ventricular sequential pacing & sensing; restores physiological AV synchrony');

  final String label;
  final String description;
  const PacemakerMode(this.label, this.description);
}

// ============================================================================
// MODULE 4 MODELS: LV PRESSURE-VOLUME (P–V) LOOP & PHARMACOLOGY
// ============================================================================

enum PvDrugPreset {
  baseline('Baseline Control', 120.0, 1.8, 2.0, 72.0, 'Normal resting preload (EDV 120 mL), afterload (Ea 1.8), and contractility (Emax 2.0).'),
  dobutamine('Dobutamine (β1 Inotrope)', 122.0, 1.65, 3.2, 88.0, 'β1-selective agonist: steepens ESPVR slope (↑ Emax to 3.2), shifts ESV left (↓ ESV), and increases Stroke Volume & LVEF.'),
  norepinephrine('Norepinephrine (α1 + β1 Pressor)', 118.0, 2.75, 2.4, 78.0, 'Potent α1 vasoconstriction markedly raises Afterload (Ea 2.75) and peak LV systolic pressure, increasing MVO2 demand.'),
  nitroglycerin('Nitroglycerin (Venodilator)', 92.0, 1.50, 2.0, 76.0, 'NO-cGMP venodilation reduces Preload (EDV drops to 92 mL), shifting the P–V loop left/down and slashing myocardial wall stress (MVO2).'),
  metoprolol('Metoprolol (β1 Blocker)', 126.0, 1.70, 1.45, 58.0, 'Negative inotrope & chronotrope: lowers Emax and HR (prolonging diastolic filling time) to reduce Pressure-Volume Area (PVA).'),
  furosemide('Furosemide (Loop Diuretic in HFrEF)', 142.0, 1.95, 1.15, 78.0, 'Unloads congested HFrEF preload along the steep EDPVR curve, lowering LVEDP (PCWP) and pulmonary edema.'),
  sacubitrilValsartan('Sacubitril/Valsartan (ARNI)', 130.0, 1.40, 1.85, 70.0, 'Dual neprilysin/AT1 inhibition reduces both Afterload (↓ Ea) and Preload, increasing Stroke Volume while lowering Stroke Work.');

  final String label;
  final double preloadEdvMl;
  final double afterloadEa;
  final double contractilityEmax;
  final double heartRateBpm;
  final String rationale;

  const PvDrugPreset(
    this.label,
    this.preloadEdvMl,
    this.afterloadEa,
    this.contractilityEmax,
    this.heartRateBpm,
    this.rationale,
  );
}

// ============================================================================
// MODULE 5 MODELS: CONGENITAL HEART DISEASE (CHD) & OXIMETRY SHUNT LAB
// ============================================================================

enum CongenitalShuntDefect {
  normalAdult(
    label: 'Normal Adult Circulation (No Shunt)',
    svcSat: 75.0,
    raSat: 75.0,
    rvSat: 75.0,
    paSat: 75.0,
    laSat: 98.0,
    lvSat: 98.0,
    aoSat: 98.0,
    shuntDirection: 'None (Qp/Qs = 1.00)',
    stepUpChamber: 'None',
    pearl: 'Normal right-heart mixed venous saturation is ~75% (SVC/RA/RV/PA) and left-heart arterial saturation is ~98% (LA/LV/Ao).',
  ),
  secundumAsd(
    label: 'Ostium Secundum ASD (L→R Atrial Shunt)',
    svcSat: 74.0,
    raSat: 86.0,
    rvSat: 86.0,
    paSat: 86.0,
    laSat: 98.0,
    lvSat: 98.0,
    aoSat: 98.0,
    shuntDirection: 'Left-to-Right (LA → RA)',
    stepUpChamber: 'Right Atrium (RA +12% O₂ Step-Up)',
    pearl: 'Oxygenated LA blood shunts across the fossa ovalis into the RA, causing a diagnostic >=7% O2 step-up from SVC (74%) to RA (86%) and wide fixed split S2.',
  ),
  membranousVsd(
    label: 'Membranous VSD (L→R Ventricular Shunt)',
    svcSat: 75.0,
    raSat: 75.0,
    rvSat: 87.0,
    paSat: 87.0,
    laSat: 98.0,
    lvSat: 98.0,
    aoSat: 98.0,
    shuntDirection: 'Left-to-Right (LV → RV)',
    stepUpChamber: 'Right Ventricle (RV +12% O₂ Step-Up)',
    pearl: 'High-pressure LV blood jets across the membranous septum into the RV, producing a harsh holosystolic murmur at the left lower sternal border and RV O2 step-up.',
  ),
  patentDuctusPda(
    label: 'Patent Ductus Arteriosus (PDA, Ao → PA)',
    svcSat: 75.0,
    raSat: 75.0,
    rvSat: 75.0,
    paSat: 86.0,
    laSat: 98.0,
    lvSat: 98.0,
    aoSat: 98.0,
    shuntDirection: 'Left-to-Right (Aorta → PA)',
    stepUpChamber: 'Pulmonary Artery (PA +11% O₂ Step-Up)',
    pearl: 'Continuous Aorta-to-PA flow through the persistence of the 6th aortic arch produces a continuous "machinery" murmur and isolated PA O2 step-up.',
  ),
  tetralogyOfFallot(
    label: 'Tetralogy of Fallot (R→L Cyanotic Shunt)',
    svcSat: 70.0,
    raSat: 70.0,
    rvSat: 71.0,
    paSat: 71.0,
    laSat: 98.0,
    lvSat: 83.0,
    aoSat: 81.0,
    shuntDirection: 'Right-to-Left (RV → Overriding Aorta)',
    stepUpChamber: 'Systemic Desaturation (Ao 81% Cyanosis)',
    pearl: 'PROVe (Pulmonic infundibular stenosis, RVH, Overriding aorta, VSD). Squatting increases SVR, driving blood into the lungs and relieving hypoxic "Tet spells".',
  ),
  eisenmengerSyndrome(
    label: 'Eisenmenger Syndrome (Reversed R→L Shunt)',
    svcSat: 68.0,
    raSat: 68.0,
    rvSat: 70.0,
    paSat: 70.0,
    laSat: 97.0,
    lvSat: 82.0,
    aoSat: 79.0,
    shuntDirection: 'Reversed Right-to-Left (PVR > SVR)',
    stepUpChamber: 'Late Cyanosis + Clubbing (Ao 79%)',
    pearl: 'Uncorrected chronic L→R shunt causes irreversible plexiform pulmonary arterial hypertension until PVR exceeds SVR, reversing the shunt to R→L.',
  );

  final String label;
  final double svcSat;
  final double raSat;
  final double rvSat;
  final double paSat;
  final double laSat;
  final double lvSat;
  final double aoSat;
  final String shuntDirection;
  final String stepUpChamber;
  final String pearl;

  const CongenitalShuntDefect({
    required this.label,
    required this.svcSat,
    required this.raSat,
    required this.rvSat,
    required this.paSat,
    required this.laSat,
    required this.lvSat,
    required this.aoSat,
    required this.shuntDirection,
    required this.stepUpChamber,
    required this.pearl,
  });

  double get qpQsRatio {
    // Fick equation: Qp/Qs = (SaO2 - SvO2) / (SpvO2 - SpaO2)
    final num = (aoSat - svcSat).clamp(1.0, 40.0);
    final den = (98.0 - paSat).clamp(4.0, 40.0);
    return num / den;
  }
}

enum ChdIntervention {
  none('Baseline Anatomy'),
  indomethacin('Indomethacin (COX Inhibitor → Closes PDA)'),
  alprostadilPge1('Prostaglandin E₁ (Alprostadil → Maintains PDA)'),
  kneeChestSquat('Knee-Chest Squatting (↑ SVR → Reverses Tet Spell)');

  final String label;
  const ChdIntervention(this.label);
}

// ============================================================================
// MODULE 6 MODELS: NEURO-CARDIOLOGY SYNCOPE & AUTONOMIC TILT-TABLE (ECG+EEG)
// ============================================================================

enum AutonomicTiltProfile {
  normalBaroreflex(
    label: 'Normal Baroreceptor Reflex',
    description: 'Carotid/aortic baroreceptors sense upright venous pooling and trigger α1 vasoconstriction + mild β1 HR rise (+12 bpm), preserving MAP & Alpha EEG.',
  ),
  vasovagalSyncope(
    label: 'Vasovagal (Neurocardiogenic) Syncope',
    description: 'Vigorous contraction of an underfilled LV triggers mechanoreceptor Bezold-Jarisch vagal surge → abrupt bradycardia + hypotension → Theta/Delta EEG slowing.',
  ),
  potsSyndrome(
    label: 'POTS (Postural Orthostatic Tachycardia)',
    description: 'Sustained heart rate increase >= 30 bpm (reaching > 120 bpm) upon 70° head-up tilt WITHOUT orthostatic hypotension; cerebral perfusion mildly borderline.',
  ),
  orthostaticHypotension(
    label: 'Neurogenic Orthostatic Hypotension',
    description: 'Impaired sympathetic α1 vasoconstriction (autonomic failure / α-blockers) causes SBP drop >= 20 mmHg and DBP drop >= 10 mmHg with blunted HR response.',
  ),
  carotidSinusHypersensitivity(
    label: 'Carotid Sinus Hypersensitivity (CN IX → CN X)',
    description: 'Exaggerated carotid baroreceptor reflex (triggered by tight collar / head turning) via Glossopharyngeal (CN IX) afferent to Vagus (CN X) efferent → cardioinhibitory sinus pause & syncope.',
  );

  final String label;
  final String description;
  const AutonomicTiltProfile({required this.label, required this.description});
}

// ============================================================================
// MAIN WIDGET: CARDIAC DIAGNOSTIC WORKSTATION PANEL
// ============================================================================

class CardiacDiagnosticWorkstationPanel extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase;
  final double bpm;
  final ValueChanged<double>? onBpmChanged;

  const CardiacDiagnosticWorkstationPanel({
    super.key,
    required this.scenario,
    required this.cardiacPhase,
    required this.bpm,
    this.onBpmChanged,
  });

  @override
  State<CardiacDiagnosticWorkstationPanel> createState() =>
      _CardiacDiagnosticWorkstationPanelState();
}

class _CardiacDiagnosticWorkstationPanelState
    extends State<CardiacDiagnosticWorkstationPanel> {
  CardiacDiagnosticModule _activeModule = CardiacDiagnosticModule.echoDoppler;

  // Module 1 State: Echo & Color Doppler
  EchoAcousticWindow _echoWindow = EchoAcousticWindow.plax;
  EchoHemodynamicPhenotype _echoPhenotype = EchoHemodynamicPhenotype.normal;
  bool _colorDopplerEnabled = true;
  bool _mModeCursorEnabled = true;

  // Module 2 State: Auscultation & PCG
  PrecordialListeningPost _listeningPost = PrecordialListeningPost.mitralApex;
  AuscultationSoundProfile _soundProfile = AuscultationSoundProfile.normalS1S2;
  BedsideManeuver _maneuver = BedsideManeuver.baseline;
  bool _audioPulseActive = false;
  bool _isBlindMurmurMode = false;
  int _blindMurmurIndex = 0;
  int? _blindMurmurSelectedChoice;
  bool _blindMurmurSubmitted = false;
  int _blindMurmurScoreCorrect = 0;
  int _blindMurmurScoreTotal = 0;

  static const List<AuscultationSoundProfile> _blindMurmurRotation = [
    AuscultationSoundProfile.aorticStenosis,
    AuscultationSoundProfile.hocmDynamic,
    AuscultationSoundProfile.mitralRegurg,
    AuscultationSoundProfile.mitralStenosis,
    AuscultationSoundProfile.asdFixedSplit,
  ];

  void _toggleBlindMurmurMode() {
    setState(() {
      _isBlindMurmurMode = !_isBlindMurmurMode;
      _blindMurmurSelectedChoice = null;
      _blindMurmurSubmitted = false;
      if (_isBlindMurmurMode) {
        _soundProfile = _blindMurmurRotation[_blindMurmurIndex % _blindMurmurRotation.length];
      }
    });
  }

  void _selectBlindMurmurOption(int index, AuscultationSoundProfile choice) {
    if (_blindMurmurSubmitted) return;
    setState(() {
      _blindMurmurSelectedChoice = index;
      _blindMurmurSubmitted = true;
      _blindMurmurScoreTotal++;
      if (choice == _soundProfile) {
        _blindMurmurScoreCorrect++;
      }
    });
  }

  void _nextBlindMurmur() {
    setState(() {
      _blindMurmurIndex++;
      _soundProfile = _blindMurmurRotation[_blindMurmurIndex % _blindMurmurRotation.length];
      _blindMurmurSelectedChoice = null;
      _blindMurmurSubmitted = false;
    });
  }

  // Module 3 State: EP Study, Arrhythmia & Pacemaker
  EpArrhythmiaState _epState = EpArrhythmiaState.normalSinus;
  PacemakerMode _pacerMode = PacemakerMode.off;
  bool _isRfAblated = false;

  // Module 4 State: LV P–V Loop & Heart Failure
  PvDrugPreset _pvDrug = PvDrugPreset.baseline;
  double _preloadEdv = 120.0;
  double _afterloadEa = 1.8;
  double _contractilityEmax = 2.0;

  // Module 5 State: Congenital Heart Disease & Oximetry Shunt
  CongenitalShuntDefect _chdDefect = CongenitalShuntDefect.secundumAsd;
  ChdIntervention _chdIntervention = ChdIntervention.none;

  // Module 6 State: Neuro-Cardiology Tilt-Table & EEG
  AutonomicTiltProfile _tiltProfile = AutonomicTiltProfile.vasovagalSyncope;
  double _tiltAngleDeg = 70.0;
  bool _counterManeuverActive = false;

  void _applyPvDrugPreset(PvDrugPreset preset) {
    setState(() {
      _pvDrug = preset;
      _preloadEdv = preset.preloadEdvMl;
      _afterloadEa = preset.afterloadEa;
      _contractilityEmax = preset.contractilityEmax;
    });
  }

  void _deliverRfAblation() {
    setState(() {
      _isRfAblated = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Radiofrequency Catheter Ablation (55°C, 35W) Delivered! Eliminated ${_epState.label} re-entrant pathway — Normal Sinus Rhythm restored.',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1722),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerStethoscopeAudioPulse() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    CardioCathThreeBridge.playHeartSoundCycle(
      splitMs: _soundProfile.baseA2P2SplitMs,
      s3Amp: _soundProfile.s3Intensity,
      s4Amp: _soundProfile.s4Intensity,
      sysMurmurAmp: _soundProfile.systolicMurmur,
      diasMurmurAmp: _soundProfile.diastolicMurmur,
    );
    setState(() => _audioPulseActive = !_audioPulseActive);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _activeModule.accent.withValues(alpha: 0.55),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _activeModule.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Workstation Header ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _activeModule.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _activeModule.accent.withValues(alpha: 0.5)),
                    ),
                    child: Icon(_activeModule.icon, color: _activeModule.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARDIOVASCULAR SCIENCES & CLINICAL DIAGNOSTIC WORKSTATION (6 MODULES)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        _activeModule.fullTitle,
                        style: TextStyle(
                          color: _activeModule.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CardiacInfoButton(
                    topicId: _activeModule.topicId,
                    customLabel: 'Module Guide & Pearls',
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 6-Module Selector Tabs ────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardiacDiagnosticModule.values.map((mod) {
              final isSel = mod == _activeModule;
              return ChoiceChip(
                avatar: Icon(
                  mod.icon,
                  size: 14,
                  color: isSel ? Colors.black : mod.accent,
                ),
                label: Text(mod.shortLabel),
                selected: isSel,
                selectedColor: mod.accent,
                backgroundColor: const Color(0xFF131C2B),
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide(
                  color: isSel ? mod.accent : mod.accent.withValues(alpha: 0.35),
                ),
                onSelected: (_) => setState(() => _activeModule = mod),
              );
            }).toList(),
          ),
          const Divider(color: Colors.white12, height: 22),

          // ── Active Module Body ────────────────────────────────────────────
          _buildActiveModuleContent(),
        ],
      ),
    );
  }

  Widget _buildActiveModuleContent() {
    switch (_activeModule) {
      case CardiacDiagnosticModule.echoDoppler:
        return _buildEchoDopplerModule();
      case CardiacDiagnosticModule.auscultationPcg:
        return _buildAuscultationPcgModule();
      case CardiacDiagnosticModule.epArrhythmia:
        return _buildEpArrhythmiaModule();
      case CardiacDiagnosticModule.pvLoopHf:
        return _buildPvLoopModule();
      case CardiacDiagnosticModule.congenitalChd:
        return _buildCongenitalChdModule();
      case CardiacDiagnosticModule.neuroTiltSyncope:
        return _buildNeuroTiltSyncopeModule();
    }
  }

  // ==========================================================================
  // MODULE 1: VIRTUAL 2D/3D ECHOCARDIOGRAPHY & COLOR FLOW DOPPLER LAB
  // ==========================================================================
  Widget _buildEchoDopplerModule() {
    final p = _echoPhenotype;
    final lvef = p.lvefPercent;
    final deltaP = p.bernoulliDeltaPMmHg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Acoustic Window Selector + Toggles
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Acoustic Probe Window:',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...EchoAcousticWindow.values.map((win) {
              final isSel = win == _echoWindow;
              return ChoiceChip(
                label: Text(win.label),
                selected: isSel,
                selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                backgroundColor: const Color(0xFF131C2B),
                labelStyle: TextStyle(
                  color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _echoWindow = win),
              );
            }),
            FilterChip(
              label: const Text('Color Doppler (BART)'),
              selected: _colorDopplerEnabled,
              selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
              backgroundColor: const Color(0xFF131C2B),
              labelStyle: TextStyle(
                color: _colorDopplerEnabled ? const Color(0xFF00E5FF) : Colors.white60,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (v) => setState(() => _colorDopplerEnabled = v),
            ),
            FilterChip(
              label: const Text('M-Mode Cursor'),
              selected: _mModeCursorEnabled,
              selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
              backgroundColor: const Color(0xFF131C2B),
              labelStyle: TextStyle(
                color: _mModeCursorEnabled ? const Color(0xFF10B981) : Colors.white60,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (v) => setState(() => _mModeCursorEnabled = v),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Hemodynamic Phenotype Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Pathology Phenotype: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...EchoHemodynamicPhenotype.values.map((ph) {
                final isSel = ph == _echoPhenotype;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(ph.label),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF00E5FF) : Colors.white60,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _echoPhenotype = ph),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Echo Sector + M-Mode / CW Doppler Canvas
        SizedBox(
          height: 270,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _EchoDopplerSectorPainter(
                window: _echoWindow,
                phenotype: _echoPhenotype,
                cardiacPhase: widget.cardiacPhase,
                colorDopplerEnabled: _colorDopplerEnabled,
                mModeEnabled: _mModeCursorEnabled,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Quantitative Echo & Bernoulli Telemetry Bar
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge(
              'LVEF ((EDV-ESV)/EDV)',
              '${lvef.toStringAsFixed(0)}% (${p.edvMl.round()}/${p.esvMl.round()} mL)',
              lvef >= 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            _metricBadge(
              'Bernoulli ΔP = 4v²',
              '${deltaP.toStringAsFixed(1)} mmHg (v = ${p.peakJetVelMs.toStringAsFixed(1)} m/s)',
              deltaP > 40 ? const Color(0xFFFFD600) : const Color(0xFF00E5FF),
            ),
            _metricBadge(
              'Mitral E/A Ratio',
              '${p.eaRatio.toStringAsFixed(2)} (E=${p.eWaveMs} / A=${p.aWaveMs} m/s)',
              const Color(0xFF38BDF8),
            ),
            _metricBadge(
              'EPSS / TAPSE',
              'EPSS ${p.epssMm} mm | TAPSE ${p.tapseMm.round()} mm',
              p.epssMm > 7.0 ? const Color(0xFFFFB300) : const Color(0xFF10B981),
            ),
            _metricBadge(
              'Probe & View',
              '${_echoWindow.probeSite} → ${_echoWindow.structuresViewed}',
              const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner(p.clinicalPearl, const Color(0xFF00E5FF)),
      ],
    );
  }

  // ==========================================================================
  // MODULE 2: CARDIAC AUSCULTATION & PHONOCARDIOGRAPHY (PCG) SIMULATOR
  // ==========================================================================
  Widget _buildAuscultationPcgModule() {
    // Compute dynamic maneuver modulation on murmur intensity & S2 split
    double maneuverMultiplier = 1.0;
    double splitDeltaMs = 0.0;
    if (_maneuver == BedsideManeuver.inspiration) {
      if (_soundProfile == AuscultationSoundProfile.asdFixedSplit) {
        splitDeltaMs = 0.0; // Fixed split!
      } else if (_soundProfile == AuscultationSoundProfile.lbbbParadoxical) {
        splitDeltaMs = 25.0; // Narrows negative split toward zero
      } else {
        splitDeltaMs = 20.0; // Normal physiologic widening
      }
      maneuverMultiplier = 1.15;
    } else if (_maneuver == BedsideManeuver.valsalva) {
      maneuverMultiplier = _soundProfile == AuscultationSoundProfile.hocmDynamic ? 1.55 : 0.55;
    } else if (_maneuver == BedsideManeuver.squatting) {
      maneuverMultiplier = _soundProfile == AuscultationSoundProfile.hocmDynamic ? 0.45 : 1.35;
    } else if (_maneuver == BedsideManeuver.handgrip) {
      if (_soundProfile == AuscultationSoundProfile.mitralRegurg) {
        maneuverMultiplier = 1.45;
      } else if (_soundProfile == AuscultationSoundProfile.hocmDynamic ||
          _soundProfile == AuscultationSoundProfile.aorticStenosis) {
        maneuverMultiplier = 0.60;
      }
    }

    final effectiveSplitMs = _soundProfile.baseA2P2SplitMs + splitDeltaMs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 Precordial Listening Posts + Audio Stethoscope Trigger
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Stethoscope Chest Post:',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...PrecordialListeningPost.values.map((post) {
              final isSel = post == _listeningPost;
              return ChoiceChip(
                avatar: Icon(
                  Icons.hearing_rounded,
                  size: 13,
                  color: isSel ? Colors.black : const Color(0xFF10B981),
                ),
                label: Text('${post.title} (${post.anatomicalLocation})'),
                selected: isSel,
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF131C2B),
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) => setState(() => _listeningPost = post),
              );
            }),
            ActionChip(
              avatar: Icon(
                _audioPulseActive ? Icons.volume_up_rounded : Icons.headphones_rounded,
                size: 14,
                color: const Color(0xFFFFD600),
              ),
              label: Text(
                _audioPulseActive ? 'Stethoscope Audio: ON' : 'Pulse Acoustic Bell/Diaphragm',
                style: const TextStyle(color: Color(0xFFFFD600), fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFFFD600).withValues(alpha: 0.15),
              side: const BorderSide(color: Color(0xFFFFD600)),
              onPressed: _triggerStethoscopeAudioPulse,
            ),
            ActionChip(
              avatar: Icon(
                _isBlindMurmurMode ? Icons.school_rounded : Icons.quiz_rounded,
                size: 14,
                color: _isBlindMurmurMode ? Colors.black : const Color(0xFF10B981),
              ),
              label: Text(
                _isBlindMurmurMode ? 'Exit Blind Exam' : '🎯 Blind Murmur Exam',
                style: TextStyle(
                  color: _isBlindMurmurMode ? Colors.black : const Color(0xFF10B981),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _isBlindMurmurMode
                  ? const Color(0xFF10B981)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              side: const BorderSide(color: Color(0xFF10B981)),
              onPressed: _toggleBlindMurmurMode,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Heart Sound / Murmur Pathology Selector or Blind Murmur Quiz
        if (_isBlindMurmurMode)
          _buildBlindMurmurQuizCard()
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Heart Sound / Murmur: ',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                ...AuscultationSoundProfile.values.map((prof) {
                  final isSel = prof == _soundProfile;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(prof.label),
                      selected: isSel,
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF131C2B),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF10B981) : Colors.white70,
                        fontSize: 10.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _soundProfile = prof),
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Dynamic Bedside Maneuvers
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Bedside Maneuver: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...BedsideManeuver.values.map((m) {
                final isSel = m == _maneuver;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(m.label),
                    selected: isSel,
                    selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFFFD600) : Colors.white60,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _maneuver = m),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Phonocardiogram (PCG) + Chest Post Map Canvas
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _PhonocardiogramPainter(
                post: _listeningPost,
                profile: _soundProfile,
                maneuver: _maneuver,
                maneuverMultiplier: maneuverMultiplier,
                effectiveSplitMs: effectiveSplitMs,
                cardiacPhase: widget.cardiacPhase,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge(
              'A2–P2 Split Interval',
              '${effectiveSplitMs.abs().round()} ms ${effectiveSplitMs < 0 ? "(Reversed P2→A2)" : "(Normal A2→P2)"}',
              const Color(0xFF10B981),
            ),
            _metricBadge(
              'Maneuver Modulation',
              '${(maneuverMultiplier * 100).round()}% Amplitude (${_maneuver.label})',
              maneuverMultiplier > 1.1 ? const Color(0xFFFFD600) : const Color(0xFF00E5FF),
            ),
            _metricBadge(
              'Gallop Sounds',
              'S3: ${_soundProfile.s3Intensity > 0 ? "PRESENT" : "Absent"} | S4: ${_soundProfile.s4Intensity > 0 ? "PRESENT" : "Absent"}',
              const Color(0xFFF43F5E),
            ),
            _metricBadge(
              'Active Chest Post',
              '${_listeningPost.title}: ${_listeningPost.primaryFindings}',
              const Color(0xFF38BDF8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner(
          '${_soundProfile.description} • Maneuver Effect: ${_maneuver.physiologyEffect}',
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildBlindMurmurQuizCard() {
    final options = [
      AuscultationSoundProfile.aorticStenosis,
      AuscultationSoundProfile.hocmDynamic,
      AuscultationSoundProfile.mitralRegurg,
      AuscultationSoundProfile.mitralStenosis,
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BLIND AUSCULTATION: CASE #${_blindMurmurIndex + 1}',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Score: $_blindMurmurScoreCorrect / $_blindMurmurScoreTotal',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.skip_next_rounded, size: 13),
                label: const Text('Next Unknown Murmur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _nextBlindMurmur,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Test the murmur with Bedside Maneuvers below (Valsalva, Squatting, Handgrip) and examine PCG changes to deduce the pathology:',
            style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(options.length, (idx) {
              final opt = options[idx];
              final isSel = _blindMurmurSelectedChoice == idx;
              final isCorrect = opt == _soundProfile;
              Color bg = const Color(0xFF162030);
              Color border = Colors.white24;
              Color textCol = Colors.white70;

              if (_blindMurmurSubmitted) {
                if (isCorrect) {
                  bg = const Color(0xFF00E676).withValues(alpha: 0.25);
                  border = const Color(0xFF00E676);
                  textCol = const Color(0xFF00E676);
                } else if (isSel) {
                  bg = const Color(0xFFFF1744).withValues(alpha: 0.25);
                  border = const Color(0xFFFF1744);
                  textCol = const Color(0xFFFF5252);
                }
              } else if (isSel) {
                bg = const Color(0xFF00E5FF).withValues(alpha: 0.25);
                border = const Color(0xFF00E5FF);
                textCol = Colors.white;
              }

              final letters = ['A', 'B', 'C', 'D'];

              return InkWell(
                onTap: () => _selectBlindMurmurOption(idx, opt),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: border, width: isSel || (_blindMurmurSubmitted && isCorrect) ? 1.4 : 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${letters[idx]}. ',
                        style: TextStyle(
                          color: isSel || (_blindMurmurSubmitted && isCorrect) ? textCol : Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: textCol,
                          fontSize: 9.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (_blindMurmurSubmitted && isCorrect) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 13),
                      ],
                      if (_blindMurmurSubmitted && isSel && !isCorrect) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.cancel_rounded, color: Color(0xFFFF1744), size: 13),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_blindMurmurSubmitted) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: options[_blindMurmurSelectedChoice!] == _soundProfile
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : const Color(0xFFFF9100).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: options[_blindMurmurSelectedChoice!] == _soundProfile
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF9100),
                ),
              ),
              child: Text(
                options[_blindMurmurSelectedChoice!] == _soundProfile
                    ? '🎯 CORRECT! ${_soundProfile.label}: ${_soundProfile.description}'
                    : '❌ INCORRECT. Correct Diagnosis: ${_soundProfile.label}. Note how ${_maneuver.label} impacts waveform amplitude: ${_maneuver.physiologyEffect}',
                style: TextStyle(
                  color: options[_blindMurmurSelectedChoice!] == _soundProfile
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFFD600),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // MODULE 3: ELECTROPHYSIOLOGY (EP) STUDY, ARRHYTHMIA & PACEMAKER LAB
  // ==========================================================================
  Widget _buildEpArrhythmiaModule() {
    final effectiveEp = _isRfAblated && _epState.ablatable
        ? EpArrhythmiaState.normalSinus
        : _epState;
    final effectiveHr = _pacerMode != PacemakerMode.off && effectiveEp.rateBpm < 60
        ? 72
        : effectiveEp.rateBpm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Arrhythmia Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Arrhythmia / Conduction Circuit: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...EpArrhythmiaState.values.map((st) {
                final isSel = st == _epState;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(st.label),
                    selected: isSel,
                    selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.28),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFFFD600) : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _epState = st;
                        _isRfAblated = false;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // RF Catheter Ablation + Pacemaker Controls
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(
                _isRfAblated ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
                size: 15,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRfAblated
                    ? const Color(0xFF10B981)
                    : (_epState.ablatable ? const Color(0xFFEF4444) : Colors.white24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _epState.ablatable && !_isRfAblated ? _deliverRfAblation : null,
              label: Text(
                _isRfAblated
                    ? 'RF Catheter Ablation Complete (Sinus Restored)'
                    : 'Deliver RF Catheter Ablation (55°C / 35W)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const Text(
              'Pacemaker Mode:',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...PacemakerMode.values.map((pm) {
              final isSel = pm == _pacerMode;
              return ChoiceChip(
                label: Text(pm.label),
                selected: isSel,
                selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                backgroundColor: const Color(0xFF131C2B),
                labelStyle: TextStyle(
                  color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _pacerMode = pm),
              );
            }),
            if (_epState.hergLinked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA78BFA)),
                ),
                child: const Text(
                  'Linked to CardioNephroGNN hERG (IKr) Blockade',
                  style: TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // 4-Channel Intracardiac Electrogram (HRA, His, CS, RVA) + Surface ECG Canvas
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _EpIntracardiacEgmPainter(
                epState: effectiveEp,
                pacerMode: _pacerMode,
                isAblated: _isRfAblated,
                cardiacPhase: widget.cardiacPhase,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge('Ventricular Rate', '$effectiveHr bpm', const Color(0xFF10B981)),
            _metricBadge('PA Interval', '${effectiveEp.paMs} ms (Norm 25–55)', const Color(0xFF38BDF8)),
            _metricBadge(
              'AH Interval (AV Node)',
              '${effectiveEp.ahMs} ms (Norm 50–120)',
              effectiveEp.ahMs > 120 ? const Color(0xFFFFD600) : const Color(0xFF00E5FF),
            ),
            _metricBadge(
              'HV Interval (His-Purkinje)',
              '${effectiveEp.hvMs} ms (Norm 35–55)',
              effectiveEp.hvMs < 35 || effectiveEp.hvMs > 55
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
            _metricBadge(
              'QTc (Bazett)',
              '${effectiveEp.qtcMs} ms',
              effectiveEp.qtcMs >= 500 ? const Color(0xFFEF4444) : const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner(effectiveEp.mechanism, const Color(0xFFFFD600)),
      ],
    );
  }

  // ==========================================================================
  // MODULE 4: LEFT VENTRICULAR PRESSURE-VOLUME (P–V) LOOP & HEART FAILURE LAB
  // ==========================================================================
  Widget _buildPvLoopModule() {
    // Sagawa Elastance Equations:
    // ESV = V0 + ESP / Emax, where ESP ≈ Ea * SV => SV = (EDV - V0) * Emax / (Emax + Ea)
    const v0 = 10.0;
    final sv = ((_preloadEdv - v0) * _contractilityEmax / (_contractilityEmax + _afterloadEa))
        .clamp(20.0, 125.0);
    final esv = (_preloadEdv - sv).clamp(15.0, 180.0);
    final esp = (sv * _afterloadEa).clamp(60.0, 220.0);
    final edp = 3.0 + 0.8 * math.exp(0.022 * _preloadEdv);
    final lvef = (sv / _preloadEdv) * 100.0;
    final strokeWorkMmHgMl = sv * (esp * 0.82 - edp);
    final pvaIndex = strokeWorkMmHgMl + 0.5 * (esv - v0) * esp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pharmacology Challenge Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Pharmacology Challenge: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...PvDrugPreset.values.map((preset) {
                final isSel = preset == _pvDrug;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: isSel,
                    selectedColor: const Color(0xFFF43F5E).withValues(alpha: 0.28),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFF43F5E) : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _applyPvDrugPreset(preset),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Interactive Preload, Afterload, Contractility Sliders
        Row(
          children: [
            Expanded(
              child: _compactSlider(
                label: 'Preload (EDV)',
                valueText: '${_preloadEdv.round()} mL',
                value: _preloadEdv,
                min: 75.0,
                max: 190.0,
                color: const Color(0xFF38BDF8),
                onChanged: (v) => setState(() => _preloadEdv = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _compactSlider(
                label: 'Afterload (Ea)',
                valueText: '${_afterloadEa.toStringAsFixed(2)} mmHg/mL',
                value: _afterloadEa,
                min: 1.0,
                max: 3.2,
                color: const Color(0xFFFFB300),
                onChanged: (v) => setState(() => _afterloadEa = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _compactSlider(
                label: 'Contractility (Emax)',
                valueText: '${_contractilityEmax.toStringAsFixed(2)} mmHg/mL',
                value: _contractilityEmax,
                min: 0.8,
                max: 3.6,
                color: const Color(0xFFF43F5E),
                onChanged: (v) => setState(() => _contractilityEmax = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // P–V Loop Canvas
        SizedBox(
          height: 265,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _PvLoopPainter(
                edv: _preloadEdv,
                esv: esv,
                esp: esp,
                edp: edp,
                emax: _contractilityEmax,
                ea: _afterloadEa,
                cardiacPhase: widget.cardiacPhase,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge('EDV / ESV', '${_preloadEdv.round()} mL / ${esv.round()} mL', const Color(0xFF38BDF8)),
            _metricBadge('Stroke Volume (SV)', '${sv.round()} mL/beat', const Color(0xFF10B981)),
            _metricBadge(
              'LVEF%',
              '${lvef.toStringAsFixed(0)}%',
              lvef >= 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            _metricBadge('Peak LVESP / LVEDP', '${esp.round()} / ${edp.round()} mmHg', const Color(0xFFF43F5E)),
            _metricBadge('Stroke Work / PVA (MVO₂)', '${(strokeWorkMmHgMl / 1000).toStringAsFixed(1)}k / ${(pvaIndex / 1000).toStringAsFixed(1)}k mmHg·mL', const Color(0xFFFFD600)),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner(_pvDrug.rationale, const Color(0xFFF43F5E)),
      ],
    );
  }

  // ==========================================================================
  // MODULE 5: CONGENITAL HEART DISEASE (CHD) & OXIMETRY SHUNT LAB
  // ==========================================================================
  Widget _buildCongenitalChdModule() {
    // Adjust oximetry if pharmacological/bedside intervention is active
    CongenitalShuntDefect effectiveDefect = _chdDefect;
    String interventionNote = 'Baseline Congenital Hemodynamics';
    if (_chdDefect == CongenitalShuntDefect.patentDuctusPda &&
        _chdIntervention == ChdIntervention.indomethacin) {
      effectiveDefect = CongenitalShuntDefect.normalAdult;
      interventionNote =
          'Indomethacin inhibited PGE2 synthesis → Ductus Arteriosus CLOSED (PA O2 step-up eliminated, Qp/Qs restored to 1.00)!';
    } else if (_chdIntervention == ChdIntervention.alprostadilPge1) {
      interventionNote =
          'Prostaglandin E1 (Alprostadil) infusion active → maintains ductal patency for ductal-dependent systemic/pulmonary flow.';
    } else if (_chdDefect == CongenitalShuntDefect.tetralogyOfFallot &&
        _chdIntervention == ChdIntervention.kneeChestSquat) {
      interventionNote =
          'Knee-Chest Squatting kinked femoral arteries (↑ SVR) → reduced R→L VSD shunting, raising Aortic SaO2 from 81% to 92%!';
    }

    final aoSatDisplay = (_chdDefect == CongenitalShuntDefect.tetralogyOfFallot &&
            _chdIntervention == ChdIntervention.kneeChestSquat)
        ? 92.0
        : effectiveDefect.aoSat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Congenital Lesion Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Congenital Defect: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...CongenitalShuntDefect.values.map((def) {
                final isSel = def == _chdDefect;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(def.label),
                    selected: isSel,
                    selectedColor: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFA78BFA) : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _chdDefect = def;
                        _chdIntervention = ChdIntervention.none;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Pharmacological & Bedside Shunt Interventions
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Intervention / Pharmacology: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...ChdIntervention.values.map((intv) {
                final isSel = intv == _chdIntervention;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(intv.label),
                    selected: isSel,
                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF10B981) : Colors.white60,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _chdIntervention = intv),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4-Chamber Oximetry & Shunt Flow Map Canvas
        SizedBox(
          height: 255,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _ChdOximetryShuntPainter(
                defect: effectiveDefect,
                aoSatOverride: aoSatDisplay,
                cardiacPhase: widget.cardiacPhase,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge(
              'Qp / Qs Shunt Ratio',
              effectiveDefect.qpQsRatio.toStringAsFixed(2),
              effectiveDefect.qpQsRatio > 1.4
                  ? const Color(0xFFFFD600)
                  : (effectiveDefect.qpQsRatio < 0.85
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981)),
            ),
            _metricBadge('Diagnostic O₂ Step-Up', effectiveDefect.stepUpChamber, const Color(0xFF00E5FF)),
            _metricBadge(
              'Right Heart (SVC/RA/RV/PA)',
              '${effectiveDefect.svcSat.round()}% → ${effectiveDefect.raSat.round()}% → ${effectiveDefect.rvSat.round()}% → ${effectiveDefect.paSat.round()}%',
              const Color(0xFF38BDF8),
            ),
            _metricBadge(
              'Left Heart (LA/LV/Aorta)',
              '${effectiveDefect.laSat.round()}% → ${effectiveDefect.lvSat.round()}% → ${aoSatDisplay.round()}%',
              aoSatDisplay < 90 ? const Color(0xFFA78BFA) : const Color(0xFFF43F5E),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner('${effectiveDefect.pearl} • $interventionNote', const Color(0xFFA78BFA)),
      ],
    );
  }

  // ==========================================================================
  // MODULE 6: NEURO-CARDIOLOGY SYNCOPE & AUTONOMIC TILT-TABLE (ECG + EEG)
  // ==========================================================================
  Widget _buildNeuroTiltSyncopeModule() {
    final tiltFrac = (_tiltAngleDeg / 70.0).clamp(0.0, 1.0);
    final counterBoost = _counterManeuverActive ? 1.0 : 0.0;

    double sbp = 120.0;
    double dbp = 78.0;
    double hr = 72.0;
    String eegBand = 'Alpha (8–12 Hz Awake)';

    switch (_tiltProfile) {
      case AutonomicTiltProfile.normalBaroreflex:
        sbp = 118.0 - 4.0 * tiltFrac + 6.0 * counterBoost;
        dbp = 78.0 + 5.0 * tiltFrac + 4.0 * counterBoost;
        hr = 72.0 + 12.0 * tiltFrac;
        eegBand = 'Alpha (8–12 Hz Normal Cortical Perfusion)';
        break;
      case AutonomicTiltProfile.vasovagalSyncope:
        sbp = 120.0 - 62.0 * tiltFrac + 38.0 * counterBoost;
        dbp = 78.0 - 38.0 * tiltFrac + 22.0 * counterBoost;
        hr = 72.0 - 30.0 * tiltFrac + 22.0 * counterBoost;
        eegBand = (sbp < 75.0)
            ? 'Theta/Delta Slowing (1–4 Hz Cerebral Hypoperfusion!)'
            : 'Alpha (8–12 Hz Restored by Counter-Pressure)';
        break;
      case AutonomicTiltProfile.potsSyndrome:
        sbp = 116.0 - 5.0 * tiltFrac + 5.0 * counterBoost;
        dbp = 76.0 + 2.0 * tiltFrac;
        hr = 75.0 + 48.0 * tiltFrac - 18.0 * counterBoost;
        eegBand = 'Fast Beta / Alpha (Mild Orthostatic Lightheadedness)';
        break;
      case AutonomicTiltProfile.orthostaticHypotension:
        sbp = 122.0 - 38.0 * tiltFrac + 20.0 * counterBoost;
        dbp = 78.0 - 20.0 * tiltFrac + 12.0 * counterBoost;
        hr = 70.0 + 4.0 * tiltFrac; // Blunted neurogenic HR response
        eegBand = (sbp < 90.0)
            ? 'Theta Slowing (4–7 Hz Borderline Cortical Perfusion)'
            : 'Alpha (8–12 Hz Awake)';
        break;
      case AutonomicTiltProfile.carotidSinusHypersensitivity:
        sbp = 118.0 - 55.0 * tiltFrac + 34.0 * counterBoost;
        dbp = 76.0 - 34.0 * tiltFrac + 20.0 * counterBoost;
        hr = 70.0 - 34.0 * tiltFrac + 24.0 * counterBoost;
        eegBand = (sbp < 75.0)
            ? 'Theta/Delta Slowing (CN IX → X Cardioinhibitory Pause!)'
            : 'Alpha (8–12 Hz Restored)';
        break;
    }

    final map = dbp + (sbp - dbp) / 3.0;
    final cpp = (map - 12.0).clamp(20.0, 100.0); // Cerebral Perfusion Pressure

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Autonomic Profile Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Autonomic Syndrome: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              ...AutonomicTiltProfile.values.map((prof) {
                final isSel = prof == _tiltProfile;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(prof.label),
                    selected: isSel,
                    selectedColor: const Color(0xFFFB923C).withValues(alpha: 0.28),
                    backgroundColor: const Color(0xFF131C2B),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFFB923C) : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _tiltProfile = prof),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tilt Table Angle Slider + Counter-Pressure Maneuver
        Row(
          children: [
            Expanded(
              child: _compactSlider(
                label: 'Head-Up Tilt Angle (HUTT)',
                valueText: '${_tiltAngleDeg.round()}° (${_tiltAngleDeg < 15 ? "Supine" : "Head-Up Tilt"})',
                value: _tiltAngleDeg,
                min: 0.0,
                max: 70.0,
                color: const Color(0xFFFB923C),
                onChanged: (v) => setState(() => _tiltAngleDeg = v),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              avatar: const Icon(Icons.accessibility_new_rounded, size: 15, color: Color(0xFF10B981)),
              label: Text(
                _counterManeuverActive
                    ? 'Leg-Cross Counter-Pressure: ACTIVE'
                    : 'Leg-Cross Counter-Pressure Maneuver',
              ),
              selected: _counterManeuverActive,
              selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
              backgroundColor: const Color(0xFF131C2B),
              labelStyle: TextStyle(
                color: _counterManeuverActive ? const Color(0xFF10B981) : Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (v) => setState(() => _counterManeuverActive = v),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tilt-Table + Coupled ECG + Frontal EEG Canvas
        SizedBox(
          height: 255,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _NeuroTiltEegPainter(
                profile: _tiltProfile,
                tiltAngleDeg: _tiltAngleDeg,
                sbp: sbp,
                dbp: dbp,
                hr: hr,
                cpp: cpp,
                cardiacPhase: widget.cardiacPhase,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _metricBadge(
              'Arterial BP (MAP)',
              '${sbp.round()}/${dbp.round()} mmHg (MAP ${map.round()})',
              sbp < 90 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
            _metricBadge(
              'Heart Rate (Orthostatic)',
              '${hr.round()} bpm',
              hr >= 110 || hr < 50 ? const Color(0xFFFFD600) : const Color(0xFF00E5FF),
            ),
            _metricBadge(
              'Cerebral Perfusion (CPP)',
              '${cpp.round()} mmHg',
              cpp < 50 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
            ),
            _metricBadge(
              'Frontal EEG Rhythm',
              eegBand,
              cpp < 50 ? const Color(0xFFFF1744) : const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _clinicalPearlBanner(_tiltProfile.description, const Color(0xFFFB923C)),
      ],
    );
  }

  // ==========================================================================
  // SHARED UI HELPERS
  // ==========================================================================

  Widget _metricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicalPearlBanner(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(valueText, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white24,
              thumbColor: color,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAINTER 1: VIRTUAL ECHOCARDIOGRAPHY SECTOR, COLOR DOPPLER & M-MODE / CW
// ============================================================================

class _EchoDopplerSectorPainter extends CustomPainter {
  final EchoAcousticWindow window;
  final EchoHemodynamicPhenotype phenotype;
  final double cardiacPhase;
  final bool colorDopplerEnabled;
  final bool mModeEnabled;

  _EchoDopplerSectorPainter({
    required this.window,
    required this.phenotype,
    required this.cardiacPhase,
    required this.colorDopplerEnabled,
    required this.mModeEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF060A10);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Split screen: Left 56% = 2D Sector + Color Doppler, Right 44% = M-Mode & CW Spectral Doppler
    final leftWidth = size.width * 0.54;
    final rightStart = leftWidth + 10;
    final rightWidth = size.width - rightStart - 8;

    // 1. Draw Phased-Array Ultrasound Sector Cone on Left
    final apex = Offset(leftWidth * 0.5, 22);
    final sectorRadius = math.min(leftWidth * 0.85, size.height - 34);
    const startAngle = math.pi * 0.28;
    const sweepAngle = math.pi * 0.44;

    final sectorPath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..arcTo(
        Rect.fromCircle(center: apex, radius: sectorRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    canvas.save();
    canvas.clipPath(sectorPath);

    // Ultrasound speckle background gradient
    final sectorGrad = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.8),
        radius: 1.2,
        colors: [
          const Color(0xFF1E293B),
          const Color(0xFF0F172A),
          const Color(0xFF05080D),
        ],
      ).createShader(Rect.fromCircle(center: apex, radius: sectorRadius));
    canvas.drawPath(sectorPath, sectorGrad);

    // Systolic contraction factor (0.26..0.52 is systole)
    final isSystole = cardiacPhase >= 0.26 && cardiacPhase <= 0.52;
    final contraction = isSystole
        ? math.sin(((cardiacPhase - 0.26) / 0.26) * math.pi)
        : 0.0;

    // Scale LV cavity by phenotype
    final lvDilation = phenotype == EchoHemodynamicPhenotype.hfref ? 1.32 : 1.0;
    final wallThick = (phenotype == EchoHemodynamicPhenotype.hfpef ||
            phenotype == EchoHemodynamicPhenotype.hocm ||
            phenotype == EchoHemodynamicPhenotype.severeAs)
        ? 11.0
        : 6.5;

    final chamberCenter = Offset(apex.dx, apex.dy + sectorRadius * 0.58);
    final lvRx = (46.0 * lvDilation) * (1.0 - 0.22 * contraction * (phenotype.lvefPercent / 60.0));
    final lvRy = (32.0 * lvDilation) * (1.0 - 0.18 * contraction * (phenotype.lvefPercent / 60.0));

    // Myocardial walls (hyperechoic grey-white)
    final wallPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = wallThick;

    if (window == EchoAcousticWindow.psax) {
      // PSAX Donut Short-Axis View
      canvas.drawCircle(chamberCenter, lvRy, wallPaint);
      // RV Crescent anteriorly
      final rvPath = Path()
        ..addArc(
          Rect.fromCircle(center: chamberCenter.translate(-14, -18), radius: lvRy * 0.9),
          math.pi * 0.85,
          math.pi * 0.75,
        );
      canvas.drawPath(rvPath, wallPaint..strokeWidth = 4.5);
    } else {
      // PLAX / A4C / Subcostal 4-Chamber / Long-Axis View
      canvas.drawOval(
        Rect.fromCenter(center: chamberCenter, width: lvRx * 2, height: lvRy * 2),
        wallPaint,
      );
      // Interventricular septum line
      final septPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = phenotype == EchoHemodynamicPhenotype.hocm ? 13.0 : wallThick;
      canvas.drawLine(
        Offset(chamberCenter.dx - lvRx * 0.75, chamberCenter.dy - lvRy * 0.65),
        Offset(chamberCenter.dx + lvRx * 0.65, chamberCenter.dy - lvRy * 0.45),
        septPaint,
      );

      // Mitral & Aortic Valve Leaflets
      final mvOpen = !isSystole ? 12.0 : (phenotype == EchoHemodynamicPhenotype.hocm ? -6.0 : 2.0);
      final leafletPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(chamberCenter.dx + 14, chamberCenter.dy - 12),
        Offset(chamberCenter.dx + 2, chamberCenter.dy - 2 + mvOpen),
        leafletPaint,
      );
    }

    // Color Flow Doppler BART Jet Overlay
    if (colorDopplerEnabled) {
      final isAliasing = phenotype.peakJetVelMs > 2.5 ||
          phenotype == EchoHemodynamicPhenotype.severeMr;
      final jetColor = isSystole
          ? (isAliasing ? const Color(0xFFFFEA00) : const Color(0xFF00B0FF)) // Blue Away in systole + yellow aliasing
          : const Color(0xFFFF1744); // Red Toward in diastole

      final jetPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            jetColor.withValues(alpha: 0.85),
            (isAliasing ? const Color(0xFF00E5FF) : jetColor).withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: chamberCenter, radius: 42));
      canvas.drawCircle(
        chamberCenter.translate(isSystole ? 12 : -8, isSystole ? -10 : 6),
        isSystole ? 32 : 28,
        jetPaint,
      );
    }

    // M-Mode interrogation line
    if (mModeEnabled) {
      final cursorPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.8)
        ..strokeWidth = 1.2;
      canvas.drawLine(apex, Offset(apex.dx, apex.dy + sectorRadius), cursorPaint);
    }

    canvas.restore();

    // Sector Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(sectorPath, borderPaint);

    // BART Color Bar Legend (Top Left)
    if (colorDopplerEnabled) {
      const barRect = Rect.fromLTWH(14, 34, 10, 70);
      final bartGrad = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEA00), Color(0xFFFF1744), Colors.black, Color(0xFF00B0FF), Color(0xFF00E5FF)],
        ).createShader(barRect);
      canvas.drawRect(barRect, bartGrad);
      _drawLabel(canvas, '+${phenotype.peakJetVelMs.toStringAsFixed(1)} m/s', const Offset(28, 32), const Color(0xFFFF5252), 9);
      _drawLabel(canvas, 'BART', const Offset(28, 62), Colors.white70, 8.5);
      _drawLabel(canvas, '-${phenotype.peakJetVelMs.toStringAsFixed(1)} m/s', const Offset(28, 92), const Color(0xFF00E5FF), 9);
    }

    _drawLabel(
      canvas,
      '2D ECHO SECTOR: ${window.label} • ${phenotype.colorJetType}',
      const Offset(12, 8),
      const Color(0xFF00E5FF),
      10,
    );

    // 2. Right Top: M-Mode Septal & Mitral Anterior Leaflet Sweep (EPSS)
    final mModeRect = Rect.fromLTWH(rightStart, 26, rightWidth, 95);
    canvas.drawRect(mModeRect, Paint()..color = const Color(0xFF0B131E));
    canvas.drawRect(
      mModeRect,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke,
    );
    _drawLabel(
      canvas,
      'M-MODE TIME-MOTION (EPSS = ${phenotype.epssMm} mm | TAPSE = ${phenotype.tapseMm.round()} mm)',
      Offset(rightStart + 6, 8),
      const Color(0xFF10B981),
      9.5,
    );

    final septPath = Path();
    final mvMModePath = Path();
    for (int i = 0; i <= 100; i++) {
      final u = i / 100.0;
      final x = mModeRect.left + u * mModeRect.width;
      final ph = (u * 2.0) % 1.0;
      final sysWave = (ph >= 0.26 && ph <= 0.52)
          ? math.sin(((ph - 0.26) / 0.26) * math.pi)
          : 0.0;
      final septY = mModeRect.top + 22 + 10.0 * sysWave * (phenotype.lvefPercent / 60.0);

      // Mitral E-wave & A-wave anterior excursion in diastole
      double mvExcursion = 0.0;
      if (ph >= 0.56 && ph <= 0.74) {
        mvExcursion = 22.0 * (phenotype.eWaveMs / 1.0) * math.sin(((ph - 0.56) / 0.18) * math.pi);
      } else if (ph >= 0.78 && ph <= 0.94) {
        mvExcursion = 18.0 * (phenotype.aWaveMs / 0.8) * math.sin(((ph - 0.78) / 0.16) * math.pi);
      }
      final mvY = mModeRect.bottom - 18 - mvExcursion + (phenotype.epssMm * 0.6);

      if (i == 0) {
        septPath.moveTo(x, septY);
        mvMModePath.moveTo(x, mvY);
      } else {
        septPath.lineTo(x, septY);
        mvMModePath.lineTo(x, mvY);
      }
    }
    canvas.drawPath(
      septPath,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawPath(
      mvMModePath,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 3. Right Bottom: Spectral Doppler (Mitral E/A Inflow & CW Jet ΔP = 4v²)
    final cwRect = Rect.fromLTWH(rightStart, 146, rightWidth, 112);
    canvas.drawRect(cwRect, Paint()..color = const Color(0xFF0B131E));
    canvas.drawRect(
      cwRect,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke,
    );
    _drawLabel(
      canvas,
      'SPECTRAL DOPPLER: E/A = ${phenotype.eaRatio.toStringAsFixed(2)} | CW ΔP = 4v² = ${phenotype.bernoulliDeltaPMmHg.toStringAsFixed(1)} mmHg',
      Offset(rightStart + 6, 128),
      const Color(0xFFFFD600),
      9.5,
    );

    final zeroY = cwRect.top + cwRect.height * 0.45;
    canvas.drawLine(
      Offset(cwRect.left, zeroY),
      Offset(cwRect.right, zeroY),
      Paint()..color = Colors.white24,
    );

    final dopplerPath = Path()..moveTo(cwRect.left, zeroY);
    for (int i = 0; i <= 120; i++) {
      final u = i / 120.0;
      final x = cwRect.left + u * cwRect.width;
      final ph = (u * 2.0) % 1.0;
      double y = zeroY;

      if (ph >= 0.28 && ph <= 0.52) {
        // Systolic CW outflow jet (downward below baseline)
        final tau = (ph - 0.28) / 0.24;
        // HOCM has late-peaking "dagger" shape; AS has symmetric parabolic shape
        final shape = phenotype == EchoHemodynamicPhenotype.hocm
            ? math.pow(tau, 2.2) * math.sin(tau * math.pi)
            : math.sin(tau * math.pi);
        y = zeroY + (phenotype.peakJetVelMs / 5.2) * 52.0 * shape;
      } else if (ph >= 0.58 && ph <= 0.75) {
        // Diastolic Mitral E-wave (upward above baseline)
        final tau = (ph - 0.58) / 0.17;
        y = zeroY - (phenotype.eWaveMs / 1.5) * 38.0 * math.sin(tau * math.pi);
      } else if (ph >= 0.79 && ph <= 0.94) {
        // Diastolic Mitral A-wave (upward above baseline)
        final tau = (ph - 0.79) / 0.15;
        y = zeroY - (phenotype.aWaveMs / 1.5) * 38.0 * math.sin(tau * math.pi);
      }
      dopplerPath.lineTo(x, y);
    }
    canvas.drawPath(
      dopplerPath,
      Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _EchoDopplerSectorPainter oldDelegate) => true;
}

// ============================================================================
// PAINTER 2: CARDIAC AUSCULTATION & PHONOCARDIOGRAM (PCG)
// ============================================================================

class _PhonocardiogramPainter extends CustomPainter {
  final PrecordialListeningPost post;
  final AuscultationSoundProfile profile;
  final BedsideManeuver maneuver;
  final double maneuverMultiplier;
  final double effectiveSplitMs;
  final double cardiacPhase;

  _PhonocardiogramPainter({
    required this.post,
    required this.profile,
    required this.maneuver,
    required this.maneuverMultiplier,
    required this.effectiveSplitMs,
    required this.cardiacPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF060B11));

    // Left 28%: Precordial 4-Post Chest Map
    final chestW = size.width * 0.27;
    final chestRect = Rect.fromLTWH(8, 8, chestW - 12, size.height - 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0D1520),
    );

    _drawText(canvas, 'PRECORDIAL POSTS', const Offset(16, 14), const Color(0xFF10B981), 9.5);

    // Sternum & Rib landmarks
    final sternumX = chestRect.center.dx - 6;
    canvas.drawLine(
      Offset(sternumX, chestRect.top + 35),
      Offset(sternumX, chestRect.bottom - 20),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 4,
    );

    final postOffsets = <PrecordialListeningPost, Offset>{
      PrecordialListeningPost.aortic: Offset(sternumX - 24, chestRect.top + 62),
      PrecordialListeningPost.pulmonic: Offset(sternumX + 24, chestRect.top + 62),
      PrecordialListeningPost.tricuspid: Offset(sternumX + 22, chestRect.top + 125),
      PrecordialListeningPost.mitralApex: Offset(sternumX + 58, chestRect.top + 165),
    };

    postOffsets.forEach((p, offset) {
      final isSel = p == post;
      canvas.drawCircle(
        offset,
        isSel ? 12 : 8,
        Paint()
          ..color = isSel
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : Colors.white12,
      );
      canvas.drawCircle(
        offset,
        isSel ? 6 : 4,
        Paint()..color = isSel ? const Color(0xFF10B981) : Colors.white54,
      );
      _drawText(
        canvas,
        p.title.split(' ').first,
        Offset(offset.dx - 18, offset.dy + 13),
        isSel ? const Color(0xFF10B981) : Colors.white54,
        8.5,
      );
    });

    // Right 72%: Synchronized Wiggers Lead II ECG (Top) + Phonocardiogram Acoustic Waveform (Bottom)
    final traceLeft = chestW + 8;
    final traceWidth = size.width - traceLeft - 12;

    _drawText(
      canvas,
      'WIGGERS SYNCHRONIZED ECG & PHONOCARDIOGRAM (PCG): ${profile.label}',
      Offset(traceLeft, 10),
      const Color(0xFF00E5FF),
      10,
    );

    final ecgZeroY = 68.0;
    final pcgZeroY = 175.0;

    // Baseline grid
    canvas.drawLine(
      Offset(traceLeft, pcgZeroY),
      Offset(traceLeft + traceWidth, pcgZeroY),
      Paint()..color = Colors.white12,
    );

    final ecgPath = Path();
    final pcgPath = Path();

    final splitPhiDelta = (effectiveSplitMs / 800.0).clamp(-0.08, 0.08);

    for (int i = 0; i <= 240; i++) {
      final u = i / 240.0;
      final x = traceLeft + u * traceWidth;
      final phi = (u * 2.0) % 1.0;

      // 1. ECG Lead II trace
      double ecgMv = 0.0;
      if (phi >= 0.10 && phi <= 0.20) {
        ecgMv = 0.18 * math.sin(((phi - 0.10) / 0.10) * math.pi);
      } else if (phi >= 0.25 && phi <= 0.29) {
        ecgMv = 1.15 * math.sin(((phi - 0.25) / 0.04) * math.pi);
      } else if (phi >= 0.42 && phi <= 0.56) {
        ecgMv = 0.30 * math.sin(((phi - 0.42) / 0.14) * math.pi);
      }
      final ecgY = ecgZeroY - ecgMv * 32.0;

      // 2. High-Frequency Acoustic Phonocardiogram (PCG)
      double pcgAmp = 0.0;
      final carrier = math.sin(u * 220.0 * math.pi);

      // S1 (M1 + T1 at phi ~ 0.28..0.33)
      if (phi >= 0.27 && phi <= 0.33) {
        final env = math.sin(((phi - 0.27) / 0.06) * math.pi);
        pcgAmp += 0.90 * env * carrier;
      }

      // A2 (at phi ~ 0.56) and P2 (at phi ~ 0.56 + splitPhiDelta)
      const a2Phi = 0.56;
      final p2Phi = 0.56 + splitPhiDelta;
      if ((phi - a2Phi).abs() <= 0.022) {
        final env = math.cos(((phi - a2Phi) / 0.022) * math.pi * 0.5);
        pcgAmp += 0.78 * env * carrier;
      }
      if ((phi - p2Phi).abs() <= 0.022) {
        final env = math.cos(((phi - p2Phi) / 0.022) * math.pi * 0.5);
        pcgAmp += 0.68 * env * carrier;
      }

      // S3 Ventricular Gallop (early diastole phi ~ 0.66)
      if (profile.s3Intensity > 0 && (phi - 0.66).abs() <= 0.025) {
        final env = math.cos(((phi - 0.66) / 0.025) * math.pi * 0.5);
        pcgAmp += profile.s3Intensity * env * carrier;
      }

      // S4 Atrial Gallop (late diastole / presystole phi ~ 0.18)
      if (profile.s4Intensity > 0 && (phi - 0.18).abs() <= 0.025) {
        final env = math.cos(((phi - 0.18) / 0.025) * math.pi * 0.5);
        pcgAmp += profile.s4Intensity * env * carrier;
      }

      // Systolic Murmur (between S1 and S2: phi 0.33..0.55)
      if (profile.systolicMurmur > 0 && phi > 0.33 && phi < 0.55) {
        final tau = (phi - 0.33) / 0.22;
        final shape = profile == AuscultationSoundProfile.mitralRegurg
            ? 0.85 // Holosystolic plateau
            : math.sin(tau * math.pi); // Diamond crescendo-decrescendo
        pcgAmp += profile.systolicMurmur * maneuverMultiplier * shape * math.sin(u * 340.0 * math.pi);
      }

      // Diastolic Murmur (Mitral Stenosis Opening Snap + Rumble: phi 0.62..0.90)
      if (profile.diastolicMurmur > 0 && phi >= 0.61 && phi <= 0.90) {
        final isOpeningSnap = (phi - 0.62).abs() <= 0.015;
        final rumble = 0.55 * profile.diastolicMurmur * maneuverMultiplier;
        pcgAmp += (isOpeningSnap ? 0.85 : rumble) * carrier;
      }

      final pcgY = pcgZeroY - (pcgAmp.clamp(-1.3, 1.3)) * 46.0;

      if (i == 0) {
        ecgPath.moveTo(x, ecgY);
        pcgPath.moveTo(x, pcgY);
      } else {
        ecgPath.lineTo(x, ecgY);
        pcgPath.lineTo(x, pcgY);
      }
    }

    canvas.drawPath(
      ecgPath,
      Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawPath(
      pcgPath,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Sound Labels along PCG
    _drawText(canvas, 'S4', Offset(traceLeft + traceWidth * 0.09, pcgZeroY - 54), const Color(0xFFF43F5E), 9.5);
    _drawText(canvas, 'S1 (M1/T1)', Offset(traceLeft + traceWidth * 0.14, pcgZeroY - 54), Colors.white, 9.5);
    _drawText(canvas, 'A2 / P2', Offset(traceLeft + traceWidth * 0.27, pcgZeroY - 54), const Color(0xFF00E5FF), 9.5);
    _drawText(canvas, 'S3', Offset(traceLeft + traceWidth * 0.33, pcgZeroY - 54), const Color(0xFFFFD600), 9.5);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PhonocardiogramPainter oldDelegate) => true;
}

// ============================================================================
// PAINTER 3: ELECTROPHYSIOLOGY (EP) INTRACARDIAC ELECTROGRAMS & PACEMAKER
// ============================================================================

class _EpIntracardiacEgmPainter extends CustomPainter {
  final EpArrhythmiaState epState;
  final PacemakerMode pacerMode;
  final bool isAblated;
  final double cardiacPhase;

  _EpIntracardiacEgmPainter({
    required this.epState,
    required this.pacerMode,
    required this.isAblated,
    required this.cardiacPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF05090F));

    final channels = [
      ('SURFACE ECG II', const Color(0xFF00E676), 42.0),
      ('HRA (High Right Atrium)', const Color(0xFF38BDF8), 96.0),
      ('HIS Bundle (A–H–V)', const Color(0xFFFFD600), 150.0),
      ('CS (Coronary Sinus)', const Color(0xFFA78BFA), 200.0),
      ('RVA (RV Apex)', const Color(0xFFF43F5E), 240.0),
    ];

    for (final ch in channels) {
      _drawText(canvas, ch.$1, Offset(10, ch.$3 - 18), ch.$2, 9.5);
      canvas.drawLine(
        Offset(155, ch.$3),
        Offset(size.width - 12, ch.$3),
        Paint()..color = Colors.white10,
      );
    }

    final startX = 155.0;
    final width = size.width - startX - 14.0;

    for (int chIdx = 0; chIdx < channels.length; chIdx++) {
      final baseY = channels[chIdx].$3;
      final color = channels[chIdx].$2;
      final path = Path()..moveTo(startX, baseY);

      for (int i = 0; i <= 220; i++) {
        final u = i / 220.0;
        final x = startX + u * width;
        final phi = (u * 2.5) % 1.0;
        double dy = 0.0;

        if (chIdx == 0) {
          // Surface Lead II ECG
          if (epState == EpArrhythmiaState.torsadesHerg) {
            // Polymorphic twisting QRS envelope around baseline
            final env = math.sin(u * 3.0 * math.pi);
            dy = -26.0 * env * math.sin(u * 34.0 * math.pi);
          } else if (epState == EpArrhythmiaState.atrialFlutter) {
            // Sawtooth F-waves + QRS
            dy = -8.0 * ((phi * 4.0) % 1.0 - 0.5);
            if ((phi - 0.28).abs() < 0.025) dy -= 26.0;
          } else {
            // P wave
            if (phi >= 0.10 && phi <= 0.18) {
              dy -= 6.0 * math.sin(((phi - 0.10) / 0.08) * math.pi);
            }
            // Pacemaker atrial/ventricular spikes
            if (pacerMode == PacemakerMode.ddd && (phi - 0.09).abs() < 0.008) {
              dy -= 22.0;
            }
            if (pacerMode != PacemakerMode.off && (phi - 0.24).abs() < 0.008) {
              dy -= 24.0;
            }
            // WPW Slurred Delta wave upstroke
            if (epState == EpArrhythmiaState.wpwSyndrome && phi >= 0.19 && phi < 0.26) {
              dy -= 18.0 * ((phi - 0.19) / 0.07);
            }
            // QRS
            if ((phi - 0.27).abs() <= 0.025) {
              dy -= 28.0 * math.cos(((phi - 0.27) / 0.025) * math.pi * 0.5);
            }
            // T wave
            if (phi >= 0.42 && phi <= 0.58) {
              dy -= 9.0 * math.sin(((phi - 0.42) / 0.16) * math.pi);
            }
          }
        } else if (chIdx == 1) {
          // HRA Atrial Electrogram (A-wave spike at phi = 0.12)
          if ((phi - 0.12).abs() <= 0.015) {
            dy = -18.0 * math.sin(((phi - 0.12) / 0.015) * math.pi);
          }
        } else if (chIdx == 2) {
          // HIS Bundle: A (0.14), H (0.21), V (0.27)
          final hPhi = epState == EpArrhythmiaState.avnrt ? 0.24 : 0.21;
          final vPhi = epState == EpArrhythmiaState.wpwSyndrome ? 0.23 : 0.27;
          if ((phi - 0.14).abs() <= 0.012) dy = -12.0;
          if ((phi - hPhi).abs() <= 0.010) dy = -16.0;
          if ((phi - vPhi).abs() <= 0.014) dy = -20.0;
        } else if (chIdx == 3) {
          // Coronary Sinus (CS): A and V signals (eccentric/fused in WPW)
          final csVPhi = epState == EpArrhythmiaState.wpwSyndrome ? 0.19 : 0.28;
          if ((phi - 0.15).abs() <= 0.012) dy = -14.0;
          if ((phi - csVPhi).abs() <= 0.014) dy = -16.0;
        } else {
          // RVA (Right Ventricular Apex): sharp V deflection at 0.27
          if ((phi - 0.27).abs() <= 0.016) {
            dy = -20.0 * math.sin(((phi - 0.27) / 0.016) * math.pi);
          }
        }

        path.lineTo(x, baseY + dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _EpIntracardiacEgmPainter oldDelegate) => true;
}

// ============================================================================
// PAINTER 4: LEFT VENTRICULAR PRESSURE-VOLUME (P–V) LOOP & SAGAWA ELASTANCE
// ============================================================================

class _PvLoopPainter extends CustomPainter {
  final double edv;
  final double esv;
  final double esp;
  final double edp;
  final double emax;
  final double ea;
  final double cardiacPhase;

  _PvLoopPainter({
    required this.edv,
    required this.esv,
    required this.esp,
    required this.edp,
    required this.emax,
    required this.ea,
    required this.cardiacPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF060B12));

    const padLeft = 52.0;
    const padBottom = 30.0;
    const padTop = 22.0;
    const padRight = 24.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;

    Offset toCanvas(double volMl, double pressMmHg) {
      final x = padLeft + (volMl / 200.0).clamp(0.0, 1.0) * plotW;
      final y = (size.height - padBottom) - (pressMmHg / 220.0).clamp(0.0, 1.0) * plotH;
      return Offset(x, y);
    }

    // Axes
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(padLeft, padTop), Offset(padLeft, size.height - padBottom), axisPaint);
    canvas.drawLine(
      Offset(padLeft, size.height - padBottom),
      Offset(size.width - padRight, size.height - padBottom),
      axisPaint,
    );

    _drawText(canvas, 'LV Pressure (0–220 mmHg)', const Offset(12, 6), Colors.white70, 9.5);
    _drawText(
      canvas,
      'LV Volume (0–200 mL) • Dashed = Normal Control | Solid = Active P–V Loop',
      Offset(padLeft + 10, size.height - 18),
      Colors.white70,
      9.5,
    );

    // 1. EDPVR Curve (Exponential passive filling curve)
    final edpvrPath = Path();
    for (int v = 10; v <= 195; v += 5) {
      final p = 3.0 + 0.8 * math.exp(0.022 * v);
      final pt = toCanvas(v.toDouble(), p);
      if (v == 10) {
        edpvrPath.moveTo(pt.dx, pt.dy);
      } else {
        edpvrPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      edpvrPath,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 2. ESPVR Line (Linear Emax slope from V0 = 10 mL)
    final espvrStart = toCanvas(10.0, 0.0);
    final espvrEnd = toCanvas(10.0 + 210.0 / emax, 210.0);
    canvas.drawLine(
      espvrStart,
      espvrEnd,
      Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.75)
        ..strokeWidth = 1.8,
    );
    _drawText(
      canvas,
      'ESPVR (Emax=${emax.toStringAsFixed(2)})',
      Offset(espvrEnd.dx + 6, espvrEnd.dy + 4),
      const Color(0xFFF43F5E),
      9,
    );

    // 3. Normal Control Reference Loop (EDV 120, ESV 50, ESP 120)
    final refRect = Path()
      ..moveTo(toCanvas(50, 8).dx, toCanvas(50, 8).dy)
      ..lineTo(toCanvas(120, 12).dx, toCanvas(120, 12).dy)
      ..lineTo(toCanvas(120, 80).dx, toCanvas(120, 80).dy)
      ..quadraticBezierTo(
        toCanvas(85, 132).dx,
        toCanvas(85, 132).dy,
        toCanvas(50, 115).dx,
        toCanvas(50, 115).dy,
      )
      ..close();
    canvas.drawPath(
      refRect,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 4. Active Dynamic P–V Loop
    final pA = toCanvas(esv, edp * 0.7); // Mitral Opens
    final pB = toCanvas(edv, edp); // Mitral Closes (End-Diastole)
    final pC = toCanvas(edv, esp * 0.68); // Aortic Opens
    final pPeak = toCanvas((edv + esv) * 0.5, esp * 1.08); // Peak Systolic Pressure
    final pD = toCanvas(esv, esp * 0.92); // Aortic Closes (End-Systole)

    final loopPath = Path()
      ..moveTo(pA.dx, pA.dy)
      ..quadraticBezierTo(toCanvas((esv + edv) * 0.5, edp * 0.75).dx, toCanvas((esv + edv) * 0.5, edp * 0.75).dy, pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..quadraticBezierTo(pPeak.dx, pPeak.dy, pD.dx, pD.dy)
      ..close();

    canvas.drawPath(
      loopPath,
      Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      loopPath,
      Paint()
        ..color = const Color(0xFFF43F5E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );

    // Valve Event Corner Markers
    for (final marker in [
      (pA, 'MO', const Color(0xFF38BDF8)),
      (pB, 'MC (EDV)', const Color(0xFF10B981)),
      (pC, 'AO', const Color(0xFFFFD600)),
      (pD, 'AC (ESV)', const Color(0xFFF43F5E)),
    ]) {
      canvas.drawCircle(marker.$1, 4.0, Paint()..color = marker.$3);
      _drawText(canvas, marker.$2, marker.$1.translate(5, -10), marker.$3, 8.5);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PvLoopPainter oldDelegate) => true;
}

// ============================================================================
// PAINTER 5: CONGENITAL HEART DISEASE (CHD) OXIMETRY & SHUNT MAP
// ============================================================================

class _ChdOximetryShuntPainter extends CustomPainter {
  final CongenitalShuntDefect defect;
  final double aoSatOverride;
  final double cardiacPhase;

  _ChdOximetryShuntPainter({
    required this.defect,
    required this.aoSatOverride,
    required this.cardiacPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF060B12));

    _drawText(
      canvas,
      'FICK OXIMETRY RUN & INTRACARDIAC SHUNT TELEMETRY: ${defect.shuntDirection}',
      const Offset(12, 8),
      const Color(0xFFA78BFA),
      10,
    );

    final cx = size.width * 0.5;
    final cy = size.height * 0.54;

    // Draw 4 Chambers + Great Vessels
    final raRect = Rect.fromCenter(center: Offset(cx - 95, cy - 28), width: 110, height: 64);
    final rvRect = Rect.fromCenter(center: Offset(cx - 95, cy + 52), width: 110, height: 68);
    final laRect = Rect.fromCenter(center: Offset(cx + 95, cy - 28), width: 110, height: 64);
    final lvRect = Rect.fromCenter(center: Offset(cx + 95, cy + 52), width: 110, height: 68);

    final paRect = Rect.fromCenter(center: Offset(cx - 55, cy - 92), width: 95, height: 34);
    final aoRect = Rect.fromCenter(center: Offset(cx + 55, cy - 92), width: 95, height: 34);

    _drawChamberBox(canvas, raRect, 'RA', defect.raSat, const Color(0xFF38BDF8));
    _drawChamberBox(canvas, rvRect, 'RV', defect.rvSat, const Color(0xFF38BDF8));
    _drawChamberBox(canvas, laRect, 'LA', defect.laSat, const Color(0xFFF43F5E));
    _drawChamberBox(canvas, lvRect, 'LV', defect.lvSat, const Color(0xFFF43F5E));
    _drawChamberBox(canvas, paRect, 'PA', defect.paSat, const Color(0xFF00B0FF));
    _drawChamberBox(canvas, aoRect, 'Aorta', aoSatOverride, aoSatOverride < 90 ? const Color(0xFFA78BFA) : const Color(0xFFFF5252));

    // Draw Animated Shunt Jet Arrow between chambers
    if (defect == CongenitalShuntDefect.secundumAsd) {
      _drawShuntArrow(canvas, laRect.centerLeft, raRect.centerRight, const Color(0xFFFF5252), 'ASD L→R');
    } else if (defect == CongenitalShuntDefect.membranousVsd) {
      _drawShuntArrow(canvas, lvRect.centerLeft, rvRect.centerRight, const Color(0xFFFF5252), 'VSD L→R');
    } else if (defect == CongenitalShuntDefect.patentDuctusPda) {
      _drawShuntArrow(canvas, aoRect.centerLeft, paRect.centerRight, const Color(0xFFFFD600), 'PDA Ao→PA');
    } else if (defect == CongenitalShuntDefect.tetralogyOfFallot ||
        defect == CongenitalShuntDefect.eisenmengerSyndrome) {
      _drawShuntArrow(canvas, rvRect.centerRight, lvRect.centerLeft, const Color(0xFFA78BFA), 'R→L CYANOTIC');
    }
  }

  void _drawChamberBox(Canvas canvas, Rect rect, String name, double sat, Color accent) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _drawText(canvas, '$name: ${sat.round()}% SaO₂', Offset(rect.left + 10, rect.center.dy - 6), Colors.white, 10.5);
  }

  void _drawShuntArrow(Canvas canvas, Offset from, Offset to, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    // Animated bolus dot along shunt
    final p = Offset.lerp(from, to, cardiacPhase)!;
    canvas.drawCircle(p, 5.5, Paint()..color = Colors.white);
    _drawText(canvas, label, Offset((from.dx + to.dx) * 0.5 - 28, (from.dy + to.dy) * 0.5 - 16), color, 9.5);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ChdOximetryShuntPainter oldDelegate) => true;
}

// ============================================================================
// PAINTER 6: NEURO-CARDIOLOGY TILT-TABLE & COUPLED ECG + FRONTAL EEG
// ============================================================================

class _NeuroTiltEegPainter extends CustomPainter {
  final AutonomicTiltProfile profile;
  final double tiltAngleDeg;
  final double sbp;
  final double dbp;
  final double hr;
  final double cpp;
  final double cardiacPhase;

  _NeuroTiltEegPainter({
    required this.profile,
    required this.tiltAngleDeg,
    required this.sbp,
    required this.dbp,
    required this.hr,
    required this.cpp,
    required this.cardiacPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF060A10));

    // Left 26%: Motorized Tilt-Table Inclination Schematic
    final leftW = size.width * 0.25;
    final pivot = Offset(leftW * 0.5, size.height * 0.58);
    final rad = -tiltAngleDeg * math.pi / 180.0;

    // Pedestal
    canvas.drawLine(
      pivot,
      Offset(pivot.dx, size.height - 22),
      Paint()
        ..color = Colors.white30
        ..strokeWidth = 5,
    );

    // Tilting Table + Patient Vector
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(rad);
    canvas.drawLine(
      const Offset(-52, 0),
      const Offset(52, 0),
      Paint()
        ..color = const Color(0xFFFB923C)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Head circle at right end of table
    canvas.drawCircle(
      const Offset(42, -9),
      7,
      Paint()..color = cpp < 50 ? const Color(0xFFEF4444) : const Color(0xFF00E5FF),
    );
    canvas.restore();

    _drawText(canvas, 'HUTT: ${tiltAngleDeg.round()}°', const Offset(14, 10), const Color(0xFFFB923C), 10);
    _drawText(canvas, 'CPP: ${cpp.round()} mmHg', Offset(14, size.height - 20), const Color(0xFF38BDF8), 9.5);

    // Right 74%: Coupled Arterial BP + ECG + Frontal Cortical EEG (Fp1–Fp2)
    final rightX = leftW + 10;
    final rightW = size.width - rightX - 12;

    final traces = [
      ('BEAT-TO-BEAT ARTERIAL BP (${sbp.round()}/${dbp.round()} mmHg)', const Color(0xFFEF4444), 56.0),
      ('AUTONOMIC ECG LEAD II (${hr.round()} bpm)', const Color(0xFF00E676), 132.0),
      ('FRONTAL CORTICAL EEG (Fp1–Fp2): ${cpp < 50 ? "THETA/DELTA HYPOPERFUSION SLOWING" : "AWAKE ALPHA 8–12 Hz"}', const Color(0xFFA78BFA), 210.0),
    ];

    for (int idx = 0; idx < traces.length; idx++) {
      final t = traces[idx];
      _drawText(canvas, t.$1, Offset(rightX, t.$3 - 26), t.$2, 9.5);
      final path = Path();

      for (int i = 0; i <= 200; i++) {
        final u = i / 200.0;
        final x = rightX + u * rightW;
        final cycles = (hr / 72.0) * 2.5;
        final phi = (u * cycles) % 1.0;
        double y = t.$3;

        if (idx == 0) {
          // Arterial BP wave scaled by SBP/DBP
          final pulse = (phi >= 0.28 && phi <= 0.56)
              ? math.sin(((phi - 0.28) / 0.28) * math.pi)
              : 0.25 * math.exp(-2.0 * phi);
          final p = dbp + (sbp - dbp) * pulse;
          y = t.$3 + 18.0 - ((p - 40.0) / 100.0) * 32.0;
        } else if (idx == 1) {
          // ECG trace
          double mv = 0.0;
          if ((phi - 0.27).abs() < 0.025) mv = 1.0;
          if (phi >= 0.42 && phi <= 0.56) mv = 0.25;
          y = t.$3 - mv * 24.0;
        } else {
          // Frontal EEG: Alpha (10 Hz low amplitude) vs Theta/Delta slowing (2.5 Hz high amplitude) when CPP < 50
          if (cpp < 50.0) {
            y = t.$3 - 18.0 * math.sin(u * 14.0 * math.pi) - 6.0 * math.cos(u * 9.0 * math.pi);
          } else {
            y = t.$3 - 7.0 * math.sin(u * 56.0 * math.pi) * (0.7 + 0.3 * math.cos(u * 8.0 * math.pi));
          }
        }

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = t.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _NeuroTiltEegPainter oldDelegate) => true;
}
