// ============================================================================
// DentoLab 3D: Full-Screen Micro-Anatomical Tooth & Maxillofacial Theater
// ----------------------------------------------------------------------------
// Immersive full-screen clinical workstation featuring:
// 1. 360° Volumetric Orbit & Micro-Anatomical Zoom
// 2. Coronal & Sagittal Cutaway Slider (0%–100%) revealing Endodontic Pulp System
// 3. 32-Tooth Permanent Universal (#1–#32) & FDI Notation Switcher
// 4. 22+ Projected 3D Name Tags with Click-to-Inspect BDS/DDS/INBDE Clinical Cards
// 5. Permanent SaMD 7-Pillar Legal Shield Amber Banner
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/dental_models.dart';
import 'dental_three_engine.dart';

class DentalFullScreenTheater extends StatefulWidget {
  final DentalLayerMode initialLayer;
  final int initialToothNumber;
  final EndoRctStep initialRctStep;
  final ImplantStep initialImplantStep;

  const DentalFullScreenTheater({
    super.key,
    this.initialLayer = DentalLayerMode.all,
    this.initialToothNumber = 19,
    this.initialRctStep = EndoRctStep.none,
    this.initialImplantStep = ImplantStep.none,
  });

  @override
  State<DentalFullScreenTheater> createState() => _DentalFullScreenTheaterState();
}

class _DentalFullScreenTheaterState extends State<DentalFullScreenTheater>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  DentoLabThreeBridge? _threeBridge;
  late DentalLayerMode _selectedLayer;
  late int _selectedToothNumber;
  late EndoRctStep _rctStep;
  late ImplantStep _implantStep;
  double _cutawayDepth = 0.0;
  bool _showLabels = true;
  String? _selectedLandmarkId;
  ProjectedDentalLandmark? _inspectingLandmark;

  @override
  void initState() {
    super.initState();
    _selectedLayer = widget.initialLayer;
    _selectedToothNumber = widget.initialToothNumber;
    _rctStep = widget.initialRctStep;
    _implantStep = widget.initialImplantStep;

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
    _threeBridge!.setViewMode(_selectedLayer.keyName);
    _threeBridge!.setSelectedTooth(_selectedToothNumber);
    _threeBridge!.setCutaway(_cutawayDepth);
    _threeBridge!.setShowLabels(_showLabels);
    if (_rctStep != EndoRctStep.none) {
      _threeBridge!.setIntervention('rct', _rctStep.keyName);
    } else if (_implantStep != ImplantStep.none) {
      _threeBridge!.setIntervention('implant', _implantStep.keyName);
    } else {
      _threeBridge!.setIntervention('none', 'none');
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncBridge();
    final currentTooth = DentalToothDefinition.kAll32Teeth.firstWhere(
      (t) => t.universalNumber == _selectedToothNumber,
      orElse: () => DentalToothDefinition.kAll32Teeth[18],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020611),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 3D WebGL / Canvas Viewport
            Positioned.fill(
              child: kIsWeb
                  ? HtmlElementView(
                      viewType: DentoLabThreeBridge.fullScreenDentalViewType,
                      onPlatformViewCreated: (viewId) {
                        _threeBridge = DentoLabThreeBridge.forFullScreenDentalView(viewId);
                        _syncBridge();
                      },
                    )
                  : const Center(
                      child: Text(
                        'Full-Screen 3D Dental Theater (WebGL Active)',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
            ),

            // 2. Projected 3D-to-2D Name Tags
            if (_showLabels)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    final landmarks = _threeBridge?.getProjectedLandmarks() ?? [];
                    return Stack(
                      children: landmarks.where((l) => l.visible).map((lm) {
                        final isSelected = lm.id == _selectedLandmarkId;
                        return Positioned(
                          left: lm.x - 30,
                          top: lm.y - 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLandmarkId = lm.id;
                                _inspectingLandmark = lm;
                              });
                              _threeBridge?.focusLandmark(lm.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF0F172A).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isSelected ? Colors.white : const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                lm.name,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

            // 3. Permanent Amber SaMD 7-Pillar Legal Banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF78350F).withValues(alpha: 0.95),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFDE68A), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Educational Simulation Only — Not for Clinical Diagnosis, Treatment Planning, or Patient Care. Quantum Forge — A Product of Dart Nexus Lab.',
                        style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Header Navigation & Layer Bar
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Exit Full Screen Theater',
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85)),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DentoLab 3D: Micro-Anatomical Theater',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Universal #${currentTooth.universalNumber} (FDI ${currentTooth.fdiNotation}): ${currentTooth.name} • ${currentTooth.arch}',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Layer Mode Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DentalLayerMode>(
                        value: _selectedLayer,
                        dropdownColor: const Color(0xFF0F172A),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                        items: DentalLayerMode.values.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(l.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (newLayer) {
                          if (newLayer != null) {
                            setState(() => _selectedLayer = newLayer);
                            _threeBridge?.setViewMode(newLayer.keyName);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Toggle Name Tags
                  IconButton.filled(
                    tooltip: 'Toggle 3D Name Tags',
                    style: IconButton.styleFrom(
                      backgroundColor: _showLabels ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                    ),
                    icon: Icon(Icons.label_outlined, color: _showLabels ? const Color(0xFF0F172A) : Colors.white, size: 20),
                    onPressed: () {
                      setState(() => _showLabels = !_showLabels);
                      _threeBridge?.setShowLabels(_showLabels);
                    },
                  ),
                ],
              ),
            ),

            // 5. Bottom Controls: Tooth Selector & Cutaway Slider
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Universal Tooth Picker Carousel (#1 to #32)
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: DentalToothDefinition.kAll32Teeth.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final tooth = DentalToothDefinition.kAll32Teeth[i];
                          final isSelected = tooth.universalNumber == _selectedToothNumber;
                          return ChoiceChip(
                            selected: isSelected,
                            selectedColor: const Color(0xFF38BDF8),
                            backgroundColor: const Color(0xFF1E293B),
                            side: BorderSide(
                              color: isSelected ? Colors.white : Colors.transparent,
                            ),
                            label: Text(
                              '#${tooth.universalNumber} (${tooth.fdiNotation})',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() => _selectedToothNumber = tooth.universalNumber);
                              _threeBridge?.setSelectedTooth(tooth.universalNumber);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Coronal Cutaway Slider
                    Row(
                      children: [
                        const Icon(Icons.content_cut_rounded, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        const Text(
                          'Coronal Cutaway Depth:',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF38BDF8),
                              inactiveTrackColor: const Color(0xFF334155),
                              thumbColor: Colors.white,
                              trackHeight: 3.0,
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
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 6. Inspecting Landmark Bottom Sheet / Card
            if (_inspectingLandmark != null)
              Positioned(
                bottom: 110,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _inspectingLandmark!.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _inspectingLandmark!.clinicalPearl,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                        onPressed: () => setState(() => _inspectingLandmark = null),
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
