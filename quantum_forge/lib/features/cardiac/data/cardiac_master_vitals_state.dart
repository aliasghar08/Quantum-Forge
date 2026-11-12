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

  CardiacMasterVitalsState({
    double heartRateBpm = 72.0,
    double systolicBp = 120.0,
    double diastolicBp = 80.0,
    double spo2Pct = 99.0,
    double respRate = 14.0,
    double etco2MmHg = 38.0,
    double lvefPct = 60.0,
  })  : _heartRateBpm = heartRateBpm.clamp(30.0, 220.0),
        _systolicBp = systolicBp.clamp(60.0, 220.0),
        _diastolicBp = diastolicBp.clamp(35.0, 130.0),
        _spo2Pct = spo2Pct.clamp(60.0, 100.0),
        _respRate = respRate.clamp(6.0, 40.0),
        _etco2MmHg = etco2MmHg.clamp(10.0, 70.0),
        _lvefPct = lvefPct.clamp(15.0, 75.0);

  // ── Primary Getters ─────────────────────────────────────────────────────────

  double get heartRateBpm => _heartRateBpm;
  double get systolicBp => _systolicBp;
  double get diastolicBp => _diastolicBp;
  double get spo2Pct => _spo2Pct;
  double get respRate => _respRate;
  double get etco2MmHg => _etco2MmHg;
  double get lvefPct => _lvefPct;

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

  // ── Direct Interactive Setters ─────────────────────────────────────────────

  void setHeartRate(double bpm) {
    final clamped = bpm.clamp(30.0, 220.0);
    if ((_heartRateBpm - clamped).abs() > 0.1) {
      _heartRateBpm = clamped;
      notifyListeners();
    }
  }

  void setBloodPressure(double sys, double dia) {
    final clampedSys = sys.clamp(60.0, 220.0);
    final clampedDia = dia.clamp(35.0, math.min<double>(130.0, clampedSys - 10.0)).toDouble();
    if ((_systolicBp - clampedSys).abs() > 0.1 ||
        (_diastolicBp - clampedDia).abs() > 0.1) {
      _systolicBp = clampedSys;
      _diastolicBp = clampedDia;
      notifyListeners();
    }
  }

  void setSystolicBp(double sys) {
    final clampedSys = sys.clamp(60.0, 220.0);
    if ((_systolicBp - clampedSys).abs() > 0.1) {
      _systolicBp = clampedSys;
      if (_diastolicBp >= _systolicBp) {
        _diastolicBp = (_systolicBp - 15.0).clamp(35.0, 130.0);
      }
      notifyListeners();
    }
  }

  void setDiastolicBp(double dia) {
    final clampedDia = dia.clamp(35.0, math.min<double>(130.0, _systolicBp - 10.0)).toDouble();
    if ((_diastolicBp - clampedDia).abs() > 0.1) {
      _diastolicBp = clampedDia;
      notifyListeners();
    }
  }

  void setSpo2(double pct) {
    final clamped = pct.clamp(60.0, 100.0);
    if ((_spo2Pct - clamped).abs() > 0.1) {
      _spo2Pct = clamped;
      notifyListeners();
    }
  }

  void setRespiration(double rr, double etco2) {
    final clampedRr = rr.clamp(6.0, 40.0);
    final clampedEtco2 = etco2.clamp(10.0, 70.0);
    if ((_respRate - clampedRr).abs() > 0.1 ||
        (_etco2MmHg - clampedEtco2).abs() > 0.1) {
      _respRate = clampedRr;
      _etco2MmHg = clampedEtco2;
      notifyListeners();
    }
  }

  void setRespRate(double rr) {
    final clamped = rr.clamp(6.0, 40.0);
    if ((_respRate - clamped).abs() > 0.1) {
      _respRate = clamped;
      notifyListeners();
    }
  }

  void setEtco2(double etco2) {
    final clamped = etco2.clamp(10.0, 70.0);
    if ((_etco2MmHg - clamped).abs() > 0.1) {
      _etco2MmHg = clamped;
      notifyListeners();
    }
  }

  void setLvef(double ef) {
    final clamped = ef.clamp(15.0, 75.0);
    if ((_lvefPct - clamped).abs() > 0.1) {
      _lvefPct = clamped;
      notifyListeners();
    }
  }

  // ── Bi-Directional Synchronizers ───────────────────────────────────────────

  /// Updates vitals to match the physiological phenotype of a clinical scenario.
  void applyScenarioPreset(CardiacPathologyScenario scenario) {
    final id = scenario.id;
    if (id.contains('anterior_stemi')) {
      _heartRateBpm = 95.0;
      _systolicBp = 105.0;
      _diastolicBp = 70.0;
      _spo2Pct = 94.0;
      _respRate = 20.0;
      _etco2MmHg = 35.0;
      _lvefPct = 40.0;
    } else if (id.contains('inferior_mi')) {
      _heartRateBpm = 42.0;
      _systolicBp = 88.0;
      _diastolicBp = 55.0;
      _spo2Pct = 93.0;
      _respRate = 18.0;
      _etco2MmHg = 32.0;
      _lvefPct = 50.0;
    } else if (id.contains('bifurcation')) {
      _heartRateBpm = 76.0;
      _systolicBp = 135.0;
      _diastolicBp = 85.0;
      _spo2Pct = 98.0;
      _respRate = 14.0;
      _etco2MmHg = 38.0;
      _lvefPct = 58.0;
    } else if (id.contains('post_cabg')) {
      _heartRateBpm = 84.0;
      _systolicBp = 128.0;
      _diastolicBp = 82.0;
      _spo2Pct = 96.0;
      _respRate = 16.0;
      _etco2MmHg = 37.0;
      _lvefPct = 45.0;
    } else if (id.contains('aortic_stenosis')) {
      _heartRateBpm = 78.0;
      _systolicBp = 142.0;
      _diastolicBp = 90.0;
      _spo2Pct = 95.0;
      _respRate = 16.0;
      _etco2MmHg = 36.0;
      _lvefPct = 48.0;
    } else {
      // Normal baseline
      _heartRateBpm = scenario.baselineBpm;
      _systolicBp = 120.0;
      _diastolicBp = 80.0;
      _spo2Pct = 99.0;
      _respRate = 14.0;
      _etco2MmHg = 38.0;
      _lvefPct = 60.0;
    }
    notifyListeners();
  }

  /// Applies acute pharmacological hemodynamic shifts from emergency IV medications.
  void applyIvDrugEffect(IvEmergencyMedication drug) {
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
        break;
    }
    notifyListeners();
  }

  /// Updates vitals when an arrhythmia or conduction block is selected on the monitor.
  void applyRhythmOverride(OscilloscopeRhythmType rhythm) {
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
    } else if (rhythm == OscilloscopeRhythmType.vtach ||
        rhythm == OscilloscopeRhythmType.torsades) {
      _respRate = 24.0;
      _lvefPct = 25.0;
    } else if (rhythm == OscilloscopeRhythmType.sinusTachy ||
        rhythm == OscilloscopeRhythmType.svt) {
      _respRate = 22.0;
      _lvefPct = 65.0;
    } else if (rhythm == OscilloscopeRhythmType.sinusBrady) {
      _respRate = 12.0;
      _lvefPct = 58.0;
    } else {
      _respRate = 14.0;
      _lvefPct = 60.0;
    }

    notifyListeners();
  }

  /// Resets patient vitals to textbook normal physiological parameters.
  void resetToNormalVitals() {
    _heartRateBpm = 72.0;
    _systolicBp = 120.0;
    _diastolicBp = 80.0;
    _spo2Pct = 99.0;
    _respRate = 14.0;
    _etco2MmHg = 38.0;
    _lvefPct = 60.0;
    notifyListeners();
  }
}
