// ============================================================================
// Master Patient Vitals & Hemodynamics State (Unified Physiological Model)
// ----------------------------------------------------------------------------
// Single source of truth coordinating patient vital signs and hemodynamics
// across CardioCath 3D Lab:
// 1. 3D Anatomical Heart & Cine Fluoroscopy (Contraction velocity & LVEF excursion)
// 2. 5-Channel Hospital Oscilloscope (Lead II, V1, ABP, SpO2, EtCO2 & ICU tiles)
// 3. 6-Module Diagnostic Workstation (Echo Doppler, Auscultation, EP, PV Loop, CHD, Neuro-Tilt)
// 4. PyTorch Computational Research & Fellowship Suites (CardioElectrophys-Net & CardioPINN)
// Strictly follows the SaMD 7-Pillar Educational Simulation Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'cardiac_pathology_models.dart';
import 'coronary_hemodynamics_engine.dart';

/// Bedside acute cardiac situations and disease states for auto-pilot simulation.
enum CardiacClinicalSituation {
  normal(
    id: 'normal',
    title: 'Normal Sinus Baseline',
    shortLabel: 'Normal',
    badge: 'NSR',
    heartRateBpm: 72.0,
    systolicBp: 120.0,
    diastolicBp: 80.0,
    spo2Pct: 99.0,
    respRate: 14.0,
    etco2MmHg: 38.0,
    lvefPct: 60.0,
    rhythm: OscilloscopeRhythmType.nsr,
    stElevationMm: 0.0,
    description: 'Euvolemic baseline, normal cardiac output (5.2 L/min) and tissue perfusion.',
    accentColor: Color(0xFF00E676),
  ),
  anteriorStemi(
    id: 'anterior_stemi',
    title: 'Acute Anterior STEMI',
    shortLabel: 'Anterior STEMI',
    badge: 'STEMI',
    heartRateBpm: 104.0,
    systolicBp: 98.0,
    diastolicBp: 64.0,
    spo2Pct: 94.0,
    respRate: 20.0,
    etco2MmHg: 34.0,
    lvefPct: 38.0,
    rhythm: OscilloscopeRhythmType.sinusTachy,
    stElevationMm: 4.5,
    description: 'LAD occlusion, acute anterior wall hypokinesis, ST elevation in V1–V4, borderline cardiogenic perfusion.',
    accentColor: Color(0xFFFF5252),
  ),
  inferiorRvMi(
    id: 'inferior_rv_mi',
    title: 'Inferior MI + RV Involvement',
    shortLabel: 'Inferior/RV MI',
    badge: 'RV-INFARCT',
    heartRateBpm: 52.0,
    systolicBp: 84.0,
    diastolicBp: 50.0,
    spo2Pct: 95.0,
    respRate: 18.0,
    etco2MmHg: 33.0,
    lvefPct: 48.0,
    rhythm: OscilloscopeRhythmType.sinusBrady,
    stElevationMm: 3.8,
    description: 'RCA occlusion, Bezold-Jarisch reflex bradycardia, preload-dependent (Nitroglycerin contraindicated).',
    accentColor: Color(0xFFFF7043),
  ),
  cardiogenicShock(
    id: 'cardiogenic_shock',
    title: 'Cardiogenic Shock',
    shortLabel: 'Cardiogenic Shock',
    badge: 'SHOCK',
    heartRateBpm: 126.0,
    systolicBp: 76.0,
    diastolicBp: 48.0,
    spo2Pct: 88.0,
    respRate: 26.0,
    etco2MmHg: 26.0,
    lvefPct: 22.0,
    rhythm: OscilloscopeRhythmType.sinusTachy,
    stElevationMm: 2.0,
    description: 'Severe pump failure (LVEF 22%), high SVR compensatory vasoconstriction, critical hypoperfusion.',
    accentColor: Color(0xFFFF1744),
  ),
  hypertensiveCrisis(
    id: 'hypertensive_crisis',
    title: 'Hypertensive Emergency',
    shortLabel: 'Hypertensive Crisis',
    badge: 'HYPERTENSION',
    heartRateBpm: 96.0,
    systolicBp: 210.0,
    diastolicBp: 124.0,
    spo2Pct: 97.0,
    respRate: 18.0,
    etco2MmHg: 39.0,
    lvefPct: 55.0,
    rhythm: OscilloscopeRhythmType.nsr,
    stElevationMm: -1.5,
    description: 'Acute severe afterload excess (MAP 153 mmHg), high wall tension, subendocardial strain.',
    accentColor: Color(0xFFFF9100),
  ),
  massivePe(
    id: 'massive_pe',
    title: 'Acute Massive Pulmonary Embolism',
    shortLabel: 'Massive PE',
    badge: 'MASSIVE PE',
    heartRateBpm: 132.0,
    systolicBp: 86.0,
    diastolicBp: 54.0,
    spo2Pct: 85.0,
    respRate: 28.0,
    etco2MmHg: 22.0,
    lvefPct: 58.0,
    rhythm: OscilloscopeRhythmType.sinusTachy,
    stElevationMm: 0.0,
    description: 'Severe RV outflow obstruction, massive V/Q mismatch with acute EtCO2 drop to 22 mmHg, sinus tachycardia.',
    accentColor: Color(0xFF00E5FF),
  ),
  tamponade(
    id: 'tamponade',
    title: 'Cardiac Tamponade (Beck\'s Triad)',
    shortLabel: 'Tamponade',
    badge: 'TAMPONADE',
    heartRateBpm: 128.0,
    systolicBp: 82.0,
    diastolicBp: 62.0,
    spo2Pct: 92.0,
    respRate: 24.0,
    etco2MmHg: 29.0,
    lvefPct: 50.0,
    rhythm: OscilloscopeRhythmType.sinusTachy,
    stElevationMm: 1.0,
    description: 'Pericardial fluid compression, narrow pulse pressure (20 mmHg), muffled sounds, pulsus paradoxus.',
    accentColor: Color(0xFFA78BFA),
  ),
  decompensatedHfref(
    id: 'decompensated_hfref',
    title: 'Acute Decompensated HFrEF',
    shortLabel: 'Acute HFrEF',
    badge: 'HFrEF + AFIB',
    heartRateBpm: 108.0,
    systolicBp: 102.0,
    diastolicBp: 68.0,
    spo2Pct: 89.0,
    respRate: 26.0,
    etco2MmHg: 31.0,
    lvefPct: 25.0,
    rhythm: OscilloscopeRhythmType.afib,
    stElevationMm: -0.5,
    description: 'End-stage heart failure decompensation, rapid A-Fib, severe systolic impairment, pulmonary congestion.',
    accentColor: Color(0xFFE040FB),
  ),
  hyperkalemia(
    id: 'hyperkalemia',
    title: 'Severe Hyperkalemia (K⁺ 7.2 mEq/L)',
    shortLabel: 'Hyperkalemia',
    badge: 'HYPER-K (K⁺ 7.2)',
    heartRateBpm: 68.0,
    systolicBp: 118.0,
    diastolicBp: 76.0,
    spo2Pct: 98.0,
    respRate: 16.0,
    etco2MmHg: 38.0,
    lvefPct: 56.0,
    rhythm: OscilloscopeRhythmType.hyperkalemia,
    stElevationMm: 0.0,
    description: 'Serum K⁺ 7.2 mEq/L: tall tented T-waves (+0.85 mV), widened QRS (148 ms), flattened P-wave (+0.04 mV), prolonged PR (215 ms). IV Calcium Gluconate indicated.',
    accentColor: Color(0xFFFF5252),
  ),
  hypokalemia(
    id: 'hypokalemia',
    title: 'Severe Hypokalemia (K⁺ 2.4 mEq/L)',
    shortLabel: 'Hypokalemia',
    badge: 'HYPO-K (K⁺ 2.4)',
    heartRateBpm: 78.0,
    systolicBp: 112.0,
    diastolicBp: 72.0,
    spo2Pct: 98.0,
    respRate: 16.0,
    etco2MmHg: 37.0,
    lvefPct: 58.0,
    rhythm: OscilloscopeRhythmType.hypokalemia,
    stElevationMm: -0.8,
    description: 'Serum K⁺ 2.4 mEq/L: flattened T-wave (+0.07 mV), prominent upright U-wave (+0.24 mV), prolonged QU/QTc (490 ms). Risk of Torsades de Pointes; IV KCl replacement required.',
    accentColor: Color(0xFFFFB74D),
  ),
  myocardialIschemia(
    id: 'myocardial_ischemia',
    title: 'Subendocardial Ischemia (NSTEMI / Angina)',
    shortLabel: 'Ischemia',
    badge: 'ISCHEMIA (ST↓+T-Inv)',
    heartRateBpm: 102.0,
    systolicBp: 148.0,
    diastolicBp: 92.0,
    spo2Pct: 95.0,
    respRate: 20.0,
    etco2MmHg: 36.0,
    lvefPct: 45.0,
    rhythm: OscilloscopeRhythmType.ischemia,
    stElevationMm: -2.5,
    description: 'Acute subendocardial ischemia (NSTEMI / Angina): horizontal/downsloping ST depression (-0.25 mV) and symmetrical deep T-wave inversion (-0.35 mV). Coupled with elevated afterload and tachycardia.',
    accentColor: Color(0xFFFF9100),
  );

