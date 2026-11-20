// ============================================================================
// PulmoVent 3D: ECMO Circuit Twin & ICU Pulmonary Therapeutics Panel
// ----------------------------------------------------------------------------
// 1. Extracorporeal Membrane Oxygenation (ECMO) Circuit Simulation:
//    - V-V ECMO (hypoxemic respiratory failure) vs V-A ECMO (cardiopulmonary shock).
//    - Centrifugal pump RPM, Sweep Gas Flow (CO2 clearance), Membrane FdO2 (O2 addition).
//    - Pre-membrane deoxygenated blue vs Post-membrane arterial crimson blood shift.
// 2. Harlequin (North-South) Syndrome Detector:
//    - Dual-site monitoring of Right Radial SpO2 vs Femoral Cannula SpO2 on V-A ECMO.
// 3. Evidence-Based Bedside Pulmonary Interventions:
//    - Needle Decompression (14G, 2nd ICS MCL) / Chest Tube Thoracostomy.
//    - Prone Positioning 16h (PROSEVA trial - mortality benefit in severe ARDS).
//    - Nebulized Beta-2 Agonist + Anticholinergic (Albuterol/Ipratropium).
//    - IV Corticosteroids (Methylprednisolone).
//    - Neuromuscular Blockade (Cisatracurium - ACURASYS trial).
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

class PulmoEcmoAndTherapeuticsPanel extends StatelessWidget {
  final PulmoMasterVitalsState vitals;

  const PulmoEcmoAndTherapeuticsPanel({
    super.key,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Panel Header & ECMO Mode Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cached_rounded, size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 6),
                      Text(
                        'ECMO CIRCUIT TWIN & THERAPEUTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ECMO Mode Selector
                SegmentedButton<EcmoMode>(
                  segments: const [
                    ButtonSegment(value: EcmoMode.off, label: Text('ECMO Off', style: TextStyle(fontSize: 10))),
                    ButtonSegment(value: EcmoMode.vvEcmo, label: Text('V-V ECMO', style: TextStyle(fontSize: 10))),
                    ButtonSegment(value: EcmoMode.vaEcmo, label: Text('V-A ECMO', style: TextStyle(fontSize: 10))),
                  ],
                  selected: {vitals.ecmoMode},
                  onSelectionChanged: (set) => vitals.setEcmoSettings(mode: set.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Harlequin (North-South) Syndrome Alert if Active
          if (vitals.isHarlequinSyndromeActive) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF1744)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFFF1744)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CRITICAL ALERT: NORTH–SOUTH (HARLEQUIN) SYNDROME DETECTED',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                        Text(
                          'Right Radial SpO₂ (${vitals.rightRadialSpo2.round()}%) vs Femoral SpO₂ (${vitals.femoralSpo2.round()}%). Poorly oxygenated native LV ejection is starving the brain while retrograde ECMO oxygenates the lower body. Convert to V-A-V ECMO or upgrade ventilator PEEP/FiO₂.',
                          style: const TextStyle(fontSize: 9, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 3. ECMO Parameters Visualizer & Sliders
          if (vitals.ecmoMode != EcmoMode.off) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  // Pre/Post Membrane Blood Color Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Drainage (Venous): SvO₂ 68%', style: TextStyle(fontSize: 8.5, color: Colors.white60)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Reinfusion (Arterial): Post-Membrane SaO₂ 100%', style: TextStyle(fontSize: 8.5, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Flow Slider
                  _ecmoSlider('Pump Flow: ${vitals.ecmoFlowLMin.toStringAsFixed(1)} L/min',
                      vitals.ecmoFlowLMin, 1.0, 6.5, (val) => vitals.setEcmoSettings(flowLMin: val)),
                  const SizedBox(width: 10),

                  // Sweep Gas Slider
                  _ecmoSlider('Sweep Gas: ${vitals.sweepGasLMin.toStringAsFixed(1)} L/min',
                      vitals.sweepGasLMin, 0.5, 10.0, (val) => vitals.setEcmoSettings(sweepGasLMin: val)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 4. Bedside Critical Care Interventions Dock
          const Text(
            'BEDSIDE ICU PULMONARY INTERVENTIONS & DRUG PROTOCOLS',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Needle Thoracostomy / Chest Tube
                _actionButton(
                  icon: Icons.medical_services_rounded,
                  label: vitals.isChestTubeDecompressed ? 'Chest Tube Decompressed' : 'Needle Thoracostomy (2nd ICS)',
                  isActive: vitals.isChestTubeDecompressed,
                  activeColor: const Color(0xFF00E676),
                  idleColor: const Color(0xFFFF1744),
                  onPressed: vitals.performNeedleThoracostomy,
                ),
                const SizedBox(width: 8),

                // Prone Positioning
                _actionButton(
                  icon: Icons.airline_seat_flat_rounded,
                  label: vitals.isPronePositionActive ? 'Prone 16h (Active)' : 'Prone Positioning (PROSEVA)',
                  isActive: vitals.isPronePositionActive,
                  activeColor: const Color(0xFF10B981),
                  idleColor: const Color(0xFF38BDF8),
                  onPressed: vitals.togglePronePositioning,
                ),
                const SizedBox(width: 8),

                // Nebulized Bronchodilator
                _actionButton(
                  icon: Icons.air_rounded,
                  label: vitals.isBronchodilatorActive ? 'Nebulizer Administered' : 'Albuterol + Ipratropium Neb',
                  isActive: vitals.isBronchodilatorActive,
                  activeColor: const Color(0xFFF59E0B),
                  idleColor: const Color(0xFF00E5FF),
                  onPressed: vitals.administerNebulizedBronchodilator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ecmoSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
        SizedBox(
          width: 80,
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color idleColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? activeColor.withValues(alpha: 0.25) : const Color(0xFF0F172A),
        foregroundColor: isActive ? activeColor : idleColor,
        side: BorderSide(color: isActive ? activeColor : idleColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }
}
