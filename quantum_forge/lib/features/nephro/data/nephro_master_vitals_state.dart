// ============================================================================
// NephroLab 3D: Nephrology Master Vitals & Acid-Base Engine State
// ----------------------------------------------------------------------------
// Deterministic clinical mathematical engine simulating:
// 1. Glomerular & Tubular Hemodynamics: RPP, eGFR, Urine Output, Cr, BUN, K+.
// 2. Comprehensive Acid-Base Math:
//    - Uncorrected & Albumin-Corrected Anion Gap (AGcorr = AG + 2.5 * (4 - Alb))
//    - Winter's Formula for respiratory compensation (Expected PaCO2 = 1.5 * HCO3 + 8 ± 2)
//    - Delta-Delta (Δ/Δ) Ratio: (AGcorr - 12) / (24 - HCO3)
// 3. 120-Frame Physiological Renal Cycle & Multi-Species Particle Trajectories:
//    - Phase 1 (0–24): Systolic Pulse Arrival & Afferent Myogenic Stretch
//    - Phase 2 (25–54): Glomerular Ultrafiltration Burst & Podocyte Slit Flux
//    - Phase 3 (55–79): Proximal & Loop Countercurrent Peristalsis
//    - Phase 4 (80–99): Macula Densa NaCl Sensing & Tubuloglomerular Feedback (TGF)
//    - Phase 5 (100–119): Collecting Duct Fine-Tuning & Ureteral Outflow
// 4. 8 Classic Nephrology ICU Situations: Normal, Cardiorenal AKI, DKA, Uremic AKI,
//    Salicylate Toxicity, Diarrhea NAGMA, COPD Retention, Contraction Alkalosis.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';

/// 5-Phase 120-Frame Renal Physiological Cycle
enum RenalCyclePhase {
  afferentMyogenicStretch(
    startFrame: 0,
    endFrame: 24,
    title: 'Phase 1: Systolic Pulse Arrival & Afferent Stretch',
    shortLabel: 'Afferent Stretch',
    accentColor: Color(0xFFEF4444),
    description: 'Renal arterial pulse wave expands afferent arteriole; myogenic vascular response rapidly increases vascular resistance to buffer glomerular capillary pressure.',
  ),
  glomerularUltrafiltrationBurst(
    startFrame: 25,
    endFrame: 54,
    title: 'Phase 2: Glomerular Ultrafiltration Burst',
    shortLabel: 'Ultrafiltration Burst',
    accentColor: Color(0xFF00E5FF),
    description: 'Peak capillary hydrostatic pressure (P_gc ~48-52 mmHg) drives net ultrafiltration across fenestrated endothelium, GBM, and podocyte slit diaphragms into Bowman space.',
  ),
  countercurrentPeristalsis(
    startFrame: 55,
    endFrame: 79,
    title: 'Phase 3: Proximal & Loop Countercurrent Peristalsis',
    shortLabel: 'Loop Peristalsis',
    accentColor: Color(0xFFFFB300),
    description: 'Bulk reabsorption of 65% Na+/water in PCT (SGLT2/NHE3); medullary countercurrent multiplier establishes 300->1200 mOsm/kg hyperosmolar interstitial gradient.',
  ),
  maculaDensaTubuloglomerularFeedback(
    startFrame: 80,
    endFrame: 99,
    title: 'Phase 4: Macula Densa NaCl Sensing & TGF',
    shortLabel: 'Macula Densa / TGF',
    accentColor: Color(0xFFBA68C8),
    description: 'Early DCT macula densa cells sense luminal NaCl delivery via NKCC2; elevated salt triggers paracrine adenosine release, constricting afferent arteriole to protect GFR.',
  ),
  collectingDuctFineTuning(
    startFrame: 100,
    endFrame: 119,
    title: 'Phase 5: Collecting Duct Fine-Tuning & Ureteral Outflow',
    shortLabel: 'CD Fine-Tuning',
    accentColor: Color(0xFF00E676),
    description: 'Aldosterone/ENaC modulates distal Na+/K+ exchange; ADH mobilizes AQP2 aquaporins to concentrate urine; final filtrate propelled by ureteral peristalsis.',
  );

