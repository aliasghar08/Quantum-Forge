// ============================================================================
// Multi-Organ Patient State & Cross-Organ Physiological Coupling Engine
// ----------------------------------------------------------------------------
// Integrates and synchronizes physiological models across three vital systems:
// 1. CardioCath 3D Lab (CardiacMasterVitalsState: HR, SBP, DBP, MAP, LVEF, Rhythm)
// 2. NeuroLab 3D (NeuroMasterVitalsState: MAP, ICP, CPP, PaCO2, SpO2, GCS)
// 3. NephroLab 3D & ADME (NephroMasterVitalsState: RPP, eGFR, Cr, BUN, K+, ABG, CL_ratio)
//
// Active Physiological Cascades:
// - Cardiorenal Cascade: Cardiogenic shock (LVEF < 30%) or MAP < 65 mmHg
//   drops RPP & eGFR (95 -> 24 mL/min), triggers oliguria, and scales drug
//   clearance (CL_ratio = 0.25), prolonging half-life and elevating toxic AUC.
// - Cardio-Embolic Neuro Cascade: Atrial Fibrillation raises CHA2DS2-VASc
//   embolic risk and offers a 1-click jump to Left M1 MCA LVO.
// - Cushing Reflex Neuro-Cardiac Cascade: ICP > 28 mmHg triggers reactive
//   hypertension (SBP > 195 mmHg) and reflex baroreceptor bradycardia (HR < 50 bpm).
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/cardiac/data/cardiac_master_vitals_state.dart';
import 'package:quantum_forge/features/cardiac/data/coronary_hemodynamics_engine.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_master_vitals_state.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

