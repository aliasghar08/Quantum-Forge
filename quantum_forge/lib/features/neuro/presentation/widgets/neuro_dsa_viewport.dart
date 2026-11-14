// ============================================================================
// Biplane DSA Neuro-Angiography Viewport — NeuroLab 3D
// ----------------------------------------------------------------------------
// High-resolution digital subtraction angiography (DSA) simulation of
// cerebral catheterization. Features:
// - Dual projection: Frontal (AP) and Straight Lateral (90°)
// - Beer-Lambert bone-subtraction radiopacity
// - Live contrast dye injection with pulsatile capillary wash
// - M1 occlusion cutoff vs TICI 3 revascularization
// - Aneurysm inflow jet & coil mass radiopacity
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';
import 'neuro_three_engine.dart';
import 'neuro_clinical_info_system.dart';

class NeuroDsaViewport extends StatefulWidget {
  final NeuroScenario scenario;
  final DsaProjection projection;
  final ValueChanged<DsaProjection> onProjectionChanged;
  final bool isThrombectomized;
  final bool isCoiled;
  final VoidCallback? onInjectContrast;

  const NeuroDsaViewport({
    super.key,
    required this.scenario,
    required this.projection,
    required this.onProjectionChanged,
    this.isThrombectomized = false,
    this.isCoiled = false,
    this.onInjectContrast,
  });

  @override
  State<NeuroDsaViewport> createState() => _NeuroDsaViewportState();
}

