// ============================================================================
// PulmoVent 3D: Pulmonary Master Vitals State & Gas-Exchange Physics Engine
// ----------------------------------------------------------------------------
// Deterministic clinical mathematical engine simulating:
// 1. Mechanical Ventilator Physics: VC-AC, PC-AC, PRVC, PSV.
// 2. Airway Mechanics: Ppeak, Pplat, Driving Pressure (ΔP), Static Compliance (Cstat),
//    Airway Resistance (Raw), Auto-PEEP (Intrinsic PEEP), and Mean Airway Pressure.
// 3. Alveolar-Capillary Gas Exchange: Alveolar Gas Equation (PAO2), A-a Gradient,
//    P/F Ratio (PaO2/FiO2), Shunt Fraction (Qs/Qt), Dead Space (Vd/Vt), and arterial pH/PaCO2.
// 4. Extracorporeal Membrane Oxygenation (ECMO): V-V ECMO (hypoxemic respiratory failure)
//    and V-A ECMO (cardiogenic shock) with North-South (Harlequin) Syndrome detector.
// 5. 8 ICU Clinical Presets: Normal, Severe ARDS, Status Asthmaticus, COPD Auto-PEEP,
//    Tension Pneumothorax, Cardiogenic Pulmonary Edema, Massive PE, Opioid Overdose.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mechanical Ventilation Delivery Modes
enum VentilatorMode {
  vcAc('VC-AC', 'Volume Control (Assist/Control)', 'Guaranteed tidal volume delivered at set flow rate. Pressure varies with lung mechanics.'),
  pcAc('PC-AC', 'Pressure Control (Assist/Control)', 'Guaranteed inspiratory pressure delivered. Volume varies with lung compliance and resistance.'),
  prvc('PRVC', 'Pressure-Regulated Volume Control', 'Decelerating flow delivering target tidal volume at lowest achievable peak pressure.'),
  psv('PSV', 'Pressure Support Ventilation', 'Patient-triggered spontaneous breathing with flow-cycled pressure support.');

  final String code;
  final String title;
  final String description;

  const VentilatorMode(this.code, this.title, this.description);
}

/// Extracorporeal Membrane Oxygenation (ECMO) Modalities
enum EcmoMode {
  off('Off', 'No Extracorporeal Support', 'Mechanical ventilation only.'),
  vvEcmo('V-V ECMO', 'Veno-Venous ECMO (Respiratory)', 'Femoral-internal jugular cannulation providing pure blood oxygenation and CO2 removal without cardiac support.'),
  vaEcmo('V-A ECMO', 'Veno-Arterial ECMO (Cardiopulmonary)', 'Femoral vein to femoral artery cannulation providing full circulatory bypass and gas exchange support.');

  final String code;
  final String title;
  final String description;

  const EcmoMode(this.code, this.title, this.description);
}

/// Anatomical Layers for the 3D Procedural Lung Engine & Full-Screen Theater
enum PulmoAnatomicalLayer {
  all('all', 'All Structures', 'Conducting airways, acinar alveolar sacs, pulmonary capillaries, and pleura.'),
  conducting('conducting', 'Conducting Airways (Gen 0–16)', 'Cartilaginous trachea, carina, lobar, segmental bronchi, and terminal bronchioles.'),
  alveolar('alveolar', 'Micro-Acinus & Alveolar-Capillary', 'Type I/II pneumocytes, surfactant layer, and capillary RBC gas-exchange transition.'),
  heatmap('heatmap', 'West Zones & V/Q Shunt Map', 'Gravitational West Zones 1–3, dependent ARDS consolidation, and dead space.'),
  pleura('pleura', 'Pleura & Thoracic Dynamics', 'Visceral/parietal pleura, pleural space, and tension pneumothorax mediastinal shift.');

  final String id;
  final String label;
  final String description;

  const PulmoAnatomicalLayer(this.id, this.label, this.description);
}