  final String id;
  final String title;
  final String shortLabel;
  final String badge;
  final double heartRateBpm;
  final double systolicBp;
  final double diastolicBp;
  final double spo2Pct;
  final double respRate;
  final double etco2MmHg;
  final double lvefPct;
  final OscilloscopeRhythmType rhythm;
  final double stElevationMm;
  final String description;
  final Color accentColor;

  const CardiacClinicalSituation({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.badge,
    required this.heartRateBpm,
    required this.systolicBp,
    required this.diastolicBp,
    required this.spo2Pct,
    required this.respRate,
    required this.etco2MmHg,
    required this.lvefPct,
    required this.rhythm,
    required this.stElevationMm,
    required this.description,
    required this.accentColor,
  });
}

/// Emergency intravenous medications for live bedside ward simulation.
enum IvEmergencyMedication {
  adenosine(
    'Adenosine 6mg IV',
    'A1 receptor agonist → Transient AV nodal block / 2.5s pause, converts SVT → NSR (76 bpm)',
    Color(0xFFFFD600),
  ),
  atropine(
    'Atropine 1mg IV',
    'Muscarinic M2 antagonist → Blocks vagal tone, accelerates Sinus Bradycardia (45 → 85 bpm)',
    Color(0xFF00E676),
  ),
  norepinephrine(
    'Norepinephrine 4mcg/min',
    'Alpha-1 vasoconstrictor & Beta-1 inotrope → Elevates ABP to 125/82 (MAP 96 mmHg)',
    Color(0xFFFF5252),
  ),
  nitroglycerin(
    'Nitroglycerin 10mcg/min',
    'Venodilator / Preload reduction → Blunts ST elevation; in RV Infarct drops ABP to 72/42 mmHg (Contraindicated!)',
    Color(0xFF00E5FF),
  ),
  amiodaroneHerg(
    'Amiodarone (hERG Challenge)',
    'Class III IKr block → Extends QTc > 540 ms, triggers Polymorphic VT / Torsades de Pointes',
    Color(0xFFA78BFA),
  ),
  magnesiumSulfate(
    'Magnesium Sulfate 2g IV',
    'Suppresses EADs / Ca2+ influx → Terminates Torsades de Pointes, restores NSR (80 bpm)',
    Color(0xFF69F0AE),
  );

