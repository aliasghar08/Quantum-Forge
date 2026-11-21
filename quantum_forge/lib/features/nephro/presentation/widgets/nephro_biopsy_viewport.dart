// ============================================================================
// NephroLab 3D: Virtual Renal Biopsy (LM / IF / EM) Pathology Viewport
// ----------------------------------------------------------------------------
// Simulates high-resolution procedural microscopic pathology examination:
// - Light Microscopy (LM): H&E, PAS, Jones Methenamine Silver
// - Immunofluorescence (IF): Linear, Granular, Starry-Sky, Full-House, Pauci-Immune
// - Electron Microscopy (EM): Podocyte effacement, Subepithelial humps, Wire-loops
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/nephro_master_vitals_state.dart';
import 'nephro_full_screen_biopsy_theater.dart';

enum BiopsyModalStain {
  lmHe('Light Microscopy (H&E)', 'LM (H&E)', Color(0xFFF43F5E)),
  lmPas('PAS (Periodic Acid-Schiff)', 'LM (PAS)', Color(0xFFD946EF)),
  lmSilver('Jones Methenamine Silver', 'LM (Silver)', Color(0xFF64748B)),
  ifGranular('Immunofluorescence (IF)', 'IF Stain', Color(0xFF10B981)),
  emUltra('Electron Microscopy (EM)', 'EM Ultra', Color(0xFF94A3B8));

  final String label;
  final String shortCode;
  final Color tintColor;

  const BiopsyModalStain(this.label, this.shortCode, this.tintColor);
}

enum GlomerularDiseasePattern {
  mcd('Minimal Change Disease', 'Effacement of podocyte foot processes; normal LM.', 'Nephrotic'),
  fsgs('Focal Segmental Glomerulosclerosis', 'Segmental sclerosis & hyalinosis in juxtamedullary glomeruli.', 'Nephrotic'),
  membranous('Membranous Nephropathy', 'Subepithelial spike-and-dome deposits with thickened GBM.', 'Nephrotic'),
  igaNephropathy('IgA Nephropathy (Berger)', 'Mesangial proliferation and granular IgA/C3 deposition.', 'Nephritic'),
  psgn('Post-Streptococcal GN', 'Subepithelial "humps" on EM, starry-sky granular IF.', 'Nephritic'),
  mpgn('Membranoproliferative GN', 'Tram-track GBM splitting on silver stain; mesangial interposition.', 'Mixed'),
  lupusClassIV('Diffuse Proliferative Lupus GN', 'Subendothelial wire-loop lesions; "Full House" IF.', 'Mixed'),
  antiGbm('Anti-GBM / Goodpasture', 'Crescentic necrotizing GN with linear IgG along GBM.', 'Nephritic');

  final String title;
  final String diagnosticFinding;
  final String syndromeType;

  const GlomerularDiseasePattern(this.title, this.diagnosticFinding, this.syndromeType);
}

class NephroBiopsyViewport extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroBiopsyViewport({super.key, required this.vitals});

  @override
  State<NephroBiopsyViewport> createState() => _NephroBiopsyViewportState();
}

