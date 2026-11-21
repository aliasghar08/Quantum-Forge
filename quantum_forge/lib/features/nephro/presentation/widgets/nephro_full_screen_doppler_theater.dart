// ============================================================================
// NephroLab 3D: Full-Screen Renal Color Doppler & Resistive Index Theater
// ----------------------------------------------------------------------------
// Full-screen (100vw x 100vh) immersive renal vascular ultrasound workstation.
// Features interactive Doppler sample volume gating, live spectral FFT analysis,
// electronic PSV/EDV calipers, resistive index gauge, and USMLE fellowship pearls.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/nephro_master_vitals_state.dart';
import 'nephro_doppler_viewport.dart';

class NephroFullScreenDopplerTheater extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroFullScreenDopplerTheater({super.key, required this.vitals});

  @override
  State<NephroFullScreenDopplerTheater> createState() =>
      _NephroFullScreenDopplerTheaterState();
}

class _NephroFullScreenDopplerTheaterState
    extends State<NephroFullScreenDopplerTheater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  RenalDopplerArterySite _selectedSite = RenalDopplerArterySite.segmental;
  bool _showColor = true;
  bool _showCalipers = true;
  bool _showTags = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double get _psv {
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.mainRenal) {
      return 265.0;
    }
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.segmental) {
      return 25.0; // Tardus-Parvus!
    }
    if (widget.vitals.isAkiActive) {
      return _selectedSite.normalPsv * 1.18;
    }
    return _selectedSite.normalPsv;
  }

  double get _edv {
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.segmental) {
      return 13.0;
    }
    if (widget.vitals.isAkiActive) {
      return math.max(2.0, _selectedSite.normalEdv * 0.35);
    }
    return _selectedSite.normalEdv;
  }

  double get _ri => (_psv - _edv) / math.max(1.0, _psv);
  double get _pi => (_psv - _edv) / math.max(1.0, (_psv + 2.0 * _edv) / 3.0);
  double get _rar => _psv / 70.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          children: [
            // Top Control Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FULL-SCREEN RENAL COLOR DOPPLER & RI THEATER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'B-Mode Sector · BART Color Flow · Spectral FFT Velocity Envelope · Calipers',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Color Toggle
                  FilterChip(
                    label: const Text('BART Color', style: TextStyle(fontSize: 10)),
                    selected: _showColor,
                    onSelected: (val) => setState(() => _showColor = val),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  // Calipers Toggle
                  FilterChip(
                    label: const Text('Calipers', style: TextStyle(fontSize: 10)),
                    selected: _showCalipers,
                    onSelected: (val) => setState(() => _showCalipers = val),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFFEAB308),
                  ),
                  const SizedBox(width: 8),
                  // Tags Toggle
                  FilterChip(
                    label: const Text('🏷️ Tags', style: TextStyle(fontSize: 10)),
                    selected: _showTags,
                    onSelected: (val) => setState(() => _showTags = val),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),

            // Main Display Sector
            Expanded(
              child: Row(
                children: [
                  // Ultrasound Display Pane
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _anim,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _FullScreenDopplerPainter(
                                  phase: _anim.value,
                                  psv: _psv,
                                  edv: _edv,
                                  ri: _ri,
                                  site: _selectedSite,
                                  showColor: _showColor,
                                  showCalipers: _showCalipers,
                                  showTags: _showTags,
                                  isStenosis: widget.vitals.isRenalArteryStenosis,
                                  isAki: widget.vitals.isAkiActive,
                                ),
                              );
                            },
                          ),
                        ),

                        // Interactive Gate Overlay
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              children: [
                                const Text('GATE: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<RenalDopplerArterySite>(
                                    value: _selectedSite,
                                    dropdownColor: const Color(0xFF0F172A),
                                    isDense: true,
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                    items: RenalDopplerArterySite.values.map((s) {
                                      return DropdownMenuItem(value: s, child: Text(s.label));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedSite = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Diagnostics Sidebar
                  Container(
                    width: 320,
                    color: const Color(0xFF090E1A),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HEMODYNAMIC METRICS',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricTile('Peak Systolic Velocity (PSV)', '${_psv.toStringAsFixed(1)} cm/s', const Color(0xFF38BDF8), 'Normal: 60-120 cm/s'),
                        _buildMetricTile('End Diastolic Velocity (EDV)', '${_edv.toStringAsFixed(1)} cm/s', const Color(0xFF818CF8), 'Normal: 20-40 cm/s'),
                        _buildMetricTile(
                          'Resistive Index (RI = [PSV-EDV]/PSV)',
                          _ri.toStringAsFixed(2),
                          _ri > 0.70 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          _ri > 0.75 ? 'ELEVATED: ATN, Rejection, or Obstruction' : (_ri < 0.58 ? 'LOW: Distal to Renal Artery Stenosis' : 'NORMAL (<0.70)'),
                        ),
                        _buildMetricTile('Pulsatility Index (PI)', _pi.toStringAsFixed(2), const Color(0xFFF59E0B), 'Normal: 1.1 - 1.5'),
                        _buildMetricTile('Renal-Aortic Ratio (RAR)', _rar.toStringAsFixed(1), _rar >= 3.5 ? const Color(0xFFEF4444) : const Color(0xFF10B981), _rar >= 3.5 ? 'CRITICAL: >3.5 indicates >60% Stenosis' : 'Normal (<3.5)'),
                        const Divider(color: Color(0xFF1E293B), height: 24),
                        const Text(
                          'USMLE / NEPHROLOGY PEARLS',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _getClinicalNotes(),
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5, height: 1.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, Color color, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(sub, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 8.5)),
          ],
        ),
      ),
    );
  }

  String _getClinicalNotes() {
    if (widget.vitals.isRenalArteryStenosis) {
      return '• Severe Renal Artery Stenosis (>60% lumen narrowing):\n'
          '  - MRA shows marked velocity acceleration (PSV > 180-200 cm/s) and Renal-Aortic Ratio (RAR) > 3.5.\n'
          '  - Segmental arteries exhibit the classic "Parvus-Tardus" waveform: prolonged systolic acceleration time (AT > 0.07s) and flattened acceleration index (AI < 3.0 m/s²).\n'
          '  - Stimulates high renin secretion from ipsilateral ischemic kidney, causing renovascular hypertension.';
    }
    if (widget.vitals.isAkiActive) {
      return '• Acute Tubular Necrosis (ATN) & Acute Obstruction:\n'
          '  - Marked increase in parenchymal Resistive Index (RI > 0.75 - 0.85).\n'
          '  - Caused by interstitial edema, sloughed tubular cellular debris obstructing lumens, and intense pre-glomerular vasoconstriction.\n'
          '  - Severe cases may show absent or even reversed diastolic flow in interlobar vessels.';
    }
    return '• Normal Renal Doppler Hemodynamics:\n'
        '  - Low-resistance vascular bed with continuous forward diastolic flow throughout the cardiac cycle.\n'
        '  - Normal Resistive Index (RI) is typically 0.58 to 0.68. RI > 0.70 is abnormal in all adult age groups.\n'
        '  - BART (Blue Away, Red Toward probe) color Doppler allows rapid visualization of main renal artery origin from the abdominal aorta.';
  }
}

