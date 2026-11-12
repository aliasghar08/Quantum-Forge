// ============================================================================
// Multi-Parameter Bedside Hospital Oscilloscope & Telemetry Workstation
// ----------------------------------------------------------------------------
// Modeled after Philips IntelliVue MX800 / GE CARESCAPE B850 ICU & Cath Lab Monitors.
// Features:
// 1. 5-Channel Synchronized Hospital Oscilloscope:
//    - Ch 1: ECG Lead II (or selected active territory lead) — Phosphor Green (#00E676)
//    - Ch 2: ECG V1 Precordial Lead — Lime Green (#69F0AE)
//    - Ch 3: Invasive ABP Pa (Crimson #FF5252) + Distal Pd (Yellow #FFD740)
//    - Ch 4: Plethysmograph SpO₂ — Cyan (#00E5FF) with ~150 ms systolic delay
//    - Ch 5: Capnography EtCO₂ — Amber (#FFAB40) alveolar plateau (0-50 mmHg)
// 2. 14 Real-Time Arrhythmias & Conduction States:
//    - Sinus: NSR, Sinus Bradycardia, Sinus Tachycardia
//    - Atrial: Atrial Fibrillation (RVR), Atrial Flutter (2:1), SVT (AVNRT)
//    - AV Blocks: 1° AV Block, 2° Mobitz I (Wenckebach), 2° Mobitz II, 3° Complete AV Block
//    - Ventricular / Arrest: Monomorphic VT, Torsades de Pointes, VFib, Asystole
// 3. Electronic Oscilloscope Calipers & Freeze-Frame Mode:
//    - Draggable vertical calipers (C1, C2) computing delta t (ms) and rate (bpm)
// 4. Bedside Resuscitation Console:
//    - Defibrillator (200J Biphasic Shock) delivering shock artifact and ROSC surge
//    - Transcutaneous Pacing (TCP) with pacing spikes and 70 bpm capture
// 5. Right-Hand Hospital Numeric Parameter Readout Tiles:
//    - Stacked color-coded tiles: HR, ABP SYS/DIA (MAP), SpO₂ %, EtCO₂ / RR, PR/QRS/QTc
// 6. SaMD 7-Pillar Legal Shield Banner: Educational Simulation Only
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';
import 'cardiac_clinical_info_system.dart';

/// Signal generation realism mode: physiological artifacts vs idealized textbook geometry.
enum OscilloscopeSignalMode {
  realBedside('Real Bedside Signal', 'Full physiological wander, EMG micro-jitter, HRV & catheter ringing'),
  cleanTextbook('Clean Textbook', 'Zero-noise idealized mathematical teaching curves');

  final String label;
  final String description;
  const OscilloscopeSignalMode(this.label, this.description);
}

/// Visual display theme: dark phosphor monitor vs authentic hospital thermal paper printout.
enum OscilloscopeDisplayTheme {
  icuPhosphor('ICU Phosphor CRT', 'Classic dark cath lab monitor with luminous phosphor traces'),
  thermalPaper('Hospital Thermal Paper', 'Authentic pink/red 1mm/5mm grid with dark ink needle recording');

  final String label;
  final String description;
  const OscilloscopeDisplayTheme(this.label, this.description);
}

