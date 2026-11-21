// ============================================================================
// NephroLab 3D: Renal Color Doppler Ultrasound & Resistive Index (RI) Viewport
// ----------------------------------------------------------------------------
// Simulates B-Mode sector scanning with color flow Doppler (BART map) across
// Main Renal Artery, Segmental, Interlobar, and Arcuate arteries.
// Provides live spectral Doppler velocity envelope, PSV/EDV calipers, and RI gauge.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/nephro_master_vitals_state.dart';
import 'nephro_full_screen_doppler_theater.dart';

enum RenalDopplerArterySite {
  mainRenal('Main Renal Artery', 'MRA', 100.0, 36.0),
  segmental('Segmental Artery', 'Segmental', 48.0, 16.0),
  interlobar('Interlobar Artery', 'Interlobar', 32.0, 11.0),
  arcuate('Arcuate Artery', 'Arcuate', 24.0, 8.5);

  final String label;
  final String shortCode;
  final double normalPsv;
  final double normalEdv;

  const RenalDopplerArterySite(this.label, this.shortCode, this.normalPsv, this.normalEdv);
}

class NephroDopplerViewport extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroDopplerViewport({super.key, required this.vitals});

  @override
  State<NephroDopplerViewport> createState() => _NephroDopplerViewportState();
}

