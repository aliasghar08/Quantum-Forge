// ============================================================================
// DentoLab 3D: Digital Dental Radiography & 3D CBCT Viewport
// ----------------------------------------------------------------------------
// High-resolution monochrome inverted X-ray engine providing:
// 1. 4 Imaging Projections: Periapical (PA), Bitewing (BW), Panoramic (OPG), 3D CBCT
// 2. Tube Head Angulation Sliders: Vertical (-20° to +20°) & Horizontal Angulation
// 3. Electronic Endodontic Working Length & Crestal Bone Loss Calipers (mm)
// 4. Radiopaque Gutta-Percha & Grade V Titanium Implant Contrast Display
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/dental_models.dart';
import 'dental_three_engine.dart';

class DentalRadiographyViewport extends StatefulWidget {
  final DentalRadiographyMode mode;
  final ValueChanged<DentalRadiographyMode>? onModeChanged;
  final EndoRctStep rctStep;
  final ImplantStep implantStep;
  final int toothNumber;

  const DentalRadiographyViewport({
    super.key,
    this.mode = DentalRadiographyMode.pa,
    this.onModeChanged,
    this.rctStep = EndoRctStep.none,
    this.implantStep = ImplantStep.none,
    this.toothNumber = 19,
  });

  @override
  State<DentalRadiographyViewport> createState() => _DentalRadiographyViewportState();
}

class _DentalRadiographyViewportState extends State<DentalRadiographyViewport> {
  DentoLabThreeBridge? _threeBridge;
  double _verticalAngle = 0.0; // -20 to +20
  final double _horizontalAngle = 0.0;
  bool _calipersEnabled = false;

  // Calipers (Normalized coordinates 0.0 to 1.0)
  Offset _caliperA = const Offset(0.48, 0.35); // Cusp tip
  Offset _caliperB = const Offset(0.45, 0.78); // Radiographic apex
  int? _activeCaliperDrag;

  @override
  void initState() {
    super.initState();
    DentoLabThreeBridge.ensureViewFactories();
  }

  void _syncBridge() {
    if (_threeBridge == null) return;
    _threeBridge!.setRadiographyMode(widget.mode.keyName);
    _threeBridge!.setTubeAngles(_verticalAngle, _horizontalAngle);
    if (widget.rctStep != EndoRctStep.none) {
      _threeBridge!.setIntervention('rct', widget.rctStep.keyName);
    } else if (widget.implantStep != ImplantStep.none) {
      _threeBridge!.setIntervention('implant', widget.implantStep.keyName);
    }
  }

  double _calculateDistanceMm() {
    // 1.0 normalized height roughly corresponds to 25.0 mm field of view in periapical PA
    final dx = (_caliperB.dx - _caliperA.dx) * 20.0;
    final dy = (_caliperB.dy - _caliperA.dy) * 25.0;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    _syncBridge();
    final distanceMm = _calculateDistanceMm();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050709),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. Monochrome X-Ray Viewport
            Positioned.fill(
              child: kIsWeb
                  ? HtmlElementView(
                      viewType: DentoLabThreeBridge.radiographyViewType,
                      onPlatformViewCreated: (viewId) {
                        _threeBridge = DentoLabThreeBridge.forRadiographyView(viewId);
                        _syncBridge();
                      },
                    )
                  : CustomPaint(
                      painter: _RadiographyVectorPainter(
                        mode: widget.mode,
                        rctStep: widget.rctStep,
                        implantStep: widget.implantStep,
                        verticalAngle: _verticalAngle,
                        horizontalAngle: _horizontalAngle,
                      ),
                    ),
            ),

            // 2. Electronic Working Length & Bone Calipers Overlay
            if (_calipersEnabled)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pA = Offset(_caliperA.dx * constraints.maxWidth, _caliperA.dy * constraints.maxHeight);
                    final pB = Offset(_caliperB.dx * constraints.maxWidth, _caliperB.dy * constraints.maxHeight);

