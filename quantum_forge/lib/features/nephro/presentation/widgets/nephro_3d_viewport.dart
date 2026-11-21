// ============================================================================
// NephroLab 3D: Glomerulus & Nephron 3D Viewport Widget
// ----------------------------------------------------------------------------
// Mounts hardware-accelerated WebGL Three.js NephroLabThreeViewer on Flutter Web,
// paired with custom mathematical vector CustomPainter fallback for tests & mobile.
// Synchronized with 120-frame physiological renal cycle and multi-species particles.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../clinical_core/data/multi_organ_patient_state.dart';
import 'nephro_three_engine.dart';
import 'nephro_full_screen_nephron_theater.dart';

enum NephronViewMode {
  all('Full Nephron & Vasculature'),
  glomerulus('Glomerulus & Arterioles'),
  tubules('Tubules, Loop & Collecting Duct');

  final String label;
  const NephronViewMode(this.label);
}

class Nephro3DViewport extends StatefulWidget {
  final NephronViewMode viewMode;
  final String? activeDrugTarget;
  final ValueChanged<NephronViewMode>? onViewModeChanged;
  final ValueChanged<String?>? onDrugSelected;
  final NephroMasterVitalsState? vitals;

  const Nephro3DViewport({
    super.key,
    this.viewMode = NephronViewMode.all,
    this.activeDrugTarget,
    this.onViewModeChanged,
    this.onDrugSelected,
    this.vitals,
  });

  @override
  State<Nephro3DViewport> createState() => _Nephro3DViewportState();
}