  final int startFrame;
  final int endFrame;
  final String title;
  final String shortLabel;
  final Color accentColor;
  final String description;

  const RenalCyclePhase({
    required this.startFrame,
    required this.endFrame,
    required this.title,
    required this.shortLabel,
    required this.accentColor,
    required this.description,
  });

  static RenalCyclePhase fromFrame(int frame) {
    final clamped = frame.clamp(0, 119);
    for (final phase in RenalCyclePhase.values) {
      if (clamped >= phase.startFrame && clamped <= phase.endFrame) {
        return phase;
      }
    }
    return RenalCyclePhase.afferentMyogenicStretch;
  }
}

/// 7 Synchronized Animation Layer Modes
enum NephroAnimationLayerMode {
  allInOne('all_in_one', 'All In One', 'Full micro-vascular, tubular & transporter architecture'),
  glomerularFiltration('filtration', 'Glomerular Filtration', 'Filtration barrier, podocyte slit pores, and ultrafiltrate stream'),
  tubularTransport('tubular', 'Tubular Transport', 'Active ion counters, solute reabsorption, and brush border'),
  hemodynamicsVasaRecta('vasculature', 'Hemodynamics & Vasa Recta', 'Capillary countercurrent vascular loops and RBC transition'),
  jgaRaasSignaling('jga_raas', 'JGA & RAAS Signaling', 'Macula densa NaCl sensor, renin granule exocytosis, and TGF feedback'),
  podocyteUltrastructure('podocyte', 'Podocyte Ultrastructure', 'Slit diaphragm pedicel interdigitations and nephrin integrity'),
  drugPathologyAction('drug_action', 'Drug / Pathology Action', 'Pharmacological binding gates and lesion visualizations');

  final String id;
  final String label;
  final String description;

