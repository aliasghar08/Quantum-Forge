// ============================================================================
// NeuroLab 3D: Brain, Neurovascular & Spinal Cord Workstation
// ----------------------------------------------------------------------------
// Procedural Three.js WebGL & Multi-Channel Neuro-Electrophysiology Workstation.
// Features:
// 1. Permanent SaMD 7-Pillar Amber Legal Shield Banner
// 2. 3D Glassmorphic Brain, Ventricles, Circle of Willis & Full Spinal Cord
// 3. Biplane DSA Neuro-Angiography Viewport (AP Frontal vs Straight Lateral)
// 4. 5-Channel Neuro-ICU & IONM Phosphor Oscilloscope (EEG L/R, SSEP, MEP, ICP/CPP)
// 5. Axial Spinal Cord Tract Localizer (Dorsal Columns, Corticospinal, Spinothalamic)
// 6. Molecular Neuropharmacology Explorer (tPA, Levetiracetam, Nimodipine, Mannitol, L-DOPA)
// ============================================================================

import 'package:flutter/material.dart';
import '../features/neuro/data/neuro_pathology_models.dart';
import '../features/neuro/presentation/widgets/neuro_3d_brain_viewport.dart';
import '../features/neuro/presentation/widgets/neuro_dsa_viewport.dart';
import '../features/neuro/presentation/widgets/neuro_icu_oscilloscope_strip.dart';
import '../features/neuro/presentation/widgets/spinal_cord_localizer_panel.dart';
import '../features/neuro/presentation/widgets/neuro_clinical_info_system.dart';
import '../features/neuro/presentation/widgets/neuro_drug_mechanism_dialog.dart';

class NeuroLabScreen extends StatefulWidget {
  final String? initialScenarioId;

  const NeuroLabScreen({super.key, this.initialScenarioId});

  static Route<void> route({String? initialScenarioId}) {
    return MaterialPageRoute<void>(
      builder: (_) => NeuroLabScreen(initialScenarioId: initialScenarioId),
      settings: const RouteSettings(name: '/neuro'),
    );
  }

  @override
  State<NeuroLabScreen> createState() => _NeuroLabScreenState();
}

class _NeuroLabScreenState extends State<NeuroLabScreen> {
  late NeuroClinicalScenario _activeScenario;
  NeuroAnatomicalLayer _selectedLayer = NeuroAnatomicalLayer.all;
  DsaProjection _dsaProjection = DsaProjection.ap;
  late SpinalSyndrome _selectedSyndrome;
  late EegPattern _activeEegPattern;
  String _selectedSpineLevel = 'C5';

  bool _isThrombectomized = false;
  bool _isCoiled = false;
  int _activeViewportTab = 0; // 0 = 3D Brain/Spine, 1 = Biplane DSA

  @override
  void initState() {
    super.initState();
    if (widget.initialScenarioId != null) {
      _activeScenario = kNeuroScenarios.firstWhere(
        (s) => s.id == widget.initialScenarioId,
        orElse: () => kNeuroScenarios[0],
      );
    } else {
      _activeScenario = kNeuroScenarios[0]; // Default to Left M1 Stroke
    }
    _selectedSyndrome = _activeScenario.defaultSpineSyndrome;
    _activeEegPattern = _activeScenario.eegPattern;
  }

  void _switchScenario(NeuroClinicalScenario scenario) {
    setState(() {
      _activeScenario = scenario;
      _selectedSyndrome = scenario.defaultSpineSyndrome;
      _activeEegPattern = scenario.eegPattern;
      _isThrombectomized = false;
      _isCoiled = false;
    });
  }

