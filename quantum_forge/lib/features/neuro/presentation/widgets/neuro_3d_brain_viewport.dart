// ============================================================================
// 3D Glassmorphic Brain, Neurovascular & Spinal Cord Viewport — NeuroLab 3D
// ----------------------------------------------------------------------------
// Embeds procedural Three.js WebGL rendering for:
// - Glassmorphic translucent cerebral cortex, cerebellum & brainstem
// - Complete Circle of Willis & dural sinuses (ICA, MCA, ACA, Basilar, SSS)
// - Ventricular CSF circulation with kinetic flow particles
// - Full C1–L5 spinal cord with internal tract columns
// - Ischemic core vs. penumbra volumetric map
// - Interactive endovascular devices: Stent-retriever & platinum coil mass
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';
import 'neuro_three_engine.dart';
import 'neuro_clinical_info_system.dart';

class Neuro3DBrainViewport extends StatefulWidget {
  final NeuroScenario scenario;
  final NeuroAnatomicalLayer selectedLayer;
  final ValueChanged<NeuroAnatomicalLayer> onLayerChanged;
  final bool isThrombectomized;
  final bool isCoiled;
  final VoidCallback? onDeployThrombectomy;
  final VoidCallback? onDeployCoils;

  const Neuro3DBrainViewport({
    super.key,
    required this.scenario,
    required this.selectedLayer,
    required this.onLayerChanged,
    this.isThrombectomized = false,
    this.isCoiled = false,
    this.onDeployThrombectomy,
    this.onDeployCoils,
  });

  @override
  State<Neuro3DBrainViewport> createState() => _Neuro3DBrainViewportState();
}

