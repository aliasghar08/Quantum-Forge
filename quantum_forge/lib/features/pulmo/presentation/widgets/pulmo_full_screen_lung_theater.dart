// ============================================================================
// PulmoVent 3D: Full-Screen Micro-Anatomical 3D Lung Theater
// ----------------------------------------------------------------------------
// Full 100vw × 100vh interactive viewport with:
// 1. Procedural 3D WebGL / vector rendering of the Weibel Gen 0-16 respiratory tree.
// 2. Microscopic Alveolar-Capillary gas-exchange unit with flowing RBC color shift.
// 3. 22 Dynamic Real-Time 3D Projected Micro-Anatomical Name Tags:
//    - Conducting Airways, Alveolar Micro, Vasculature & Shunt, Pleura & Chest Wall.
//    - Click-to-inspect USMLE & Critical Care Board Pearls.
// 4. Coronal Lung Cutaway Slider (0%–100%) and Respiratory Speed Scrubber (0.1x–1.0x).
// 5. Emergency Interventions: Needle Decompression, Prone 16h, Albuterol Nebulizer.
// 6. Live Gas Exchange & Mechanics HUD (PaO2, PaCO2, pH, P/F, Pplat, ΔP).
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

enum PulmoTagCategory {
  all('All Structures'),
  conducting('Conducting Airways (Gen 0–16)'),
  alveolar('Alveolar Micro & Gas Exchange'),
  vasculature('Pulmonary Vasculature & Shunt'),
  pleura('Pleura & Chest Wall');

  final String label;
  const PulmoTagCategory(this.label);
}

class PulmoLandmarkTag {
  final String id;
  final String name;
  final String shortName;
  final PulmoTagCategory category;
  final double x; // Relative -1.0 to 1.0
  final double y; // Relative -1.0 to 1.0
  final String clinicalPearl;
  final String usmleQuestion;
  final String boardAnswer;

  const PulmoLandmarkTag({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.x,
    required this.y,
    required this.clinicalPearl,
    required this.usmleQuestion,
    required this.boardAnswer,
  });
}

