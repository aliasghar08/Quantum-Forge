// ============================================================================
// NephroLab 3D: 5-Channel Renal-ICU & CRRT CRT Oscilloscope Telemetry Strip
// ----------------------------------------------------------------------------
// Real-time 10.0-second calibrated (25/50 mm/s) 500 Hz CRT hospital monitor:
// Ch 1: ECG Lead II (Dynamic Hyperkalemia: Peaked T -> Wide QRS -> Sine-Wave)
// Ch 2: Systemic MAP & Renal Perfusion Pressure (RPP mmHg, Autoregulatory threshold)
// Ch 3: CRRT Circuit Pressures (Access -120 / TMP +145 / Return +110 mmHg)
// Ch 4: Real-time Urine Output Flow Rate (mL/hr, Oliguria < 30 mL/hr alert)
// Ch 5: Continuous Serum K+ (mEq/L) & Arterial pH Trend
//
// Controls: Freeze Calipers (C1/C2), IV Calcium Gluconate 10%, Insulin+D50W,
// IV Sodium Bicarb, Emergent HD / CRRT Start.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../clinical_core/data/multi_organ_patient_state.dart';

class NephroIcuOscilloscopeStrip extends StatefulWidget {
  final NephroMasterVitalsState vitals;
  final MultiOrganPatientState? patientState;

  const NephroIcuOscilloscopeStrip({
    super.key,
    required this.vitals,
    this.patientState,
  });

  @override
  State<NephroIcuOscilloscopeStrip> createState() => _NephroIcuOscilloscopeStripState();
}

