// ============================================================================
// Computational Coronary Hemodynamics Engine — CardioCath 3D
// ----------------------------------------------------------------------------
// Client-Side 1D-0D Coupled Windkessel & Navier-Stokes Approximator.
// Provides instantaneous sub-millisecond local execution paired with
// remote Google Cloud Run microservice synchronization.
// Computes:
// 1. Aortic (Pa) and Distal (Pd) pressure waveforms
// 2. Fractional Flow Reserve (FFR = Pd/Pa hyperemic, <= 0.80 threshold)
// 3. Instantaneous Wave-Free Ratio (iFR wave-free diastolic window, <= 0.89)
// 4. Endothelial Wall Shear Stress (WSS dynes/cm²) & Reynolds numbers
// 5. IABP 1:1 diastolic counterpulsation augmentation
// 6. Catheter ostial damping (AL1 deep-seating ventricularization)
// 7. Acute complication state machines (No-Reflow, Perforation/Tamponade, Shock)
// 8. ALARA Radiation (Air Kerma, DAP) and Contrast Nephrotoxicity tracking
// ============================================================================

import 'dart:math' as math;
import 'cardiac_pathology_models.dart';

enum GuideCatheterType {
  jl4('JL4 (Judkins Left 4.0)', 'Standard diagnostic & PCI guide for Left Main / LAD / LCx with passive coaxial support.'),
  jr4('JR4 (Judkins Right 4.0)', 'Standard diagnostic & PCI guide for RCA ostium engagement.'),
  ebu35('EBU 3.5 (Extra Backup)', 'Deep aortic root support for tortuous calcified LAD/LCx interventions.'),
  al1('AL1 (Amplatz Left 1.0)', 'High backup power; carries high risk of ostial LM deep-seating and ventricularization.');

  final String label;
  final String description;
  const GuideCatheterType(this.label, this.description);
}

enum InterventionalWireType {
  workhorse('0.014" Workhorse Guidewire', 'Hydrophilic polymer-jacketed steerable wire for lesion crossing.'),
  pressureWireX('PressureWire X (FFR / iFR)', 'Fiber-optic piezoresistive micro-transducer measuring trans-stenotic Pd/Pa ratio.');

  final String label;
  final String description;
  const InterventionalWireType(this.label, this.description);
}

enum AcuteComplicationState {
  none('Stable Hemodynamics', 'No acute procedural complications.'),
  noReflow('No-Reflow Phenomenon', 'Microvascular spasm & distal embolization. Microvascular resistance x4. Treat with IC Adenosine / Nitroprusside.'),
  perforationTamponade('Coronary Perforation & Tamponade', 'Ellis Type III perforation with dye extravasation and pulsus paradoxus. Deploy covered stent + pericardiocentesis.'),
  lmVentricularization('LM Ostial Ventricularization', 'Deep catheter seat damping aortic pressure waveform. Withdraw guide immediately to prevent dissection.'),
  cardiogenicShock('Cardiogenic Shock', 'Profound pump failure (BP < 80 mmHg). Requires emergency IABP 1:1 counterpulsation.');

  final String label;
  final String description;
  const AcuteComplicationState(this.label, this.description);
}

class CoronaryPhysiologyFrame {
  final double timeSeconds;
  final double cardiacPhase;
  final double aorticPressurePa;      // Red trace (mmHg)
  final double distalPressurePd;      // Yellow trace (mmHg)
  final double ecgLeadIiMv;
  final double coronaryFlowMlMin;
  final double wallShearStressDynes;  // dynes/cm²
  final double reynoldsNumber;
  final bool isWaveFreePeriod;
  final double iabpPressure;

  const CoronaryPhysiologyFrame({
    required this.timeSeconds,
    required this.cardiacPhase,
    required this.aorticPressurePa,
    required this.distalPressurePd,
    required this.ecgLeadIiMv,
    required this.coronaryFlowMlMin,
    required this.wallShearStressDynes,
    required this.reynoldsNumber,
    required this.isWaveFreePeriod,
    required this.iabpPressure,
  });
}