  final String label;
  final String description;
  final Color color;

  String get mechanism => description;
  Color get badgeColor => color;

  const IvEmergencyMedication(this.label, this.description, this.color);
}

/// Unified physiological state coordinating vital signs and hemodynamic parameters across all modules.
class CardiacMasterVitalsState extends ChangeNotifier {
  double _heartRateBpm;
  double _systolicBp;
  double _diastolicBp;
  double _spo2Pct;
  double _respRate;
  double _etco2MmHg;
  double _lvefPct;

  // ── Auto-Pilot vs. Manual Override State ────────────────────────────────────
  CardiacClinicalSituation _activeSituation = CardiacClinicalSituation.normal;
  bool _isManualOverride = false;
  double _stElevationMm = 0.0;
  OscilloscopeRhythmType _targetRhythm = OscilloscopeRhythmType.nsr;

  CardiacMasterVitalsState({
    double heartRateBpm = 72.0,
    double systolicBp = 120.0,
    double diastolicBp = 80.0,
    double spo2Pct = 99.0,
    double respRate = 14.0,
    double etco2MmHg = 38.0,
    double lvefPct = 60.0,
    CardiacClinicalSituation activeSituation = CardiacClinicalSituation.normal,
    bool isManualOverride = false,
  })  : _heartRateBpm = heartRateBpm.clamp(30.0, 220.0),
        _systolicBp = systolicBp.clamp(60.0, 220.0),
        _diastolicBp = diastolicBp.clamp(35.0, 130.0),
        _spo2Pct = spo2Pct.clamp(60.0, 100.0),
        _respRate = respRate.clamp(6.0, 40.0),
        _etco2MmHg = etco2MmHg.clamp(10.0, 70.0),
        _lvefPct = lvefPct.clamp(15.0, 75.0),
        _activeSituation = activeSituation,
        _stElevationMm = activeSituation.stElevationMm,
        _targetRhythm = activeSituation.rhythm {
    _isManualOverride = isManualOverride;
  }

