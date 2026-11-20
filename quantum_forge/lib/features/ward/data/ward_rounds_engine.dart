// ============================================================================
// WardRounds 3D: Undifferentiated ER/ICU Clinical Reasoning Engine
// ----------------------------------------------------------------------------
// Simulates acute undifferentiated bedside emergencies for MBBS, Pharm-D,
// and USMLE Step 1/2/3 students. Connects cross-organ vitals from
// CardioCath 3D, NeuroLab 3D, NephroLab 3D, and PulmoVent 3D.
//
// 8 High-Yield Cases with Hidden Diagnoses & Socratic Safety Interceptions:
// 1. Obstructive Shock — Cardiac Tamponade (Beck's Triad)
// 2. Obstructive Shock — Left Tension Pneumothorax
// 3. Cardiogenic Shock — Inferior STEMI with RV Infarction
// 4. Distributive Shock — Septic Shock + ARDS
// 5. Severe DKA + Hyperkalemic ECG Crisis
// 6. Neurogenic Emergency — Ruptured ACom Aneurysm + Cushing Triad
// 7. Toxicology Crisis — Organophosphate Cholinergic Toxidrome (SLUDGEM)
// 8. Pharmacogenomic Crisis — CYP2D6 Ultra-Rapid Metabolizer / Torsades
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

enum WardPocusWindow {
  subxiphoid4Chamber('Subxiphoid 4-Chamber', 'Pericardial effusion & RV diastolic collapse'),
  parasternalLong('Parasternal Long Axis (PLAX)', 'LV contractility, chamber sizes & aortic root'),
  ivcLongitudinal('IVC Longitudinal', 'Diameter & respiratory collapsibility index %'),
  anteriorLung('Anterior Lung Zones', 'A-lines vs B-lines, lung sliding & M-mode'),
  ruqMorison('RUQ Morison\'s Pouch', 'Hepatorenal space free fluid anechoic stripe');

  final String title;
  final String subtitle;
  const WardPocusWindow(this.title, this.subtitle);
}

enum PocusUltrasoundMode { bMode2D, mModeMotion }

enum BedsideOrderCategory { statLabs, ivFluids, medications, proceduresAirway }

class WardBedsideOrder {
  final String id;
  final String name;
  final BedsideOrderCategory category;
  final String description;
  final bool isContraindicated;
  final String? contraindicationReason;

  const WardBedsideOrder({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.isContraindicated = false,
    this.contraindicationReason,
  });
}

class PocusFindings {
  final String subxiphoidDescription;
  final bool hasPericardialEffusion;
  final double effusionDepthMm;
  final bool hasRvDiastolicCollapse;

  final String plaxDescription;
  final double lvefEstimated;

  final String ivcDescription;
  final double ivcDiameterMm;
  final double collapsibilityIndexPct;
  final bool isPlethoric;

  final String lungDescription;
  final bool hasLungSliding;
  final bool hasBLines;
  final bool isStratosphereBarcodeSign;

  final String morisonDescription;
  final bool hasFreeFluid;
  final double freeFluidStripeMm;

  const PocusFindings({
    required this.subxiphoidDescription,
    this.hasPericardialEffusion = false,
    this.effusionDepthMm = 0.0,
    this.hasRvDiastolicCollapse = false,
    required this.plaxDescription,
    this.lvefEstimated = 55.0,
    required this.ivcDescription,
    this.ivcDiameterMm = 18.0,
    this.collapsibilityIndexPct = 50.0,
    this.isPlethoric = false,
    required this.lungDescription,
    this.hasLungSliding = true,
    this.hasBLines = false,
    this.isStratosphereBarcodeSign = false,
    required this.morisonDescription,
    this.hasFreeFluid = false,
    this.freeFluidStripeMm = 0.0,
  });
}

class WardBedsideCase {
  final int caseNumber;
  final String triageId;
  final String demographic;
  final String chiefComplaint;
  final String triageStory;
  final String physicalExamSummary;

  // Initial vitals
  final double initialHr;
  final double initialSbp;
  final double initialDbp;
  final double initialRr;
  final double initialSpo2;
  final double initialTempC;
  final int initialGcs;
  final String initialEcgRhythm;

  // Hidden truths revealed upon submission
  final String hiddenDiagnosis;
  final String primaryOrganDomain; // 'Cardiovascular', 'Pulmonary', 'Nephrology', 'Neurology', 'Pharmacology'
  final String pathophysiologyMechanism;
  final String usmlePearl;
  final String remediationRoute; // '/cardiac', '/pulmo', '/neuro', '/nephro', etc.

  // Diagnostic & POCUS profiles
  final PocusFindings pocusFindings;
  final List<String> differentialOptions;
  final List<String> correctDdxRanking; // top 3
  final List<String> mandatoryOrderIds;
  final Map<String, String> contraindicationMap; // orderId -> rationale

  const WardBedsideCase({
    required this.caseNumber,
    required this.triageId,
    required this.demographic,
    required this.chiefComplaint,
    required this.triageStory,
    required this.physicalExamSummary,
    required this.initialHr,
    required this.initialSbp,
    required this.initialDbp,
    required this.initialRr,
    required this.initialSpo2,
    required this.initialTempC,
    required this.initialGcs,
    required this.initialEcgRhythm,
    required this.hiddenDiagnosis,
    required this.primaryOrganDomain,
    required this.pathophysiologyMechanism,
    required this.usmlePearl,
    required this.remediationRoute,
    required this.pocusFindings,
    required this.differentialOptions,
    required this.correctDdxRanking,
    required this.mandatoryOrderIds,
    required this.contraindicationMap,
  });
}

class WardRoundsEngine extends ChangeNotifier {
  static final WardRoundsEngine instance = WardRoundsEngine._internal();
  WardRoundsEngine._internal() {
    _loadCase(0);
  }
  factory WardRoundsEngine() => instance;

  final MultiOrganPatientState multiOrganState = MultiOrganPatientState.instance;

  int _currentCaseIndex = 0;
  int get currentCaseIndex => _currentCaseIndex;

  late WardBedsideCase _activeCase;
  WardBedsideCase get activeCase => _activeCase;

  // Bedside POCUS State
  WardPocusWindow _activePocusWindow = WardPocusWindow.subxiphoid4Chamber;
  WardPocusWindow get activePocusWindow => _activePocusWindow;

  PocusUltrasoundMode _ultrasoundMode = PocusUltrasoundMode.bMode2D;
  PocusUltrasoundMode get ultrasoundMode => _ultrasoundMode;

  bool _showLandmarkTags = true;
  bool get showLandmarkTags => _showLandmarkTags;

  // Encounter Timer
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;
  Timer? _caseTimer;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // Differential Diagnoses (Top 3 slots)
  final List<String?> _top3Ddx = [null, null, null];
  List<String?> get top3Ddx => List.unmodifiable(_top3Ddx);

