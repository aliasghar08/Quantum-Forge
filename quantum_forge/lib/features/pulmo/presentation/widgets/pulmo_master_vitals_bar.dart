// ============================================================================
// PulmoVent 3D: Master Vitals & Situation Trigger Bar
// ----------------------------------------------------------------------------
// Top telemetry HUD providing:
// 1. 8 1-Tap ICU Clinical Situation Triggers: Normal, Severe ARDS, Status Asthmaticus,
//    COPD Auto-PEEP, Tension Pneumothorax, Cardiogenic Edema, Massive PE, Opioid OD.
// 2. Real-Time ABG & Mechanics Telemetry: PaO2, PaCO2, pH, P/F, A-a, Pplat, ΔP, PEEP.
// 3. Multi-Organ Coupling status indicator.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

class PulmoMasterVitalsBar extends StatelessWidget {
  final PulmoMasterVitalsState vitals;

  const PulmoMasterVitalsBar({
    super.key,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Telemetry Badges & Auto-Pilot Toggle
          Row(
            children: [
              // Active Situation Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vitals.activeSituation.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: vitals.activeSituation.accentColor),
                ),
                child: Text(
                  vitals.activeSituation.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: vitals.activeSituation.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Telemetry Readouts
              _badge('PaO₂', '${vitals.pao2MmHg.round()}', 'mmHg',
                  vitals.pao2MmHg < 60 ? const Color(0xFFFF1744) : const Color(0xFF00E676)),
              const SizedBox(width: 6),
              _badge('PaCO₂', '${vitals.paco2MmHg.round()}', 'mmHg',
                  vitals.paco2MmHg > 50 ? const Color(0xFFFF9100) : const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              _badge('pH', vitals.arterialPh.toStringAsFixed(2), '',
                  vitals.arterialPh < 7.30 ? const Color(0xFFFF1744) : const Color(0xFF00E676)),
              const SizedBox(width: 6),
              _badge('P/F Ratio', '${vitals.pfRatio.round()}', '',
                  vitals.pfRatio < 150 ? const Color(0xFFFF5252) : const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _badge('A-a Gradient', '${vitals.alveolarArterialGradient.round()}', 'mmHg',
                  vitals.alveolarArterialGradient > 30 ? const Color(0xFFFFB300) : const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              _badge('SpO₂', '${vitals.spo2Percent.round()}%', '',
                  vitals.spo2Percent < 90 ? const Color(0xFFFF1744) : const Color(0xFF00E676)),

              const Spacer(),

              // Auto-Pilot Status
              if (!vitals.isAutoPilot)
                ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded, size: 12),
                  label: const Text('Reset to Preset', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF00E5FF),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: vitals.resetToAutoPilot,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom Row: 8 1-Tap ICU Situation Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PulmoClinicalSituation.values.map((situation) {
                final isSelected = vitals.activeSituation == situation;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      situation.shortLabel,
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: isSelected,
                    selectedColor: situation.accentColor.withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: isSelected ? situation.accentColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? situation.accentColor : const Color(0xFF1E293B),
                    ),
                    onSelected: (_) => vitals.applySituation(situation),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 9, color: Colors.white60)),
          Text(value, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 8, color: Colors.white38)),
          ],
        ],
      ),
    );
  }
}
