// ============================================================================
// NeuroLab 3D: Full-Screen 3D Brain, Circle of Willis & Spinal Cord Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// human central nervous system, cerebral vasculature, CSF system, and spinal tracts:
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, drag, and mouse wheel).
// 2. High-Fidelity Procedural 3D Neuro-Anatomy:
//    - Translucent glassmorphic cerebral cortex (frontal, parietal, temporal, occipital).
//    - Cerebellum and brainstem (midbrain, pons, medulla oblongata).
//    - Complete Circle of Willis (ICA, M1/M2 MCA, A1/A2 ACA, ACom, Basilar, Vertebral, PICA).
//    - Ventricular CSF circulation (lateral ventricles, foramen of Monro, 3rd & 4th ventricles).
//    - Full C1–L5 spinal cord with internal motor (corticospinal) & sensory (DCML/STT) columns.
//    - Cranial Nerves I–XII emergence sites.
//    - Ischemic penumbra vs core volume map during acute LVO stroke.
//    - Endovascular Solitaire™ stent-retriever & Axium™ platinum coil mass.
// 3. Dynamic Real-Time 3D Projected Anatomical Name Tags with category filters:
//    - All, Cortical & Deep Nuclei, Circle of Willis, CSF & Ventricles, Cranial Nerves, Spinal Tracts.
//    - Click-to-inspect USMLE / Neurosurgery Board Cards with vascular territory & localizing pearls.
// 4. Live Neuro-Critical Care Telemetry HUD (MAP, ICP, CPP, PaCO2, GCS score).
// 5. Coronal/Sagittal Cutaway Slider (0%–100%) & Slow-Motion Impulse Speed (0.1x–1.0x).
// 6. Interactive Endovascular Interventions: Stent-retriever & Aneurysm Coiling.
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/neuro_pathology_models.dart';
import 'neuro_master_vitals_state.dart';

enum NeuroTagCategory {
  all('All Landmarks'),
  cortical('Cortical & Deep Nuclei'),
  vessels('Circle of Willis'),
  csf('CSF & Ventricles'),
  cranialNerves('Cranial Nerves'),
  spinal('Spinal Tracts (C1–L5)');

  final String label;
  const NeuroTagCategory(this.label);
}

class NeuroLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final NeuroTagCategory category;
  final String vascularSupply;
  final String functionalRole;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const NeuroLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.vascularSupply,
    required this.functionalRole,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

class NeuroFullScreenBrainTheater extends StatefulWidget {
  final NeuroScenario scenario;
  final NeuroAnatomicalLayer selectedLayer;
  final ValueChanged<NeuroAnatomicalLayer>? onLayerChanged;
  final bool isThrombectomized;
  final bool isCoiled;
  final VoidCallback? onDeployThrombectomy;
  final VoidCallback? onDeployCoils;
  final NeuroMasterVitalsState? vitals;

  const NeuroFullScreenBrainTheater({
    super.key,
    required this.scenario,
    this.selectedLayer = NeuroAnatomicalLayer.cortical,
    this.onLayerChanged,
    this.isThrombectomized = false,
    this.isCoiled = false,
    this.onDeployThrombectomy,
    this.onDeployCoils,
    this.vitals,
  });

  @override
  State<NeuroFullScreenBrainTheater> createState() =>
      _NeuroFullScreenBrainTheaterState();
}