  const NephroAnimationLayerMode(this.id, this.label, this.description);
}

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

  String get label => shortLabel;

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

  // 120-Frame Physiological Kinematics & Multi-Species Particle Trajectories
  int _currentFrame = 0;
  bool _isPlaying = true;
  double _playbackSpeed = 1.0;
  double _heartRate = 72.0;
  bool _isTracerActive = false;
  double _tracerProgress = 0.0;
  NephroAnimationLayerMode _layerMode = NephroAnimationLayerMode.allInOne;
  double _afferentTone = 1.0; // 1.0 normal, <1.0 constricted (SGLT2i/NSAIDs), >1.0 dilated
  double _efferentTone = 1.0; // 1.0 normal, >1.0 dilated (ACEi/ARBs)
  double _accumulatedSeconds = 0.0;

  NephroClinicalSituation get activeSituation => _activeSituation;
  NephroClinicalSituation get currentSituation => _activeSituation;
  bool get isAutoPilot => _isAutoPilot;

  double get egfrMlMin => _egfrMlMin;
  double get egfr => _egfrMlMin;
  set egfr(double v) {
    _egfrMlMin = v;
    notifyListeners();
  }

  double get rppMmHg => _rppMmHg;
  double get rpp => _rppMmHg;
  set rpp(double v) {
    _rppMmHg = v;
    notifyListeners();
  }

  double get map => _rppMmHg + 6.0;

  double get urineOutputMlKgH => _urineOutputMlKgH;
  double get urineOutput => _urineOutputMlKgH * 70.0;
  set urineOutput(double v) {
    _urineOutputMlKgH = v / 70.0;
    notifyListeners();
  }

  double get serumCreatinineMgDl => _serumCreatinineMgDl;
  double get bunMgDl => _bunMgDl;
  double get potassiumMeqL => _potassiumMeqL;
  double get potassium => _potassiumMeqL;
  set potassium(double v) {
    _potassiumMeqL = v;
    notifyListeners();
  }

  double get clearanceRatio => _clearanceRatio;

  double get ph => _ph;
  set ph(double v) {
    _ph = v;
    notifyListeners();
  }

  double get paco2MmHg => _paco2MmHg;
  double get paco2 => _paco2MmHg;
  set paco2(double v) {
    _paco2MmHg = v;
    notifyListeners();
  }

  double get hco3MeqL => _hco3MeqL;
  double get bicarb => _hco3MeqL;
  set bicarb(double v) {
    _hco3MeqL = v;
    notifyListeners();
  }

  double get sodiumMeqL => _sodiumMeqL;
  double get sodium => _sodiumMeqL;
  set sodium(double v) {
    _sodiumMeqL = v;
    notifyListeners();
  }

  double get chlorideMeqL => _chlorideMeqL;
  double get chloride => _chlorideMeqL;
  set chloride(double v) {
    _chlorideMeqL = v;
    notifyListeners();
  }

  double get albuminGDl => _albuminGDl;

  bool get isRenalArteryStenosis => _rppMmHg < 65.0 && _activeSituation == NephroClinicalSituation.cardiorenalAki;
  bool get isAkiActive => _egfrMlMin < 40.0;

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

  // ── 120-Frame Physiological Kinematics & Particle Trajectory Controls ────────

  int get currentFrame => _currentFrame;
  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  double get heartRate => _heartRate;
  bool get isTracerActive => _isTracerActive;
  double get tracerProgress => _tracerProgress;
  NephroAnimationLayerMode get layerMode => _layerMode;
  double get afferentTone => _afferentTone;
  double get efferentTone => _efferentTone;
  RenalCyclePhase get currentPhase => RenalCyclePhase.fromFrame(_currentFrame);

  void setFrame(int frame) {
    _currentFrame = frame.clamp(0, 119);
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setIsPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.05, 3.0);
    notifyListeners();
  }

  void setHeartRate(double bpm) {
    _heartRate = bpm.clamp(30.0, 220.0);
    notifyListeners();
  }

  void injectGfrTracer() {
    _isTracerActive = true;
    _tracerProgress = 0.0;
    notifyListeners();
  }

  void setAnimationLayerMode(NephroAnimationLayerMode mode) {
    _layerMode = mode;
    notifyListeners();
  }

  void setVasomotorTone({double? afferentTone, double? efferentTone}) {
    bool changed = false;
    if (afferentTone != null && afferentTone != _afferentTone) {
      _afferentTone = afferentTone.clamp(0.5, 1.8);
      changed = true;
    }
    if (efferentTone != null && efferentTone != _efferentTone) {
      _efferentTone = efferentTone.clamp(0.5, 1.8);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Advances physiological cycle by [dt] seconds.
  /// 1 full 120-frame cycle corresponds to 1 cardiac stroke (60.0 / heartRate seconds).
  void advanceFrame(double dt) {
    if (!_isPlaying) return;

    final cycleDurationSec = 60.0 / _heartRate;
    final framesPerSecond = (120.0 / cycleDurationSec) * _playbackSpeed;

    _accumulatedSeconds += dt;
    final int framesToAdvance = (_accumulatedSeconds * framesPerSecond).floor();
    if (framesToAdvance > 0) {
      _currentFrame = (_currentFrame + framesToAdvance) % 120;
      _accumulatedSeconds -= framesToAdvance / framesPerSecond;

      if (_isTracerActive) {
        // FITC-inulin bolus transit takes ~4 complete cycles to clear
        _tracerProgress += (dt / (cycleDurationSec * 4.0)) * _playbackSpeed;
        if (_tracerProgress >= 1.0) {
          _tracerProgress = 1.0;
          _isTracerActive = false;
        }
      }

      notifyListeners();
    }
  }
}
