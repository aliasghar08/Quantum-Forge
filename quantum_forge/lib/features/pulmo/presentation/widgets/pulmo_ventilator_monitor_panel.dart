// ============================================================================
// PulmoVent 3D: ICU Mechanical Ventilator Monitor & Respiratory Loops Panel
// ----------------------------------------------------------------------------
// 1. Hospital-Grade 3-Channel CRT Sweep:
//    - Airway Pressure (Paw, cmH2O): Ppeak, Pplat, PEEP, and hold plateaus.
//    - Airway Flow (Vdot, L/min): Inspiratory ramp vs expiratory scooping.
//    - Tidal Volume (Vt, mL): Dynamic inflation and passive recoil.
// 2. Interactive Hold Maneuvers:
//    - Inspiratory Hold (determines Pplat and Driving Pressure ΔP).
//    - Expiratory Hold (determines intrinsic Auto-PEEP).
// 3. Side-by-Side Loops:
//    - Pressure-Volume (P-V) Loop: Lower Inflection Point (LIP), UIP "beaking", compliance.
//    - Flow-Volume Loop: Obstructive expiratory limitation vs normal hysteresis.
// 4. Ventilator Mode Selection (VC-AC, PC-AC, PRVC, PSV) and Titration Sliders.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

class PulmoVentilatorMonitorPanel extends StatefulWidget {
  final PulmoMasterVitalsState vitals;

  const PulmoVentilatorMonitorPanel({
    super.key,
    required this.vitals,
  });

  @override
  State<PulmoVentilatorMonitorPanel> createState() =>
      _PulmoVentilatorMonitorPanelState();
}

