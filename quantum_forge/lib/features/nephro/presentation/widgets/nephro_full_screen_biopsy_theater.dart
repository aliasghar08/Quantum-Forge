// ============================================================================
// NephroLab 3D: Full-Screen Virtual Renal Biopsy (LM / IF / EM) Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport interactive renal pathology workstation.
// Switches seamlessly between Light Microscopy (H&E, PAS, Silver),
// Immunofluorescence (FITC green), and Electron Microscopy (ultrastructure).
// Features interactive pan/zoom, disease presets, and 🏷️ Pathology Name Tags.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/nephro_master_vitals_state.dart';
import 'nephro_biopsy_viewport.dart';

class NephroFullScreenBiopsyTheater extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroFullScreenBiopsyTheater({super.key, required this.vitals});

  @override
  State<NephroFullScreenBiopsyTheater> createState() =>
      _NephroFullScreenBiopsyTheaterState();
}

class _NephroFullScreenBiopsyTheaterState
    extends State<NephroFullScreenBiopsyTheater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  BiopsyModalStain _selectedStain = BiopsyModalStain.lmPas;
  GlomerularDiseasePattern _selectedDisease = GlomerularDiseasePattern.membranous;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;
  Offset? _lastPan;
  bool _showTags = true;

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
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Column(
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FULL-SCREEN RENAL BIOPSY & PATHOLOGY THEATER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Light Microscopy · Periodic Acid-Schiff · Jones Silver · Immunofluorescence · EM',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Tags Toggle
                  FilterChip(
                    label: const Text('🏷️ Tags', style: TextStyle(fontSize: 10)),
                    selected: _showTags,
                    onSelected: (val) => setState(() => _showTags = val),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  // Reset Zoom
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Reset Zoom & Pan',
                    onPressed: () => setState(() {
                      _zoom = 1.0;
                      _panOffset = Offset.zero;
                    }),
                  ),
                ],
              ),
            ),

            // Main Field & Diagnostics
            Expanded(
              child: Row(
                children: [
                  // Microscopic Canvas
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onScaleStart: (details) => _lastPan = details.localFocalPoint,
                      onScaleUpdate: (details) {
                        setState(() {
                          _zoom = (_zoom * details.scale).clamp(0.6, 3.5);
                          if (_lastPan != null) {
                            _panOffset += details.localFocalPoint - _lastPan!;
                            _lastPan = details.localFocalPoint;
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _anim,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _FullScreenBiopsyPainter(
                                    phase: _anim.value,
                                    stain: _selectedStain,
                                    disease: _selectedDisease,
                                    zoom: _zoom,
                                    panOffset: _panOffset,
                                    showTags: _showTags,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Stain Modality Bar
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: BiopsyModalStain.values.map((stain) {
                                  final isSel = stain == _selectedStain;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: ChoiceChip(
                                      label: Text(stain.shortCode, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : const Color(0xFF94A3B8))),
                                      selected: isSel,
                                      selectedColor: stain.tintColor,
                                      backgroundColor: const Color(0xFF1E293B),
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedStain = stain);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Diagnostics & Disease Card Sidebar
                  Container(
                    width: 330,
                    color: const Color(0xFF090E1A),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GLOMERULOPATHY SELECTOR',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<GlomerularDiseasePattern>(
                              value: _selectedDisease,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              items: GlomerularDiseasePattern.values.map((d) {
                                return DropdownMenuItem(value: d, child: Text(d.title));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDisease = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDiagnosticSection('Light Microscopy (LM)', _getLmDescription()),
                        _buildDiagnosticSection('Immunofluorescence (IF)', _getIfDescription()),
                        _buildDiagnosticSection('Electron Microscopy (EM)', _getEmDescription()),
                        _buildDiagnosticSection('Clinical Presentation', _getClinicalPresentation()),
                        const Divider(color: Color(0xFF1E293B), height: 20),
                        const Text(
                          'NEPHROLOGY BOARD PEARL',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _getBoardPearl(),
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5, height: 1.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(content, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  String _getLmDescription() {
    switch (_selectedDisease) {
      case GlomerularDiseasePattern.mcd:
        return 'Normal glomeruli on LM. No sclerosis or hypercellularity.';
      case GlomerularDiseasePattern.fsgs:
        return 'Segmental sclerosis and hyalinosis in some glomeruli.';
      case GlomerularDiseasePattern.membranous:
        return 'Uniform diffuse thickening of GBM without hypercellularity.';
      case GlomerularDiseasePattern.igaNephropathy:
        return 'Mesangial expansion and hypercellularity.';
      case GlomerularDiseasePattern.psgn:
        return 'Diffuse endocapillary proliferation and neutrophilic influx.';
      case GlomerularDiseasePattern.mpgn:
        return 'Lobular accentuation with "tram-track" GBM double contours.';
      case GlomerularDiseasePattern.lupusClassIV:
        return 'Wire-loop capillary lesions and diffuse proliferative GN.';
      case GlomerularDiseasePattern.antiGbm:
        return 'Extensive cellular crescents compressing glomerular tufts.';
    }
  }

  String _getIfDescription() {
    switch (_selectedDisease) {
      case GlomerularDiseasePattern.mcd:
        return 'Negative / non-specific.';
      case GlomerularDiseasePattern.fsgs:
        return 'Non-specific focal IgM and C3 in sclerotic segments.';
      case GlomerularDiseasePattern.membranous:
        return 'Granular IgG and C3 along glomerular capillary walls.';
      case GlomerularDiseasePattern.igaNephropathy:
        return 'Strong mesangial granular IgA and C3 deposition.';
      case GlomerularDiseasePattern.psgn:
        return 'Granular "starry-sky" IgG, IgM, and C3 along capillary walls.';
      case GlomerularDiseasePattern.mpgn:
        return 'Granular C3 and IgG along GBM and mesangium.';
      case GlomerularDiseasePattern.lupusClassIV:
        return '"Full House": strong IgG, IgA, IgM, C3, and C1q staining.';
      case GlomerularDiseasePattern.antiGbm:
        return 'Classic smooth linear ribbon-like IgG along GBM.';
    }
  }

  String _getEmDescription() {
    switch (_selectedDisease) {
      case GlomerularDiseasePattern.mcd:
        return 'Diffuse effacement of visceral epithelial (podocyte) foot processes.';
      case GlomerularDiseasePattern.fsgs:
        return 'Podocyte foot process effacement with focal denudation of GBM.';
      case GlomerularDiseasePattern.membranous:
        return 'Subepithelial spike-and-dome electron-dense deposits.';
      case GlomerularDiseasePattern.igaNephropathy:
        return 'Electron-dense deposits confined to the mesangial matrix.';
      case GlomerularDiseasePattern.psgn:
        return 'Large subepithelial electron-dense "humps".';
      case GlomerularDiseasePattern.mpgn:
        return 'Subendothelial deposits with mesangial cellular interposition.';
      case GlomerularDiseasePattern.lupusClassIV:
        return 'Prominent subendothelial wire-loop electron-dense deposits.';
      case GlomerularDiseasePattern.antiGbm:
        return 'GBM disruptions with fibrin deposition in Bowman\'s space.';
    }
  }

  String _getClinicalPresentation() {
    switch (_selectedDisease) {
      case GlomerularDiseasePattern.mcd:
        return 'Children with sudden massive selective proteinuria and facial edema. Excellent steroid response.';
      case GlomerularDiseasePattern.fsgs:
        return 'Non-selective proteinuria in adults, common in APOL1 risk alleles or HIV. Poor steroid response.';
      case GlomerularDiseasePattern.membranous:
        return 'Adult nephrotic syndrome associated with anti-PLA2R antibodies, solid tumors, or NSAIDs.';
      case GlomerularDiseasePattern.igaNephropathy:
        return 'Young adults with synpharyngitic macroscopic hematuria 1-2 days after upper respiratory infection.';
      case GlomerularDiseasePattern.psgn:
        return 'Children 1-3 weeks post-streptococcal pharyngitis/impetigo with cola-colored urine, edema, and low C3.';
      case GlomerularDiseasePattern.mpgn:
        return 'Associated with Hepatitis C, cryoglobulinemia, or dysproteinemias. Chronic low C3/C4.';
      case GlomerularDiseasePattern.lupusClassIV:
        return 'SLE patients with active urinary sediment, RBC casts, low complement, and anti-dsDNA.';
      case GlomerularDiseasePattern.antiGbm:
        return 'Pulmonary-renal syndrome with hemoptysis and rapidly progressive renal failure (RPGN).';
    }
  }

  String _getBoardPearl() {
    switch (_selectedDisease) {
      case GlomerularDiseasePattern.mcd:
        return '• Minimal Change Disease is the most common cause of childhood nephrotic syndrome. Podocyte effacement is completely reversible with corticosteroids.';
      case GlomerularDiseasePattern.fsgs:
        return '• Collapsing variant of FSGS is classically associated with HIV (HIVAN) and high-risk APOL1 G1/G2 genotype in individuals of African ancestry.';
      case GlomerularDiseasePattern.membranous:
        return '• 70-80% of primary Membranous cases are driven by autoantibodies against the M-type Phospholipase A2 Receptor (anti-PLA2R1). High risk of renal vein thrombosis!';
      case GlomerularDiseasePattern.igaNephropathy:
        return '• Berger disease is the most common primary glomerulonephritis worldwide. Synpharyngitic hematuria occurs concurrently with infection, unlike PSGN (1-3 weeks later).';
      case GlomerularDiseasePattern.psgn:
        return '• Elevated ASO or anti-DNase B titers with depressed serum C3 that normalizes within 6-8 weeks. Subepithelial humps resolve spontaneously.';
      case GlomerularDiseasePattern.mpgn:
        return '• Type I (immune complex mediated) vs Type II (Dense Deposit Disease, mediated by C3 Nephritic Factor autoantibody stabilizing C3 convertase).';
      case GlomerularDiseasePattern.lupusClassIV:
        return '• Class IV is the most aggressive lupus nephritis class requiring intensive immunosuppression with mycophenolate mofetil or cyclophosphamide plus steroids.';
      case GlomerularDiseasePattern.antiGbm:
        return '• Antibodies target the non-collagenous domain (NC1) of α3 chain of type IV collagen. Emergency plasmapheresis is mandatory to prevent permanent ESRD.';
    }
  }
}

class _FullScreenBiopsyPainter extends CustomPainter {
  final double phase;
  final BiopsyModalStain stain;
  final GlomerularDiseasePattern disease;
  final double zoom;
  final Offset panOffset;
  final bool showTags;

  _FullScreenBiopsyPainter({
    required this.phase,
    required this.stain,
    required this.disease,
    required this.zoom,
    required this.panOffset,
    required this.showTags,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2.0, h / 2.0) + panOffset;

    Color bg;
    if (stain == BiopsyModalStain.ifGranular) {
      bg = const Color(0xFF020408);
    } else if (stain == BiopsyModalStain.emUltra) {
      bg = const Color(0xFF18181B);
    } else if (stain == BiopsyModalStain.lmSilver) {
      bg = const Color(0xFFF1F5F9);
    } else if (stain == BiopsyModalStain.lmPas) {
      bg = const Color(0xFFFFF1F2);
    } else {
      bg = const Color(0xFFFFFAF0);
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = bg);

    final radius = math.min(w, h) * 0.36 * zoom;

    if (stain == BiopsyModalStain.ifGranular) {
      _paintImmunofluorescence(canvas, center, radius);
    } else if (stain == BiopsyModalStain.emUltra) {
      _paintElectronMicroscopy(canvas, center, radius);
    } else {
      _paintLightMicroscopy(canvas, center, radius);
    }

    if (showTags) {
      final tagPainter = TextPainter(textDirection: TextDirection.ltr);
      void drawTag(String text, Offset pos, Color color) {
        tagPainter.text = TextSpan(
          text: '🏷️ $text',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.black87),
        );
        tagPainter.layout();
        tagPainter.paint(canvas, pos);
      }

      if (stain == BiopsyModalStain.ifGranular) {
        drawTag(disease == GlomerularDiseasePattern.antiGbm ? 'Linear IgG along GBM' : 'Granular Immune Clumps', center + const Offset(-60, -80), const Color(0xFF22C55E));
      } else if (stain == BiopsyModalStain.emUltra) {
        drawTag('GBM Lamina Densa', center + const Offset(50, -40), const Color(0xFFCBD5E1));
        if (disease == GlomerularDiseasePattern.psgn) {
          drawTag('Subepithelial Hump', center + const Offset(-70, -75), const Color(0xFFF59E0B));
        } else if (disease == GlomerularDiseasePattern.membranous) {
          drawTag('Spike-and-Dome Deposits', center + const Offset(-80, -75), const Color(0xFFEC4899));
        }
      } else {
        drawTag('Bowman Capsule', center + Offset(-radius * 0.9, -radius * 0.9), const Color(0xFF0284C7));
        drawTag('Glomerular Capillary Tuft', center + const Offset(-45, 0), const Color(0xFFEF4444));
        if (disease == GlomerularDiseasePattern.igaNephropathy) {
          drawTag('Mesangial Hypercellularity', center + const Offset(20, 25), const Color(0xFFA855F7));
        }
      }
    }
  }

  void _paintImmunofluorescence(Canvas canvas, Offset center, double radius) {
    final ifGreen = const Color(0xFF22C55E);
    final ifPaint = Paint()..color = ifGreen..style = PaintingStyle.stroke..strokeWidth = 3.0;

    if (disease == GlomerularDiseasePattern.antiGbm) {
      for (int i = 0; i < 7; i++) {
        final a = (i / 7.0) * 2.0 * math.pi;
        final c = center + Offset(math.cos(a) * (radius * 0.55), math.sin(a) * (radius * 0.55));
        canvas.drawCircle(c, radius * 0.35, ifPaint);
      }
    } else {
      final dotPaint = Paint()..color = ifGreen;
      final int nDots = (disease == GlomerularDiseasePattern.lupusClassIV) ? 120 : 70;
      for (int i = 0; i < nDots; i++) {
        final r = (i / nDots) * radius * 0.92;
        final th = i * 2.39996 + phase * 0.3;
        final p = center + Offset(math.cos(th) * r, math.sin(th) * r);
        canvas.drawCircle(p, 2.5 + (i % 3) * 1.5, dotPaint);
      }
    }
  }

  void _paintElectronMicroscopy(Canvas canvas, Offset center, double radius) {
    final gbmPaint = Paint()..color = const Color(0xFF52525B)..style = PaintingStyle.stroke..strokeWidth = 10.0;
    canvas.drawOval(Rect.fromCenter(center: center, width: radius * 1.5, height: radius * 1.15), gbmPaint);

    if (disease == GlomerularDiseasePattern.mcd || disease == GlomerularDiseasePattern.fsgs) {
      final effacedPaint = Paint()..color = const Color(0xFFA1A1AA)..style = PaintingStyle.stroke..strokeWidth = 6.0;
      canvas.drawOval(Rect.fromCenter(center: center, width: radius * 1.65, height: radius * 1.3), effacedPaint);
    } else if (disease == GlomerularDiseasePattern.psgn) {
      final humpPaint = Paint()..color = const Color(0xFF27272A)..style = PaintingStyle.fill;
      for (int i = 0; i < 10; i++) {
        final a = (i / 10.0) * 2.0 * math.pi;
        final p = center + Offset(math.cos(a) * (radius * 0.82), math.sin(a) * (radius * 0.65));
        canvas.drawCircle(p, 9.0, humpPaint);
      }
    } else if (disease == GlomerularDiseasePattern.membranous) {
      final spikePaint = Paint()..color = const Color(0xFF3F3F46)..strokeWidth = 3.5;
      for (int i = 0; i < 28; i++) {
        final a = (i / 28.0) * 2.0 * math.pi;
        final p1 = center + Offset(math.cos(a) * (radius * 0.74), math.sin(a) * (radius * 0.58));
        final p2 = center + Offset(math.cos(a) * (radius * 0.88), math.sin(a) * (radius * 0.69));
        canvas.drawLine(p1, p2, spikePaint);
      }
    }
  }

  void _paintLightMicroscopy(Canvas canvas, Offset center, double radius) {
    Color gbmCol = (stain == BiopsyModalStain.lmSilver) ? const Color(0xFF0F172A) : const Color(0xFFBE185D);
    Color nucCol = (stain == BiopsyModalStain.lmPas) ? const Color(0xFFC026D3) : const Color(0xFF4338CA);

    canvas.drawCircle(center, radius, Paint()..color = gbmCol..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final loopPaint = Paint()..color = gbmCol..style = PaintingStyle.stroke..strokeWidth = 2.5;
    for (int i = 0; i < 8; i++) {
      final a = (i / 8.0) * 2.0 * math.pi;
      final c = center + Offset(math.cos(a) * (radius * 0.52), math.sin(a) * (radius * 0.52));
      canvas.drawCircle(c, radius * 0.34, loopPaint);
    }

    final nucPaint = Paint()..color = nucCol.withValues(alpha: 0.85);
    final int n = (disease == GlomerularDiseasePattern.igaNephropathy) ? 45 : 24;
    for (int i = 0; i < n; i++) {
      final r = (i / n) * radius * 0.75;
      final th = i * 1.9;
      canvas.drawCircle(center + Offset(math.cos(th) * r, math.sin(th) * r), 3.5, nucPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FullScreenBiopsyPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.stain != stain ||
        oldDelegate.disease != disease ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset;
  }
}
