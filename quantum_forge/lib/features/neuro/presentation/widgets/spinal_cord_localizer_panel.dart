// ============================================================================
// Spinal Cord Cross-Sectional & Longitudinal Localizer — NeuroLab 3D
// ----------------------------------------------------------------------------
// High-yield anatomical and clinical spinal cord localizer:
// - Interactive axial cross-section rendering Dorsal Columns, Corticospinal,
//   Spinothalamic tracts, and anterior horn cells.
// - 1-Tap syndrome presets (Brown-Séquard, Anterior Cord, Central Cord,
//   Subacute Combined Degeneration, Cauda Equina).
// - Real-time sensory & motor dissociation deficit breakdown.
// - Direct synchronization with SSEP & MEP telemetry channels.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';
import 'neuro_clinical_info_system.dart';

class SpinalCordLocalizerPanel extends StatelessWidget {
  final SpinalSyndrome selectedSyndrome;
  final ValueChanged<SpinalSyndrome> onSyndromeChanged;
  final String selectedLevel;
  final ValueChanged<String> onLevelChanged;

  const SpinalCordLocalizerPanel({
    super.key,
    required this.selectedSyndrome,
    required this.onSyndromeChanged,
    this.selectedLevel = 'C5',
    required this.onLevelChanged,
  });

  static const List<String> kSpinalLevels = ['C3', 'C5', 'T4', 'T10', 'L1', 'L4', 'S1'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060911),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: Color(0xFFA78BFA), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SPINAL CORD TRACT LOCALIZER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const NeuroInfoButton(topicId: 'brown_sequard', size: 14),
                const SizedBox(width: 8),

