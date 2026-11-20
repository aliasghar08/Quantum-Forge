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
import 'package:quantum_forge/features/nephro/data/nephro_master_vitals_state.dart';

export 'package:quantum_forge/features/nephro/data/nephro_master_vitals_state.dart';

/// Unified Multi-Organ Digital Patient State connecting Cardio, Neuro, Pulmo, and Renal.
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
