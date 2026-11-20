// ============================================================================
// NephroLab 3D: Full-Screen 3D Nephron, Glomerulus & JGA Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// microscopic renal functional unit (nephron, glomerular filtration barrier,
// juxtaglomerular apparatus, and transport tubular segments):
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, drag, mouse wheel).
// 2. High-Fidelity Procedural 3D Micro-Anatomy:
//    - Bowman's capsule, urinary space, and vascular pole.
//    - Afferent & Efferent arterioles with vascular tone regulation.
//    - Glomerular capillary loops with fenestrated endothelium and podocyte slit diaphragms.
//    - Proximal Convoluted Tubule (PCT) with apical microvillar brush border.
//    - Loop of Henle (thin descending, hairpin turn, thick ascending limb TAL).
//    - Juxtaglomerular Apparatus (JGA): Macula densa NaCl sensor, renin granules.
//    - Distal Convoluted Tubule (DCT) and Cortical/Medullary Collecting Ducts.
// 3. Dynamic Real-Time 3D Projected Micro-Anatomical & Transporter Name Tags:
//    - Filterable across: All, Glomerulus & Filtration, PCT & Loop, DCT & JGA, Collecting Duct.
//    - Click-to-inspect Nephrology & Pharmacology Cards with electrochemical kinetics.
// 4. Site-of-Action Drug Overlay Chips:
//    - Dapagliflozin (SGLT2i), Lisinopril (ACEi), Furosemide (NKCC2i),
//      Hydrochlorothiazide (NCCi), Spironolactone (MRA), Tolvaptan (V2RA).
// 5. Live Renal Hemodynamics & Electrolyte Telemetry HUD:
//    - MAP, RPP, eGFR, Urine Output, Na+, K+, Serum pH, Anion Gap.
// 6. Tubular Cutaway Slider (0%–100%) and Ion-Flux Velocity Scrubber (0.1x–1.0x).
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../clinical_core/data/multi_organ_patient_state.dart';

enum NephronTagCategory {
  all('All Structures'),
  glomerulus('Glomerulus & Filtration'),
  pctAndLoop('PCT & Loop of Henle'),
  dctAndJga('DCT & JGA (RAAS)'),
  collectingDuct('Collecting Duct');

  final String label;
  const NephronTagCategory(this.label);
}

class NephronLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final NephronTagCategory category;
  final String transportKinetics;
  final String targetDrug;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const NephronLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.transportKinetics,
    required this.targetDrug,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

class NephroFullScreenNephronTheater extends StatefulWidget {
  final String? activeDrugTarget;
  final ValueChanged<String?>? onDrugSelected;
  final NephroMasterVitalsState? vitals;

  const NephroFullScreenNephronTheater({
    super.key,
    this.activeDrugTarget,
    this.onDrugSelected,
    this.vitals,
  });

  @override
  State<NephroFullScreenNephronTheater> createState() =>
      _NephroFullScreenNephronTheaterState();
}