  // ── Primary Getters ─────────────────────────────────────────────────────────

  double get heartRateBpm => _heartRateBpm;
  double get systolicBp => _systolicBp;
  double get diastolicBp => _diastolicBp;
  double get spo2Pct => _spo2Pct;
  double get respRate => _respRate;
  double get etco2MmHg => _etco2MmHg;
  double get lvefPct => _lvefPct;

  CardiacClinicalSituation get activeSituation => _activeSituation;
  bool get isManualOverride => _isManualOverride;
  double get stElevationMm => _stElevationMm;
  OscilloscopeRhythmType get targetRhythm => _targetRhythm;

  // ── Derived Physiological Metrics ──────────────────────────────────────────

  /// Mean Arterial Pressure: MAP = DBP + 1/3 (SBP - DBP) [mmHg]
  double get mapBp => _diastolicBp + (_systolicBp - _diastolicBp) / 3.0;

  /// Basic Cardiac Cycle Length (BCL): 60,000 / HR [ms]
  double get cycleLengthMs =>
      _heartRateBpm > 0 ? (60000.0 / _heartRateBpm) : 1000.0;

  /// Estimated Stroke Volume based on baseline 120 mL EDV scaled by LVEF [mL]
  double get strokeVolumeMl =>
      (120.0 * (_lvefPct / 100.0)).clamp(15.0, 130.0);

  /// Cardiac Output: (HR * SV) / 1000.0 [L/min]
  double get cardiacOutputLMin =>
      (_heartRateBpm * strokeVolumeMl) / 1000.0;

  /// Systemic Vascular Resistance index estimation [dynes*s/cm5]
  double get estimatedSvrDynes =>
      cardiacOutputLMin > 0 ? ((mapBp - 4.0) / cardiacOutputLMin) * 80.0 : 1200.0;

  // ── Auto-Pilot Clinical Situation Triggers ─────────────────────────────────

  /// Triggers an acute clinical situation, atomically aligning all vitals,
  /// rhythm, and ST-segment state while setting isManualOverride = false.
  void triggerSituation(CardiacClinicalSituation situation) {
    _activeSituation = situation;
    _isManualOverride = false;
    _heartRateBpm = situation.heartRateBpm;
    _systolicBp = situation.systolicBp;
    _diastolicBp = situation.diastolicBp;
    _spo2Pct = situation.spo2Pct;
    _respRate = situation.respRate;
    _etco2MmHg = situation.etco2MmHg;
    _lvefPct = situation.lvefPct;
    _stElevationMm = situation.stElevationMm;
    _targetRhythm = situation.rhythm;
    notifyListeners();
  }

  /// Re-synchronizes manual adjustments back to the active auto-situation baseline.
  void syncToActiveSituation() {
    triggerSituation(_activeSituation);
  }

  /// Alias for syncToActiveSituation to support alternate prompt naming.
  void resyncAutoVitals() {
    triggerSituation(_activeSituation);
  }

  // ── Direct Interactive Setters (Manual Override) ───────────────────────────

  void setHeartRate(double bpm) {
    final clamped = bpm.clamp(30.0, 220.0);
    _isManualOverride = true;
    _heartRateBpm = clamped;
    notifyListeners();
  }

  void setBloodPressure(double sys, double dia) {
    final clampedSys = sys.clamp(60.0, 220.0);
    final clampedDia = dia.clamp(35.0, math.min<double>(130.0, clampedSys - 10.0)).toDouble();
    _isManualOverride = true;
    _systolicBp = clampedSys;
    _diastolicBp = clampedDia;
    notifyListeners();
  }

