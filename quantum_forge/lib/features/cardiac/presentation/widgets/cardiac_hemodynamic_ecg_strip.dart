// ============================================================================
// Live Hemodynamic & ECG Telemetry Strip — CardioCath 3D
// ----------------------------------------------------------------------------
// Real-time continuous Lead II ECG, Dual Aortic Pa (Red) & Distal Pd (Yellow)
// pressure waveforms rendered via mathematical CustomPainter.
// Synchronized to cardiac contraction cycle, BPM, STEMI ST-elevation,
// live FFR / iFR / WSS metrics, IABP counterpulsation, and catheter damping.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';

class CardiacHemodynamicEcgStrip extends StatelessWidget {
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

  double _computeEffectiveStElevation() {
    double baseSt;
    if (scenario.id.contains('anterior_stemi')) {
      switch (activeTerritory) {
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
          baseSt = scenario.stElevationMm;
          break;
      }
    } else if (scenario.id.contains('inferior_mi')) {
      switch (activeTerritory) {
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
          baseSt = scenario.stElevationMm;
          break;
      }
    } else {
      baseSt = scenario.stElevationMm;
    }

    if (isRevascularized) {
      return baseSt * 0.25; // 75% resolution post-revascularization
    }
    return baseSt;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    // Calculate dynamic hemodynamics
    final isShock = complication == AcuteComplicationState.cardiogenicShock;
    final sys = isShock ? 75.0 : scenario.systolicBp;
    final dia = isShock ? 48.0 : scenario.diastolicBp;
    final map = dia + (sys - dia) / 3.0;
    final effectiveSt = _computeEffectiveStElevation();

    final isPressureWire = wireType == InterventionalWireType.pressureWireX;
    final isDamped = scenario.isCatheterDamped ||
        complication == AcuteComplicationState.lmVentricularization ||
        (catheterType == GuideCatheterType.al1 && scenario.id.contains('critical_lm'));

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
                    const SizedBox(width: 12),
                    _vitalsBadge(
                      label: 'HR',
                      value: '${bpm.round()} bpm',
                      color: bpm < 60
                          ? const Color(0xFFFFB300)
                          : (bpm > 100
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF00E676)),
                    ),
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
                      label: 'ST (${activeTerritory.shortLabel})',
                      value: '${effectiveSt >= 0 ? "+" : ""}${effectiveSt.toStringAsFixed(1)} mm',
                      color: effectiveSt.abs() > 1.0
                          ? (effectiveSt > 0 ? const Color(0xFFFF1744) : const Color(0xFF38BDF8))
                          : const Color(0xFF00E676),
                    ),

                    // Pressure Wire Metrics (FFR & iFR)
                    if (isPressureWire && ffrValue != null) ...[
                      const SizedBox(width: 10),
                      _vitalsBadge(
                        label: 'FFR (Pd/Pa)',
                        value: ffrValue!.toStringAsFixed(2),
                        color: ffrValue! <= 0.80
                            ? const Color(0xFFFF1744)
                            : const Color(0xFF00E676),
                      ),
                    ],

                    if (isPressureWire && ifrValue != null) ...[
                      const SizedBox(width: 10),
                      _vitalsBadge(
                        label: 'iFR (WFP)',
                        value: ifrValue!.toStringAsFixed(2),
                        color: ifrValue! <= 0.89
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF00E676),
                      ),
                    ],

                    if (wssDynes != null) ...[
                      const SizedBox(width: 10),
                      _vitalsBadge(
                        label: 'WSS',
                        value: '${wssDynes!.toStringAsFixed(0)} dyn/cm²',
                        color: wssDynes! > 70.0
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF38BDF8),
                      ),
                    ],

                    if (iabpActive) ...[
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
                              value: bpm,
                              min: 45.0,
                              max: 130.0,
                              onChanged: onBpmChanged,
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
                          final isSelected = territory == activeTerritory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTerritoryChanged?.call(territory),
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
                  cardiacPhase: cardiacPhase,
                  stElevationMm: effectiveSt,
                  isDamped: isDamped,
                  systolicBp: sys,
                  diastolicBp: dia,
                  leadLabel: activeTerritory.label,
                  wireType: wireType,
                  iabpActive: iabpActive,
                  ffrValue: ffrValue,
                ),
                child: Container(),
              ),
            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter: Dual Oscilloscope (Lead II ECG + Pa/Pd Pressure Strip)
// ─────────────────────────────────────────────────────────────────────────────

class _DualWaveformsPainter extends CustomPainter {
  final double cardiacPhase;
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