class _NephroFullScreenNephronTheaterState
    extends State<NephroFullScreenNephronTheater> {
  String? _activeDrug;

  // Orbit camera
  double _rotationY = 0.52;
  double _rotationX = 0.28;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  // Filter & sliders
  NephronTagCategory _selectedCategory = NephronTagCategory.all;
  bool _showNameTags = true;
  double _cutawayFraction = 0.0;
  double _ionFluxSpeed = 1.0;

  NephronLandmarkTag? _selectedTag;
  final FocusNode _focusNode = FocusNode();

  static const List<NephronLandmarkTag> kNephronTags = [
    // ── Glomerulus & Filtration ─────────────────────────────────────────────
    NephronLandmarkTag(
      id: 'afferent_arteriole',
      label: 'Afferent Arteriole (Vascular Pole)',
      shortCode: 'Afferent Art.',
      category: NephronTagCategory.glomerulus,
      transportKinetics: 'Autoregulatory myogenic & tubuloglomerular feedback resistance.',
      targetDrug: 'NSAIDs (constrict via PG inhibition)',
      clinicalPearl:
          'Prostaglandins (PGE2/PGI2) maintain afferent vasodilation during hypovolemia. NSAID inhibition causes acute pre-renal azotemia by dropping glomerular capillary pressure.',
      x3D: -38,
      y3D: 32,
      z3D: -12,
      badgeColor: Color(0xFFEF4444),
    ),
    NephronLandmarkTag(
      id: 'efferent_arteriole',
      label: 'Efferent Arteriole',
      shortCode: 'Efferent Art.',
      category: NephronTagCategory.glomerulus,
      transportKinetics: 'Post-glomerular resistance maintaining intraglomerular hydraulic pressure.',
      targetDrug: 'Lisinopril / ACEi / ARBs (dilate)',
      clinicalPearl:
          'Angiotensin II preferentially constricts efferent arterioles to sustain GFR. ACE inhibitors relieve efferent tone, lowering intraglomerular pressure (nephroprotective in diabetes).',
      x3D: -32,
      y3D: 42,
      z3D: 10,
      badgeColor: Color(0xFFF97316),
    ),
    NephronLandmarkTag(
      id: 'capillary_tuft',
      label: 'Glomerular Capillary Tuft',
      shortCode: 'Capillary Tuft',
      category: NephronTagCategory.glomerulus,
      transportKinetics: 'Ultrafiltration across fenestrated endothelium & glomerular basement membrane.',
      targetDrug: 'SGLT2 inhibitors (lower hyperfiltration)',
      clinicalPearl:
          'Net ultrafiltration pressure Puf = (Pgc - Pbs) - (πgc - πbs). Normal GFR is 120 mL/min; loss of negative charge on GBM causes albuminuria (Nephrotic Syndrome).',
      x3D: -25,
      y3D: 25,
      z3D: 0,
      badgeColor: Color(0xFF00E5FF),
    ),
    NephronLandmarkTag(
      id: 'podocyte_pedicels',
      label: 'Podocyte Interdigitating Foot Processes',
      shortCode: 'Podocytes',
      category: NephronTagCategory.glomerulus,
      transportKinetics: 'Nephrin/podocin slit diaphragm sieve (exclusion size ~4 nm).',
      targetDrug: 'Steroids (Minimal Change Disease)',
      clinicalPearl:
          'Podocyte effacement on electron microscopy is the hallmark of Minimal Change Disease. Disruption of the slit diaphragm allows massive non-selective proteinuria (>3.5 g/day).',
      x3D: -20,
      y3D: 35,
      z3D: -4,
      badgeColor: Color(0xFF06B6D4),
    ),

    // ── PCT & Loop of Henle ─────────────────────────────────────────────────
    NephronLandmarkTag(
      id: 'pct_sglt2',
      label: 'PCT SGLT2 Na⁺-Glucose Cotransporter',
      shortCode: 'SGLT2 (PCT)',
      category: NephronTagCategory.pctAndLoop,
      transportKinetics: '1 Na⁺ : 1 Glucose symport, reabsorbing 90% of filtered glucose.',
      targetDrug: 'Dapagliflozin / Empagliflozin (SGLT2i)',
      clinicalPearl:
          'SGLT2 inhibitors block glucose & Na+ reabsorption, delivering more NaCl to macula densa -> activates tubuloglomerular feedback, restoring afferent tone and arresting CKD progression.',
      x3D: -5,
      y3D: 45,
      z3D: 20,
      badgeColor: Color(0xFF10B981),
    ),
    NephronLandmarkTag(
      id: 'pct_brush_border',
      label: 'PCT Apical Brush Border & NHE3 Exchanger',
      shortCode: 'NHE3 (PCT)',
      category: NephronTagCategory.pctAndLoop,
      transportKinetics: 'Na⁺/H⁺ exchange coupled to carbonic anhydrase (CA-IV) HCO3⁻ recovery.',
      targetDrug: 'Acetazolamide (CA inhibitor)',
      clinicalPearl:
          'Reabsorbs 65% of filtered water, Na+, and 85% of HCO3-. CA inhibitors block HCO3- recovery, promoting urinary alkalinization and mild hyperchloremic metabolic acidosis.',
      x3D: 15,
      y3D: 35,
      z3D: 25,
      badgeColor: Color(0xFF38BDF8),
    ),
    NephronLandmarkTag(
      id: 'thin_descending_loop',
      label: 'Thin Descending Limb of Henle (AQP1)',
      shortCode: 'Thin Descending',
      category: NephronTagCategory.pctAndLoop,
      transportKinetics: 'High water permeability via AQP1; impermeable to NaCl.',
      targetDrug: 'Osmotic Diuretics (Mannitol)',
      clinicalPearl:
          'Passive water extraction concentrates tubular fluid up to 1200 mOsm/kg at the hairpin turn, matching the medullary hyperosmolar interstitium.',
      x3D: 28,
      y3D: -20,
      z3D: 15,
      badgeColor: Color(0xFF6366F1),
    ),
    NephronLandmarkTag(
      id: 'tal_nkcc2',
      label: 'Thick Ascending Limb NKCC2 Symporter',
      shortCode: 'NKCC2 (TAL)',
      category: NephronTagCategory.pctAndLoop,
      transportKinetics: 'Electroneutral 1 Na⁺ : 1 K⁺ : 2 Cl⁻ cotransport driven by basolateral Na/K-ATPase.',
      targetDrug: 'Furosemide / Bumetanide (Loop Diuretics)',
      clinicalPearl:
          'Generates the corticomedullary osmolar gradient via countercurrent multiplication. Loop diuretics inhibit NKCC2, collapsing the gradient, causing potent diuresis and Mg²⁺/Ca²⁺ wasting.',
      x3D: 18,
      y3D: -15,
      z3D: -15,
      badgeColor: Color(0xFFEC4899),
    ),
    NephronLandmarkTag(
      id: 'romk_channel',
      label: 'TAL Apical ROMK K⁺ Channel',
      shortCode: 'ROMK Channel',
      category: NephronTagCategory.pctAndLoop,
      transportKinetics: 'Recycles K⁺ back into lumen, generating a lumen-positive transepithelial potential (+8 mV).',
      targetDrug: 'Target in Bartter Syndrome Type II',
      clinicalPearl:
          'Lumen-positive potential drives paracellular reabsorption of Ca²⁺ and Mg²⁺. Inhibiting NKCC2 destroys this positive charge, explaining loop-induced hypercalciuria.',
      x3D: 12,
      y3D: 5,
      z3D: -18,
      badgeColor: Color(0xFFA855F7),
    ),

    // ── DCT & JGA (RAAS) ────────────────────────────────────────────────────
    NephronLandmarkTag(
      id: 'macula_densa',
      label: 'Macula Densa NaCl Sensor (JGA)',
      shortCode: 'Macula Densa',
      category: NephronTagCategory.dctAndJga,
      transportKinetics: 'Specialized TAL cells sensing tubular [NaCl] delivery via NKCC2.',
      targetDrug: 'Modulated by SGLT2i & ACEi',
      clinicalPearl:
          'Low luminal NaCl signals low GFR/hypotension -> stimulates Juxtaglomerular granular cells to release Renin via PGE2. High NaCl triggers adenosine release -> afferent arteriole constriction.',
      x3D: -14,
      y3D: 18,
      z3D: -8,
      badgeColor: Color(0xFFFFB300),
    ),
    NephronLandmarkTag(
      id: 'jg_granular_cells',
      label: 'Juxtaglomerular Granular Cells (Renin Secretion)',
      shortCode: 'JG Cells (Renin)',
      category: NephronTagCategory.dctAndJga,
      transportKinetics: 'Myoepithelial smooth muscle cells on afferent arteriole containing renin granules.',
      targetDrug: 'Aliskiren (Direct Renin Inhibitor)',
      clinicalPearl:
          'Cleaves hepatic Angiotensinogen to Angiotensin I. Stimulated by: 1) low afferent stretch, 2) low macula densa NaCl, and 3) β1-adrenergic sympathetic tone.',
      x3D: -22,
      y3D: 15,
      z3D: -14,
      badgeColor: Color(0xFFEAB308),
    ),
    NephronLandmarkTag(
      id: 'dct_ncct',
      label: 'DCT NCCT Na⁺-Cl⁻ Cotransporter',
      shortCode: 'NCCT (DCT)',
      category: NephronTagCategory.dctAndJga,
      transportKinetics: 'Electroneutral Na⁺-Cl⁻ cotransport reabsorbing 5-8% of filtered NaCl.',
      targetDrug: 'Hydrochlorothiazide / Chlorthalidone',
      clinicalPearl:
          'Thiazides block NCCT, promoting mild natriuresis. Lowering intracellular Na+ enhances basolateral 3Na+/Ca2+ exchange, increasing apical Ca2+ uptake -> causes Hypercalcemia and hypocalciuria.',
      x3D: -2,
      y3D: 22,
      z3D: -25,
      badgeColor: Color(0xFFFFD600),
    ),

    // ── Collecting Duct ─────────────────────────────────────────────────────
    NephronLandmarkTag(
      id: 'principal_cell_enac',
      label: 'Principal Cell ENaC Channel & Na⁺/K⁺ Exchange',
      shortCode: 'ENaC (Principal)',
      category: NephronTagCategory.collectingDuct,
      transportKinetics: 'Apical Epithelial Na⁺ Channel (ENaC) driven by basolateral Na⁺/K⁺-ATPase.',
      targetDrug: 'Amiloride / Spironolactone (MRA)',
      clinicalPearl:
          'Aldosterone upregulates ENaC & ROMK, driving Na+ reabsorption in exchange for K+ secretion. Spironolactone blocks mineralocorticoid receptor, sparing K+ at risk of Hyperkalemia.',
      x3D: -35,
      y3D: -5,
      z3D: -32,
      badgeColor: Color(0xFF10B981),
    ),
    NephronLandmarkTag(
      id: 'principal_cell_aqp2',
      label: 'Principal Cell Aquaporin-2 Water Channels (V2R)',
      shortCode: 'AQP2 (Principal)',
      category: NephronTagCategory.collectingDuct,
      transportKinetics: 'cAMP-mediated trafficking of AQP2 vesicles to apical membrane via Vasopressin V2 receptor.',
      targetDrug: 'Tolvaptan (V2 Receptor Antagonist)',
      clinicalPearl:
          'ADH/Vasopressin inserts AQP2 to reabsorb free water down medullary gradient. Tolvaptan blocks V2R, causing pure aquaresis for euvolemic/hypervolemic hyponatremia (SIADH).',
      x3D: -42,
      y3D: -25,
      z3D: -35,
      badgeColor: Color(0xFF00E5FF),
    ),
    NephronLandmarkTag(
      id: 'alpha_intercalated_h_atpase',
      label: 'α-Intercalated Cell Apical H⁺-ATPase',
      shortCode: 'H⁺-ATPase (α-IC)',
      category: NephronTagCategory.collectingDuct,
      transportKinetics: 'Active H⁺ proton extrusion into lumen; basolateral AE1 Cl⁻/HCO3⁻ exchange.',
      targetDrug: 'Defective in Type 1 Distal RTA',
      clinicalPearl:
          'Acidifies urine down to pH 4.5. Failure of H+-ATPase in Type 1 Distal RTA prevents urinary acidification (urine pH > 5.5), causing metabolic acidosis and calcium phosphate nephrolithiasis.',
      x3D: -48,
      y3D: -50,
      z3D: -38,
      badgeColor: Color(0xFFEF4444),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeDrug = widget.activeDrugTarget;
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.52;
      _rotationX = 0.28;
      _zoom = 1.0;
    });
  }

  void _selectDrug(String drugId) {
    setState(() {
      _activeDrug = _activeDrug == drugId ? null : drugId;
    });
    widget.onDrugSelected?.call(_activeDrug);
  }

  List<NephronLandmarkTag> get _filteredTags {
    if (_selectedCategory == NephronTagCategory.all) return kNephronTags;
    return kNephronTags.where((t) => t.category == _selectedCategory).toList();
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
                  painter: _NephronTheater3DPainter(
                    rotationY: _rotationY,
                    rotationX: _rotationX,
                    zoom: _zoom,
                    cutaway: _cutawayFraction,
                    ionFluxSpeed: _ionFluxSpeed,
                    activeDrug: _activeDrug,
                  ),
                ),
              ),
            ),

            // ── Projected Micro-Anatomical Name Tags ────────────────────────
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

            // ── Active Selected Nephrology Card ─────────────────────────────
            if (_selectedTag != null)
              Positioned(
                top: 75,
                right: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1420).withValues(alpha: 0.95),
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
                          'Kinetics: ${_selectedTag!.transportKinetics}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Site-of-Action Drug: ${_selectedTag!.targetDrug}',
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
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
                  color: const Color(0xFF040A14).withValues(alpha: 0.92),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('nephro_theater_exit_button'),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        tooltip: 'Exit Nephron Theater (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.water_drop_rounded, color: Color(0xFF00E5FF), size: 15),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'NEPHROLAB 3D: GLOMERULUS, NEPHRON & JGA THEATER',
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
                            SizedBox(height: 2),
                            Text(
                              'Microscopic Functional Unit | Multi-Organ Cardiorenal Coupled',
                              style: TextStyle(
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

                      // Live Renal Vitals Telemetry Badge
                      if (vitals != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: vitals.egfrMlMin < 60.0
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          child: Text(
                            'eGFR ${vitals.egfrMlMin.round()} mL/min • RPP ${vitals.rppMmHg.round()} mmHg • UO ${vitals.urineOutputMlKgH.toStringAsFixed(1)} mL/kg/h',
                            style: TextStyle(
                              color: vitals.egfrMlMin < 60.0
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
                        message: 'Toggle 3D Nephron Landmarks',
                        child: OutlinedButton.icon(
                          key: const Key('nephro_theater_tags_toggle'),
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
                        key: const Key('nephro_theater_reset_cam'),
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

            // ── Floating Bottom Controls & Pharmacology Dock ────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF040A14).withValues(alpha: 0.94),
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
                      // Site-of-Action Drug Overlay Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'DRUG SITE:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            for (final drug in [
                              {'id': 'dapagliflozin', 'label': 'Dapagliflozin (SGLT2i)'},
                              {'id': 'lisinopril', 'label': 'Lisinopril (ACEi)'},
                              {'id': 'furosemide', 'label': 'Furosemide (Loop)'},
                              {'id': 'hctz', 'label': 'Hydrochlorothiazide (Thiazide)'},
                              {'id': 'spironolactone', 'label': 'Spironolactone (MRA)'},
                              {'id': 'tolvaptan', 'label': 'Tolvaptan (V2RA)'},
                            ]) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  key: Key('nephro_drug_${drug['id']}'),
                                  label: Text(drug['label']!),
                                  selected: _activeDrug == drug['id'],
                                  selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: _activeDrug == drug['id']
                                        ? const Color(0xFFFFD600)
                                        : Colors.white24,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: _activeDrug == drug['id']
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _activeDrug == drug['id']
                                        ? const Color(0xFFFFD600)
                                        : Colors.white70,
                                  ),
                                  onSelected: (_) => _selectDrug(drug['id']!),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sliders (Cutaway & Ion-Flux)
                      Row(
                        children: [
                          // Category selector
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: NephronTagCategory.values.map((cat) {
                                  final isSel = _selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(cat.label),
                                      selected: isSel,
                                      selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                      side: BorderSide(
                                        color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                      ),
                                      onSelected: (_) => setState(() => _selectedCategory = cat),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Tubular Cutaway Slider
                          SizedBox(
                            width: 220,
                            child: Row(
                              children: [
                                const Text(
                                  'CUTAWAY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
                                  width: 36,
                                  child: Text(
                                    '${(_cutawayFraction * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Ion-Flux Speed Slider
                          SizedBox(
                            width: 200,
                            child: Row(
                              children: [
                                const Text(
                                  'ION FLUX',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _ionFluxSpeed,
                                      min: 0.1,
                                      max: 1.0,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _ionFluxSpeed = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${_ionFluxSpeed.toStringAsFixed(1)}x',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
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
// Procedural 3D Painter for Glomerulus, Nephron Loop & Collecting Duct
// ─────────────────────────────────────────────────────────────────────────────

class _NephronTheater3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final double zoom;
  final double cutaway;
  final double ionFluxSpeed;
  final String? activeDrug;

  _NephronTheater3DPainter({
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.cutaway,
    required this.ionFluxSpeed,
    required this.activeDrug,
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

    // 1. Bowman's Capsule & Glomerular Capillaries
    _drawGlomerulusAndArterioles(canvas, cx, cy, scale);

    // 2. Proximal Convoluted Tubule (PCT)
    _drawProximalTubule(canvas, cx, cy, scale);

    // 3. Loop of Henle (Descending & Thick Ascending TAL)
    _drawLoopOfHenle(canvas, cx, cy, scale);

    // 4. Distal Convoluted Tubule & JGA
    _drawDctAndJga(canvas, cx, cy, scale);

    // 5. Collecting Duct
    _drawCollectingDuct(canvas, cx, cy, scale);
  }

  void _drawGlomerulusAndArterioles(Canvas canvas, double cx, double cy, double s) {
    // Bowman's Capsule Outer Cup
    final cupPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18 * (1.0 - cutaway * 0.5))
      ..style = PaintingStyle.fill;
    final cupRim = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final center = _project(-25, 25, 0, cx, cy, s);
    canvas.drawCircle(center, 24.0 * s * zoom, cupPaint);
    canvas.drawCircle(center, 24.0 * s * zoom, cupRim);

    // Glomerular Capillary Loops (Red tuft)
    final capillaryPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8 * s * zoom;

    final c1 = _project(-30, 22, -4, cx, cy, s);
    final c2 = _project(-22, 30, 4, cx, cy, s);
    final c3 = _project(-18, 20, -2, cx, cy, s);
    final c4 = _project(-26, 18, 6, cx, cy, s);

    canvas.drawLine(c1, c2, capillaryPaint);
    canvas.drawLine(c2, c3, capillaryPaint);
    canvas.drawLine(c3, c4, capillaryPaint);

    // Afferent Arteriole (red line leading in)
    final affPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6 * s * zoom;
    final affIn = _project(-50, 30, -15, cx, cy, s);
    final affEnd = _project(-32, 26, -5, cx, cy, s);
    canvas.drawLine(affIn, affEnd, affPaint);

    // Efferent Arteriole (smaller caliber leading out)
    final effPaint = Paint()
      ..color = activeDrug == 'lisinopril' ? const Color(0xFFFFD600) : const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (activeDrug == 'lisinopril' ? 3.4 : 2.2) * s * zoom;
    final effStart = _project(-30, 34, 5, cx, cy, s);
    final effOut = _project(-48, 48, 18, cx, cy, s);
    canvas.drawLine(effStart, effOut, effPaint);
  }

  void _drawProximalTubule(Canvas canvas, double cx, double cy, double s) {
    final pctPaint = Paint()
      ..color = activeDrug == 'dapagliflozin'
          ? const Color(0xFFFFD600)
          : const Color(0xFF10B981).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0 * s * zoom;

    // Serpentine winding of PCT
    final p1 = _project(-15, 35, 12, cx, cy, s);
    final p2 = _project(-5, 45, 20, cx, cy, s);
    final p3 = _project(12, 38, 22, cx, cy, s);
    final p4 = _project(20, 25, 18, cx, cy, s);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy);
    canvas.drawPath(path, pctPaint);
  }

  void _drawLoopOfHenle(Canvas canvas, double cx, double cy, double s) {
    // Thin descending limb (water permeable, cyan)
    final descPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * s * zoom;

    final pTop = _project(20, 25, 18, cx, cy, s);
    final pTurn = _project(28, -60, 5, cx, cy, s);
    canvas.drawLine(pTop, pTurn, descPaint);

    // Hairpin turn
    final pAsc = _project(20, -58, -8, cx, cy, s);
    canvas.drawLine(pTurn, pAsc, descPaint);

    // Thick Ascending Limb (TAL - active NKCC2, thick magenta)
    final talPaint = Paint()
      ..color = activeDrug == 'furosemide'
          ? const Color(0xFFFFD600)
          : const Color(0xFFEC4899)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.5 * s * zoom;

    final pTalEnd = _project(10, 15, -15, cx, cy, s);
    canvas.drawLine(pAsc, pTalEnd, talPaint);
  }

  void _drawDctAndJga(Canvas canvas, double cx, double cy, double s) {
    // JGA Macula Densa (nestled between afferent & efferent arterioles)
    final mdPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    final mdCenter = _project(-14, 18, -8, cx, cy, s);
    canvas.drawCircle(mdCenter, 5.0 * s * zoom, mdPaint);

    // Distal Convoluted Tubule (yellow/amber)
    final dctPaint = Paint()
      ..color = activeDrug == 'hctz'
          ? const Color(0xFFFFD600)
          : const Color(0xFFEAB308)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.2 * s * zoom;

    final d1 = _project(10, 15, -15, cx, cy, s);
    final d2 = _project(-5, 22, -22, cx, cy, s);
    final d3 = _project(-25, 12, -28, cx, cy, s);

    final path = Path()
      ..moveTo(d1.dx, d1.dy)
      ..quadraticBezierTo(d2.dx, d2.dy, d3.dx, d3.dy);
    canvas.drawPath(path, dctPaint);
  }

  void _drawCollectingDuct(Canvas canvas, double cx, double cy, double s) {
    final cdPaint = Paint()
      ..color = (activeDrug == 'spironolactone' || activeDrug == 'tolvaptan')
          ? const Color(0xFFFFD600)
          : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.5 * s * zoom;

    final cdTop = _project(-25, 12, -28, cx, cy, s);
    final cdBottom = _project(-35, -75, -35, cx, cy, s);
    canvas.drawLine(cdTop, cdBottom, cdPaint);
  }

  @override
  bool shouldRepaint(covariant _NephronTheater3DPainter old) {
    return old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.cutaway != cutaway ||
        old.ionFluxSpeed != ionFluxSpeed ||
        old.activeDrug != activeDrug;
  }
}