class _NephroIcuOscilloscopeStripState extends State<NephroIcuOscilloscopeStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepAnim;
  bool _isFrozen = false;
  bool _calciumAdministered = false;
  bool _insulinAdministered = false;
  bool _bicarbAdministered = false;
  bool _crrtRunning = false;
  int _sweepSpeedMmS = 25; // 25 or 50 mm/s

  // Caliper state
  final double _caliper1X = 0.25;
  final double _caliper2X = 0.45;

  @override
  void initState() {
    super.initState();
    _sweepAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _sweepSpeedMmS == 25 ? 4000 : 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepAnim.dispose();
    super.dispose();
  }

  void _toggleSpeed() {
    setState(() {
      _sweepSpeedMmS = _sweepSpeedMmS == 25 ? 50 : 25;
      _sweepAnim.duration = Duration(milliseconds: _sweepSpeedMmS == 25 ? 4000 : 2000);
      if (!_isFrozen) _sweepAnim.repeat();
    });
  }

  void _toggleFreeze() {
    setState(() {
      _isFrozen = !_isFrozen;
      if (_isFrozen) {
        _sweepAnim.stop();
      } else {
        _sweepAnim.repeat();
      }
    });
  }

  void _giveCalciumGluconate() {
    setState(() {
      _calciumAdministered = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ IV Calcium Gluconate 10% (1g) Given: Cardiac Membrane Stabilized! QRS Narrowed.'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _giveInsulinD50W() {
    setState(() {
      _insulinAdministered = true;
      widget.vitals.potassium = math.max(3.8, widget.vitals.potassium - 1.2);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💉 10U Regular Insulin + 50 mL D50W + Albuterol: K+ shifted intracellularly (-1.2 mEq/L).'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _giveBicarbonate() {
    setState(() {
      _bicarbAdministered = true;
      widget.vitals.bicarb = math.min(26.0, widget.vitals.bicarb + 4.0);
      widget.vitals.ph = math.min(7.42, widget.vitals.ph + 0.08);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 2 Amps IV Sodium Bicarbonate (100 mEq) Administered: pH & HCO3- Corrected.'),
        backgroundColor: Color(0xFFD946EF),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _toggleCrrt() {
    setState(() {
      _crrtRunning = !_crrtRunning;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_crrtRunning ? '🔄 Emergent CRRT (CVVHDF) Circuit Initiated (Effluent: 25 mL/kg/hr).' : '⏹️ CRRT Circuit Paused.'),
        backgroundColor: _crrtRunning ? const Color(0xFF00E5FF) : Colors.amber,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double get _effectiveK {
    if (_calciumAdministered) {
      return math.min(5.2, widget.vitals.potassium - 2.0);
    }
    return widget.vitals.potassium;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF02040A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Oscilloscope CRT Top Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFF0A1120),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '5-CHANNEL RENAL-ICU & CRRT CRT OSCILLOSCOPE (500 Hz)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _effectiveK >= 7.5
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : (_effectiveK >= 6.0
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                            : const Color(0xFF10B981).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: _effectiveK >= 7.5
                          ? const Color(0xFFEF4444)
                          : (_effectiveK >= 6.0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _effectiveK >= 8.5
                        ? 'CRITICAL SINE-WAVE'
                        : (_effectiveK >= 7.6
                            ? 'WIDE QRS'
                            : (_effectiveK >= 6.0 ? 'PEAKED T' : 'NORMAL ECG')),
                    style: TextStyle(
                      color: _effectiveK >= 7.5
                          ? const Color(0xFFEF4444)
                          : (_effectiveK >= 6.0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Speed Toggle
                InkWell(
                  onTap: _toggleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_sweepSpeedMmS mm/s',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Freeze Button
                InkWell(
                  onTap: _toggleFreeze,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isFrozen ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isFrozen ? 'FROZEN' : 'FREEZE',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CRT Multi-Channel Phosphor Oscilloscope Canvas
          SizedBox(
            height: 180,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _sweepAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RenalIcuCrtPainter(
                    sweepPos: _sweepAnim.value,
                    effectiveK: _effectiveK,
                    rawK: widget.vitals.potassium,
                    map: widget.vitals.map,
                    rpp: widget.vitals.rpp,
                    urineFlow: widget.vitals.urineOutput,
                    isCrrtRunning: _crrtRunning,
                    isFrozen: _isFrozen,
                    caliper1X: _caliper1X,
                    caliper2X: _caliper2X,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Emergency Rescue Action Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF090E1A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionChip(
                    label: '⚡ Ca²⁺ Gluconate 10%',
                    color: const Color(0xFF10B981),
                    active: _calciumAdministered,
                    onTap: _giveCalciumGluconate,
                  ),
                  const SizedBox(width: 5),
                  _buildActionChip(
                    label: '💉 Insulin + D50W',
                    color: const Color(0xFF0284C7),
                    active: _insulinAdministered,
                    onTap: _giveInsulinD50W,
                  ),
                  const SizedBox(width: 5),
                  _buildActionChip(
                    label: '🧪 Sodium Bicarb',
                    color: const Color(0xFFD946EF),
                    active: _bicarbAdministered,
                    onTap: _giveBicarbonate,
                  ),
                  const SizedBox(width: 5),
                  _buildActionChip(
                    label: _crrtRunning ? '🔄 CRRT ACTIVE' : '▶ START CRRT',
                    color: const Color(0xFF00E5FF),
                    active: _crrtRunning,
                    onTap: _toggleCrrt,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'K⁺: ${widget.vitals.potassium.toStringAsFixed(1)} | RPP: ${widget.vitals.rpp.toStringAsFixed(0)} | UO: ${widget.vitals.urineOutput.toStringAsFixed(0)} mL/h',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.25) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? color : const Color(0xFF334155), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : const Color(0xFFE2E8F0),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RenalIcuCrtPainter extends CustomPainter {
  final double sweepPos;
  final double effectiveK;
  final double rawK;
  final double map;
  final double rpp;
  final double urineFlow;
  final bool isCrrtRunning;
  final bool isFrozen;
  final double caliper1X;
  final double caliper2X;

  _RenalIcuCrtPainter({
    required this.sweepPos,
    required this.effectiveK,
    required this.rawK,
    required this.map,
    required this.rpp,
    required this.urineFlow,
    required this.isCrrtRunning,
    required this.isFrozen,
    required this.caliper1X,
    required this.caliper2X,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Phosphor green grid
    final gridPaint = Paint()
      ..color = const Color(0xFF0F2418)
      ..strokeWidth = 0.5;

    for (double x = 0; x < w; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 5 Horizontal Channel Slots
    final chHeight = h / 5.0;

    // Paint Channel Labels
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawChLabel(String text, double y, Color color) {
      labelPainter.text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(6, y + 2));
    }

    drawChLabel('CH1: ECG II (K⁺ ${rawK.toStringAsFixed(1)})', 0, const Color(0xFF22C55E));
    drawChLabel('CH2: MAP / RPP (${rpp.toInt()} mmHg)', chHeight, const Color(0xFFEF4444));
    drawChLabel('CH3: CRRT TMP (${isCrrtRunning ? "+145" : "OFF"})', chHeight * 2, const Color(0xFF00E5FF));
    drawChLabel('CH4: URINE FLOW (${urineFlow.toInt()} mL/h)', chHeight * 3, const Color(0xFFF59E0B));
    drawChLabel('CH5: K⁺ & pH TREND', chHeight * 4, const Color(0xFFD946EF));

    // ── Channel 1: ECG Waveform ──────────────────────────────────────────────
    final ecgY = chHeight * 0.55;
    final ecgPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final ecgPath = Path();
    const int pts = 120;
    final cycleWidth = w * 0.22; // ~4.5 beats across screen

    for (int i = 0; i < pts; i++) {
      final x = (i / (pts - 1)) * w;
      final t = (x / cycleWidth) % 1.0;

      double dy = 0.0;
      if (effectiveK >= 8.5) {
        // Sine wave pattern
        dy = math.sin(t * 2.0 * math.pi) * (chHeight * 0.38);
      } else {
        // P-wave
        if (t < 0.12 && effectiveK < 7.0) {
          dy -= math.sin((t / 0.12) * math.pi) * 3.5;
        }
        // QRS
        final pr = 0.16 + (effectiveK > 6.0 ? (effectiveK - 6.0) * 0.03 : 0.0);
        final qrsW = 0.08 + (effectiveK > 6.5 ? (effectiveK - 6.5) * 0.035 : 0.0);
        if (t >= pr && t < pr + qrsW) {
          final qt = (t - pr) / qrsW;
          if (qt < 0.2) {
            dy += 3.0; // Q
          } else if (qt < 0.6) {
            dy -= chHeight * 0.35; // Tall R wave
          } else {
            dy += 6.0; // S wave
          }
        }
        // T-wave (Tall, peaked, tented)
        final tStart = pr + qrsW + 0.10;
        const tW = 0.16;
        if (t >= tStart && t < tStart + tW) {
          final tt = (t - tStart) / tW;
          final tAmp = (chHeight * 0.15) + math.max(0.0, (effectiveK - 4.5) * 4.5);
          dy -= math.sin(tt * math.pi) * tAmp;
        }
      }

      if (i == 0) {
        ecgPath.moveTo(x, ecgY + dy);
      } else {
        ecgPath.lineTo(x, ecgY + dy);
      }
    }
    canvas.drawPath(ecgPath, ecgPaint);

    // ── Channel 2: MAP / RPP Pulsatile Waveform ──────────────────────────────
    final mapY = chHeight * 1.55;
    final rppPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rppPath = Path();

    for (int i = 0; i < pts; i++) {
      final x = (i / (pts - 1)) * w;
      final t = (x / cycleWidth) % 1.0;
      final dy = -math.sin(t * 2.0 * math.pi) * (chHeight * 0.28) * math.exp(-t * 1.5);
      if (i == 0) {
        rppPath.moveTo(x, mapY + dy);
      } else {
        rppPath.lineTo(x, mapY + dy);
      }
    }
    canvas.drawPath(rppPath, rppPaint);

    // ── Channel 3: CRRT TMP Pressures ────────────────────────────────────────
    final crrtY = chHeight * 2.55;
    final crrtPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final crrtPath = Path();

    for (int i = 0; i < pts; i++) {
      final x = (i / (pts - 1)) * w;
      final dy = isCrrtRunning ? math.sin(x * 0.15) * 4.0 : 0.0;
      if (i == 0) {
        crrtPath.moveTo(x, crrtY + dy);
      } else {
        crrtPath.lineTo(x, crrtY + dy);
      }
    }
    canvas.drawPath(crrtPath, crrtPaint);

    // ── Channel 4: Urine Output Flow Rate ────────────────────────────────────
    final uoY = chHeight * 3.55;
    final uoPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final uoPath = Path();

    for (int i = 0; i < pts; i++) {
      final x = (i / (pts - 1)) * w;
      final dy = math.sin(x * 0.04) * 3.0;
      if (i == 0) {
        uoPath.moveTo(x, uoY + dy);
      } else {
        uoPath.lineTo(x, uoY + dy);
      }
    }
    canvas.drawPath(uoPath, uoPaint);

    // ── Channel 5: K+ & pH Trend ─────────────────────────────────────────────
    final kY = chHeight * 4.55;
    final kPaint = Paint()
      ..color = const Color(0xFFD946EF)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final kPath = Path();

    for (int i = 0; i < pts; i++) {
      final x = (i / (pts - 1)) * w;
      final dy = math.sin(x * 0.02) * 2.0;
      if (i == 0) {
        kPath.moveTo(x, kY + dy);
      } else {
        kPath.lineTo(x, kY + dy);
      }
    }
    canvas.drawPath(kPath, kPaint);

    // Vertical CRT Sweep Cursor
    if (!isFrozen) {
      final sweepX = sweepPos * w;
      final sweepPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(sweepX, 0), Offset(sweepX, h), sweepPaint);

      // Phosphor Fade Erase Bar right after cursor
      final eraseRect = Rect.fromLTWH(sweepX, 0, 15, h);
      final erasePaint = Paint()..color = const Color(0xFF02040A).withValues(alpha: 0.65);
      canvas.drawRect(eraseRect, erasePaint);
    }

    // Freeze Calipers
    if (isFrozen) {
      final calPaint = Paint()
        ..color = const Color(0xFFFFD600)
        ..strokeWidth = 1.0;
      final c1 = caliper1X * w;
      final c2 = caliper2X * w;
      canvas.drawLine(Offset(c1, 0), Offset(c1, h), calPaint);
      canvas.drawLine(Offset(c2, 0), Offset(c2, h), calPaint);

      // Caliper Delta readout
      final deltaMs = ((caliper2X - caliper1X).abs() * 4000).toInt();
      labelPainter.text = TextSpan(
        text: 'Δt: $deltaMs ms (QRS/PR Caliper)',
        style: const TextStyle(color: Color(0xFFFFD600), fontSize: 9, fontWeight: FontWeight.bold),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(c1 + 4, 15));
    }
  }

  @override
  bool shouldRepaint(covariant _RenalIcuCrtPainter oldDelegate) {
    return oldDelegate.sweepPos != sweepPos ||
        oldDelegate.effectiveK != effectiveK ||
        oldDelegate.rawK != rawK ||
        oldDelegate.isCrrtRunning != isCrrtRunning ||
        oldDelegate.isFrozen != isFrozen;
  }
}