/// Nephrology and Acid-Base Clinical Situation Presets.
enum NephroClinicalSituation {
  normalBaseline(
    id: 'normal',
    title: 'Normal Renal & Acid-Base Baseline',
    shortLabel: 'Normal Baseline',
    egfrMlMin: 95.0,
    rppMmHg: 80.0,
    urineOutputMlKgH: 1.2,
    serumCreatinineMgDl: 0.9,
    bunMgDl: 14.0,
    potassiumMeqL: 4.2,
    clearanceRatio: 1.0,
    ph: 7.40,
    paco2MmHg: 40.0,
    hco3MeqL: 24.0,
    sodiumMeqL: 140.0,
    chlorideMeqL: 102.0,
    albuminGDl: 4.0,
    description: 'Normal glomerular filtration, intact tubular reabsorption, normal anion gap (14 mEq/L).',
    accentColor: Color(0xFF00E676),
  ),
  cardiorenalAki(
    id: 'cardiorenal_aki',
    title: 'Type 1 Cardiorenal Syndrome (Cardiogenic AKI)',
    shortLabel: 'Cardiorenal Shock',
    egfrMlMin: 24.0,
    rppMmHg: 44.0,
    urineOutputMlKgH: 0.22,
    serumCreatinineMgDl: 3.4,
    bunMgDl: 58.0,
    potassiumMeqL: 5.8,
    clearanceRatio: 0.28,
    ph: 7.21,
    paco2MmHg: 29.0,
    hco3MeqL: 11.0,
    sodiumMeqL: 136.0,
    chlorideMeqL: 96.0,
    albuminGDl: 3.4,
    description: 'Low cardiac output drops renal perfusion pressure; severe oliguria, uremic retention, and lactic acidosis.',
    accentColor: Color(0xFFFF1744),
  ),
  dka(
    id: 'dka',
    title: 'Diabetic Ketoacidosis (High AG Acidosis)',
    shortLabel: 'Severe DKA',
    egfrMlMin: 68.0,
    rppMmHg: 72.0,
    urineOutputMlKgH: 2.4, // Osmotic diuresis
    serumCreatinineMgDl: 1.8,
    bunMgDl: 36.0,
    potassiumMeqL: 5.6,
    clearanceRatio: 0.75,
    ph: 7.12,
    paco2MmHg: 19.0,
    hco3MeqL: 6.0,
    sodiumMeqL: 132.0,
    chlorideMeqL: 94.0,
    albuminGDl: 4.2,
    description: 'Severe ketoacidosis with Kussmaul respiratory compensation (Winter expected PaCO2 17 mmHg).',
    accentColor: Color(0xFFFF5252),
  ),
  uremicAkiEsrd(
    id: 'uremic_aki',
    title: 'Uremic AKI & Hyperkalemia (K⁺ 6.8 mEq/L)',
    shortLabel: 'Uremic AKI (K⁺ 6.8)',
    egfrMlMin: 12.0,
    rppMmHg: 68.0,
    urineOutputMlKgH: 0.15,
    serumCreatinineMgDl: 4.8,
    bunMgDl: 86.0,
    potassiumMeqL: 6.8,
    clearanceRatio: 0.15,
    ph: 7.18,
    paco2MmHg: 31.0,
    hco3MeqL: 12.0,
    sodiumMeqL: 135.0,
    chlorideMeqL: 98.0,
    albuminGDl: 3.0,
    description: 'Critical hyperkalemia with peaked T-waves, uremic metabolic acidosis, indication for emergent hemodialysis.',
    accentColor: Color(0xFFD50000),
  ),
  salicylateToxicity(
    id: 'salicylate_toxicity',
    title: 'Salicylate Toxicity (Mixed Resp Alk + HAGMA)',
    shortLabel: 'Salicylate Toxicity',
    egfrMlMin: 72.0,
    rppMmHg: 78.0,
    urineOutputMlKgH: 1.0,
    serumCreatinineMgDl: 1.4,
    bunMgDl: 22.0,
    potassiumMeqL: 3.6,
    clearanceRatio: 0.80,
    ph: 7.45,
    paco2MmHg: 18.0,
    hco3MeqL: 12.0,
    sodiumMeqL: 142.0,
    chlorideMeqL: 100.0,
    albuminGDl: 4.0,
    description: 'Direct respiratory center stimulation produces primary respiratory alkalosis; uncoupling of oxidative phosphorylation produces HAGMA.',
    accentColor: Color(0xFFFF9100),
  ),
  severeDiarrheaNagma(
    id: 'diarrhea_nagma',
    title: 'Severe Diarrheal Bicarbonate Loss (NAGMA)',
    shortLabel: 'NAGMA Diarrhea',
    egfrMlMin: 78.0,
    rppMmHg: 70.0,
    urineOutputMlKgH: 0.7,
    serumCreatinineMgDl: 1.3,
    bunMgDl: 26.0,
    potassiumMeqL: 3.1,
    clearanceRatio: 0.85,
    ph: 7.27,
    paco2MmHg: 29.0,
    hco3MeqL: 13.0,
    sodiumMeqL: 138.0,
    chlorideMeqL: 114.0,
    albuminGDl: 4.0,
    description: 'GI bicarbonate wasting with compensatory hyperchloremia; normal anion gap (11 mEq/L).',
    accentColor: Color(0xFFAB47BC),
  ),
  copdRetention(
    id: 'copd_retention',
    title: 'COPD Exacerbation (Acute on Chronic Resp Acidosis)',
    shortLabel: 'COPD Acidosis',
    egfrMlMin: 85.0,
    rppMmHg: 82.0,
    urineOutputMlKgH: 1.1,
    serumCreatinineMgDl: 1.0,
    bunMgDl: 18.0,
    potassiumMeqL: 4.4,
    clearanceRatio: 0.95,
    ph: 7.30,
    paco2MmHg: 65.0,
    hco3MeqL: 32.0,
    sodiumMeqL: 139.0,
    chlorideMeqL: 94.0,
    albuminGDl: 4.0,
    description: 'CO2 retention with renal metabolic retention compensation (elevated serum HCO3-).',
    accentColor: Color(0xFF3F51B5),
  ),
  contractionAlkalosis(
    id: 'contraction_alkalosis',
    title: 'Loop Diuretic Overuse (Contraction Alkalosis)',
    shortLabel: 'Loop Diuretic Alk',
    egfrMlMin: 82.0,
    rppMmHg: 74.0,
    urineOutputMlKgH: 2.8,
    serumCreatinineMgDl: 1.2,
    bunMgDl: 28.0,
    potassiumMeqL: 3.0,
    clearanceRatio: 0.90,
    ph: 7.54,
    paco2MmHg: 46.0,
    hco3MeqL: 38.0,
    sodiumMeqL: 142.0,
    chlorideMeqL: 88.0,
    albuminGDl: 4.3,
    description: 'Volume depletion + hypokalemic, hypochloremic metabolic alkalosis from intense NKCC2 blockade.',
    accentColor: Color(0xFF00ACC1),
  );

