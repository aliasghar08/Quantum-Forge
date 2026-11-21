// ============================================================================
// DentoLab 3D: Micro-Anatomical Dental & Maxillofacial 3D Viewport
// ----------------------------------------------------------------------------
// Dual-mode rendering: hardware-accelerated WebGL Three.js DentoLabThreeEngine
// on Flutter Web, paired with procedural vector CustomPainter for tests & mobile.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/dental_models.dart';
import 'dental_three_engine.dart';
import 'dental_full_screen_theater.dart';

class Dental3DViewport extends StatefulWidget {
  final DentalLayerMode selectedLayer;
  final ValueChanged<DentalLayerMode>? onLayerChanged;
  final int selectedToothNumber;
  final ValueChanged<int>? onToothSelected;
  final EndoRctStep rctStep;
  final ImplantStep implantStep;
  final ValueChanged<EndoRctStep>? onRctStepChanged;
  final ValueChanged<ImplantStep>? onImplantStepChanged;

  const Dental3DViewport({
    super.key,
    this.selectedLayer = DentalLayerMode.all,
    this.onLayerChanged,
    this.selectedToothNumber = 19,
    this.onToothSelected,
    this.rctStep = EndoRctStep.none,
    this.implantStep = ImplantStep.none,
    this.onRctStepChanged,
    this.onImplantStepChanged,
  });

  @override
  State<Dental3DViewport> createState() => _Dental3DViewportState();
}