class _PulmoVentilatorMonitorPanelState
    extends State<PulmoVentilatorMonitorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  bool _showLoops = false;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vitals;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Ventilator Status & Mode Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monitor_heart_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'ICU VENTILATOR • ${v.ventMode.code}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Mechanics Badges
                _statBadge('Ppeak', '${v.peakPressureCmH2o.round()}', 'cmH₂O',
                    v.peakPressureCmH2o > 35 ? const Color(0xFFFF1744) : const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                _statBadge('Pplat', '${v.plateauPressureCmH2o.round()}', 'cmH₂O',
                    v.plateauPressureCmH2o > 30 ? const Color(0xFFFF1744) : const Color(0xFF00E676)),
                const SizedBox(width: 6),
                _statBadge('ΔP', '${v.drivingPressureCmH2o.round()}', 'cmH₂O',
                    v.drivingPressureCmH2o > 15 ? const Color(0xFFFF5252) : const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                _statBadge('Cstat', '${v.staticComplianceMlCmH2o.round()}', 'mL/cmH₂O',
                    v.staticComplianceMlCmH2o < 25 ? const Color(0xFFFF9100) : const Color(0xFF10B981)),

                const SizedBox(width: 12),

                // Toggle Waveform vs Loops
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('CRT Sweep', style: TextStyle(fontSize: 10))),
                    ButtonSegment(value: true, label: Text('P-V / F-V Loops', style: TextStyle(fontSize: 10))),
                  ],
                  selected: {_showLoops},
                  onSelectionChanged: (set) => setState(() => _showLoops = set.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Oscilloscope CRT Sweep or P-V / F-V Loops Display Area
          Expanded(
            child: _showLoops
                ? _buildLoopsView(v)
                : _buildCrtSweepView(v),
          ),
          const SizedBox(height: 8),

          // 3. Interactive Holds & Ventilator Machine Setting Sliders
          _buildVentilatorControls(v),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 9, color: Colors.white60)),
          Text(value, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 2),
          Text(unit, style: const TextStyle(fontSize: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildCrtSweepView(PulmoMasterVitalsState v) {
    return AnimatedBuilder(
      animation: _sweepCtrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _VentilatorCrtSweepPainter(
            vitals: v,
            sweepProgress: _sweepCtrl.value,
          ),
        );
      },
    );
  }

  Widget _buildLoopsView(PulmoMasterVitalsState v) {
    return Row(
      children: [
        // Pressure-Volume Loop
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRESSURE–VOLUME (P–V) COMPLIANCE LOOP',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PvLoopPainter(vitals: v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Flow-Volume Loop
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FLOW–VOLUME (F–V) HYSTERESIS LOOP',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FvLoopPainter(vitals: v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVentilatorControls(PulmoMasterVitalsState v) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hold Maneuvers & Mode Switcher
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Inspiratory Hold Button
                OutlinedButton.icon(
                  key: const Key('vent_insp_hold_btn'),
                  icon: Icon(
                    v.isInspiratoryHoldActive ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                    size: 14,
                    color: const Color(0xFF00E5FF),
                  ),
                  label: Text(
                    v.isInspiratoryHoldActive ? 'Insp Hold (Active)' : 'Insp Hold (Pplat)',
                    style: const TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: v.toggleInspiratoryHold,
                ),
                const SizedBox(width: 8),

                // Expiratory Hold Button
                OutlinedButton.icon(
                  key: const Key('vent_exp_hold_btn'),
                  icon: Icon(
                    v.isExpiratoryHoldActive ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                    size: 14,
                    color: const Color(0xFFFFB300),
                  ),
                  label: Text(
                    v.isExpiratoryHoldActive ? 'Exp Hold (Active)' : 'Exp Hold (Auto-PEEP)',
                    style: const TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFB300)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: v.toggleExpiratoryHold,
                ),
                const SizedBox(width: 12),

                // Mode chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: VentilatorMode.values.map((m) {
                    final isSel = v.ventMode == m;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(m.code, style: const TextStyle(fontSize: 10)),
                        selected: isSel,
                        selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF0B132B),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF00E5FF) : Colors.white60,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF1E293B)),
                        onSelected: (_) => v.setVentilatorSettings(mode: m),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Machine Sliders: Vt, RR, PEEP, FiO2
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sliderWidget('Vt: ${v.tidalVolumeMl.round()} mL (${v.tidalVolumePerKgIbw.toStringAsFixed(1)} mL/kg)',
                    v.tidalVolumeMl, 250, 750, (val) => v.setVentilatorSettings(tidalVolumeMl: val)),
                const SizedBox(width: 12),
                _sliderWidget('Set RR: ${v.setRespRate} /min',
                    v.setRespRate.toDouble(), 8, 36, (val) => v.setVentilatorSettings(setRespRate: val.round())),
                const SizedBox(width: 12),
                _sliderWidget('PEEP: ${v.peepCmH2o.round()} cmH₂O',
                    v.peepCmH2o, 0, 24, (val) => v.setVentilatorSettings(peepCmH2o: val)),
                const SizedBox(width: 12),
                _sliderWidget('FiO₂: ${v.fio2Pct.round()}%',
                    v.fio2Pct, 21, 100, (val) => v.setVentilatorSettings(fio2Pct: val)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderWidget(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
        SizedBox(
          width: 90,
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Real-time 3-channel CRT Sweep Painter (Paw, Vdot, Vt)
class _VentilatorCrtSweepPainter extends CustomPainter {
  final PulmoMasterVitalsState vitals;
  final double sweepProgress;

  _VentilatorCrtSweepPainter({
    required this.vitals,
    required this.sweepProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final channelH = h / 3.0;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(0, i * channelH), Offset(w, i * channelH), gridPaint);
    }

    final sweepX = sweepProgress * w;
    final sweepCursor = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(sweepX, 0), Offset(sweepX, h), sweepCursor);

    // Channel 1: Airway Pressure (Paw, cmH2O) - Yellow/Cyan
    _drawPawChannel(canvas, 0, channelH, w, sweepX);

    // Channel 2: Airway Flow (Vdot, L/min) - Emerald Green
    _drawFlowChannel(canvas, channelH, channelH * 2, w, sweepX);

    // Channel 3: Tidal Volume (Vt, mL) - Amber
    _drawVolumeChannel(canvas, channelH * 2, h, w, sweepX);
  }

  void _drawPawChannel(Canvas canvas, double top, double bot, double w, double sweepX) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Paw (cmH₂O)',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, top + 4));

    final pPath = Path();
    final pPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final baselineY = bot - 8;
    final ppeak = vitals.peakPressureCmH2o;
    final pplatt = vitals.plateauPressureCmH2o;
    final peep = vitals.peepCmH2o;

    final scaleY = (bot - top - 24) / 60.0; // up to 60 cmH2O

    for (double x = 0; x < w; x += 3) {
      if ((x - sweepX).abs() < 6) continue;
      final cycleT = (x / (w / 3.0)) % 1.0; // 3 breaths across screen

      double pVal;
      if (vitals.isInspiratoryHoldActive && cycleT > 0.3 && cycleT < 0.6) {
        pVal = pplatt;
      } else if (cycleT < 0.35) {
        // Inspiratory ramp up to Ppeak
        pVal = peep + (cycleT / 0.35) * (ppeak - peep);
      } else if (cycleT < 0.45) {
        // Quick drop to Pplat
        pVal = pplatt;
      } else {
        // Expiratory drop to PEEP
        final expT = (cycleT - 0.45) / 0.55;
        pVal = peep + (pplatt - peep) * math.exp(-expT * 5);
      }

      final y = baselineY - (pVal * scaleY);
      if (x == 0) {
        pPath.moveTo(x, y);
      } else {
        pPath.lineTo(x, y);
      }
    }
    canvas.drawPath(pPath, pPaint);
  }

  void _drawFlowChannel(Canvas canvas, double top, double bot, double w, double sweepX) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flow (L/min)',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, top + 4));

    final fPath = Path();
    final fPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final zeroY = top + (bot - top) / 2.0;

    for (double x = 0; x < w; x += 3) {
      if ((x - sweepX).abs() < 6) continue;
      final cycleT = (x / (w / 3.0)) % 1.0;

      double fVal;
      if (cycleT < 0.35) {
        // Inspiratory square / decelerating wave
        fVal = 50.0 * (1.0 - cycleT * 0.5);
      } else if (cycleT < 0.85) {
        // Expiratory negative flow with scooping if obstructive
        final expT = (cycleT - 0.35) / 0.5;
        final scooping = vitals.isSevereBronchospasm ? 1.5 : 4.0;
        fVal = -60.0 * math.exp(-expT * scooping);
      } else {
        fVal = 0.0;
      }

      final y = zeroY - (fVal * 0.45);
      if (x == 0) {
        fPath.moveTo(x, y);
      } else {
        fPath.lineTo(x, y);
      }
    }
    canvas.drawPath(fPath, fPaint);
  }

  void _drawVolumeChannel(Canvas canvas, double top, double bot, double w, double sweepX) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Volume (mL)',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(8, top + 4));

    final vPath = Path();
    final vPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final baseY = bot - 8;
    final maxVol = vitals.tidalVolumeMl;
    final scaleY = (bot - top - 24) / 750.0;

    for (double x = 0; x < w; x += 3) {
      if ((x - sweepX).abs() < 6) continue;
      final cycleT = (x / (w / 3.0)) % 1.0;

      double volVal;
      if (cycleT < 0.35) {
        // Volume accumulating
        volVal = maxVol * (cycleT / 0.35);
      } else {
        // Volume expiring
        final expT = (cycleT - 0.35) / 0.65;
        volVal = maxVol * math.exp(-expT * 4);
      }

      final y = baseY - (volVal * scaleY);
      if (x == 0) {
        vPath.moveTo(x, y);
      } else {
        vPath.lineTo(x, y);
      }
    }
    canvas.drawPath(vPath, vPaint);
  }

  @override
  bool shouldRepaint(covariant _VentilatorCrtSweepPainter old) => true;
}