/// 8 Classic ICU Pulmonary & Ventilator Clinical Presets
enum PulmoClinicalSituation {
  normalLungs(
    id: 'normal',
    title: 'Normal Lungs (Healthy Adult)',
    shortLabel: 'Normal Baseline',
    description: 'Normal static compliance (60 mL/cmH2O), low resistance (3 cmH2O/L/s), PaO2 95, PaCO2 40, normal V/Q ratio.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 450.0,
    setRespRate: 14,
    peepCmH2o: 5.0,
    fio2Pct: 40.0,
    inspiratoryFlowLMin: 60.0,
    ieRatio: 0.5, // 1:2
    staticComplianceMlCmH2o: 60.0,
    airwayResistanceCmH2oLs: 3.5,
    autoPeepCmH2o: 0.0,
    pao2MmHg: 95.0,
    paco2MmHg: 40.0,
    arterialPh: 7.40,
    bicarbonateMeqL: 24.0,
    accentColor: Color(0xFF00E676),
  ),
  severeArds(
    id: 'severe_ards',
    title: 'Severe ARDS (COVID-19 / Sepsis, P/F < 100)',
    shortLabel: 'Severe ARDS',
    description: 'Heterogeneous bilateral consolidations, baby lung, profound intrapulmonary shunt (P/F 78), compliance 18 mL/cmH2O. Needs ARDSNet lung-protective ventilation and high PEEP.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 350.0, // 5 mL/kg lung protection
    setRespRate: 26,
    peepCmH2o: 16.0,
    fio2Pct: 90.0,
    inspiratoryFlowLMin: 55.0,
    ieRatio: 0.5,
    staticComplianceMlCmH2o: 18.0,
    airwayResistanceCmH2oLs: 6.0,
    autoPeepCmH2o: 1.5,
    pao2MmHg: 70.0,
    paco2MmHg: 52.0,
    arterialPh: 7.28,
    bicarbonateMeqL: 24.0,
    accentColor: Color(0xFFFF1744),
  ),
  statusAsthmaticus(
    id: 'status_asthmaticus',
    title: 'Status Asthmaticus (Severe Bronchospasm)',
    shortLabel: 'Asthmatic Spasm',
    description: 'Severe smooth-muscle bronchospasm, mucus plugging, markedly elevated airway resistance (Raw 24 cmH2O/L/s), prolonged expiratory time with air trapping.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 420.0,
    setRespRate: 12,
    peepCmH2o: 4.0,
    fio2Pct: 50.0,
    inspiratoryFlowLMin: 80.0,
    ieRatio: 0.25, // 1:4 prolonged expiratory time
    staticComplianceMlCmH2o: 50.0,
    airwayResistanceCmH2oLs: 24.0,
    autoPeepCmH2o: 8.0,
    pao2MmHg: 78.0,
    paco2MmHg: 58.0,
    arterialPh: 7.24,
    bicarbonateMeqL: 25.0,
    accentColor: Color(0xFFFF9100),
  ),
  copdAutoPeep(
    id: 'copd_autopeep',
    title: 'Acute COPD Exacerbation & Auto-PEEP',
    shortLabel: 'COPD Breath-Stack',
    description: 'Severe expiratory flow limitation, loss of lung elastic recoil, dynamic hyperinflation with intrinsic Auto-PEEP 11 cmH2O, chronic respiratory acidosis.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 400.0,
    setRespRate: 12,
    peepCmH2o: 5.0,
    fio2Pct: 35.0,
    inspiratoryFlowLMin: 70.0,
    ieRatio: 0.25, // 1:4
    staticComplianceMlCmH2o: 55.0,
    airwayResistanceCmH2oLs: 18.0,
    autoPeepCmH2o: 11.0,
    pao2MmHg: 64.0,
    paco2MmHg: 68.0,
    arterialPh: 7.30,
    bicarbonateMeqL: 34.0, // Compensated chronic retention
    accentColor: Color(0xFFFFB300),
  ),
  tensionPneumothorax(
    id: 'tension_pneumo',
    title: 'Tension Pneumothorax (Left Lung Collapse)',
    shortLabel: 'Tension Pneumo',
    description: 'One-way pleural valve creating positive intrathoracic pressure on left, complete left lung collapse, mediastinal shift to right, acute Ppeak spike, and IVC compression collapsing venous return.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 420.0,
    setRespRate: 18,
    peepCmH2o: 5.0,
    fio2Pct: 100.0,
    inspiratoryFlowLMin: 60.0,
    ieRatio: 0.5,
    staticComplianceMlCmH2o: 16.0,
    airwayResistanceCmH2oLs: 12.0,
    autoPeepCmH2o: 3.0,
    pao2MmHg: 52.0,
    paco2MmHg: 56.0,
    arterialPh: 7.22,
    bicarbonateMeqL: 23.0,
    accentColor: Color(0xFFD50000),
  ),
  cardiogenicPulmonaryEdema(
    id: 'cardiac_edema',
    title: 'Cardiogenic Pulmonary Edema (Flash)',
    shortLabel: 'Cardiogenic Edema',
    description: 'High pulmonary capillary hydrostatic pressure (PCWP > 25 mmHg) causing transudation into alveoli, decreased lung compliance, hypoxemia, frothy airway fluid.',
    ventMode: VentilatorMode.pcAc,
    tidalVolumeMl: 420.0,
    setRespRate: 20,
    peepCmH2o: 10.0,
    fio2Pct: 70.0,
    inspiratoryFlowLMin: 60.0,
    ieRatio: 0.5,
    staticComplianceMlCmH2o: 26.0,
    airwayResistanceCmH2oLs: 9.0,
    autoPeepCmH2o: 1.0,
    pao2MmHg: 68.0,
    paco2MmHg: 46.0,
    arterialPh: 7.31,
    bicarbonateMeqL: 22.0,
    accentColor: Color(0xFF00B0FF),
  ),
  massivePe(
    id: 'massive_pe',
    title: 'Massive Pulmonary Embolism (Dead Space)',
    shortLabel: 'Massive PE',
    description: 'Large saddle embolus obstructing pulmonary arterial blood flow: massive alveolar dead space (Vd/Vt > 65%), acute RV dilation, normal lung compliance but severe refractory hypoxemia.',
    ventMode: VentilatorMode.vcAc,
    tidalVolumeMl: 450.0,
    setRespRate: 22,
    peepCmH2o: 6.0,
    fio2Pct: 100.0,
    inspiratoryFlowLMin: 60.0,
    ieRatio: 0.5,
    staticComplianceMlCmH2o: 50.0,
    airwayResistanceCmH2oLs: 4.5,
    autoPeepCmH2o: 0.5,
    pao2MmHg: 58.0,
    paco2MmHg: 54.0,
    arterialPh: 7.26,
    bicarbonateMeqL: 23.0,
    accentColor: Color(0xFF7C4DFF),
  ),
  opioidOverdose(
    id: 'opioid_overdose',
    title: 'Opioid Overdose (Acute Hypoventilation)',
    shortLabel: 'Opioid Overdose',
    description: 'Profound central respiratory depression from mu-opioid agonism in medullary rhythm generators: set RR 4/min, acute severe uncompensated respiratory acidosis, normal A-a gradient.',
    ventMode: VentilatorMode.psv,
    tidalVolumeMl: 280.0,
    setRespRate: 5,
    peepCmH2o: 5.0,
    fio2Pct: 21.0,
    inspiratoryFlowLMin: 40.0,
    ieRatio: 0.5,
    staticComplianceMlCmH2o: 58.0,
    airwayResistanceCmH2oLs: 3.5,
    autoPeepCmH2o: 0.0,
    pao2MmHg: 48.0,
    paco2MmHg: 82.0,
    arterialPh: 7.12,
    bicarbonateMeqL: 25.0,
    accentColor: Color(0xFFE040FB),
  );

