// ============================================================================
// Live Hemodynamic & ECG Telemetry Strip — CardioCath 3D
// ----------------------------------------------------------------------------
// Real-time continuous Lead II ECG, Dual Aortic Pa (Red) & Distal Pd (Yellow)
// pressure waveforms rendered via mathematical CustomPainter.
// Synchronized to cardiac contraction cycle, BPM, STEMI ST-elevation,
// live FFR / iFR / WSS metrics, IABP counterpulsation, and catheter damping.
// Calibrated to 25 mm/s | 10 mm/mV standard Cath Lab telemetry grid with
// sweeping phosphor erase-bar, leading glowing dots, and QRS sync LED.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';
import 'cardiac_clinical_info_system.dart';

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
  ///
  /// Strict Electro-Mechanical Phase Lock (Wiggers Diagram):
  /// - phi = 0.270: Ventricular depolarization (R-wave peak).
  /// - phi in [0.270, 0.330]: Isovolumetric contraction -> Left ventricle generates
  ///   pressure against closed aortic valve. Pa remains at diastolic nadir (80 mmHg).
  /// - phi = 0.330: Aortic valve opens -> Steep systolic upstroke begins.
  /// - phi = 0.440: Peak systolic pressure (120 mmHg) during ventricular ejection.
  /// - phi = 0.560: Ventricular ejection ceases -> Pa drops to ~91 mmHg.
  /// - phi = 0.570: Dicrotic notch incisura (aortic valve closure) with rebound to 94 mmHg at 0.590.
  /// - phi > 0.600: Diastolic runoff exponential Windkessel decay returning to 80 mmHg.
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

  @override
  State<CardiacHemodynamicEcgStrip> createState() => _CardiacHemodynamicEcgStripState();
}

class _CardiacHemodynamicEcgStripState extends State<CardiacHemodynamicEcgStrip> {
  int _beatParity = 0;
  double _lastPhase = 0.0;

  @override
  void didUpdateWidget(covariant CardiacHemodynamicEcgStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect phase wrap-around (1.0 -> 0.0) to advance phosphor sweep beat parity
    if (widget.cardiacPhase < _lastPhase - 0.5) {
      _beatParity = (_beatParity + 1) % 2;
    }
    _lastPhase = widget.cardiacPhase;
  }

  double _computeEffectiveStElevation() {
    double baseSt;
    if (widget.scenario.id.contains('anterior_stemi')) {
      switch (widget.activeTerritory) {
        case EcgTerritoryLead.v1V4Anterior:
          baseSt = 4.5;
          break;
        case EcgTerritoryLead.inferiorLeads:
          baseSt = -2.0; // Reciprocal depression in inferior leads
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
          baseSt = -2.2; // Reciprocal depression in anterior leads
          break;
        case EcgTerritoryLead.lateralLeads:
          baseSt = -1.5; // Reciprocal depression in high lateral aVL
          break;
        case EcgTerritoryLead.leadII:
          baseSt = widget.scenario.stElevationMm;
          break;
      }
    } else {
      baseSt = widget.scenario.stElevationMm;
    }

    if (widget.isRevascularized) {
      return baseSt * 0.25; // 75% resolution post-revascularization
    }
    return baseSt;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    // Calculate dynamic hemodynamics
    final isShock = widget.complication == AcuteComplicationState.cardiogenicShock;
    final sys = isShock ? 75.0 : widget.scenario.systolicBp;
    final dia = isShock ? 48.0 : widget.scenario.diastolicBp;
    final map = dia + (sys - dia) / 3.0;
    final effectiveSt = _computeEffectiveStElevation();

    final isPressureWire = widget.wireType == InterventionalWireType.pressureWireX;
    final isDamped = widget.scenario.isCatheterDamped ||
        widget.complication == AcuteComplicationState.lmVentricularization ||
        (widget.catheterType == GuideCatheterType.al1 &&
            widget.scenario.id.contains('critical_lm'));

    // R-Wave QRS Electrical Depolarization Sync (phi in [0.255, 0.295])
    final isQrsActive = widget.cardiacPhase >= 0.255 && widget.cardiacPhase <= 0.295;

    // Continuous 2-beat phosphor sweep progress across the canvas width [0.0, 1.0]
    final sweepProgress = (_beatParity * 0.5) + (widget.cardiacPhase * 0.5);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF070B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // ── Top Telemetry Readout Strip ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1722),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.monitor_heart_rounded,
                        color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'CATH LAB TELEMETRY',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const CardiacInfoButton(
                      topicId: 'viewport_telemetry',
                      customLabel: 'Wiggers & ECG Info',
                      size: 12,
                    ),
                    const SizedBox(width: 12),

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
                    const SizedBox(width: 12),

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
                      const SizedBox(width: 4),
                      const CardiacInfoButton(
                        topicId: 'metric_wss',
                        size: 11,
                      ),
                    ],

