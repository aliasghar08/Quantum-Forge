// ============================================================================
// DentoLab 3D: Chairside Multi-Channel Dental & Vital Monitor
// ----------------------------------------------------------------------------
// 5-Channel Chairside Hospital & Pulpal Telemetry Oscilloscope:
// 1. Ch 1: Lead II ECG (Green #00E676)
// 2. Ch 2: SpO₂ Plethysmograph (Cyan #00E5FF)
// 3. Ch 3: Non-Invasive Arterial BP (Crimson #FF5252)
// 4. Ch 4: Laser Doppler Pulp Vitality Blood Flow (LDF) (Amber #FFB74D)
// 5. Ch 5: Masseter & Temporalis Surface EMG (Violet #C084FC)
//
// Includes Electronic Freeze Calipers & Chairside Emergency Rescue
// (Epinephrine 1:1000, Flumazenil, Glucose, High-Flow O₂).
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/dental_models.dart';

class DentalChairsideMonitorStrip extends StatefulWidget {
  final DentalTelemetryState telemetry;
  final ValueChanged<DentalTelemetryState>? onTelemetryChanged;

  const DentalChairsideMonitorStrip({
    super.key,
    required this.telemetry,
    this.onTelemetryChanged,
  });

  @override
  State<DentalChairsideMonitorStrip> createState() => _DentalChairsideMonitorStripState();
}