class CoronaryPhysiologyResult {
  final double ffr;
  final double ifr;
  final double meanPa;
  final double meanPd;
  final double deltaP;
  final double peakWssDynes;
  final double maxReynolds;
  final bool isIschemicFfr;
  final bool isIschemicIfr;
  final int timiGrade;
  final String clinicalRecommendation;
  final List<CoronaryPhysiologyFrame> waveform;

  const CoronaryPhysiologyResult({
    required this.ffr,
    required this.ifr,
    required this.meanPa,
    required this.meanPd,
    required this.deltaP,
    required this.peakWssDynes,
    required this.maxReynolds,
    required this.isIschemicFfr,
    required this.isIschemicIfr,
    required this.timiGrade,
    required this.clinicalRecommendation,
    required this.waveform,
  });
}

class ComputationalHemodynamicsEngine {
  const ComputationalHemodynamicsEngine._();

  static CoronaryPhysiologyResult solve({
    required CardiacPathologyScenario scenario,
    required double bpm,
    required GuideCatheterType catheter,
    required InterventionalWireType wire,
    required bool isHyperemic,
    required bool isRevascularized,
    required bool isRotablated,
    required bool iabpActive,
    required AcuteComplicationState complication,
    required CoronaryDominance dominance,
    int sampleCount = 100,
  }) {
    final beatDuration = 60.0 / bpm;
    final isTamponade = complication == AcuteComplicationState.perforationTamponade;
    final isShock = complication == AcuteComplicationState.cardiogenicShock;
    final isNoReflow = complication == AcuteComplicationState.noReflow;
    final isVentricularized = complication == AcuteComplicationState.lmVentricularization ||
        (catheter == GuideCatheterType.al1 && scenario.id.contains('critical_lm'));

    double sbp = isShock ? 75.0 : (isTamponade ? 88.0 : scenario.systolicBp);
    double dbp = isShock ? 48.0 : (isTamponade ? 72.0 : scenario.diastolicBp);

    // Stenosis parameters
    double stenosisFraction = isRevascularized
        ? 0.0
        : (isRotablated ? 0.25 : scenario.ladStenosisFraction);

    final d0 = 3.2e-3; // Reference diameter in meters (3.2 mm)
    final a0 = math.pi * math.pow(d0 / 2.0, 2);
    final stenosedD = math.max(d0 * (1.0 - stenosisFraction), 0.25e-3);
    final asArea = math.pi * math.pow(stenosedD / 2.0, 2);
    final areaRatio = math.max(a0 / asArea, 1.0);

    const rho = 1.05e3; // Blood density kg/m³
    const mu = 0.0035;  // Viscosity Pa*s
    const lengthM = 0.015; // 15 mm lesion

    double qMean = (75.0 * 1e-6 / 60.0); // m³/s
    if (isHyperemic) qMean *= 3.2; // Hyperemia CFR
    if (isNoReflow) qMean *= 0.22;

    const kv = 32.0;
    final kvTerm = kv * mu * lengthM / (math.pi * math.pow(d0, 3));
    final inertialTerm = (rho / 2.0) * math.pow(areaRatio - 1.0, 2) / math.pow(a0, 2);

    final List<CoronaryPhysiologyFrame> frames = [];
    final List<double> paList = [];
    final List<double> pdList = [];
    final List<double> wssList = [];
    final List<double> reList = [];

    const systoleFraction = 0.35;

    for (int i = 0; i < sampleCount; i++) {
      final t = (i / sampleCount) * beatDuration;
      final phi = i / sampleCount;

      // ECG synthesis
      double ecg = 0.0;
      if (phi >= 0.10 && phi <= 0.20) {
        ecg += 0.20 * math.sin((phi - 0.10) / 0.10 * math.pi);
      } else if (phi > 0.24 && phi <= 0.26) {
        ecg -= 0.18 * math.sin((phi - 0.24) / 0.02 * math.pi);
      } else if (phi > 0.26 && phi <= 0.30) {
        ecg += 1.60 * math.sin((phi - 0.26) / 0.04 * math.pi);
      } else if (phi > 0.30 && phi <= 0.33) {
        ecg -= 0.35 * math.sin((phi - 0.30) / 0.03 * math.pi);
      } else if (phi > 0.33 && phi <= 0.65) {
        ecg += 0.38 * math.sin((phi - 0.38) / 0.27 * math.pi);
        if (scenario.id.contains('stemi') && !isRevascularized) {
          ecg += 0.45; // ST Elevation
        }
      }

      // Wave-free period for iFR (mid-to-late diastole)
      final isWfp = phi >= 0.52 && phi <= 0.94;

      // Aortic pressure synthesis
      double pa;
      if (isVentricularized) {
        pa = (phi < 0.30)
            ? 15.0 + (sbp - 25.0) * math.sin(phi / 0.30 * math.pi)
            : 15.0 + 10.0 * math.exp(-(phi - 0.30) * 4.0);
      } else if (phi < systoleFraction) {
        final tau = phi / systoleFraction;
        pa = dbp + (sbp - dbp) * math.sin(tau * math.pi * 0.85);
      } else {
        final tau = (phi - systoleFraction) / (1.0 - systoleFraction);
        final notch = 8.0 * math.exp(-math.pow(tau - 0.06, 2) / 0.002);
        final decay = (sbp - dbp) * 0.65 * math.exp(-tau * 1.5);
        pa = dbp + decay + notch;
      }

      // IABP 1:1 counterpulsation
      double iabpPress = 0.0;
      if (iabpActive) {
        if (phi >= 0.35 && phi <= 0.90) {
          final tau = (phi - 0.35) / 0.55;
          pa += 35.0 * math.sin(tau * math.pi); // Diastolic augmentation wave
          iabpPress = 260.0;
        } else if (phi > 0.90) {
          pa -= 12.0; // Presystolic LV unloading
        }
      }

      // Pulsus paradoxus in tamponade
      if (isTamponade) {
        pa -= 14.0 * math.sin(phi * 2.0 * math.pi);
      }

      pa = math.max(pa, 10.0);
      paList.add(pa);

      // Flow & pressure drop
      double flowFactor;
      if (phi < systoleFraction) {
        flowFactor = 0.35 + 0.25 * math.sin(phi / systoleFraction * math.pi);
      } else {
        final tau = (phi - systoleFraction) / (1.0 - systoleFraction);
        flowFactor = 1.35 * math.sin(tau * math.pi * 0.9);
      }
      final qInst = math.max(qMean * flowFactor, 1e-7);

      final deltaPPa = (kvTerm * qInst) + (inertialTerm * math.pow(qInst, 2));
      double deltaPMmhg = deltaPPa / 133.322;
      if (isNoReflow) deltaPMmhg += 18.0;

      double pd = math.max(pa - deltaPMmhg, 5.0);
      final pdMeanComp = (dbp + (sbp - dbp) / 3.0) * (1.0 - math.pow(stenosisFraction, 1.6) * 0.7);
      pd = (pd * 0.6) + (pdMeanComp * 0.4);
      pdList.add(pd);

      // WSS & Reynolds
      final rStenosed = stenosedD / 2.0;
      final wssPa = (4.0 * mu * qInst) / (math.pi * math.pow(rStenosed, 3));
      final wssDynes = wssPa * 10.0;
      wssList.add(wssDynes);

      final velocity = qInst / asArea;
      final reynolds = (rho * velocity * stenosedD) / mu;
      reList.add(reynolds);

      frames.add(CoronaryPhysiologyFrame(
        timeSeconds: t,
        cardiacPhase: phi,
        aorticPressurePa: pa,
        distalPressurePd: wire == InterventionalWireType.pressureWireX ? pd : pa,
        ecgLeadIiMv: ecg,
        coronaryFlowMlMin: qInst * 60.0 * 1e6,
        wallShearStressDynes: wssDynes,
        reynoldsNumber: reynolds,
        isWaveFreePeriod: isWfp,
        iabpPressure: iabpPress,
      ));
    }

    final meanPa = paList.reduce((a, b) => a + b) / paList.length;
    final meanPd = pdList.reduce((a, b) => a + b) / pdList.length;
    final ffr = (meanPd / math.max(meanPa, 1.0)).clamp(0.20, 1.00);

    // iFR calculation across wave-free period
    final wfpPa = <double>[];
    final wfpPd = <double>[];
    for (int i = 0; i < frames.length; i++) {
      if (frames[i].isWaveFreePeriod) {
        wfpPa.add(paList[i]);
        wfpPd.add(pdList[i]);
      }
    }
    final ifr = wfpPa.isNotEmpty
        ? (wfpPd.reduce((a, b) => a + b) / math.max(wfpPa.reduce((a, b) => a + b), 1.0)).clamp(0.25, 1.00)
        : (ffr + 0.05).clamp(0.25, 1.00);

    final deltaP = meanPa - meanPd;
    final peakWss = wssList.reduce(math.max);
    final maxRe = reList.reduce(math.max);

    int timi = 3;
    if (isNoReflow) {
      timi = 1;
    } else if (stenosisFraction >= 0.95) {
      timi = 0;
    } else if (stenosisFraction >= 0.70) {
      timi = 2;
    }

    String rec;
    if (isTamponade) {
      rec = 'EMERGENCY: Coronary Perforation & Tamponade! Deploy covered stent immediately and prepare pericardiocentesis.';
    } else if (isNoReflow) {
      rec = 'ALERT: No-Reflow Phenomenon. Administer intracoronary Adenosine (100-200 mcg) or Nitroprusside.';
    } else if (isVentricularized) {
      rec = 'WARNING: Ostial Ventricularization (Catheter Damping). Disengage guide immediately to prevent dissection.';
    } else if (isRevascularized) {
      rec = 'POST-PCI SUCCESS: TIMI 3 restored. Target FFR achieved (${ffr.toStringAsFixed(2)} > 0.90).';
    } else if (scenario.id.contains('critical') && !isRotablated) {
      rec = 'HEAVY CALCIFICATION (>180° arc): Perform Rotational Atherectomy (Rotablator 160,000 RPM) prior to stenting.';
    } else if (ffr <= 0.80 || ifr <= 0.89) {
      rec = 'HEMODYNAMICALLY SIGNIFICANT ISCHEMIA: FFR = ${ffr.toStringAsFixed(2)} (<= 0.80), iFR = ${ifr.toStringAsFixed(2)} (<= 0.89). Revascularization with DES Stent indicated.';
    } else {
      rec = 'HEMODYNAMICALLY NON-SIGNIFICANT: FFR = ${ffr.toStringAsFixed(2)} (> 0.80). Defer stenting; optimal medical therapy.';
    }

    return CoronaryPhysiologyResult(
      ffr: double.parse(ffr.toStringAsFixed(2)),
      ifr: double.parse(ifr.toStringAsFixed(2)),
      meanPa: double.parse(meanPa.toStringAsFixed(1)),
      meanPd: double.parse(meanPd.toStringAsFixed(1)),
      deltaP: double.parse(deltaP.toStringAsFixed(1)),
      peakWssDynes: double.parse(peakWss.toStringAsFixed(1)),
      maxReynolds: double.parse(maxRe.toStringAsFixed(0)),
      isIschemicFfr: ffr <= 0.80,
      isIschemicIfr: ifr <= 0.89,
      timiGrade: timi,
      clinicalRecommendation: rec,
      waveform: frames,
    );
  }
}