class _NeuroDsaViewportState extends State<NeuroDsaViewport> {
  NeuroLabThreeBridge? _bridge;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      NeuroLabThreeBridge.ensureViewFactories();
    }
  }

  void _onPlatformViewCreated(int id) {
    _bridge = NeuroLabThreeBridge.forDsaView(id) ?? NeuroLabThreeBridge.latestDsaBridge;
    _syncBridgeState();
  }

  void _syncBridgeState() {
    final b = _bridge ?? NeuroLabThreeBridge.latestDsaBridge;
    if (b == null) return;
    b.setDsaProjection(widget.projection.id);
    b.setAneurysmActive(widget.scenario.hasAneurysm);
    b.setM1OcclusionActive(widget.scenario.hasM1Occlusion && !widget.isThrombectomized);
    if (widget.isThrombectomized) {
      b.deployThrombectomy();
    }
    if (widget.isCoiled) {
      b.deployAneurysmCoils();
    }
  }

  @override
  void didUpdateWidget(covariant NeuroDsaViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projection != oldWidget.projection ||
        widget.scenario != oldWidget.scenario ||
        widget.isThrombectomized != oldWidget.isThrombectomized ||
        widget.isCoiled != oldWidget.isCoiled) {
      _syncBridgeState();
    }
  }

  void _handleInject() {
    final b = _bridge ?? NeuroLabThreeBridge.latestDsaBridge;
    b?.injectContrast();
    widget.onInjectContrast?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030508),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // DSA Canvas or Fallback Painter
          Positioned.fill(
            child: kIsWeb
                ? HtmlElementView(
                    viewType: NeuroLabThreeBridge.dsaViewType,
                    onPlatformViewCreated: _onPlatformViewCreated,
                  )
                : _DsaFallbackPainterWidget(
                    projection: widget.projection,
                    scenario: widget.scenario,
                    isThrombectomized: widget.isThrombectomized,
                    isCoiled: widget.isCoiled,
                  ),
          ),

          // Header Overlay
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B111E).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lens_blur_rounded, color: Color(0xFF94A3B8), size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'BIPLANE DSA (${widget.projection.label.toUpperCase()})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const NeuroInfoButton(topicId: 'm1_thrombectomy', size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Inject Contrast Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.water_drop_rounded, size: 13, color: Color(0xFF00E5FF)),
                  label: const Text('Inject Contrast Dye', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 1.0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: _handleInject,
                ),
              ],
            ),
          ),

          // Projection Switcher (Bottom-Left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: DsaProjection.values.map((proj) {
                  final isSelected = widget.projection == proj;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected ? const Color(0xFF334155) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => widget.onProjectionChanged(proj),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Text(
                            proj.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Scale & Calibration Badge (Top-Right under Header)
          Positioned(
            top: 50,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                '1024x1024 • 7.5 fps',
                style: TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DsaFallbackPainterWidget extends StatelessWidget {
  final DsaProjection projection;
  final NeuroScenario scenario;
  final bool isThrombectomized;
  final bool isCoiled;

  const _DsaFallbackPainterWidget({
    required this.projection,
    required this.scenario,
    required this.isThrombectomized,
    required this.isCoiled,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DsaFallbackPainter(
        projection: projection,
        scenario: scenario,
        isThrombectomized: isThrombectomized,
        isCoiled: isCoiled,
      ),
      size: Size.infinite,
    );
  }
}

class _DsaFallbackPainter extends CustomPainter {
  final DsaProjection projection;
  final NeuroScenario scenario;
  final bool isThrombectomized;
  final bool isCoiled;

  _DsaFallbackPainter({
    required this.projection,
    required this.scenario,
    required this.isThrombectomized,
    required this.isCoiled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;

    // Subtracted gray fluoroscopy background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F141C),
    );

    // Vignette circular mask
    final vignettePaint = Paint()
      ..color = const Color(0xFF1E2638).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), size.height * 0.44, vignettePaint);

    final vesselPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (projection == DsaProjection.ap) {
      // AP Frontal: Carotid siphon + bifurcation into ACA & MCA
      vesselPaint.strokeWidth = 5.0;
      final icaPath = Path()
        ..moveTo(cx - 20, size.height - 20)
        ..cubicTo(cx - 20, cy + 90, cx - 25, cy + 40, cx - 15, cy + 20);
      canvas.drawPath(icaPath, vesselPaint);

      // ACA branching medial & superior
      vesselPaint.strokeWidth = 3.5;
      final acaPath = Path()
        ..moveTo(cx - 15, cy + 20)
        ..cubicTo(cx - 8, cy - 10, cx - 5, cy - 50, cx - 5, cy - 90);
      canvas.drawPath(acaPath, vesselPaint);

      // ACom connection
      if (scenario.hasAneurysm) {
        canvas.drawCircle(
          Offset(cx - 2, cy - 15),
          isCoiled ? 7.0 : 9.0,
          Paint()
            ..color = isCoiled ? const Color(0xFFFFD740) : Colors.white
            ..style = isCoiled ? PaintingStyle.stroke : PaintingStyle.fill
            ..strokeWidth = 2.5,
        );
      }

      // MCA branching laterally
      final mcaPath = Path()
        ..moveTo(cx - 15, cy + 20)
        ..cubicTo(cx - 45, cy + 15, cx - 85, cy + 10, cx - 130, cy + 25);

      if (scenario.hasM1Occlusion && !isThrombectomized) {
        // Cutoff at M1
        final cutoffPath = Path()
          ..moveTo(cx - 15, cy + 20)
          ..lineTo(cx - 45, cy + 18);
        canvas.drawPath(cutoffPath, vesselPaint);
        // Abrupt truncated end
        canvas.drawCircle(Offset(cx - 45, cy + 18), 3.5, Paint()..color = const Color(0xFFEF4444));
      } else {
        // Full opacification
        canvas.drawPath(mcaPath, vesselPaint);
        // Distal M2/M3 branches
        vesselPaint.strokeWidth = 2.0;
        canvas.drawLine(Offset(cx - 85, cy + 10), Offset(cx - 110, cy - 20), vesselPaint);
        canvas.drawLine(Offset(cx - 110, cy + 18), Offset(cx - 140, cy + 60), vesselPaint);
      }
    } else {
      // Straight Lateral (90°): Carotid siphon hairpin loop + pericallosal arch
      vesselPaint.strokeWidth = 5.0;
      final siphonPath = Path()
        ..moveTo(cx - 40, size.height - 20)
        ..lineTo(cx - 40, cy + 60)
        ..cubicTo(cx - 40, cy + 20, cx - 10, cy + 10, cx - 10, cy + 30) // Siphon posterior bend
        ..cubicTo(cx - 10, cy + 50, cx + 20, cy + 40, cx + 15, cy + 10); // Anterior bend
      canvas.drawPath(siphonPath, vesselPaint);

      // Pericallosal ACA curving over corpus callosum
      vesselPaint.strokeWidth = 3.5;
      final pericallosal = Path()
        ..moveTo(cx + 15, cy + 10)
        ..cubicTo(cx + 20, cy - 40, cx - 20, cy - 70, cx - 60, cy - 70);
      canvas.drawPath(pericallosal, vesselPaint);

      // Sylvian tree going posteriorly
      final sylvian = Path()
        ..moveTo(cx + 15, cy + 10)
        ..cubicTo(cx + 50, cy + 5, cx + 80, cy - 15, cx + 110, cy - 35);

      if (scenario.hasM1Occlusion && !isThrombectomized) {
        final cutSylvian = Path()
          ..moveTo(cx + 15, cy + 10)
          ..lineTo(cx + 35, cy + 8);
        canvas.drawPath(cutSylvian, vesselPaint);
        canvas.drawCircle(Offset(cx + 35, cy + 8), 3.5, Paint()..color = const Color(0xFFEF4444));
      } else {
        canvas.drawPath(sylvian, vesselPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DsaFallbackPainter oldDelegate) {
    return oldDelegate.projection != projection ||
        oldDelegate.scenario != scenario ||
        oldDelegate.isThrombectomized != isThrombectomized ||
        oldDelegate.isCoiled != isCoiled;
  }
}