class _NephroDopplerViewportState extends State<NephroDopplerViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  RenalDopplerArterySite _selectedSite = RenalDopplerArterySite.segmental;
  final bool _colorDopplerEnabled = true;
  final bool _showCalipers = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double get _psv {
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.mainRenal) {
      return 260.0; // High velocity jet > 180 cm/s
    }
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.segmental) {
      return 26.0; // Parvus-Tardus waveform distal to stenosis!
    }
    if (widget.vitals.isAkiActive) {
      return _selectedSite.normalPsv * 1.15;
    }
    return _selectedSite.normalPsv;
  }

  double get _edv {
    if (widget.vitals.isRenalArteryStenosis && _selectedSite == RenalDopplerArterySite.segmental) {
      return 14.0;
    }
    if (widget.vitals.isAkiActive) {
      return math.max(2.0, _selectedSite.normalEdv * 0.4); // Marked diastolic loss in ATN!
    }
    return _selectedSite.normalEdv;
  }

  double get _ri => (_psv - _edv) / math.max(1.0, _psv);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'RENAL COLOR DOPPLER & RI',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Artery Picker
                DropdownButtonHideUnderline(
                  child: DropdownButton<RenalDopplerArterySite>(
                    value: _selectedSite,
                    dropdownColor: const Color(0xFF0F172A),
                    isDense: true,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    items: RenalDopplerArterySite.values.map((site) {
                      return DropdownMenuItem(
                        value: site,
                        child: Text(site.shortCode),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSite = val);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // Full Screen Theater Button
                IconButton(
                  tooltip: 'Full-Screen Doppler Theater',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF38BDF8)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NephroFullScreenDopplerTheater(vitals: widget.vitals),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Doppler Sector & Spectral Waveform
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RenalDopplerPainter(
                    phase: _anim.value,
                    psv: _psv,
                    edv: _edv,
                    ri: _ri,
                    site: _selectedSite,
                    showColor: _colorDopplerEnabled,
                    showCalipers: _showCalipers,
                    isStenosis: widget.vitals.isRenalArteryStenosis,
                    isAki: widget.vitals.isAkiActive,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Telemetry Strip at Bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFF0B132B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('PSV', '${_psv.toStringAsFixed(1)} cm/s', const Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  _buildMetric('EDV', '${_edv.toStringAsFixed(1)} cm/s', const Color(0xFF818CF8)),
                  const SizedBox(width: 8),
                  _buildMetric(
                    'RI',
                    _ri.toStringAsFixed(2),
                    _ri > 0.70 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    badge: _ri > 0.75 ? 'HIGH' : (_ri < 0.58 ? 'LOW' : 'NORM'),
                  ),
                  const SizedBox(width: 8),
                  _buildMetric(
                    'RAR',
                    (_psv / 70.0).toStringAsFixed(1),
                    (_psv / 70.0) >= 3.5 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, {String? badge}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
        if (badge != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Text(badge, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

class _RenalDopplerPainter extends CustomPainter {
  final double phase;
  final double psv;
  final double edv;
  final double ri;
  final RenalDopplerArterySite site;
  final bool showColor;
  final bool showCalipers;
  final bool isStenosis;
  final bool isAki;

  _RenalDopplerPainter({
    required this.phase,
    required this.psv,
    required this.edv,
    required this.ri,
    required this.site,
    required this.showColor,
    required this.showCalipers,
    required this.isStenosis,
    required this.isAki,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Split viewport: Top 45% B-Mode Sector, Bottom 55% Spectral Doppler
    final bModeHeight = h * 0.42;
    final spectralHeight = h - bModeHeight;

    // ── 1. B-Mode Ultrasound Sector ──────────────────────────────────────────
    final sectorRect = Rect.fromLTWH(0, 0, w, bModeHeight);
    canvas.save();
    canvas.clipRect(sectorRect);

    final sectorPaint = Paint()..color = const Color(0xFF02040A);
    canvas.drawRect(sectorRect, sectorPaint);

    final apex = Offset(w / 2.0, 5.0);
    final maxRadius = bModeHeight * 1.8;

    // Sector Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 1; r <= 3; r++) {
      canvas.drawCircle(apex, maxRadius * (r / 3.0), gridPaint);
    }

    // Kidney Silhouette (Renal outline)
    final kidneyPath = Path();
    final centerKidney = Offset(w * 0.50, bModeHeight * 0.55);
    kidneyPath.addOval(Rect.fromCenter(center: centerKidney, width: w * 0.45, height: bModeHeight * 0.65));

    final parenchymalPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(kidneyPath, parenchymalPaint);

    // Central Sinus (Echogenic fat)
    final sinusPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: centerKidney, width: w * 0.18, height: bModeHeight * 0.35),
      sinusPaint,
    );

    // Color Flow Doppler BART Sector (Blue Away, Red Toward)
    if (showColor) {
      final colorFlowRed = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      final colorFlowBlue = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;

      // Arteries (Red toward probe)
      canvas.drawCircle(centerKidney + const Offset(-15, -5), 6, colorFlowRed);
      canvas.drawCircle(centerKidney + const Offset(12, 10), 5, colorFlowRed);

      // Veins (Blue away)
      canvas.drawCircle(centerKidney + const Offset(-8, 12), 7, colorFlowBlue);

      // Sample Volume Gate Cursor (Yellow gate marks active site)
      final gatePaint = Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final gatePos = centerKidney + const Offset(-15, -5);
      canvas.drawLine(gatePos + const Offset(-6, -4), gatePos + const Offset(6, -4), gatePaint);
      canvas.drawLine(gatePos + const Offset(-6, 4), gatePos + const Offset(6, 4), gatePaint);
      canvas.drawLine(apex, gatePos, Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.2)..strokeWidth = 0.5);
    }

    canvas.restore();

    // ── 2. Spectral Doppler Division Line ──────────────────────────────────
    final divPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, bModeHeight), Offset(w, bModeHeight), divPaint);

    // ── 3. Spectral Velocity Waveform ──────────────────────────────────────
    final baselineY = h - 22.0;
    final maxVelocityScale = 300.0; // cm/s scale
    final pxPerCmS = (spectralHeight - 35.0) / maxVelocityScale;

    // Baseline axis
    final axisPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, baselineY), Offset(w, baselineY), axisPaint);

    // Velocity scale ticks
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (double v in [0, 50, 100, 200]) {
      final yTick = baselineY - (v * pxPerCmS);
      if (yTick > bModeHeight) {
        canvas.drawLine(Offset(0, yTick), Offset(4, yTick), axisPaint);
        textPainter.text = TextSpan(
          text: '${v.toInt()}',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(6, yTick - 4));
      }
    }

    // Draw Continuous Spectral Envelope
    final wavePath = Path();
    final fillPath = Path();
    fillPath.moveTo(0, baselineY);

    const int nSamples = 120;
    final periodWidth = w * 0.45; // ~2 cardiac cycles across width

    for (int i = 0; i < nSamples; i++) {
      final x = (i / (nSamples - 1)) * w;
      final cyclePhase = ((x / periodWidth) + phase) % 1.0;

      double velocity;
      if (isStenosis && site == RenalDopplerArterySite.segmental) {
        // Tardus-parvus: sluggish rise, rounded peak
        if (cyclePhase < 0.35) {
          velocity = edv + (psv - edv) * math.sin((cyclePhase / 0.35) * (math.pi / 2.0));
        } else {
          velocity = edv + (psv - edv) * math.exp(-(cyclePhase - 0.35) * 2.0);
        }
      } else {
        // Normal or high-resistance ATN
        if (cyclePhase < 0.12) {
          velocity = edv + (psv - edv) * math.sin((cyclePhase / 0.12) * (math.pi / 2.0));
        } else if (cyclePhase < 0.32) {
          velocity = edv + (psv - edv) * math.cos(((cyclePhase - 0.12) / 0.20) * (math.pi / 2.0)) * 0.7 + (edv * 0.3);
        } else {
          velocity = edv * math.exp(-(cyclePhase - 0.32) * 1.8);
        }
      }

      final y = baselineY - (velocity * pxPerCmS);

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

    // Waveform Spectral Gradient Fill
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF38BDF8).withValues(alpha: 0.6),
        const Color(0xFF0284C7).withValues(alpha: 0.15),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, bModeHeight, w, spectralHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wavePath, linePaint);

    // Electronic PSV & EDV Calipers
    if (showCalipers) {
      final caliperPaint = Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final psvY = baselineY - (psv * pxPerCmS);
      final edvY = baselineY - (edv * pxPerCmS);

      // PSV dotted horizontal
      canvas.drawLine(Offset(w * 0.65, psvY), Offset(w * 0.98, psvY), caliperPaint);
      // EDV dotted horizontal
      canvas.drawLine(Offset(w * 0.65, edvY), Offset(w * 0.98, edvY), caliperPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RenalDopplerPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.psv != psv ||
        oldDelegate.edv != edv ||
        oldDelegate.site != site;
  }
}