  void setSystolicBp(double sys) {
    final clampedSys = sys.clamp(60.0, 220.0);
    _isManualOverride = true;
    _systolicBp = clampedSys;
    if (_diastolicBp >= _systolicBp) {
      _diastolicBp = (_systolicBp - 15.0).clamp(35.0, 130.0);
    }
    notifyListeners();
  }

  void setDiastolicBp(double dia) {
    final clampedDia = dia.clamp(35.0, math.min<double>(130.0, _systolicBp - 10.0)).toDouble();
    _isManualOverride = true;
    _diastolicBp = clampedDia;
    notifyListeners();
  }

  void setSpo2(double pct) {
    final clamped = pct.clamp(60.0, 100.0);
    _isManualOverride = true;
    _spo2Pct = clamped;
    notifyListeners();
  }

  void setRespiration(double rr, double etco2) {
    final clampedRr = rr.clamp(6.0, 40.0);
    final clampedEtco2 = etco2.clamp(10.0, 70.0);
    _isManualOverride = true;
    _respRate = clampedRr;
    _etco2MmHg = clampedEtco2;
    notifyListeners();
  }

  void setRespRate(double rr) {
    final clamped = rr.clamp(6.0, 40.0);
    _isManualOverride = true;
    _respRate = clamped;
    notifyListeners();
  }

  void setEtco2(double etco2) {
    final clamped = etco2.clamp(10.0, 70.0);
    _isManualOverride = true;
    _etco2MmHg = clamped;
    notifyListeners();
  }

  void setLvef(double ef) {
    final clamped = ef.clamp(15.0, 75.0);
    _isManualOverride = true;
    _lvefPct = clamped;
    notifyListeners();
  }

  // ── Bi-Directional Synchronizers ───────────────────────────────────────────

  /// Updates vitals to match the physiological phenotype of a clinical scenario.
  void applyScenarioPreset(CardiacPathologyScenario scenario) {
    final id = scenario.id;
    if (id.contains('anterior_stemi')) {
      triggerSituation(CardiacClinicalSituation.anteriorStemi);
    } else if (id.contains('inferior_mi')) {
      triggerSituation(CardiacClinicalSituation.inferiorRvMi);
    } else if (id.contains('shock') || id.contains('cardiogenic')) {
      triggerSituation(CardiacClinicalSituation.cardiogenicShock);
    } else if (id.contains('hypertensive')) {
      triggerSituation(CardiacClinicalSituation.hypertensiveCrisis);
    } else if (id.contains('pulmonary_embolism') || id.contains('massive_pe')) {
      triggerSituation(CardiacClinicalSituation.massivePe);
    } else if (id.contains('tamponade')) {
      triggerSituation(CardiacClinicalSituation.tamponade);
    } else if (id.contains('hfref') || id.contains('heart_failure')) {
      triggerSituation(CardiacClinicalSituation.decompensatedHfref);
    } else {
      triggerSituation(CardiacClinicalSituation.normal);
    }
  }