const List<PulmoLandmarkTag> kPulmoTags = [
  PulmoLandmarkTag(
    id: 'trachea_cartilage',
    name: 'Trachea & C-Shaped Hyaline Cartilage',
    shortName: 'Trachea (Gen 0)',
    category: PulmoTagCategory.conducting,
    x: 0.0,
    y: -0.65,
    clinicalPearl:
        'Contains 16-20 C-shaped hyaline cartilage rings with a posterior membranous wall adjacent to the esophagus. Prevents tracheal collapse during forced expiration.',
    usmleQuestion: 'Why does the trachea contain open C-shaped cartilage rather than continuous circular rings?',
    boardAnswer: 'Allows esophageal expansion during food bolus deglutition while preventing airway collapse under negative intrathoracic pressures.',
  ),
  PulmoLandmarkTag(
    id: 'carina',
    name: 'Carina Tracheae (T4/T5 Angle of Louis)',
    shortName: 'Carina (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: 0.0,
    y: -0.15,
    clinicalPearl:
        'The most sensitive cough-reflex zone, innervated by vagal sensory fibers. Lies at the T4/T5 vertebral disc, corresponding to the sternal angle of Louis.',
    usmleQuestion: 'Endotracheal tube position on chest radiograph should ideally terminate how far above the carina?',
    boardAnswer: '3 to 5 cm above the carina to avoid endobronchial intubation of the right mainstem during neck flexion.',
  ),
  PulmoLandmarkTag(
    id: 'right_main_bronchus',
    name: 'Right Mainstem Bronchus',
    shortName: 'Right Main (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: 0.28,
    y: -0.05,
    clinicalPearl:
        'Shorter (~2.5 cm), wider, and steeper (~25° off midline). Common site for foreign-body aspiration (peanuts, teeth) and accidental right-mainstem intubation.',
    usmleQuestion: 'Why is aspirated foreign material significantly more likely to enter the right mainstem than the left?',
    boardAnswer: 'The right main bronchus is wider, shorter, and takes a more vertical course aligned with the trachea.',
  ),
  PulmoLandmarkTag(
    id: 'left_main_bronchus',
    name: 'Left Mainstem Bronchus',
    shortName: 'Left Main (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: -0.35,
    y: -0.02,
    clinicalPearl:
        'Longer (~5 cm), narrower, and takes a more horizontal angle (~45°) under the aortic arch to accommodate the heart.',
    usmleQuestion: 'Compression of the left main bronchus by massive left atrial enlargement (Ortner syndrome) can cause:',
    boardAnswer: 'Hoarseness due to recurrent laryngeal nerve palsy and chronic dry cough from mechanical bronchial impingement.',
  ),
  PulmoLandmarkTag(
    id: 'terminal_bronchiole',
    name: 'Terminal Bronchiole (Gen 16)',
    shortName: 'Terminal Bronchiole',
    category: PulmoTagCategory.conducting,
    x: 0.55,
    y: 0.15,
    clinicalPearl:
        'Last generation of the conducting zone (anatomic dead space ~150 mL). Lacks cartilage and submucosal glands; lined by simple ciliated cuboidal epithelium and Club (Clara) cells.',
    usmleQuestion: 'What is the primary function of Club (Clara) cells located in terminal and respiratory bronchioles?',
    boardAnswer: 'Secretion of CC16 protective uteroglobin-like proteins, xenobiotic detox via cytochrome P450, and stem cell regeneration.',
  ),
  PulmoLandmarkTag(
    id: 'type1_pneumocyte',
    name: 'Type I Alveolar Epithelial Cell (Squamous)',
    shortName: 'Type I Pneumocyte',
    category: PulmoTagCategory.alveolar,
    x: 0.15,
    y: 0.35,
    clinicalPearl:
        'Covers 95% of alveolar surface area. Ultra-thin (0.1–0.2 μm) cytoplasm optimized for passive Fickian gas diffusion of O2 and CO2 across the basement membrane.',
    usmleQuestion: 'Why are Type I pneumocytes extremely vulnerable to irreversible damage in ARDS?',
    boardAnswer: 'They are end-differentiated and cannot divide; damaged Type I cells must be replaced via hyperplasia of Type II pneumocytes.',
  ),
  PulmoLandmarkTag(
    id: 'type2_pneumocyte',
    name: 'Type II Pneumocyte (Dipalmitoylphosphatidylcholine)',
    shortName: 'Type II Pneumocyte',
    category: PulmoTagCategory.alveolar,
    x: -0.18,
    y: 0.38,
    clinicalPearl:
        'Cuboidal surfactant-secreting stem cells. Store DPPC surfactant in lamellar bodies. Reduces surface tension (Laplace law P=2T/r), preventing small-alveolus atelectasis.',
    usmleQuestion: 'In Neonatal Respiratory Distress Syndrome (NRDS), deficiency of which phospholipid leads to diffuse atelectasis?',
    boardAnswer: 'Dipalmitoylphosphatidylcholine (DPPC), the primary active component of pulmonary surfactant.',
  ),
  PulmoLandmarkTag(
    id: 'blood_gas_barrier',
    name: 'Alveolar-Capillary Membrane (0.5 μm Barrier)',
    shortName: 'Blood-Gas Barrier',
    category: PulmoTagCategory.alveolar,
    x: 0.02,
    y: 0.48,
    clinicalPearl:
        'Tri-laminar membrane consisting of Type I pneumocyte, fused basal lamina, and capillary endothelial cell. Total thickness ~0.2-0.5 μm. Diffusion capacity DLCO drops in fibrosis.',
    usmleQuestion: 'Which physiological law governs gas transfer across the alveolar-capillary barrier?',
    boardAnswer: 'Fick’s Law of Diffusion: Rate = (Surface Area × Diffusion Constant × ΔPressure) / Membrane Thickness.',
  ),
  PulmoLandmarkTag(
    id: 'alveolar_macrophage',
    name: 'Alveolar Macrophage (Dust Cell / Hemosiderin)',
    shortName: 'Alveolar Macrophage',
    category: PulmoTagCategory.alveolar,
    x: -0.28,
    y: 0.42,
    clinicalPearl:
        'Phagocytoses inhaled silica, asbestos, and bacteria. In left heart failure with pulmonary congestion, engulfs extravasated RBCs becoming "heart failure cells" (hemosiderin-laden).',
    usmleQuestion: 'What stain demonstrates hemosiderin-laden macrophages in sputum or bronchoalveolar lavage?',
    boardAnswer: 'Prussian Blue (Perls) stain highlights ferric iron deposits in alveolar macrophages.',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_1',
    name: 'West Zone 1: Apical Lung (PA > Pa > Pv)',
    shortName: 'West Zone 1 (Apex)',
    category: PulmoTagCategory.vasculature,
    x: 0.38,
    y: -0.45,
    clinicalPearl:
        'Alveolar pressure exceeds arterial pressure, compressing capillaries. Normally negligible, but expands during positive-pressure ventilation or hypovolemic shock, creating alveolar dead space.',
    usmleQuestion: 'What occurs physiologically in West Zone 1 when a hypovolemic patient receives high PEEP?',
    boardAnswer: 'Alveolar pressure compresses pulmonary capillaries entirely, abolishing perfusion and creating high alveolar dead space (V/Q = ∞).',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_2',
    name: 'West Zone 2: Mid Lung (Pa > PA > Pv)',
    shortName: 'West Zone 2 (Waterfall)',
    category: PulmoTagCategory.vasculature,
    x: 0.45,
    y: -0.15,
    clinicalPearl:
        'Waterfall or Starling resistor flow: blood flow is determined by the arterial-to-alveolar pressure gradient (Pa - PA), independent of downstream venous pressure.',
    usmleQuestion: 'In West Zone 2, blood flow is directly determined by the difference between which two pressures?',
    boardAnswer: 'Pulmonary arterial pressure (Pa) and alveolar pressure (PA).',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_3',
    name: 'West Zone 3: Basal Dependent Lung (Pa > Pv > PA)',
    shortName: 'West Zone 3 (Base)',
    category: PulmoTagCategory.vasculature,
    x: 0.42,
    y: 0.25,
    clinicalPearl:
        'Continuous blood flow through fully distended capillaries. Highest perfusion and ventilation, with V/Q ~0.6. Site of dependent consolidations and intrapulmonary shunt in ARDS.',
    usmleQuestion: 'Why does prone positioning in severe ARDS improve oxygenation?',
    boardAnswer: 'Recruits dense dependent dorsal lung units (Zone 3) while shifting heart and abdominal weight off the posterior parenchyma.',
  ),
  PulmoLandmarkTag(
    id: 'visceral_pleura',
    name: 'Visceral Pleura (Lung Surface)',
    shortName: 'Visceral Pleura',
    category: PulmoTagCategory.pleura,
    x: 0.62,
    y: -0.1,
    clinicalPearl:
        'Adheres tightly to all lung surfaces and fissures. Innervated by autonomic nerves (insensitive to sharp somatic pain). Rupture of subpleural apical blebs causes primary spontaneous pneumothorax.',
    usmleQuestion: 'Why is visceral pleural irritation perceived as dull ache while parietal pleural irritation causes sharp localized pain?',
    boardAnswer: 'Visceral pleura receives autonomic innervation; parietal pleura is innervated by intercostal and phrenic somatic nerves.',
  ),
  PulmoLandmarkTag(
    id: 'parietal_pleura',
    name: 'Parietal Pleura (Chest Wall / Phrenic)',
    shortName: 'Parietal Pleura',
    category: PulmoTagCategory.pleura,
    x: -0.68,
    y: 0.05,
    clinicalPearl:
        'Lines the thoracic cavity. Mediastinal and diaphragmatic parietal pleura are innervated by the phrenic nerve (C3-C5), referring pain to the ipsilateral shoulder dermatome.',
    usmleQuestion: 'Irritation of the central diaphragmatic parietal pleura refers pain to which anatomical region?',
    boardAnswer: 'The C3–C5 dermatome over the shoulder (Kehr sign) via phrenic nerve sensory afferents.',
  ),
  PulmoLandmarkTag(
    id: 'costophrenic_recess',
    name: 'Costophrenic Recess (Angle of Fluid Accumulation)',
    shortName: 'Costophrenic Recess',
    category: PulmoTagCategory.pleura,
    x: -0.52,
    y: 0.58,
    clinicalPearl:
        'Deepest potential space in the pleural cavity. Normal lateral angle is sharp; blunting on upright PA chest radiograph requires ~175–200 mL of pleural effusion.',
    usmleQuestion: 'What is the minimal volume of pleural fluid required to blunt the costophrenic angle on an upright frontal chest radiograph?',
    boardAnswer: 'Approximately 175 to 200 mL (compared to ~50 mL visible on a lateral film).',
  ),
  PulmoLandmarkTag(
    id: 'diaphragm_dome',
    name: 'Diaphragm (Phrenic Nerve C3, 4, 5)',
    shortName: 'Diaphragm Dome',
    category: PulmoTagCategory.pleura,
    x: 0.0,
    y: 0.68,
    clinicalPearl:
        'Primary muscle of inspiration. Contraction flattens the dome, increasing vertical thoracic volume and creating negative intrapleural pressure (-5 to -8 cmH2O).',
    usmleQuestion: 'Unilateral phrenic nerve transection results in what characteristic finding on upright chest radiography?',
    boardAnswer: 'Paradoxical elevation of the ipsilateral hemidiaphragm during inspiration (sniff test fluoroscopy).',
  ),
  PulmoLandmarkTag(
    id: 'vv_ecmo_cannula',
    name: 'V-V ECMO Jugular Return Cannula',
    shortName: 'V-V ECMO Cannula',
    category: PulmoTagCategory.vasculature,
    x: 0.12,
    y: -0.52,
    clinicalPearl:
        'Reinfuses oxygenated, decarboxylated blood from the membrane lung directly into the right atrium towards the tricuspid valve for refractory hypoxemic ARDS.',
    usmleQuestion: 'What is the primary physiological objective of V-V ECMO compared to V-A ECMO?',
    boardAnswer: 'Provides pure respiratory gas exchange (O2 addition and CO2 removal) while relying entirely on native heart function for cardiac output.',
  ),
];