class _Nephro3DViewportState extends State<Nephro3DViewport> with SingleTickerProviderStateMixin {
  NephroLabThreeBridge? _threeBridge;
  NephroVisualRenderMode _visualMode = NephroVisualRenderMode.photorealistic;
  double _rotationY = 0.35;
  double _rotationX = 0.25;
  double _zoom = 1.0;
  Offset? _lastPanPos;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      NephroLabThreeBridge.ensureViewFactories();
    }

    _ticker = createTicker((elapsed) {
      if (_lastTick == Duration.zero) {
        _lastTick = elapsed;
        return;
      }
      final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
      _lastTick = elapsed;

      final v = widget.vitals;
      if (v != null && v.isPlaying) {
        v.advanceFrame(dt);
        _threeBridge?.setFrame(v.currentFrame, v.currentPhase.shortLabel);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Nephro3DViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewMode != oldWidget.viewMode) {
      _threeBridge?.setViewMode(widget.viewMode.name);
    }
    if (widget.activeDrugTarget != oldWidget.activeDrugTarget && widget.activeDrugTarget != null) {
      _threeBridge?.highlightDrugTarget(widget.activeDrugTarget!);
      _applyDrugVasomotorTone(widget.activeDrugTarget!);
    }
  }

  void _applyDrugVasomotorTone(String drugId) {
    if (drugId == 'dapagliflozin' || drugId == 'nsaid') {
      widget.vitals?.setVasomotorTone(afferentTone: 0.78, efferentTone: 1.0);
      _threeBridge?.setVasomotorTone(0.78, 1.0);
    } else if (drugId == 'lisinopril' || drugId == 'acei') {
      widget.vitals?.setVasomotorTone(afferentTone: 1.0, efferentTone: 1.28);
      _threeBridge?.setVasomotorTone(1.0, 1.28);
    } else {
      widget.vitals?.setVasomotorTone(afferentTone: 1.0, efferentTone: 1.0);
      _threeBridge?.setVasomotorTone(1.0, 1.0);
    }
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.35;
      _rotationX = 0.25;
      _zoom = 1.0;
    });
    _threeBridge?.resetCamera();
  }

  void _injectGfrTracer() {
    widget.vitals?.injectGfrTracer();
    _threeBridge?.injectGfrTracer();
  }

  void _openFullScreenTheater() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: NephroFullScreenNephronTheater(
              activeDrugTarget: widget.activeDrugTarget,
              onDrugSelected: widget.onDrugSelected,
              vitals: widget.vitals,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final vitals = widget.vitals;

    if (kIsWeb && _threeBridge == null) {
      _threeBridge = NephroLabThreeBridge.latestNephronBridge;
      if (_threeBridge != null) {
        _threeBridge!.setViewMode(widget.viewMode.name);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ── 3D Canvas / Viewport Layer ──────────────────────────────────
            Positioned.fill(
              child: kIsWeb && NephroLabThreeBridge.isSupported && !(_threeBridge?.hasFailed ?? false)
                  ? HtmlElementView(
                      viewType: NephroLabThreeBridge.nephronViewType,
                      onPlatformViewCreated: (int id) {
                        _threeBridge = NephroLabThreeBridge.forNephronView(id);
                        _threeBridge?.setViewMode(widget.viewMode.name);
                        _threeBridge?.setVisualRenderMode(_visualMode);
                        if (vitals != null) {
                          _threeBridge?.setFrame(vitals.currentFrame, vitals.currentPhase.shortLabel);
                          _threeBridge?.setPlaybackSpeed(vitals.playbackSpeed);
                          _threeBridge?.setLayerMode(vitals.layerMode.id);
                        }
                      },
                    )
                  : GestureDetector(
                      onScaleStart: (details) => _lastPanPos = details.focalPoint,
                      onScaleUpdate: (details) {
                        setState(() {
                          if (details.scale != 1.0) {
                            _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                          } else if (_lastPanPos != null) {
                            final delta = details.focalPoint - _lastPanPos!;
                            _rotationY += delta.dx * 0.012;
                            _rotationX = (_rotationX - delta.dy * 0.012).clamp(-math.pi / 2.5, math.pi / 2.5);
                          }
                          _lastPanPos = details.focalPoint;
                        });
                      },
                      onScaleEnd: (_) => _lastPanPos = null,
                      child: CustomPaint(
                        painter: _NephronFallbackPainter(
                          viewMode: widget.viewMode,
                          visualMode: _visualMode,
                          rotationY: _rotationY,
                          rotationX: _rotationX,
                          zoom: _zoom,
                          palette: palette,
                        ),
                      ),
                    ),
            ),

            // ── Top Header Bar ──────────────────────────────────────────────
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.biotech_rounded, size: 12, color: Color(0xFF00E5FF)),
                          SizedBox(width: 4),
                          Text(
                            'NEPHRON 3D | PROCEDURAL',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tracer Bolus Injection Button
                    InkWell(
                      key: const Key('nephro_inject_tracer_mini'),
                      onTap: _injectGfrTracer,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: vitals?.isTracerActive ?? false
                              ? const Color(0xFF00FF66).withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: vitals?.isTracerActive ?? false
                                ? const Color(0xFF00FF66)
                                : const Color(0xFF00FF66).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.science_rounded,
                              size: 11,
                              color: vitals?.isTracerActive ?? false
                                  ? const Color(0xFF00FF66)
                                  : const Color(0xFF00FF66).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vitals?.isTracerActive ?? false ? 'TRACER ACTIVE' : 'INJECT TRACER',
                              style: const TextStyle(
                                color: Color(0xFF00FF66),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Segmented Render Mode Switcher (Tissue | Glass | Schematic)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: NephroVisualRenderMode.values.map((vMode) {
                          final isSel = vMode == _visualMode;
                          return Tooltip(
                            message: '${vMode.label} Mode: ${vMode.description}',
                            child: GestureDetector(
                              key: Key('nephro_viewport_render_mode_${vMode.name}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() => _visualMode = vMode);
                                _threeBridge?.setVisualRenderMode(vMode);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: isSel
                                      ? Border.all(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(vMode.icon, style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 3),
                                    Text(
                                      vMode.label,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : Colors.white60,
                                        fontSize: 9,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      key: const Key('nephro_reset_camera'),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Reset 3D Camera',
                      onPressed: _resetCamera,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      key: const Key('launch_fullscreen_nephron_theater'),
                      icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF00E5FF), size: 18),
                      tooltip: 'Full-Screen Nephron Theater',
                      onPressed: _openFullScreenTheater,
                    ),
                  ],
                ),
              ),
            ),

            // ── View Mode Filter Chips & Phase Badge ────────────────────────
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vitals != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: vitals.currentPhase.accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: vitals.currentPhase.accentColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'Frame ${vitals.currentFrame}/120 • ${vitals.currentPhase.shortLabel}',
                        style: TextStyle(
                          color: vitals.currentPhase.accentColor,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: NephronViewMode.values.map((mode) {
                        final isSel = mode == widget.viewMode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            key: Key('nephron_mode_${mode.name}'),
                            onTap: () {
                              widget.onViewModeChanged?.call(mode);
                              _threeBridge?.setViewMode(mode.name);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                    : const Color(0xFF0A1124).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF1E293B),
                                  width: isSel ? 1.2 : 0.8,
                                ),
                              ),
                              child: Text(
                                mode.label,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
}

class _NephronFallbackPainter extends CustomPainter {
  final NephronViewMode viewMode;
  final NephroVisualRenderMode visualMode;
  final double rotationY;
  final double rotationX;
  final double zoom;
  final dynamic palette;

  _NephronFallbackPainter({
    required this.viewMode,
    this.visualMode = NephroVisualRenderMode.photorealistic,
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = math.min(size.width, size.height) * 0.35 * zoom;

    // Draw Bowman's Capsule & Glomerular Tuft
    if (viewMode == NephronViewMode.all || viewMode == NephronViewMode.glomerulus) {
      final capsuleColor = switch (visualMode) {
        NephroVisualRenderMode.photorealistic => const Color(0xFFE8B4B8),
        NephroVisualRenderMode.translucent => const Color(0xFF38BDF8),
        NephroVisualRenderMode.schematic => const Color(0xFF0284C7),
      };
      final capsulePaint = Paint()
        ..color = capsuleColor.withValues(alpha: visualMode == NephroVisualRenderMode.photorealistic ? 0.35 : 0.30)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - scale * 0.4, cy - scale * 0.4), scale * 0.28, capsulePaint);

      final tuftColor = switch (visualMode) {
        NephroVisualRenderMode.photorealistic => const Color(0xFF9E212B),
        NephroVisualRenderMode.translucent => const Color(0xFFEF4444),
        NephroVisualRenderMode.schematic => const Color(0xFFFF1744),
      };
      final tuftPaint = Paint()
        ..color = tuftColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(Offset(cx - scale * 0.4, cy - scale * 0.4), scale * 0.16, tuftPaint);

      // Afferent & Efferent
      final affColor = visualMode == NephroVisualRenderMode.photorealistic
          ? const Color(0xFFD32F2F)
          : const Color(0xFFEF4444);
      final effColor = visualMode == NephroVisualRenderMode.photorealistic
          ? const Color(0xFFFF7043)
          : const Color(0xFFF97316);
      final artPaint = Paint()
        ..color = affColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawLine(
        Offset(cx - scale * 0.8, cy - scale * 0.2),
        Offset(cx - scale * 0.4, cy - scale * 0.4),
        artPaint,
      );
      canvas.drawLine(
        Offset(cx - scale * 0.4, cy - scale * 0.4),
        Offset(cx - scale * 0.15, cy - scale * 0.6),
        artPaint..color = effColor,
      );
    }

    // Draw Tubules & Loop of Henle
    if (viewMode == NephronViewMode.all || viewMode == NephronViewMode.tubules) {
      // PCT
      final pctColor = switch (visualMode) {
        NephroVisualRenderMode.photorealistic => const Color(0xFFD97736),
        NephroVisualRenderMode.translucent => const Color(0xFFFFB300),
        NephroVisualRenderMode.schematic => const Color(0xFFF59E0B),
      };
      final pctPath = Path()
        ..moveTo(cx - scale * 0.3, cy - scale * 0.2)
        ..cubicTo(
          cx, cy - scale * 0.35,
          cx + scale * 0.1, cy - scale * 0.1,
          cx + scale * 0.2, cy,
        );
      canvas.drawPath(
        pctPath,
        Paint()
          ..color = pctColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round,
      );

      // Loop of Henle
      final henleColor = switch (visualMode) {
        NephroVisualRenderMode.photorealistic => const Color(0xFF4DD0E1),
        NephroVisualRenderMode.translucent => const Color(0xFF00E5FF),
        NephroVisualRenderMode.schematic => const Color(0xFF0288D1),
      };
      final henlePath = Path()
        ..moveTo(cx + scale * 0.2, cy)
        ..lineTo(cx + scale * 0.25, cy + scale * 0.7)
        ..quadraticBezierTo(cx + scale * 0.35, cy + scale * 0.85, cx + scale * 0.45, cy + scale * 0.7)
        ..lineTo(cx + scale * 0.5, cy - scale * 0.1);
      canvas.drawPath(
        henlePath,
        Paint()
          ..color = henleColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );

      // Collecting Duct
      final cdColor = switch (visualMode) {
        NephroVisualRenderMode.photorealistic => const Color(0xFF43A047),
        NephroVisualRenderMode.translucent => const Color(0xFF00E676),
        NephroVisualRenderMode.schematic => const Color(0xFF16A34A),
      };
      canvas.drawLine(
        Offset(cx + scale * 0.65, cy - scale * 0.6),
        Offset(cx + scale * 0.65, cy + scale * 0.8),
        Paint()
          ..color = cdColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NephronFallbackPainter old) =>
      old.viewMode != viewMode ||
      old.visualMode != visualMode ||
      old.rotationY != rotationY ||
      old.rotationX != rotationX ||
      old.zoom != zoom;
}