  /// Applies acute pharmacological hemodynamic shifts from emergency IV medications.
  void applyIvDrugEffect(IvEmergencyMedication drug) {
    _isManualOverride = true;
    switch (drug) {
      case IvEmergencyMedication.adenosine:
        // Converts SVT to NSR with normal hemodynamics
        _heartRateBpm = 76.0;
        _systolicBp = 118.0;
        _diastolicBp = 76.0;
        _spo2Pct = 98.0;
        _respRate = 14.0;
        _etco2MmHg = 38.0;
        _lvefPct = 60.0;
        _targetRhythm = OscilloscopeRhythmType.nsr;
        break;

      case IvEmergencyMedication.atropine:
        // M2 muscarinic blockade accelerates sinus bradycardia
        _heartRateBpm = 85.0;
        _systolicBp = 122.0;
        _diastolicBp = 80.0;
        _spo2Pct = 98.0;
        _respRate = 15.0;
        _etco2MmHg = 39.0;
        _lvefPct = 62.0;
        _targetRhythm = OscilloscopeRhythmType.nsr;
        break;

      case IvEmergencyMedication.norepinephrine:
        // Potent alpha-1 vasoconstriction & beta-1 inotropy
        _heartRateBpm = 80.0;
        _systolicBp = 125.0;
        _diastolicBp = 82.0;
        _spo2Pct = 98.0;
        _respRate = 16.0;
        _etco2MmHg = 39.0;
        _lvefPct = 65.0;
        break;

      case IvEmergencyMedication.nitroglycerin:
        // Venodilator preload reduction; severe hypotension if RV infarct
        _heartRateBpm = 88.0;
        _systolicBp = 98.0;
        _diastolicBp = 62.0;
        _spo2Pct = 98.0;
        _respRate = 14.0;
        _etco2MmHg = 37.0;
        _lvefPct = 58.0;
        break;

      case IvEmergencyMedication.amiodaroneHerg:
        // hERG blockade / QTc prolongation / Torsades trigger
        _heartRateBpm = 180.0;
        _systolicBp = 78.0;
        _diastolicBp = 52.0;
        _spo2Pct = 86.0;
        _respRate = 26.0;
        _etco2MmHg = 24.0;
        _lvefPct = 25.0;
        _targetRhythm = OscilloscopeRhythmType.torsades;
        break;

      case IvEmergencyMedication.magnesiumSulfate:
        // Membrane stabilization terminates Torsades back to NSR
        _heartRateBpm = 80.0;
        _systolicBp = 120.0;
        _diastolicBp = 78.0;
        _spo2Pct = 98.0;
        _respRate = 14.0;
        _etco2MmHg = 38.0;
        _lvefPct = 58.0;
        _targetRhythm = OscilloscopeRhythmType.nsr;
        break;
    }
    notifyListeners();
  }

  /// Updates vitals when an arrhythmia or conduction block is selected on the monitor.
  void applyRhythmOverride(OscilloscopeRhythmType rhythm) {
    _targetRhythm = rhythm;
    _isManualOverride = true;
    if (rhythm.defaultHr > 0) {
      _heartRateBpm = rhythm.defaultHr.toDouble();
    }
    _systolicBp = rhythm.defaultSys.toDouble().clamp(60.0, 220.0);
    _diastolicBp = rhythm.defaultDia.toDouble().clamp(35.0, 130.0);
    _spo2Pct = rhythm.defaultSpo2.clamp(60.0, 100.0);
    _etco2MmHg = rhythm.defaultEtco2.clamp(10.0, 70.0);

    if (rhythm.isArrest) {
      _respRate = 6.0;
      _lvefPct = 15.0;
      _stElevationMm = 0.0;
    } else if (rhythm == OscilloscopeRhythmType.vtach ||
        rhythm == OscilloscopeRhythmType.torsades) {
      _respRate = 24.0;
      _lvefPct = 25.0;
      _stElevationMm = 0.0;
    } else if (rhythm == OscilloscopeRhythmType.sinusTachy ||
        rhythm == OscilloscopeRhythmType.svt) {
      _respRate = 22.0;
      _lvefPct = 65.0;
      _stElevationMm = 0.0;
    } else if (rhythm == OscilloscopeRhythmType.sinusBrady) {
      _respRate = 12.0;
      _lvefPct = 58.0;
      _stElevationMm = 0.0;
    } else if (rhythm == OscilloscopeRhythmType.hyperkalemia) {
      _respRate = 16.0;
      _lvefPct = 56.0;
      _stElevationMm = 0.0;
    } else if (rhythm == OscilloscopeRhythmType.hypokalemia) {
      _respRate = 16.0;
      _lvefPct = 58.0;
      _stElevationMm = -0.8;
    } else if (rhythm == OscilloscopeRhythmType.stemi) {
      _respRate = 20.0;
      _lvefPct = 38.0;
      _stElevationMm = 4.5;
    } else if (rhythm == OscilloscopeRhythmType.ischemia) {
      _respRate = 20.0;
      _lvefPct = 45.0;
      _stElevationMm = -2.5;
    } else {
      _respRate = 14.0;
      _lvefPct = 60.0;
      _stElevationMm = 0.0;
    }

    notifyListeners();
  }

  /// Resets patient vitals to textbook normal physiological parameters.
  void resetToNormalVitals() {
    triggerSituation(CardiacClinicalSituation.normal);
  }
}
