// ============================================================================
// NeuroLab 3D: Neuro-Critical Care Master Vitals & Situation State
// ----------------------------------------------------------------------------
// Synchronizes Mean Arterial Pressure (MAP), Intracranial Pressure (ICP),
// Cerebral Perfusion Pressure (CPP = MAP - ICP), Arterial PaCO2 (vasoreactivity),
// SpO2, Core Temperature, and Glasgow Coma Scale (GCS) across the 3D Brain,
// Biplane Angiography, 5-Channel IONM Oscilloscope, and Diagnostic Suites.
// Strictly Educational In-Silico Simulation — SaMD Compliant.
// ============================================================================

import 'package:flutter/foundation.dart';

enum NeuroClinicalSituation {
  normalBaseline(
    id: 'normal',
    title: 'Normal Baseline (Intact Compliance)',
    description: 'Normal ICP (10 mmHg), CPP 75 mmHg, GCS 15. Normal Circle of Willis autoregulation.',
    mapMmHg: 85.0,
    icpMmHg: 10.0,
    paco2MmHg: 40.0,
    spo2Percent: 99.0,
    temperatureC: 37.0,
    gcsEye: 4,
    gcsVerbal: 5,
    gcsMotor: 6,
  ),
  acuteM1Stroke(
    id: 'left_m1_stroke',
    title: 'Acute Left M1 LVO Stroke (3.5h Onset)',
    description: 'Large-vessel occlusion of left M1 trunk. Penumbra at risk, focal delta slowing on left EEG.',
    mapMmHg: 120.0,
    icpMmHg: 16.0,
    paco2MmHg: 40.0,
    spo2Percent: 96.0,
    temperatureC: 37.2,
    gcsEye: 3,
    gcsVerbal: 2,
    gcsMotor: 4,
  ),
  sahDay7Vasospasm(
    id: 'sah_vasospasm',
    title: 'Aneurysmal SAH Day-7 Vasospasm',
    description: 'Post-rupture ACom aneurysm with severe MCA vasospasm (Lindegaard > 5.0). Needs Nimodipine & euvolemia.',
    mapMmHg: 135.0,
    icpMmHg: 32.0,
    paco2MmHg: 38.0,
    spo2Percent: 97.0,
    temperatureC: 38.1,
    gcsEye: 3,
    gcsVerbal: 3,
    gcsMotor: 5,
  ),
  malignantMcaEdema(
    id: 'uncal_herniation',
    title: 'Malignant MCA Edema & Impending Herniation',
    description: 'Critical intracranial hypertension (ICP > 30 mmHg), Cushing reflex (HTN + bradycardia), P2 > P1.',
    mapMmHg: 155.0,
    icpMmHg: 34.0,
    paco2MmHg: 45.0,
    spo2Percent: 93.0,
    temperatureC: 38.6,
    gcsEye: 1,
    gcsVerbal: 1,
    gcsMotor: 3,
  ),
  statusEpilepticus(
    id: 'status_epilepticus',
    title: 'Refractory Status Epilepticus',
    description: 'Continuous 3 Hz generalized spike-wave discharges. Hypermetabolism with secondary lactic acidosis.',
    mapMmHg: 130.0,
    icpMmHg: 22.0,
    paco2MmHg: 48.0,
    spo2Percent: 91.0,
    temperatureC: 38.8,
    gcsEye: 1,
    gcsVerbal: 1,
    gcsMotor: 2,
  ),
  neurogenicShock(
    id: 't6_neurogenic_shock',
    title: 'T6 Spinal Cord Injury & Neurogenic Shock',
    description: 'Loss of sympathetic vascular tone below T6. Severe hypotension (MAP 55 mmHg) and relative bradycardia.',
    mapMmHg: 55.0,
    icpMmHg: 8.0,
    paco2MmHg: 38.0,
    spo2Percent: 95.0,
    temperatureC: 35.4,
    gcsEye: 4,
    gcsVerbal: 5,
    gcsMotor: 4,
  );