class _DentalChairsideMonitorStripState extends State<DentalChairsideMonitorStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  bool _isFrozen = false;
  bool _calipersActive = false;
  double _caliperX1 = 0.35;
  double _caliperX2 = 0.65;
  int? _activeCaliperDrag;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  void _triggerEmergencyRescue(String medication) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        content: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMERGENCY RESCUE ADMINISTERED: $medication',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text(
                    'Vitals stabilized. High-flow O₂ initiated. Emergency Medical Services (EMS) on standby.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      widget.telemetry.heartRateBpm = 76.0;
      widget.telemetry.bloodPressureSys = 120.0;
      widget.telemetry.bloodPressureDia = 80.0;
      widget.telemetry.spo2Percent = 99.0;
    });
    widget.onTelemetryChanged?.call(widget.telemetry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF040711),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Left 5-Channel CRT Oscilloscope
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _sweepCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _DentalOscilloscopePainter(
                            sweepProgress: _isFrozen ? 0.8 : _sweepCtrl.value,
                            bpm: widget.telemetry.heartRateBpm,
                            ldfPercent: widget.telemetry.ldfPulpFlowPercent,
                            masseterEmg: widget.telemetry.masseterEmgMicroVolts,
                          ),
                        );
                      },
                    ),
                  ),

                  // Draggable Calipers
                  if (_calipersActive)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final x1 = _caliperX1 * constraints.maxWidth;
                          final x2 = _caliperX2 * constraints.maxWidth;
                          final deltaTms = ((_caliperX2 - _caliperX1).abs() * 3000).toInt();

                          return GestureDetector(
                            onPanStart: (d) {
                              final mx = d.localPosition.dx;
                              if ((mx - x1).abs() < 20) {
                                _activeCaliperDrag = 1;
                              } else if ((mx - x2).abs() < 20) {
                                _activeCaliperDrag = 2;
                              } else {
                                _activeCaliperDrag = null;
                              }
                            },
                            onPanUpdate: (d) {
                              if (_activeCaliperDrag == 1) {
                                setState(() => _caliperX1 = (d.localPosition.dx / constraints.maxWidth).clamp(0.05, 0.95));
                              } else if (_activeCaliperDrag == 2) {
                                setState(() => _caliperX2 = (d.localPosition.dx / constraints.maxWidth).clamp(0.05, 0.95));
                              }
                            },
                            onPanEnd: (_) => _activeCaliperDrag = null,
                            child: CustomPaint(
                              painter: _OscilloscopeCalipersPainter(x1: x1, x2: x2, deltaTms: deltaTms),
                            ),
                          );
                        },
                      ),
                    ),

                  // Top Oscilloscope Controls
                  Positioned(
                    top: 6,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        const Text(
                          'CHAIRSIDE TELEMETRY & PULP/JAW MONITOR',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const Spacer(),
                        // Freeze Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isFrozen = !_isFrozen;
                              if (_isFrozen) {
                                _sweepCtrl.stop();
                              } else {
                                _sweepCtrl.repeat();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isFrozen ? const Color(0xFFEF4444).withValues(alpha: 0.25) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _isFrozen ? const Color(0xFFEF4444) : const Color(0xFF334155)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isFrozen ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                  size: 12,
                                  color: _isFrozen ? const Color(0xFFEF4444) : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isFrozen ? 'FROZEN' : 'FREEZE',
                                  style: TextStyle(
                                    color: _isFrozen ? const Color(0xFFEF4444) : Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Calipers Toggle
                        InkWell(
                          onTap: () => setState(() => _calipersActive = !_calipersActive),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _calipersActive ? const Color(0xFF38BDF8).withValues(alpha: 0.25) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _calipersActive ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                            ),
                            child: Text(
                              'CALIPERS',
                              style: TextStyle(
                                color: _calipersActive ? const Color(0xFF38BDF8) : Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Channel Legend
                  Positioned(
                    bottom: 4,
                    left: 8,
                    child: Row(
                      children: [
                        _buildLegendItem('ECG II', const Color(0xFF00E676)),
                        const SizedBox(width: 10),
                        _buildLegendItem('SpO₂', const Color(0xFF00E5FF)),
                        const SizedBox(width: 10),
                        _buildLegendItem('BP', const Color(0xFFFF5252)),
                        const SizedBox(width: 10),
                        _buildLegendItem('LDF Pulp', const Color(0xFFFFB74D)),
                        const SizedBox(width: 10),
                        _buildLegendItem('Masseter EMG', const Color(0xFFC084FC)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vertical Divider
            Container(width: 1, color: const Color(0xFF1E293B)),

            // Right Hospital & Dental Telemetry Readout Tiles
            Container(
              width: 215,
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF070C18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: HR & SpO2
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          'HR',
                          '${widget.telemetry.heartRateBpm.toInt()}',
                          'bpm',
                          const Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTile(
                          'SpO₂',
                          '${widget.telemetry.spo2Percent.toInt()}',
                          '%',
                          const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),

                  // Row 2: BP & EPT
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          'NIBP',
                          '${widget.telemetry.bloodPressureSys.toInt()}/${widget.telemetry.bloodPressureDia.toInt()}',
                          'mmHg',
                          const Color(0xFFFF5252),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTile(
                          'EPT Pulp',
                          '${widget.telemetry.eptMicroAmps.toInt()}',
                          'µA',
                          const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),

                  // Row 3: Pocket Depth & Masseter EMG
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          'Pocket Depth',
                          widget.telemetry.pocketDepthMm.toStringAsFixed(1),
                          'mm',
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTile(
                          'Masseter EMG',
                          '${widget.telemetry.masseterEmgMicroVolts.toInt()}',
                          'µV',
                          const Color(0xFFC084FC),
                        ),
                      ),
                    ],
                  ),

                  // Row 4: Emergency Medical Rescue Buttons
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _triggerEmergencyRescue('Epinephrine 1:1000 (0.3 mg IM)'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: const Center(
                              child: Text(
                                '⚡ EPI 1:1000',
                                style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => _triggerEmergencyRescue('Flumazenil 0.2 mg IV (Sedation Reversal)'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF38BDF8)),
                            ),
                            child: const Center(
                              child: Text(
                                'FLUMAZENIL',
                                style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 7.5)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ============================================================================
// Multi-Channel CRT Sweep Waveform Painter
// ============================================================================

class _DentalOscilloscopePainter extends CustomPainter {
  final double sweepProgress;
  final double bpm;
  final double ldfPercent;
  final double masseterEmg;

  _DentalOscilloscopePainter({
    required this.sweepProgress,
    required this.bpm,
    required this.ldfPercent,
    required this.masseterEmg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background Phosphor Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF0F2942).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final channelHeight = size.height / 5;

    // Draw Ch 1: ECG Lead II
    _drawWave(canvas, size, 0 * channelHeight, channelHeight, const Color(0xFF00E676), (t) {
      final p = (t * (bpm / 60.0)) % 1.0;
      if (p > 0.12 && p < 0.16) return -0.25; // P wave
      if (p >= 0.18 && p < 0.20) return 0.15; // Q
      if (p >= 0.20 && p < 0.23) return -1.0; // R spike
      if (p >= 0.23 && p < 0.25) return 0.3; // S
      if (p > 0.35 && p < 0.45) return -0.35; // T wave
      return 0.0;
    });

    // Draw Ch 2: SpO2 Plethysmograph
    _drawWave(canvas, size, 1 * channelHeight, channelHeight, const Color(0xFF00E5FF), (t) {
      final p = ((t * (bpm / 60.0)) - 0.15) % 1.0;
      if (p < 0.0) return 0.0;
      if (p < 0.3) return -math.sin(p / 0.3 * math.pi);
      if (p < 0.5) return -0.35 * math.sin((p - 0.3) / 0.2 * math.pi); // Dicrotic notch
      return 0.0;
    });

    // Draw Ch 3: Arterial BP Wave
    _drawWave(canvas, size, 2 * channelHeight, channelHeight, const Color(0xFFFF5252), (t) {
      final p = (t * (bpm / 60.0)) % 1.0;
      if (p < 0.25) return -math.sin(p / 0.25 * math.pi) * 0.9;
      if (p >= 0.25 && p < 0.4) return -0.25 * math.sin((p - 0.25) / 0.15 * math.pi);
      return 0.0;
    });

    // Draw Ch 4: Laser Doppler Pulp Flow (LDF)
    _drawWave(canvas, size, 3 * channelHeight, channelHeight, const Color(0xFFFFB74D), (t) {
      final p = (t * (bpm / 60.0)) % 1.0;
      final pulsatile = -math.sin(p * math.pi * 2) * 0.45 * (ldfPercent / 100.0);
      final noise = (math.sin(t * 40.0) * 0.08);
      return pulsatile + noise;
    });

    // Draw Ch 5: Masseter / Temporalis EMG
    _drawWave(canvas, size, 4 * channelHeight, channelHeight, const Color(0xFFC084FC), (t) {
      final jitter = (math.sin(t * 120.0) * math.cos(t * 73.0)) * (masseterEmg / 150.0);
      return jitter;
    });

    // Vertical Phosphor Sweep Bar
    final sweepX = sweepProgress * size.width;
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(sweepX, 0), Offset(sweepX, size.height), sweepPaint);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double topY,
    double height,
    Color color,
    double Function(double t) generator,
  ) {
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final centerY = topY + height * 0.55;
    final amp = height * 0.38;

    final path = Path();
    bool first = true;
    final maxPts = (size.width).toInt();

    for (int x = 0; x < maxPts; x += 2) {
      final t = (x / size.width) * 3.0; // 3 sec time window
      final normVal = generator(t);
      final y = centerY + normVal * amp;

      if (first) {
        path.moveTo(x.toDouble(), y);
        first = false;
      } else {
        path.lineTo(x.toDouble(), y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _DentalOscilloscopePainter old) => true;
}

// ============================================================================
// Draggable Oscilloscope Calipers Overlay Painter
// ============================================================================

class _OscilloscopeCalipersPainter extends CustomPainter {
  final double x1;
  final double x2;
  final int deltaTms;

  _OscilloscopeCalipersPainter({required this.x1, required this.x2, required this.deltaTms});

  @override
  void paint(Canvas canvas, Size size) {
    final calPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // C1 & C2 vertical caliper lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), calPaint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), calPaint);

    // Delta t readout banner
    final midX = (x1 + x2) / 2;
    final textSpan = TextSpan(
      text: ' Δt = $deltaTms ms ',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        backgroundColor: Color(0xFF38BDF8),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(midX - tp.width / 2, size.height - 22));
  }

  @override
  bool shouldRepaint(covariant _OscilloscopeCalipersPainter old) {
    return old.x1 != x1 || old.x2 != x2 || old.deltaTms != deltaTms;
  }
}