class CardiacHemodynamicEcgStrip extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase; // 0.0 to 1.0 (repeating cycle)
  final double bpm;
  final ValueChanged<double> onBpmChanged;
  final EcgTerritoryLead activeTerritory;
  final ValueChanged<EcgTerritoryLead>? onTerritoryChanged;
  final bool isRevascularized;
  final InterventionalWireType wireType;
  final GuideCatheterType catheterType;
  final AcuteComplicationState complication;
  final bool iabpActive;
  final double? ffrValue;
  final double? ifrValue;
  final double? wssDynes;

  // Next-Gen Multi-Parameter Oscilloscope props
  final OscilloscopeRhythmType initialRhythm;
  final ValueChanged<OscilloscopeRhythmType>? onRhythmChanged;
  final VoidCallback? onDefibrillated;

  // Realistic Signal & Theme Options
  final OscilloscopeSignalMode initialSignalMode;
  final OscilloscopeDisplayTheme initialDisplayTheme;
  final bool initialMainsHum;

  const CardiacHemodynamicEcgStrip({
    super.key,
    required this.scenario,
    required this.cardiacPhase,
    required this.bpm,
    required this.onBpmChanged,
    this.activeTerritory = EcgTerritoryLead.leadII,
    this.onTerritoryChanged,
    this.isRevascularized = false,
    this.wireType = InterventionalWireType.workhorse,
    this.catheterType = GuideCatheterType.jl4,
    this.complication = AcuteComplicationState.none,
    this.iabpActive = false,
    this.ffrValue,
    this.ifrValue,
    this.wssDynes,
    this.initialRhythm = OscilloscopeRhythmType.nsr,
    this.onRhythmChanged,
    this.onDefibrillated,
    this.initialSignalMode = OscilloscopeSignalMode.realBedside,
    this.initialDisplayTheme = OscilloscopeDisplayTheme.icuPhosphor,
    this.initialMainsHum = false,
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Public Clinical Mathematical Models (Exposed for High-Fidelity Verification)
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes synthetic ECG amplitude (mV) at cardiac cycle phase [phase] in [0.0, 1.0).
  ///
  /// Milestones (25 mm/s, 10 mm/mV):
  /// - P-wave: [0.08, 0.17] -> smooth upright dome, peak +0.15 mV.
  /// - PR-segment: (0.17, 0.23) -> isoelectric 0.00 mV (AV nodal delay).
  /// - QRS-complex: [0.23, 0.31] (< 85 ms narrow duration):
  ///   * Q-wave: [0.230, 0.255] -> nadir -0.15 mV at phi = 0.245.
  ///   * R-wave: [0.255, 0.285] -> razor-sharp triangular spike peaking at +1.25 mV at phi = 0.270.
  ///   * S-wave: [0.285, 0.310] -> sharp nadir -0.28 mV at phi = 0.295, returning to J-point at 0.310.
  /// - ST-segment & T-wave: (0.310, 0.560]:
  ///   * ST deviation: localized elevation/depression decaying from J-point into T-wave.
  ///   * T-wave: upright dome peaking at phi = 0.460 (+0.32 mV), ending by phi = 0.560.
  /// - Diastole (TP interval): (0.560, 1.0] and [0.0, 0.08) -> isoelectric 0.00 mV.
  static double computeSyntheticEcgSample(double phase, double stElevationMm) {
    final phi = phase % 1.0;
    double v = 0.0;

    if (phi >= 0.08 && phi <= 0.17) {
      // P-Wave (Atrial Depolarization)
      v = 0.15 * math.sin((phi - 0.08) / 0.09 * math.pi);
    } else if (phi > 0.17 && phi < 0.230) {
      // PR Segment (AV Nodal Delay)
      v = 0.0;
    } else if (phi >= 0.230 && phi <= 0.255) {
      // Q-Wave Dip (Nadir -0.15 mV at phi = 0.245)
      v = -0.15 * math.sin((phi - 0.230) / 0.025 * math.pi);
    } else if (phi > 0.255 && phi <= 0.285) {
      // R-Wave Razor-Sharp Spike (Peak +1.25 mV at phi = 0.270)
      if (phi <= 0.270) {
        v = 1.25 * ((phi - 0.255) / 0.015);
      } else {
        v = 1.25 * ((0.285 - phi) / 0.015);
      }
    } else if (phi > 0.285 && phi <= 0.310) {
      // S-Wave Nadir (-0.28 mV at phi = 0.295)
      v = -0.28 * math.sin((phi - 0.285) / 0.025 * math.pi);
    } else if (phi > 0.310 && phi <= 0.560) {
      // ST Segment & Asymmetric T-Wave (Repolarization)
      final stMv = (stElevationMm / 10.0);
      final stProgress = (phi - 0.310) / 0.250;
      final stOffset = stMv * math.cos(stProgress * math.pi * 0.5);

      double tWave = 0.0;
      if (phi >= 0.340) {
        final tProg = (phi - 0.340) / 0.220;
        tWave = 0.32 * math.pow(math.sin(tProg * math.pi), 1.2);
      }
      v = stOffset + tWave;
    } else {
      // Isoelectric baseline during diastole
      v = 0.0;
    }

    return v;
  }

  /// Computes physiological Aortic Pressure Pa (mmHg) at cardiac cycle phase [phase].
  static double computeAorticPressure(
    double phase,
    bool damped,
    bool iabp, {
    double systolicBp = 120.0,
    double diastolicBp = 80.0,
  }) {
    final phi = phase % 1.0;

    if (damped) {
      // Catheter wedged into ostium / LM ventricularization
      if (phi >= 0.28 && phi <= 0.48) {
        final tau = (phi - 0.28) / 0.20;
        return 20.0 + (systolicBp * 0.55) * math.sin(tau * math.pi);
      } else {
        return 18.0;
      }
    }

    double p;
    if (phi >= 0.330 && phi <= 0.440) {
      // Rapid Systolic Ejection Upstroke
      final tau = (phi - 0.330) / 0.110;
      p = diastolicBp + (systolicBp - diastolicBp) * math.pow(math.sin(tau * math.pi * 0.5), 1.15);
    } else if (phi > 0.440 && phi <= 0.560) {
      // Reduced Ejection
      final tau = (phi - 0.440) / 0.120;
      p = systolicBp - (systolicBp - 91.0) * math.sin(tau * math.pi * 0.5);
    } else if (phi > 0.560 && phi <= 0.600) {
      // Dicrotic Notch Incisura & Rebound (Aortic Valve Closure at phi = 0.570)
      final tau = (phi - 0.560) / 0.040;
      p = 91.0 - 2.0 * math.sin(tau * 2.0 * math.pi) + 3.0 * tau;
    } else if (phi >= 0.260 && phi < 0.330) {
      // End-Diastolic Plateau & Isovolumetric Contraction (Aortic Valve Closed)
      p = diastolicBp;
    } else {
      // Diastolic Windkessel Runoff (Exponential Decay towards Diastolic BP)
      final tRun = phi > 0.600 ? (phi - 0.600) / 0.660 : (phi + 0.400) / 0.660;
      p = diastolicBp + (94.0 - diastolicBp) * math.exp(-3.0 * tRun);
    }

    // Intra-Aortic Balloon Pump (IABP) 1:1 Counterpulsation Augmentation
    if (iabp) {
      if (phi >= 0.570 && phi <= 0.880) {
        // Balloon inflation at dicrotic notch provides diastolic coronary augmentation
        final iabpTau = (phi - 0.570) / 0.310;
        p += 36.0 * math.sin(iabpTau * math.pi);
      } else if (phi > 0.880) {
        // Presystolic balloon deflation unloads left ventricle afterload
        p -= 10.0;
      }
    }

    return p;
  }

  /// Synthesizes Precordial Lead V1 sample (mV)
  static double computePrecordialV1Sample(double phase, OscilloscopeRhythmType rhythm) {
    final phi = phase % 1.0;
    if (rhythm == OscilloscopeRhythmType.vfib) {
      return 0.30 * math.sin(phi * 28.0) + 0.22 * math.sin(phi * 44.0 + 1.2);
    }
    if (rhythm == OscilloscopeRhythmType.asystole) {
      return 0.01 * math.sin(phi * 4.0);
    }
    if (rhythm == OscilloscopeRhythmType.vtach) {
      // Negative concordance wide QRS in V1
      if (phi >= 0.20 && phi <= 0.38) {
        final tau = (phi - 0.20) / 0.18;
        return -1.3 * math.sin(tau * math.pi);
      }
      return 0.15 * math.sin(phi * 6.0);
    }
    if (rhythm == OscilloscopeRhythmType.torsades) {
      final tau = (phi - 0.20) / 0.18;
      if (phi >= 0.20 && phi <= 0.38) {
        return 1.1 * math.sin(tau * math.pi) * math.cos(phase * 4.0);
      }
      return 0.0;
    }
    // Normal V1 morphology: small r +0.2 mV, deep S -0.9 mV
    if (phi >= 0.250 && phi <= 0.270) {
      final tau = (phi - 0.250) / 0.020;
      return 0.22 * math.sin(tau * math.pi);
    } else if (phi > 0.270 && phi <= 0.315) {
      final tau = (phi - 0.270) / 0.045;
      return -0.95 * math.sin(tau * math.pi);
    } else if (phi > 0.340 && phi <= 0.540) {
      final tau = (phi - 0.340) / 0.200;
      return 0.16 * math.sin(tau * math.pi);
    }
    return 0.0;
  }

  /// Synthesizes Photoplethysmogram SpO2 Pleth sample (0.0 to 1.0)
  static double computePlethSample(double phase, OscilloscopeRhythmType rhythm, double spo2Pct) {
    if (rhythm == OscilloscopeRhythmType.vfib || rhythm == OscilloscopeRhythmType.asystole) {
      return 0.04 + 0.01 * math.sin(phase * 12.0); // Flatline/no pulse
    }
    final phi = phase % 1.0;
    final amp = (rhythm == OscilloscopeRhythmType.vtach || rhythm == OscilloscopeRhythmType.torsades)
        ? 0.30
        : (spo2Pct / 100.0);

    // Delayed pulse arriving ~140 ms post-QRS (phi ~0.40 to 0.85)
    if (phi >= 0.38 && phi <= 0.54) {
      final tau = (phi - 0.38) / 0.16;
      return 0.05 + amp * 0.95 * math.sin(tau * math.pi * 0.5);
    } else if (phi > 0.54 && phi <= 0.68) {
      final tau = (phi - 0.54) / 0.14;
      return 0.05 + amp * (0.95 - 0.32 * tau);
    } else if (phi > 0.68 && phi <= 0.76) {
      // Dicrotic reflection
      final tau = (phi - 0.68) / 0.08;
      return 0.05 + amp * (0.63 + 0.10 * math.sin(tau * math.pi));
    } else if (phi > 0.76 && phi <= 0.98) {
      final tau = (phi - 0.76) / 0.22;
      return 0.05 + amp * 0.63 * math.exp(-3.0 * tau);
    }
    return 0.05;
  }

  /// Synthesizes Alveolar Capnogram EtCO2 sample (0 to 50 mmHg)
  static double computeEtco2Sample(double phase, OscilloscopeRhythmType rhythm, double etco2MmHg) {
    if (rhythm == OscilloscopeRhythmType.vfib || rhythm == OscilloscopeRhythmType.asystole) {
      return math.min(etco2MmHg, 8.0); // Severe low-flow arrest capnography (< 10 mmHg)
    }
    final phi = phase % 1.0;
    // Expiration: 0.10 to 0.50 | Inspiration: 0.50 to 1.0
    if (phi < 0.10) {
      return 0.0; // Phase I
    } else if (phi >= 0.10 && phi <= 0.18) {
      // Phase II upstroke
      final tau = (phi - 0.10) / 0.08;
      return (etco2MmHg * 0.85) * (1.0 / (1.0 + math.exp(-10.0 * (tau - 0.5))));
    } else if (phi > 0.18 && phi <= 0.48) {
      // Phase III alveolar plateau
      final tau = (phi - 0.18) / 0.30;
      return etco2MmHg * 0.85 + (etco2MmHg * 0.15) * tau;
    } else if (phi > 0.48 && phi <= 0.53) {
      // Phase IV inspiratory downstroke
      final tau = (phi - 0.48) / 0.05;
      return etco2MmHg * (1.0 - tau);
    }
    return 0.0;
  }

  @override
  State<CardiacHemodynamicEcgStrip> createState() => _CardiacHemodynamicEcgStripState();
}

class _CardiacHemodynamicEcgStripState extends State<CardiacHemodynamicEcgStrip> {
  int _beatParity = 0;
  double _lastPhase = 0.0;

  // Multi-parameter Monitor State
  late OscilloscopeRhythmType _currentRhythm;
  late OscilloscopeSignalMode _signalMode;
  late OscilloscopeDisplayTheme _displayTheme;
  late bool _mainsHum;
  bool _isFrozen = false;
  double _caliper1X = 0.30; // 0.0 to 1.0
  double _caliper2X = 0.55; // 0.0 to 1.0
  int _sweepSpeedMmS = 25;  // 25 mm/s vs 50 mm/s
  int _ecgGainMmMv = 10;    // 5, 10, 20 mm/mV
  bool _tcpActive = false;  // Transcutaneous pacing
  bool _showShockFlash = false;
  String? _alertBannerText;
  Color _alertBannerColor = const Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    _currentRhythm = widget.initialRhythm;
    _signalMode = widget.initialSignalMode;
    _displayTheme = widget.initialDisplayTheme;
    _mainsHum = widget.initialMainsHum;
    _updateAlertBanner();
  }

  @override
  void didUpdateWidget(covariant CardiacHemodynamicEcgStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFrozen) {
      if (widget.cardiacPhase < _lastPhase && (_lastPhase - widget.cardiacPhase) > 0.5) {
        _beatParity = (_beatParity + 1) % 2;
      }
      _lastPhase = widget.cardiacPhase;
    }
  }

  void _updateAlertBanner() {
    if (_currentRhythm.isArrest) {
      _alertBannerText = '⚠️ CODE BLUE: PULSELESS ARREST (${_currentRhythm.badge}) — RESUSCITATION PROTOCOL ACTIVE';
      _alertBannerColor = const Color(0xFFFF1744);
    } else if (_currentRhythm == OscilloscopeRhythmType.vtach || _currentRhythm == OscilloscopeRhythmType.torsades) {
      _alertBannerText = '⚠️ TACHYARRHYTHMIA ALERT: ${_currentRhythm.label} — UNSTABLE HEMODYNAMICS';
      _alertBannerColor = const Color(0xFFFF9100);
    } else if (_currentRhythm == OscilloscopeRhythmType.avb3Complete) {
      _alertBannerText = '⚠️ CRITICAL CONDUCTION BLOCK: 3° COMPLETE HEART BLOCK — PACEMAKER INDICATED';
      _alertBannerColor = const Color(0xFFFF5252);
    } else {
      _alertBannerText = null;
    }
  }

  void _switchRhythm(OscilloscopeRhythmType rhythm) {
    setState(() {
      _currentRhythm = rhythm;
      _updateAlertBanner();
      // Adjust heart rate to match rhythm
      if (rhythm.defaultHr > 0) {
        widget.onBpmChanged(rhythm.defaultHr.toDouble());
      }
    });
    widget.onRhythmChanged?.call(rhythm);
  }

  void _deliver200JDefib() {
    setState(() {
      _showShockFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showShockFlash = false;
          if (_currentRhythm.isShockable || _currentRhythm.isArrest) {
            // Achieve ROSC back to NSR
            _currentRhythm = OscilloscopeRhythmType.nsr;
            widget.onBpmChanged(85.0);
            _alertBannerText = '⚡ 200J BIPHASIC DELIVERED — ROSC ACHIEVED (NSR 85 BPM, EtCO₂ SURGED > 40 mmHg)';
            _alertBannerColor = const Color(0xFF00E676);
          } else {
            _alertBannerText = '⚡ 200J BIPHASIC SYNCHRONIZED CARDIOVERSION DELIVERED';
            _alertBannerColor = const Color(0xFF00E5FF);
          }
        });
        widget.onDefibrillated?.call();
        widget.onRhythmChanged?.call(_currentRhythm);
      }
    });
  }

  void _toggleTcpPacing() {
    setState(() {
      _tcpActive = !_tcpActive;
      if (_tcpActive) {
        widget.onBpmChanged(70.0);
        _alertBannerText = '⚡ TRANSCUTANEOUS PACING ACTIVE — VENTRICULAR CAPTURE AT 70 BPM';
        _alertBannerColor = const Color(0xFF69F0AE);
      } else {
        _updateAlertBanner();
      }
    });
  }

  double _computeEffectiveStElevation() {
    double baseSt;
    if (widget.scenario.id.contains('anterior_stemi')) {
      switch (widget.activeTerritory) {
        case EcgTerritoryLead.v1V4Anterior:
          baseSt = 4.5;
          break;
        case EcgTerritoryLead.inferiorLeads:
          baseSt = -2.0;
          break;
        case EcgTerritoryLead.lateralLeads:
          baseSt = 1.2;
          break;
        case EcgTerritoryLead.leadII:
          baseSt = widget.scenario.stElevationMm;
          break;
      }
    } else if (widget.scenario.id.contains('inferior_mi')) {
      switch (widget.activeTerritory) {
        case EcgTerritoryLead.inferiorLeads:
          baseSt = 3.8;
          break;
        case EcgTerritoryLead.v1V4Anterior:
          baseSt = -2.2;
          break;
        case EcgTerritoryLead.lateralLeads:
          baseSt = -1.5;
          break;
        case EcgTerritoryLead.leadII:
          baseSt = widget.scenario.stElevationMm;
          break;
      }
    } else {
      baseSt = widget.scenario.stElevationMm;
    }

    if (widget.isRevascularized) {
      return baseSt * 0.25;
    }
    return baseSt;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    // Compute active hemodynamics
    final isShock = widget.complication == AcuteComplicationState.cardiogenicShock;
    final baseSys = isShock ? 75.0 : _currentRhythm.defaultSys.toDouble();
    final baseDia = isShock ? 48.0 : _currentRhythm.defaultDia.toDouble();
    final sys = _tcpActive ? 112.0 : baseSys;
    final dia = _tcpActive ? 70.0 : baseDia;
    final map = dia + (sys - dia) / 3.0;
    final spo2 = _tcpActive ? 97.0 : _currentRhythm.defaultSpo2;
    final etco2 = _tcpActive ? 38.0 : _currentRhythm.defaultEtco2;
    final effectiveSt = _computeEffectiveStElevation();

    final isPressureWire = widget.wireType == InterventionalWireType.pressureWireX;
    final isDamped = widget.scenario.isCatheterDamped ||
        widget.complication == AcuteComplicationState.lmVentricularization ||
        (widget.catheterType == GuideCatheterType.al1 && widget.scenario.id.contains('critical_lm'));

    final isQrsActive = widget.cardiacPhase >= 0.255 && widget.cardiacPhase <= 0.295;
    final sweepProgress = (_beatParity * 0.5) + (widget.cardiacPhase * 0.5);
    final isThermal = _displayTheme == OscilloscopeDisplayTheme.thermalPaper;

    return Container(
      decoration: BoxDecoration(
        color: isThermal ? const Color(0xFFFFF1F1) : const Color(0xFF05080E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showShockFlash
              ? Colors.white
              : (isThermal ? const Color(0xFFE57373) : palette.border),
          width: _showShockFlash ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Oscilloscope Header & Resuscitation Bar ─────────────────
            _buildMonitorHeader(sys, dia, map, effectiveSt, isPressureWire, isDamped, isQrsActive),

            // ── Flashing Code Blue / Tachyarrhythmia Alert Banner ───────────
            if (_alertBannerText != null) _buildAlertBanner(),

            // ── 14-Rhythm Hospital Selector Bar ────────────────────────────
            _buildRhythmSelectorBar(),

            // ── 5-Channel Canvas + Right ICU Parameter Tiles ────────────────
            SizedBox(
              height: 230,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Oscilloscope Waveforms Canvas with Draggable Calipers
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FiveChannelHospitalOscilloscopePainter(
                              cardiacPhase: _isFrozen ? _lastPhase : widget.cardiacPhase,
                              sweepProgress: _isFrozen ? 0.85 : sweepProgress,
                              rhythm: _currentRhythm,
                              stElevationMm: effectiveSt,
                              isDamped: isDamped,
                              systolicBp: sys,
                              diastolicBp: dia,
                              spo2Pct: spo2,
                              etco2MmHg: etco2,
                              leadLabel: widget.activeTerritory.label,
                              wireType: widget.wireType,
                              iabpActive: widget.iabpActive,
                              ffrValue: widget.ffrValue,
                              sweepSpeedMmS: _sweepSpeedMmS,
                              gainMmMv: _ecgGainMmMv,
                              tcpActive: _tcpActive,
                              signalMode: _signalMode,
                              displayTheme: _displayTheme,
                              mainsHum: _mainsHum,
                            ),
                          ),
                        ),

                        // Electronic Calipers Overlay in Freeze Mode
                        if (_isFrozen)
                          Positioned.fill(
                            child: _buildCaliperOverlay(),
                          ),
                      ],
                    ),
                  ),

                  // Right-Hand ICU Numeric Parameter Tiles
                  _buildRightIcuNumericTiles(sys, dia, map, spo2, etco2, isQrsActive),
                ],
              ),
            ),

            // ── Bottom Telemetry Secondary Controls Bar ─────────────────────
            _buildBottomControlsBar(),
          ],
        ),
      ),
    );
  }

  Widget _vitalsBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9.5,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _qrsSyncIndicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF00E676).withValues(alpha: 0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? const Color(0xFF00E676) : Colors.white12,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF00E676) : const Color(0xFF0B331A),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'QRS',
            style: TextStyle(
              color: active ? const Color(0xFF00E676) : Colors.white30,
              fontSize: 8.5,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorHeader(
    double sys,
    double dia,
    double map,
    double effectiveSt,
    bool isPressureWire,
    bool isDamped,
    bool isQrsActive,
  ) {
    final isThermal = _displayTheme == OscilloscopeDisplayTheme.thermalPaper;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isThermal ? const Color(0xFFFFEBEE) : const Color(0xFF0C131D),
        border: Border(
          bottom: BorderSide(
            color: isThermal ? const Color(0xFFEF9A9A) : Colors.white12,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.monitor_heart_rounded,
              color: isThermal ? const Color(0xFFB71C1C) : const Color(0xFF00E676),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'CATH LAB TELEMETRY',
              style: TextStyle(
                color: isThermal ? const Color(0xFFB71C1C) : const Color(0xFF00E676),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            const CardiacInfoButton(
              topicId: 'viewport_telemetry',
              customLabel: 'Wiggers & ECG Info',
              size: 11,
            ),
            const SizedBox(width: 10),

            // Heart Rate with live R-Wave QRS Sync LED
            _vitalsBadge(
              label: 'HR',
              value: '${widget.bpm.round()} bpm',
              color: widget.bpm < 60
                  ? const Color(0xFFFFB300)
                  : (widget.bpm > 100
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF00E676)),
            ),
            const SizedBox(width: 6),
            _qrsSyncIndicator(isQrsActive),
            const SizedBox(width: 10),

            _vitalsBadge(
              label: 'Ao BP',
              value: '${sys.round()}/${dia.round()} mmHg',
              color: isDamped
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00E5FF),
            ),
            const SizedBox(width: 10),
            _vitalsBadge(
              label: 'MAP',
              value: '${map.round()} mmHg',
              color: map < 65
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00E5FF),
            ),
            const SizedBox(width: 10),

            // ST-Segment elevation / depression readout
            _vitalsBadge(
              label: 'ST (${widget.activeTerritory.shortLabel})',
              value: '${effectiveSt >= 0 ? "+" : ""}${effectiveSt.toStringAsFixed(1)} mm',
              color: effectiveSt.abs() > 1.0
                  ? (effectiveSt > 0 ? const Color(0xFFFF1744) : const Color(0xFF38BDF8))
                  : const Color(0xFF00E676),
            ),

            // Pressure Wire Metrics (FFR & iFR)
            if (isPressureWire && widget.ffrValue != null) ...[
              const SizedBox(width: 10),
              _vitalsBadge(
                label: 'FFR (Pd/Pa)',
                value: widget.ffrValue!.toStringAsFixed(2),
                color: widget.ffrValue! <= 0.80
                    ? const Color(0xFFFF1744)
                    : const Color(0xFF00E676),
              ),
            ],

            if (isPressureWire && widget.ifrValue != null) ...[
              const SizedBox(width: 10),
              _vitalsBadge(
                label: 'iFR (WFP)',
                value: widget.ifrValue!.toStringAsFixed(2),
                color: widget.ifrValue! <= 0.89
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF00E676),
              ),
            ],

            if (widget.wssDynes != null) ...[
              const SizedBox(width: 10),
              _vitalsBadge(
                label: 'WSS',
                value: '${widget.wssDynes!.toStringAsFixed(0)} dyn/cm²',
                color: widget.wssDynes! > 70.0
                    ? const Color(0xFFFFB300)
                    : const Color(0xFF38BDF8),
              ),
            ],

            if (widget.iabpActive) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF8B5CF6)),
                ),
                child: const Text(
                  'IABP 1:1 AUGMENTATION',
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 12),

            // Defibrillator 200J Biphasic Button
            ElevatedButton.icon(
              onPressed: _deliver200JDefib,
              icon: const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
              label: Text(
                _currentRhythm.isShockable ? '200J DEFIB (SHOCKABLE)' : '200J BIPHASIC SHOCK',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentRhythm.isShockable ? const Color(0xFFFF1744) : const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),

            // Transcutaneous Pacing (TCP) Toggle
            OutlinedButton.icon(
              onPressed: _toggleTcpPacing,
              icon: Icon(Icons.flash_on_rounded, size: 12, color: _tcpActive ? const Color(0xFF00E676) : Colors.white60),
              label: Text(
                _tcpActive ? 'TCP: 70 BPM (CAPTURED)' : 'TCP PACER (70 BPM)',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: _tcpActive ? const Color(0xFF00E676) : Colors.white70,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _tcpActive ? const Color(0xFF00E676) : Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),

            // Freeze / Calipers Toggle
            OutlinedButton.icon(
              onPressed: () => setState(() => _isFrozen = !_isFrozen),
              icon: Icon(_isFrozen ? Icons.play_arrow_rounded : Icons.ac_unit_rounded, size: 12, color: _isFrozen ? const Color(0xFF00E5FF) : Colors.white60),
              label: Text(
                _isFrozen ? 'UNFREEZE' : 'FREEZE CALIPERS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: _isFrozen ? const Color(0xFF00E5FF) : Colors.white70,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _isFrozen ? const Color(0xFF00E5FF) : Colors.white24),
                backgroundColor: _isFrozen ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),

            // Sweep Speed Toggle (25 vs 50 mm/s)
            InkWell(
              onTap: () => setState(() => _sweepSpeedMmS = (_sweepSpeedMmS == 25) ? 50 : 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SWEEP: $_sweepSpeedMmS mm/s',
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // ECG Gain Toggle (5, 10, 20 mm/mV)
            InkWell(
              onTap: () => setState(() {
                if (_ecgGainMmMv == 5) {
                  _ecgGainMmMv = 10;
                } else if (_ecgGainMmMv == 10) {
                  _ecgGainMmMv = 20;
                } else {
                  _ecgGainMmMv = 5;
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GAIN: $_ecgGainMmMv mm/mV',
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Heart Rate slider control
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pace:', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                SizedBox(
                  width: 75,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 7),
                      activeTrackColor: const Color(0xFF00E676),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const Color(0xFF00E676),
                    ),
                    child: Slider(
                      value: widget.bpm,
                      min: 45.0,
                      max: 130.0,
                      onChanged: widget.onBpmChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // ── Realism Control 1: Signal Realism Mode Toggle ───────────────
            InkWell(
              key: const Key('oscilloscope_signal_mode_toggle'),
              onTap: () => setState(() {
                _signalMode = (_signalMode == OscilloscopeSignalMode.realBedside)
                    ? OscilloscopeSignalMode.cleanTextbook
                    : OscilloscopeSignalMode.realBedside;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _signalMode == OscilloscopeSignalMode.realBedside
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: _signalMode == OscilloscopeSignalMode.realBedside
                        ? const Color(0xFF00E676)
                        : Colors.white24,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _signalMode == OscilloscopeSignalMode.realBedside
                          ? Icons.grain_rounded
                          : Icons.show_chart_rounded,
                      size: 11,
                      color: _signalMode == OscilloscopeSignalMode.realBedside
                          ? const Color(0xFF00E676)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _signalMode == OscilloscopeSignalMode.realBedside
                          ? 'REAL BEDSIDE'
                          : 'CLEAN TEXTBOOK',
                      style: TextStyle(
                        color: _signalMode == OscilloscopeSignalMode.realBedside
                            ? const Color(0xFF00E676)
                            : Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Realism Control 2: 60 Hz Mains Hum Filter Toggle ─────────────
            InkWell(
              key: const Key('oscilloscope_mains_hum_toggle'),
              onTap: () => setState(() => _mainsHum = !_mainsHum),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _mainsHum
                      ? const Color(0xFFFF9100).withValues(alpha: 0.2)
                      : const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  border: Border.all(
                    color: _mainsHum ? const Color(0xFFFF9100) : const Color(0xFF00E5FF),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _mainsHum ? Icons.power_rounded : Icons.filter_alt_rounded,
                      size: 11,
                      color: _mainsHum ? const Color(0xFFFF9100) : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _mainsHum ? '60Hz HUM ON' : 'NOTCH FILTER ON',
                      style: TextStyle(
                        color: _mainsHum ? const Color(0xFFFF9100) : const Color(0xFF00E5FF),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Realism Control 3: Display Theme Toggle (CRT vs Thermal Paper) ─
            InkWell(
              key: const Key('oscilloscope_display_theme_toggle'),
              onTap: () => setState(() {
                _displayTheme = (_displayTheme == OscilloscopeDisplayTheme.icuPhosphor)
                    ? OscilloscopeDisplayTheme.thermalPaper
                    : OscilloscopeDisplayTheme.icuPhosphor;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isThermal
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFF1E293B),
                  border: Border.all(
                    color: isThermal
                        ? const Color(0xFFE53935)
                        : const Color(0xFF64748B),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isThermal
                          ? Icons.receipt_long_rounded
                          : Icons.tv_rounded,
                      size: 11,
                      color: isThermal
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isThermal
                          ? 'THERMAL PAPER'
                          : 'ICU PHOSPHOR CRT',
                      style: TextStyle(
                        color: isThermal
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF38BDF8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: _alertBannerColor.withValues(alpha: 0.25),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: _alertBannerColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _alertBannerText!,
              style: TextStyle(
                color: _alertBannerColor,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF080D14),
      child: Row(
        children: [
          const Text(
            'RHYTHM:',
            style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: OscilloscopeRhythmType.values.map((rhythm) {
                  final isSelected = rhythm == _currentRhythm;
                  Color chipColor = const Color(0xFF00E676);
                  if (rhythm.isArrest) {
                    chipColor = const Color(0xFFFF1744);
                  } else if (rhythm == OscilloscopeRhythmType.vtach || rhythm == OscilloscopeRhythmType.torsades) {
                    chipColor = const Color(0xFFFF9100);
                  } else if (rhythm == OscilloscopeRhythmType.avb3Complete || rhythm == OscilloscopeRhythmType.avb2Mobitz2) {
                    chipColor = const Color(0xFFFF5252);
                  } else if (rhythm == OscilloscopeRhythmType.afib || rhythm == OscilloscopeRhythmType.aflutter || rhythm == OscilloscopeRhythmType.svt) {
                    chipColor = const Color(0xFFFFD740);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: InkWell(
                      onTap: () => _switchRhythm(rhythm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? chipColor : Colors.white12,
                            width: isSelected ? 1.2 : 0.6,
                          ),
                        ),
                        child: Text(
                          rhythm.badge,
                          style: TextStyle(
                            color: isSelected ? chipColor : Colors.white70,
                            fontSize: 8.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightIcuNumericTiles(
    double sys,
    double dia,
    double map,
    double spo2,
    double etco2,
    bool isQrsActive,
  ) {
    final hrVal = _tcpActive ? 70 : (_currentRhythm.defaultHr > 0 ? _currentRhythm.defaultHr : (widget.bpm.round()));
    final rrVal = _currentRhythm.isArrest ? 0 : (_currentRhythm == OscilloscopeRhythmType.sinusTachy ? 22 : 14);

    return Container(
      width: 140,
      decoration: const BoxDecoration(
        color: Color(0xFF090E17),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tile 1: Heart Rate (HR)
            _icuParamTile(
              label: 'HR bpm',
              value: _currentRhythm.isArrest ? '---' : '$hrVal',
              unit: '60-100',
              color: const Color(0xFF00E676),
              trailing: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isQrsActive ? const Color(0xFF00E676) : const Color(0xFF052A15),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Tile 2: Invasive Blood Pressure (ABP)
            _icuParamTile(
              label: 'ABP Pa mmHg',
              value: _currentRhythm.isArrest ? '15/14' : '${sys.round()}/${dia.round()}',
              unit: 'MAP (${map.round()})',
              color: const Color(0xFFFF5252),
            ),
            const SizedBox(height: 5),

            // Tile 3: SpO2 Pleth
            _icuParamTile(
              label: 'SpO₂ %',
              value: _currentRhythm.isArrest ? '---' : '${spo2.round()}%',
              unit: 'Pleth Normal',
              color: const Color(0xFF00E5FF),
            ),
            const SizedBox(height: 5),

            // Tile 4: EtCO2 Capnography
            _icuParamTile(
              label: 'EtCO₂ mmHg',
              value: '${etco2.round()}',
              unit: 'RR $rrVal',
              color: const Color(0xFFFFAB40),
            ),
            const SizedBox(height: 5),

            // Tile 5: ECG Intervals
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INTERVALS (II)', style: TextStyle(color: Colors.white38, fontSize: 7.5, fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Text('PR: ${_currentRhythm.id.contains("avb_1") ? "260" : "160"} ms', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 8.5, fontFamily: 'monospace')),
                  Text('QRS: ${_currentRhythm == OscilloscopeRhythmType.vtach ? "160" : (_currentRhythm == OscilloscopeRhythmType.avb3Complete ? "145" : "80")} ms', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 8.5, fontFamily: 'monospace')),
                  Text('QTc: ${_currentRhythm == OscilloscopeRhythmType.torsades ? ">540" : "425"} ms', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 8.5, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icuParamTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 8, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                value,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              Text(
                unit,
                style: const TextStyle(color: Colors.white38, fontSize: 7.5, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaliperOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final c1Px = _caliper1X * w;
      final c2Px = _caliper2X * w;
      final deltaPx = (c2Px - c1Px).abs();
      // At 25 mm/s, full width (~800px) ~2.0 sec -> deltaT = (deltaPx / w) * 2000 ms
      final deltaT = (deltaPx / w) * 2000.0;
      final calcRate = deltaT > 20 ? (60000.0 / deltaT).round() : 0;

      return Stack(
        children: [
          // Caliper 1 Line
          Positioned(
            left: c1Px,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _caliper1X = math.max(0.02, math.min(0.98, _caliper1X + details.delta.dx / w));
                });
              },
              child: Container(
                width: 14,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ),
          ),

          // Caliper 2 Line
          Positioned(
            left: c2Px,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _caliper2X = math.max(0.02, math.min(0.98, _caliper2X + details.delta.dx / w));
                });
              },
              child: Container(
                width: 14,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFFF4081),
                  ),
                ),
              ),
            ),
          ),

          // Measurement Floating Badge
          Positioned(
            left: math.min(c1Px, c2Px) + 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E5FF)),
              ),
              child: Text(
                'Δt: ${deltaT.round()} ms | Rate: $calcRate bpm',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF080D14),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Territory:', style: TextStyle(color: Colors.white54, fontSize: 9)),
            const SizedBox(width: 6),
            ...EcgTerritoryLead.values.map((t) {
              final isSel = t == widget.activeTerritory;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => widget.onTerritoryChanged?.call(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.white12),
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        color: isSel ? const Color(0xFF00E676) : Colors.white60,
                        fontSize: 8.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),

            // Legal Shield Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'SaMD 7-Pillar Shield: Educational Simulation Only',
                style: TextStyle(color: Colors.white38, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter: 5-Channel Hospital Oscilloscope (Lead II, V1, ABP, SpO2, EtCO2)
// ─────────────────────────────────────────────────────────────────────────────

class _FiveChannelHospitalOscilloscopePainter extends CustomPainter {
  final double cardiacPhase;
  final double sweepProgress;
  final OscilloscopeRhythmType rhythm;
  final double stElevationMm;
  final bool isDamped;
  final double systolicBp;
  final double diastolicBp;
  final double spo2Pct;
  final double etco2MmHg;
  final String leadLabel;
  final InterventionalWireType wireType;
  final bool iabpActive;
  final double? ffrValue;
  final int sweepSpeedMmS;
  final int gainMmMv;
  final bool tcpActive;
  final OscilloscopeSignalMode signalMode;
  final OscilloscopeDisplayTheme displayTheme;
  final bool mainsHum;

  _FiveChannelHospitalOscilloscopePainter({
    required this.cardiacPhase,
    required this.sweepProgress,
    required this.rhythm,
    required this.stElevationMm,
    required this.isDamped,
    required this.systolicBp,
    required this.diastolicBp,
    required this.spo2Pct,
    required this.etco2MmHg,
    required this.leadLabel,
    required this.wireType,
    required this.iabpActive,
    this.ffrValue,
    required this.sweepSpeedMmS,
    required this.gainMmMv,
    required this.tcpActive,
    required this.signalMode,
    required this.displayTheme,
    required this.mainsHum,
  });

  bool get _isThermal => displayTheme == OscilloscopeDisplayTheme.thermalPaper;
  bool get _isReal => signalMode == OscilloscopeSignalMode.realBedside;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // 5 Channel vertical layout slices
    final chHeight = size.height / 5.0;
    final r1 = Rect.fromLTWH(0, chHeight * 0.0, size.width, chHeight);
    final r2 = Rect.fromLTWH(0, chHeight * 1.0, size.width, chHeight);
    final r3 = Rect.fromLTWH(0, chHeight * 2.0, size.width, chHeight);
    final r4 = Rect.fromLTWH(0, chHeight * 3.0, size.width, chHeight);
    final r5 = Rect.fromLTWH(0, chHeight * 4.0, size.width, chHeight);

    _drawEcgLeadII(canvas, r1);
    _drawEcgPrecordialV1(canvas, r2);
    _drawArterialPressure(canvas, r3);
    _drawSpo2Pleth(canvas, r4);
    _drawEtco2Capno(canvas, r5);

    _drawSweepBeam(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (_isThermal) {
      // Authentic hospital pink thermal paper background & grid
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFFFF1F1),
      );
      final minorPaint = Paint()
        ..color = const Color(0xFFEF9A9A).withValues(alpha: 0.35)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: 0.65)
        ..strokeWidth = 0.8;

      const minorStep = 4.0;
      const majorStep = 20.0;

      for (double x = 0; x < size.width; x += minorStep) {
        if ((x % majorStep).abs() > 0.01) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
        }
      }
      for (double x = 0; x < size.width; x += majorStep) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
      }
      for (double y = 0; y < size.height; y += minorStep) {
        if ((y % majorStep).abs() > 0.01) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
        }
      }
      for (double y = 0; y < size.height; y += majorStep) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
      }

      // Dividers between channels
      final divPaint = Paint()
        ..color = const Color(0xFFD32F2F).withValues(alpha: 0.35)
        ..strokeWidth = 0.8;
      final chH = size.height / 5.0;
      for (int i = 1; i < 5; i++) {
        canvas.drawLine(Offset(0, chH * i), Offset(size.width, chH * i), divPaint);
      }
    } else {
      // Classic dark ICU CRT monitor grid
      final minorPaint = Paint()
        ..color = const Color(0xFFEF5350).withValues(alpha: 0.04)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFFEF5350).withValues(alpha: 0.12)
        ..strokeWidth = 0.8;

      const minorStep = 4.0;
      const majorStep = 20.0;

      for (double x = 0; x < size.width; x += minorStep) {
        if ((x % majorStep).abs() > 0.01) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
        }
      }
      for (double x = 0; x < size.width; x += majorStep) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
      }
      for (double y = 0; y < size.height; y += minorStep) {
        if ((y % majorStep).abs() > 0.01) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
        }
      }
      for (double y = 0; y < size.height; y += majorStep) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
      }

      // Dividers between channels
      final divPaint = Paint()..color = Colors.white12..strokeWidth = 0.8;
      final chH = size.height / 5.0;
      for (int i = 1; i < 5; i++) {
        canvas.drawLine(Offset(0, chH * i), Offset(size.width, chH * i), divPaint);
      }
    }
  }

  void _drawEcgLeadII(Canvas canvas, Rect bounds) {
    final labelColor = _isThermal ? const Color(0xFF7F1D1D) : const Color(0xFF00E676);
    final traceColor = _isThermal ? const Color(0xFF111827) : const Color(0xFF00E676);
    _drawChannelLabel(canvas, bounds, 'ECG $leadLabel', labelColor);

    final baselineY = bounds.top + bounds.height * 0.65;
    final cursorX = sweepProgress * bounds.width;
    const numSamples = 200;
    final gainScale = (gainMmMv / 10.0) * 22.0;

    final paint = Paint()
      ..color = traceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isThermal ? 1.6 : 1.5;

    Path? path;
    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * bounds.width;
      if (_inEraseGap(x, cursorX, bounds.width)) {
        if (path != null) { canvas.drawPath(path, paint); path = null; }
        continue;
      }
      final localPhase = ((x / bounds.width) * 2.0) % 1.0;
      double v = 0.0;
      if (rhythm == OscilloscopeRhythmType.vfib) {
        v = 0.35 * math.sin(localPhase * 32.0) + 0.25 * math.sin(localPhase * 50.0);
      } else if (rhythm == OscilloscopeRhythmType.asystole) {
        v = 0.01 * math.sin(localPhase * 3.0);
      } else if (rhythm == OscilloscopeRhythmType.vtach) {
        if (localPhase >= 0.20 && localPhase <= 0.38) {
          v = 1.35 * math.sin((localPhase - 0.20) / 0.18 * math.pi);
        }
      } else if (rhythm == OscilloscopeRhythmType.torsades) {
        if (localPhase >= 0.20 && localPhase <= 0.38) {
          v = 1.25 * math.sin((localPhase - 0.20) / 0.18 * math.pi) * math.cos(x * 0.02);
        }
      } else {
        v = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(localPhase, stElevationMm);
      }

      if (tcpActive && localPhase >= 0.23 && localPhase <= 0.245) {
        v += 1.8; // Pacing spike
      }

      // Authentic physiological signal realism
      if (_isReal) {
        // Respiratory baseline wander (0.22 Hz)
        final respWander = 0.045 * math.sin((x / bounds.width) * math.pi * 3.5 + sweepProgress * 2.8);
        // Skeletal muscle EMG & electrode micro-noise
        final emgNoise = 0.015 * math.sin(x * 1.83) + 0.010 * math.cos(x * 2.91) + 0.007 * math.sin(x * 5.43);
        // R-wave respiratory amplitude modulation (RSA ±6%)
        final rWaveMod = 1.0 + 0.06 * math.sin(sweepProgress * 3.14);
        // 60 Hz AC mains hum fuzz if enabled
        final hum = mainsHum ? (0.040 * math.sin(x * 3.77)) : 0.0;

        v = (v * rWaveMod) + respWander + emgNoise + hum;
      }

      final y = baselineY - (v * gainScale);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _drawEcgPrecordialV1(Canvas canvas, Rect bounds) {
    final labelColor = _isThermal ? const Color(0xFF1E293B) : const Color(0xFF69F0AE);
    final traceColor = _isThermal ? const Color(0xFF1E293B) : const Color(0xFF69F0AE);
    _drawChannelLabel(canvas, bounds, 'ECG V1 PRECORDIAL', labelColor);

    final baselineY = bounds.top + bounds.height * 0.65;
    final cursorX = sweepProgress * bounds.width;
    const numSamples = 200;
    final gainScale = (gainMmMv / 10.0) * 22.0;

    final paint = Paint()
      ..color = traceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isThermal ? 1.6 : 1.5;

    Path? path;
    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * bounds.width;
      if (_inEraseGap(x, cursorX, bounds.width)) {
        if (path != null) { canvas.drawPath(path, paint); path = null; }
        continue;
      }
      final localPhase = ((x / bounds.width) * 2.0) % 1.0;
      double v = CardiacHemodynamicEcgStrip.computePrecordialV1Sample(localPhase, rhythm);

      // Authentic physiological signal realism
      if (_isReal) {
        final respWander = 0.035 * math.sin((x / bounds.width) * math.pi * 3.5 + sweepProgress * 2.8);
        final emgNoise = 0.012 * math.sin(x * 2.15) + 0.008 * math.cos(x * 3.17);
        final hum = mainsHum ? (0.035 * math.sin(x * 3.77)) : 0.0;
        v = v + respWander + emgNoise + hum;
      }

      final y = baselineY - (v * gainScale);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _drawArterialPressure(Canvas canvas, Rect bounds) {
    final isPressureWire = wireType == InterventionalWireType.pressureWireX;
    final labelColor = _isThermal ? const Color(0xFF991B1B) : const Color(0xFFFF5252);
    final paColor = _isThermal ? const Color(0xFF991B1B) : const Color(0xFFFF5252);
    final pdColor = _isThermal ? const Color(0xFFB45309) : const Color(0xFFFFD740);

    _drawChannelLabel(
      canvas,
      bounds,
      isDamped ? 'ABP Pa (DAMPED)' : (isPressureWire ? 'ABP Pa (RED) / Pd (YEL)' : 'ABP Pa INVASIVE'),
      labelColor,
    );
    final bottomY = bounds.bottom - 4.0;
    final cursorX = sweepProgress * bounds.width;
    const numSamples = 200;

    final paPaint = Paint()..color = paColor..style = PaintingStyle.stroke..strokeWidth = _isThermal ? 1.6 : 1.5;
    final pdPaint = Paint()..color = pdColor..style = PaintingStyle.stroke..strokeWidth = _isThermal ? 1.6 : 1.5;

    Path? paPath;
    Path? pdPath;
    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * bounds.width;
      if (_inEraseGap(x, cursorX, bounds.width)) {
        if (paPath != null) { canvas.drawPath(paPath, paPaint); paPath = null; }
        if (pdPath != null) { canvas.drawPath(pdPath, pdPaint); pdPath = null; }
        continue;
      }
      final localPhase = ((x / bounds.width) * 2.0) % 1.0;
      double pa = 0.0;
      if (rhythm == OscilloscopeRhythmType.asystole) {
        pa = 10.0;
      } else if (rhythm == OscilloscopeRhythmType.vfib) {
        pa = 15.0 + 1.5 * math.sin(localPhase * 30.0);
      } else {
        pa = CardiacHemodynamicEcgStrip.computeAorticPressure(localPhase, isDamped, iabpActive, systolicBp: systolicBp, diastolicBp: diastolicBp);
      }

      // Authentic arterial line realism
      if (_isReal) {
        // Respiratory swing across cycle (-4.5 mmHg)
        final respSwing = -4.5 * math.sin(sweepProgress * 3.14);
        // Catheter fluid resonance ringing post systolic ejection
        double ringing = 0.0;
        if (localPhase >= 0.36 && localPhase <= 0.44) {
          ringing = 2.8 * math.sin((localPhase - 0.36) / 0.08 * 8.0 * math.pi) * (1.0 - (localPhase - 0.36) / 0.08);
        }
        pa = pa + respSwing + ringing;
      }

      final yPa = bottomY - ((pa - 10.0) / 160.0) * (bounds.height * 0.85);
      if (paPath == null) {
        paPath = Path()..moveTo(x, yPa);
      } else {
        paPath.lineTo(x, yPa);
      }

      if (isPressureWire) {
        final drop = (ffrValue != null) ? (1.0 - ffrValue!) * 40.0 : 25.0;
        final pd = math.max(pa - drop, 12.0);
        final yPd = bottomY - ((pd - 10.0) / 160.0) * (bounds.height * 0.85);
        if (pdPath == null) {
          pdPath = Path()..moveTo(x, yPd);
        } else {
          pdPath.lineTo(x, yPd);
        }
      }
    }
    if (paPath != null) canvas.drawPath(paPath, paPaint);
    if (pdPath != null) canvas.drawPath(pdPath, pdPaint);
  }

  void _drawSpo2Pleth(Canvas canvas, Rect bounds) {
    final labelColor = _isThermal ? const Color(0xFF0E7490) : const Color(0xFF00E5FF);
    final traceColor = _isThermal ? const Color(0xFF0E7490) : const Color(0xFF00E5FF);
    _drawChannelLabel(canvas, bounds, 'PLETH SpO₂', labelColor);

    final bottomY = bounds.bottom - 4.0;
    final cursorX = sweepProgress * bounds.width;
    const numSamples = 200;

    final paint = Paint()..color = traceColor..style = PaintingStyle.stroke..strokeWidth = _isThermal ? 1.6 : 1.5;
    Path? path;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * bounds.width;
      if (_inEraseGap(x, cursorX, bounds.width)) {
        if (path != null) { canvas.drawPath(path, paint); path = null; }
        continue;
      }
      final localPhase = ((x / bounds.width) * 2.0) % 1.0;
      double pleth = CardiacHemodynamicEcgStrip.computePlethSample(localPhase, rhythm, spo2Pct);

      if (_isReal) {
        final plethMod = 0.020 * math.sin(sweepProgress * 3.14);
        final plethJitter = 0.005 * math.sin(x * 1.5);
        pleth = math.max(0.0, math.min(1.0, pleth + plethMod + plethJitter));
      }

      final y = bottomY - (pleth * bounds.height * 0.80);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _drawEtco2Capno(Canvas canvas, Rect bounds) {
    final labelColor = _isThermal ? const Color(0xFFB45309) : const Color(0xFFFFAB40);
    final traceColor = _isThermal ? const Color(0xFFB45309) : const Color(0xFFFFAB40);
    _drawChannelLabel(canvas, bounds, 'CAPNO EtCO₂', labelColor);

    final bottomY = bounds.bottom - 4.0;
    final cursorX = sweepProgress * bounds.width;
    const numSamples = 200;

    final paint = Paint()..color = traceColor..style = PaintingStyle.stroke..strokeWidth = _isThermal ? 1.6 : 1.5;
    Path? path;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * bounds.width;
      if (_inEraseGap(x, cursorX, bounds.width)) {
        if (path != null) { canvas.drawPath(path, paint); path = null; }
        continue;
      }
      final localPhase = ((x / bounds.width) * 2.0) % 1.0;
      double etco2 = CardiacHemodynamicEcgStrip.computeEtco2Sample(localPhase, rhythm, etco2MmHg);

      if (_isReal) {
        final cardiogenicOsc = (localPhase > 0.20 && localPhase < 0.45) ? 0.7 * math.sin(localPhase * 40.0) : 0.0;
        etco2 = math.max(0.0, etco2 + cardiogenicOsc);
      }

      final y = bottomY - (etco2 / 50.0) * (bounds.height * 0.80);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _drawChannelLabel(Canvas canvas, Rect bounds, String label, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, bounds.top + 3));
  }

  void _drawSweepBeam(Canvas canvas, Size size) {
    final cursorX = sweepProgress * size.width;
    final beamPaint = Paint()
      ..color = _isThermal
          ? const Color(0xFFD32F2F).withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = _isThermal ? 1.2 : 1.0;
    canvas.drawLine(Offset(cursorX, 0), Offset(cursorX, size.height), beamPaint);
  }

  bool _inEraseGap(double x, double cursorX, double totalW) {
    const gap = 20.0;
    if (cursorX + gap <= totalW) {
      return x >= cursorX && x <= cursorX + gap;
    } else {
      return x >= cursorX || x <= (cursorX + gap - totalW);
    }
  }

  @override
  bool shouldRepaint(covariant _FiveChannelHospitalOscilloscopePainter old) {
    return true;
  }
}