                    return GestureDetector(
                      onPanStart: (details) {
                        final pos = details.localPosition;
                        if ((pos - pA).distance < 24) {
                          _activeCaliperDrag = 1;
                        } else if ((pos - pB).distance < 24) {
                          _activeCaliperDrag = 2;
                        } else {
                          _activeCaliperDrag = null;
                        }
                      },
                      onPanUpdate: (details) {
                        if (_activeCaliperDrag == 1) {
                          setState(() {
                            _caliperA = Offset(
                              (details.localPosition.dx / constraints.maxWidth).clamp(0.05, 0.95),
                              (details.localPosition.dy / constraints.maxHeight).clamp(0.05, 0.95),
                            );
                          });
                        } else if (_activeCaliperDrag == 2) {
                          setState(() {
                            _caliperB = Offset(
                              (details.localPosition.dx / constraints.maxWidth).clamp(0.05, 0.95),
                              (details.localPosition.dy / constraints.maxHeight).clamp(0.05, 0.95),
                            );
                          });
                        }
                      },
                      onPanEnd: (_) => _activeCaliperDrag = null,
                      child: CustomPaint(
                        painter: _CalipersPainter(pA: pA, pB: pB, distanceMm: distanceMm),
                      ),
                    );
                  },
                ),
              ),

            // 3. Top Mode Selector Bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DentalRadiographyMode>(
                        value: widget.mode,
                        dropdownColor: const Color(0xFF0F172A),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8), size: 18),
                        items: DentalRadiographyMode.values.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.label,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (newMode) {
                          if (newMode != null && widget.onModeChanged != null) {
                            widget.onModeChanged!(newMode);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Electronic Calipers Toggle Button
                  ActionChip(
                    backgroundColor: _calipersEnabled
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                        : const Color(0xFF0F172A).withValues(alpha: 0.88),
                    side: BorderSide(
                      color: _calipersEnabled ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                    ),
                    avatar: Icon(
                      Icons.straighten_rounded,
                      size: 13,
                      color: _calipersEnabled ? const Color(0xFF38BDF8) : Colors.white60,
                    ),
                    label: Text(
                      _calipersEnabled ? 'Calipers: ${distanceMm.toStringAsFixed(1)} mm' : 'Calipers',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _calipersEnabled ? const Color(0xFF38BDF8) : Colors.white70,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _calipersEnabled = !_calipersEnabled);
                    },
                  ),
                ],
              ),
            ),

            // 4. Bottom Tube Head Angulation Sliders
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    const Text('Vert Angle:', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          activeTrackColor: const Color(0xFF38BDF8),
                          inactiveTrackColor: const Color(0xFF334155),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _verticalAngle,
                          min: -20.0,
                          max: 20.0,
                          onChanged: (val) {
                            setState(() => _verticalAngle = val);
                            _threeBridge?.setTubeAngles(_verticalAngle, _horizontalAngle);
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${_verticalAngle.toInt()}°',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Electronic Calipers Overlay Painter
// ============================================================================

class _CalipersPainter extends CustomPainter {
  final Offset pA;
  final Offset pB;
  final double distanceMm;

  _CalipersPainter({required this.pA, required this.pB, required this.distanceMm});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Measurement Line
    canvas.drawLine(pA, pB, linePaint);

    // End-point Knobs
    canvas.drawCircle(pA, 6, dotPaint);
    canvas.drawCircle(pB, 6, dotPaint);

    // Midpoint Distance Label
    final mid = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
    final textSpan = TextSpan(
      text: ' ${distanceMm.toStringAsFixed(1)} mm ',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        backgroundColor: Color(0xFF38BDF8),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, mid.translate(-textPainter.width / 2, -14));
  }

  @override
  bool shouldRepaint(covariant _CalipersPainter old) {
    return old.pA != pA || old.pB != pB || old.distanceMm != distanceMm;
  }
}

// ============================================================================
// Fallback Monochrome X-Ray Vector Painter
// ============================================================================

class _RadiographyVectorPainter extends CustomPainter {
  final DentalRadiographyMode mode;
  final EndoRctStep rctStep;
  final ImplantStep implantStep;
  final double verticalAngle;
  final double horizontalAngle;

  _RadiographyVectorPainter({
    required this.mode,
    required this.rctStep,
    required this.implantStep,
    required this.verticalAngle,
    required this.horizontalAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background Bone Trabecular Radiopacity
    final bonePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bonePaint);

    // Tooth #19 Outline (Radiopaque White Enamel, Gray Dentin)
    final enamelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    final dentinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    // Crown
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 25), width: 50, height: 35), const Radius.circular(5)),
      enamelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 25), width: 40, height: 26), const Radius.circular(3)),
      dentinPaint,
    );

    // Root Dentin
    final rootPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawLine(Offset(cx - 12, cy - 5), Offset(cx - 16, cy + 55), rootPaint);
    canvas.drawLine(Offset(cx + 12, cy - 5), Offset(cx + 16, cy + 55), rootPaint);

    // Radiolucent Pulp Chamber & Canals (Dark)
    final pulpDarkPaint = Paint()
      ..color = const Color(0xFF050709)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx - 12, cy - 18), Offset(cx - 16, cy + 53), pulpDarkPaint);
    canvas.drawLine(Offset(cx + 12, cy - 18), Offset(cx + 16, cy + 53), pulpDarkPaint);

    // Radiopaque Gutta-Percha (Solid Dense White Line)
    if (rctStep == EndoRctStep.obturate) {
      final gpPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawLine(Offset(cx - 12, cy - 18), Offset(cx - 16, cy + 53), gpPaint);
      canvas.drawLine(Offset(cx + 12, cy - 18), Offset(cx + 16, cy + 53), gpPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiographyVectorPainter old) => true;
}