class _FullScreenDopplerPainter extends CustomPainter {
  final double phase;
  final double psv;
  final double edv;
  final double ri;
  final RenalDopplerArterySite site;
  final bool showColor;
  final bool showCalipers;
  final bool showTags;
  final bool isStenosis;
  final bool isAki;

  _FullScreenDopplerPainter({
    required this.phase,
    required this.psv,
    required this.edv,
    required this.ri,
    required this.site,
    required this.showColor,
    required this.showCalipers,
    required this.showTags,
    required this.isStenosis,
    required this.isAki,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bModeHeight = h * 0.48;
    final spectralHeight = h - bModeHeight;

    // Top B-Mode Sector
    final sectorRect = Rect.fromLTWH(0, 0, w, bModeHeight);
    canvas.save();
    canvas.clipRect(sectorRect);

    final bgPaint = Paint()..color = const Color(0xFF030712);
    canvas.drawRect(sectorRect, bgPaint);

    final apex = Offset(w / 2.0, 10.0);
    final maxRadius = bModeHeight * 1.6;

    // Sector Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(apex, maxRadius * (r / 4.0), gridPaint);
    }

    // Kidney Silhouette
    final centerKidney = Offset(w * 0.50, bModeHeight * 0.58);
    final kidneyRect = Rect.fromCenter(center: centerKidney, width: w * 0.55, height: bModeHeight * 0.70);
    canvas.drawOval(kidneyRect, Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.75));