  void _deployThrombectomy() {
    setState(() {
      _isThrombectomized = true;
      _activeEegPattern = EegPattern.normalAlpha;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 8),
            Text('Solitaire™ Stent-Retriever Deployed: TICI 3 Recanalization Achieved!'),
          ],
        ),
        backgroundColor: const Color(0xFF065F46),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deployCoils() {
    setState(() {
      _isCoiled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFFFFD740)),
            SizedBox(width: 8),
            Text('Axium™ Platinum Coils Packed: Complete Raymond-Roy I Aneurysm Occlusion!'),
          ],
        ),
        backgroundColor: const Color(0xFF78350F),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030508),
      body: SafeArea(
        child: Column(
          children: [
            // 1. SaMD 7-Pillar Legal Banner
            const NeuroBannerBar(),

            // 2. Workstation App Bar & Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0F1D),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    tooltip: 'Back to Dashboard',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEUROLAB 3D WORKSTATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Brain, Neurovascular & Spinal Cord In-Silico Simulator',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const NeuroInfoButton(topicId: 'circle_of_willis', size: 16),
                  const Spacer(),

                  // Molecular Neuropharmacology Dialog Trigger
                  ElevatedButton.icon(
                    icon: const Icon(Icons.medication_rounded, size: 14, color: Color(0xFF38BDF8)),
                    label: const Text('Neuropharmacology', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF38BDF8), width: 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const NeuroDrugMechanismDialog(),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 7-Pillar Shield Trigger
                  IconButton(
                    tooltip: 'SaMD 7-Pillar Regulatory Shield',
                    icon: const Icon(Icons.shield_rounded, color: Color(0xFFFFB74D), size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const NeuroLegalShieldDialog(),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Clinical Scenario Horizontal Switcher Bar
            Container(
              color: const Color(0xFF070B13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kNeuroScenarios.map((scenario) {
                    final isSel = scenario.id == _activeScenario.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 14,
                          color: isSel ? Colors.black : Colors.white60,
                        ),
                        label: Text(scenario.badge, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: scenario.badgeColor.withValues(alpha: 0.9),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) _switchScenario(scenario);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 4. Clinical Scenario Context Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _activeScenario.badgeColor.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: _activeScenario.badgeColor.withValues(alpha: 0.25))),
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _activeScenario.badgeColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _activeScenario.title,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _activeScenario.badgeColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Text(
                      _activeScenario.clinicalSummary,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: Text(
                      'Rx: ${_activeScenario.recommendedDrugMoa}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Main 2x2 Workstation Canvas
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column: 3D Brain & Biplane DSA
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                // Tab Switcher for Left Column
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildTabButton(
                                          title: '3D Brain & Spine Viewport',
                                          icon: Icons.view_in_ar_rounded,
                                          index: 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildTabButton(
                                          title: 'Biplane DSA Angiography',
                                          icon: Icons.lens_blur_rounded,
                                          index: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Viewport Canvas
                                Expanded(
                                  child: _activeViewportTab == 0
                                      ? Neuro3DBrainViewport(
                                          scenario: _activeScenario,
                                          selectedLayer: _selectedLayer,
                                          onLayerChanged: (l) => setState(() => _selectedLayer = l),
                                          isThrombectomized: _isThrombectomized,
                                          isCoiled: _isCoiled,
                                          onDeployThrombectomy: _deployThrombectomy,
                                          onDeployCoils: _deployCoils,
                                        )
                                      : NeuroDsaViewport(
                                          scenario: _activeScenario,
                                          projection: _dsaProjection,
                                          onProjectionChanged: (p) => setState(() => _dsaProjection = p),
                                          isThrombectomized: _isThrombectomized,
                                          isCoiled: _isCoiled,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right Column: Oscilloscope & Spinal Localizer
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                // Top Right: 5-Channel Neuro-ICU Monitor
                                Expanded(
                                  flex: 6,
                                  child: NeuroIcuOscilloscopeStrip(
                                    scenario: _activeScenario,
                                    spinalSyndrome: _selectedSyndrome,
                                    eegPattern: _activeEegPattern,
                                    onEegPatternChanged: (p) => setState(() => _activeEegPattern = p),
                                    isThrombectomized: _isThrombectomized,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Bottom Right: Spinal Cord Localizer
                                Expanded(
                                  flex: 5,
                                  child: SpinalCordLocalizerPanel(
                                    selectedSyndrome: _selectedSyndrome,
                                    onSyndromeChanged: (s) => setState(() => _selectedSyndrome = s),
                                    selectedLevel: _selectedSpineLevel,
                                    onLevelChanged: (lvl) => setState(() => _selectedSpineLevel = lvl),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Mobile / Narrow Stacked Layout
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 380,
                            child: Neuro3DBrainViewport(
                              scenario: _activeScenario,
                              selectedLayer: _selectedLayer,
                              onLayerChanged: (l) => setState(() => _selectedLayer = l),
                              isThrombectomized: _isThrombectomized,
                              isCoiled: _isCoiled,
                              onDeployThrombectomy: _deployThrombectomy,
                              onDeployCoils: _deployCoils,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 320,
                            child: NeuroDsaViewport(
                              scenario: _activeScenario,
                              projection: _dsaProjection,
                              onProjectionChanged: (p) => setState(() => _dsaProjection = p),
                              isThrombectomized: _isThrombectomized,
                              isCoiled: _isCoiled,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 380,
                            child: NeuroIcuOscilloscopeStrip(
                              scenario: _activeScenario,
                              spinalSyndrome: _selectedSyndrome,
                              eegPattern: _activeEegPattern,
                              onEegPatternChanged: (p) => setState(() => _activeEegPattern = p),
                              isThrombectomized: _isThrombectomized,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 380,
                            child: SpinalCordLocalizerPanel(
                              selectedSyndrome: _selectedSyndrome,
                              onSyndromeChanged: (s) => setState(() => _selectedSyndrome = s),
                              selectedLevel: _selectedSpineLevel,
                              onLevelChanged: (lvl) => setState(() => _selectedSpineLevel = lvl),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSel = _activeViewportTab == index;
    return InkWell(
      onTap: () => setState(() => _activeViewportTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSel ? const Color(0xFF38BDF8) : Colors.white60),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : Colors.white60,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