  final String id;
  final String title;
  final String shortLabel;
  final String description;
  final VentilatorMode ventMode;
  final double tidalVolumeMl;
  final int setRespRate;
  final double peepCmH2o;
  final double fio2Pct;
  final double inspiratoryFlowLMin;
  final double ieRatio;
  final double staticComplianceMlCmH2o;
  final double airwayResistanceCmH2oLs;
  final double autoPeepCmH2o;
  final double pao2MmHg;
  final double paco2MmHg;
  final double arterialPh;
  final double bicarbonateMeqL;
  final Color accentColor;

  const PulmoClinicalSituation({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.ventMode,
    required this.tidalVolumeMl,
    required this.setRespRate,
    required this.peepCmH2o,
    required this.fio2Pct,
    required this.inspiratoryFlowLMin,
    required this.ieRatio,
    required this.staticComplianceMlCmH2o,
    required this.airwayResistanceCmH2oLs,
    required this.autoPeepCmH2o,
    required this.pao2MmHg,
    required this.paco2MmHg,
    required this.arterialPh,
    required this.bicarbonateMeqL,
    required this.accentColor,
  });
}

/// PulmoVent 3D Master Vitals and Mechanical Ventilation Physics State
class PulmoMasterVitalsState extends ChangeNotifier {
  PulmoClinicalSituation _activeSituation = PulmoClinicalSituation.normalLungs;
  bool _isAutoPilot = true;