    _drawOscilloscopeGrid(canvas, size);
    _drawEcgWaveform(canvas, ecgBounds);
    _drawArterialPressureWaveforms(canvas, bpBounds);
  }

  void _drawOscilloscopeGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dividerPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height * 0.50),
        Offset(size.width, size.height * 0.50), dividerPaint);
  }

  void _drawEcgWaveform(Canvas canvas, Rect bounds) {
    final baselineY = bounds.top + bounds.height * 0.65;
    final sweepWidth = bounds.width;

    // Lead Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ECG $leadLabel',
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 9.5,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, bounds.top + 4));

    final path = Path();
    const int numSamples = 200;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * sweepWidth;
      final localPhase = ((i / numSamples) * 2.5 + cardiacPhase) % 1.0;

      final ecgVal = _computeSyntheticEcgSample(localPhase, stElevationMm);
      final y = baselineY - ecgVal * 14.0;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final ecgPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    canvas.drawPath(path, ecgPaint);
  }

  double _computeSyntheticEcgSample(double phase, double stElevation) {
    double v = 0.0;
    if (phase >= 0.10 && phase <= 0.20) {
      v += 0.20 * math.sin((phase - 0.10) / 0.10 * math.pi);
    } else if (phase > 0.24 && phase <= 0.26) {
      v -= 0.18 * math.sin((phase - 0.24) / 0.02 * math.pi);
    } else if (phase > 0.26 && phase <= 0.30) {
      v += 1.60 * math.sin((phase - 0.26) / 0.04 * math.pi);
    } else if (phase > 0.30 && phase <= 0.33) {
      v -= 0.35 * math.sin((phase - 0.30) / 0.03 * math.pi);
    } else if (phase > 0.33 && phase <= 0.65) {
      final stOffset = (stElevation / 10.0);
      final tWave = 0.38 * math.sin((phase - 0.38) / 0.27 * math.pi);
      v += (stOffset * 0.75) + (phase > 0.40 ? tWave : 0.0);
    }
    return v;
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

    // Aortic Pa (Red)
    final paPath = Path();
    final pdPath = Path();
    const int numSamples = 200;

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * sweepWidth;
      final localPhase = ((i / numSamples) * 2.5 + cardiacPhase) % 1.0;

      final pa = _computeAorticPressure(localPhase, isDamped, iabpActive);
      final yPa = bottomY - (pa / 160.0) * (bounds.height * 0.85);

      if (i == 0) {
        paPath.moveTo(x, yPa);
      } else {
        paPath.lineTo(x, yPa);
      }

      if (isPressureWire) {
        // Distal Pd has trans-stenotic pressure drop
        final drop = (ffrValue != null) ? (1.0 - ffrValue!) * 40.0 : 25.0;
        final pd = math.max(pa - drop, 15.0);
        final yPd = bottomY - (pd / 160.0) * (bounds.height * 0.85);

        if (i == 0) {
          pdPath.moveTo(x, yPd);
        } else {
          pdPath.lineTo(x, yPd);
        }
      }
    }

    // Paint Pa (Red)
    final paPaint = Paint()
      ..color = isDamped ? const Color(0xFFFF5252) : const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    canvas.drawPath(paPath, paPaint);

    // Paint Pd (Yellow)
    if (isPressureWire) {
      final pdPaint = Paint()
        ..color = const Color(0xFFFFEB3B)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6;
      canvas.drawPath(pdPath, pdPaint);
    }
  }

  double _computeAorticPressure(double phase, bool damped, bool iabp) {
    if (damped) {
      if (phase >= 0.28 && phase <= 0.50) {
        return 35.0 + 50.0 * math.sin((phase - 0.28) / 0.22 * math.pi);
      }
      return 35.0;
    }

    double p;
    if (phase >= 0.26 && phase <= 0.44) {
      final sFraction = (phase - 0.26) / 0.18;
      p = diastolicBp + (systolicBp - diastolicBp) * math.sin(sFraction * math.pi);
    } else if (phase > 0.44 && phase <= 0.52) {
      final nFraction = (phase - 0.44) / 0.08;
      p = 92.0 + 8.0 * math.cos(nFraction * math.pi * 2);
    } else {
      final dFraction = (phase > 0.52 ? (phase - 0.52) / 0.74 : (phase + 0.48) / 0.74);
      p = 92.0 - (92.0 - diastolicBp) * math.pow(dFraction, 0.7);
    }

    if (iabp) {
      if (phase >= 0.35 && phase <= 0.88) {
        final tau = (phase - 0.35) / 0.53;
        p += 36.0 * math.sin(tau * math.pi); // Diastolic augmentation wave
      } else if (phase > 0.88) {
        p -= 10.0;
      }
    }

    return p;
  }

  @override
  bool shouldRepaint(covariant _DualWaveformsPainter old) {
    return old.cardiacPhase != cardiacPhase ||
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