    // Medullary Pyramids (Hypoechoic)
    final medullaryPaint = Paint()..color = const Color(0xFF0F172A);
    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.35;
      final pyCenter = centerKidney + Offset(math.cos(angle) * (w * 0.15), math.sin(angle) * (bModeHeight * 0.22));
      canvas.drawOval(Rect.fromCenter(center: pyCenter, width: 28, height: 18), medullaryPaint);
    }

    // Central Sinus (Echogenic)
    canvas.drawOval(
      Rect.fromCenter(center: centerKidney, width: w * 0.22, height: bModeHeight * 0.38),
      Paint()..color = const Color(0xFF475569).withValues(alpha: 0.8),
    );

    // Color Doppler Flow
    if (showColor) {
      final redPaint = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.7);
      final bluePaint = Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.7);

      canvas.drawCircle(centerKidney + const Offset(-25, -10), 8, redPaint);
      canvas.drawCircle(centerKidney + const Offset(20, 15), 7, redPaint);
      canvas.drawCircle(centerKidney + const Offset(-10, 18), 9, bluePaint);

      // Gate
      final gatePos = centerKidney + const Offset(-25, -10);
      final gatePaint = Paint()..color = const Color(0xFFFFD600)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawLine(gatePos + const Offset(-10, -5), gatePos + const Offset(10, -5), gatePaint);
      canvas.drawLine(gatePos + const Offset(-10, 5), gatePos + const Offset(10, 5), gatePaint);
    }

    // 🏷️ Tags
    if (showTags) {
      final tagPainter = TextPainter(textDirection: TextDirection.ltr);
      void drawTag(String text, Offset pos, Color color) {
        tagPainter.text = TextSpan(
          text: '🏷️ $text',
          style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold, backgroundColor: Colors.black87),
        );
        tagPainter.layout();
        tagPainter.paint(canvas, pos);
      }

      drawTag('Renal Cortex', centerKidney + Offset(-w * 0.24, -bModeHeight * 0.25), const Color(0xFFE0E7FF));
      drawTag('Medullary Pyramid', centerKidney + Offset(w * 0.14, -bModeHeight * 0.18), const Color(0xFF818CF8));
      drawTag('Renal Pelvis / Hilum', centerKidney + const Offset(-30, 28), const Color(0xFF38BDF8));
    }

    canvas.restore();

    // Divider
    canvas.drawLine(Offset(0, bModeHeight), Offset(w, bModeHeight), Paint()..color = const Color(0xFF334155)..strokeWidth = 1.5);

    // Bottom Spectral FFT Waveform
    final baselineY = h - 28.0;
    final maxScale = 320.0;
    final pxPerCmS = (spectralHeight - 45.0) / maxScale;

    // Zero baseline
    canvas.drawLine(Offset(0, baselineY), Offset(w, baselineY), Paint()..color = const Color(0xFF64748B)..strokeWidth = 1.0);

    // Scale ticks
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (double v in [0, 50, 100, 150, 200, 250, 300]) {
      final yTick = baselineY - (v * pxPerCmS);
      if (yTick > bModeHeight) {
        canvas.drawLine(Offset(0, yTick), Offset(6, yTick), Paint()..color = const Color(0xFF475569));
        textPainter.text = TextSpan(text: '${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8));
        textPainter.layout();
        textPainter.paint(canvas, Offset(8, yTick - 5));
      }
    }

    // Draw Continuous Spectral Envelope
    final wavePath = Path();
    final fillPath = Path();
    fillPath.moveTo(0, baselineY);

    const int nSamples = 160;
    final periodWidth = w * 0.35;

    for (int i = 0; i < nSamples; i++) {
      final x = (i / (nSamples - 1)) * w;
      final cyclePhase = ((x / periodWidth) + phase) % 1.0;

      double v;
      if (isStenosis && site == RenalDopplerArterySite.segmental) {
        if (cyclePhase < 0.38) {
          v = edv + (psv - edv) * math.sin((cyclePhase / 0.38) * (math.pi / 2.0));
        } else {
          v = edv + (psv - edv) * math.exp(-(cyclePhase - 0.38) * 2.2);
        }
      } else {
        if (cyclePhase < 0.12) {
          v = edv + (psv - edv) * math.sin((cyclePhase / 0.12) * (math.pi / 2.0));
        } else if (cyclePhase < 0.30) {
          v = edv + (psv - edv) * math.cos(((cyclePhase - 0.12) / 0.18) * (math.pi / 2.0)) * 0.75 + (edv * 0.25);
        } else {
          v = edv * math.exp(-(cyclePhase - 0.30) * 1.6);
        }
      }

      final y = baselineY - (v * pxPerCmS);
      if (i == 0) {
        wavePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        wavePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(w, baselineY);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF38BDF8).withValues(alpha: 0.65),
        const Color(0xFF0284C7).withValues(alpha: 0.1),
      ],
    );
    canvas.drawPath(fillPath, Paint()..shader = fillGradient.createShader(Rect.fromLTWH(0, bModeHeight, w, spectralHeight)));
    canvas.drawPath(wavePath, Paint()..color = const Color(0xFF38BDF8)..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Calipers
    if (showCalipers) {
      final psvY = baselineY - (psv * pxPerCmS);
      final edvY = baselineY - (edv * pxPerCmS);
      final calPaint = Paint()..color = const Color(0xFFFFD600)..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.70, psvY), Offset(w * 0.98, psvY), calPaint);
      canvas.drawLine(Offset(w * 0.70, edvY), Offset(w * 0.98, edvY), calPaint);

      textPainter.text = TextSpan(
        text: 'PSV: ${psv.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFFFFD600), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(w * 0.71, psvY - 12));

      textPainter.text = TextSpan(
        text: 'EDV: ${edv.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFFFFD600), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(w * 0.71, edvY - 12));
    }
  }

  @override
  bool shouldRepaint(covariant _FullScreenDopplerPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.site != site || oldDelegate.psv != psv;
  }
}