class _NephroBiopsyViewportState extends State<NephroBiopsyViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  BiopsyModalStain _selectedStain = BiopsyModalStain.lmPas;
  GlomerularDiseasePattern _selectedDisease = GlomerularDiseasePattern.membranous;
  final double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.biotech_rounded, size: 14, color: Color(0xFFD946EF)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'RENAL BIOPSY PATHOLOGY (LM / IF / EM)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Stain Picker
                DropdownButtonHideUnderline(
                  child: DropdownButton<BiopsyModalStain>(
                    value: _selectedStain,
                    dropdownColor: const Color(0xFF0F172A),
                    isDense: true,
                    style: TextStyle(color: _selectedStain.tintColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                    items: BiopsyModalStain.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.shortCode));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStain = val);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Full-Screen Pathology Theater',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFFD946EF)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NephroFullScreenBiopsyTheater(vitals: widget.vitals),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Microscopic Field
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RenalBiopsyPainter(
                    phase: _anim.value,
                    stain: _selectedStain,
                    disease: _selectedDisease,
                    zoom: _zoomLevel,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Footer Diagnostic Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFF0B132B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<GlomerularDiseasePattern>(
                      value: _selectedDisease,
                      dropdownColor: const Color(0xFF0F172A),
                      isDense: true,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      items: GlomerularDiseasePattern.values.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d.title));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDisease = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDisease.diagnosticFinding,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedDisease.syndromeType == 'Nephrotic'
                          ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _selectedDisease.syndromeType == 'Nephrotic'
                            ? const Color(0xFF0284C7)
                            : const Color(0xFFEF4444),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _selectedDisease.syndromeType,
                      style: TextStyle(
                        color: _selectedDisease.syndromeType == 'Nephrotic'
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFF87171),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenalBiopsyPainter extends CustomPainter {
  final double phase;
  final BiopsyModalStain stain;
  final GlomerularDiseasePattern disease;
  final double zoom;

  _RenalBiopsyPainter({
    required this.phase,
    required this.stain,
    required this.disease,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2.0, h / 2.0);

    // Background based on stain modality
    Color bgColor;
    if (stain == BiopsyModalStain.ifGranular) {
      bgColor = const Color(0xFF020408); // pitch dark fluorescent background
    } else if (stain == BiopsyModalStain.emUltra) {
      bgColor = const Color(0xFF18181B); // transmission electron grayscale
    } else if (stain == BiopsyModalStain.lmSilver) {
      bgColor = const Color(0xFFF8FAFC); // silver background
    } else if (stain == BiopsyModalStain.lmPas) {
      bgColor = const Color(0xFFFFF1F2); // pale pink PAS background
    } else {
      bgColor = const Color(0xFFFFFAF0); // H&E light background
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = bgColor);

    // Draw Glomerular Tuft / Capillary Loops
    final radius = math.min(w, h) * 0.38 * zoom;

    if (stain == BiopsyModalStain.ifGranular) {
      _paintImmunofluorescence(canvas, center, radius);
    } else if (stain == BiopsyModalStain.emUltra) {
      _paintElectronMicroscopy(canvas, center, radius);
    } else {
      _paintLightMicroscopy(canvas, center, radius);
    }
  }

  void _paintImmunofluorescence(Canvas canvas, Offset center, double radius) {
    final ifGreen = const Color(0xFF22C55E); // Apple green fluorescein (FITC)
    final ifPaint = Paint()
      ..color = ifGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    if (disease == GlomerularDiseasePattern.antiGbm) {
      // Linear smooth ribbon-like IgG deposition along all GBM loops
      for (int i = 0; i < 6; i++) {
        final angle = (i / 6.0) * 2.0 * math.pi;
        final loopCenter = center + Offset(math.cos(angle) * (radius * 0.55), math.sin(angle) * (radius * 0.55));
        canvas.drawCircle(loopCenter, radius * 0.35, ifPaint);
      }
    } else {
      // Granular discrete immune complex clumping
      final dotPaint = Paint()..color = ifGreen..style = PaintingStyle.fill;
      final int nDots = (disease == GlomerularDiseasePattern.lupusClassIV) ? 90 : 55;

      for (int i = 0; i < nDots; i++) {
        final r = (i / nDots) * radius * 0.9;
        final theta = i * 2.39996 + phase * 0.5; // Golden ratio spiral
        final pt = center + Offset(math.cos(theta) * r, math.sin(theta) * r);
        final dotSize = 2.0 + (i % 3) * 1.2;
        canvas.drawCircle(pt, dotSize, dotPaint);
      }
    }
  }

  void _paintElectronMicroscopy(Canvas canvas, Offset center, double radius) {
    // Grayscale EM drawing of GBM, podocytes, and deposits
    final gbmPaint = Paint()
      ..color = const Color(0xFF52525B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final capillaryPath = Path();
    capillaryPath.addOval(Rect.fromCenter(center: center, width: radius * 1.4, height: radius * 1.1));
    canvas.drawPath(capillaryPath, gbmPaint);

    if (disease == GlomerularDiseasePattern.mcd || disease == GlomerularDiseasePattern.fsgs) {
      // Diffuse podocyte foot process effacement (continuous flat layer)
      final effacedPaint = Paint()
        ..color = const Color(0xFFA1A1AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0;
      canvas.drawOval(Rect.fromCenter(center: center, width: radius * 1.55, height: radius * 1.25), effacedPaint);
    } else if (disease == GlomerularDiseasePattern.psgn) {
      // Discrete subepithelial electron-dense humps
      final humpPaint = Paint()..color = const Color(0xFF27272A)..style = PaintingStyle.fill;
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8.0) * 2.0 * math.pi;
        final humpPos = center + Offset(math.cos(angle) * (radius * 0.78), math.sin(angle) * (radius * 0.62));
        canvas.drawCircle(humpPos, 7.0, humpPaint);
      }
    } else if (disease == GlomerularDiseasePattern.membranous) {
      // Spike-and-dome subepithelial deposits
      final spikePaint = Paint()..color = const Color(0xFF3F3F46)..strokeWidth = 3.0;
      for (int i = 0; i < 20; i++) {
        final angle = (i / 20.0) * 2.0 * math.pi;
        final p1 = center + Offset(math.cos(angle) * (radius * 0.70), math.sin(angle) * (radius * 0.55));
        final p2 = center + Offset(math.cos(angle) * (radius * 0.82), math.sin(angle) * (radius * 0.65));
        canvas.drawLine(p1, p2, spikePaint);
      }
    }
  }

  void _paintLightMicroscopy(Canvas canvas, Offset center, double radius) {
    Color gbmColor = (stain == BiopsyModalStain.lmSilver) ? const Color(0xFF0F172A) : const Color(0xFFBE185D);
    Color cellularColor = (stain == BiopsyModalStain.lmPas) ? const Color(0xFFC026D3) : const Color(0xFF4338CA);

    // Bowman's capsule ring
    final bowmanPaint = Paint()
      ..color = gbmColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, bowmanPaint);

    // Capillary tuft loops
    final loopPaint = Paint()
      ..color = gbmColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (disease == GlomerularDiseasePattern.membranous) ? 4.5 : 2.0;

    for (int i = 0; i < 7; i++) {
      final angle = (i / 7.0) * 2.0 * math.pi;
      final loopCenter = center + Offset(math.cos(angle) * (radius * 0.50), math.sin(angle) * (radius * 0.50));
      canvas.drawCircle(loopCenter, radius * 0.32, loopPaint);

      // Tram-track splitting in MPGN
      if (disease == GlomerularDiseasePattern.mpgn && stain == BiopsyModalStain.lmSilver) {
        canvas.drawCircle(loopCenter, radius * 0.37, loopPaint..strokeWidth = 1.0);
      }
    }

    // Mesangial nuclei
    final nucleiPaint = Paint()..color = cellularColor.withValues(alpha: 0.85);
    final int nNuclei = (disease == GlomerularDiseasePattern.igaNephropathy) ? 35 : 18;
    for (int i = 0; i < nNuclei; i++) {
      final r = (i / nNuclei) * radius * 0.7;
      final theta = i * 1.8;
      canvas.drawCircle(center + Offset(math.cos(theta) * r, math.sin(theta) * r), 3.0, nucleiPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RenalBiopsyPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.stain != stain ||
        oldDelegate.disease != disease ||
        oldDelegate.zoom != zoom;
  }
}
