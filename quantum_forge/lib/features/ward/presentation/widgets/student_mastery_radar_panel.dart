// ============================================================================
// Student Mastery Radar Dashboard & Longitudinal Competency Tracker
// ----------------------------------------------------------------------------
// Custom-painted 6-Axis Competency Radar Chart aggregating performance across:
// 1. Cardiovascular (CardioCath 3D)
// 2. Neurology (NeuroLab 3D)
// 3. Nephrology & Acid-Base (NephroLab 3D)
// 4. Pulmonology & Critical Care (PulmoVent 3D)
// 5. Pharmacology & Toxicology (PharmaBioNet & DDI)
// 6. Emergency & POCUS Diagnostics (WardRounds 3D)
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/ward_rounds_engine.dart';

class StudentMasteryRadarPanel extends StatelessWidget {
  final WardRoundsEngine engine;
  final void Function(String route)? onNavigateRemediation;

  const StudentMasteryRadarPanel({
    super.key,
    required this.engine,
    this.onNavigateRemediation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final mastery = engine.aggregateDomainMastery;

        // Find weakest domain for auto-remediation
        String weakestDomain = 'Pulmonology & Critical Care';
        double lowestScore = 100.0;
        mastery.forEach((domain, score) {
          if (score < lowestScore) {
            lowestScore = score;
            weakestDomain = domain;
          }
        });

        String targetRemediationRoute = '/pulmo';
        if (weakestDomain.contains('Cardiovascular')) {
          targetRemediationRoute = '/cardiac';
        } else if (weakestDomain.contains('Neurology')) {
          targetRemediationRoute = '/neuro';
        } else if (weakestDomain.contains('Nephrology')) {
          targetRemediationRoute = '/nephro';
        } else if (weakestDomain.contains('Pharmacology')) {
          targetRemediationRoute = '/pharmacogenomics';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'STUDENT ORGAN-SYSTEM MASTERY RADAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'USMLE / MBBS CORE',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Custom Painted Radar Chart
              SizedBox(
                height: 240,
                child: CustomPaint(
                  painter: _MasteryRadarPainter(masteryScores: mastery),
                ),
              ),
              const SizedBox(height: 14),

              // Domain breakdown list
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mastery.entries.map((e) {
                  Color chipColor = Colors.greenAccent;
                  if (e.value < 70) {
                    chipColor = Colors.orangeAccent;
                  } else if (e.value < 85) {
                    chipColor = Colors.cyanAccent;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.value.toInt()}%',
                          style: TextStyle(
                            color: chipColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 1-Click Targeted Remediation Launcher
              ElevatedButton.icon(
                onPressed: () {
                  if (onNavigateRemediation != null) {
                    onNavigateRemediation!(targetRemediationRoute);
                  } else {
                    Navigator.of(context).pushNamed(targetRemediationRoute);
                  }
                },
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: Text(
                  'REMEDIATE WEAKEST DOMAIN: ${weakestDomain.toUpperCase()} (${lowestScore.toInt()}%)',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MasteryRadarPainter extends CustomPainter {
  final Map<String, double> masteryScores;

  _MasteryRadarPainter({required this.masteryScores});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) * 0.72;

    final categories = masteryScores.keys.toList();
    final count = categories.length;
    if (count < 3) return;

    final angleStep = (2 * math.pi) / count;

    // 1. Concentric Grid Polygons (20%, 40%, 60%, 80%, 100%)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 5; step++) {
      final r = radius * (step / 5.0);
      final gridPath = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * angleStep) - (math.pi / 2);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // 2. Radial Axis Lines
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    for (int i = 0; i < count; i++) {
      final angle = (i * angleStep) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label text
      final label = categories[i];
      final labelAngle = angle;
      final labelDist = radius + 22.0;
      final lx = center.dx + labelDist * math.cos(labelAngle);
      final ly = center.dy + labelDist * math.sin(labelAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.split('&')[0].trim(),
          style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(lx - textPainter.width / 2, ly - textPainter.height / 2));
    }

    // 3. User Mastery Polygon
    final radarPath = Path();
    final scorePoints = <Offset>[];

    for (int i = 0; i < count; i++) {
      final angle = (i * angleStep) - (math.pi / 2);
      final score = (masteryScores[categories[i]] ?? 50.0).clamp(0.0, 100.0);
      final r = radius * (score / 100.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final pt = Offset(x, y);
      scorePoints.add(pt);

      if (i == 0) {
        radarPath.moveTo(x, y);
      } else {
        radarPath.lineTo(x, y);
      }
    }
    radarPath.close();

    // Fill polygon
    final fillPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(radarPath, fillPaint);

    // Stroke border
    final strokePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(radarPath, strokePaint);

    // Vertex dots
    final dotPaint = Paint()..color = Colors.white;
    for (final pt in scorePoints) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MasteryRadarPainter oldDelegate) {
    return oldDelegate.masteryScores != masteryScores;
  }
}