  // Ventilator Machine Settings
  VentilatorMode _ventMode = VentilatorMode.vcAc;
  double _tidalVolumeMl = 450.0;
  final double _idealBodyWeightKg = 70.0;
  int _setRespRate = 14;
  double _peepCmH2o = 5.0;
  double _fio2Pct = 40.0;
  double _inspiratoryFlowLMin = 60.0;
  double _ieRatio = 0.5; // 1:2

  // Lung Pathophysiology Parameters
  double _staticComplianceMlCmH2o = 60.0;
  double _airwayResistanceCmH2oLs = 3.5;
  double _autoPeepCmH2o = 0.0;

  // Gas Exchange & Blood Gas Telemetry
  double _pao2MmHg = 95.0;
  double _paco2MmHg = 40.0;
  double _arterialPh = 7.40;
  double _bicarbonateMeqL = 24.0;

  // Interactive Hold Maneuvers
  bool _isInspiratoryHoldActive = false;
  bool _isExpiratoryHoldActive = false;

  // ECMO Circuit Parameters
  EcmoMode _ecmoMode = EcmoMode.off;
  double _ecmoFlowLMin = 3.8;
  double _sweepGasLMin = 4.0;
  double _membraneFdo2Pct = 100.0;
  int _centrifugalPumpRpm = 3200;

  // Interventions Active
  bool _isChestTubeDecompressed = false;
  bool _isPronePositionActive = false;
  bool _isBronchodilatorActive = false;

  PulmoClinicalSituation get activeSituation => _activeSituation;
  bool get isAutoPilot => _isAutoPilot;

  VentilatorMode get ventMode => _ventMode;
  double get tidalVolumeMl => _tidalVolumeMl;
  double get idealBodyWeightKg => _idealBodyWeightKg;
  double get tidalVolumePerKgIbw => _tidalVolumeMl / _idealBodyWeightKg;
  int get setRespRate => _setRespRate;
  double get peepCmH2o => _peepCmH2o;
  double get fio2Pct => _fio2Pct;
  double get inspiratoryFlowLMin => _inspiratoryFlowLMin;
  double get ieRatio => _ieRatio;

  double get staticComplianceMlCmH2o => _staticComplianceMlCmH2o;
  double get airwayResistanceCmH2oLs => _airwayResistanceCmH2oLs;
  double get autoPeepCmH2o => _autoPeepCmH2o;

  double get pao2MmHg => _pao2MmHg;
  double get paco2MmHg => _paco2MmHg;
  double get arterialPh => _arterialPh;
  double get bicarbonateMeqL => _bicarbonateMeqL;

  bool get isInspiratoryHoldActive => _isInspiratoryHoldActive;
  bool get isExpiratoryHoldActive => _isExpiratoryHoldActive;

  EcmoMode get ecmoMode => _ecmoMode;
  double get ecmoFlowLMin => _ecmoFlowLMin;
  double get sweepGasLMin => _sweepGasLMin;
  double get membraneFdo2Pct => _membraneFdo2Pct;
  int get centrifugalPumpRpm => _centrifugalPumpRpm;

  bool get isChestTubeDecompressed => _isChestTubeDecompressed;
  bool get isPronePositionActive => _isPronePositionActive;
  bool get isBronchodilatorActive => _isBronchodilatorActive;