  final String id;
  final String title;
  final String shortLabel;
  final double egfrMlMin;
  final double rppMmHg;
  final double urineOutputMlKgH;
  final double serumCreatinineMgDl;
  final double bunMgDl;
  final double potassiumMeqL;
  final double clearanceRatio;
  final double ph;
  final double paco2MmHg;
  final double hco3MeqL;
  final double sodiumMeqL;
  final double chlorideMeqL;
  final double albuminGDl;
  final String description;
  final Color accentColor;

  const NephroClinicalSituation({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.egfrMlMin,
    required this.rppMmHg,
    required this.urineOutputMlKgH,
    required this.serumCreatinineMgDl,
    required this.bunMgDl,
    required this.potassiumMeqL,
    required this.clearanceRatio,
    required this.ph,
    required this.paco2MmHg,
    required this.hco3MeqL,
    required this.sodiumMeqL,
    required this.chlorideMeqL,
    required this.albuminGDl,
    required this.description,
    required this.accentColor,
  });
}

/// Nephrology Master Vitals and Acid-Base Engine State.
class NephroMasterVitalsState extends ChangeNotifier {
  NephroClinicalSituation _activeSituation = NephroClinicalSituation.normalBaseline;
  bool _isAutoPilot = true;

  double _egfrMlMin = 95.0;
  double _rppMmHg = 80.0;
  double _urineOutputMlKgH = 1.2;
  double _serumCreatinineMgDl = 0.9;
  double _bunMgDl = 14.0;
  double _potassiumMeqL = 4.2;
  double _clearanceRatio = 1.0;

  // ABG & Electrolytes
  double _ph = 7.40;
  double _paco2MmHg = 40.0;
  double _hco3MeqL = 24.0;
  double _sodiumMeqL = 140.0;
  double _chlorideMeqL = 102.0;
  double _albuminGDl = 4.0;

  NephroClinicalSituation get activeSituation => _activeSituation;
  bool get isAutoPilot => _isAutoPilot;

  double get egfrMlMin => _egfrMlMin;
  double get rppMmHg => _rppMmHg;
  double get urineOutputMlKgH => _urineOutputMlKgH;
  double get serumCreatinineMgDl => _serumCreatinineMgDl;
  double get bunMgDl => _bunMgDl;
  double get potassiumMeqL => _potassiumMeqL;
  double get clearanceRatio => _clearanceRatio;

  double get ph => _ph;
  double get paco2MmHg => _paco2MmHg;
  double get hco3MeqL => _hco3MeqL;
  double get sodiumMeqL => _sodiumMeqL;
  double get chlorideMeqL => _chlorideMeqL;
  double get albuminGDl => _albuminGDl;

  // ── Derived Acid-Base Calculations ──────────────────────────────────────────

  /// Uncorrected Anion Gap: Na - (Cl + HCO3)
  double get rawAnionGap => _sodiumMeqL - (_chlorideMeqL + _hco3MeqL);

  /// Albumin-Corrected Anion Gap: AG + 2.5 * (4.0 - Albumin)
  double get correctedAnionGap {
    final correction = 2.5 * (4.0 - _albuminGDl);
    return rawAnionGap + correction;
  }

  /// Winter's Formula: Expected PaCO2 = 1.5 * HCO3 + 8 (+/- 2)
  double get winterExpectedPaCO2 => 1.5 * _hco3MeqL + 8.0;

  /// Delta-Delta Ratio: (Corrected AG - 12) / (24 - HCO3)
  double? get deltaDeltaRatio {
    final deltaHco3 = 24.0 - _hco3MeqL;
    if (deltaHco3.abs() < 0.8) return null; // Normal bicarbonate denominator
    final deltaAg = correctedAnionGap - 12.0;
    return deltaAg / deltaHco3;
  }

  bool get isOliguric => _urineOutputMlKgH < 0.5;
  bool get isSevereAki => _egfrMlMin < 30.0;
  bool get isHighAnionGap => correctedAnionGap > 12.0;