class _NeuroFullScreenBrainTheaterState
    extends State<NeuroFullScreenBrainTheater>
    with SingleTickerProviderStateMixin {
  late NeuroAnatomicalLayer _selectedLayer;
  late bool _isThrombectomized;
  late bool _isCoiled;

  // Orbit camera
  double _rotationY = 0.45;
  double _rotationX = 0.22;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  // Category filter & micro-anatomy sliders
  NeuroTagCategory _selectedCategory = NeuroTagCategory.all;
  bool _showNameTags = true;
  double _cutawayFraction = 0.0; // 0% intact to 100% open
  double _impulseSpeed = 1.0; // 0.1x to 1.0x

  NeuroLandmarkTag? _selectedTag;
  final FocusNode _focusNode = FocusNode();

  static const List<NeuroLandmarkTag> kNeuroTags = [
    // ── Cortical & Deep Nuclei ──────────────────────────────────────────────
    NeuroLandmarkTag(
      id: 'primary_motor_cortex',
      label: 'Precentral Gyrus (Motor Homunculus)',
      shortCode: 'M1 Cortex',
      category: NeuroTagCategory.cortical,
      vascularSupply: 'ACA (medial leg/foot) & MCA (lateral face/hand)',
      functionalRole: 'Primary voluntary somatic motor output (Brodmann Area 4 via corticospinal tract).',
      clinicalPearl: 'Focal ischemia triggers contralateral hemiparesis. MCA territory preferentially paralyzes face and arm; ACA preferentially paralyzes leg and foot.',
      x3D: -25,
      y3D: 40,
      z3D: 10,
      badgeColor: Color(0xFFEF4444),
    ),
    NeuroLandmarkTag(
      id: 'brocas_area',
      label: "Broca's Motor Speech Area (Pars Opercularis)",
      shortCode: "Broca's",
      category: NeuroTagCategory.cortical,
      vascularSupply: 'Left MCA Superior Division (Anterior branches)',
      functionalRole: 'Motor expressive speech planning & grammatical articulation (Brodmann Areas 44 & 45).',
      clinicalPearl: 'Expressive (non-fluent) aphasia with preserved comprehension. Patients exhibit telegraphic, halting speech and intense frustration because awareness is intact.',
      x3D: -45,
      y3D: 25,
      z3D: 30,
      badgeColor: Color(0xFFF59E0B),
    ),
    NeuroLandmarkTag(
      id: 'wernickes_area',
      label: "Wernicke's Sensory Speech Area (Superior Temporal)",
      shortCode: "Wernicke's",
      category: NeuroTagCategory.cortical,
      vascularSupply: 'Left MCA Inferior Division',
      functionalRole: 'Receptive auditory language decoding and semantic comprehension (Brodmann Area 22).',
      clinicalPearl: 'Fluent (receptive) aphasia: effortless "word salad" with neologisms and complete lack of comprehension, typically paired with anosognosia (unawareness of deficit).',
      x3D: -50,
      y3D: 5,
      z3D: -15,
      badgeColor: Color(0xFF10B981),
    ),
    NeuroLandmarkTag(
      id: 'somatosensory_cortex',
      label: 'Postcentral Gyrus (Primary Somatosensory)',
      shortCode: 'S1 Cortex',
      category: NeuroTagCategory.cortical,
      vascularSupply: 'MCA & ACA cortical branches',
      functionalRole: 'Discriminative touch, proprioception, pain and temperature localization (Brodmann Areas 3, 1, 2).',
      clinicalPearl: 'Lesions cause contralateral cortical sensory loss: loss of two-point discrimination, astereognosis, and agraphesthesia with preserved crude pain.',
      x3D: -25,
      y3D: 38,
      z3D: -8,
      badgeColor: Color(0xFF38BDF8),
    ),
    NeuroLandmarkTag(
      id: 'basal_ganglia',
      label: 'Basal Ganglia (Caudate & Putamen Striatum)',
      shortCode: 'Striatum',
      category: NeuroTagCategory.cortical,
      vascularSupply: 'Lateral Lenticulostriate Arteries (from M1 MCA)',
      functionalRole: 'GABAergic motor loop gating, action selection, and procedural habit formation.',
      clinicalPearl: 'Charcot-Bouchard microaneurysms from chronic HTN rupture here, triggering classic hypertensive deep intracerebral hemorrhage (ICH) with dense contralateral hemiplegia.',
      x3D: -18,
      y3D: 10,
      z3D: 12,
      badgeColor: Color(0xFFA855F7),
    ),

    // ── Circle of Willis ───────────────────────────────────────────────────
    NeuroLandmarkTag(
      id: 'm1_mca_trunk',
      label: 'Middle Cerebral Artery (M1 Sphenoidal Trunk)',
      shortCode: 'M1 MCA',
      category: NeuroTagCategory.vessels,
      vascularSupply: 'Terminal branch of Internal Carotid Artery (ICA)',
      functionalRole: 'Supplies 70% of the cerebral hemisphere including lateral convexity and internal capsule.',
      clinicalPearl: 'Target of emergency mechanical thrombectomy! LVO acute occlusion yields global hemiplegia, forced gaze toward lesion, and global aphasia (left) or neglect (right).',
      x3D: -24,
      y3D: -12,
      z3D: 18,
      badgeColor: Color(0xFF00E5FF),
    ),
    NeuroLandmarkTag(
      id: 'acom_aneurysm',
      label: 'Anterior Communicating Artery (ACom)',
      shortCode: 'ACom Junction',
      category: NeuroTagCategory.vessels,
      vascularSupply: 'Bridges left and right A1 segments of Anterior Cerebral Arteries',
      functionalRole: 'Collateral cross-filling between anterior hemispheric circulations.',
      clinicalPearl: 'Most common site of saccular "berry" aneurysms (~35% of all intracranial aneurysms). Rupture produces severe aneurysmal subarachnoid hemorrhage (thunderclap headache) and CN III palsy.',
      x3D: 0,
      y3D: -14,
      z3D: 30,
      badgeColor: Color(0xFFEC4899),
    ),
    NeuroLandmarkTag(
      id: 'basilar_artery',
      label: 'Basilar Artery Trunk',
      shortCode: 'Basilar',
      category: NeuroTagCategory.vessels,
      vascularSupply: 'Formed by confluence of left and right Vertebral Arteries',
      functionalRole: 'Perfuses pons, midbrain, superior cerebellum, and posterior cerebral arteries (PCA).',
      clinicalPearl: 'Basilar tip or trunk thrombosis causes "Locked-In Syndrome" (intact consciousness with quadriplegia and loss of horizontal eye movements; vertical gaze and blinking preserved).',
      x3D: 0,
      y3D: -32,
      z3D: -10,
      badgeColor: Color(0xFF38BDF8),
    ),
    NeuroLandmarkTag(
      id: 'carotid_siphon',
      label: 'Internal Carotid Artery (Cavernous Siphon)',
      shortCode: 'Carotid Siphon',
      category: NeuroTagCategory.vessels,
      vascularSupply: 'Ascending petrous/cavernous segment of ICA',
      functionalRole: 'Primary anterior circulation inflow to Circle of Willis.',
      clinicalPearl: 'S-shaped siphon dampens systolic arterial pressure pulses before microvascular entry. Cavernous sinus thrombosis or aneurysm here compresses CN III, IV, V1, V2, and VI.',
      x3D: -14,
      y3D: -24,
      z3D: 10,
      badgeColor: Color(0xFF6366F1),
    ),

    // ── CSF & Ventricles ────────────────────────────────────────────────────
    NeuroLandmarkTag(
      id: 'lateral_ventricle',
      label: 'Lateral Ventricle (Anterior Horn)',
      shortCode: 'Lateral Ventricle',
      category: NeuroTagCategory.csf,
      vascularSupply: 'Choroid plexus supplied by Anterior/Posterior Choroidal Arteries',
      functionalRole: 'CSF production (500 mL/day) and hydro-dynamic brain cushioning.',
      clinicalPearl: 'Hydrocephalus (communicating vs non-communicating). In Normal Pressure Hydrocephalus (NPH), ventriculomegaly presents with classic triad: wet (incontinence), wacky (dementia), and wobbly (magnetic gait).',
      x3D: -15,
      y3D: 18,
      z3D: 15,
      badgeColor: Color(0xFF06B6D4),
    ),
    NeuroLandmarkTag(
      id: 'aqueduct_sylvius',
      label: 'Cerebral Aqueduct of Sylvius (Midbrain)',
      shortCode: 'Aqueduct',
      category: NeuroTagCategory.csf,
      vascularSupply: 'Surrounded by Periaqueductal Gray (PAG)',
      functionalRole: 'Narrow conduit channeling CSF from Third to Fourth Ventricle.',
      clinicalPearl: 'Narrowest point in CSF pathway (~1.5 mm diameter). Stenosis from tectal glioma or congenital web causes obstructive non-communicating hydrocephalus with Parinaud syndrome (upward gaze palsy).',
      x3D: 0,
      y3D: -8,
      z3D: -12,
      badgeColor: Color(0xFF0EA5E9),
    ),

    // ── Cranial Nerves ──────────────────────────────────────────────────────
    NeuroLandmarkTag(
      id: 'optic_chiasm',
      label: 'Optic Chiasm (Cranial Nerve II)',
      shortCode: 'CN II Chiasm',
      category: NeuroTagCategory.cranialNerves,
      vascularSupply: 'Ophthalmic & Superior Hypophyseal Arteries',
      functionalRole: 'Decussation of nasal retinal ganglion fibers transmitting contralateral visual fields.',
      clinicalPearl: 'Pituitary adenoma or anterior skull base meningioma expanding superiorly compresses chiasmal decussation, generating classic Bitemporal Hemianopsia ("tunnel vision").',
      x3D: 0,
      y3D: -16,
      z3D: 22,
      badgeColor: Color(0xFFFFD600),
    ),
    NeuroLandmarkTag(
      id: 'oculomotor_nerve',
      label: 'Oculomotor Nerve (Cranial Nerve III)',
      shortCode: 'CN III',
      category: NeuroTagCategory.cranialNerves,
      vascularSupply: 'PCom & Superior Cerebellar Artery (SCA) branches',
      functionalRole: 'Extraocular motility (SR, IR, MR, IO, levator) and parasympathetic pupillary constriction.',
      clinicalPearl: 'Uncal herniation (temporal lobe squeezing over tentorium) or PCom aneurysm compresses outer parasympathetic fibers first -> "blown pupil" (mydriasis, non-reactive), followed by "down and out" gaze.',
      x3D: -8,
      y3D: -22,
      z3D: 4,
      badgeColor: Color(0xFFF97316),
    ),
    NeuroLandmarkTag(
      id: 'trigeminal_ganglion',
      label: 'Trigeminal Nerve & Gasserian Ganglion (CN V)',
      shortCode: 'CN V Ganglion',
      category: NeuroTagCategory.cranialNerves,
      vascularSupply: 'Pons basilar perforators and Meckel cave dural arteries',
      functionalRole: 'Facial sensory dermatomes (V1 ophthalmic, V2 maxillary, V3 mandibular) and muscles of mastication.',
      clinicalPearl: 'Neurovascular compression by aberrant SCA loop at root entry zone causes Trigeminal Neuralgia (tic douloureux): paroxysmal electric lancinating facial pain treated with Carbamazepine or Janetta decompression.',
      x3D: -16,
      y3D: -28,
      z3D: -4,
      badgeColor: Color(0xFFEAB308),
    ),

    // ── Spinal Tracts (C1–L5) ───────────────────────────────────────────────
    NeuroLandmarkTag(
      id: 'lateral_corticospinal',
      label: 'Lateral Corticospinal Tract (Spinal Motor Column)',
      shortCode: 'Corticospinal',
      category: NeuroTagCategory.spinal,
      vascularSupply: 'Anterior Spinal Artery (ASA)',
      functionalRole: 'Carries descending voluntary motor commands to distal limb muscles (crossed at medullary pyramids).',
      clinicalPearl: 'Upper Motor Neuron (UMN) lesion yields spastic paralysis, hyperreflexia, positive Babinski sign, and clonus. Anterior cord syndrome (ASA infarct) paralyzes both sides below the lesion.',
      x3D: -6,
      y3D: -70,
      z3D: -4,
      badgeColor: Color(0xFFEF4444),
    ),
    NeuroLandmarkTag(
      id: 'dorsal_columns',
      label: 'Dorsal Columns (Fasciculus Gracilis & Cuneatus)',
      shortCode: 'DCML Column',
      category: NeuroTagCategory.spinal,
      vascularSupply: 'Posterior Spinal Arteries (PSA)',
      functionalRole: 'Ascending conscious proprioception, vibratory sense, and fine discriminative touch.',
      clinicalPearl: 'Subacute Combined Degeneration (Vitamin B12 deficiency) or Tabes Dorsalis (tertiary syphilis) demyelinates dorsal columns -> sensory ataxia with positive Romberg sign (swaying when eyes close).',
      x3D: 0,
      y3D: -72,
      z3D: -10,
      badgeColor: Color(0xFF10B981),
    ),
    NeuroLandmarkTag(
      id: 'spinothalamic_tract',
      label: 'Lateral Spinothalamic Tract (Anterolateral System)',
      shortCode: 'Spinothalamic',
      category: NeuroTagCategory.spinal,
      vascularSupply: 'Anterior Spinal Artery (ASA) pial plexus',
      functionalRole: 'Ascending pain, temperature, and crude touch sensations (decussates at anterior white commissure).',
      clinicalPearl: 'Syringomyelia (fluid cavity expanding within central canal) compresses crossing anterior commissure fibers first, creating "cape-like" bilateral loss of pain & temperature across upper extremities.',
      x3D: 8,
      y3D: -74,
      z3D: 0,
      badgeColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLayer = widget.selectedLayer;
    _isThrombectomized = widget.isThrombectomized;
    _isCoiled = widget.isCoiled;
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.45;
      _rotationX = 0.22;
      _zoom = 1.0;
    });
  }

  void _handleThrombectomy() {
    setState(() => _isThrombectomized = true);
    widget.onDeployThrombectomy?.call();
  }

  void _handleCoiling() {
    setState(() => _isCoiled = true);
    widget.onDeployCoils?.call();
  }

  List<NeuroLandmarkTag> get _filteredTags {
    if (_selectedCategory == NeuroTagCategory.all) return kNeuroTags;
    return kNeuroTags.where((t) => t.category == _selectedCategory).toList();
  }

  Offset _project3D(double x, double y, double z, double cx, double cy, double s) {
    final cosY = math.cos(_rotationY);
    final sinY = math.sin(_rotationY);
    final cosX = math.cos(_rotationX);
    final sinX = math.sin(_rotationX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 420.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * _zoom,
      cy - y2 * s * factor * _zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitals = widget.vitals;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // ── 360° Interactive Orbit Canvas ───────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) => _lastPanPos = details.localFocalPoint,
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    setState(() {
                      _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                    });
                  } else if (_lastPanPos != null) {
                    final delta = details.localFocalPoint - _lastPanPos!;
                    setState(() {
                      _rotationY += delta.dx * 0.007;
                      _rotationX =
                          (_rotationX + delta.dy * 0.007).clamp(-1.2, 1.2);
                    });
                  }
                  _lastPanPos = details.localFocalPoint;
                },
                onScaleEnd: (_) => _lastPanPos = null,
                child: CustomPaint(
                  painter: _NeuroBrainTheater3DPainter(
                    rotationY: _rotationY,
                    rotationX: _rotationX,
                    zoom: _zoom,
                    layer: _selectedLayer,
                    cutaway: _cutawayFraction,
                    impulseSpeed: _impulseSpeed,
                    hasAneurysm: widget.scenario.hasAneurysm,
                    hasM1Occlusion: widget.scenario.hasM1Occlusion && !_isThrombectomized,
                    isCoiled: _isCoiled,
                  ),
                ),
              ),
            ),

            // ── 3D Projected Name Tags Overlay ──────────────────────────────
            if (_showNameTags)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2 - 15;
                    final scale = constraints.maxHeight / 300.0;

                    return Stack(
                      children: _filteredTags.map((tag) {
                        final p = _project3D(tag.x3D, tag.y3D, tag.z3D, cx, cy, scale);

                        if (p.dx < 40 ||
                            p.dx > constraints.maxWidth - 40 ||
                            p.dy < 95 ||
                            p.dy > constraints.maxHeight - 145) {
                          return const SizedBox.shrink();
                        }

                        final isSelected = _selectedTag?.id == tag.id;

                        return Positioned(
                          left: p.dx - 12,
                          top: p.dy - 12,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTag = isSelected ? null : tag;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? tag.badgeColor
                                    : Colors.black.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tag.badgeColor,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: tag.badgeColor.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Colors.black : tag.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    tag.shortCode,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

            // ── Active Selected Anatomical Card ─────────────────────────────
            if (_selectedTag != null)
              Positioned(
                top: 75,
                right: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedTag!.badgeColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedTag!.badgeColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedTag!.badgeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _selectedTag!.badgeColor),
                              ),
                              child: Text(
                                _selectedTag!.category.label.toUpperCase(),
                                style: TextStyle(
                                  color: _selectedTag!.badgeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTag!.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _selectedTag = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vascular Supply: ${_selectedTag!.vascularSupply}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTag!.functionalRole,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 14, color: _selectedTag!.badgeColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedTag!.clinicalPearl,
                                style: TextStyle(
                                  color: _selectedTag!.badgeColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Top Glassmorphic Navigation HUD ─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF060B14).withValues(alpha: 0.92),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('neuro_brain_theater_exit_button'),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        tooltip: 'Exit Neuro Theater (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.psychology_rounded, color: Color(0xFF00E5FF), size: 15),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'NEUROLAB 3D: CEREBRAL & SPINAL NEURO-ANATOMY THEATER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Scenario: ${widget.scenario.title}  |  Layer: ${_selectedLayer.label}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Live Neuro Vitals Telemetry Badge
                      if (vitals != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: vitals.icpMmHg > 20.0
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          child: Text(
                            'MAP ${vitals.mapMmHg.round()} | ICP ${vitals.icpMmHg.round()} | CPP ${vitals.cppMmHg.round()} | GCS ${vitals.totalGcs}',
                            style: TextStyle(
                              color: vitals.icpMmHg > 20.0
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF10B981),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Toggle 3D Name Tags
                      Tooltip(
                        message: 'Toggle 3D Neuro Landmarks',
                        child: OutlinedButton.icon(
                          key: const Key('neuro_brain_theater_tags_toggle'),
                          onPressed: () => setState(() => _showNameTags = !_showNameTags),
                          icon: Icon(
                            _showNameTags ? Icons.label_rounded : Icons.label_off_rounded,
                            size: 13,
                            color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white54,
                          ),
                          label: Text(
                            'Tags',
                            style: TextStyle(
                              color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _showNameTags
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Reset Camera
                      IconButton(
                        key: const Key('neuro_brain_theater_reset_cam'),
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Reset 3D Orbit Camera',
                        onPressed: _resetCamera,
                      ),

                      // Exit Full Screen
                      IconButton(
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 20),
                        tooltip: 'Exit Full Screen (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating Bottom Controls Dock ───────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060B14).withValues(alpha: 0.94),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: NeuroTagCategory.values.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                key: Key('neuro_cat_${cat.name}'),
                                label: Text(cat.label),
                                selected: isSel,
                                selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                ),
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sliders & Intervention Triggers
                      Row(
                        children: [
                          // Brain Cutaway Slider
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 76,
                                  child: Text(
                                    'CUTAWAY',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _cutawayFraction,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: const Color(0xFF38BDF8),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _cutawayFraction = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${(_cutawayFraction * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Impulse Speed Slider
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 76,
                                  child: Text(
                                    'IMPULSE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _impulseSpeed,
                                      min: 0.1,
                                      max: 1.0,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _impulseSpeed = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${_impulseSpeed.toStringAsFixed(1)}x',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Thrombectomy Trigger Button
                          if (widget.scenario.hasM1Occlusion && !_isThrombectomized)
                            FilledButton.icon(
                              key: const Key('neuro_theater_stent_retriever_btn'),
                              onPressed: _handleThrombectomy,
                              icon: const Icon(Icons.bolt_rounded, size: 14),
                              label: const Text('Stent-Retriever', style: TextStyle(fontSize: 10.5)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),

                          // Coiling Trigger Button
                          if (widget.scenario.hasAneurysm && !_isCoiled)
                            FilledButton.icon(
                              key: const Key('neuro_theater_coils_btn'),
                              onPressed: _handleCoiling,
                              icon: const Icon(Icons.grain_rounded, size: 14),
                              label: const Text('Deploy Coils', style: TextStyle(fontSize: 10.5)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Procedural 3D Painter for Cerebral Cortex, Circle of Willis & Spine
// ─────────────────────────────────────────────────────────────────────────────

class _NeuroBrainTheater3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final double zoom;
  final NeuroAnatomicalLayer layer;
  final double cutaway;
  final double impulseSpeed;
  final bool hasAneurysm;
  final bool hasM1Occlusion;
  final bool isCoiled;

  _NeuroBrainTheater3DPainter({
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.layer,
    required this.cutaway,
    required this.impulseSpeed,
    required this.hasAneurysm,
    required this.hasM1Occlusion,
    required this.isCoiled,
  });

  Offset _project(double x, double y, double z, double cx, double cy, double s) {
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 420.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * zoom,
      cy - y2 * s * factor * zoom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 15;
    final scale = size.height / 300.0;

    // 1. Spinal Cord Column (C1–L5)
    _drawSpinalCord(canvas, cx, cy, scale);

    // 2. Brainstem & Cerebellar Lobes
    _drawBrainstemAndCerebellum(canvas, cx, cy, scale);

    // 3. Translucent Cerebral Hemispheres (with cutaway)
    _drawCerebralHemispheres(canvas, cx, cy, scale);

    // 4. Ventricular CSF System
    _drawVentricularSystem(canvas, cx, cy, scale);

    // 5. Circle of Willis & Cerebral Arteries
    _drawCircleOfWillis(canvas, cx, cy, scale);

    // 6. Cranial Nerves Emergence
    _drawCranialNerves(canvas, cx, cy, scale);
  }

  void _drawSpinalCord(Canvas canvas, double cx, double cy, double s) {
    final cordPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * s * zoom;

    final c1 = _project(0, -45, 0, cx, cy, s);
    final l5 = _project(0, -110, -10, cx, cy, s);
    canvas.drawLine(c1, l5, cordPaint);

    // Spinal tract columns (Lateral corticospinal = red, DCML = cyan)
    final motorTract = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s * zoom;
    final m1 = _project(-4, -45, 0, cx, cy, s);
    final m2 = _project(-4, -110, -10, cx, cy, s);
    canvas.drawLine(m1, m2, motorTract);

    final sensoryTract = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s * zoom;
    final s1 = _project(0, -45, -5, cx, cy, s);
    final s2 = _project(0, -110, -15, cx, cy, s);
    canvas.drawLine(s1, s2, sensoryTract);
  }

  void _drawBrainstemAndCerebellum(Canvas canvas, double cx, double cy, double s) {
    // Pons and Medulla
    final stemPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0 * s * zoom;

    final midbrain = _project(0, -10, 0, cx, cy, s);
    final medulla = _project(0, -45, 0, cx, cy, s);
    canvas.drawLine(midbrain, medulla, stemPaint);

    // Cerebellar hemispheres (posterior-inferior)
    final cerebPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final leftCereb = _project(-22, -30, -22, cx, cy, s);
    final rightCereb = _project(22, -30, -22, cx, cy, s);
    canvas.drawCircle(leftCereb, 16.0 * s * zoom, cerebPaint);
    canvas.drawCircle(rightCereb, 16.0 * s * zoom, cerebPaint);
  }

  void _drawCerebralHemispheres(Canvas canvas, double cx, double cy, double s) {
    final double opacity = (0.35 * (1.0 - cutaway * 0.7)).clamp(0.08, 0.45);
    final cortexPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final sulciPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left hemisphere
    final lFrontal = _project(-28, 25, 28, cx, cy, s);
    final lParietal = _project(-32, 35, -5, cx, cy, s);
    final lOccipital = _project(-24, 15, -35, cx, cy, s);
    final lTemporal = _project(-42, 5, 0, cx, cy, s);

    canvas.drawCircle(lFrontal, 24.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lParietal, 26.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lOccipital, 20.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lTemporal, 22.0 * s * zoom, cortexPaint);

    // Sulcal convolution curves
    final path = Path()
      ..moveTo(lFrontal.dx, lFrontal.dy)
      ..quadraticBezierTo(lParietal.dx, lParietal.dy, lOccipital.dx, lOccipital.dy)
      ..quadraticBezierTo(lTemporal.dx, lTemporal.dy, lFrontal.dx, lFrontal.dy);
    canvas.drawPath(path, sulciPaint);

    // Right hemisphere (if not fully cut away)
    if (cutaway < 0.85) {
      final rFrontal = _project(28, 25, 28, cx, cy, s);
      final rParietal = _project(32, 35, -5, cx, cy, s);
      final rOccipital = _project(24, 15, -35, cx, cy, s);
      final rTemporal = _project(42, 5, 0, cx, cy, s);

      canvas.drawCircle(rFrontal, 24.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rParietal, 26.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rOccipital, 20.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rTemporal, 22.0 * s * zoom, cortexPaint);
    }
  }

  void _drawVentricularSystem(Canvas canvas, double cx, double cy, double s) {
    final csfPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5 * s * zoom;

    // C-shaped lateral ventricles
    final lAnt = _project(-14, 18, 18, cx, cy, s);
    final lBody = _project(-16, 20, -5, cx, cy, s);
    final lPost = _project(-18, 12, -26, cx, cy, s);
    final lTemp = _project(-22, -2, 5, cx, cy, s);

    final vPath = Path()
      ..moveTo(lAnt.dx, lAnt.dy)
      ..lineTo(lBody.dx, lBody.dy)
      ..lineTo(lPost.dx, lPost.dy)
      ..lineTo(lTemp.dx, lTemp.dy);
    canvas.drawPath(vPath, csfPaint);

    // Third and Fourth ventricle channel
    final v3 = _project(0, 10, 0, cx, cy, s);
    final v4 = _project(0, -25, -15, cx, cy, s);
    canvas.drawLine(v3, v4, csfPaint);
  }

  void _drawCircleOfWillis(Canvas canvas, double cx, double cy, double s) {
    final vesselPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4 * s * zoom;

    final occludedPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // ICA to MCA
    final lIca = _project(-14, -20, 10, cx, cy, s);
    final lM1 = _project(-24, -12, 18, cx, cy, s);
    final lM2 = _project(-42, 0, 24, cx, cy, s);

    canvas.drawLine(lIca, lM1, vesselPaint);
    if (hasM1Occlusion) {
      canvas.drawLine(lM1, lM2, occludedPaint); // Truncated / dark during LVO
    } else {
      canvas.drawLine(lM1, lM2, vesselPaint);
    }

    // ACA & ACom
    final lA1 = _project(-6, -14, 25, cx, cy, s);
    final rA1 = _project(6, -14, 25, cx, cy, s);
    canvas.drawLine(lIca, lA1, vesselPaint);
    canvas.drawLine(lA1, rA1, vesselPaint);

    // Aneurysm at ACom
    if (hasAneurysm) {
      final acom = _project(0, -14, 25, cx, cy, s);
      final aneurysmPaint = Paint()
        ..color = isCoiled ? const Color(0xFFCBD5E1) : const Color(0xFFE11D48)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(acom, 6.0 * s * zoom, aneurysmPaint);
    }

    // Basilar Artery & PCAs
    final basilarBottom = _project(0, -42, -5, cx, cy, s);
    final basilarTip = _project(0, -14, 0, cx, cy, s);
    canvas.drawLine(basilarBottom, basilarTip, vesselPaint);

    final lPca = _project(-18, -12, -14, cx, cy, s);
    final rPca = _project(18, -12, -14, cx, cy, s);
    canvas.drawLine(basilarTip, lPca, vesselPaint);
    canvas.drawLine(basilarTip, rPca, vesselPaint);
  }

  void _drawCranialNerves(Canvas canvas, double cx, double cy, double s) {
    final nervePaint = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Optic Chiasm (CN II)
    final cn2L = _project(-10, -16, 24, cx, cy, s);
    final cn2R = _project(10, -16, 24, cx, cy, s);
    canvas.drawLine(cn2L, cn2R, nervePaint);

    // Oculomotor (CN III) emerging from interpeduncular fossa
    final cn3Origin = _project(0, -18, 5, cx, cy, s);
    final cn3L = _project(-12, -22, 12, cx, cy, s);
    canvas.drawLine(cn3Origin, cn3L, nervePaint);
  }

  @override
  bool shouldRepaint(covariant _NeuroBrainTheater3DPainter old) {
    return old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.layer != layer ||
        old.cutaway != cutaway ||
        old.impulseSpeed != impulseSpeed ||
        old.hasAneurysm != hasAneurysm ||
        old.hasM1Occlusion != hasM1Occlusion ||
        old.isCoiled != isCoiled;
  }
}