                    if (widget.iabpActive) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF8B5CF6)),
                        ),
                        child: const Text(
                          'IABP 1:1 AUGMENTATION',
                          style: TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(width: 14),

                    // Heart Rate slider control
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pace:',
                            style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                        SizedBox(
                          width: 80,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 8),
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
                  ],
                ),
              ),
            ),

            // ── 12-Lead Territory Selection Bar ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFF0A0F16),
              child: Row(
                children: [
                  const Text(
                    '12-Lead Territory:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: EcgTerritoryLead.values.map((territory) {
                          final isSelected = territory == widget.activeTerritory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTerritoryChanged?.call(territory),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00E676).withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E676)
                                        : Colors.white12,
                                    width: isSelected ? 1.0 : 0.6,
                                  ),
                                ),
                                child: Text(
                                  territory.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF00E676)
                                        : Colors.white70,
                                    fontSize: 9,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
            ),

            // ── Dual Waveforms Canvas (ECG + Dual Pressure Pa/Pd) ───────────
            Expanded(
              child: CustomPaint(
                painter: _DualWaveformsPainter(
                  cardiacPhase: widget.cardiacPhase,
                  sweepProgress: sweepProgress,
                  stElevationMm: effectiveSt,
                  isDamped: isDamped,
                  systolicBp: sys,
                  diastolicBp: dia,
                  leadLabel: widget.activeTerritory.label,
                  wireType: widget.wireType,
                  iabpActive: widget.iabpActive,
                  ffrValue: widget.ffrValue,
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrsSyncIndicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF00E676).withValues(alpha: 0.25)
            : Colors.transparent,
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
              boxShadow: active
                  ? [
                      const BoxShadow(
                        color: Color(0xFF00E676),
                        blurRadius: 6,
                        spreadRadius: 1.5,
                      )
                    ]
                  : null,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter: Dual Oscilloscope (Lead II ECG + Pa/Pd Pressure Strip)
// ─────────────────────────────────────────────────────────────────────────────

class _DualWaveformsPainter extends CustomPainter {
  final double cardiacPhase;
  final double sweepProgress;
  final double stElevationMm;
  final bool isDamped;
  final double systolicBp;
  final double diastolicBp;
  final String leadLabel;
  final InterventionalWireType wireType;
  final bool iabpActive;
  final double? ffrValue;

  _DualWaveformsPainter({
    required this.cardiacPhase,
    required this.sweepProgress,
    required this.stElevationMm,
    required this.isDamped,
    required this.systolicBp,
    required this.diastolicBp,
    required this.leadLabel,
    required this.wireType,
    required this.iabpActive,
    this.ffrValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ecgBounds = Rect.fromLTWH(0, 0, size.width, size.height * 0.48);
    final bpBounds =
        Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.48);

    _drawTelemetryGrid(canvas, size);
    _drawEcgWaveform(canvas, ecgBounds);
    _drawArterialPressureWaveforms(canvas, bpBounds);
    _drawPhosphorSweepBeam(canvas, size);
  }

  /// Standard Cath Lab Telemetry Calibration Grid (25 mm/s | 10 mm/mV)
  /// - Minor grid: 1 mm spacing (~4 px), subtle salmon/red line
  /// - Major grid: 5 mm spacing (20 px = 5 minor boxes), bold accent
  void _drawTelemetryGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFFEF5350).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = const Color(0xFFEF5350).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double minorStep = 4.0;
    const double majorStep = 20.0;

    // Minor vertical lines
    for (double x = 0; x < size.width; x += minorStep) {
      if ((x % majorStep).abs() > 0.01) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
      }
    }
    // Major vertical lines
    for (double x = 0; x < size.width; x += majorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }

    // Minor horizontal lines
    for (double y = 0; y < size.height; y += minorStep) {
      if ((y % majorStep).abs() > 0.01) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
      }
    }
    // Major horizontal lines
    for (double y = 0; y < size.height; y += majorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }

    // Middle separator bar between ECG and Pressure
    final dividerPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height * 0.50),
        Offset(size.width, size.height * 0.50), dividerPaint);
  }

  void _drawEcgWaveform(Canvas canvas, Rect bounds) {
    final baselineY = bounds.top + bounds.height * 0.70;
    final sweepWidth = bounds.width;

    // Standard 1 mV Calibration Pulse on Far-Left Margin (10 mm vertical step = 36 px)
    _drawCalibrationPulse(canvas, bounds, baselineY);

    // Header Lead Label + Telemetry Calibration Badge
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'ECG $leadLabel  ',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 9.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '[25 mm/s | 10 mm/mV]',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, bounds.top + 4));

    // Continuous 2-beat waveform across width
    const int numSamples = 240;
    const double numBeats = 2.0;
    final cursorX = sweepProgress * sweepWidth;
    const double eraseGap = 24.0;

    final ecgPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;

    Path? currentPath;
    double? activeCursorY;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * sweepWidth;

      // Check if x is inside the CRT sweeping erase-head gap
      final inEraseGap = (cursorX + eraseGap <= sweepWidth)
          ? (x >= cursorX && x <= cursorX + eraseGap)
          : (x >= cursorX || x <= (cursorX + eraseGap) - sweepWidth);

      if (inEraseGap) {
        if (currentPath != null) {
          canvas.drawPath(currentPath, ecgPaint);
          currentPath = null;
        }
        continue;
      }

      final localPhase = ((x / sweepWidth) * numBeats) % 1.0;
      final ecgVal = CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(
          localPhase, stElevationMm);

      // 10 mm/mV scaling: 1.0 mV = 36 px deflection
      final y = baselineY - (ecgVal * 36.0);

      // Capture exact position of leading beam dot
      if ((x - cursorX).abs() < (sweepWidth / numSamples) * 1.2) {
        activeCursorY = y;
      }

      if (currentPath == null) {
        currentPath = Path()..moveTo(x, y);
      } else {
        currentPath.lineTo(x, y);
      }
    }

    if (currentPath != null) {
      canvas.drawPath(currentPath, ecgPaint);
    }

    // Glowing phosphor leading dot at sweep cursor
    final dotY = activeCursorY ??
        (baselineY -
            (CardiacHemodynamicEcgStrip.computeSyntheticEcgSample(
                    (cardiacPhase % 1.0), stElevationMm) *
                36.0));
    _drawGlowingDot(canvas, Offset(cursorX, dotY), const Color(0xFF00E676));
  }

  void _drawCalibrationPulse(Canvas canvas, Rect bounds, double baselineY) {
    const double pulseStartX = 10.0;
    const double pulseWidth = 12.0;
    const double pulseHeight = 36.0; // 1.0 mV = 36 px at 10 mm/mV

    final calPath = Path()
      ..moveTo(pulseStartX - 4.0, baselineY)
      ..lineTo(pulseStartX, baselineY)
      ..lineTo(pulseStartX, baselineY - pulseHeight)
      ..lineTo(pulseStartX + pulseWidth, baselineY - pulseHeight)
      ..lineTo(pulseStartX + pulseWidth, baselineY)
      ..lineTo(pulseStartX + pulseWidth + 4.0, baselineY);

    final calPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(calPath, calPaint);

    final calLabel = TextPainter(
      text: const TextSpan(
        text: '1mV',
        style: TextStyle(
          color: Color(0xFF00E676),
          fontSize: 7.5,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    calLabel.paint(canvas, Offset(pulseStartX + 1, baselineY - pulseHeight - 9));
  }

  void _drawArterialPressureWaveforms(Canvas canvas, Rect bounds) {
    final bottomY = bounds.bottom - 6.0;
    final sweepWidth = bounds.width;
    final isPressureWire = wireType == InterventionalWireType.pressureWireX;

    // Header label
    final labelSpan = TextSpan(
      children: [
        TextSpan(
          text: isDamped ? 'Ao (DAMPED / VENTRICULARIZED)' : 'Pa (AORTIC)',
          style: TextStyle(
            color: isDamped ? const Color(0xFFFF5252) : const Color(0xFFFF1744),
            fontSize: 9.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isPressureWire)
          const TextSpan(
            text: '  |  Pd (DISTAL WIRE)',
            style: TextStyle(
              color: Color(0xFFFFEB3B),
              fontSize: 9.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        if (iabpActive)
          const TextSpan(
            text: '  [IABP 1:1 AUGMENTED]',
            style: TextStyle(
              color: Color(0xFFA78BFA),
              fontSize: 9.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );

    final textPainter = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, bounds.top + 4));

    const int numSamples = 240;
    const double numBeats = 2.0;
    final cursorX = sweepProgress * sweepWidth;
    const double eraseGap = 24.0;

    final paPaint = Paint()
      ..color = isDamped ? const Color(0xFFFF5252) : const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;

    final pdPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;

    Path? currentPaPath;
    Path? currentPdPath;
    double? activePaCursorY;
    double? activePdCursorY;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * sweepWidth;

      // Check CRT erase-head gap
      final inEraseGap = (cursorX + eraseGap <= sweepWidth)
          ? (x >= cursorX && x <= cursorX + eraseGap)
          : (x >= cursorX || x <= (cursorX + eraseGap) - sweepWidth);

      if (inEraseGap) {
        if (currentPaPath != null) {
          canvas.drawPath(currentPaPath, paPaint);
          currentPaPath = null;
        }
        if (currentPdPath != null) {
          canvas.drawPath(currentPdPath, pdPaint);
          currentPdPath = null;
        }
        continue;
      }

      final localPhase = ((x / sweepWidth) * numBeats) % 1.0;
      final pa = CardiacHemodynamicEcgStrip.computeAorticPressure(
        localPhase,
        isDamped,
        iabpActive,
        systolicBp: systolicBp,
        diastolicBp: diastolicBp,
      );

      // Scale: 30 mmHg nadir to 160 mmHg ceiling mapped to height * 0.82
      final yPa = bottomY - ((pa - 30.0) / 130.0) * (bounds.height * 0.82);

      if ((x - cursorX).abs() < (sweepWidth / numSamples) * 1.2) {
        activePaCursorY = yPa;
      }

      if (currentPaPath == null) {
        currentPaPath = Path()..moveTo(x, yPa);
      } else {
        currentPaPath.lineTo(x, yPa);
      }

      if (isPressureWire) {
        // Distal Pd trans-stenotic pressure drop
        final drop = (ffrValue != null) ? (1.0 - ffrValue!) * 40.0 : 25.0;
        final pd = math.max(pa - drop, 15.0);
        final yPd = bottomY - ((pd - 30.0) / 130.0) * (bounds.height * 0.82);

        if ((x - cursorX).abs() < (sweepWidth / numSamples) * 1.2) {
          activePdCursorY = yPd;
        }

        if (currentPdPath == null) {
          currentPdPath = Path()..moveTo(x, yPd);
        } else {
          currentPdPath.lineTo(x, yPd);
        }
      }
    }

    if (currentPaPath != null) {
      canvas.drawPath(currentPaPath, paPaint);
    }
    if (currentPdPath != null) {
      canvas.drawPath(currentPdPath, pdPaint);
    }

    // Glowing phosphor leading dots
    final dotPaY = activePaCursorY ??
        (bottomY -
            ((CardiacHemodynamicEcgStrip.computeAorticPressure(
                            (cardiacPhase % 1.0), isDamped, iabpActive,
                            systolicBp: systolicBp, diastolicBp: diastolicBp) -
                        30.0) /
                    130.0) *
                (bounds.height * 0.82));
    _drawGlowingDot(canvas, Offset(cursorX, dotPaY),
        isDamped ? const Color(0xFFFF5252) : const Color(0xFFFF1744));

    if (isPressureWire) {
      final drop = (ffrValue != null) ? (1.0 - ffrValue!) * 40.0 : 25.0;
      final curPa = CardiacHemodynamicEcgStrip.computeAorticPressure(
          (cardiacPhase % 1.0), isDamped, iabpActive,
          systolicBp: systolicBp, diastolicBp: diastolicBp);
      final curPd = math.max(curPa - drop, 15.0);
      final dotPdY = activePdCursorY ??
          (bottomY - ((curPd - 30.0) / 130.0) * (bounds.height * 0.82));
      _drawGlowingDot(canvas, Offset(cursorX, dotPdY), const Color(0xFFFFEB3B));
    }
  }

  /// Sweeping vertical phosphor bar across the monitor strip
  void _drawPhosphorSweepBeam(Canvas canvas, Size size) {
    final cursorX = sweepProgress * size.width;
    final beamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(cursorX, 0), Offset(cursorX, size.height), beamPaint);
  }

  void _drawGlowingDot(Canvas canvas, Offset center, Color color) {
    // Outer halo glow
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.5, haloPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, corePaint);

    // Color fringe
    final fringePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.2, fringePaint);
  }

  @override
  bool shouldRepaint(covariant _DualWaveformsPainter old) {
    return old.cardiacPhase != cardiacPhase ||
        old.sweepProgress != sweepProgress ||
        old.stElevationMm != stElevationMm ||
        old.isDamped != isDamped ||
        old.systolicBp != systolicBp ||
        old.diastolicBp != diastolicBp ||
        old.leadLabel != leadLabel ||
        old.wireType != wireType ||
        old.iabpActive != iabpActive ||
        old.ffrValue != ffrValue;
  }
}
