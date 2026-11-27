// ============================================================================
// NephroLab 3D: Real-Time ABG, Anion Gap, Winter's & Delta-Delta ICU Suite
// ----------------------------------------------------------------------------
// Calculates and displays:
// 1. Albumin-Corrected Anion Gap: Na - (Cl + HCO3) + 2.5 * (4.0 - Albumin)
// 2. Winter's Formula for metabolic acidosis compensation: 1.5 * HCO3 + 8 +/- 2
// 3. Delta-Delta (Delta AG / Delta HCO3) ratio for mixed triple acid-base disorders
// 4. One-tap bedside clinical presets (DKA, Cardiorenal Shock, Salicylates, Uremia)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';

class NephroAcidBasePanel extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroAcidBasePanel({
    super.key,
    required this.vitals,
  });

  @override
  State<NephroAcidBasePanel> createState() => _NephroAcidBasePanelState();
}

class _NephroAcidBasePanelState extends State<NephroAcidBasePanel> {
  @override
  void initState() {
    super.initState();
    widget.vitals.addListener(_onVitalsChanged);
  }

  @override
  void dispose() {
    widget.vitals.removeListener(_onVitalsChanged);
    super.dispose();
  }

  void _onVitalsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vitals;
    final agCorr = v.correctedAnionGap;
    final winter = v.winterExpectedPaCO2;
    final dd = v.deltaDeltaRatio;

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
          // ── Header & Active Preset ─────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.calculate_rounded, color: Color(0xFF00E5FF), size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABG, ANION GAP & WINTER’S SUITE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Albumin-Corrected AG · Winter Compensation · Δ/Δ Ratio',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Clinical Preset Chips ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NephroClinicalSituation.values.map((sit) {
                final isSel = v.activeSituation == sit;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: Key('nephro_situation_${sit.id}'),
                    onTap: () => v.applySituation(sit),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel
                            ? sit.accentColor.withValues(alpha: 0.25)
                            : const Color(0xFF040814),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? sit.accentColor : const Color(0xFF1E293B),
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: sit.accentColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sit.shortLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? sit.accentColor : const Color(0xFF94A3B8),
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

          const SizedBox(height: 12),

          // ── ABG Value Tiles Row ────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metricTile('pH', v.ph.toStringAsFixed(2), '', v.ph < 7.35 ? const Color(0xFFFF5252) : (v.ph > 7.45 ? const Color(0xFF00E5FF) : const Color(0xFF00E676))),
              _metricTile('PaCO₂', '${v.paco2MmHg.round()}', 'mmHg', const Color(0xFF7C4DFF)),
              _metricTile('HCO₃⁻', '${v.hco3MeqL.round()}', 'mEq/L', const Color(0xFFFFB74D)),
              _metricTile('Na⁺', '${v.sodiumMeqL.round()}', 'mEq/L', const Color(0xFF38BDF8)),
              _metricTile('Cl⁻', '${v.chlorideMeqL.round()}', 'mEq/L', const Color(0xFF81C784)),
              _metricTile('Albumin', v.albuminGDl.toStringAsFixed(1), 'g/dL', const Color(0xFFE2E8F0)),
            ],
          ),

          const SizedBox(height: 12),

          // ── Diagnostic Results & Formulas Box ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF040814).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Corrected Anion Gap
                Row(
                  children: [
                    const Icon(Icons.scatter_plot_rounded, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Anion Gap (Albumin-Corrected): ${agCorr.toStringAsFixed(1)} mEq/L',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: agCorr > 12.0 ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      agCorr > 12.0 ? 'ELEVATED (HAGMA)' : 'NORMAL GAP (8–12)',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: agCorr > 12.0 ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Formula: [Na⁺ (${v.sodiumMeqL.round()}) - (Cl⁻ (${v.chlorideMeqL.round()}) + HCO₃⁻ (${v.hco3MeqL.round()}))] + 2.5 × (4.0 - Albumin (${v.albuminGDl.toStringAsFixed(1)})) = ${agCorr.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),

                const Divider(height: 14, color: Color(0xFF1E293B)),

                // 2. Winter's Formula
                Row(
                  children: [
                    const Icon(Icons.air_rounded, size: 14, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Winter’s Expected PaCO₂: ${(winter - 2).round()}–${(winter + 2).round()} mmHg (Obs: ${v.paco2MmHg.round()})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected PaCO₂ = 1.5 × [HCO₃⁻] + 8 ± 2 = ${winter.toStringAsFixed(1)} ± 2 mmHg',
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),

                if (v.hco3MeqL < 22.0) ...[
                  const SizedBox(height: 4),
                  Text(
                    v.paco2MmHg > winter + 2.0
                        ? '⚠️ PaCO₂ > Expected: Inadequate respiratory compensation → Secondary Respiratory Acidosis (hypoventilation / fatigue).'
                        : (v.paco2MmHg < winter - 2.0
                            ? '⚠️ PaCO₂ < Expected: Excessive hyperventilation → Concurrent Respiratory Alkalosis (sepsis / salicylate).'
                            : '✓ PaCO₂ within range: Appropriate respiratory compensation.'),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: (v.paco2MmHg > winter + 2.0 || v.paco2MmHg < winter - 2.0)
                          ? const Color(0xFFFFB300)
                          : const Color(0xFF00E676),
                    ),
                  ),
                ],

                const Divider(height: 14, color: Color(0xFF1E293B)),

                // 3. Delta-Delta Ratio
                Row(
                  children: [
                    const Icon(Icons.change_circle_rounded, size: 14, color: Color(0xFFAB47BC)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dd != null
                            ? 'Delta-Delta (Δ/Δ) Ratio: ${dd.toStringAsFixed(2)}'
                            : 'Delta-Delta: N/A (Baseline HCO₃⁻ ~24)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Δ/Δ = (Corrected AG - 12) / (24 - HCO₃⁻)',
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),

                const Divider(height: 14, color: Color(0xFF1E293B)),

                // 4. Serum Osmolar Gap
                Row(
                  children: [
                    const Icon(Icons.science_rounded, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Serum Osmolar Gap: ${v.osmolarGap.toStringAsFixed(1)} mOsm/kg (Calc: ${v.calculatedOsmolality.round()} | Meas: ${v.measuredOsmolality.round()})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: v.isElevatedOsmolarGap ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      v.isElevatedOsmolarGap ? 'ELEVATED (>10)' : 'NORMAL GAP (<10)',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: v.isElevatedOsmolarGap ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Calc Osm = 2×Na⁺ + Glucose/18 + BUN/2.8 = ${v.calculatedOsmolality.toStringAsFixed(1)} mOsm/kg',
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),
                if (v.isElevatedOsmolarGap) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '⚠️ Elevated Osmolar Gap > 10 mOsm/kg: Strongly suggests unmeasured osmotically active toxin (Ethylene Glycol, Methanol, Propylene Glycol). Administer Fomepizole stat.',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFFFFB300), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Automated Clinical Interpretation Banner ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, size: 14, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    v.acidBaseInterpretation,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF),
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

  Widget _metricTile(String label, String value, String unit, Color color) {
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
