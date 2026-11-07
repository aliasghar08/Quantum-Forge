// ============================================================================
// Live Hemodynamic & ECG Telemetry Strip — CardioCath 3D
// ----------------------------------------------------------------------------
// Real-time continuous Lead II ECG and Aortic Arterial Pressure (P_ao)
// waveforms rendered via mathematical CustomPainter.
// Synchronized to cardiac contraction cycle, BPM, STEMI ST-elevation,
// and catheter pressure damping / ventricularization.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';

class CardiacHemodynamicEcgStrip extends StatelessWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase; // 0.0 to 1.0 (repeating cycle)
  final double bpm;
  final ValueChanged<double> onBpmChanged;
  final EcgTerritoryLead activeTerritory;
  final ValueChanged<EcgTerritoryLead>? onTerritoryChanged;
  final bool isRevascularized;

  const CardiacHemodynamicEcgStrip({
    super.key,
    required this.scenario,
    required this.cardiacPhase,
    required this.bpm,
    required this.onBpmChanged,
    this.activeTerritory = EcgTerritoryLead.leadII,
    this.onTerritoryChanged,
    this.isRevascularized = false,
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
    final sys = scenario.systolicBp;
    final dia = scenario.diastolicBp;
    final map = dia + (sys - dia) / 3.0;
    final effectiveSt = _computeEffectiveStElevation();

    return Container(
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
                    const SizedBox(width: 8),
                    _vitalsBadge(
                      label: 'Ao BP',
                      value: '${sys.round()}/${dia.round()} mmHg',
                      color: scenario.isCatheterDamped
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    _vitalsBadge(
                      label: 'MAP',
                      value: '${map.round()} mmHg',
                      color: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    _vitalsBadge(
                      label: 'ST (${activeTerritory.shortLabel})',
                      value: effectiveSt > 0
                          ? '+${effectiveSt.toStringAsFixed(1)} mm'
                          : (effectiveSt < 0
                              ? '${effectiveSt.toStringAsFixed(1)} mm'
                              : '0.0 mm'),
                      color: effectiveSt.abs() > 1.0
                          ? const Color(0xFFFF1744)
                          : const Color(0xFF00E676),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pace:',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4.5),
                        ),
                        child: Slider(
                          value: bpm,
                          min: 45.0,
                          max: 130.0,
                          activeColor: const Color(0xFF00E676),
                          inactiveColor: Colors.white12,
                          onChanged: onBpmChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ECG Multi-Lead Territory Selector Bar ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFF090D14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      '12-Lead Territory: ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...EcgTerritoryLead.values.map((t) {
                      final isSelected = t == activeTerritory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: onTerritoryChanged == null
                              ? null
                              : () => onTerritoryChanged!(t),
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00E676).withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E676)
                                    : Colors.white12,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              t.label,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF00E676)
                                    : Colors.white70,
                                fontSize: 9.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Dual Waveforms Canvas (ECG + Aortic Pressure) ───────────────
            SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(
                painter: _DualWaveformsPainter(
                  cardiacPhase: cardiacPhase,
                  stElevationMm: effectiveSt,
                  isDamped: scenario.isCatheterDamped,
                  systolicBp: sys,
                  diastolicBp: dia,
                  leadLabel: activeTerritory.label,
                ),
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mathematical Waveform Painter for ECG & Aortic Pressure
// ─────────────────────────────────────────────────────────────────────────────

class _DualWaveformsPainter extends CustomPainter {
  final double cardiacPhase;
  final double stElevationMm;
  final bool isDamped;
  final double systolicBp;
  final double diastolicBp;
  final String leadLabel;

  _DualWaveformsPainter({
    required this.cardiacPhase,
    required this.stElevationMm,
    required this.isDamped,
    required this.systolicBp,
    required this.diastolicBp,
    this.leadLabel = 'Lead II',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background ECG paper grid
    _drawMedicalGrid(canvas, size);

    final halfHeight = size.height / 2.0;

    // 1. Render Lead II ECG Waveform (Top Half)
    _drawEcgWaveform(canvas, Rect.fromLTWH(0, 0, size.width, halfHeight));

    // 2. Render Aortic Arterial Pressure Waveform (Bottom Half)
    _drawAorticPressureWaveform(
        canvas, Rect.fromLTWH(0, halfHeight, size.width, halfHeight));
  }

  void _drawMedicalGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const step = 15.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawEcgWaveform(Canvas canvas, Rect bounds) {
    final baselineY = bounds.top + bounds.height * 0.58;
    final sweepWidth = bounds.width;

    // Active Lead / Territory label
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
      // Phase along strip with 2.5 cardiac cycles visible
      final localPhase =
          ((i / numSamples) * 2.5 + cardiacPhase) % 1.0;

      final ecgVal = _computeSyntheticEcgSample(localPhase, stElevationMm);
      // Scale: 1 mV = ~14 px
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
    // Normal ECG sequence: P wave (0.15), PR segment (0.22), QRS complex (0.28),
    // ST segment (0.35 - 0.45), T wave (0.55 - 0.70)
    double v = 0.0;

    // P wave (atrium depolarizes)
    if (phase >= 0.10 && phase <= 0.20) {
      v += 0.20 * math.sin((phase - 0.10) / 0.10 * math.pi);
    }
    // Q wave (septal depolarization)
    else if (phase > 0.24 && phase <= 0.26) {
      v -= 0.18 * math.sin((phase - 0.24) / 0.02 * math.pi);
    }
    // R wave (ventricular apex)
    else if (phase > 0.26 && phase <= 0.30) {
      v += 1.60 * math.sin((phase - 0.26) / 0.04 * math.pi);
    }
    // S wave (ventricular base)
    else if (phase > 0.30 && phase <= 0.33) {
      v -= 0.35 * math.sin((phase - 0.30) / 0.03 * math.pi);
    }
    // ST Segment & T wave
    else if (phase > 0.33 && phase <= 0.65) {
      // In STEMI, baseline is elevated above isoelectric line
      final stOffset = (stElevation / 10.0); // mm to mV approx
      final tWave = 0.38 * math.sin((phase - 0.38) / 0.27 * math.pi);
      v += (stOffset * 0.75) + (phase > 0.40 ? tWave : 0.0);
    }

    return v;
  }

  void _drawAorticPressureWaveform(Canvas canvas, Rect bounds) {
    final bottomY = bounds.bottom - 6.0;
    final sweepWidth = bounds.width;

    // Aortic Pressure label
    final textPainter = TextPainter(
      text: TextSpan(
        text: isDamped ? 'Ao (DAMPED / VENTRICULARIZED)' : 'Ao PRESSURE (mmHg)',
        style: TextStyle(
          color: isDamped ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
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
      final localPhase =
          ((i / numSamples) * 2.5 + cardiacPhase) % 1.0;

      final p = _computeAorticPressureSample(localPhase, isDamped);
      // Map 0 - 150 mmHg to pixel height
      final y = bottomY - (p / 160.0) * (bounds.height * 0.85);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final bpPaint = Paint()
      ..color = isDamped ? const Color(0xFFFF5252) : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    canvas.drawPath(path, bpPaint);
  }

  double _computeAorticPressureSample(double phase, bool damped) {
    if (damped) {
      // Damped / Ventricularized waveform:
      // Sharp systolic spike decaying immediately to zero (loses dicrotic notch)
      if (phase >= 0.28 && phase <= 0.50) {
        return 35.0 + 50.0 * math.sin((phase - 0.28) / 0.22 * math.pi);
      }
      return 35.0; // Flat bottomed
    }

    // Normal Aortic Pressure Waveform:
    // Rapid systolic upstroke, peak at 120 mmHg, dicrotic notch at ~95 mmHg, diastolic runoff to 80 mmHg
    if (phase >= 0.26 && phase <= 0.44) {
      // Systolic ejection upstroke
      final sFraction = (phase - 0.26) / 0.18;
      return diastolicBp + (systolicBp - diastolicBp) * math.sin(sFraction * math.pi);
    } else if (phase > 0.44 && phase <= 0.52) {
      // Dicrotic notch reflection (aortic valve closure incisura)
      final nFraction = (phase - 0.44) / 0.08;
      return 92.0 + 8.0 * math.cos(nFraction * math.pi * 2);
    } else {
      // Gradual diastolic runoff
      final dFraction = (phase > 0.52 ? (phase - 0.52) / 0.74 : (phase + 0.48) / 0.74);
      return 92.0 - (92.0 - diastolicBp) * math.pow(dFraction, 0.7);
    }
  }

  @override
  bool shouldRepaint(covariant _DualWaveformsPainter old) {
    return old.cardiacPhase != cardiacPhase ||
        old.stElevationMm != stElevationMm ||
        old.isDamped != isDamped ||
        old.systolicBp != systolicBp ||
        old.diastolicBp != diastolicBp ||
        old.leadLabel != leadLabel;
  }
}