  String get acidBaseInterpretation {
    final ag = correctedAnionGap;
    final winter = winterExpectedPaCO2;
    final dd = deltaDeltaRatio;

    if (_ph < 7.35) {
      // Primary Acidosis
      if (_hco3MeqL < 22.0) {
        // Metabolic Acidosis
        final String agType = ag > 12.0 ? 'High Anion Gap (HAGMA)' : 'Normal Anion Gap (NAGMA)';
        String comp = 'Appropriate compensation';
        if (_paco2MmHg > winter + 2.0) {
          comp = 'Concurrent Respiratory Acidosis (PaCO2 > Winter)';
        } else if (_paco2MmHg < winter - 2.0) {
          comp = 'Concurrent Respiratory Alkalosis (PaCO2 < Winter)';
        }

        String deltaNote = '';
        if (ag > 12.0 && dd != null) {
          if (dd < 0.8) {
            deltaNote = ' · Mixed HAGMA + NAGMA (Δ/Δ < 0.8)';
          } else if (dd > 2.0) {
            deltaNote = ' · Concurrent Metabolic Alkalosis (Δ/Δ > 2.0)';
          } else {
            deltaNote = ' · Pure HAGMA (Δ/Δ 0.8–2.0)';
          }
        }
        return 'Metabolic Acidosis ($agType) · $comp$deltaNote';
      } else if (_paco2MmHg > 45.0) {
        return 'Primary Respiratory Acidosis (CO2 Retention)';
      }
    } else if (_ph > 7.45) {
      // Primary Alkalosis
      if (_hco3MeqL > 26.0) {
        return 'Primary Metabolic Alkalosis (Elevated HCO3⁻)';
      } else if (_paco2MmHg < 35.0) {
        return 'Primary Respiratory Alkalosis (Hyperventilation / Sepsis)';
      }
    }
    return 'Normal / Compensated Acid-Base Homeostasis';
  }

  void applySituation(NephroClinicalSituation situation) {
    _activeSituation = situation;
    _isAutoPilot = true;

    _egfrMlMin = situation.egfrMlMin;
    _rppMmHg = situation.rppMmHg;
    _urineOutputMlKgH = situation.urineOutputMlKgH;
    _serumCreatinineMgDl = situation.serumCreatinineMgDl;
    _bunMgDl = situation.bunMgDl;
    _potassiumMeqL = situation.potassiumMeqL;
    _clearanceRatio = situation.clearanceRatio;

    _ph = situation.ph;
    _paco2MmHg = situation.paco2MmHg;
    _hco3MeqL = situation.hco3MeqL;
    _sodiumMeqL = situation.sodiumMeqL;
    _chlorideMeqL = situation.chlorideMeqL;
    _albuminGDl = situation.albuminGDl;

    notifyListeners();
  }

  void setManualValues({
    double? egfr,
    double? rpp,
    double? urineOutput,
    double? creatinine,
    double? bun,
    double? potassium,
    double? clearanceRatio,
    double? ph,
    double? paco2,
    double? hco3,
    double? sodium,
    double? chloride,
    double? albumin,
  }) {
    _isAutoPilot = false;
    if (egfr != null) _egfrMlMin = egfr.clamp(2.0, 160.0);
    if (rpp != null) _rppMmHg = rpp.clamp(10.0, 140.0);
    if (urineOutput != null) _urineOutputMlKgH = urineOutput.clamp(0.0, 5.0);
    if (creatinine != null) _serumCreatinineMgDl = creatinine.clamp(0.2, 18.0);
    if (bun != null) _bunMgDl = bun.clamp(3.0, 200.0);
    if (potassium != null) _potassiumMeqL = potassium.clamp(1.5, 9.5);
    if (clearanceRatio != null) _clearanceRatio = clearanceRatio.clamp(0.05, 1.5);

    if (ph != null) _ph = ph.clamp(6.8, 7.8);
    if (paco2 != null) _paco2MmHg = paco2.clamp(10.0, 110.0);
    if (hco3 != null) _hco3MeqL = hco3.clamp(2.0, 55.0);
    if (sodium != null) _sodiumMeqL = sodium.clamp(105.0, 175.0);
    if (chloride != null) _chlorideMeqL = chloride.clamp(65.0, 140.0);
    if (albumin != null) _albuminGDl = albumin.clamp(1.0, 6.0);

    notifyListeners();
  }