                // Level Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: kSpinalLevels.map((lvl) {
                      final isSel = selectedLevel == lvl;
                      return InkWell(
                        onTap: () => onLevelChanged(lvl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF7C3AED) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lvl,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : Colors.white60,
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

          // Main Body
          Expanded(
            child: Row(
              children: [
                // Left: Axial Spinal Cross-Section CustomPainter
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: _SpinalAxialPainter(syndrome: selectedSyndrome),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // Right: Syndrome Selection & Deficit Breakdown
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(0xFF1E293B))),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1-Tap Syndrome Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: SpinalSyndrome.values.map((syn) {
                              final isSel = selectedSyndrome == syn;
                              return ChoiceChip(
                                label: Text(syn.shortBadge, style: const TextStyle(fontSize: 10.5)),
                                selected: isSel,
                                selectedColor: syn.accentColor.withValues(alpha: 0.85),
                                backgroundColor: const Color(0xFF1E293B),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                onSelected: (val) {
                                  if (val) onSyndromeChanged(syn);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          // Syndrome Title & Description
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedSyndrome.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selectedSyndrome.accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedSyndrome.label,
                                  style: TextStyle(
                                    color: selectedSyndrome.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedSyndrome.description,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Deficit Matrix
                          _buildDeficitRow(
                            title: 'IPSILATERAL DEFICIT',
                            icon: Icons.accessibility_new_rounded,
                            text: selectedSyndrome.ipsilateralDeficit,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(height: 6),
                          _buildDeficitRow(
                            title: 'CONTRALATERAL DEFICIT',
                            icon: Icons.airline_seat_legroom_reduced_rounded,
                            text: selectedSyndrome.contralateralDeficit,
                            color: const Color(0xFFFF7043),
                          ),
                          const SizedBox(height: 6),
                          _buildDeficitRow(
                            title: 'SSEP MONITORING STATUS',
                            icon: Icons.electric_bolt_rounded,
                            text: selectedSyndrome.ssepStatus,
                            color: const Color(0xFFA78BFA),
                          ),
                          const SizedBox(height: 6),
                          _buildDeficitRow(
                            title: 'MEP MOTOR CONDUCTION',
                            icon: Icons.speed_rounded,
                            text: selectedSyndrome.mepStatus,
                            color: const Color(0xFFF43F5E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeficitRow({
    required String title,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _SpinalAxialPainter extends CustomPainter {
  final SpinalSyndrome syndrome;

  _SpinalAxialPainter({required this.syndrome});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.42;

    // Outer White Matter contour
    final cordPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: radius * 2.2, height: radius * 1.9));

    final whiteMatterPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(cordPath, whiteMatterPaint);
    canvas.drawPath(cordPath, outlinePaint);

    // Anterior Median Fissure (slit at bottom)
    final fissurePaint = Paint()
      ..color = const Color(0xFF060911)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(cx, cy + radius * 0.95), Offset(cx, cy + radius * 0.35), fissurePaint);

    // Posterior Median Sulcus (line at top)
    canvas.drawLine(Offset(cx, cy - radius * 0.95), Offset(cx, cy - radius * 0.45), fissurePaint);

    // Central Gray Matter "Butterfly" H-shape
    final grayMatterPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final grayOutline = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final butterflyPath = Path();
    // Central canal
    final ccY = cy;
    // Left dorsal horn (top left)
    butterflyPath.moveTo(cx - 8, ccY);
    butterflyPath.lineTo(cx - radius * 0.45, cy - radius * 0.55);
    butterflyPath.lineTo(cx - radius * 0.30, cy - radius * 0.65);
    butterflyPath.lineTo(cx - 15, cy - 10);
    // Left ventral horn (bottom left)
    butterflyPath.lineTo(cx - radius * 0.55, cy + radius * 0.45);
    butterflyPath.lineTo(cx - radius * 0.35, cy + radius * 0.55);
    butterflyPath.lineTo(cx - 6, cy + 10);
    // Across commissure
    butterflyPath.lineTo(cx + 6, cy + 10);
    // Right ventral horn
    butterflyPath.lineTo(cx + radius * 0.35, cy + radius * 0.55);
    butterflyPath.lineTo(cx + radius * 0.55, cy + radius * 0.45);
    butterflyPath.lineTo(cx + 15, cy - 10);
    // Right dorsal horn
    butterflyPath.lineTo(cx + radius * 0.30, cy - radius * 0.65);
    butterflyPath.lineTo(cx + radius * 0.45, cy - radius * 0.55);
    butterflyPath.lineTo(cx + 8, ccY);
    butterflyPath.close();

    canvas.drawPath(butterflyPath, grayMatterPaint);
    canvas.drawPath(butterflyPath, grayOutline);

    // Central canal dot
    canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = const Color(0xFF00E5FF));

    // Tract Color Identifiers
    // 1. Dorsal Columns (Posterior): Blue/Green (#00E676)
    final dcLeftRect = Rect.fromCenter(center: Offset(cx - radius * 0.28, cy - radius * 0.45), width: radius * 0.42, height: radius * 0.45);
    final dcRightRect = Rect.fromCenter(center: Offset(cx + radius * 0.28, cy - radius * 0.45), width: radius * 0.42, height: radius * 0.45);

    // 2. Lateral Corticospinal Tract (Lateral): Crimson (#EF4444)
    final cstLeftRect = Rect.fromCenter(center: Offset(cx - radius * 0.68, cy - radius * 0.1), width: radius * 0.36, height: radius * 0.45);
    final cstRightRect = Rect.fromCenter(center: Offset(cx + radius * 0.68, cy - radius * 0.1), width: radius * 0.36, height: radius * 0.45);

    // 3. Spinothalamic Tract (Anterolateral): Orange (#FB923C)
    final stLeftRect = Rect.fromCenter(center: Offset(cx - radius * 0.65, cy + radius * 0.32), width: radius * 0.36, height: radius * 0.36);
    final stRightRect = Rect.fromCenter(center: Offset(cx + radius * 0.65, cy + radius * 0.32), width: radius * 0.36, height: radius * 0.36);

    // Highlight tracts based on syndrome lesion
    _paintTract(canvas, dcLeftRect, 'DC (L)', const Color(0xFF00E676), _isTractDamaged('dc_left'));
    _paintTract(canvas, dcRightRect, 'DC (R)', const Color(0xFF00E676), _isTractDamaged('dc_right'));
    _paintTract(canvas, cstLeftRect, 'CST (L)', const Color(0xFFEF4444), _isTractDamaged('cst_left'));
    _paintTract(canvas, cstRightRect, 'CST (R)', const Color(0xFFEF4444), _isTractDamaged('cst_right'));
    _paintTract(canvas, stLeftRect, 'ST (L)', const Color(0xFFFB923C), _isTractDamaged('st_left'));
    _paintTract(canvas, stRightRect, 'ST (R)', const Color(0xFFFB923C), _isTractDamaged('st_right'));

    // Special lesion overlays for Central Cord / Syrinx
    if (syndrome == SpinalSyndrome.centralCord) {
      final syrinxPaint = Paint()
        ..color = const Color(0xFFFFD740).withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius * 0.35, syrinxPaint);
    }
  }

  bool _isTractDamaged(String tract) {
    switch (syndrome) {
      case SpinalSyndrome.normal:
        return false;
      case SpinalSyndrome.brownSequard:
        // Left hemisection damages left DC, left CST, and left entering ST
        return tract.contains('left');
      case SpinalSyndrome.anteriorCord:
        // Anterior 2/3: bilateral CST and bilateral ST damaged; DCs spared!
        return tract.contains('cst') || tract.contains('st');
      case SpinalSyndrome.centralCord:
        // Crossing fibers damaged
        return false;
      case SpinalSyndrome.subacuteCombined:
        // Posterior columns + lateral corticospinal tracts bilaterally
        return tract.contains('dc') || tract.contains('cst');
      case SpinalSyndrome.caudaEquina:
        return false;
    }
  }

  void _paintTract(Canvas canvas, Rect rect, String label, Color normalColor, bool isDamaged) {
    final fillPaint = Paint()
      ..color = isDamaged
          ? const Color(0xFFDC2626).withValues(alpha: 0.85)
          : normalColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = isDamaged ? const Color(0xFFEF4444) : normalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDamaged ? 2.5 : 1.2;

    canvas.drawOval(rect, fillPaint);
    canvas.drawOval(rect, strokePaint);

    if (isDamaged) {
      // Draw Red 'X' over damaged tract
      final xPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0;
      canvas.drawLine(rect.topLeft + const Offset(4, 4), rect.bottomRight - const Offset(4, 4), xPaint);
      canvas.drawLine(rect.topRight + const Offset(-4, 4), rect.bottomLeft - const Offset(-4, 4), xPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinalAxialPainter oldDelegate) {
    return oldDelegate.syndrome != syndrome;
  }
}
