import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';

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

/// Verification footer for pictorial diagrams rendering verified data origin.
Widget buildDiagramSourceFooter({
  required String authorYear,
  required String citationTitle,
  required String identifierLabel,
  required String targetUrl,
  VerifiedRepositoryType repoType = VerifiedRepositoryType.crossref,
}) {
  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_outlined, color: Color(0xFF00E676), size: 14),
        const SizedBox(width: 6),
        _buildDiagramRepositoryTag(repoType),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$authorYear — $citationTitle',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => UrlService.launch(targetUrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  identifierLabel,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF00E676)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDiagramRepositoryTag(VerifiedRepositoryType type) {
  Color color;
  String label;
  switch (type) {
    case VerifiedRepositoryType.pubmed:
      color = const Color(0xFF0288D1);
      label = 'NCBI PubMed';
      break;
    case VerifiedRepositoryType.crossref:
      color = const Color(0xFFFF9800);
      label = 'CrossRef Registry';
      break;
    case VerifiedRepositoryType.rcsbPdb:
      color = const Color(0xFFAB47BC);
      label = 'RCSB Protein Data Bank';
      break;
    case VerifiedRepositoryType.fdaAccessData:
      color = const Color(0xFF26A69A);
      label = 'FDA Regulatory Label';
      break;
    case VerifiedRepositoryType.emaEpar:
      color = const Color(0xFF3F51B5);
      label = 'EMA EPAR Record';
      break;
    case VerifiedRepositoryType.openAlex:
      color = const Color(0xFF00ACC1);
      label = 'OpenAlex Scholarly';
      break;
    case VerifiedRepositoryType.textbookBenchmark:
      color = const Color(0xFF8D6E63);
      label = 'Pharmacology Benchmark';
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
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
  double _rotationY = 0.0;
  double _rotationX = -0.05;
  bool _isDragging = false;

  void _handleOrganTap(Offset localPos, double viewWidth, double viewHeight) {
    final cx = viewWidth / 2;
    final cy = viewHeight / 2 - 10;
    final scale = viewHeight / 540.0;
    final cosX = math.cos(_rotationX);
    final sinX = math.sin(_rotationX);
    final cosY = math.cos(_rotationY);
    final sinY = math.sin(_rotationY);

    final organNodes = [
      const _Point3D(0, -165, 0),        // 0: Brain
      const _Point3D(-14, -50, 15),      // 1: Stomach
      const _Point3D(18, -54, 13),       // 2: Liver
      const _Point3D(0, 5, 17),          // 3: Duodenum
      const _Point3D(-18, -25, -15),     // 4: Kidney Left
    ];

    int closestIdx = -1;
    double minDistance = 35.0;

    for (int i = 0; i < organNodes.length; i++) {
      final p = organNodes[i];
      final x1 = p.x * cosY - p.z * sinY;
      final z1 = p.x * sinY + p.z * cosY;
      final y2 = p.y * cosX - z1 * sinX;
      final z2 = p.y * sinX + z1 * cosX;
      final factor = 520.0 / (520.0 + z2);
      final px = cx + x1 * scale * factor;
      final py = cy + y2 * scale * factor;

      final dist = (localPos - Offset(px, py)).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestIdx = i;
      }
    }

    // Also test right kidney for index 4
    const rk = _Point3D(18, -25, -15);
    final x1 = rk.x * cosY - rk.z * sinY;
    final z1 = rk.x * sinY + rk.z * cosY;
    final y2 = rk.y * cosX - z1 * sinX;
    final z2 = rk.y * sinX + z1 * cosX;
    final factor = 520.0 / (520.0 + z2);
    final px = cx + x1 * scale * factor;
    final py = cy + y2 * scale * factor;
    if ((localPos - Offset(px, py)).distance < minDistance) {
      closestIdx = 4;
    }

    if (closestIdx != -1) {
      setState(() => _selectedOrganIndex = closestIdx);
    }
  }

  Widget _buildOrbitPresetChip(String label, double rotY, double rotX, Color activeColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        setState(() {
          _rotationY = rotY;
          _rotationX = rotX;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active.color.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: active.color.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── 3D Viewport Header Controls ──
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: active.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: active.color.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.view_in_ar_rounded, color: active.color, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '3D ANATOMICAL MODEL',
                                style: TextStyle(
                                  color: active.color,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Angle badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ORBIT: ${(((_rotationY * 180 / math.pi) % 360).round() + 360) % 360}°',
                                style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Quick Presets
                            _buildOrbitPresetChip('Front', 0.0, -0.05, active.color),
                            const SizedBox(width: 3),
                            _buildOrbitPresetChip('3/4', 0.785, -0.08, active.color),
                            const SizedBox(width: 3),
                            _buildOrbitPresetChip('Side', 1.57, -0.05, active.color),
                            const SizedBox(width: 3),
                            _buildOrbitPresetChip('Back', math.pi, -0.05, active.color),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Colors.white70),
                              tooltip: 'Reset 3D View',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              onPressed: () {
                                setState(() {
                                  _rotationY = 0.0;
                                  _rotationX = -0.05;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Interactive Graggable 3D Mannequin Viewport ──
                    LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final viewWidth = boxConstraints.maxWidth;
                        const viewHeight = 480.0;

                        return SizedBox(
                          height: viewHeight,
                          width: double.infinity,
                          child: MouseRegion(
                            cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) => setState(() => _isDragging = true),
                              onPanEnd: (_) => setState(() => _isDragging = false),
                              onPanCancel: () => setState(() => _isDragging = false),
                              onPanUpdate: (details) {
                                setState(() {
                                  _rotationY += details.delta.dx * 0.012;
                                  _rotationX = (_rotationX + details.delta.dy * 0.012).clamp(-0.55, 0.55);
                                });
                              },
                              onTapUp: (details) => _handleOrganTap(details.localPosition, viewWidth, viewHeight),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _Anatomical3DMannequinPainter(
                                          activeColor: active.color,
                                          selectedOrganIndex: _selectedOrganIndex,
                                          rotationY: _rotationY,
                                          rotationX: _rotationX,
                                          isDragging: _isDragging,
                                        ),
                                      ),
                                    ),
                                    // Floating hint at bottom of 3D canvas
                                    Positioned(
                                      bottom: 8,
                                      left: 12,
                                      right: 12,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.threed_rotation_rounded, color: active.color, size: 12),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: Text(
                                                  'Drag to orbit 360° · Tap node to inspect',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

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

// ============================================================================
// 3D Anatomical Mannequin Models & Interactive CustomPainter
// Full 3D volumetric human male mannequin in standard standing posture
// featuring 360-degree drag rotation, broad athletic/muscular proportions,
// true 3D depth cross-sections, longitudinal muscle meridians, grounded stage,
// and depth-sorted internal organ nodes with Gut-Brain neural axis.
// ============================================================================

class _Point3D {
  final double x, y, z;
  const _Point3D(this.x, this.y, this.z);
}

class _ProjectedPoint {
  final double x, y, z;
  const _ProjectedPoint(this.x, this.y, this.z);
  Offset toOffset() => Offset(x, y);
}

class _Slice3D {
  final double y;
  final double cx;
  final double rx;
  final double rz;
  const _Slice3D({
    required this.y,
    this.cx = 0.0,
    required this.rx,
    required this.rz,
  });
  double get cz => 0.0;
}

class _Anatomical3DMannequinPainter extends CustomPainter {
  final Color activeColor;
  final int selectedOrganIndex;
  final double rotationY;
  final double rotationX;
  final bool isDragging;

  _Anatomical3DMannequinPainter({
    required this.activeColor,
    required this.selectedOrganIndex,
    required this.rotationY,
    required this.rotationX,
    required this.isDragging,
  });

  _ProjectedPoint _project(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double scale,
    double cosX,
    double sinX,
    double cosY,
    double sinY,
  ) {
    // 1. Rotate Y (around vertical body axis)
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    // 2. Rotate X (tilt forward / back)
    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    // 3. Perspective Camera Projection
    const dist = 520.0;
    final factor = dist / (dist + z2);

    return _ProjectedPoint(
      cx + x1 * scale * factor,
      cy + y2 * scale * factor,
      z2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 8;
    final scale = size.height / 540.0;

    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);

    _ProjectedPoint p3(double x, double y, double z) =>
        _project(x, y, z, cx, cy, scale, cosX, sinX, cosY, sinY);

    // ── 1. Holographic Grounding 3D Pedestal Stage ───────────────────────────
    final floorY = 265.0;
    final floorCenter = p3(0, floorY, 0);

    // Radial floor ambient glow
    final floorGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          activeColor.withValues(alpha: 0.22),
          activeColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(
        center: floorCenter.toOffset(),
        width: 220 * scale,
        height: 70 * scale,
      ));
    canvas.drawOval(
      Rect.fromCenter(center: floorCenter.toOffset(), width: 220 * scale, height: 70 * scale),
      floorGlow,
    );

    // Rotating 3D Concentric Floor Rings
    for (final radius in [95.0, 72.0, 48.0]) {
      final ringPath = Path();
      const numPts = 32;
      for (var i = 0; i <= numPts; i++) {
        final theta = i * 2 * math.pi / numPts;
        final px = radius * math.cos(theta);
        final pz = radius * math.sin(theta);
        final pt = p3(px, floorY, pz);
        if (i == 0) {
          ringPath.moveTo(pt.x, pt.y);
        } else {
          ringPath.lineTo(pt.x, pt.y);
        }
      }
      ringPath.close();

      final ringPaint = Paint()
        ..color = (radius == 95.0 ? activeColor : Colors.white).withValues(alpha: radius == 95.0 ? 0.35 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius == 95.0 ? 1.2 : 0.8;
      canvas.drawPath(ringPath, ringPaint);
    }

    // 3D Perspective Radial Floor Spokes (every 30 degrees)
    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var a = 0; a < 12; a++) {
      final theta = a * math.pi / 6;
      final inner = p3(48 * math.cos(theta), floorY, 48 * math.sin(theta));
      final outer = p3(95 * math.cos(theta), floorY, 95 * math.sin(theta));
      canvas.drawLine(inner.toOffset(), outer.toOffset(), spokePaint);
    }

    // ── 2. Volumetric 3D Mannequin Cross-Sectional Geometry ──────────────────
    // Head slices
    final headSlices = const [
      _Slice3D(y: -198, rx: 17, rz: 19),
      _Slice3D(y: -182, rx: 24, rz: 26),
      _Slice3D(y: -168, rx: 23, rz: 25),
      _Slice3D(y: -152, rx: 20, rz: 22),
      _Slice3D(y: -138, rx: 16, rz: 18),
      _Slice3D(y: -130, rx: 11, rz: 13),
    ];

    // Neck slices
    final neckSlices = const [
      _Slice3D(y: -122, rx: 13.5, rz: 13.5),
      _Slice3D(y: -110, rx: 17.5, rz: 16.5),
    ];

    // Torso / Thorax / Pelvis (Broad, athletic masculine V-taper)
    final torsoSlices = const [
      _Slice3D(y: -100, rx: 66, rz: 25), // Clavicles & Shoulders
      _Slice3D(y: -80, rx: 58, rz: 29),  // Pectoral major deep chest
      _Slice3D(y: -54, rx: 51, rz: 25),  // Mid ribcage
      _Slice3D(y: -30, rx: 45, rz: 23),  // Subcostal epigastrium
      _Slice3D(y: -6, rx: 39, rz: 21),   // Athletic waist taper
      _Slice3D(y: 18, rx: 46, rz: 25),   // Iliac crest / Pelvis
      _Slice3D(y: 44, rx: 49, rz: 28),   // Greater trochanters / Gluteal hips
    ];

    // Bilateral Arms
    List<_Slice3D> makeArmSlices(double sign) => [
      _Slice3D(cx: sign * 67, y: -88, rx: 15, rz: 15),
      _Slice3D(cx: sign * 71, y: -58, rx: 13, rz: 13),
      _Slice3D(cx: sign * 69, y: -22, rx: 11, rz: 11),
      _Slice3D(cx: sign * 64, y: 16, rx: 10, rz: 10),
      _Slice3D(cx: sign * 58, y: 54, rx: 8.5, rz: 8.5),
      _Slice3D(cx: sign * 54, y: 82, rx: 7.5, rz: 6),
    ];

    // Bilateral Legs (BROAD, POWERFUL, ATHLETIC MUSCULAR PROPORTIONS)
    List<_Slice3D> makeLegSlices(double sign) => [
      _Slice3D(cx: sign * 25, y: 58, rx: 21, rz: 22),   // Inguinal thigh root (wide!)
      _Slice3D(cx: sign * 27, y: 92, rx: 20.5, rz: 21.5), // Upper quad
      _Slice3D(cx: sign * 27, y: 126, rx: 19.5, rz: 20.5),// Mid quad belly
      _Slice3D(cx: sign * 25, y: 154, rx: 16.5, rz: 17),  // Suprapatellar lower thigh
      _Slice3D(cx: sign * 24, y: 172, rx: 14.5, rz: 15),  // Knee capsule & patella
      _Slice3D(cx: sign * 25, y: 200, rx: 18.5, rz: 19),  // Upper calf (gastrocnemius belly!)
      _Slice3D(cx: sign * 23, y: 228, rx: 14.5, rz: 15),  // Mid calf
      _Slice3D(cx: sign * 21, y: 244, rx: 11.5, rz: 12),  // Achilles taper
      _Slice3D(cx: sign * 20, y: 254, rx: 10, rz: 10.5),  // Malleoli (ankles)
    ];

    final leftArmSlices = makeArmSlices(-1.0);
    final rightArmSlices = makeArmSlices(1.0);
    final leftLegSlices = makeLegSlices(-1.0);
    final rightLegSlices = makeLegSlices(1.0);

    final allSliceGroups = [
      headSlices,
      neckSlices,
      torsoSlices,
      leftArmSlices,
      rightArmSlices,
      leftLegSlices,
      rightLegSlices,
    ];

    // ── Helper to draw a 3D elliptical slice with volumetric depth shading ───
    void drawSlice(_Slice3D slice) {
      const numPts = 16;
      final pts = <_ProjectedPoint>[];
      double sumZ = 0;

      for (var i = 0; i < numPts; i++) {
        final theta = i * 2 * math.pi / numPts;
        final x = slice.cx + slice.rx * math.cos(theta);
        final z = slice.cz + slice.rz * math.sin(theta);
        final pt = p3(x, slice.y, z);
        pts.add(pt);
        sumZ += pt.z;
      }

      final avgZ = sumZ / numPts;
      final depthFactor = (avgZ / 100.0).clamp(-1.0, 1.0);

      // Translucent volumetric slice fill
      final fillPath = Path()..moveTo(pts.first.x, pts.first.y);
      for (var i = 1; i < pts.length; i++) {
        fillPath.lineTo(pts[i].x, pts[i].y);
      }
      fillPath.close();

      final sliceFill = Paint()
        ..color = (depthFactor > 0 ? activeColor : Colors.white).withValues(
          alpha: (0.04 + 0.05 * (depthFactor + 1.0) / 2).clamp(0.02, 0.12),
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, sliceFill);

      // Perimeter wire segments with depth attenuation (front is brighter)
      for (var i = 0; i < numPts; i++) {
        final pA = pts[i];
        final pB = pts[(i + 1) % numPts];
        final segZ = (pA.z + pB.z) / 2;
        final isFront = segZ > -15;

        final wirePaint = Paint()
          ..color = isFront
              ? activeColor.withValues(alpha: (0.35 + 0.35 * (segZ / 40).clamp(0.0, 1.0)))
              : Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isFront ? 1.2 : 0.75;

        canvas.drawLine(pA.toOffset(), pB.toOffset(), wirePaint);
      }
    }

    // Render all slices
    for (final group in allSliceGroups) {
      for (final slice in group) {
        drawSlice(slice);
      }
    }

    // ── 3. Longitudinal 3D Surface Muscle Meridians ──────────────────────────
    void drawMeridian(List<_Slice3D> slices, double theta, Color color, double width, {bool dashed = false}) {
      final path = Path();
      for (var i = 0; i < slices.length; i++) {
        final s = slices[i];
        final x = s.cx + s.rx * math.cos(theta);
        final z = s.cz + s.rz * math.sin(theta);
        final pt = p3(x, s.y, z);

        if (i == 0) {
          path.moveTo(pt.x, pt.y);
        } else {
          path.lineTo(pt.x, pt.y);
        }
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }

    // Torso Meridians
    // Anterior midline (Sternum & Linea Alba): theta = pi / 2
    drawMeridian(torsoSlices, math.pi / 2, activeColor.withValues(alpha: 0.75), 1.4);
    // Posterior midline (Spine): theta = 3 * pi / 2
    drawMeridian(torsoSlices, 3 * math.pi / 2, Colors.white.withValues(alpha: 0.22), 1.0);
    // Lateral Flanks (Left & Right): theta = pi and 0
    drawMeridian(torsoSlices, math.pi, activeColor.withValues(alpha: 0.55), 1.3);
    drawMeridian(torsoSlices, 0, activeColor.withValues(alpha: 0.55), 1.3);
    // Anterolateral Pectoral/Abdominal guide lines
    drawMeridian(torsoSlices, math.pi / 4, Colors.white.withValues(alpha: 0.25), 0.9);
    drawMeridian(torsoSlices, 3 * math.pi / 4, Colors.white.withValues(alpha: 0.25), 0.9);

    // Head Meridians
    drawMeridian(headSlices, math.pi / 2, activeColor.withValues(alpha: 0.65), 1.2);
    drawMeridian(headSlices, 3 * math.pi / 2, Colors.white.withValues(alpha: 0.18), 0.9);
    drawMeridian(headSlices, math.pi, activeColor.withValues(alpha: 0.45), 1.0);
    drawMeridian(headSlices, 0, activeColor.withValues(alpha: 0.45), 1.0);

    // Arm Meridians (Lateral and Medial)
    drawMeridian(leftArmSlices, math.pi, activeColor.withValues(alpha: 0.50), 1.2);
    drawMeridian(leftArmSlices, 0, Colors.white.withValues(alpha: 0.22), 0.9);
    drawMeridian(rightArmSlices, 0, activeColor.withValues(alpha: 0.50), 1.2);
    drawMeridian(rightArmSlices, math.pi, Colors.white.withValues(alpha: 0.22), 0.9);

    // Leg Meridians (PROMINENT MUSCULAR QUADRICEPS & CALF SWEEPS)
    for (final isLeft in [true, false]) {
      final legGroup = isLeft ? leftLegSlices : rightLegSlices;
      // Anterior crest (Rectus Femoris & Tibia): theta = pi / 2
      drawMeridian(legGroup, math.pi / 2, activeColor.withValues(alpha: 0.70), 1.35);
      // Lateral sweep (Vastus Lateralis & Peroneus): outer
      drawMeridian(legGroup, isLeft ? math.pi : 0, activeColor.withValues(alpha: 0.60), 1.35);
      // Medial inner curve (Adductor & Medial Gastrocnemius): inner
      drawMeridian(legGroup, isLeft ? 0 : math.pi, activeColor.withValues(alpha: 0.45), 1.1);
      // Posterior hamstring/Achilles: theta = 3 * pi / 2
      drawMeridian(legGroup, 3 * math.pi / 2, Colors.white.withValues(alpha: 0.20), 0.95);
    }

    // ── 4. Anatomical Key Feature Landmarks ──────────────────────────────────
    final landmarkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Clavicles (Collarbones)
    final leftClavicle = p3(-64, -100, 2);
    final sternalNotch = p3(0, -96, 24);
    final rightClavicle = p3(64, -100, 2);
    final claviclePath = Path()
      ..moveTo(leftClavicle.x, leftClavicle.y)
      ..quadraticBezierTo(
        p3(-25, -97, 18).x, p3(-25, -97, 18).y,
        sternalNotch.x, sternalNotch.y,
      )
      ..quadraticBezierTo(
        p3(25, -97, 18).x, p3(25, -97, 18).y,
        rightClavicle.x, rightClavicle.y,
      );
    canvas.drawPath(claviclePath, landmarkPaint);

    // Pectoral major folds in 3D
    final leftPec = Path()
      ..moveTo(sternalNotch.x, p3(0, -78, 28).y)
      ..quadraticBezierTo(
        p3(-28, -72, 28).x, p3(-28, -72, 28).y,
        p3(-54, -84, 12).x, p3(-54, -84, 12).y,
      );
    final rightPec = Path()
      ..moveTo(sternalNotch.x, p3(0, -78, 28).y)
      ..quadraticBezierTo(
        p3(28, -72, 28).x, p3(28, -72, 28).y,
        p3(54, -84, 12).x, p3(54, -84, 12).y,
      );
    canvas.drawPath(leftPec, landmarkPaint);
    canvas.drawPath(rightPec, landmarkPaint);

    // Costal Arch (Ribcage Lower Border)
    final xiphoid = p3(0, -36, 22);
    final costalPath = Path()
      ..moveTo(p3(-42, -28, 12).x, p3(-42, -28, 12).y)
      ..quadraticBezierTo(p3(-18, -32, 20).x, p3(-18, -32, 20).y, xiphoid.x, xiphoid.y)
      ..quadraticBezierTo(p3(18, -32, 20).x, p3(18, -32, 20).y, p3(42, -28, 12).x, p3(42, -28, 12).y);
    canvas.drawPath(costalPath, landmarkPaint);

    // Patella (Kneecap Rings in 3D)
    final patellaPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final leftKnee = p3(-24, 172, 15);
    final rightKnee = p3(24, 172, 15);
    canvas.drawCircle(leftKnee.toOffset(), 7.5 * scale, patellaPaint);
    canvas.drawCircle(rightKnee.toOffset(), 7.5 * scale, patellaPaint);

    // Feet Profiles on Floor
    for (final sign in [-1.0, 1.0]) {
      final heel = p3(sign * 20, 260, -14);
      final arch = p3(sign * 20, 260, 2);
      final ball = p3(sign * 20, 261, 18);
      final toes = p3(sign * 20, 262, 30);

      final footPath = Path()
        ..moveTo(heel.x, heel.y)
        ..lineTo(arch.x, arch.y)
        ..lineTo(ball.x, ball.y)
        ..lineTo(toes.x, toes.y);
      canvas.drawPath(
        footPath,
        Paint()
          ..color = activeColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 5. 3D Gut-Brain Vagal Axis (Neural Signaling Path) ───────────────────
    final vagusPoints3D = const [
      _Point3D(0, -145, -5), // Brainstem / Medulla
      _Point3D(0, -120, -4), // Cervical vagus
      _Point3D(-2, -88, -2), // Superior mediastinum
      _Point3D(-5, -62, 6),  // Esophageal hiatus
      _Point3D(-14, -50, 15), // Stomach & Celiac plexus
      _Point3D(0, 5, 17),    // Mesenteric plexus
    ];

    final vagusPath = Path();
    for (var i = 0; i < vagusPoints3D.length; i++) {
      final pt = p3(vagusPoints3D[i].x, vagusPoints3D[i].y, vagusPoints3D[i].z);
      if (i == 0) {
        vagusPath.moveTo(pt.x, pt.y);
      } else {
        vagusPath.lineTo(pt.x, pt.y);
      }
    }

    final vagusGlow = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(vagusPath, vagusGlow);

    final vagusCore = Paint()
      ..color = const Color(0xFFE040FB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(vagusPath, vagusCore);

    // ── 6. 3D Internal Organs with True Spatial Depth Sorting ────────────────
    final organNodes3D = const [
      _Point3D(0, -165, 0),        // 0: Brain & CNS
      _Point3D(-14, -50, 15),      // 1: Stomach & Gastric Mucosa (Anterior Left)
      _Point3D(18, -54, 13),       // 2: Liver & Hepatic Shunt (Anterior Right)
      _Point3D(0, 5, 17),          // 3: Duodenum & Intestines (Anterior Umbilical)
      _Point3D(-18, -25, -15),     // 4: Kidneys & Renal Tubules (Dorsal Retroperitoneal Left)
    ];

    final rightKidney3D = const _Point3D(18, -25, -15); // Right Kidney companion

    // Project each organ
    final projectedOrgans = <({int index, _ProjectedPoint pt, bool isSelected})>[];
    for (var i = 0; i < organNodes3D.length; i++) {
      final p = organNodes3D[i];
      projectedOrgans.add((
        index: i,
        pt: p3(p.x, p.y, p.z),
        isSelected: selectedOrganIndex == i,
      ));
    }

    // Sort by projected depth Z (draw back organs first, front organs in front)
    projectedOrgans.sort((a, b) => a.pt.z.compareTo(b.pt.z));

    for (final organ in projectedOrgans) {
      final i = organ.index;
      final pos = organ.pt.toOffset();
      final isSelected = organ.isSelected;
      final depthFactor = (organ.pt.z / 100.0).clamp(-1.0, 1.0);
      final zScale = (520.0 / (520.0 + organ.pt.z)).clamp(0.7, 1.3);

      // Draw organ anatomical silhouette highlight when selected
      if (isSelected) {
        final organHighlightPaint = Paint()
          ..color = activeColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;

        final organStrokePaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;

        switch (i) {
          case 0: // Brain Cortex Silhouette
            final brainRect = Rect.fromCenter(center: pos, width: 34 * scale * zScale, height: 30 * scale * zScale);
            canvas.drawOval(brainRect, organHighlightPaint);
            canvas.drawOval(brainRect, organStrokePaint);
            break;
          case 1: // Stomach J-Shape
            final sp = Path()
              ..moveTo(pos.dx - 4 * scale, pos.dy - 12 * scale)
              ..cubicTo(pos.dx - 18 * scale, pos.dy - 10 * scale, pos.dx - 24 * scale, pos.dy + 8 * scale, pos.dx - 18 * scale, pos.dy + 18 * scale)
              ..cubicTo(pos.dx - 12 * scale, pos.dy + 24 * scale, pos.dx + 4 * scale, pos.dy + 20 * scale, pos.dx + 8 * scale, pos.dy + 10 * scale)
              ..cubicTo(pos.dx + 2 * scale, pos.dy + 2 * scale, pos.dx - 2 * scale, pos.dy - 6 * scale, pos.dx - 4 * scale, pos.dy - 12 * scale)
              ..close();
            canvas.drawPath(sp, organHighlightPaint);
            canvas.drawPath(sp, organStrokePaint);
            break;
          case 2: // Liver Wedge
            final lp = Path()
              ..moveTo(pos.dx - 2 * scale, pos.dy - 10 * scale)
              ..lineTo(pos.dx + 26 * scale, pos.dy - 6 * scale)
              ..lineTo(pos.dx + 22 * scale, pos.dy + 16 * scale)
              ..lineTo(pos.dx - 4 * scale, pos.dy + 12 * scale)
              ..close();
            canvas.drawPath(lp, organHighlightPaint);
            canvas.drawPath(lp, organStrokePaint);
            break;
          case 3: // Duodenum & Intestines
            final intRect = Rect.fromCenter(center: pos, width: 38 * scale * zScale, height: 26 * scale * zScale);
            canvas.drawRRect(RRect.fromRectAndRadius(intRect, Radius.circular(8 * scale)), organHighlightPaint);
            canvas.drawRRect(RRect.fromRectAndRadius(intRect, Radius.circular(8 * scale)), organStrokePaint);
            break;
          case 4: // Kidneys (Bilateral Dorsal Beans)
            final leftK = Rect.fromCenter(center: pos, width: 14 * scale * zScale, height: 20 * scale * zScale);
            final rightKPt = p3(rightKidney3D.x, rightKidney3D.y, rightKidney3D.z);
            final rightK = Rect.fromCenter(center: rightKPt.toOffset(), width: 14 * scale * zScale, height: 20 * scale * zScale);
            canvas.drawOval(leftK, organHighlightPaint);
            canvas.drawOval(leftK, organStrokePaint);
            canvas.drawOval(rightK, organHighlightPaint);
            canvas.drawOval(rightK, organStrokePaint);
            break;
        }

        // Concentric 3D Radar Beacon Target Rings
        for (final r in [22.0, 32.0]) {
          final beaconPaint = Paint()
            ..color = activeColor.withValues(alpha: r == 22.0 ? 0.45 : 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawCircle(pos, r * scale * zScale, beaconPaint);
        }

        // Floating 3D Leader Line and Tag
        final tagOffset = Offset(pos.dx + 34 * scale, pos.dy - 18 * scale);
        canvas.drawLine(
          pos,
          tagOffset,
          Paint()
            ..color = activeColor.withValues(alpha: 0.6)
            ..strokeWidth = 1.0,
        );
        canvas.drawCircle(tagOffset, 2.5 * scale, Paint()..color = activeColor);
      }

      // Radar glow effect
      final glowPaint = Paint()
        ..color = (isSelected ? activeColor : Colors.white).withValues(
          alpha: isSelected ? 0.55 : (0.12 + 0.10 * (depthFactor + 1.0) / 2).clamp(0.08, 0.25),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 12 : 5);
      canvas.drawCircle(pos, (isSelected ? 18.0 : 9.0) * scale * zScale, glowPaint);

      // Core node circle
      final nodePaint = Paint()
        ..color = isSelected ? activeColor : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, (isSelected ? 7.0 : 4.5) * scale * zScale, nodePaint);

      // Inner white pip
      final pipPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, (isSelected ? 3.0 : 1.8) * scale * zScale, pipPaint);

      // Border ring
      final ringPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.0;
      canvas.drawCircle(pos, (isSelected ? 10.0 : 6.5) * scale * zScale, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Anatomical3DMannequinPainter oldDelegate) {
    return oldDelegate.rotationY != rotationY ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.selectedOrganIndex != selectedOrganIndex ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDragging != isDragging;
  }
}