  // Evidence tags selected by user
  final Set<String> _selectedEvidenceTags = {};
  Set<String> get selectedEvidenceTags => Set.unmodifiable(_selectedEvidenceTags);

  // Orders placed in encounter
  final List<WardBedsideOrder> _placedOrders = [];
  List<WardBedsideOrder> get placedOrders => List.unmodifiable(_placedOrders);

  // Safety & Socratic Attending Interception
  String? _activeSafetyAlertTitle;
  String? _activeSafetyAlertRationale;
  bool get hasActiveSafetyAlert => _activeSafetyAlertTitle != null;
  String? get activeSafetyAlertTitle => _activeSafetyAlertTitle;
  String? get activeSafetyAlertRationale => _activeSafetyAlertRationale;

  // Encounter completion & scoring
  bool _isCaseSubmitted = false;
  bool get isCaseSubmitted => _isCaseSubmitted;

  bool _isPatientStabilized = false;
  bool get isPatientStabilized => _isPatientStabilized;

  double _finalEncounterScore = 0.0;
  double get finalEncounterScore => _finalEncounterScore;

  // Domain score tracking across sessions
  final Map<String, List<double>> _domainScores = {
    'Cardiovascular': [84.0, 90.0],
    'Neurology': [78.0, 82.0],
    'Nephrology & Acid-Base': [88.0, 85.0],
    'Pulmonology & Critical Care': [75.0, 80.0],
    'Pharmacology & Toxicology': [92.0, 88.0],
    'Emergency & POCUS Diagnostics': [80.0, 86.0],
  };

  Map<String, double> get aggregateDomainMastery {
    final result = <String, double>{};
    for (final entry in _domainScores.entries) {
      if (entry.value.isEmpty) {
        result[entry.key] = 75.0;
      } else {
        final sum = entry.value.reduce((a, b) => a + b);
        result[entry.key] = (sum / entry.value.length).clamp(0.0, 100.0);
      }
    }
    return result;
  }

  // Curated catalog of bedside orders
  static const List<WardBedsideOrder> catalogOrders = [
    // Stat Labs
    WardBedsideOrder(
      id: 'stat_abg',
      name: 'Stat Arterial Blood Gas (ABG)',
      category: BedsideOrderCategory.statLabs,
      description: 'Measures pH, PaCO2, PaO2, HCO3, and Base Excess within 3 minutes.',
    ),
    WardBedsideOrder(
      id: 'stat_lactate',
      name: 'Stat Serum Lactate',
      category: BedsideOrderCategory.statLabs,
      description: 'Assesses tissue hypoperfusion and anaerobic cellular metabolism.',
    ),
    WardBedsideOrder(
      id: 'stat_ecg',
      name: 'Stat 12-Lead ECG',
      category: BedsideOrderCategory.statLabs,
      description: 'Records limb & precordial leads for ischemia, arrhythmogenesis, and alternans.',
    ),
    WardBedsideOrder(
      id: 'stat_cmp',
      name: 'Stat Chem-7 / CMP & Electrolytes',
      category: BedsideOrderCategory.statLabs,
      description: 'Assesses K+, Na+, Cl-, BUN, Creatinine, Glucose, and Anion Gap.',
    ),

    // IV Resuscitation Fluids
    WardBedsideOrder(
      id: 'iv_crystalloid_bolus',
      name: 'IV Crystalloid Bolus (1000 mL Normal Saline)',
      category: BedsideOrderCategory.ivFluids,
      description: 'Rapid isotonic volume expansion to restore RV preload and intravascular volume.',
    ),
    WardBedsideOrder(
      id: 'iv_balanced_crystalloid',
      name: 'IV Balanced Crystalloid (30 mL/kg Lactated Ringer\'s)',
      category: BedsideOrderCategory.ivFluids,
      description: 'Standard sepsis guideline bundle fluid resuscitation to mitigate hyperchloremia.',
    ),

    // Medications
    WardBedsideOrder(
      id: 'iv_calcium_gluconate',
      name: 'IV Calcium Gluconate (10% 10 mL)',
      category: BedsideOrderCategory.medications,
      description: 'Immediately stabilizes cardiac myocyte membrane against hyperkalemic arrhythmogenesis.',
    ),
    WardBedsideOrder(
      id: 'iv_regular_insulin_d50',
      name: 'IV Regular Insulin (10 Units) + D50W (50 mL)',
      category: BedsideOrderCategory.medications,
      description: 'Shifts extracellular potassium into intracellular space via Na+/K+-ATPase stimulation.',
    ),
    WardBedsideOrder(
      id: 'iv_atropine_high_dose',
      name: 'High-Dose IV Atropine (2-4 mg every 5 min)',
      category: BedsideOrderCategory.medications,
      description: 'Competitive muscarinic M2/M3 receptor antagonist; titrate until bronchial secretions dry.',
    ),
    WardBedsideOrder(
      id: 'iv_pralidoxime_2pam',
      name: 'IV Pralidoxime (2-PAM 1-2 g)',
      category: BedsideOrderCategory.medications,
      description: 'Nucleophilic oxime that reactivates phosphorylated acetylcholinesterase prior to aging.',
    ),
    WardBedsideOrder(
      id: 'iv_naloxone',
      name: 'IV Naloxone (0.4-2.0 mg)',
      category: BedsideOrderCategory.medications,
      description: 'Competitive mu-opioid receptor antagonist reversing respiratory depression.',
    ),
    WardBedsideOrder(
      id: 'iv_norepinephrine',
      name: 'IV Norepinephrine Infusion (2-20 mcg/min)',
      category: BedsideOrderCategory.medications,
      description: 'Potent alpha-1 vasoconstrictor with modest beta-1 inotropic support for septic/distributive shock.',
    ),
    WardBedsideOrder(
      id: 'iv_mannitol_hypertonic',
      name: 'IV Mannitol 20% (1 g/kg) or 3% Hypertonic Saline',
      category: BedsideOrderCategory.medications,
      description: 'Osmotic gradient generator pulling free water from cerebral parenchyma to drop acute ICP.',
    ),
    WardBedsideOrder(
      id: 'iv_magnesium_sulfate',
      name: 'IV Magnesium Sulfate (2 g over 10 min)',
      category: BedsideOrderCategory.medications,
      description: 'Blocks early afterdepolarizations (EADs) and terminates Torsades de Pointes.',
    ),
    WardBedsideOrder(
      id: 'iv_broad_spectrum_abx',
      name: 'IV Broad-Spectrum Antibiotics (Ceftriaxone + Vanco)',
      category: BedsideOrderCategory.medications,
      description: 'Empiric coverage for sepsis source control within 1 hour of triage.',
    ),
    WardBedsideOrder(
      id: 'iv_nitroglycerin',
      name: 'Sublingual / IV Nitroglycerin',
      category: BedsideOrderCategory.medications,
      description: 'Systemic venodilator reducing LV preload and coronary vascular resistance.',
    ),
    WardBedsideOrder(
      id: 'iv_furosemide',
      name: 'IV Furosemide (40-80 mg)',
      category: BedsideOrderCategory.medications,
      description: 'NKCC2 loop diuretic promoting rapid natriuresis and venodilation in pulmonary edema.',
    ),

    // Procedures & Airway
    WardBedsideOrder(
      id: 'proc_pericardiocentesis',
      name: 'Emergency Subxiphoid Pericardiocentesis',
      category: BedsideOrderCategory.proceduresAirway,
      description: 'Ultrasound-guided aspiration of 20-50 mL pericardial fluid to relieve cardiac compression.',
    ),
    WardBedsideOrder(
      id: 'proc_needle_decompression',
      name: 'Immediate Needle Thoracostomy & Chest Tube',
      category: BedsideOrderCategory.proceduresAirway,
      description: '14G cannula in 2nd ICS MCL or 5th ICS AAL followed by formal tube thoracostomy.',
    ),
    WardBedsideOrder(
      id: 'proc_primary_pci',
      name: 'Activate Cath Lab for Primary Percutaneous Coronary Intervention (PCI)',
      category: BedsideOrderCategory.proceduresAirway,
      description: 'Emergency coronary wire crossing and balloon angioplasty / stenting of culprit vessel.',
    ),
    WardBedsideOrder(
      id: 'proc_head_of_bed_30',
      name: 'Elevate Head of Bed to 30° & Neutral Neck Alignment',
      category: BedsideOrderCategory.proceduresAirway,
      description: 'Optimizes cerebral venous jugular drainage to lower intracranial pressure without dropping MAP.',
    ),
    WardBedsideOrder(
      id: 'proc_low_tidal_ventilation',
      name: 'Intubation & Low-Tidal-Volume (6 mL/kg) Lung-Protective Ventilation',
      category: BedsideOrderCategory.proceduresAirway,
      description: 'Prevents volutrauma/barotrauma and targets driving pressure < 14 cmH2O in ARDS.',
    ),
  ];