class _Neuro3DBrainViewportState extends State<Neuro3DBrainViewport> {
  NeuroLabThreeBridge? _bridge;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      NeuroLabThreeBridge.ensureViewFactories();
    }
  }

  void _onPlatformViewCreated(int id) {
    _bridge = NeuroLabThreeBridge.forBrainView(id) ?? NeuroLabThreeBridge.latestBrainBridge;
    _syncBridgeState();
  }

  void _syncBridgeState() {
    final b = _bridge ?? NeuroLabThreeBridge.latestBrainBridge;
    if (b == null) return;
    b.setLayer(widget.selectedLayer.id);
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
  void didUpdateWidget(covariant Neuro3DBrainViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLayer != oldWidget.selectedLayer ||
        widget.scenario != oldWidget.scenario ||
        widget.isThrombectomized != oldWidget.isThrombectomized ||
        widget.isCoiled != oldWidget.isCoiled) {
      _syncBridgeState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060911),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 3D Canvas / PlatformView or Fallback
          Positioned.fill(
            child: kIsWeb
                ? HtmlElementView(
                    viewType: NeuroLabThreeBridge.brainViewType,
                    onPlatformViewCreated: _onPlatformViewCreated,
                  )
                : _Brain3DFallbackPainterWidget(
                    layer: widget.selectedLayer,
                    scenario: widget.scenario,
                    isThrombectomized: widget.isThrombectomized,
                    isCoiled: widget.isCoiled,
                  ),
          ),

          // Top Header & Layer Selection Bar
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar_rounded, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 6),
                      Text(
                        '3D BRAIN & SPINAL CORD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 4),
                      NeuroInfoButton(topicId: 'circle_of_willis', size: 14),
                    ],
                  ),
                ),
                const Spacer(),
                // Reset View Button
                IconButton(
                  tooltip: 'Reset 3D Camera',
                  icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white70, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    padding: const EdgeInsets.all(6),
                  ),
                  onPressed: () {
                    final b = _bridge ?? NeuroLabThreeBridge.latestBrainBridge;
                    b?.resetCamera();
                  },
                ),
              ],
            ),
          ),

          // Layer Mode Horizontal Chips (Bottom-Left)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Intervention Action Buttons if relevant
                if (widget.scenario.hasM1Occlusion || widget.scenario.hasAneurysm)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (widget.scenario.hasM1Occlusion)
                          ElevatedButton.icon(
                            icon: Icon(
                              widget.isThrombectomized ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                              size: 14,
                              color: widget.isThrombectomized ? const Color(0xFF00E676) : Colors.white,
                            ),
                            label: Text(
                              widget.isThrombectomized ? 'TICI 3 Revascularized' : 'Deploy Stent-Retriever',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isThrombectomized
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: widget.isThrombectomized ? null : widget.onDeployThrombectomy,
                          ),
                        if (widget.scenario.hasAneurysm)
                          ElevatedButton.icon(
                            icon: Icon(
                              widget.isCoiled ? Icons.verified_rounded : Icons.album_rounded,
                              size: 14,
                              color: widget.isCoiled ? const Color(0xFF00E676) : Colors.white,
                            ),
                            label: Text(
                              widget.isCoiled ? 'Raymond I Occluded' : 'Deploy Endovascular Coils',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isCoiled
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: widget.isCoiled ? null : widget.onDeployCoils,
                          ),
                      ],
                    ),
                  ),

                // Layer Chips Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F1D).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: NeuroAnatomicalLayer.values.map((layer) {
                        final isSelected = widget.selectedLayer == layer;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(layer.label, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0284C7),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            onSelected: (val) {
                              if (val) widget.onLayerChanged(layer);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brain3DFallbackPainterWidget extends StatelessWidget {
  final NeuroAnatomicalLayer layer;
  final NeuroScenario scenario;
  final bool isThrombectomized;
  final bool isCoiled;

  const _Brain3DFallbackPainterWidget({
    required this.layer,
    required this.scenario,
    required this.isThrombectomized,
    required this.isCoiled,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Brain3DFallbackPainter(
        layer: layer,
        scenario: scenario,
        isThrombectomized: isThrombectomized,
        isCoiled: isCoiled,
      ),
      size: Size.infinite,
    );
  }
}

class _Brain3DFallbackPainter extends CustomPainter {
  final NeuroAnatomicalLayer layer;
  final NeuroScenario scenario;
  final bool isThrombectomized;
  final bool isCoiled;

  _Brain3DFallbackPainter({
    required this.layer,
    required this.scenario,
    required this.isThrombectomized,
    required this.isCoiled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Background gradient grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1. Cortical glassmorphic contours
    if (layer == NeuroAnatomicalLayer.all ||
        layer == NeuroAnatomicalLayer.cortical ||
        layer == NeuroAnatomicalLayer.penumbra) {
      final brainFill = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final brainOutline = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Left & Right Hemispheres
      final leftHemi = Path()
        ..addOval(Rect.fromCenter(center: Offset(cx - 55, cy), width: 100, height: 130));
      final rightHemi = Path()
        ..addOval(Rect.fromCenter(center: Offset(cx + 55, cy), width: 100, height: 130));
      // Cerebellum & Brainstem
      final cerebellum = Path()
        ..addOval(Rect.fromCenter(center: Offset(cx, cy + 65), width: 120, height: 50));
      final brainstem = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 95), width: 34, height: 70),
          const Radius.circular(8),
        ));

      canvas.drawPath(leftHemi, brainFill);
      canvas.drawPath(leftHemi, brainOutline);
      canvas.drawPath(rightHemi, brainFill);
      canvas.drawPath(rightHemi, brainOutline);
      canvas.drawPath(cerebellum, brainFill);
      canvas.drawPath(cerebellum, brainOutline);
      canvas.drawPath(brainstem, brainFill);
      canvas.drawPath(brainstem, brainOutline);

      // Sulci Gyri decorative ripples
      final sulcusPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 55, cy - 20), width: 60, height: 40), 0.2, math.pi * 0.9, false, sulcusPaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 55, cy - 20), width: 60, height: 40), 0.2, math.pi * 0.9, false, sulcusPaint);
    }

    // 2. Circle of Willis Vessels
    if (layer == NeuroAnatomicalLayer.all || layer == NeuroAnatomicalLayer.vessels) {
      final vesselPaint = Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      // Basilar & Vertebrals
      canvas.drawLine(Offset(cx, cy + 95), Offset(cx, cy + 30), vesselPaint);
      canvas.drawLine(Offset(cx - 15, cy + 120), Offset(cx, cy + 95), vesselPaint);
      canvas.drawLine(Offset(cx + 15, cy + 120), Offset(cx, cy + 95), vesselPaint);

      // Circle of Willis ring
      final cowRing = Path()
        ..addOval(Rect.fromCenter(center: Offset(cx, cy + 15), width: 50, height: 35));
      canvas.drawPath(cowRing, vesselPaint);

      // MCAs branching laterally
      final mcaLeft = Path()
        ..moveTo(cx - 25, cy + 15)
        ..cubicTo(cx - 50, cy + 10, cx - 85, cy + 20, cx - 110, cy + 5);
      final mcaRight = Path()
        ..moveTo(cx + 25, cy + 15)
        ..cubicTo(cx + 50, cy + 10, cx + 85, cy + 20, cx + 110, cy + 5);

      canvas.drawPath(mcaRight, vesselPaint);

      if (scenario.hasM1Occlusion && !isThrombectomized) {
        // Red clot cutoff on left MCA
        canvas.drawPath(mcaLeft, vesselPaint..color = const Color(0xFF64748B));
        canvas.drawCircle(Offset(cx - 50, cy + 12), 6.5, Paint()..color = const Color(0xFFDC2626));
      } else {
        canvas.drawPath(mcaLeft, vesselPaint);
      }

      // Aneurysm on ACom
      if (scenario.hasAneurysm) {
        final sacPaint = Paint()
          ..color = isCoiled ? const Color(0xFFFFD740) : const Color(0xFFFF1744)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy - 5), 8.0, sacPaint);
      }
    }

    // 3. Ventricles & CSF
    if (layer == NeuroAnatomicalLayer.all || layer == NeuroAnatomicalLayer.ventricles) {
      final ventriclePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      // Lateral ventricle anterior and temporal horns
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 20, cy), width: 35, height: 60), -math.pi * 0.4, math.pi * 0.8, false, ventriclePaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 20, cy), width: 35, height: 60), math.pi * 0.6, math.pi * 0.8, false, ventriclePaint);
    }

    // 4. Spinal Cord (C1-L5)
    if (layer == NeuroAnatomicalLayer.all || layer == NeuroAnatomicalLayer.spine) {
      final spinePaint = Paint()
        ..color = const Color(0xFFA78BFA).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy + 130), Offset(cx, size.height - 50), spinePaint);

      // Tract columns inside spine
      final cstPaint = Paint()
        ..color = const Color(0xFFFF5252)
        ..strokeWidth = 3.0;
      final dcPaint = Paint()
        ..color = const Color(0xFF00E676)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(cx - 3, cy + 130), Offset(cx - 3, size.height - 50), cstPaint);
      canvas.drawLine(Offset(cx + 3, cy + 130), Offset(cx + 3, size.height - 50), dcPaint);
    }

    // 5. Penumbra Map
    if (layer == NeuroAnatomicalLayer.penumbra || (scenario.hasM1Occlusion && layer == NeuroAnatomicalLayer.all)) {
      // Penumbra (salvageable amber)
      final penumbraPaint = Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - 65, cy + 10), 38, penumbraPaint);

      // Infarct core (irreversible crimson)
      final corePaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - 60, cy + 10), 16, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Brain3DFallbackPainter oldDelegate) {
    return oldDelegate.layer != layer ||
        oldDelegate.scenario != scenario ||
        oldDelegate.isThrombectomized != isThrombectomized ||
        oldDelegate.isCoiled != isCoiled;
  }
}