  void resetToAutoPilot() {
    applySituation(_activeSituation);
  }
}

/// Unified Multi-Organ Digital Patient State connecting Cardio, Neuro, and Renal.
class MultiOrganPatientState extends ChangeNotifier {
  static final MultiOrganPatientState instance = MultiOrganPatientState._internal();

  MultiOrganPatientState._internal() {
    _initListeners();
  }

  factory MultiOrganPatientState() => instance;

  bool _isCoupled = true;
  bool _isUpdating = false;

  final CardiacMasterVitalsState cardiacVitals = CardiacMasterVitalsState();
  final NeuroMasterVitalsState neuroVitals = NeuroMasterVitalsState();
  final NephroMasterVitalsState nephroVitals = NephroMasterVitalsState();
  final PulmoMasterVitalsState pulmoVitals = PulmoMasterVitalsState();

  // Embolic stroke alert state
  bool _hasEmbolicRisk = false;
  int _cha2ds2VascScore = 0;

  // Cushing reflex state
  bool _isCushingReflexActive = false;

  bool get isCoupled => _isCoupled;
  bool get hasEmbolicRisk => _hasEmbolicRisk;
  int get cha2ds2VascScore => _cha2ds2VascScore;
  bool get isCushingReflexActive => _isCushingReflexActive;

  void toggleCoupling() {
    _isCoupled = !_isCoupled;
    if (_isCoupled) {
      _synchronizeCrossOrganCascades();
    }
    notifyListeners();
  }

  void setCoupled(bool value) {
    if (_isCoupled != value) {
      _isCoupled = value;
      if (_isCoupled) {
        _synchronizeCrossOrganCascades();
      }
      notifyListeners();
    }
  }

  void setCoupling(bool value) => setCoupled(value);

  void resetAllVitals() {
    cardiacVitals.resetToNormalVitals();
    neuroVitals.resetToAutoPilot();
    nephroVitals.applySituation(NephroClinicalSituation.normalBaseline);
    pulmoVitals.applySituation(PulmoClinicalSituation.normalLungs);
    _hasEmbolicRisk = false;
    _cha2ds2VascScore = 0;
    _isCushingReflexActive = false;
    notifyListeners();
  }

  void _initListeners() {
    cardiacVitals.addListener(_onCardiacChanged);
    neuroVitals.addListener(_onNeuroChanged);
    nephroVitals.addListener(_onNephroChanged);
    pulmoVitals.addListener(_onPulmoChanged);
  }

