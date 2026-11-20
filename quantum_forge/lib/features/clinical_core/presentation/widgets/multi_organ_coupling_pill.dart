// ============================================================================
// Multi-Organ Coupling Status & Control Pill
// ----------------------------------------------------------------------------
// Interactive UI widget mounted across CardioCath 3D, NeuroLab 3D, and NephroLab 3D:
// - Displays active physiological coupling status (LINKED vs INDEPENDENT).
// - Allows 1-tap toggling of cross-organ cascades.
// - Highlights live cross-organ emergency alerts (Cardiorenal AKI, Cardio-Embolic
//   AFib Stroke Risk with 1-click jump to Left M1 LVO, and Cushing Reflex).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';
import '../../../../screens/neuro_lab_screen.dart';
import '../../../../screens/cardio_cath_screen.dart';

class MultiOrganCouplingPill extends StatefulWidget {
  final MultiOrganPatientState? state;

  const MultiOrganCouplingPill({
    super.key,
    this.state,
  });

  @override
  State<MultiOrganCouplingPill> createState() => _MultiOrganCouplingPillState();
}

class _MultiOrganCouplingPillState extends State<MultiOrganCouplingPill> {
  MultiOrganPatientState get _state => widget.state ?? MultiOrganPatientState.instance;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isCoupled = _state.isCoupled;
    final hasEmbolic = _state.hasEmbolicRisk;
    final isCushing = _state.isCushingReflexActive;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main Toggle Pill ────────────────────────────────────────────────
        Tooltip(
          message: isCoupled
              ? 'Multi-Organ Coupling: ACTIVE. Changes in Cardio, Neuro, or Renal dynamically modulate perfusion & vitals across all 3 organs.'
              : 'Multi-Organ Coupling: INDEPENDENT. Each workstation operates in isolated single-organ mode.',
          child: InkWell(
            key: const Key('multi_organ_coupling_toggle'),
            onTap: () {
              _state.toggleCoupling();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 1800),
                  backgroundColor: _state.isCoupled ? const Color(0xFF00E676) : const Color(0xFF64748B),
                  content: Text(
                    _state.isCoupled
                        ? '🔗 Multi-Organ Digital Patient: LINKED (Cardio-Neuro-Renal cascades active)'
                        : '🔓 Multi-Organ Digital Patient: INDEPENDENT (Single-organ isolation mode)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isCoupled
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : const Color(0xFF64748B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCoupled
                      ? const Color(0xFF00E676).withValues(alpha: 0.6)
                      : const Color(0xFF64748B).withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCoupled ? Icons.link_rounded : Icons.link_off_rounded,
                    size: 13,
                    color: isCoupled ? const Color(0xFF00E676) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCoupled ? 'PHYSIO: LINKED' : 'PHYSIO: INDEPENDENT',
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isCoupled ? const Color(0xFF00E676) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Active Cardio-Embolic Neuro Alert & 1-Click Jump ────────────────
        if (isCoupled && hasEmbolic) ...[
          const SizedBox(width: 6),
          InkWell(
            key: const Key('cardio_embolic_jump_button'),
            onTap: () {
              Navigator.of(context).push(
                NeuroLabScreen.route(initialScenarioId: 'left_m1_stroke'),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.7)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFFF5252)),
                  SizedBox(width: 3),
                  Text(
                    'AFib → Jump Left M1 Stroke 🧠',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── Active Cushing Reflex Alert ──────────────────────────────────────
        if (isCoupled && isCushing) ...[
          const SizedBox(width: 6),
          InkWell(
            key: const Key('cushing_reflex_alert_badge'),
            onTap: () {
              Navigator.of(context).push(CardioCathScreen.route());
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.7)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFFFFB300)),
                  SizedBox(width: 3),
                  Text(
                    'Cushing Reflex: HTN + Brady ❤️',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