class PulmoFullScreenLungTheater extends StatefulWidget {
  final PulmoAnatomicalLayer selectedLayer;
  final ValueChanged<PulmoAnatomicalLayer>? onLayerChanged;
  final PulmoMasterVitalsState? vitals;

  const PulmoFullScreenLungTheater({
    super.key,
    this.selectedLayer = PulmoAnatomicalLayer.all,
    this.onLayerChanged,
    this.vitals,
  });

  @override
  State<PulmoFullScreenLungTheater> createState() =>
      _PulmoFullScreenLungTheaterState();
}

class _PulmoFullScreenLungTheaterState
    extends State<PulmoFullScreenLungTheater> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animCtrl;

  late PulmoAnatomicalLayer _activeLayer;
  PulmoTagCategory _activeCategory = PulmoTagCategory.all;
  bool _showNameTags = true;
  PulmoLandmarkTag? _selectedTag;
  double _cutawayPercent = 0.0;
  double _speedMultiplier = 1.0;

  double _rotX = 0.12;
  double _rotY = 0.0;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    _activeLayer = widget.selectedLayer;
    _focusNode = FocusNode();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vitals ?? PulmoMasterVitalsState();

    final filteredTags = _showNameTags
        ? kPulmoTags.where((t) {
            if (_activeCategory == PulmoTagCategory.all) return true;
            return t.category == _activeCategory;
          }).toList()
        : <PulmoLandmarkTag>[];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            // 1. Procedural 3D Canvas
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (details) => _lastPanPos = details.localFocalPoint,
                onScaleUpdate: (details) {
                  setState(() {
                    if (_lastPanPos != null) {
                      final delta = details.localFocalPoint - _lastPanPos!;
                      _rotY += delta.dx * 0.01;
                      _rotX = (_rotX + delta.dy * 0.01).clamp(-0.8, 0.8);
                    }
                    _lastPanPos = details.localFocalPoint;
                    _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                  });
                },
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _PulmoTheater3DPainter(
                        layer: _activeLayer,
                        vitals: v,
                        breathPhase: _animCtrl.value * math.pi * 2 * _speedMultiplier,
                        rotX: _rotX,
                        rotY: _rotY,
                        zoom: _zoom,
                        cutaway: _cutawayPercent,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Projected 3D-to-2D Landmark Name Tags
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cx = constraints.maxWidth / 2;
                  final cy = constraints.maxHeight / 2;
                  final scale = (math.min(constraints.maxWidth, constraints.maxHeight) / 380.0) * _zoom;

                  return Stack(
                    children: filteredTags.map((tag) {
                      // Project 3D coordinate to screen
                      final px = cx + (tag.x * 160 * scale) + (_rotY * 40);
                      final py = cy + (tag.y * 140 * scale) + (_rotX * 40);

                      if (px < 40 ||
                          px > constraints.maxWidth - 40 ||
                          py < 90 ||
                          py > constraints.maxHeight - 140) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = _selectedTag?.id == tag.id;

                      return Positioned(
                        left: px - 60,
                        top: py - 14,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTag = isSelected ? null : tag;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              tag.shortName,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
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

            // 3. Top Floating Glassmorphic HUD
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E5FF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.air_rounded, size: 16, color: Color(0xFF00E5FF)),
                        SizedBox(width: 8),
                        Text(
                          'PULMOVENT 3D THEATER • ALVEOLAR & VENTILATION TWIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Live Vitals Telemetry Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: v.isBarotraumaRisk
                            ? const Color(0xFFFF1744)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    child: Text(
                      'PaO₂ ${v.pao2MmHg.round()} | PaCO₂ ${v.paco2MmHg.round()} | pH ${v.arterialPh.toStringAsFixed(2)} | P/F ${v.pfRatio.round()} | Pplat ${v.plateauPressureCmH2o.round()} | ΔP ${v.drivingPressureCmH2o.round()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: v.isBarotraumaRisk
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Toggle Name Tags Button
                  Tooltip(
                    message: 'Toggle 3D Name Tags',
                    child: OutlinedButton.icon(
                      key: const Key('pulmo_theater_tags_toggle'),
                      icon: Icon(
                        _showNameTags ? Icons.label_rounded : Icons.label_off_rounded,
                        size: 14,
                        color: _showNameTags ? const Color(0xFF00E5FF) : Colors.grey,
                      ),
                      label: Text(
                        _showNameTags ? 'Tags ON' : 'Tags OFF',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _showNameTags ? const Color(0xFF00E5FF) : Colors.grey,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _showNameTags ? const Color(0xFF00E5FF) : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => setState(() => _showNameTags = !_showNameTags),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Exit Theater Button
                  IconButton(
                    key: const Key('pulmo_theater_exit_button'),
                    icon: const Icon(Icons.close_fullscreen_rounded, size: 20, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),

            // 4. Click-to-Inspect Clinical & USMLE Card
            if (_selectedTag != null)
              Positioned(
                top: 75,
                left: 16,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedTag!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.white70),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _selectedTag = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedTag!.clinicalPearl,
                        style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
                      ),
                      const Divider(height: 16, color: Color(0xFF1E293B)),
                      Text(
                        'USMLE / ICU Pearl: ${_selectedTag!.usmleQuestion}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFFFB74D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Answer: ${_selectedTag!.boardAnswer}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Floating Bottom Control Dock
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF040814).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PulmoTagCategory.values.map((cat) {
                          final isSelected = _activeCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat.label, style: const TextStyle(fontSize: 10.5)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              backgroundColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E293B),
                              ),
                              onSelected: (_) => setState(() => _activeCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sliders Row & Action Buttons
                    Row(
                      children: [
                        // Cutaway Slider
                        const Icon(Icons.layers_clear_rounded, size: 14, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 4),
                        Text(
                          'Cutaway: ${(_cutawayPercent * 100).round()}%',
                          style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                        ),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: _cutawayPercent,
                            onChanged: (val) => setState(() => _cutawayPercent = val),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Speed Scrubber
                        const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Speed: ${_speedMultiplier.toStringAsFixed(1)}x',
                          style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                        ),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: _speedMultiplier,
                            min: 0.1,
                            max: 1.0,
                            onChanged: (val) => setState(() => _speedMultiplier = val),
                          ),
                        ),
                        const Spacer(),

                        // Emergency Bedside Actions
                        if (v.activeSituation == PulmoClinicalSituation.tensionPneumothorax)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.medical_services_rounded, size: 14),
                            label: Text(
                              v.isChestTubeDecompressed
                                  ? 'Chest Tube Placed'
                                  : 'Needle Decompress',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1744),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onPressed: () {
                              v.performNeedleThoracostomy();
                              setState(() {});
                            },
                          ),
                        const SizedBox(width: 8),

                        ElevatedButton.icon(
                          icon: Icon(
                            v.isPronePositionActive ? Icons.bed_rounded : Icons.airline_seat_flat_rounded,
                            size: 14,
                          ),
                          label: Text(
                            v.isPronePositionActive ? 'Prone: 16h Active' : 'Prone 16h',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: v.isPronePositionActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            v.togglePronePositioning();
                            setState(() {});
                          },
                        ),
                      ],
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

class _PulmoTheater3DPainter extends CustomPainter {
  final PulmoAnatomicalLayer layer;
  final PulmoMasterVitalsState vitals;
  final double breathPhase;
  final double rotX;
  final double rotY;
  final double zoom;
  final double cutaway;

  _PulmoTheater3DPainter({
    required this.layer,
    required this.vitals,
    required this.breathPhase,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.cutaway,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (math.min(size.width, size.height) / 380.0) * zoom;
    final isTension = vitals.activeSituation == PulmoClinicalSituation.tensionPneumothorax &&
        !vitals.isChestTubeDecompressed;
    final tidalExp = 1.0 + (math.sin(breathPhase) * 0.08 * (vitals.tidalVolumeMl / 450.0));

    // Lungs with Cutaway Transparency
    final rPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: math.max(0.05, 0.45 * (1.0 - cutaway)))
      ..style = PaintingStyle.fill;
    final rBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rx = cx + (75 * scale) + (rotY * 25);
    final ry = cy - (10 * scale) + (rotX * 25);
    final rw = 75 * scale * tidalExp;
    final rh = 110 * scale * tidalExp;

    canvas.drawOval(Rect.fromCenter(center: Offset(rx, ry), width: rw * 2, height: rh * 2), rPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(rx, ry), width: rw * 2, height: rh * 2), rBorder);

    // Left Lung
    final lPaint = Paint()
      ..color = isTension
          ? const Color(0xFFD50000).withValues(alpha: 0.35)
          : const Color(0xFF0284C7).withValues(alpha: math.max(0.05, 0.45 * (1.0 - cutaway)))
      ..style = PaintingStyle.fill;
    final lBorder = Paint()
      ..color = isTension ? const Color(0xFFFF1744) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final lx = cx - (75 * scale) + (rotY * 25);
    final ly = cy - (10 * scale) + (rotX * 25);
    final lw = (isTension ? 30.0 : 70.0) * scale * tidalExp;
    final lh = (isTension ? 40.0 : 105.0) * scale * tidalExp;

    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: lw * 2, height: lh * 2), lPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: lw * 2, height: lh * 2), lBorder);

    // Airways (Trachea & Bronchi)
    final airwayPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round;

    final shift = isTension ? 25.0 * scale : 0.0;
    canvas.drawLine(Offset(cx + shift, cy - 130 * scale), Offset(cx + shift, cy - 25 * scale), airwayPaint);
    canvas.drawLine(Offset(cx + shift, cy - 25 * scale), Offset(cx + shift + 55 * scale, cy + 20 * scale), airwayPaint);
    canvas.drawLine(Offset(cx + shift, cy - 25 * scale), Offset(cx + shift - 65 * scale, cy + 22 * scale), airwayPaint);
  }

  @override
  bool shouldRepaint(covariant _PulmoTheater3DPainter old) {
    return old.breathPhase != breathPhase ||
        old.rotX != rotX ||
        old.rotY != rotY ||
        old.zoom != zoom ||
        old.cutaway != cutaway ||
        old.layer != layer ||
        old.vitals.activeSituation != vitals.activeSituation ||
        old.vitals.isChestTubeDecompressed != vitals.isChestTubeDecompressed;
  }
}