  void _onCardiacChanged() {
    if (!_isCoupled || _isUpdating) return;
    _isUpdating = true;
    try {
      _cascadeFromCardiac();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void _onNeuroChanged() {
    if (!_isCoupled || _isUpdating) return;
    _isUpdating = true;
    try {
      _cascadeFromNeuro();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void _onNephroChanged() {
    if (!_isCoupled || _isUpdating) return;
    _isUpdating = true;
    try {
      _cascadeFromNephro();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void _onPulmoChanged() {
    if (!_isCoupled || _isUpdating) return;
    _isUpdating = true;
    try {
      _cascadeFromPulmo();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void _synchronizeCrossOrganCascades() {
    _isUpdating = true;
    try {
      _cascadeFromCardiac();
      _cascadeFromNeuro();
      _cascadeFromPulmo();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Cardiorenal & Cardio-Embolic Cascades
  void _cascadeFromCardiac() {
    final lvef = cardiacVitals.lvefPct;
    final map = cardiacVitals.mapBp;
    final isAfib = cardiacVitals.targetRhythm == OscilloscopeRhythmType.afib;

    // 1. Cardiorenal Cascade: Pump failure or MAP < 65 mmHg drops RPP and eGFR
    if (lvef < 30.0 || map < 65.0 || cardiacVitals.activeSituation == CardiacClinicalSituation.cardiogenicShock) {
      final rpp = math.max(25.0, map - 14.0); // MAP - CVP (elevated CVP in shock)
      final egfr = math.max(12.0, (map / 85.0) * (lvef / 60.0) * 85.0);
      final clRatio = (egfr / 95.0).clamp(0.18, 1.0);

      nephroVitals.setManualValues(
        rpp: rpp,
        egfr: egfr,
        urineOutput: math.max(0.12, (rpp / 80.0) * 0.4),
        creatinine: math.min(5.2, 0.9 + (1.0 - clRatio) * 3.5),
        bun: math.min(95.0, 14.0 + (1.0 - clRatio) * 65.0),
        potassium: math.min(6.5, 4.2 + (1.0 - clRatio) * 2.2),
        clearanceRatio: clRatio,
        ph: math.max(7.14, 7.40 - (1.0 - clRatio) * 0.28),
        hco3: math.max(8.0, 24.0 - (1.0 - clRatio) * 16.0),
      );
    }

    // 2. Cardio-Embolic Neuro Cascade: AFib triggers high embolic stroke risk
    if (isAfib) {
      _hasEmbolicRisk = true;
      _cha2ds2VascScore = (lvef < 40.0 ? 1 : 0) + (cardiacVitals.systolicBp >= 140.0 ? 1 : 0) + 2; // Baseline age/AFib
    } else {
      _hasEmbolicRisk = false;
      _cha2ds2VascScore = 0;
    }

    // Sync MAP to Neuro if not in Cushing reflex
    if (!_isCushingReflexActive && neuroVitals.isAutoPilot) {
      neuroVitals.setManualMap(map);
    }
  }

  /// Cushing Reflex Cascade from Neuro
  void _cascadeFromNeuro() {
    final icp = neuroVitals.icpMmHg;

    // Cushing Reflex: Critical intracranial hypertension (ICP > 28 mmHg) triggers
    // reactive sympathetic surge (SBP > 195 mmHg) and reflex baroreceptor bradycardia (HR < 50 bpm).
    if (icp > 28.0) {
      _isCushingReflexActive = true;
      cardiacVitals.setHeartRate(46.0); // Reflex bradycardia
      cardiacVitals.setBloodPressure(205.0, 112.0); // Severe reactive systolic hypertension
    } else {
      _isCushingReflexActive = false;
    }
  }

  /// Renal to Cardio/Neuro Cascades (Hyperkalemia arrhythmogenesis)
  void _cascadeFromNephro() {
    final k = nephroVitals.potassiumMeqL;
    if (k >= 6.8) {
      // Severe hyperkalemia triggers wide-complex rhythm & bradycardia in heart
      cardiacVitals.applyRhythmOverride(OscilloscopeRhythmType.hyperkalemia);
    }
  }

  /// Pulmonary to Cardio, Neuro, and Renal Cascades
  void _cascadeFromPulmo() {
    final peep = pulmoVitals.peepCmH2o;
    final isTension = pulmoVitals.activeSituation == PulmoClinicalSituation.tensionPneumothorax &&
        !pulmoVitals.isChestTubeDecompressed;
    final paco2 = pulmoVitals.paco2MmHg;

    // 1. High PEEP or Tension Pneumothorax compresses vena cava, reducing venous return & BP
    if (isTension || peep >= 16.0) {
      final sbpDrop = isTension ? 35.0 : 18.0;
      final dbpDrop = isTension ? 20.0 : 10.0;
      cardiacVitals.setBloodPressure(
        math.max(55.0, 120.0 - sbpDrop),
        math.max(35.0, 80.0 - dbpDrop),
      );
    }

    // 2. PaCO2 modulates cerebral vasoreactivity (ICP & CBF in NeuroLab 3D)
    if (paco2 > 48.0) {
      // Hypercapnic vasodilation increases ICP
      final icpIncrease = (paco2 - 40.0) * 0.3;
      neuroVitals.setManualIcp(math.min(32.0, 10.0 + icpIncrease));
    }

    // 3. Respiratory Acidosis renal bicarbonate compensation (NephroLab 3D)
    if (paco2 > 45.0 && nephroVitals.isAutoPilot) {
      final hco3Comp = 24.0 + ((paco2 - 40.0) * 0.35);
      nephroVitals.setManualValues(
        hco3: math.min(36.0, hco3Comp),
        paco2: paco2,
      );
    }
  }
}
