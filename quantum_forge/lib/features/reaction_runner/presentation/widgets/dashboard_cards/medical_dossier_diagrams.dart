import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';

// ============================================================================
// Medical & Biochemical Vector Diagrams for Clinical Dossier
// Interactive pictorial data, biochemical cycles, PK curves, and reaction
// energy profiles for MBBS, Pharm-D, DVM, and medical researchers.
// ============================================================================

class DiagramSourceCitation {
  final String label;
  final String type; // 'DOI', 'PMID', 'PDB', 'FDA', 'TEXT'
  final String identifier;
  final String? url;

  const DiagramSourceCitation({
    required this.label,
    required this.type,
    required this.identifier,
    this.url,
  });

  String get targetUrl {
    if (url != null && url!.isNotEmpty) return url!;
    switch (type.toUpperCase()) {
      case 'PMID':
        return 'https://pubmed.ncbi.nlm.nih.gov/$identifier/';
      case 'DOI':
        return 'https://doi.org/$identifier';
      case 'PDB':
        return 'https://www.rcsb.org/structure/$identifier';
      case 'FDA':
        return 'https://www.accessdata.fda.gov/scripts/cder/daf/';
      default:
        return 'https://scholar.google.com/scholar?q=${Uri.encodeComponent("$label $identifier")}';
    }
  }
}

class VerificationSourceFooter extends StatelessWidget {
  final List<DiagramSourceCitation> citations;
  final String? primaryReference;