  // 8 High-Yield Undifferentiated Bedside Cases
  static final List<WardBedsideCase> allCases = [
    // 1. Obstructive Shock — Cardiac Tamponade
    WardBedsideCase(
      caseNumber: 1,
      triageId: 'UNDIFF-ER-001',
      demographic: '48-year-old female with metastatic breast cancer',
      chiefComplaint: 'Acute diaphoresis, severe air hunger, and near-syncope',
      triageStory: 'Patient presented with sudden severe weakness and dizziness after mild exertion. No chest pain radiating to arm, no fever. Triage nurse reports extremities are cool and clammy.',
      physicalExamSummary: 'Marked Jugular Venous Distension (JVD) to the angle of the jaw at 45°. Heart sounds are notably faint and distant on auscultation. Lung fields are bilaterally resonant and clear without rales or wheezes.',
      initialHr: 128.0,
      initialSbp: 78.0,
      initialDbp: 54.0,
      initialRr: 28.0,
      initialSpo2: 93.0,
      initialTempC: 36.8,
      initialGcs: 14,
      initialEcgRhythm: 'Sinus Tachycardia with Electrical Alternans (Beat-to-Beat QRS Amplitude Variation)',
      hiddenDiagnosis: 'Obstructive Shock secondary to Acute Cardiac Tamponade (Beck\'s Triad)',
      primaryOrganDomain: 'Cardiovascular',
      pathophysiologyMechanism: 'Accumulation of pericardial fluid under positive pressure impairs diastolic filling of all cardiac chambers. During inspiration, RV filling expands into the LV via the interventricular septum (pulsus paradoxus > 10 mmHg). Cardiac output collapses.',
      usmlePearl: 'Beck\'s Triad = Hypotension + Distended Neck Veins (JVD) + Muffled Heart Sounds. On ECG: Sinus tachycardia with Electrical Alternans due to the heart swinging within the fluid envelope. Avoid positive-pressure mechanical ventilation if possible, as elevated intrathoracic pressure further obliterates venous return.',
      remediationRoute: '/cardiac',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Large circumferential anechoic pericardial effusion (28 mm) with diastolic collapse of the right ventricular free wall and swinging heart movement.',
        hasPericardialEffusion: true,
        effusionDepthMm: 28.0,
        hasRvDiastolicCollapse: true,
        plaxDescription: 'Fluid layer visible anteriorly and posteriorly; hyperdynamic underfilled left ventricle.',
        lvefEstimated: 65.0,
        ivcDescription: 'Plethoric, dilated IVC (25 mm) with 0% respiratory collapsibility (complete loss of inspiratory sniff collapse).',
        ivcDiameterMm: 25.0,
        collapsibilityIndexPct: 0.0,
        isPlethoric: true,
        lungDescription: 'Bilateral lung sliding present; prominent horizontal A-lines without lung consolidation or B-lines (clear lungs).',
        hasLungSliding: true,
        hasBLines: false,
        morisonDescription: 'No free fluid identified in the right upper quadrant hepatorenal space.',
      ),
      differentialOptions: [
        'Acute Cardiac Tamponade',
        'Acute Pulmonary Embolism',
        'Left Tension Pneumothorax',
        'Anterior Wall STEMI with Cardiogenic Shock',
        'Hypovolemic Hemorrhagic Shock',
        'Septic Shock from Pneumonia',
      ],
      correctDdxRanking: [
        'Acute Cardiac Tamponade',
        'Acute Pulmonary Embolism',
        'Anterior Wall STEMI with Cardiogenic Shock',
      ],
      mandatoryOrderIds: ['iv_crystalloid_bolus', 'proc_pericardiocentesis'],
      contraindicationMap: {
        'iv_furosemide': 'FATAL ERROR: Furosemide causes acute volume depletion and venodilation, removing the critical preload sustaining cardiac output in tamponade, precipitating immediate arrest.',
        'iv_nitroglycerin': 'FATAL ERROR: Nitrates cause systemic venodilation and drop RV filling pressure, inducing rapid pulseless electrical activity (PEA).',
        'proc_low_tidal_ventilation': 'CONTRAINDICATION WARNING: Positive-pressure mechanical ventilation increases intrathoracic pressure, collapsing the vena cava and destroying right heart filling in tamponade.',
      },
    ),