  // ── Derived Ventilator & Respiratory Mechanics Calculations ──────────────────

  /// Driving Pressure: ΔP = Pplat - PEEP (Target < 14-15 cmH2O)
  double get drivingPressureCmH2o =>
      (_tidalVolumeMl / math.max(5.0, _staticComplianceMlCmH2o)).clamp(2.0, 50.0);

  /// Plateau Pressure: Pplat = PEEP + ΔP (Target < 30 cmH2O)
  double get plateauPressureCmH2o =>
      (_peepCmH2o + drivingPressureCmH2o).clamp(5.0, 70.0);

  /// Peak Inspiratory Pressure: Ppeak = Pplat + (Raw * Flow / 60)
  double get peakPressureCmH2o => (plateauPressureCmH2o +
          (_airwayResistanceCmH2oLs * (_inspiratoryFlowLMin / 60.0)))
      .clamp(8.0, 95.0);

  /// Total PEEP: Set PEEP + Auto-PEEP
  double get totalPeepCmH2o => _peepCmH2o + _autoPeepCmH2o;

  /// Minute Ventilation: Ve = Vt * RR (L/min)
  double get minuteVentilationLMin => (_tidalVolumeMl * _setRespRate) / 1000.0;

  /// Mean Airway Pressure: Pmean ≈ PEEP + [ (Ti / Ttot) * (Pplat - PEEP) ]
  double get meanAirwayPressureCmH2o {
    final dutyCycle = _ieRatio / (1.0 + _ieRatio);
    return _peepCmH2o + (dutyCycle * drivingPressureCmH2o);
  }

  // ── Derived Gas Exchange & Oxygenation Kinetics ─────────────────────────────

  /// Alveolar Oxygen Tension: PAO2 = (FiO2 * (Patm - PH2O)) - (PaCO2 / R)
  /// Patm = 760, PH2O = 47, R = 0.8
  double get alveolarO2MmHg {
    final fio2Fraction = _fio2Pct / 100.0;
    return (fio2Fraction * (760.0 - 47.0)) - (_paco2MmHg / 0.8);
  }

  /// Alveolar-Arterial Gradient: A-a = PAO2 - PaO2
  double get alveolarArterialGradient =>
      math.max(2.0, alveolarO2MmHg - _pao2MmHg);

  /// P/F Ratio: PaO2 / (FiO2 / 100) (Berlin ARDS Definition: < 300 mild, < 200 mod, < 100 severe)
  double get pfRatio => _pao2MmHg / (_fio2Pct / 100.0);

  /// Arterial Oxygen Saturation (SpO2) modeled via Hill equation on PaO2
  double get spo2Percent {
    if (_ecmoMode == EcmoMode.vvEcmo) return 96.0;
    // Hill's equation: SpO2 = (PaO2^2.8) / (PaO2^2.8 + P50^2.8)
    const p50 = 26.8;
    final po2Power = math.pow(_pao2MmHg, 2.8);
    final p50Power = math.pow(p50, 2.8);
    final sat = (po2Power / (po2Power + p50Power)) * 100.0;
    return sat.clamp(40.0, 100.0);
  }

  /// Right Radial SpO2 on V-A ECMO (Detects North-South / Harlequin Syndrome)
  double get rightRadialSpo2 {
    if (_ecmoMode != EcmoMode.vaEcmo) return spo2Percent;
    // If native lungs are failing with severe shunt and heart is ejecting antegrade,
    // right arm/brain receives poorly oxygenated blood from native LV
    if (_activeSituation == PulmoClinicalSituation.severeArds) return 84.0;
    return math.min(spo2Percent, 87.0);
  }

  /// Femoral Cannula SpO2 on V-A ECMO
  double get femoralSpo2 {
    if (_ecmoMode != EcmoMode.vaEcmo) return spo2Percent;
    // Retrograde blood from membrane oxygenator is fully saturated
    return 99.5;
  }

  /// Harlequin (North-South) Syndrome Active Flag
  bool get isHarlequinSyndromeActive =>
      _ecmoMode == EcmoMode.vaEcmo &&
      rightRadialSpo2 < 88.0 &&
      femoralSpo2 >= 98.0;

