// ============================================================================
// NephroLab 3D: Renal Master Vitals & Pharmacological Drug MoA Overlays
// ----------------------------------------------------------------------------
// Visualizes:
// 1. Core Renal Hemodynamics: eGFR, RPP (MAP - CVP), Urine Output, Serum Cr,
//    BUN, Serum Potassium, and Drug Clearance Multiplier (CL_ratio).
// 2. Site-of-Action Drug Targets: SGLT2 (Dapagliflozin), Efferent Arteriole (ACEi),
//    NKCC2 (Furosemide), NCCT (Thiazides), ENaC (Spironolactone), V2/AQP2 (Tolvaptan).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';

class NephroVitalsAndDrugsPanel extends StatelessWidget {
  final NephroMasterVitalsState vitals;
  final String? activeDrugId;
  final ValueChanged<String?> onSelectDrug;

  const NephroVitalsAndDrugsPanel({
    super.key,
    required this.vitals,
    this.activeDrugId,
    required this.onSelectDrug,
  });

  static const List<({
    String id,
    String name,
    String segment,
    String moa,
    Color color,
  })> drugPresets = [
    (
      id: 'sglt2',
      name: 'Dapagliflozin (SGLT2i)',
      segment: 'Proximal Convoluted Tubule (PCT)',
      moa: 'Blocks 90% of glucose & Na⁺ reabsorption in S1/S2 PCT; reduces intraglomerular hyperfiltration.',
      color: Color(0xFFFFD600),
    ),
    (
      id: 'acei',
      name: 'Lisinopril / Losartan (ACEi / ARB)',
      segment: 'Efferent Arteriole & RAAS',
      moa: 'Dilates efferent arteriole > afferent; lowers intraglomerular pressure, reduces proteinuria.',
      color: Color(0xFFFF5252),
    ),
    (
      id: 'nkcc2',
      name: 'Furosemide (Loop Diuretic)',
      segment: 'Thick Ascending Limb (TAL)',
      moa: 'Inhibits luminal Na⁺-K⁺-2Cl⁻ (NKCC2) symporter; dissipates medullary hypertonicity.',
      color: Color(0xFF00E5FF),
    ),
    (
      id: 'ncct',
      name: 'Hydrochlorothiazide (Thiazide)',
      segment: 'Distal Convoluted Tubule (DCT)',
      moa: 'Inhibits apical Na⁺-Cl⁻ cotransporter (NCCT); increases distal Na⁺ delivery and Ca²⁺ reabsorption.',
      color: Color(0xFFAB47BC),
    ),
    (
      id: 'enac',
      name: 'Spironolactone (MRA)',
      segment: 'Late DCT & Cortical Collecting Duct',
      moa: 'Competitive aldosterone antagonist; downregulates ENaC & basolateral Na⁺/K⁺-ATPase.',
      color: Color(0xFF00E676),
    ),
    (
      id: 'aqp2',
      name: 'Tolvaptan (V2 Antagonist)',
      segment: 'Medullary Collecting Duct',
      moa: 'Selective Vasopressin V2 receptor antagonist; blocks Aquaporin-2 channel fusion, produces aquaresis.',
      color: Color(0xFF38BDF8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF00E676), size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RENAL HEMODYNAMICS & ADME CLEARANCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Perfusion Pressure · Glomerular Filtration · Nephro-Target MoA',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.0),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Renal Vitals Grid ──────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _vitalTile('eGFR', '${vitals.egfrMlMin.round()}', 'mL/min', vitals.egfrMlMin < 30 ? const Color(0xFFFF5252) : const Color(0xFF00E676)),
              _vitalTile('RPP', '${vitals.rppMmHg.round()}', 'mmHg', vitals.rppMmHg < 60 ? const Color(0xFFFFB300) : const Color(0xFF00E5FF)),
              _vitalTile('Urine Flow', vitals.urineOutputMlKgH.toStringAsFixed(2), 'mL/kg/h', vitals.isOliguric ? const Color(0xFFFF1744) : const Color(0xFF38BDF8)),
              _vitalTile('Serum Cr', vitals.serumCreatinineMgDl.toStringAsFixed(1), 'mg/dL', vitals.serumCreatinineMgDl > 2.0 ? const Color(0xFFFF5252) : const Color(0xFFE2E8F0)),
              _vitalTile('BUN', '${vitals.bunMgDl.round()}', 'mg/dL', vitals.bunMgDl > 40 ? const Color(0xFFFF9100) : const Color(0xFFCBD5E1)),
              _vitalTile('Serum K⁺', vitals.potassiumMeqL.toStringAsFixed(1), 'mEq/L', vitals.potassiumMeqL >= 6.0 ? const Color(0xFFD50000) : (vitals.potassiumMeqL < 3.5 ? const Color(0xFFFFB74D) : const Color(0xFF00E676))),
              _vitalTile('CL Ratio', '${(vitals.clearanceRatio * 100).round()}%', 'normal', vitals.clearanceRatio < 0.5 ? const Color(0xFFFF5252) : const Color(0xFF00E676)),
            ],
          ),

          const SizedBox(height: 12),

          // ── Drug MoA Site-of-Action Overlays ───────────────────────────────
          const Text(
            'PHARMACOLOGICAL SITE-OF-ACTION OVERLAYS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: drugPresets.map((d) {
                final isSel = activeDrugId == d.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: Key('nephro_drug_${d.id}'),
                    onTap: () => onSelectDrug(isSel ? null : d.id),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel
                            ? d.color.withValues(alpha: 0.25)
                            : const Color(0xFF040814),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? d.color : const Color(0xFF1E293B),
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medication_rounded, size: 12, color: d.color),
                          const SizedBox(width: 4),
                          Text(
                            d.name,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? d.color : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (activeDrugId != null) ...[
            const SizedBox(height: 8),
            _buildActiveDrugCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveDrugCard() {
    final drug = drugPresets.firstWhere((d) => d.id == activeDrugId, orElse: () => drugPresets.first);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: drug.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: drug.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                drug.name,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: drug.color,
                ),
              ),
              const Spacer(),
              Text(
                drug.segment,
                style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            drug.moa,
            style: const TextStyle(fontSize: 9.0, color: Color(0xFFE2E8F0), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _vitalTile(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(' $unit', style: const TextStyle(fontSize: 8.0, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }
}