/// Pressure-Volume (P-V) Compliance Loop CustomPainter
class _PvLoopPainter extends CustomPainter {
  final PulmoMasterVitalsState vitals;

  _PvLoopPainter({required this.vitals});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 1.0;
    canvas.drawLine(Offset(30, h - 20), Offset(w - 10, h - 20), axisPaint); // P axis
    canvas.drawLine(Offset(30, h - 20), Offset(30, 10), axisPaint);        // V axis

    // P-V Hysteresis Loop
    final loopPath = Path();
    final loopPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final p0 = Offset(30 + (vitals.peepCmH2o * 4), h - 20);
    final pLIP = Offset(30 + (10 * 4), h - 20 - 50); // Lower Inflection Point
    final pUIP = Offset(30 + (vitals.plateauPressureCmH2o * 4), h - 20 - (vitals.tidalVolumeMl * 0.18)); // UIP

    // Inspiratory limb (sigmoid)
    loopPath.moveTo(p0.dx, p0.dy);
    loopPath.quadraticBezierTo(pLIP.dx, pLIP.dy, pUIP.dx, pUIP.dy);

    // Beaking / Overdistension if Pplat > 30
    if (vitals.plateauPressureCmH2o > 30.0) {
      final beakEnd = Offset(pUIP.dx + 25, pUIP.dy - 5);
      loopPath.lineTo(beakEnd.dx, beakEnd.dy);
      loopPath.lineTo(pUIP.dx, pUIP.dy);
    }

    // Expiratory limb (higher volume at same pressure)
    loopPath.quadraticBezierTo(p0.dx + 15, p0.dy - 70, p0.dx, p0.dy);
    canvas.drawPath(loopPath, loopPaint);
  }

  @override
  bool shouldRepaint(covariant _PvLoopPainter old) => true;
}

/// Flow-Volume (F-V) Hysteresis Loop CustomPainter
class _FvLoopPainter extends CustomPainter {
  final PulmoMasterVitalsState vitals;

  _FvLoopPainter({required this.vitals});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2.0;

    // Zero-flow axis
    canvas.drawLine(Offset(20, midY), Offset(w - 20, midY), Paint()..color = const Color(0xFF1E293B));

    final loopPath = Path();
    final loopPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final vStart = 40.0;
    final vEnd = w - 40.0;

    // Inspiration (below baseline or above depending on convention)
    loopPath.moveTo(vStart, midY);
    loopPath.quadraticBezierTo((vStart + vEnd) / 2, midY + 45, vEnd, midY);

    // Expiration: check for obstructive scooping (Asthma/COPD)
    if (vitals.isSevereBronchospasm) {
      // Scooped expiratory limb
      loopPath.lineTo(vEnd - 20, midY - 60); // Peak expiratory flow
      loopPath.quadraticBezierTo((vStart + vEnd) / 2 + 30, midY - 15, vStart, midY); // Scooped concavity
    } else {
      // Normal linear expiratory limb
      loopPath.lineTo(vEnd - 30, midY - 55);
      loopPath.lineTo(vStart, midY);
    }

    canvas.drawPath(loopPath, loopPaint);
  }

  @override
  bool shouldRepaint(covariant _FvLoopPainter old) => true;
}