  /// Shunt Fraction Approximation: Qs/Qt (%)
  double get shuntFractionPct {
    // Shunt increases with lower P/F and wider A-a gradient
    final baseShunt = (alveolarArterialGradient / (alveolarO2MmHg + 10.0)) * 50.0;
    return baseShunt.clamp(3.0, 65.0);
  }

  /// Alveolar Dead-Space Fraction: Vd/Vt (%)
  double get deadSpaceFractionPct {
    if (_activeSituation == PulmoClinicalSituation.massivePe) return 65.0;
    if (_activeSituation == PulmoClinicalSituation.copdAutoPeep) return 48.0;
    return 30.0;
  }

  // ── Clinical Alerts & Interceptor Flags ─────────────────────────────────────

  /// Critical Barotrauma/Volutrauma risk: Pplat > 30 cmH2O or ΔP > 15 cmH2O
  bool get isBarotraumaRisk =>
      plateauPressureCmH2o > 30.0 || drivingPressureCmH2o > 15.0;

  /// High Airway Resistance / Bronchospasm: Raw > 12 cmH2O/L/s
  bool get isSevereBronchospasm => _airwayResistanceCmH2oLs > 12.0;

  /// Critical Hypoxemia: PaO2 < 55 mmHg or P/F < 100
  bool get isRefractoryHypoxemia => _pao2MmHg < 55.0 || pfRatio < 100.0;

  /// Severe Acidemia: pH < 7.20
  bool get isSevereRespiratoryAcidosis => _arterialPh < 7.20 && _paco2MmHg > 50.0;

  // ── Actions & Parameter Modifications ───────────────────────────────────────

  void applySituation(PulmoClinicalSituation situation) {
    _activeSituation = situation;
    _isAutoPilot = true;

    _ventMode = situation.ventMode;
    _tidalVolumeMl = situation.tidalVolumeMl;
    _setRespRate = situation.setRespRate;
    _peepCmH2o = situation.peepCmH2o;
    _fio2Pct = situation.fio2Pct;
    _inspiratoryFlowLMin = situation.inspiratoryFlowLMin;
    _ieRatio = situation.ieRatio;

    _staticComplianceMlCmH2o = situation.staticComplianceMlCmH2o;
    _airwayResistanceCmH2oLs = situation.airwayResistanceCmH2oLs;
    _autoPeepCmH2o = situation.autoPeepCmH2o;

    _pao2MmHg = situation.pao2MmHg;
    _paco2MmHg = situation.paco2MmHg;
    _arterialPh = situation.arterialPh;
    _bicarbonateMeqL = situation.bicarbonateMeqL;

    _isInspiratoryHoldActive = false;
    _isExpiratoryHoldActive = false;
    _isChestTubeDecompressed = false;
    _isPronePositionActive = false;
    _isBronchodilatorActive = false;

    notifyListeners();
  }

  void setVentilatorSettings({
    VentilatorMode? mode,
    double? tidalVolumeMl,
    int? setRespRate,
    double? peepCmH2o,
    double? fio2Pct,
    double? inspiratoryFlowLMin,
    double? ieRatio,
  }) {
    _isAutoPilot = false;
    if (mode != null) _ventMode = mode;
    if (tidalVolumeMl != null) _tidalVolumeMl = tidalVolumeMl.clamp(200.0, 850.0);
    if (setRespRate != null) _setRespRate = setRespRate.clamp(4, 45);
    if (peepCmH2o != null) _peepCmH2o = peepCmH2o.clamp(0.0, 26.0);
    if (fio2Pct != null) _fio2Pct = fio2Pct.clamp(21.0, 100.0);
    if (inspiratoryFlowLMin != null) {
      _inspiratoryFlowLMin = inspiratoryFlowLMin.clamp(20.0, 120.0);
    }
    if (ieRatio != null) _ieRatio = ieRatio.clamp(0.2, 1.0);

    _recalculateGasExchangeFromVent();
    notifyListeners();
  }