class _Dental3DViewportState extends State<Dental3DViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  DentoLabThreeBridge? _threeBridge;
  double _cutawayDepth = 0.0;
  bool _showLabels = true;
  String? _selectedLandmarkId;
  double _rotationX = 0.2;
  double _rotationY = -0.3;
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    DentoLabThreeBridge.ensureViewFactories();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _syncBridge() {
    if (_threeBridge == null) return;
    _threeBridge!.setViewMode(widget.selectedLayer.keyName);
    _threeBridge!.setSelectedTooth(widget.selectedToothNumber);
    _threeBridge!.setCutaway(_cutawayDepth);
    _threeBridge!.setShowLabels(_showLabels);
    if (widget.rctStep != EndoRctStep.none) {
      _threeBridge!.setIntervention('rct', widget.rctStep.keyName);
    } else if (widget.implantStep != ImplantStep.none) {
      _threeBridge!.setIntervention('implant', widget.implantStep.keyName);
    } else {
      _threeBridge!.setIntervention('none', 'none');
    }
  }

  void _openFullScreenTheater() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, anim, secAnim) => DentalFullScreenTheater(
          initialLayer: widget.selectedLayer,
          initialToothNumber: widget.selectedToothNumber,
          initialRctStep: widget.rctStep,
          initialImplantStep: widget.implantStep,
        ),
        transitionsBuilder: (ctx, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showPearlDialog(ProjectedDentalLandmark lm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lm.name,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CATEGORY: ${lm.category.toUpperCase()}',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'BDS / DDS / INBDE Clinical Board Pearl:',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              lm.clinicalPearl,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (_threeBridge != null) {
                _threeBridge!.focusLandmark(lm.id);
              }
            },
            child: const Text('Focus Camera 3D', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            child: const Text('Close', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncBridge();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. Interactive 3D WebGL / Vector Viewport
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) => _lastPanPos = details.localPosition,
                onPanUpdate: (details) {
                  if (_lastPanPos == null) return;
                  final dx = details.localPosition.dx - _lastPanPos!.dx;
                  final dy = details.localPosition.dy - _lastPanPos!.dy;
                  _lastPanPos = details.localPosition;
                  setState(() {
                    _rotationY += dx * 0.01;
                    _rotationX = (_rotationX + dy * 0.01).clamp(-1.1, 1.1);
                  });
                },
                child: kIsWeb
                    ? HtmlElementView(
                        viewType: DentoLabThreeBridge.dentalViewType,
                        onPlatformViewCreated: (viewId) {
                          _threeBridge = DentoLabThreeBridge.forDentalView(viewId);
                          _syncBridge();
                        },
                      )
                    : CustomPaint(
                        painter: _DentalVectorPainter(
                          layer: widget.selectedLayer,
                          toothNumber: widget.selectedToothNumber,
                          cutawayDepth: _cutawayDepth,
                          rctStep: widget.rctStep,
                          implantStep: widget.implantStep,
                          rotX: _rotationX,
                          rotY: _rotationY,
                        ),
                      ),
              ),
            ),

            // 2. Projected 3D-to-2D Name Tags Overlay
            if (_showLabels)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, _) {
                      final landmarks = _threeBridge?.getProjectedLandmarks() ?? _getFallbackProjectedLandmarks();
                      return Stack(
                        children: landmarks.where((l) => l.visible).map((lm) {
                          final isSelected = lm.id == _selectedLandmarkId;
                          return Positioned(
                            left: lm.x - 30,
                            top: lm.y - 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedLandmarkId = lm.id);
                                _showPearlDialog(lm);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  lm.name,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

            // 3. Top Control Bar: Layer Switcher & Full Screen
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Layer Selector Chip Menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DentalLayerMode>(
                        value: widget.selectedLayer,
                        dropdownColor: const Color(0xFF0F172A),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8), size: 18),
                        items: DentalLayerMode.values.map((layer) {
                          return DropdownMenuItem(
                            value: layer,
                            child: Row(
                              children: [
                                Icon(layer.icon, size: 14, color: const Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  layer.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newLayer) {
                          if (newLayer != null && widget.onLayerChanged != null) {
                            widget.onLayerChanged!(newLayer);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Name Tags Toggle Chip
                  ActionChip(
                    backgroundColor: _showLabels
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                        : const Color(0xFF0F172A).withValues(alpha: 0.88),
                    side: BorderSide(
                      color: _showLabels ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                    ),
                    avatar: Icon(
                      Icons.label_outlined,
                      size: 13,
                      color: _showLabels ? const Color(0xFF38BDF8) : Colors.white60,
                    ),
                    label: Text(
                      '🏷️ Tags',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _showLabels ? const Color(0xFF38BDF8) : Colors.white70,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _showLabels = !_showLabels);
                      _threeBridge?.setShowLabels(_showLabels);
                    },
                  ),
                  const Spacer(),

                  // Full-Screen Theater Button
                  IconButton.filled(
                    tooltip: 'Expand Full-Screen Micro-Anatomical Theater',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF38BDF8), size: 18),
                    onPressed: _openFullScreenTheater,
                  ),
                ],
              ),
            ),

            // 4. Bottom Quick Controls: Cutaway Depth Slider & Active Intervention Badge
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_cut_rounded, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    const Text('Coronal Cutaway:', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF38BDF8),
                          inactiveTrackColor: const Color(0xFF334155),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _cutawayDepth,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            setState(() => _cutawayDepth = val);
                            _threeBridge?.setCutaway(val);
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${(_cutawayDepth * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),

                    // Active Step Indicator Badge
                    if (widget.rctStep != EndoRctStep.none)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Text(
                          widget.rctStep.label,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (widget.implantStep != ImplantStep.none)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          widget.implantStep.label,
                          style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
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

  List<ProjectedDentalLandmark> _getFallbackProjectedLandmarks() {
    return [
      const ProjectedDentalLandmark(
        id: 'enamel_19',
        name: 'Enamel Cap (#19)',
        category: 'enamel',
        x: 140,
        y: 110,
        normX: -0.4,
        normY: 0.2,
        depth: 0.5,
        visible: true,
        clinicalPearl: '96% inorganic hydroxyapatite. Critical demineralization threshold is pH 5.5.',
      ),
      const ProjectedDentalLandmark(
        id: 'pulp_chamber_19',
        name: 'Pulp Chamber (#19)',
        category: 'pulp',
        x: 180,
        y: 155,
        normX: -0.2,
        normY: 0.0,
        depth: 0.5,
        visible: true,
        clinicalPearl: 'Low-compliance chamber; acute edema leads to vascular strangulation.',
      ),
      const ProjectedDentalLandmark(
        id: 'ian_canal',
        name: 'Inferior Alveolar Nerve',
        category: 'nerve',
        x: 230,
        y: 240,
        normX: 0.1,
        normY: -0.3,
        depth: 0.5,
        visible: true,
        clinicalPearl: 'Trigeminal V3 branch. Requires >2mm vertical safety margin in implant osteotomy.',
      ),
      const ProjectedDentalLandmark(
        id: 'sinus_floor',
        name: 'Maxillary Sinus Floor',
        category: 'sinus',
        x: 210,
        y: 80,
        normX: 0.0,
        normY: 0.4,
        depth: 0.5,
        visible: true,
        clinicalPearl: 'Pneumatizes after molar extraction; residual bone <4mm requires sinus lift.',
      ),
    ];
  }
}

// ============================================================================
// Procedural Vector Fallback Painter (Flutter Canvas for Mobile / Tests)
// ============================================================================

class _DentalVectorPainter extends CustomPainter {
  final DentalLayerMode layer;
  final int toothNumber;
  final double cutawayDepth;
  final EndoRctStep rctStep;
  final ImplantStep implantStep;
  final double rotX;
  final double rotY;

  _DentalVectorPainter({
    required this.layer,
    required this.toothNumber,
    required this.cutawayDepth,
    required this.rctStep,
    required this.implantStep,
    required this.rotX,
    required this.rotY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw Jawbone Base Arches
    final bonePaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final archPath = Path();
    archPath.moveTo(cx - 120, cy + 60);
    archPath.quadraticBezierTo(cx, cy + 120, cx + 120, cy + 60);
    canvas.drawPath(archPath, bonePaint);

    final upperArchPath = Path();
    upperArchPath.moveTo(cx - 120, cy - 60);
    upperArchPath.quadraticBezierTo(cx, cy - 120, cx + 120, cy - 60);
    canvas.drawPath(upperArchPath, bonePaint);

    // Draw Inferior Alveolar Nerve (Yellow Conduit)
    final nervePaint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final nervePath = Path();
    nervePath.moveTo(cx - 130, cy + 40);
    nervePath.cubicTo(cx - 80, cy + 85, cx + 30, cy + 85, cx + 130, cy + 40);
    canvas.drawPath(nervePath, nervePaint);

    // Draw Representative Mandibular Molar (#19) at center-left
    final toothCenter = Offset(cx - 50, cy + 30);

    // 1. Enamel Crown
    final crownPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final crownRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: toothCenter.translate(0, -18), width: 36, height: 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(crownRect, crownPaint);

    // 2. Dentin Core
    final dentinPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;
    final dentinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: toothCenter.translate(0, -18), width: 28, height: 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(dentinRect, dentinPaint);

    // 3. Roots (Mesial & Distal)
    final rootPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawLine(toothCenter.translate(-8, -5), toothCenter.translate(-14, 40), rootPaint);
    canvas.drawLine(toothCenter.translate(8, -5), toothCenter.translate(14, 40), rootPaint);

    // 4. Pulp Chamber & Root Canals (Crimson / Pink)
    final pulpPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (rctStep == EndoRctStep.file) ? 3 : 2;
    canvas.drawLine(toothCenter.translate(-8, -15), toothCenter.translate(-14, 38), pulpPaint);
    canvas.drawLine(toothCenter.translate(8, -15), toothCenter.translate(14, 38), pulpPaint);

    // Interventions rendering
    if (rctStep == EndoRctStep.obturate) {
      final gpPaint = Paint()
        ..color = const Color(0xFFF43F5E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawLine(toothCenter.translate(-8, -15), toothCenter.translate(-14, 38), gpPaint);
      canvas.drawLine(toothCenter.translate(8, -15), toothCenter.translate(14, 38), gpPaint);
    } else if (implantStep == ImplantStep.fixture || implantStep == ImplantStep.crown) {
      final tiPaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9;
      canvas.drawLine(Offset(cx + 40, cy + 5), Offset(cx + 40, cy + 45), tiPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DentalVectorPainter oldDelegate) {
    return oldDelegate.layer != layer ||
        oldDelegate.toothNumber != toothNumber ||
        oldDelegate.cutawayDepth != cutawayDepth ||
        oldDelegate.rctStep != rctStep ||
        oldDelegate.implantStep != implantStep ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY;
  }
}