  const NeuroClinicalSituation({
    required this.id,
    required this.title,
    required this.description,
    required this.mapMmHg,
    required this.icpMmHg,
    required this.paco2MmHg,
    required this.spo2Percent,
    required this.temperatureC,
    required this.gcsEye,
    required this.gcsVerbal,
    required this.gcsMotor,
  });

  final String id;
  final String title;
  final String description;
  final double mapMmHg;
  final double icpMmHg;
  final double paco2MmHg;
  final double spo2Percent;
  final double temperatureC;
  final int gcsEye;
  final int gcsVerbal;
  final int gcsMotor;

  int get totalGcs => gcsEye + gcsVerbal + gcsMotor;
}

class NeuroMasterVitalsState extends ChangeNotifier {
  NeuroClinicalSituation _activeSituation = NeuroClinicalSituation.normalBaseline;
  bool _isAutoPilot = true;

  double _mapMmHg = 85.0;
  double _icpMmHg = 10.0;
  double _paco2MmHg = 40.0;
  double _spo2Percent = 99.0;
  double _temperatureC = 37.0;
  int _gcsEye = 4;
  int _gcsVerbal = 5;
  int _gcsMotor = 6;

  NeuroClinicalSituation get activeSituation => _activeSituation;
  bool get isAutoPilot => _isAutoPilot;

  double get mapMmHg => _mapMmHg;
  double get icpMmHg => _icpMmHg;
  double get cppMmHg => (_mapMmHg - _icpMmHg).clamp(0.0, 180.0);
  double get paco2MmHg => _paco2MmHg;
  double get spo2Percent => _spo2Percent;
  double get temperatureC => _temperatureC;
  int get gcsEye => _gcsEye;
  int get gcsVerbal => _gcsVerbal;
  int get gcsMotor => _gcsMotor;
  int get totalGcs => _gcsEye + _gcsVerbal + _gcsMotor;

  bool get isIntracranialHypertension => _icpMmHg > 20.0;
  bool get isCriticalHerniationRisk => _icpMmHg > 30.0 || cppMmHg < 50.0;
  bool get isCushingReflex => _icpMmHg > 25.0 && _mapMmHg >= 130.0;

  void applySituation(NeuroClinicalSituation situation) {
    _activeSituation = situation;
    _isAutoPilot = true;

    _mapMmHg = situation.mapMmHg;
    _icpMmHg = situation.icpMmHg;
    _paco2MmHg = situation.paco2MmHg;
    _spo2Percent = situation.spo2Percent;
    _temperatureC = situation.temperatureC;
    _gcsEye = situation.gcsEye;
    _gcsVerbal = situation.gcsVerbal;
    _gcsMotor = situation.gcsMotor;

    notifyListeners();
  }

  void setManualMap(double value) {
    _isAutoPilot = false;
    _mapMmHg = value.clamp(40.0, 200.0);
    notifyListeners();
  }

  void setManualIcp(double value) {
    _isAutoPilot = false;
    _icpMmHg = value.clamp(2.0, 60.0);
    notifyListeners();
  }

  void setManualPaCO2(double value) {
    _isAutoPilot = false;
    _paco2MmHg = value.clamp(18.0, 65.0);
    notifyListeners();
  }

  void setManualSpO2(double value) {
    _isAutoPilot = false;
    _spo2Percent = value.clamp(60.0, 100.0);
    notifyListeners();
  }

  void setManualTemperature(double value) {
    _isAutoPilot = false;
    _temperatureC = value.clamp(32.0, 41.0);
    notifyListeners();
  }

  void setManualGcs({int? eye, int? verbal, int? motor}) {
    _isAutoPilot = false;
    if (eye != null) _gcsEye = eye.clamp(1, 4);
    if (verbal != null) _gcsVerbal = verbal.clamp(1, 5);
    if (motor != null) _gcsMotor = motor.clamp(1, 6);
    notifyListeners();
  }

  void resetToAutoPilot() {
    applySituation(_activeSituation);
  }
}