  void setEcmoSettings({
    EcmoMode? mode,
    double? flowLMin,
    double? sweepGasLMin,
    double? membraneFdo2Pct,
    int? pumpRpm,
  }) {
    if (mode != null) _ecmoMode = mode;
    if (flowLMin != null) _ecmoFlowLMin = flowLMin.clamp(0.5, 7.5);
    if (sweepGasLMin != null) _sweepGasLMin = sweepGasLMin.clamp(0.5, 12.0);
    if (membraneFdo2Pct != null) {
      _membraneFdo2Pct = membraneFdo2Pct.clamp(21.0, 100.0);
    }
    if (pumpRpm != null) _centrifugalPumpRpm = pumpRpm.clamp(1000, 5000);

    if (_ecmoMode == EcmoMode.vvEcmo) {
      // Sweep gas clears CO2, membrane FdO2 oxygenates
      _pao2MmHg = math.max(_pao2MmHg, 85.0 + (_ecmoFlowLMin * 3.0));
      _paco2MmHg = math.max(32.0, 48.0 - (_sweepGasLMin * 2.5));
      _arterialPh = 7.35 + ((40.0 - _paco2MmHg) * 0.008);
    }
    notifyListeners();
  }

  void toggleInspiratoryHold() {
    _isInspiratoryHoldActive = !_isInspiratoryHoldActive;
    notifyListeners();
  }

  void toggleExpiratoryHold() {
    _isExpiratoryHoldActive = !_isExpiratoryHoldActive;
    notifyListeners();
  }

  void performNeedleThoracostomy() {
    if (_activeSituation == PulmoClinicalSituation.tensionPneumothorax) {
      _isChestTubeDecompressed = true;
      _staticComplianceMlCmH2o = 44.0;
      _airwayResistanceCmH2oLs = 4.5;
      _pao2MmHg = 88.0;
      _paco2MmHg = 42.0;
      _arterialPh = 7.38;
      notifyListeners();
    }
  }

  void togglePronePositioning() {
    _isPronePositionActive = !_isPronePositionActive;
    if (_isPronePositionActive) {
      // Prone positioning improves dorsal alveolar recruitment and V/Q matching in ARDS
      _staticComplianceMlCmH2o = (_staticComplianceMlCmH2o * 1.35).clamp(10.0, 70.0);
      _pao2MmHg = (_pao2MmHg + 24.0).clamp(40.0, 160.0);
    } else {
      _staticComplianceMlCmH2o = _activeSituation.staticComplianceMlCmH2o;
      _pao2MmHg = _activeSituation.pao2MmHg;
    }
    notifyListeners();
  }

  void administerNebulizedBronchodilator() {
    _isBronchodilatorActive = true;
    _airwayResistanceCmH2oLs = (_airwayResistanceCmH2oLs * 0.45).clamp(3.0, 30.0);
    _autoPeepCmH2o = (_autoPeepCmH2o * 0.4).clamp(0.0, 15.0);
    notifyListeners();
  }

  void resetToAutoPilot() {
    applySituation(_activeSituation);
  }

  void _recalculateGasExchangeFromVent() {
    // Alveolar ventilation change modulates PaCO2: PaCO2_new = PaCO2_old * (Ve_old / Ve_new)
    final expectedVe = 6.0; // Normal minute ventilation ~6 L/min
    final currentVe = minuteVentilationLMin;
    final veRatio = expectedVe / math.max(2.0, currentVe);

    if (!_isAutoPilot) {
      _paco2MmHg = (_activeSituation.paco2MmHg * veRatio).clamp(18.0, 110.0);
      // Acute respiratory pH change: ΔpH ≈ -0.008 * (PaCO2 - 40)
      _arterialPh = (7.40 - (0.008 * (_paco2MmHg - 40.0))).clamp(6.85, 7.75);

      // PEEP & FiO2 modulate PaO2
      final peepBoost = (_peepCmH2o - 5.0) * 2.5;
      final fio2Factor = _fio2Pct / 40.0;
      _pao2MmHg = ((_activeSituation.pao2MmHg * fio2Factor) + peepBoost).clamp(35.0, 450.0);
    }
  }
}