    // 2. Obstructive Shock — Left Tension Pneumothorax
    WardBedsideCase(
      caseNumber: 2,
      triageId: 'UNDIFF-ICU-002',
      demographic: '34-year-old male post-motor-vehicle collision and left subclavian line placement',
      chiefComplaint: 'Sudden desaturation, cyanosis, and profound agitation',
      triageStory: 'Shortly after emergency left-sided central line cannulation, the patient developed acute respiratory distress. The ventilator high-peak-pressure alarm triggered with Ppeak rising from 22 to 46 cmH2O.',
      physicalExamSummary: 'Trachea visibly deviated to the right. Absent breath sounds over the entire left hemithorax with hyperresonance to percussion. Marked left-sided subcutaneous crepitus and distended neck veins.',
      initialHr: 136.0,
      initialSbp: 72.0,
      initialDbp: 48.0,
      initialRr: 36.0,
      initialSpo2: 81.0,
      initialTempC: 37.1,
      initialGcs: 12,
      initialEcgRhythm: 'Sinus Tachycardia with Low Voltage Complexes',
      hiddenDiagnosis: 'Obstructive Shock secondary to Left Tension Pneumothorax',
      primaryOrganDomain: 'Pulmonology & Critical Care',
      pathophysiologyMechanism: 'One-way flap valve injury allows air into left pleural cavity during inspiration without escape. Progressive tension shifts mediastinum to right, kinking SVC and IVC, preventing cardiac preload and causing PEA arrest if not vented.',
      usmlePearl: 'Tension Pneumothorax is a CLINICAL diagnosis. NEVER delay decompression for a chest X-ray. On POCUS: Absence of lung sliding, absence of B-lines, and presence of the Barcode / Stratosphere Sign on M-mode. Decompress immediately in 2nd ICS midclavicular line or 5th ICS anterior axillary line.',
      remediationRoute: '/pulmo',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Hyperdynamic compressed heart shifted into right hemithorax.',
        plaxDescription: 'Underfilled LV chambers; hyperdynamic contractility.',
        lvefEstimated: 60.0,
        ivcDescription: 'Plethoric, engorged IVC (26 mm) due to mediastinal compression of venous return.',
        ivcDiameterMm: 26.0,
        collapsibilityIndexPct: 5.0,
        isPlethoric: true,
        lungDescription: 'Left anterior lung: Complete absence of lung sliding. M-mode reveals horizontal parallel lines throughout (Barcode / Stratosphere Sign). Right lung: Normal seashore sign.',
        hasLungSliding: false,
        hasBLines: false,
        isStratosphereBarcodeSign: true,
        morisonDescription: 'Negative for intraperitoneal free fluid.',
      ),
      differentialOptions: [
        'Left Tension Pneumothorax',
        'Massive Pulmonary Embolism',
        'Acute Cardiac Tamponade',
        'Severe Mucus Plugging with Atelectasis',
        'Aortic Dissection (Stanford Type A)',
        'Right Mainstem Endotracheal Intubation',
      ],
      correctDdxRanking: [
        'Left Tension Pneumothorax',
        'Right Mainstem Endotracheal Intubation',
        'Acute Cardiac Tamponade',
      ],
      mandatoryOrderIds: ['proc_needle_decompression'],
      contraindicationMap: {
        'proc_low_tidal_ventilation': 'CRITICAL WARNING: Increasing positive-pressure ventilation before decompression inflates the pleural tension space faster, precipitating immediate fatal PEA.',
        'iv_nitroglycerin': 'CONTRAINDICATION: Vasodilation drops perfusion pressure further without addressing mechanical airway obstruction.',
      },
    ),

    // 3. Cardiogenic Shock — Inferior STEMI with RV Infarction
    WardBedsideCase(
      caseNumber: 3,
      triageId: 'UNDIFF-ER-003',
      demographic: '62-year-old male with type 2 diabetes and smoking history',
      chiefComplaint: 'Epigastric nausea, profound lightheadedness, and cold sweats',
      triageStory: 'Patient called EMS for severe indigestion and vomiting that began 2 hours ago. On arrival to the resuscitation bay, he is pale, ashen, and unable to sit up due to graying vision.',
      physicalExamSummary: 'Heart rate 52 bpm with irregular bradycardia. BP 82/50 mmHg. JVD present to 8 cm above sternal angle. Auscultation reveals clear lung fields bilaterally (no pulmonary crackles or wheezes). Heart sounds reveal an S3 gallop.',
      initialHr: 52.0,
      initialSbp: 82.0,
      initialDbp: 50.0,
      initialRr: 20.0,
      initialSpo2: 95.0,
      initialTempC: 36.6,
      initialGcs: 15,
      initialEcgRhythm: 'Sinus Bradycardia with 3 mm ST-Elevation in Leads II, III, aVF and reciprocal ST depression in I, aVL',
      hiddenDiagnosis: 'Cardiogenic Shock secondary to Acute Inferior STEMI with Right Ventricular (RV) Infarction',
      primaryOrganDomain: 'Cardiovascular',
      pathophysiologyMechanism: 'Proximal RCA occlusion deprives right ventricular myocardium of perfusion. The stiff, dilated RV fails as an active pump, relying purely on elevated central venous preload (CVP) to push blood through pulmonary vasculature into the LV.',
      usmlePearl: 'Classic RV MI Triad = Hypotension + JVD + Clear Lung Fields in an inferior STEMI setting. The ischemic RV is EXQUISITELY PRELOAD-DEPENDENT. Nitrates, Morphine, and Diuretics are absolute contraindications (Class III: Harm) because venodilation collapses RVEDV, inducing cardiovascular collapse.',
      remediationRoute: '/cardiac',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Dilated right ventricle (RV > LV dimension ratio > 1.0) with severe free-wall hypokinesis. No pericardial effusion.',
        hasPericardialEffusion: false,
        plaxDescription: 'Left ventricle is underfilled and hypercontractile; RV outflow tract is visibly dilated.',
        lvefEstimated: 58.0,
        ivcDescription: 'Plethoric, dilated IVC (24 mm) with minimal collapse (< 15%), reflecting elevated RV filling pressures.',
        ivcDiameterMm: 24.0,
        collapsibilityIndexPct: 12.0,
        isPlethoric: true,
        lungDescription: 'Clear bilateral lung sliding with normal horizontal A-lines. Total absence of pulmonary edema / B-lines.',
        hasLungSliding: true,
        hasBLines: false,
        morisonDescription: 'Negative for free fluid.',
      ),
      differentialOptions: [
        'Acute Inferior STEMI with RV Infarction',
        'Acute Pulmonary Embolism',
        'Acute Cardiac Tamponade',
        'Acute Peptic Ulcer Perforation',
        'Inferior Wall Ischemia with Vagal Syncope',
        'Decompensated Biventricular Heart Failure',
      ],
      correctDdxRanking: [
        'Acute Inferior STEMI with RV Infarction',
        'Acute Pulmonary Embolism',
        'Acute Cardiac Tamponade',
      ],
      mandatoryOrderIds: ['iv_crystalloid_bolus', 'proc_primary_pci', 'stat_ecg'],
      contraindicationMap: {
        'iv_nitroglycerin': 'FATAL ERROR (CLASS III: HARM): Nitroglycerin causes profound peripheral venodilation, eliminating the elevated RV filling pressure required to maintain forward flow. BP will plummet to undetectable levels.',
        'iv_furosemide': 'FATAL ERROR: Patient has clear lungs and an underfilled left heart. Diuretics drop preload further, worsening cardiogenic shock.',
      },
    ),

    // 4. Distributive Shock — Septic Shock + ARDS
    WardBedsideCase(
      caseNumber: 4,
      triageId: 'UNDIFF-ICU-004',
      demographic: '69-year-old female resident of long-term care facility with indwelling catheter',
      chiefComplaint: 'Lethargy, high fever, shivering, and rapid shallow breathing',
      triageStory: 'Staff noted warm, flushed extremities, clouded sensorium, and dark cloudy urine over 18 hours. Triage blood gas reveals Lactate 5.6 mmol/L and metabolic acidosis.',
      physicalExamSummary: 'Febrile at 39.2°C. Flushed, warm extremities with capillary refill < 1 second (bounding peripheral pulses). Diffuse bilateral wet inspiratory crackles in all lung zones.',
      initialHr: 124.0,
      initialSbp: 76.0,
      initialDbp: 38.0,
      initialRr: 32.0,
      initialSpo2: 87.0,
      initialTempC: 39.2,
      initialGcs: 13,
      initialEcgRhythm: 'Sinus Tachycardia with Wide Pulse Pressure',
      hiddenDiagnosis: 'Distributive Shock secondary to Urosepsis with Early ARDS',
      primaryOrganDomain: 'Emergency & POCUS Diagnostics',
      pathophysiologyMechanism: 'Massive cytokine release (TNF-alpha, IL-1, IL-6) induces systemic endothelial nitric oxide synthesis, causing profound vasodilation (low SVR) and capillary leak syndrome, progressing to alveolar alveolar-capillary barrier disruption (ARDS).',
      usmlePearl: 'Distributive/Septic shock presents with warm extremities and wide pulse pressure early on. RUSH ultrasound demonstrates a hyperdynamic LV with collapsing IVC. Surviving Sepsis Campaign bundle: 30 mL/kg balanced crystalloids within 3 hours + Norepinephrine titrated to MAP >= 65 + Early broad-spectrum antibiotics within 1 hour.',
      remediationRoute: '/pulmo',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Hyperdynamic cardiac motion; all chambers contracting vigorously with near-complete systolic obliteration ("kissing walls"). No pericardial effusion.',
        hasPericardialEffusion: false,
        plaxDescription: 'Hyperdynamic LV contractility (LVEF > 70%) with end-systolic cavity obliteration.',
        lvefEstimated: 75.0,
        ivcDescription: 'Flat, underfilled IVC (10 mm) with > 80% respiratory collapse on inspiration (volume-responsive).',
        ivcDiameterMm: 10.0,
        collapsibilityIndexPct: 85.0,
        isPlethoric: false,
        lungDescription: 'Diffuse bilateral B-lines (comet-tail artifacts > 3 per intercostal space) indicating non-cardiogenic alveolar-interstitial pulmonary edema (ARDS).',
        hasLungSliding: true,
        hasBLines: true,
        morisonDescription: 'No peritoneal fluid.',
      ),
      differentialOptions: [
        'Septic Shock with Early ARDS',
        'Acute Cardiogenic Shock from Myocarditis',
        'Severe Anaphylactic Shock',
        'Severe Dehydration with Hypovolemia',
        'Acute Adrenal Insufficiency (Addisonian Crisis)',
        'Thyrotoxic Crisis (Thyroid Storm)',
      ],
      correctDdxRanking: [
        'Septic Shock with Early ARDS',
        'Severe Anaphylactic Shock',
        'Acute Adrenal Insufficiency (Addisonian Crisis)',
      ],
      mandatoryOrderIds: ['iv_balanced_crystalloid', 'iv_norepinephrine', 'iv_broad_spectrum_abx', 'proc_low_tidal_ventilation'],
      contraindicationMap: {
        'iv_furosemide': 'CONTRAINDICATION: Despite pulmonary B-lines, this patient has severe intravascular hypovolemia and distributive vasodilation. Loop diuretics will collapse venous return and worsen multi-organ ischemia.',
      },
    ),

    // 5. Severe DKA + Hyperkalemic ECG Crisis
    WardBedsideCase(
      caseNumber: 5,
      triageId: 'UNDIFF-ER-005',
      demographic: '21-year-old male with type 1 diabetes who lost health insurance',
      chiefComplaint: 'Profound exhaustion, diffuse abdominal pain, and rapid panting respirations',
      triageStory: 'Missed insulin doses for 4 days. Brought in by roommate after progressive confusion and vomiting. Fruity odor noticed on breath.',
      physicalExamSummary: 'Deep, rapid Kussmaul respirations (34/min). Mucous membranes severely dry; sunken eyes. Diffuse abdominal tenderness without guarding. Muscle weakness and hyporeflexia in lower extremities.',
      initialHr: 118.0,
      initialSbp: 88.0,
      initialDbp: 56.0,
      initialRr: 34.0,
      initialSpo2: 98.0,
      initialTempC: 36.4,
      initialGcs: 13,
      initialEcgRhythm: 'Sinus Rhythm with Symmetrical Tall, Peaked T-Waves and PR Prolongation (Hyperkalemic Pattern)',
      hiddenDiagnosis: 'Severe Diabetic Ketoacidosis (DKA) with High-Grade Hyperkalemic Arrhythmic Emergency',
      primaryOrganDomain: 'Nephrology & Acid-Base',
      pathophysiologyMechanism: 'Insulin deficiency halts glucose uptake, stimulating lipolysis into ketoacids (beta-hydroxybutyrate, acetoacetate). Extracellular shift of K+ in severe acidosis combined with prerenal AKI elevates serum K+ to 6.8 mEq/L, risking ventricular fibrillation.',
      usmlePearl: 'In DKA with peaked T-waves, FIRST STEP is ALWAYS intravenous Calcium Gluconate to stabilize the cardiac myocyte resting membrane potential. NEVER give insulin before checking ECG/K+, and NEVER start potassium binders without cardiac membrane protection. Once insulin drives K+ intracellularly, anticipate rapid hypokalemia and add K+ to fluids once K+ < 5.2 mEq/L.',
      remediationRoute: '/nephro',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Normal cardiac chamber dimensions, hyperdynamic LV ejection, no pericardial fluid.',
        plaxDescription: 'Hyperdynamic LV contractility secondary to sympathetic overdrive and hypovolemia.',
        lvefEstimated: 68.0,
        ivcDescription: 'Flat IVC (9 mm) with > 70% inspiratory collapse, confirming profound volume depletion (osmotic diuresis).',
        ivcDiameterMm: 9.0,
        collapsibilityIndexPct: 75.0,
        isPlethoric: false,
        lungDescription: 'Normal lung sliding; clear horizontal A-lines throughout (Kussmaul breathing is compensatory hyperventilation, not pulmonary edema).',
        hasLungSliding: true,
        hasBLines: false,
        morisonDescription: 'Negative for free fluid.',
      ),
      differentialOptions: [
        'Severe DKA with Hyperkalemic Cardiac Emergency',
        'Alcoholic Ketoacidosis with Hypomagnesemia',
        'Acute Salicylate / Aspirin Toxicity',
        'Lactic Acidosis from Mesenteric Ischemia',
        'Ethylene Glycol / Toxic Alcohol Ingestion',
        'Addisonian Crisis with Adrenal Failure',
      ],
      correctDdxRanking: [
        'Severe DKA with Hyperkalemic Cardiac Emergency',
        'Acute Salicylate / Aspirin Toxicity',
        'Ethylene Glycol / Toxic Alcohol Ingestion',
      ],
      mandatoryOrderIds: ['iv_calcium_gluconate', 'iv_crystalloid_bolus', 'iv_regular_insulin_d50', 'stat_cmp'],
      contraindicationMap: {
        'iv_furosemide': 'CONTRAINDICATION: Patient already has severe osmotic diuresis hypovolemia. Loop diuretics worsen renal shutdown and prerenal azotemia.',
      },
    ),

    // 6. Neurogenic Emergency — Ruptured ACom Aneurysm + Cushing Triad
    WardBedsideCase(
      caseNumber: 6,
      triageId: 'UNDIFF-ICU-006',
      demographic: '51-year-old female with polycystic kidney disease (ADPKD)',
      chiefComplaint: '"Worst headache of my entire life" followed by sudden loss of consciousness',
      triageStory: 'Collapsed during physical exercise. Regained consciousness briefly complaining of blinding occipital head pain and photophobia, then rapidly deteriorated to stupor.',
      physicalExamSummary: 'Stuporous, responsive only to noxious sternal rub (GCS 8). Left pupil is 6 mm and unreactive to direct light; right pupil is 3 mm and reactive (anisocoria). Nuchal rigidity present. BP 208/114 mmHg with severe bradycardia (HR 42 bpm).',
      initialHr: 42.0,
      initialSbp: 208.0,
      initialDbp: 114.0,
      initialRr: 10.0,
      initialSpo2: 94.0,
      initialTempC: 37.3,
      initialGcs: 8,
      initialEcgRhythm: 'Sinus Bradycardia with Neurogenic Giant Inverted T-Waves ("Cerebral T-Waves")',
      hiddenDiagnosis: 'Ruptured Anterior Communicating (ACom) Berry Aneurysm causing Acute Subarachnoid Hemorrhage (SAH) with Cushing Reflex',
      primaryOrganDomain: 'Neurology',
      pathophysiologyMechanism: 'Aneurysm rupture raises intracranial pressure (ICP > 30 mmHg), compromising cerebral perfusion pressure (CPP = MAP - ICP). The brainstem ischemic response triggers a massive sympathetic surge (hypertension) followed by carotid baroreceptor-mediated reflex bradycardia (Cushing\'s Triad).',
      usmlePearl: 'Cushing\'s Triad = Severe Hypertension + Bradycardia + Irregular / Depressed Respirations. Indicates impending uncal transtentorial herniation. Immediate management: Elevate head of bed to 30°, administer osmotic therapy (Mannitol 20% or 3% Hypertonic Saline), avoid dropping MAP too quickly (CPP must remain > 60 mmHg), and administer Nimodipine to prevent vasospasm.',
      remediationRoute: '/neuro',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Normal chamber anatomy, hypercontractile myocardium; optic nerve sheath diameter (ONSD) measured transorbitally is 6.8 mm (> 5.8 mm indicates critical intracranial hypertension).',
        plaxDescription: 'Normal LV function without regional wall motion abnormalities.',
        lvefEstimated: 60.0,
        ivcDescription: 'Euvolemic IVC (16 mm) with 40% collapse.',
        ivcDiameterMm: 16.0,
        collapsibilityIndexPct: 40.0,
        isPlethoric: false,
        lungDescription: 'Bilateral lung sliding present; irregular bradypnea without alveolar edema.',
        hasLungSliding: true,
        hasBLines: false,
        morisonDescription: 'Negative for intra-abdominal fluid.',
      ),
      differentialOptions: [
        'Ruptured Saccular Aneurysm with Subarachnoid Hemorrhage',
        'Acute Ischemic Stroke with Hemorrhagic Transformation',
        'Acute Hypertensive Encephalopathy / PRES',
        'Bacterial Meningoencephalitis',
        'Acute Subdural Hematoma',
        'Phaeochromocytoma Hypertensive Crisis',
      ],
      correctDdxRanking: [
        'Ruptured Saccular Aneurysm with Subarachnoid Hemorrhage',
        'Acute Hypertensive Encephalopathy / PRES',
        'Acute Subdural Hematoma',
      ],
      mandatoryOrderIds: ['proc_head_of_bed_30', 'iv_mannitol_hypertonic', 'stat_abg'],
      contraindicationMap: {
        'iv_nitroglycerin': 'FATAL ERROR: Potent cerebral and systemic venodilation collapses mean arterial pressure, immediately obliterating cerebral perfusion pressure (CPP < 50 mmHg) and precipitating brainstem infarction.',
      },
    ),

    // 7. Toxicology Crisis — Organophosphate Cholinergic Toxidrome (SLUDGEM)
    WardBedsideCase(
      caseNumber: 7,
      triageId: 'UNDIFF-ER-007',
      demographic: '44-year-old agricultural worker found unconscious in pesticide storage shed',
      chiefComplaint: 'Copious oral secretions, continuous muscle twitching, and wheezing',
      triageStory: 'Co-workers found patient slumped over pesticide sprayer tanks 45 minutes ago. Clothes are soaked in chemical fluid with a strong garlic-like odor.',
      physicalExamSummary: 'Copious white frothy secretions bubbling from mouth and nose (bronchorrhea). Pinpoint pupils (miosis, 1 mm bilaterally). Diffuse wheezes and coarse crackles bilaterally. Diffuse fasciculations of face and calf muscles. Diaphoretic and incontinent of urine and stool.',
      initialHr: 44.0,
      initialSbp: 86.0,
      initialDbp: 52.0,
      initialRr: 32.0,
      initialSpo2: 84.0,
      initialTempC: 36.2,
      initialGcs: 10,
      initialEcgRhythm: 'Sinus Bradycardia with Occasional Junctional Escape Beats',
      hiddenDiagnosis: 'Acute Organophosphate Poisoning with Massive Cholinergic Toxidrome (SLUDGEM)',
      primaryOrganDomain: 'Pharmacology & Toxicology',
      pathophysiologyMechanism: 'Organophosphates irreversibly phosphorylate and inactivate acetylcholinesterase (AChE) via covalent bonding. Acetylcholine floods muscarinic receptors (bradycardia, bronchospasm, bronchorrhea) and nicotinic receptors (fasciculations, weakness). Aging of the bond occurs over 24-48 hours.',
      usmlePearl: 'SLUDGEM = Salivation, Lacrimation, Urination, Defecation, GI cramping, Emesis, Miosis. The immediate cause of death is asphyxiation from the "Killer Bs": Bronchoconstriction, Bronchorrhea, and Bradycardia. First-line therapy: High-dose Atropine IV titrated to DRY BRONCHIAL SECRETIONS (not pupil size!). Next: Pralidoxime (2-PAM) to regenerate AChE before covalent aging occurs.',
      remediationRoute: '/aspirin',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Profound sinus bradycardia; normal myocardial structure without effusion.',
        plaxDescription: 'Underfilled ventricle with bradycardic chamber filling.',
        lvefEstimated: 52.0,
        ivcDescription: 'Euvolemic IVC (15 mm) with 45% collapse.',
        ivcDiameterMm: 15.0,
        collapsibilityIndexPct: 45.0,
        isPlethoric: false,
        lungDescription: 'Diffuse bilateral B-lines with retained lung sliding, reflecting torrential airway fluid (bronchorrhea / non-cardiogenic chemical edema).',
        hasLungSliding: true,
        hasBLines: true,
        morisonDescription: 'Negative for fluid.',
      ),
      differentialOptions: [
        'Acute Organophosphate / Carbamate Poisoning',
        'Severe Opioid Overdose',
        'Acute Bronchospastic Status Asthmaticus',
        'Severe Pontine Hemorrhage',
        'Clonidine / Central Alpha-2 Agonist Toxicity',
        'Beta-Blocker Toxicity',
      ],
      correctDdxRanking: [
        'Acute Organophosphate / Carbamate Poisoning',
        'Severe Opioid Overdose',
        'Clonidine / Central Alpha-2 Agonist Toxicity',
      ],
      mandatoryOrderIds: ['iv_atropine_high_dose', 'iv_pralidoxime_2pam', 'proc_low_tidal_ventilation'],
      contraindicationMap: {
        'iv_furosemide': 'CONTRAINDICATION: Bronchorrhea is driven by hyperstimulated muscarinic secretory glands, not hydrostatic pulmonary edema. Diuretics cause hypovolemic collapse without clearing secretions.',
      },
    ),

    // 8. Pharmacogenomic Crisis — CYP2D6 Ultra-Rapid Metabolizer Codeine Toxicity
    WardBedsideCase(
      caseNumber: 8,
      triageId: 'UNDIFF-ER-008',
      demographic: '27-year-old female post-elective outpatient tonsillectomy 12 hours ago',
      chiefComplaint: 'Unresponsiveness, snoring respirations, and cyanotic lips',
      triageStory: 'Prescribed oral codeine/acetaminophen syrup for post-operative pain. Family noted deep sleep that transitioned to unresponsiveness with only 4-6 breaths per minute.',
      physicalExamSummary: 'Unresponsive to vigorous shaking and sternal rub (GCS 5). Pinpoint pupils (1 mm, non-reactive). Respiratory rate 6 breaths/minute with shallow chest excursion. Perioral cyanosis. Flaccid muscle tone throughout.',
      initialHr: 54.0,
      initialSbp: 88.0,
      initialDbp: 54.0,
      initialRr: 6.0,
      initialSpo2: 78.0,
      initialTempC: 35.8,
      initialGcs: 5,
      initialEcgRhythm: 'Sinus Bradycardia with First-Degree AV Block',
      hiddenDiagnosis: 'Severe Opioid Overdose secondary to CYP2D6 Ultra-Rapid Metabolizer Phenotype (Codeine-to-Morphine Hyper-Bioactivation)',
      primaryOrganDomain: 'Pharmacology & Toxicology',
      pathophysiologyMechanism: 'Codeine is a prodrug requiring O-demethylation by hepatic CYP2D6 into active Morphine. CYP2D6 gene duplication (*1xN, *2xN) causes ultra-rapid metabolism, converting therapeutic codeine doses into lethal plasma concentrations of morphine within hours.',
      usmlePearl: 'Classic Opioid Toxidrome Triad = CNS Depression + Respiratory Depression + Miosis. FDA Black Box Warning: Codeine is contraindicated in pediatric post-tonsillectomy pain due to CYP2D6 ultra-rapid metabolizer fatalities. Immediate antidote is IV Naloxone, a pure competitive mu-opioid receptor antagonist.',
      remediationRoute: '/pharmacogenomics',
      pocusFindings: PocusFindings(
        subxiphoidDescription: 'Normal chamber anatomy, bradycardic rhythm without pericardial effusion.',
        plaxDescription: 'Normal LV wall thickness and ejection fraction.',
        lvefEstimated: 56.0,
        ivcDescription: 'Euvolemic IVC (14 mm) with 45% collapse.',
        ivcDiameterMm: 14.0,
        collapsibilityIndexPct: 45.0,
        isPlethoric: false,
        lungDescription: 'Clear lung sliding present; prominent horizontal A-lines. No B-lines or pneumothorax.',
        hasLungSliding: true,
        hasBLines: false,
        morisonDescription: 'Negative for free fluid.',
      ),
      differentialOptions: [
        'CYP2D6 Ultra-Rapid Metabolizer Codeine Opioid Toxicity',
        'Severe Benzodiazepine Overdose',
        'Acute Pontine Stroke',
        'Severe Post-Operative Hemorrhage',
        'Hypoglycemic Coma',
        'Carbon Monoxide Poisoning',
      ],
      correctDdxRanking: [
        'CYP2D6 Ultra-Rapid Metabolizer Codeine Opioid Toxicity',
        'Severe Benzodiazepine Overdose',
        'Acute Pontine Stroke',
      ],
      mandatoryOrderIds: ['iv_naloxone', 'stat_abg'],
      contraindicationMap: {
        'iv_calcium_gluconate': 'CONTRAINDICATION: Unnecessary and ineffective for primary opioid receptor overstimulation without hyperkalemic ECG abnormalities.',
      },
    ),
  ];

  void _loadCase(int index) {
    _currentCaseIndex = index.clamp(0, allCases.length - 1);
    _activeCase = allCases[_currentCaseIndex];

    _elapsedSeconds = 0;
    _top3Ddx.fillRange(0, 3, null);
    _selectedEvidenceTags.clear();
    _placedOrders.clear();
    _activeSafetyAlertTitle = null;
    _activeSafetyAlertRationale = null;
    _isCaseSubmitted = false;
    _isPatientStabilized = false;
    _finalEncounterScore = 0.0;
    _activePocusWindow = WardPocusWindow.subxiphoid4Chamber;
    _ultrasoundMode = PocusUltrasoundMode.bMode2D;

    // Apply baseline patient vitals to the coupled multi-organ state
    multiOrganState.cardiacVitals.setHeartRate(_activeCase.initialHr);
    multiOrganState.cardiacVitals.setBloodPressure(_activeCase.initialSbp, _activeCase.initialDbp);
    if (_activeCase.caseNumber == 2) {
      multiOrganState.pulmoVitals.applySituation(PulmoClinicalSituation.tensionPneumothorax);
    } else if (_activeCase.caseNumber == 4) {
      multiOrganState.pulmoVitals.applySituation(PulmoClinicalSituation.severeArds);
    } else if (_activeCase.caseNumber == 8) {
      multiOrganState.pulmoVitals.applySituation(PulmoClinicalSituation.opioidOverdose);
    } else {
      multiOrganState.pulmoVitals.applySituation(PulmoClinicalSituation.normalLungs);
    }
    multiOrganState.neuroVitals.setManualMap((_activeCase.initialSbp + 2 * _activeCase.initialDbp) / 3);
    multiOrganState.neuroVitals.setManualIcp(_activeCase.caseNumber == 6 ? 34.0 : 12.0);

    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _caseTimer?.cancel();
    _isTimerRunning = true;
    _caseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void stopTimer() {
    _caseTimer?.cancel();
    _isTimerRunning = false;
    notifyListeners();
  }

  void loadCase(int index) => _loadCase(index);

  void nextCase() {
    if (_currentCaseIndex < allCases.length - 1) {
      _loadCase(_currentCaseIndex + 1);
    } else {
      _loadCase(0);
    }
  }

  void setPocusWindow(WardPocusWindow window) {
    _activePocusWindow = window;
    notifyListeners();
  }

  void setUltrasoundMode(PocusUltrasoundMode mode) {
    _ultrasoundMode = mode;
    notifyListeners();
  }

  void toggleLandmarkTags() {
    _showLandmarkTags = !_showLandmarkTags;
    notifyListeners();
  }

  void setDdxRank(int slot, String diagnosis) {
    if (slot >= 0 && slot < 3) {
      _top3Ddx[slot] = diagnosis;
      notifyListeners();
    }
  }

  void clearDdxSlot(int slot) {
    if (slot >= 0 && slot < 3) {
      _top3Ddx[slot] = null;
      notifyListeners();
    }
  }

  void toggleEvidenceTag(String tag) {
    if (_selectedEvidenceTags.contains(tag)) {
      _selectedEvidenceTags.remove(tag);
    } else {
      _selectedEvidenceTags.add(tag);
    }
    notifyListeners();
  }

  bool placeOrder(WardBedsideOrder order) {
    if (_placedOrders.any((o) => o.id == order.id)) {
      return false; // Already placed
    }

    _placedOrders.add(order);

    // 1. Check for fatal contraindication in this specific case
    if (_activeCase.contraindicationMap.containsKey(order.id)) {
      final rationale = _activeCase.contraindicationMap[order.id]!;
      _activeSafetyAlertTitle = 'ATTENDING SAFETY INTERCEPTION: Contraindicated Order Placed!';
      _activeSafetyAlertRationale = rationale;

      // Penalize vitals
      multiOrganState.cardiacVitals.setBloodPressure(
        math.max(45.0, multiOrganState.cardiacVitals.systolicBp - 25.0),
        math.max(30.0, multiOrganState.cardiacVitals.diastolicBp - 15.0),
      );
      notifyListeners();
      return false;
    }

    // 2. Check for therapeutic stabilization
    final isMandatory = _activeCase.mandatoryOrderIds.contains(order.id);
    if (isMandatory) {
      // Improve patient hemodynamics
      final currentSbp = multiOrganState.cardiacVitals.systolicBp;
      final currentDbp = multiOrganState.cardiacVitals.diastolicBp;
      final currentHr = multiOrganState.cardiacVitals.heartRateBpm;

      if (currentSbp < 90.0) {
        multiOrganState.cardiacVitals.setBloodPressure(
          (currentSbp + 20.0).clamp(60.0, 120.0),
          (currentDbp + 12.0).clamp(40.0, 80.0),
        );
      }
      if (currentHr > 110.0) {
        multiOrganState.cardiacVitals.setHeartRate((currentHr - 18.0).clamp(60.0, 160.0));
      } else if (currentHr < 55.0) {
        multiOrganState.cardiacVitals.setHeartRate((currentHr + 22.0).clamp(50.0, 95.0));
      }

      // Check if all mandatory orders placed
      final placedIds = _placedOrders.map((o) => o.id).toSet();
      if (_activeCase.mandatoryOrderIds.every((id) => placedIds.contains(id))) {
        _isPatientStabilized = true;
      }
    }

    notifyListeners();
    return true;
  }

  void dismissSafetyAlert() {
    _activeSafetyAlertTitle = null;
    _activeSafetyAlertRationale = null;
    notifyListeners();
  }

  void submitCase() {
    stopTimer();
    _isCaseSubmitted = true;

    // Calculate encounter score out of 100
    // A. Triage Speed (20 pts): Under 90s = 20 pts, 90-180s = 15 pts, >180s = 10 pts
    double speedScore = 20.0;
    if (_elapsedSeconds > 180) {
      speedScore = 10.0;
    } else if (_elapsedSeconds > 90) {
      speedScore = 15.0;
    }

    // B. POCUS & Evidence tags (25 pts)
    double pocusScore = (_selectedEvidenceTags.length >= 2 ? 25.0 : _selectedEvidenceTags.length * 12.5);

    // C. DDx Ranking (30 pts)
    double ddxScore = 0.0;
    if (_top3Ddx[0] == _activeCase.correctDdxRanking[0]) {
      ddxScore += 18.0; // Primary suspect exactly right
    } else if (_activeCase.correctDdxRanking.contains(_top3Ddx[0])) {
      ddxScore += 8.0;
    }

    if (_activeCase.correctDdxRanking.contains(_top3Ddx[1])) {
      ddxScore += 6.0;
    }
    if (_activeCase.correctDdxRanking.contains(_top3Ddx[2])) {
      ddxScore += 6.0;
    }

    // D. Safe Therapeutics & Orders (25 pts)
    double orderScore = 25.0;
    final placedIds = _placedOrders.map((o) => o.id).toSet();
    for (final mId in _activeCase.mandatoryOrderIds) {
      if (!placedIds.contains(mId)) {
        orderScore -= 8.0;
      }
    }
    for (final order in _placedOrders) {
      if (_activeCase.contraindicationMap.containsKey(order.id)) {
        orderScore -= 15.0; // Severe safety penalty
      }
    }
    orderScore = orderScore.clamp(0.0, 25.0);

    _finalEncounterScore = (speedScore + pocusScore + ddxScore + orderScore).clamp(0.0, 100.0);

    // Update domain mastery tracking
    final domain = _activeCase.primaryOrganDomain;
    if (_domainScores.containsKey(domain)) {
      _domainScores[domain]!.add(_finalEncounterScore);
    }
    _domainScores['Emergency & POCUS Diagnostics']!.add(_finalEncounterScore);

    notifyListeners();
  }

  @override
  void dispose() {
    _caseTimer?.cancel();
    super.dispose();
  }
}