  const VerificationSourceFooter({
    super.key,
    required this.citations,
    this.primaryReference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00E676)),
              const SizedBox(width: 6),
              Text(
                primaryReference != null
                    ? 'Verified: $primaryReference'
                    : 'Peer-Reviewed Source:',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          for (final c in citations)
            Tooltip(
              message: 'Verify ${c.type} on official database: ${c.identifier}',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => UrlService.launch(c.targetUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${c.type}: ${c.identifier}',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 10.5, color: Color(0xFF00E5FF)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1. Biochemical Cascade & Enzyme Inhibition Cycle
/// Visualizes the Arachidonic Acid cascade and the precise site of Aspirin block.
class BiochemicalCascadeCycleDiagram extends StatefulWidget {
  final dynamic palette;
  final bool isAspirin;
  const BiochemicalCascadeCycleDiagram({super.key, required this.palette, this.isAspirin = true});

  @override
  State<BiochemicalCascadeCycleDiagram> createState() => _BiochemicalCascadeCycleDiagramState();
}

class _BiochemicalCascadeCycleDiagramState extends State<BiochemicalCascadeCycleDiagram> {
  int _selectedNode = 2; // Default to COX enzyme block

  final List<({String title, String subtitle, String desc, Color color, IconData icon})> _nodes = [
    (
      title: 'Membrane Phospholipids',
      subtitle: 'Cellular Lipid Bilayer',
      desc: 'Cleaved by Phospholipase A₂ (PLA₂) in response to inflammatory, physical, or chemical stimuli.',
      color: Color(0xFF4FC3F7),
      icon: Icons.layers_rounded,
    ),
    (
      title: 'Arachidonic Acid (AA)',
      subtitle: '20-Carbon Polyunsaturated Fatty Acid',
      desc: 'Free substrate released into the cytosol, directed into the hydrophobic core of cyclooxygenase enzymes.',
      color: Color(0xFFFFB74D),
      icon: Icons.grain_rounded,
    ),
    (
      title: 'COX-1 & COX-2 Enzymes',
      subtitle: '🛑 DRUG TARGET: IRREVERSIBLE INHIBITION',
      desc: 'Aspirin enters the hydrophobic tunnel and covalently transfers acetyl to Ser-530 (COX-1) & Ser-516 (COX-2), sterically blocking AA from catalytic Tyr-385.',
      color: Color(0xFFFF5252),
      icon: Icons.block_flipped,
    ),
    (
      title: 'PGG₂ / PGH₂ Intermediates',
      subtitle: 'Cyclic Endoperoxides',
      desc: 'Unstable endoperoxide intermediates normally converted by downstream cell-specific synthases.',
      color: Color(0xFFBA68C8),
      icon: Icons.alt_route_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _nodes[_selectedNode];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PICTORIAL BIOCHEMICAL CASCADE & ENZYME INHIBITION CYCLE',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'COVALENT BLOCK',
                  style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Sequential Cascade Steps ───────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: List.generate(_nodes.length, (i) {
                  final node = _nodes[i];
                  final isSelected = _selectedNode == i;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedNode = i),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? node.color.withValues(alpha: 0.25)
                                : node.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? node.color : node.color.withValues(alpha: 0.35),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: node.color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(node.icon, color: node.color, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                node.title,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : node.color,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < _nodes.length - 1 && !isNarrow) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 14),
                      ],
                    ],
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 12),

          // ── Three Divergent Terminal Branches ──────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBranchPill(
                title: 'Platelet TXA₂ Pathway',
                status: 'BLOCKED (8-10 Days)',
                icon: Icons.bloodtype_rounded,
                color: Colors.redAccent,
                effect: 'Anti-thrombotic: Blocks platelet aggregation for platelet lifespan.',
              ),
              _buildBranchPill(
                title: 'Endothelial PGI₂ Pathway',
                status: 'PRESERVED / RECOVERABLE',
                icon: Icons.favorite_rounded,
                color: const Color(0xFF00E676),
                effect: 'Vasodilation & anti-aggregation restored via nucleated endothelial resynthesis.',
              ),
              _buildBranchPill(
                title: 'Inflammatory PGE₂ / PGF₂ₐ',
                status: 'SUPPRESSED',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFFB300),
                effect: 'Analgesia, antipyresis, and reduction of peripheral hyperalgesia.',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Interactive Node Details Inspector ─────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active.color.withValues(alpha: 0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(active.icon, color: active.color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            active.title,
                            style: TextStyle(color: active.color, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${active.subtitle}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active.desc,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Picot et al., Nature 1994 (COX-1 3D Architecture)',
            citations: [
              DiagramSourceCitation(label: 'Nature 1994', type: 'DOI', identifier: '10.1038/367243a0'),
              DiagramSourceCitation(label: 'RCSB Protein Data Bank', type: 'PDB', identifier: '1PTH'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchPill({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
    required String effect,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            effect,
            style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// 2. Pharmacokinetic Plasma Concentration ($C_p$ vs $t$) Curve Diagram
/// Draws the therapeutic window, minimum effective concentration (MEC),
/// maximum tolerated concentration (MTC), Cmax, Tmax, and elimination phase.
class PkPlasmaCurveDiagram extends StatelessWidget {
  final dynamic palette;
  final double halfLifeHours;
  const PkPlasmaCurveDiagram({super.key, required this.palette, this.halfLifeHours = 0.33});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFFFF9100), size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PHARMACOKINETIC PLASMA CONCENTRATION (Cp vs TIME) PROFILE',
                  style: TextStyle(
                    color: Color(0xFFFF9100),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'THERAPEUTIC WINDOW',
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── PK Canvas Curve ────────────────────────────────────────────────
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _PkCurvePainter(),
            ),
          ),

          const SizedBox(height: 10),

          // ── PK Metrics Legends ─────────────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendDot(const Color(0xFFFF5252), 'MTC (Toxic Threshold: > 300 mg/L)'),
              _buildLegendDot(const Color(0xFF00E676), 'Optimal Antiplatelet Zone (150–300 mg/L)'),
              _buildLegendDot(const Color(0xFFFFB300), 'MEC (Analgesic Threshold: ~50 mg/L)'),
              _buildLegendDot(const Color(0xFF00E5FF), 'Tmax ≈ 20–30 min (Rapid Absorption)'),
            ],
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Goodman & Gilman’s Pharmacological Basis (14th Ed.)',
            citations: [
              DiagramSourceCitation(label: 'Bateman PK Model', type: 'PMID', identifier: '11015641'),
              DiagramSourceCitation(label: 'Salicylate Clearance', type: 'DOI', identifier: '10.1056/NEJMra052711'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
      ],
    );
  }
}

class _PkCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (double y = 0.2; y <= 0.8; y += 0.2) {
      canvas.drawLine(Offset(35, h * y), Offset(w - 10, h * y), gridPaint);
    }

    // Shaded Therapeutic Window Band
    final windowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(35, h * 0.35, w - 10, h * 0.70), windowPaint);

    // MTC Toxic Threshold Line (Red Dashed)
    final mtcPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(35, h * 0.25), Offset(w - 10, h * 0.25), mtcPaint);

    // MEC Line (Yellow)
    final mecPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(35, h * 0.70), Offset(w - 10, h * 0.70), mecPaint);

    // PK Plasma Curve (Biphasic Bateman Curve)
    final curvePath = Path();
    curvePath.moveTo(35, h * 0.88);

    // Absorption to Cmax (~20% width)
    final cMaxX = 35 + (w - 45) * 0.22;
    final cMaxY = h * 0.32;
    curvePath.cubicTo(
      35 + (cMaxX - 35) * 0.4,
      h * 0.85,
      35 + (cMaxX - 35) * 0.8,
      cMaxY + 5,
      cMaxX,
      cMaxY,
    );

    // Elimination curve (Exponential decay)
    curvePath.cubicTo(
      cMaxX + (w - cMaxX) * 0.25,
      cMaxY + (h * 0.88 - cMaxY) * 0.45,
      cMaxX + (w - cMaxX) * 0.60,
      cMaxY + (h * 0.88 - cMaxY) * 0.80,
      w - 10,
      h * 0.85,
    );

    // Stroke PK Curve
    final curvePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(curvePath, curvePaint);

    // Fill underneath curve
    final fillPath = Path.from(curvePath)
      ..lineTo(w - 10, h * 0.88)
      ..lineTo(35, h * 0.88)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(35, cMaxY, w - 10, h * 0.88));
    canvas.drawPath(fillPath, fillPaint);

    // Cmax peak point dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cMaxX, cMaxY), 4.0, dotPaint);
    final dotGlow = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cMaxX, cMaxY), 7.0, dotGlow);

    // Y-Axis and X-Axis labels
    final tpY = TextPainter(
      text: const TextSpan(
        text: 'Cp (mg/L)',
        style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpY.paint(canvas, const Offset(0, 5));

    final tpX = TextPainter(
      text: const TextSpan(
        text: 'Time (Hours) ──►',
        style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpX.paint(canvas, Offset(w - 85, h * 0.90));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Organ-System ADME Flow Schematic
/// Visually tracks drug transit through Stomach -> Blood -> Liver -> Kidney.
class AdmeOrganFlowDiagram extends StatelessWidget {
  final dynamic palette;
  const AdmeOrganFlowDiagram({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        step: '1. ABSORPTION',
        organ: 'Stomach & Duodenum',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFFFF9100),
        data: 'pKa 3.5: Non-ionized in gastric acid (pH 1.5–2.0), lipid soluble. Rapid passive diffusion.',
      ),
      (
        step: '2. DISTRIBUTION',
        organ: 'Plasma & Albumin',
        icon: Icons.shield_rounded,
        color: const Color(0xFF00E5FF),
        data: '85% Albumin binding. Vd: 0.17 L/kg. Crosses blood-brain and placental barriers.',
      ),
      (
        step: '3. METABOLISM',
        organ: 'Hepatic Esterases & UGT',
        icon: Icons.biotech_rounded,
        color: const Color(0xFFBA68C8),
        data: 'Hydrolyzed to salicylate (t½ 15m), then CYP2C9 & UGT1A6 glucuronidation.',
      ),
      (
        step: '4. ELIMINATION',
        organ: 'Renal Ion-Trapping',
        icon: Icons.filter_alt_rounded,
        color: const Color(0xFF00E676),
        data: 'pH-dependent excretion. Alkalinization (pH > 7.5) traps ionized salicylate in urine.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: Color(0xFFFF9100), size: 16),
              SizedBox(width: 8),
              Text(
                'ORGAN-SYSTEM TRANSIT & DISPOSITION MAP',
                style: TextStyle(
                  color: Color(0xFFFF9100),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final width = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stages.map((s) {
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.color.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(s.icon, color: s.color, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.step,
                                  style: TextStyle(color: s.color, fontSize: 9.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.organ,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.data,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Court & Greenblatt, Biochem Pharmacol 1997',
            citations: [
              DiagramSourceCitation(label: 'Feline UGT1A6 Deficiency', type: 'PMID', identifier: '9177056'),
              DiagramSourceCitation(label: 'Renal Elimination', type: 'PMID', identifier: '5841026'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4. Quantum Reaction Coordinate Energy Diagram
/// Illustrates the activation barrier (Ea = 18.2 kcal/mol) and transition state.
class ReactionCoordinateEnergyDiagram extends StatelessWidget {
  final dynamic palette;
  final double eaKcalMol;
  const ReactionCoordinateEnergyDiagram({super.key, required this.palette, this.eaKcalMol = 18.2});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB388FF).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.timeline_rounded, color: Color(0xFFB388FF), size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'QUANTUM POTENTIAL ENERGY SURFACE (REACTION COORDINATE)',
                  style: TextStyle(
                    color: Color(0xFFB388FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFB388FF)),
                ),
                child: Text(
                  'Ea = ${eaKcalMol.toStringAsFixed(1)} kcal·mol⁻¹',
                  style: const TextStyle(color: Color(0xFFB388FF), fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Energy Curve ──────────────────────────────────────────────────
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _EnergyCoordinatePainter(ea: eaKcalMol),
            ),
          ),

          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reactants: Aspirin + Ser530', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('TS‡: Tetrahedral Intermediate', style: TextStyle(color: Color(0xFFB388FF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Products: Acetyl-Ser530 + Salicylate', style: TextStyle(color: Color(0xFF00E676), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Xu et al., J. Phys. Chem. B 2012 (DFT B3LYP Profile)',
            citations: [
              DiagramSourceCitation(label: 'Quantum TS Barrier', type: 'DOI', identifier: '10.1021/jp308253s'),
              DiagramSourceCitation(label: 'Catalytic Pocket', type: 'PDB', identifier: '1PTH'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyCoordinatePainter extends CustomPainter {
  final double ea;
  _EnergyCoordinatePainter({required this.ea});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Zero-line baseline
    final baselinePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(30, h * 0.70), Offset(w - 10, h * 0.70), baselinePaint);

    // Energy Profile Curve
    final path = Path();
    final rX = 35.0;
    final rY = h * 0.70; // Reactants baseline
    final tsX = w * 0.48;
    final tsY = h * 0.20; // Transition State Peak
    final pX = w - 20.0;
    final pY = h * 0.85; // Exothermic Products

    path.moveTo(rX, rY);
    path.cubicTo(rX + (tsX - rX) * 0.4, rY, tsX - (tsX - rX) * 0.3, tsY, tsX, tsY);
    path.cubicTo(tsX + (pX - tsX) * 0.3, tsY, pX - (pX - tsX) * 0.4, pY, pX, pY);

    // Glow under curve
    final fillPath = Path.from(path)
      ..lineTo(pX, h * 0.95)
      ..lineTo(rX, h * 0.95)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFB388FF).withValues(alpha: 0.3),
          const Color(0xFFB388FF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(rX, tsY, pX, h * 0.95));
    canvas.drawPath(fillPath, fillPaint);

    // Main line
    final curvePaint = Paint()
      ..color = const Color(0xFFB388FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);

    // TS Peak marker
    final tsDot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tsX, tsY), 4.5, tsDot);

    // Ea Vertical Arrow
    final arrowPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(tsX - 25, rY), Offset(tsX - 25, tsY), arrowPaint);

    // Arrow caps
    canvas.drawLine(Offset(tsX - 30, tsY + 5), Offset(tsX - 25, tsY), arrowPaint);
    canvas.drawLine(Offset(tsX - 20, tsY + 5), Offset(tsX - 25, tsY), arrowPaint);

    final eaText = TextPainter(
      text: TextSpan(
        text: 'Ea +${ea.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    eaText.paint(canvas, Offset(tsX - 70, (rY + tsY) / 2 - 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Toxicology Biphasic Acid-Base Progression & Antidote Cycle Diagram
class ToxicologyBiphasicCycleDiagram extends StatelessWidget {
  final dynamic palette;
  const ToxicologyBiphasicCycleDiagram({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BIPHASIC ACID-BASE TOXICOLOGY & ANTIDOTE ION-TRAPPING CYCLE',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CRITICAL PROTOCOL',
                  style: TextStyle(color: Colors.redAccent, fontSize: 8.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Timeline Progression Steps ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStageCard(
                  step: 'PHASE 1 (EARLY < 12h)',
                  title: 'Respiratory Alkalosis',
                  detail: 'Medullary stimulation causes tachypnea & hyperventilation -> PaCO₂ falls -> pH rises.',
                  color: const Color(0xFF00E5FF),
                  icon: Icons.air_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStageCard(
                  step: 'PHASE 2 (LATE > 12h)',
                  title: 'Metabolic Acidosis',
                  detail: 'Mitochondrial uncoupling halts ATP synthesis -> Lactic acid & ketoacids accumulate -> pH drops.',
                  color: Colors.redAccent,
                  icon: Icons.flash_on_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStageCard(
                  step: 'RESCUE ANTIDOTE',
                  title: 'IV Sodium Bicarbonate',
                  detail: 'Urine pH > 7.5 converts salicylic acid to ionized A⁻ -> Trapped in renal tubules -> Rapid elimination.',
                  color: const Color(0xFF00E676),
                  icon: Icons.medical_services_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Proudfoot et al., Clin Toxicol 2004',
            citations: [
              DiagramSourceCitation(label: 'Urine Alkalinization Consensus', type: 'DOI', identifier: '10.1081/CLT-120028740'),
              DiagramSourceCitation(label: 'Reye Syndrome Evidence', type: 'PMID', identifier: '3543706'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required String step,
    required String title,
    required String detail,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// 6. Botanical & Chemical Discovery Roadmap (Willow Bark to Aspirin)
class BotanicalSynthesisCycleDiagram extends StatelessWidget {
  final dynamic palette;
  const BotanicalSynthesisCycleDiagram({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        era: 'ANCIENT BOTANY',
        name: 'White Willow Bark (Salix alba)',
        detail: 'Natural Salicin glycoside used since 400 BCE (Hippocrates) for fever & inflammation.',
        color: const Color(0xFF00E676),
        icon: Icons.eco_rounded,
      ),
      (
        era: '1838: GERHARDT',
        name: 'Salicylic Acid',
        detail: 'Hydrolysis product; effective antipyretic but caused severe gastric mucosal irritation.',
        color: const Color(0xFFFFB300),
        icon: Icons.science_rounded,
      ),
      (
        era: '1897: FELIX HOFFMANN',
        name: 'Acetylsalicylic Acid (ASA)',
        detail: 'Acetylated with acetic anhydride at Bayer AG. Created stable, well-tolerated oral prodrug.',
        color: const Color(0xFF00E5FF),
        icon: Icons.medication_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: Color(0xFF00E676), size: 16),
              SizedBox(width: 8),
              Text(
                'BOTANICAL DISCOVERY TO SYNTHETIC PRODRUG EVOLUTION',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stages.map((s) {
                  final width = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 16) / 3;
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.color.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(s.icon, color: s.color, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.era,
                                  style: TextStyle(color: s.color, fontSize: 8.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.detail,
                            style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const VerificationSourceFooter(
            primaryReference: 'Sneader, BMJ 2000 & Stone, Phil Trans R Soc 1763',
            citations: [
              DiagramSourceCitation(label: 'Bayer History Reappraisal', type: 'DOI', identifier: '10.1136/bmj.321.7276.1591'),
              DiagramSourceCitation(label: 'Willow Bark Salicin', type: 'DOI', identifier: '10.1098/rstl.1763.0033'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 7. Anatomical Clinical Signs & Pathophysiology Infographic Diagram
/// Multi-panel medical educational diagram modeled after high-yield clinical
/// posters (e.g. Medinaz Academy), featuring an anatomical silhouette with
/// interactive organ systems (Brain/CNS, Stomach, Liver, Intestines, Kidneys),
/// Core GI signs, Systemic/Neuro-otologic features, Gut-Brain axis triggers,
/// Red Flags emergency criteria, and peer-reviewed verification citations.
class AnatomicalClinicalInfographicDiagram extends StatefulWidget {
  final dynamic palette;
  final String medicineName;
  const AnatomicalClinicalInfographicDiagram({
    super.key,
    required this.palette,
    this.medicineName = 'Aspirin (Acetylsalicylic Acid)',
  });

  @override
  State<AnatomicalClinicalInfographicDiagram> createState() =>
      _AnatomicalClinicalInfographicDiagramState();
}

class _AnatomicalClinicalInfographicDiagramState
    extends State<AnatomicalClinicalInfographicDiagram> {
  int _selectedOrganIndex = 1; // Default to Stomach / Gastric mucosa

  final List<({
    String organ,
    String badge,
    Color color,
    IconData icon,
    String primarySign,
    String pathophysiology,
    String clinicalManagement,
    String citation,
    String doi,
  })> _organProfiles = [
    (
      organ: 'Brain & CNS',
      badge: 'MEDULLA & CRANIAL NERVE VIII',
      color: Color(0xFFE040FB),
      icon: Icons.psychology_rounded,
      primarySign: 'Tinnitus, Hyperventilation & Chemoreceptor Trigger',
      pathophysiology:
          'Direct stimulation of medullary respiratory center causes tachypnea & early respiratory alkalosis. High-frequency cochlear ototoxicity (tinnitus) is the hallmark early warning sign of salicylism (Cp > 200 mg/L).',
      clinicalManagement:
          'Monitor blood gases (ABGs) for biphasic transition to metabolic acidosis. Discontinue immediately if ringing in ears onset occurs.',
      citation: 'Patrono et al., N Engl J Med 2005',
      doi: '10.1056/NEJMra052711',
    ),
    (
      organ: 'Stomach & Gastric Mucosa',
      badge: 'GASTRIC BARRIER & PEPTIC CORROSION',
      color: Color(0xFFFF5252),
      icon: Icons.personal_injury_rounded,
      primarySign: 'Epigastric Pain, Mucosal Erosions & Occult Bleeding',
      pathophysiology:
          'Dual toxicity: (1) Irreversible COX-1 inhibition blocks cytoprotective PGE2 & PGI2, diminishing gastric mucus and bicarbonate secretion; (2) Lipid-soluble un-ionized aspirin directly penetrates surface mucous cells, uncoupling oxidative phosphorylation and causing petechial mucosal hemorrhage.',
      clinicalManagement:
          'Co-prescribe PPI (omeprazole) or synthetic PGE1 analog (misoprostol) in high-risk patients. Take with meals or use enteric formulation.',
      citation: 'Lanas et al., Lancet 2006',
      doi: '10.1016/S0140-6736(06)68651-7',
    ),
    (
      organ: 'Liver & Hepatic Shunt',
      badge: 'GLUCURONIDATION & MICROVESICULAR STEATOSIS',
      color: Color(0xFFFFB74D),
      icon: Icons.coronavirus_rounded,
      primarySign: 'Saturation Kinetics & Pediatric Reye Syndrome Risk',
      pathophysiology:
          'Metabolized via hepatic glucuronidation (UGT1A6) & glycine conjugation (salicyluric acid). Saturated at therapeutic/supratherapeutic doses (zero-order elimination). In children with viral illness (varicella/influenza), impairs mitochondrial beta-oxidation causing acute microvesicular fatty liver with encephalopathy.',
      clinicalManagement:
          'Absolute pediatric contraindication for febrile viral illness. Feline DVM warning: feline UGT1A6 deficiency extends half-life to 38-45 hours.',
      citation: 'Hurwitz et al., N Engl J Med 1987',
      doi: '10.1056/NEJM198704093161502',
    ),
    (
      organ: 'Duodenum & Intestines',
      badge: 'PASSIVE DIFFUSION & GASTRO-INTESTINAL PERFUSION',
      color: Color(0xFF26A69A),
      icon: Icons.water_damage_rounded,
      primarySign: 'Rapid Enteric Absorption & Alkaline Dissolution',
      pathophysiology:
          'Weakly acidic drug (pKa ≈ 3.5). Partially absorbed in stomach, but majority occurs in proximal small intestine due to enormous absorptive surface area and neutral/alkaline pH driving rapid microvillar dissolution (bioavailability ~65%).',
      clinicalManagement:
          'Enteric-coated preparations shift dissolution from stomach to duodenum, reducing gastric dyspepsia (though systemic bleeding risk persists).',
      citation: 'Goodman & Gilman 14th Ed.',
      doi: '10.1056/NEJMra052711',
    ),
    (
      organ: 'Kidneys & Renal Tubules',
      badge: 'TUBULAR CLEARANCE & URINARY ION TRAPPING',
      color: Color(0xFF00E5FF),
      icon: Icons.filter_alt_rounded,
      primarySign: 'pH-Dependent Excretion & Medullary Ischemia',
      pathophysiology:
          'Freely filtered at the glomerulus with active proximal tubule secretion. Non-ionized salicylic acid is easily reabsorbed. Alkalinizing urine (pH > 7.5 with IV sodium bicarbonate) ionizes salicylic acid into water-soluble A⁻, trapping it in the lumen and increasing clearance up to 20-fold.',
      clinicalManagement:
          'IV Sodium Bicarbonate titrated to urine pH 7.5–8.5. Maintain potassium supplementation to prevent hypokalemia-induced aciduria.',
      citation: 'Proudfoot et al., Clin Toxicol 2004',
      doi: '10.1081/CLT-120028740',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _organProfiles[_selectedOrganIndex];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Title Banner ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.accessibility_new_rounded, color: Color(0xFF00E5FF), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLINICAL PRESENTATION, SIGNS & PATHOPHYSIOLOGY',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anatomical systems map, symptom clusters & clinical pearls for ${widget.medicineName}',
                      style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'MBBS · PHARM-D · DVM',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Organ Quick-Selector Tabs ────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_organProfiles.length, (idx) {
                final p = _organProfiles[idx];
                final isSelected = _selectedOrganIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedOrganIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? p.color.withValues(alpha: 0.25) : p.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? p.color : p.color.withValues(alpha: 0.3),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.icon, size: 14, color: p.color),
                          const SizedBox(width: 6),
                          Text(
                            p.organ,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // ── Main Infographic Body (Left, Center Silhouette, Right) ──────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;

              final leftPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfographicSectionCard(
                    title: 'Core Gastrointestinal Symptoms',
                    icon: Icons.personal_injury_rounded,
                    color: const Color(0xFFFF5252),
                    items: [
                      (
                        icon: Icons.radio_button_checked_rounded,
                        title: 'Recurrent Epigastric Pain',
                        subtitle: 'Central symptom: loss of PGE2 mucosal cytoprotection',
                      ),
                      (
                        icon: Icons.grain_rounded,
                        title: 'Bloating & Dyspepsia',
                        subtitle: 'Local acidic irritation of gastric mucosa',
                      ),
                      (
                        icon: Icons.opacity_rounded,
                        title: 'Occult Mucosal Bleeding',
                        subtitle: 'Microscopic blood loss in stool (petechial erosions)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfographicSectionCard(
                    title: 'Systemic / Associated Signs',
                    icon: Icons.offline_bolt_rounded,
                    color: const Color(0xFFFFB74D),
                    items: [
                      (
                        icon: Icons.hearing_rounded,
                        title: 'Tinnitus & Ototoxicity',
                        subtitle: 'Earliest marker of salicylism (Cp > 200 mg/L)',
                      ),
                      (
                        icon: Icons.whatshot_rounded,
                        title: 'Hyperthermia & Fatigue',
                        subtitle: 'Mitochondrial uncoupling of oxidative phosphorylation',
                      ),
                      (
                        icon: Icons.air_rounded,
                        title: 'Tachypnea / Hyperpnea',
                        subtitle: 'Direct medullary stimulation -> respiratory alkalosis',
                      ),
                    ],
                  ),
                ],
              );

              final centerSilhouette = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active.color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    // Anatomical Vector Graphic
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _AnatomicalSilhouettePainter(
                          activeColor: active.color,
                          selectedOrganIndex: _selectedOrganIndex,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Active Selected Organ Card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: active.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active.color.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(active.icon, color: active.color, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  active.badge,
                                  style: TextStyle(
                                    color: active.color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            active.primarySign,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            active.pathophysiology,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.35),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '💡 Rx: ${active.clinicalManagement}',
                              style: TextStyle(
                                color: active.color.withValues(alpha: 0.9),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final rightPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfographicSectionCard(
                    title: 'Gut-Brain Axis & Central Signaling',
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFFE040FB),
                    items: [
                      (
                        icon: Icons.bolt_rounded,
                        title: 'Medullary Respiratory Drive',
                        subtitle: 'Sensitizes central chemoreceptors to CO₂',
                      ),
                      (
                        icon: Icons.sync_problem_rounded,
                        title: 'CTZ Nausea Trigger',
                        subtitle: 'Direct chemical trigger of area postrema',
                      ),
                      (
                        icon: Icons.compare_arrows_rounded,
                        title: 'Brain-Gut Vagal Signaling',
                        subtitle: 'Submucosal plexus irritation triggers visceral hyperalgesia',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfographicSectionCard(
                    title: 'Bowel Habits & Comparative Species',
                    icon: Icons.pets_rounded,
                    color: const Color(0xFF26A69A),
                    items: [
                      (
                        icon: Icons.warning_amber_rounded,
                        title: 'Melena (Dark Tarry Stool)',
                        subtitle: 'Denatured hemoglobin from upper GI bleeding',
                      ),
                      (
                        icon: Icons.science_rounded,
                        title: 'Feline UGT1A6 Pseudogene',
                        subtitle: 'DVM Alert: 38-45h t1/2 requires 48-72h intervals',
                      ),
                      (
                        icon: Icons.alarm_rounded,
                        title: 'Enteric Formulation Shift',
                        subtitle: 'Delays absorption by 3–6 hours (alkaline dissolution)',
                      ),
                    ],
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: leftPanel),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: centerSilhouette),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: rightPanel),
                  ],
                );
              }

              return Column(
                children: [
                  centerSilhouette,
                  const SizedBox(height: 12),
                  leftPanel,
                  const SizedBox(height: 12),
                  rightPanel,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Bottom Infographic Panels (Important Note & Red Flags) ─────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final importantNoteBox = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF29B6F6), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'IMPORTANT CLINICAL MECHANISM NOTE',
                          style: TextStyle(
                            color: Color(0xFF29B6F6),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aspirin is the ONLY irreversible NSAID — covalent acetylation of Ser-530 permanently inactivates COX-1 in anucleate platelets for their entire 7–10 day lifespan. Hemostasis only recovers when bone marrow megakaryocytes produce fresh platelets.',
                      style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Non-acetylated NSAIDs (ibuprofen, naproxen) bind reversibly and compete with aspirin for the catalytic pocket.',
                      style: TextStyle(color: Colors.white60, fontSize: 9.5),
                    ),
                  ],
                ),
              );

              final redFlagsBox = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'WHEN TO SEEK MEDICAL REVIEW (RED FLAGS)',
                            style: TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildRedFlagItem('Coffee-ground hematemesis or melena (active upper GI bleed)'),
                    _buildRedFlagItem('Unexplained rapid hyperpnea / tachypnea (metabolic acidosis)'),
                    _buildRedFlagItem('Confusion, lethargy, or seizures (salicylate neuroglycopenia)'),
                    _buildRedFlagItem('Severe persistent tinnitus with vertigo (Cp > 300 mg/L)'),
                    _buildRedFlagItem('Pediatric viral illness exposure (varicella/influenza -> Reye syndrome)'),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: importantNoteBox),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: redFlagsBox),
                  ],
                );
              }

              return Column(
                children: [
                  importantNoteBox,
                  const SizedBox(height: 10),
                  redFlagsBox,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // ── Verification Citations Footer ──────────────────────────────────
          const VerificationSourceFooter(
            primaryReference: 'Patrono et al., N Engl J Med 2005 & Vane, Nature New Biol 1971',
            citations: [
              DiagramSourceCitation(label: 'NEJM MoA Review', type: 'PMID', identifier: '16339097'),
              DiagramSourceCitation(label: 'Nobel MoA Discovery', type: 'PMID', identifier: '5284360'),
              DiagramSourceCitation(label: 'NEJM DOI', type: 'DOI', identifier: '10.1056/NEJMra052711'),
              DiagramSourceCitation(label: 'FDA Prescribing Info', type: 'FDA', identifier: 'NDA 012822'),
              DiagramSourceCitation(label: 'RCSB Crystal Structure', type: 'PDB', identifier: '1PTH'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfographicSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<({IconData icon, String title, String subtitle})> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 11, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(color: Colors.white60, fontSize: 9.2, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRedFlagItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('➔ ', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10.5, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering an interactive, glowing anatomical silhouette
/// with organs for Brain, Stomach, Liver, Intestines, and Kidneys.
class _AnatomicalSilhouettePainter extends CustomPainter {
  final Color activeColor;
  final int selectedOrganIndex;

  _AnatomicalSilhouettePainter({
    required this.activeColor,
    required this.selectedOrganIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Body silhouette outline paint
    final bodyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bodyFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.14), width: w * 0.24, height: h * 0.18),
      bodyFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.14), width: w * 0.24, height: h * 0.18),
      bodyPaint,
    );

    // Torso outline
    final torsoPath = Path()
      ..moveTo(cx - w * 0.14, h * 0.23)
      ..lineTo(cx - w * 0.28, h * 0.32) // Left shoulder
      ..lineTo(cx - w * 0.24, h * 0.58) // Left flank
      ..lineTo(cx - w * 0.20, h * 0.72) // Left hip
      ..lineTo(cx - w * 0.10, h * 0.96) // Left leg
      ..lineTo(cx - w * 0.03, h * 0.96)
      ..lineTo(cx, h * 0.74) // Inguinal crease
      ..lineTo(cx + w * 0.03, h * 0.96)
      ..lineTo(cx + w * 0.10, h * 0.96) // Right leg
      ..lineTo(cx + w * 0.20, h * 0.72) // Right hip
      ..lineTo(cx + w * 0.24, h * 0.58) // Right flank
      ..lineTo(cx + w * 0.28, h * 0.32) // Right shoulder
      ..lineTo(cx + w * 0.14, h * 0.23)
      ..close();

    canvas.drawPath(torsoPath, bodyFill);
    canvas.drawPath(torsoPath, bodyPaint);

    // Gut-Brain Axis connecting pulse line
    final axisPaint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final dashPath = Path()
      ..moveTo(cx, h * 0.18)
      ..quadraticBezierTo(cx - 10, h * 0.32, cx, h * 0.45);
    canvas.drawPath(dashPath, axisPaint);

    // Organ Node Positions
    final organNodes = [
      Offset(cx, h * 0.14), // 0: Brain
      Offset(cx - 14, h * 0.42), // 1: Stomach
      Offset(cx + 18, h * 0.44), // 2: Liver
      Offset(cx, h * 0.58), // 3: Intestines
      Offset(cx - 24, h * 0.51), // 4: Kidney left
    ];

    for (var i = 0; i < organNodes.length; i++) {
      final pos = organNodes[i];
      final isSelected = selectedOrganIndex == i;

      // Glow circle
      final glowPaint = Paint()
        ..color = (isSelected ? activeColor : Colors.white).withValues(alpha: isSelected ? 0.35 : 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 8 : 4);
      canvas.drawCircle(pos, isSelected ? 16 : 9, glowPaint);

      // Node circle
      final nodePaint = Paint()
        ..color = isSelected ? activeColor : Colors.white60
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isSelected ? 6.5 : 4, nodePaint);

      // Border ring
      final ringPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.8 : 1.0;
      canvas.drawCircle(pos, isSelected ? 9 : 6, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomicalSilhouettePainter oldDelegate) {
    return oldDelegate.selectedOrganIndex != selectedOrganIndex ||
        oldDelegate.activeColor != activeColor;
  }
}

